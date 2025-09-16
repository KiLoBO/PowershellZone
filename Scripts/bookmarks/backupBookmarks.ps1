<#
  This function is ran as part of a logoff script.
#>

function backup-Bookmarks {
    # set backup location. Make dir if it doesnt exist.
    $backupPath = "C:\Users\$env:UserName\backups"
    if ( -not (test-path $backupPath) ) {
        new-item -Path $backupPath -ItemType Directory
    }

    try {
        $date = (Get-Date -Format ddMMMyyyy)
        $chromeSource = "C:\Users\$env:UserName\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
        $edgeSource = "C:\Users\$env:UserName\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"

        # Backup Chrome
        if (Test-Path $chromeSource) {
            Copy-Item -Path $chromeSource -Destination "$backupPath\chrome_backup_$date"
            "$(Get-Date) - Chrome bookmarks backed up" | Out-File -Append -FilePath "$backupPath\backup.log"
            # Keep only latest 3 Chrome backups
            Get-ChildItem -Path $backupPath -Filter "chrome_backup_*" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 | Remove-Item
        }
        
        # Backup Edge
        if (Test-Path $edgeSource) {
            Copy-Item -Path $edgeSource -Destination "$backupPath\edge_backup_$date"
            "$(Get-Date) - Edge bookmarks backed up" | Out-File -Append -FilePath "$backupPath\backup.log"
            # Keep only latest 3 Edge backups
            Get-ChildItem -Path $backupPath -Filter "edge_backup_*" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 | Remove-Item
        }
    } catch {
        "$(Get-Date) - Error Occurred: $_" | Out-file -Append -FilePath "$backupPath\backup.log"
    }
}

backup-Bookmarks
