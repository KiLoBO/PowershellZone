<#
.SYNOPSIS
    Update HP or DELL BIOS on workstations from an input list
.Description
    Takes a CSV or TXT file containing workstation names and updates their BIOS. 
    For CSV files, requires specification of the column containing the workstation names.
    If this was downloaded off the repo, make sure to set the BIOS password. Dell updates are handled by DCU-CLI and
    HP updates are handled by HP CMSL.
.PARAMETER inputFile
    Path to the input file (CSV or TXT)
.PARAMETER givenCsvColumn
    For CSV files ONLY. The name of the column containing workstation names.
#>

$VerbosePreference = "Continue"

$inputFile = $args[0]
$givenCsvColumn = $args[1]
$script:workingData = $null
$script:startCompleted = $false # Set completed checks FALSE
$script:csvVerifyCompleted = $false

# --- SET THE BIOS PASSWORD HERE ---
$biosPassword = "SET PASSWORD"

# Config for BIOS and HP BIOS updates. 

$updateDellBiosCMD = {
    try {
        # Configure BitLocker
        $process = Start-Process -FilePath 'path_to_dcu-cli.exe' -ArgumentList '/configure', '-autoSuspendBitLocker=enable' -Wait -NoNewWindow -PassThru
        if ($process.ExitCode -ne 0) { throw "BitLocker config failed with exit code: $($process.ExitCode)" }

        # Configure BIOS Password
        $process = Start-Process -FilePath 'path_to_dcu-cli.exe' -ArgumentList '/configure', "-biosPassword=$Using:biosPassword" -Wait -NoNewWindow -PassThru
        if ($process.ExitCode -ne 0) { throw "BIOS password config failed with exit code: $($process.ExitCode)" }

        # Apply BIOS Updates
        $process = Start-Process -FilePath 'path_to_dcu-cli.exe' -ArgumentList '/applyUpdates', '-updatetype=Bios', '-reboot=disable', '-forceUpdate=enable' -Wait -NoNewWindow -PassThru
        if ($process.ExitCode -eq 500) { 
            Write-Output "No BIOS updates available"
        } elseif ($process.ExitCode -eq 1) { 
            Write-Output "BIOS Update Successful"
        } else {
            throw "BIOS update failed with exit code: $($process.ExitCode)" 
        }

        # Apply Firmware Updates
        $process = Start-Process -FilePath 'path_to_dcu-cli.exe' -ArgumentList '/applyUpdates', '-updatetype=firmware', '-reboot=disable', '-forceUpdate=enable' -Wait -NoNewWindow -PassThru
        if ($process.ExitCode -eq 500) { 
            Write-Output "No firmware updates available"
        } elseif ($process.ExitCode -eq 1) { 
            Write-Output "Firmware Update Successful"
        } else {
            throw "Firmware update failed with exit code: $($process.ExitCode)" 
        }
    } catch {
        throw $_
    }
 }

$updateHPBiosCMD = {
    set-executionpolicy bypass -Scope process
    Import-Module HP.ClientManagement
    $latestVer=(get-hpbiosupdates -latest | select -expandproperty Ver)
    get-hpbiosupdates -flash -version $latestVer -Password "$Using:biosPassword" -BitLocker suspend -Yes
}

