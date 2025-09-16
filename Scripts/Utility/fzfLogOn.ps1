<#
.SYNOPSIS
    Fuzzy search through user logon logs.
.Description
    At my org we write user logons to a file: user.name.log on a share drive. This script lets you fuzzy search these logs, and output the last 5 lines.

    Using the Select-FuzzyString function (see line 12) this script fuzzy searches for the entered string. It finds similar user.name.log and 
    gives you the option to pick which one to look at. See the /Functions/Select-FuzzyString.ps1 in this repo.

    Make sure the below bullets are correct for full function:
    - $reportDir is correct. (19)
    - Select-FuzzyString.ps1 is placed correctly. (25)
#>

# Disable CTRL+C to exit
[Console]::TreatControlCAsInput = $true

# Logon report location
$reportDir = "path_user_logons_dir"

# Get dir listing of reportDir
$userReports = Get-ChildItem $reportDir | Select-Object -ExpandProperty Name

# Import fzf function
. "path_to_Select-FuzzyString.ps1"

Write-Host "`n"
Write-Host "                    ---------------------------------------------------            " -ForegroundColor Cyan
Write-Host "                    |                                                 |            " -ForegroundColor Cyan
Write-Host "                    |              Fuzzy search user logons           |            " -ForegroundColor Cyan
Write-Host "                    |                 Version: working                |            " -ForegroundColor Cyan
Write-Host "                    |                                                 |            " -ForegroundColor Cyan
Write-Host "                    |                     By: David                   |            " -ForegroundColor Cyan
Write-Host "                    |                                                 |            " -ForegroundColor Cyan
Write-Host "                    ---------------------------------------------------            " -ForegroundColor Cyan
Write-Host "`n"

function LoadMenu {
    if ($fzfMatches.Count -eq "1") {
        Write-Host "`n"
        Write-Host "1 Match found: $fzfMatches" -ForegroundColor black -BackgroundColor DarkGreen
        $script:selection = $fzfMatches
        Return
    } else {
        $fzfMatches | ForEach-Object {
            "[$($fzfMatches.IndexOf($_))] $_"
        }

        $script:selection = Read-Host "`nEnter the number of the log"
    }
}

do {
    do {
        $fzfIn = Read-Host "Enter logon name"
        $fzfMatches = ($userReports | Select-FuzzyString $fzfIn | Select-Object -ExpandProperty Result)

        LoadMenu

        if ($fzfMatches.Count -gt 1 ) {
            $pickedMatch = $fzfMatches[$selection].Trim()
            Write-Host "`nYou chose: $pickedMatch"
        } else {
            $pickedMatch = $fzfMatches.Trim()
        }
        
        $acceptMatch = Read-Host "`nIs this correct? (y/n)"

    } while ($acceptMatch -ne "y")

    Write-Host "`nData from log:" -ForegroundColor Green
    Get-Content $reportDir$pickedMatch -Tail 5

    $exit = Read-Host "`nRun another search? (y/n)"

} while ($exit -ne "n")

# Re-enable CTRL+C to exit
[Console]::TreatControlCAsInput = $false
