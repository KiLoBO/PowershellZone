# Simple powershell menus

---------------------------------------------
# Select index
**Style:**
```
[0] option1.log
[1] option2.log
[2] option3.log
```
**Code:**
```powershell
function LoadMenu {
    for ($i = 0; $i -lt $myList.Count; $i++) {
        "[$i] $($myList[$i].Name)"
    }
    "[Q] Quit"
    $script:selection = Read-Host "`nEnter the number of the selection"
}
```
Your data should be in `$myList`. The result is `$selection` = index of the selected option. The 5th line is adding the "[Q] Quit" option.

**Example:**
```powershell
$myList = Get-ChildItem PATH_TO_LOGS
LoadMenu
if ($selection -ne "Q") {
    Write-Host "Index: $selection" # Writes selection index
    Write-Host "Name: $($myList[$selection].Name)" # Writes selcted index "Name" property
} elseif ($selection -eq "Q") {
    Write-Host "Quitting"
    Exit
} else {
    Write-Host "`nOperation cancelled"
}
```

---------------------------------------------
# Moving arrow selector
**IMPORTANT: THE FILE MUST BE SAVED WITH: `UTF-8 with BOM` ENCODING SO UNICODE CHARACTERS WORK**

**Style:**
```
Script Selection

Use ↑/↓ arrows to select, Enter to confirm, Esc to cancel

  Open MMC console
  GIMME BACK MY SHELL!!!
> Fuzzy find logons
  Set new AD comp info

You selected: Fuzzy find logons
File: fzfindLogOn.ps1
```
**Code:**
```powershell
# **IMPORTANT: THE FILE MUST BE SAVED WITH: `UTF-8 with BOM` ENCODING SO UNICODE CHARACTERS WORK**

function Show-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$MenuItems,
        [Parameter(Mandatory = $false)]
        [string]$Title = "Select an option"
    )

    $vkeycode = 0
    $pos = 0

    function Write-MenuLine {
        param($Index, $Item, $Selected)
        if ($Selected) {
            Write-Host ">" -NoNewline -ForegroundColor Green
            Write-Host " $($Item.niceName)" -ForegroundColor Green
        }
        else {
            Write-Host "  $($Item.niceName)"
        }
    }

    while ($vkeycode -ne 13) {
        Clear-Host
        Write-Host "$Title`n" -ForegroundColor Cyan
        Write-Host "Use ↑/↓ arrows to select, Enter to confirm, Esc to cancel`n" -ForegroundColor Yellow

        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            Write-MenuLine -Index $i -Item $MenuItems[$i] -Selected ($i -eq $pos)
        }

        $press = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.VirtualKeyCode

        switch ($vkeycode) {
            38 { if ($pos -gt 0) { $pos-- } } # Up arrow
            40 { if ($pos -lt ($MenuItems.Count - 1)) { $pos++ } } # Down arrow
            27 { return $null } # Escape
        }
    }
    
    return [PSCustomObject]@{
        Index = $pos
        Selection = $MenuItems[$pos]
    }
}
```
Your data will be in `$someVar` and then passed to the function like so: `$result = Show-Menu -MenuItems $someVar -Title "My Title"`. *Title is not required*.

**Example:**
```powershell
$scriptList = @(
    # Script/task array. niceName is what is displayed in the menu (hard coded in menu function).
    [PSCustomObject]@{
        fileName = 'PATH_TO_.msc_file'
        niceName = "Open MMC console"
    },
    [PSCustomObject]@{
        fileName = "powershell"
        niceName = "GIMME BACK MY SHELL!!!"
    },
    [PSCustomObject]@{
        fileName = "fzfindLogOn.ps1"
        niceName = "Fuzzy find logons"
    },
    [PSCustomObject]@{
        fileName = "setADComp.ps1"
        niceName = "Set new AD comp info"
    }
)
$result = Show-Menu -MenuItems $scriptList -Title "Script Selection"
if ($result) {
    Write-Host "`nYou selected: $($result.niceName)" # Writes selection niceName
    Write-Host "File: $($result.fileName)" # Writes selection fileName
    Write-Host "Index: $($result.Index)" # Writes selection index
} else {
    Write-Host "`nOperation cancelled"
}
```

---------------------------------------------

# Moving arrow selector (extended)
This version is the same as the above, but will not refresh the screen when arrowing. So if you've got any cool ascii art or text that isn't part of the options, it'll stay. The input and returned data is the same as the non-extended version.
**IMPORTANT: THE FILE MUST BE SAVED WITH: `UTF-8 with BOM` ENCODING SO UNICODE CHARACTERS WORK**

**Code:**
```powershell
# **IMPORTANT: THE FILE MUST BE SAVED WITH: `UTF-8 with BOM` ENCODING SO UNICODE CHARACTERS WORK**

