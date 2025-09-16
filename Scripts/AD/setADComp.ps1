<#
.SYNOPSIS
    Add location, description, and groups to a given AD computer.
.Description
    Adds give location, and description to an AD computer.
    Adds groups based on orgwk* or orgnb* or orgwkiap*
#>

$VerbosePreference = "Continue"

$randNum = ( 1, 2, 3, 4 | Get-Random) # random num generation
$script:defaultGroups = @('Cool Group 1','Cool group 2','Cool group 3') # base group array
$defaultGroups += "Cool-Deployment Group $randNum" # add group: "Cool-Deployment Group $randNum" to default group array

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "RSAT Tools not found, install it."
    Exit 1
}

function start-init {
    Write-Host '
        Please verify data entered prior to pressing enter.
    '
    do {
        $script:adCompTarget = Read-Host "Enter AD Computer Name"
        try {
            Get-ADComputer $adCompTarget
        } catch {
            Write-Error "Error finding AD computer: $_"
            return
        }

        # logic to handle adding build specific groups to device based on name. (org naming convention)
        if ( $adCompTarget -like "orgnb*" ) {
            $script:defaultGroups += "Org Wireless Group"
            $script:defaultGroups += "Special laptop group"

            Write-Verbose "Laptop Detected, adding necessary groups to array"

        } elseif ( $adCompTarget -like "orgwkiap*" ) {
            $script:defaultGroups += "IAP group"

            Write-Verbose "IAP, adding necessary groups to array"
        } else {
            Write-Verbose "EUD Workstation detected"
        }
        
        Write-Host 'Enter extra groups, format: Foo,Bar'
        $extraGroups = Read-Host "Leave blank if none (press enter)" 

        if ( $extraGroups ) { # Write extra groups to default groups array
            $extraGroupsArray = $extraGroups.Split(',').Trim()
            $script:defaultGroups += $extraGroupsArray
        }

        $script:adCompDescription = Read-Host "Enter description field info"
        $script:adCompLocation = Read-Host "Enter Location field info"

        Write-Host "Here is the information entered, verify it"
        Write-Host "Name: $adCompTarget"
        Write-Host "Description: $adCompDescription"
        Write-Host "Location: $adCompLocation"
        Write-Host "Groups:"
        Write-Host ($defaultGroups -join "`n")

        $acceptData = Read-Host "Data is correct? (y/n)"
    } while ($acceptData -ne 'y')

    return $true
}

function setDescription {
    param($Identity, $Description)
    try {
        Write-Verbose "Setting desciption field..."
        Set-ADComputer -Identity $Identity -Description "$Description"
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Error "Error setting AD description: $_"
        return $false
    }
    return $true
}

function setLocation {
    param($Identity, $Location)
    try {
        Write-Verbose "Setting location field..."
        Set-ADComputer -Identity $Identity -Location "$Location"
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Error "Error setting AD location: $_"
        return $false
    }
    return $true
}

function setGroups {
    param($Identity, $Groups)
    Write-Verbose "Adding to groups..."
    try {
        $computerDN = (Get-ADComputer $Identity).DistinguishedName

        foreach ( $group in $Groups ) {
            Add-AdGroupMember -Identity "$Group" -Members "$computerDN"
        }
    } catch {
        Write-Error "Error setting AD groups: $_"
        return $false
    }
    Write-Host "Success" -ForegroundColor Green
    return $true
}

if (start-init) {
    $success = $true
    $success = $success -and (setDescription -Identity $adCompTarget -Description $adCompDescription)
    $success = $success -and (setLocation -Identity $adCompTarget -Location $adCompLocation)
    $success = $success -and (setGroups -Identity $adCompTarget -Groups $defaultGroups)

    if ($success) {
        Write-Host "`nFinal overview from DC:"
        Get-ADComputer $adCompTarget -Properties Location, Description, MemberOf | 
            Select-Object Name, Location, Description,
            @{Name='MemberOf'; Expression={($_.MemberOf | ForEach-Object {([ADSI]"LDAP://$_").name}) -join "`n"}} |
            Format-List
    } else {
        Write-Error "Script completed with errors. Review output above."
    }
}
