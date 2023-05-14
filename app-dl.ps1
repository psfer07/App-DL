# Bypasses any execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Removes last possible modules.psm1 from the computer
Remove-Item "$Env:TEMP\modules.psm1" -Force -ErrorAction SilentlyContinue

# Imports variables
[string]$branch = 'dev'
[string]$mod = "$Env:TEMP\modules.psm1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/psfer07/App-DL/$branch/modules.psm1" -OutFile $mod
Import-Module $mod -DisableNameChecking -Force
$json = Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/apps.json"
# $json = Get-Content ".\apps.json" -Raw | ConvertFrom-Json
# Import-Module ".\modules.psm1" -DisableNameChecking -Force

# Sets the JSON data into Powershell variables
$nameArray = $json.psobject.Properties.Name
$filteredApps = @()
foreach ($i in 0..($nameArray.Count - 1)) {
  $name = $nameArray[$i]; $app = $json.$name; $folder = $app.folder; $url = $app.URL; $exe = $app.exe; $syn = $app.syn; $cmd = $app.cmd; $cmd_syn = $app.cmd_syn; $type = $app.type
  $filteredApps += [PsCustomObject]@{Index = $i; Name = $name; Folder = $folder; URL = $url; Exe = $exe; Size = $size; Syn = $syn; Cmd = $cmd; Cmd_syn = $cmd_syn; Type = $type }
}

# Lists every single app in the JSON
Clear-Host
Show-Apps
$pkg = Read-Host "`nWrite the number of the app you want to get"

# Assign the corresponding variables to the selected app
$n = $filteredApps[$pkg - 1]; $program = $n.Name

Write-Main "$program selected"
# Assign the left variables for quicker response
$exe = $n.Exe; $syn = $n.Syn; $folder = $n.folder; $url = $n.URL; $cmd = $n.Cmd; $cmd_syn = $n.Cmd_syn; $type = $n.type
$o = Split-Path $url -Leaf; $open = $false; $request = Invoke-WebRequest $url -Method Head; $length = [int]$request.Headers['Content-Length']

Start-Sleep -Milliseconds 750
Clear-Host
Show-Details

# Sets all possible paths for downloading the program
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
  7 { $p = $Env:TEMP; $open = $true; break }
  'x' { $p = Read-Host 'Set the whole custom path'; break }
  default { Write-Host "Invalid input. Using default path: $Env:USERPROFILE"; $p = $Env:USERPROFILE; break }
}
# Checks if the program was allocated there before
if (Test-Path "$p\$o") { Revoke-Path }
if (Test-Path "$p\$program\$folder\$exe") { Revoke-Path }


Clear-Host
# Asks the user to open the program after downloading it
$openString = $null
if ($open -eq $false) {
  Write-Main "Selected path: $p"
  Write-Point "Do you want to open it when finished? (y/n)"
  $openAns = Read-Host
  if ($openAns -eq 'y' -or $openAns -eq 'Y') { $open = $true }
}
else { $openString = ' and open' }

# Last confirmation
Write-Main "You are going to download$openString $program"
$conf = Read-Host 'Confirmation press any key or go to the (R)estart menu)'
if ($conf -eq 'R' -or $conf -eq 'r') { Restart-App }
Clear-Host

# Start download
$wc = New-Object System.Net.WebClient
$wc.DownloadFileAsync($url, "$p\$o")

# Updates the download progress
while ($wc.IsBusy) {
  $downloadedOld = (Get-Item "$p\$o").Length
  Start-Sleep -Milliseconds 100
  $Downloaded = (Get-Item "$p\$o").Length
  $MBs = ($downloaded - $DownloadedOld)*10
  $MBs = [Math]::Round($MBs) / 1MB
  $percentage = ($downloaded / $length) * 100
  $percentage = [Math]::Round($percentage)
  $downloadedString = "{0:N2} MB / {1:N2} MB at {2:N2} MB/s" -f ($downloaded / 1MB), ($length / 1MB), $MBs
  Write-Progress -Activity "Downloading $program..." -Status "$downloadedString ($percentage%) complete" -PercentComplete $percentage
}

if ($open -eq $true) { Open-File }
Write-Point 'Do you want to download another app? (y/n)'
$repeat = Read-Host
if ($repeat -eq 'y' -or $repeat -eq 'Y') { Restart-App }