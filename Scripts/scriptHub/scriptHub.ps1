<# 
  Have you read the setup readme? https://github.com/KiLoBO/PowershellZone/blob/main/Scripts/scriptHub/Hub%20script%20setup.md
#>

try {
    # Import show-menu function
    . "path_to_asciiBoxMenu.ps1"
} catch {
    Write-Error "Fatal error importing menu function: $_.Exception.Message"
    Write-Error "Have you placed asciiBoxMenu.ps1 correctly?"
}

# Set script location
$scriptsDir = "path_to_scripts_dir"

# Set Menu options. Add here as needed. niceName = what is displayed in the menu. fileName = the actual filename used to launch the script/execute something.
$scriptList = @(
    [PSCustomObject]@{
        fileName = 'path_to_.msc_file'
        niceName = "Open MMC console"
    },
    [PSCustomObject]@{
        fileName = "powershell"
        niceName = "GIMME BACK MY SHELL!!!"
    },
    [PSCustomObject]@{
        fileName = "ise"
        niceName = "Powershell ISE"
    },
    [PSCustomObject]@{
        fileName = "fzfindLogOn.ps1"
        niceName = "Fuzzy find logons"
    },
    [PSCustomObject]@{
        fileName = "setADComp.ps1"
        niceName = "Set new AD comp info"
    },
    [PSCustomObject]@{
        fileName = "Quit main Script"
        niceName = "Quit"
    }
)

function holdToReturn {
    Write-Host "`nPress any key to return"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    return
}

do {
	$menuOptions = $scriptList.niceName
    $selection = Show-BoxMenu -Options $menuOptions -asciiOn
	
	if ($selection) {
		# Find the full object in $scriptList where niceName matches the selection
		$selectedScript = $scriptList | Where-Object { $_.niceName -eq $selection }
		$selectedIndex = [array]::IndexOf($scriptList.niceName, $selection)

        # Examples to access data...
		# Write-Host "niceName: $($selectedScript.niceName)"
		# Write-Host "fileName: $($selectedScript.fileName)"
	    # Write-Host "Index: $selectedIndex"
    }


    # Do what was selected logic. The current logic is: any INDEX specifically called out is a custom thing such as running MMC console
    # ELSE treat the selection as a script and combine $scriptsDir and $selectedScript.fileName to run it.
    if ( $selectedIndex -eq "0" ) {
        Write-Host "`nOpening MMC console..." -ForegroundColor Green
        mmc.exe $scriptList[0].fileName

    } elseif ( $selectedIndex -eq "1" ) {
        Write-Host "`nfine..."
        $env:SHELL_TYPE = 'CUSTOM_SPAWNED'
        powershell
    
    } elseif ( $selectedIndex -eq "2" ) {
        Write-Host "`nSpawning ISE session"
        ise

    } elseif ( $selectedScript.niceName -eq "Quit" ) {
        Write-Host "`nBye Bye!"
        Exit

    } else {
        Write-Host "`nRunning: $scriptsDir$($selectedScript.fileName)" -ForegroundColor Green
        Write-Host ""

        & $scriptsDir$($selectedScript.fileName)
        holdToReturn

    }
} while ( 1 -eq 1)