function start-init {
    Write-Host '
        --- Have you set the BIOS password? ---
        Usage: .\updateBIOSallEUD.ps1 <inputFile> <csvColumnName>
        Example: .\updateBIOSallEUD.ps1 "C:\AdminTools\TMP\WKS.csv" "host"
        Input types: CSV or TXT
        A TXT file must contain only device names. 
        If using a CSV file, be sure to specify the name of the column (case sensitive) when running the script.
        
        '
    if ([string]::IsNullOrEmpty($biosPassword) -or $biosPassword -eq "SET PASSWORD") {
        Write-Error "BIOS Password not set."
        return
    }

    if (-not $inputFile) {
        Write-Error "No input file specified."
        return
    }

    try {
        # Test if the input file is a FILE or something else
        if (-not (Test-Path -Path $inputFile -Pathtype Leaf)) {
            throw "Input file '$inputFile' does not exist or is not a file."
        }

        # Get file extension
        $inputExt = [System.IO.Path]::GetExtension($inputFile).ToLower()

        if ($inputExt -notin @('.csv', '.txt')) {
            throw "Invalid file type. Only .csv or .txt files are supported."
        }
    } catch {
        Write-Error $_.Exception.Message
        return
    }
    
    Write-Host "File verification successful. Proceeding..." -foreground green

    if ($inputExt -eq ".csv") {
        if ($givenCsvColumn) {
            # If a column was given, proceed to verify
            csvColumnVerify
        } else {
            Write-Error "CSV Column name not specified. See help text"
        }
    } else {
        $script:workingData = (Get-Content $inputFile | 
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | 
            ForEach-Object { $_.Trim() })
        # Verify there is data in $workingData
        try {
            if ($null -eq $workingData -or $workingData.count -eq 0) {
            throw "No Data found in input file"
            }
        } catch {
        Write-Error $_.Exception.Message
        return
        }
        # All checks are good... go on to mainscript
        $script:startCompleted = $true
        $script:csvVerifyCompleted = $true
    }
}

function csvColumnVerify {
    Write-Verbose '
                    CSV file was given, beginning column verification...
                '
    try {
        $columnNames = Import-Csv -Path "$inputFile" | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        # Check if the given Column is in the given inputFile
        if ($givenCsvColumn -cnotin $columnNames) {
            throw "Column '$givenCsvColumn' not found in CSV file. Available columns are: $($columnNames -join ', ')"
        }
    } catch {
        Write-Error $_.Exception.Message
        Write-Host ""
        Write-Error "Verify column name & re-run script."
        return
    }

    $script:workingData = (Import-Csv $inputFile | 
        Select-Object -ExpandProperty $givenCsvColumn | 
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | 
        ForEach-Object { $_.ToString().Trim() })
    # Verify there is data in $workingData
    try {
        if ($null -eq $workingData -or $workingData.count -eq 0) {
            throw "No Data found in input file"
        }
    } catch {
        Write-Error $_.Exception.Message
        return
    }
    # All checks are good... go on to mainscript
    Write-Host "Column verification complete."
    $script:startCompleted = $true
    $script:csvVerifyCompleted = $true
}

function main-script {
    foreach ($target in $workingData) {
        $testOnline = (Test-Connection -Quiet -Count 1 $target)

        if ($testOnline -eq $true) {
            Write-Verbose "Getting Model of: $target"
            try {
                $session = (New-PSSession -ComputerName $target)
                $targetMake = (Invoke-Command -Session $session -ScriptBlock {Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer} -ErrorAction Stop)
            } catch {
                Write-Error "Error getting computer make: $_.Exception.Message"
            }

            if ($targetMake -like "*Dell*") {
                # DELL UPDATE STUFF

                Write-Verbose "Starting updates on $target"
                try {
                    Invoke-Command -Session $session -ScriptBlock $updateDellBiosCMD -ErrorAction Stop
                } catch {
                    Write-Error "Error Updating on ${target}: $_.Exception.Message"
                } finally {
                    Remove-PSSession $session
                }

            } elseif ($targetMake -like "*HP*") {
                # HP UPDATE STUFF

                Write-Verbose "Starting updates on $target"
                try {
                    Invoke-Command -Session $session -ScriptBlock $updateHPBiosCMD -ErrorAction Stop
                } catch {
                    Write-Error "Error Updating on ${target}: $_.Exception.Message"
                } finally {
                    Remove-PSSession $session
                }

            } else {
                Write-Error "Target make does not match Dell or HP. Found make is: $targetMake"
                Remove-PSSession $session
            }
        } else {
            Write-Error "Error testing connection to $target"
        }
    }   
}

start-init

if ($csvVerifyCompleted -and $startCompleted) {
    Write-Verbose "Loading $($workingData.count) items from input file"
    main-script
} else {
    Write-Error "One or more checks failed. Exiting"
    return
}
