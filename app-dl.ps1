# Bypasses any execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Removes last possible modules.psm1 from the computer
Remove-Item "$Env:TEMP\modules.psm1" -Force -ErrorAction SilentlyContinue

# Imports variables
# [string]$branch = 'dev'
# [string]$module = "$Env:TEMP\modules.psm1"
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/psfer07/App-DL/$branch/modules.psm1" -OutFile $module
# Import-Module $module -DisableNameChecking
# $json = Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/apps.json"
$json = Get-Content ".\apps.json" -Raw | ConvertFrom-Json
Get-Content .\modules.psm1
Import-Module ".\modules.psm1" -DisableNameChecking

# Sets the JSON data into Powershell variables
$nameArray = $json.psobject.Properties.Name
$filteredApps = @()
foreach ($i in 0..($nameArray.Count - 1)) {
  $name = $nameArray[$i]; $app = $json.$name; $folder = $app.folder; $url = $app.URL; $exe = $app.exe; $syn = $app.syn; $cmd = $app.cmd; $cmd_syn = $app.cmd_syn; $installs = $app.installs; $type = $app.type
  $filteredApps += [PsCustomObject]@{Index = $i; Name = $name; Folder = $folder; URL = $url; Exe = $exe; Size = $size; Syn = $syn; Cmd = $cmd; Cmd_syn = $cmd_syn; Installs = $installs; Type = $type }
}

# Lists every single app in the JSON
#Clear-Host
Select-App
$pkg = Read-Host "`nWrite the number of the app you want to get"

# Assign the corresponding variables to the selected app
$n = $filteredApps[$pkg - 1]; $program = $n.Name; $exe = $n.Exe; $syn = $n.Syn; $folder = $n.folder; $url = $n.URL; $cmd = $n.Cmd; $cmd_syn = $n.Cmd_syn; $installs = $n.installs; $type = $n.type; $o = Split-Path $url -Leaf

Write-Main "$program selected"
Start-Sleep -Milliseconds 2500
#Clear-Host
Show-Details

# Sets all possible paths for downloading the program
Show-Paths

# Checks if the program was allocated there before
if (Test-Path "$p\$o") { Revoke-Path }
if (Test-Path "$p\$program\$folder\$exe") { Revoke-Path }
Start-Sleep -Seconds 1

# Asks the user to open the program after downloading it
Write-Main "Do you want to open it when finished? (y/n)"
$openAns = Read-Host
$open = $false
$openString = $null
if ($openAns -eq 'y' -or $openAns -eq 'Y') { $open = $true }
if ($open -eq $true) { $openString = ' and open' }

# Last confirmation
Write-Main "You are going to download$openString $program"
$dl = Read-Host 'Confirmation (press any key or go to the (R)estart menu)'
if ($dl -eq 'R' -or $dl -eq 'r') { Restart-App }

#Clear-Host
Invoke-RestMethod -Uri $url -OutFile "$p\$o"
if ($?) { Write-Main "File downloaded successfully" } else { Write-Warning "An error occurred while downloading the file" }
if ($open -eq $false) { exit } else { Open-File }