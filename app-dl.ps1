# Initialize variables
[string]$branch = 'dev'
[string]$module = "$Env:TEMP\modules.psm1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/psfer07/App-DL/$branch/modules.psm1" -OutFile $module
Import-Module $module -DisableNameChecking
$json = Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/apps.json"
$nameArray = $json.psobject.Properties.Name
$filteredApps = @()
foreach ($i in 0..($nameArray.Count - 1)) {
  $name = $nameArray[$i]; $app = $json.$name; $folder = $app.folder; $url = $app.URL; $exe = $app.exe; $syn = $app.syn; $cmd = $app.cmd; $cmd_syn = $app.cmd_syn
  $filteredApps += [PsCustomObject]@{Index = $i; Name = $name; Folder = $folder; URL = $url; Exe = $exe; Size = $size; Syn = $syn; Cmd = $cmd; Cmd_syn = $cmd_syn }
}

Clear-Host
Select-App
$pkg = Read-Host "`nWrite the number of the app you want to get"

# Assign the corresponding variables to the selected app
$pkg_n = [int]($pkg -replace "\.")
$n = $filteredApps[$pkg_n - 1]
$program,$exe,$syn,$folder,$url,$cmd,$cmd_syn,$o = $null # Resets variables if the program is loaded from the Restart-App function
$program = $n.Name
$exe = $n.Exe
$syn = $n.Syn
$folder = $n.folder
$url = $n.URL
$cmd = $n.Cmd
$cmd_syn = $n.Cmd_syn
$o = Split-Path $url -Leaf

Clear-Host
Write-Main "$program selected"
Show-Details
Show-Paths
[string]$p = Read-Host "`nChoose a number"
switch ($p) {
  0 { Restart-App }
  1 { $p = "$Env:USERPROFILE\Desktop"; break }
  2 { $p = "$Env:USERPROFILE\Documents"; break }
  3 { $p = "$Env:USERPROFILE\Downloads"; break }
  4 { $p = $Env:SystemDrive; break }
  5 { $p = $Env:ProgramFiles; break }
  6 { $p = $Env:HOMEPATH; break }
  'x' { $p = Read-Host 'Set the whole custom path'; break }
  'X' { $p = Read-Host 'Set the whole custom path'; break }
  default { Write-Host "Invalid input. Using default path: $Env:USERPROFILE"; $p = $Env:USERPROFILE; break }
}

Write-Main "Selected path: $p"
if (Test-Path "$p\$o") { Revoke-Path }
if (Test-Path "$p\$program\$folder\$exe") { Revoke-Path }

Write-Main "App to download: $program..."

Write-Secondary "Do you want to open it when finished? (y/n)"
$open = Read-Host
if ($open -eq 'y' -or $open -eq 'Y') { $open = $true } else { $open = $false }
$dl = Read-Host 'Confirmation (press any key or go to the (R)estart menu)'
if ($dl -eq 'R' -or $dl -eq 'r') { Restart-Menu }

Invoke-WebRequest -URI $url -OutFile "$p\$o"
if ($?) { Write-Secondary "File downloaded successfully"} else { Write-Warning "An error occurred while downloading the file: $_Exception" }
if ($open = $true) { Open-File }