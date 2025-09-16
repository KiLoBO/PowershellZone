<#
  $backupPath must contain the bookmarks backup (set and written in by backupBookmarks function.
#>

$backupPath = "C:\Users\$env:UserName\backups"
if ( -not (Test-Path $backupPath) ){
    Write-Error "Backup path not found at $backupPath"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

$edgeBackupCount = (Get-ChildItem "$backupPath" -Filter "edge_backup*" | Measure-Object | Select-Object -ExpandProperty Count)
$chromeBackupCount = (Get-ChildItem "$backupPath" -Filter "chrome_backup*" | Measure-Object | Select-Object -ExpandProperty Count)

function backupColors {
    if ( $edgeBackupCount -ge 1 ) {
        $edgeColor = "Green"
    } else {
        $edgeColor = "Red"
    }

    if ( $chromeBackupCount -ge 1 ) {
        $chromeColor = "Green"
    } else {
        $chromeColor = "Red"
    }

    return @{
        edge = $edgeColor
        chrome = $chromeColor
    }
}

function restoreEdge {
    $edgeSource = "C:\Users\$env:UserName\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"
    $edgeBackupLatest = (Get-ChildItem "$backupPath" -Filter "edge_*" | Sort-Object CreationTime -Descending | Select-Object -First 1 -ExpandProperty Name)

    if ($edgeBackupCount -lt 1) {
        Write-Warning "No available backups. Exiting."
        return
    }

    if (Get-Process "msedge" -ErrorAction SilentlyContinue) {
        try {
            while (Get-Process "msedge") {
                Write-Host "Edge is still running, attempting to kill..." -ForegroundColor Yellow
                Get-Process "msedge" | Stop-Process -force
                Start-Sleep -Seconds 2
            }
            Write-Host "Successfully killed Edge" -ForegroundColor Green
        } catch {
            Write-Error "Error while trying to kill Edge: $_"
            Write-Host ""
            Write-Host ""
            Write-Error "Please kill Edge and re-run the script"
            return
        }
    }

    if (Test-Path $edgeSource) {
        $edgeHash = (Get-FileHash $edgeSource -Algorithm SHA256).Hash.Substring(0,8)
        Move-Item -Path $edgeSource -Destination "$edgeSource.$edgeHash.bak"
        Write-Host "Moved current Bookmarks file to: $edgeSource.$edgeHash.bak"
    }

    try {
        Move-Item -Path "$backupPath\$edgeBackupLatest" -Destination "$edgeSource"
        Write-Host "Successfully restored Edge bookmarks from: $edgeBackupLatest" -ForegroundColor Green
    } catch {
        Write-Error "Error occurred restoring Edge bookmarks: $_"
        return
    }
}

function restoreChrome {
    $chromeSource = "C:\Users\$env:UserName\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    $chromeBackupLatest = (Get-ChildItem "$backupPath" -Filter "chrome_*" | Sort-Object CreationTime -Descending | Select-Object -First 1 -ExpandProperty Name)

    if ($chromeBackupCount -lt 1) {
        Write-Warning "No available backups. Exiting."
        return
    }

    if (Get-Process "chrome" -ErrorAction SilentlyContinue) {
        try {
            while (Get-Process "chrome") {
                Write-Host "Chrome is still running, attempting to kill..." -ForegroundColor Yellow
                Get-Process "chrome" | Stop-Process -force
                Start-Sleep -Seconds 2
            }
            Write-Host "Successfully killed Chrome" -ForegroundColor Green
        } catch {
            Write-Error "Error while trying to kill Chrome: $_"
            Write-Host ""
            Write-Host ""
            Write-Error "Please kill Chrome and re-run the script"
            return
        }
    }

    if (Test-Path $chromeSource) {
        $chromeHash = (Get-FileHash $chromeSource -Algorithm SHA256).Hash.Substring(0,8)
        Move-Item -Path $chromeSource -Destination "$chromeSource.$chromeHash.bak"
        Write-Host "Moved current Bookmarks file to: $chromeSource.$chromeHash.bak"
    }

    try {
        Move-Item -Path "$backupPath\$chromeBackupLatest" -Destination "$chromeSource"
        Write-Host "Successfully restored Chrome bookmarks from: $chromeBackupLatest" -ForegroundColor Green
    } catch {
        Write-Error "Error occurred restoring Chrome bookmarks: $_"
        return
    }
}

$colors = backupColors
Write-Host "    Bookmarks restore tool."
Write-Host "    Edge backups found: $edgeBackupCount" -ForegroundColor $colors.edge
Write-Host "    Chrome backups found: $chromeBackupCount" -ForegroundColor $colors.chrome
Write-Host "    Enter 1 for Edge, 2 for Chrome, and 3 for Edge AND Chrome."
$browserSelection = Read-Host "Selection"

try {
    if ( $browserSelection -eq "1" ) {
        Write-Host "
        ---------------------------------------------
        Starting edge bookmark restore.
        "
        restoreEdge

    } elseif ( $browserSelection -eq "2" ) {
        Write-Host "
        ---------------------------------------------
        Starting chrome bookmark restore.
        "
        restoreChrome

    } elseif ( $browserSelection -eq "3" ) {
        Write-Host "
        ---------------------------------------------
        Starting edge + chrome bookmark restore.
        "
        restoreEdge
        restoreChrome

        Write-Host "Successfully restored both Edge and Chrome bookmarks" -ForegroundColor Green
    } else {
        Write-Host "    ---------------------------------------------"
        Write-Warning "Input option not valid."
    }
} catch {
    Write-Error "Unexpected error occured: $_"
}


Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
Write-Host ""
Exit