function Show-Menu {
    param([array]$MenuItems)
    
    # Save initial cursor position
    $originalPosition = $Host.UI.RawUI.CursorPosition

    $pos = 0
    $vkeycode = 0

    while ($vkeycode -ne 13) {
        # Reset cursor to original position
        $Host.UI.RawUI.CursorPosition = $originalPosition
        
        Write-Host "Use ↑/↓ arrows to select, Enter to confirm`n"
        
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            if ($i -eq $pos) {
                Write-Host ">" -NoNewline -ForegroundColor Green
                Write-Host " $($MenuItems[$i].niceName)" -ForegroundColor Green
            } else {
                Write-Host "  $($MenuItems[$i].niceName)"
            }
        }

        $press = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $vkeycode = $press.VirtualKeyCode

        switch ($vkeycode) {
            38 { if ($pos -gt 0) { $pos-- } }
            40 { if ($pos -lt ($MenuItems.Count - 1)) { $pos++ } }
            27 { return $null }
        }
    }
    
    return [PSCustomObject]@{
        Index = $pos
        Selection = $MenuItems[$pos]
    }
}
```

---------------------------------------------

# Super fancy ascii Menu
This menu is the one I currently use for anything that needs a menu. Stolen from github, and modified by me for simplicity and removing what wasn't needed.
**IMPORTANT: THE FILE MUST BE SAVED WITH: `UTF-8 with BOM` ENCODING SO UNICODE CHARACTERS WORK**

**Code:**

Save this somewhere on your PC and import into script.
```powershell
$ascii = "

      ⠀⠀⠀⠀⣀⣀⣤⣤⣶⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⡄⠀⠀⠀⠀⠀⠀⠀
      ⠀⠀⠀⠀⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⠛⢿⣿⡇⠀⠀⠀⠀⠀⠀⠀
      ⠀⠀⠀⠀⣿⡟⠡⠂⠀⢹⣿⣿⣿⣿⣿⣿⡇⠘⠁⠀⠀⣿⡇⠀⢠⣄⠀⠀⠀⠀
      ⠀⠀⠀⠀⢸⣗⢴⣶⣷⣷⣿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣴⣿⣗⣄⣼⣷⣶⡄⠀⠀
      ⠀⠀⠀⢀⣾⣿⡅⠐⣶⣦⣶⠀⢰⣶⣴⣦⣦⣶⠴⠀⢠⣿⣿⣿⣿⣿⣿⡇⠀⠀
      ⠀⠀⢀⣾⣿⣿⣷⣬⡛⠷⣿⣿⣿⣿⣿⣿⣿⠿⠿⣠⣿⣿⣿⣿⣿⠿⠛⠀⠀⠀
      ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣶⣦⣭⣭⣥⣭⣵⣶⣿⣿⣿⣿⡟⠉⠀⠀⠀⠀⠀⠀
      ⠀⠀⠀⠙⠇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀
      ⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣛⠛⠛⠛⠛⠛⢛⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀
      ⠀⠀⠀⠀⠀⠿⣿⣿⣿⠿⠿⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⠿⠇⠀  
                                    
        There is no place like ~/  

"

