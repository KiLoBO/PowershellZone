<#
  Sets prompt to "#" if admin.
#>
Set-Location $HOME

$isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
function Prompt {
	$currentDir = $pwd.Path.Replace($env:USERPROFILE, "~")

	$prefix = ''
	if ($isAdministrator) {
		$prefix = 'ADMIN: '
	}
	$Host.UI.RawUI.WindowTitle = "$prefix$(Split-Path $currentDir -Leaf)"

	$prompt = '$'
	if ($isAdministrator) {
		$prompt = '#'
	}
	return "`n$currentDir`n$prompt "
}

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

function cdh {
    Set-Location $HOME
}

function reboot {
    shutdown /r /t 0
}

# logic to handle spawned shell from script hub (avoids entering hub script loop if env var is set while still loading profile).
if ( -not $env:SHELL_TYPE ) {
	& path_to_scriptHub.ps1
}
