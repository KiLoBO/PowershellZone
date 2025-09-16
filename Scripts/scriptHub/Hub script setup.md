# Script Hub/Home dashboard 
Since I have so many small scripts for various functions such as fuzzy searching logins or setting data for a new computer in AD I made a script that acts like a dashboard or hub for all of these. It is essentially always on meaning that it starts when powershell opens and when one of the scripts is run out of it exits, it exits to the hub. 

I designed it to be run via your powershell profile, with powershell run as admin:
1) Make `profile.ps1` at C:\Users\user.name\Documents\WindowsPowerShell\
2) Add the below snippet:
```powershell
if ( -not $env:SHELL_TYPE ) {
	& path_to_scriptHub.ps1
}
```
3) Save and restart powershell. 

See my full [profile](profile.ps1).

### Setup the hub script
Download the [hub script](scriptHub.ps1). Make sure the name and path match the snippet added to your profile (path_to_scriptHub.ps1).

Download the [ascii Menu](../../Functions/menus.md#super-fancy-ascii-menu). Place in a common place for reuse.

Customize the `$scriptList` array for your needs. **The last Object in the array will NOT have a comma (,)**
Ideally, just copy the below template and paste it in as needed BEFORE the "Quit" object (last one)
```powershell
    [PSCustomObject]@{
        fileName = "my_cool_thing"
        niceName = "Cool Thing"
    },
```

**Some things to keep in mind:**
- Place custom options such as MMC console, launch ISE, etc BEFORE scripts. The logic of the script is: If the Index is specifially called out in the if/elseif statements, do the CUSTOM thing. Any other index is treated as a script and $scriptDir and $selectedScript.niceName are combined to make a full path to execute.
- niceName = What is displayed in the menu. 
- fileName = The actual filename used to launch the script/execute something.


```powershell
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
```

Once you are good with the options you are good to go! You can customize the ascii art if you would like in the menu function or disable by removing `-asciiOn` from line 2 in the `do` loop in `scriptHub.ps1`