function Show-BoxMenu (
    [string[]] $Options,
    [bool[]] $Selected = (New-Object bool[] $Options.Length ),
    [int] $Highlighted = 0,
    [switch] $MultiSelect,
    [switch] $asciiOn,
    [switch] $Expand,
    [string] $Border = '┌─┐│└┘├─┤▒',
    [string] $Title = $(If($MultiSelect){'Select with spacebar'} Else {'Choose an option'}),
    [string] $Marker = $(If($MultiSelect){'√ '} Else {''})
){
    $Width = ($Options + (,$Title) | Measure-Object -Maximum -Property Length).Maximum + ($Marker.Length * 2)
    If($Selected.Length -lt $Options.Length){$Selected += (New-Object bool[] ($Options.Length - $Selected.Length)) }
    
    # Clear screen once at start
    [Console]::Clear()
    if ($asciiOn) {
	    Write-Host $ascii
    }
    $MenuTop = [Console]::CursorTop 
    $FirstShowingOption = 0
    $ScrollThumbIndex = -1
    $previousHighlighted = $Highlighted
	$LeftMargin = 8

    # Initial draw of the menu
    $MaxOptionsToShow = [Console]::WindowHeight - 3 - $(If($Expand){2}Else{0})
    If($Expand) {$Width = [Math]::Max( $Width, [Console]::WindowWidth - 2) }
    $LeftPad = [Math]::Max($Marker.Length,[math]::Floor(($Width-$Title.Length)/2))
    
    # Draw the header once
    If($Expand){
        $EOL = "`r"
        Write-Host ("$(' ' * $LeftMargin)$($Border[0])$([string]$Border[1] * ($Width))$($Border[2])$EOL") -NoNewline
        Write-Host ("$(' ' * $LeftMargin)$($Border[3])$(((' ' * $LeftPad) + $Title).PadRight($Width,' '))$($Border[3])$EOL") -NoNewline
        Write-Host ("$(' ' * $LeftMargin)$($Border[6])$([string]$Border[7] * ($Width))$($Border[8])$EOL") -NoNewline
    }Else{
        $EOL = "`r`n"
        Write-Host ("$(' ' * $LeftMargin)$($Border[0])$((([string]$Border[1] * $LeftPad) + $Title).PadRight($Width,$Border[1]))$($Border[2])$EOL") -NoNewline
    }

    # Modify the Update-MenuItem function
    function Update-MenuItem($index) {
        [Console]::SetCursorPosition($LeftMargin, $MenuTop + $(If($Expand){3}Else{1}) + ($index - $FirstShowingOption))
        Write-Host "$($Border[3])$(If($Selected[$index]){$Marker}else{' ' * $Marker.length})" -NoNewLine
        if ($index -eq $Highlighted) {
            Write-Host ([string]$Options[$index]).PadRight($Width - $marker.Length,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
        } else {
            Write-Host ([string]$Options[$index]).PadRight($Width - $marker.Length,' ') -NoNewline
        }
        Write-Host "$(If($ScrollThumbIndex -eq $index){$Border[9]}Else{$Border[3]})$EOL" -NoNewline
    }
	
	for ($i = $FirstShowingOption; $i -lt [Math]::Min($Options.Length, $MaxOptionsToShow + $FirstShowingOption); $i++) {
        Update-MenuItem $i
    }

    # Modify the status line drawing
    Do {
        [Console]::SetCursorPosition($LeftMargin, $MenuTop + $(If($Expand){3}Else{1}) + [Math]::Min($Options.Length, $MaxOptionsToShow))
        $Status = If($MultiSelect){'{0}/{1}' -f ($Selected | ?{$_ -eq $true}).Count, $Options.Length}Else{''}
        Write-Host "$($Border[4])$($Status.PadLeft($Width,$Border[1]))$($Border[5])$EOL" -NoNewline
        $key = [Console]::ReadKey($true)

        # Store previous state
        $previousHighlighted = $Highlighted
        $previousFirstShowing = $FirstShowingOption

        # Handle key input (your existing key handling code)
        If ($key.Key -eq [ConsoleKey]::Spacebar) {$Selected[$Highlighted] = !$Selected[$Highlighted]; If($Highlighted -lt $Options.Length - 1){$Highlighted++} }
        ElseIf ($key.Key -eq [ConsoleKey]::UpArrow  ) {$Highlighted = [math]::Max($Highlighted - 1, 0)}
        ElseIf ($key.Key -eq [ConsoleKey]::DownArrow) {$Highlighted = [math]::Min($Highlighted + 1, $Options.Length - 1)}
        # ... (rest of your key handling code)

        # Update only what changed
        if ($previousHighlighted -ne $Highlighted) {
            Update-MenuItem $previousHighlighted
            Update-MenuItem $Highlighted
        }

    }While(! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($key.Key))

    # Your existing return logic
    If($key.Key-eq [ConsoleKey]::Enter){
        If($MultiSelect){
            $Options | %{$i=0}{ If($Selected[$i++]){$_} }
        }Else{
            $Options[$Highlighted]
        }
    }
}
```

**Example:**
```powershell
# Import menu function
. "path_to_above_function"

# Set data (can come from a command such as get-childitem)
$scriptList = @(
    [PSCustomObject]@{
        fileName = 'PATH_TO_.msc_file'
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

$selection = Show-BoxMenu -Options $scriptList

if ($selection) {
    # Find the full object in $scriptList where niceName matches the selection
    $selectedScript = $scriptList | Where-Object { $_.niceName -eq $selection }
    $selectedIndex = [array]::IndexOf($scriptList.niceName, $selection)

    # Access various parts of the data...
    Write-Host "niceName: $($selectedScript.niceName)"
    Write-Host "fileName: $($selectedScript.fileName)"
    Write-Host "Index: $selectedIndex"
}

if ( $selectedIndex -eq "0" ) {
    Write-Host "`n Opening MMC console..." -ForegroundColor Green
    mmc.exe $scriptList[0].fileName
} elseif ( $selectedIndex -eq "2" ) {
    Write-Host "`nSpawning ISE session"
    ise
} else {
    Write-Host "`nRunning: $scriptsDir$($selectedScript.fileName)" -ForegroundColor Green
    Write-Host ""
}
```
