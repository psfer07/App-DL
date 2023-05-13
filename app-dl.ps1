# Bypasses any execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Removes last possible modules.psm1 from the computer
Remove-Item "$Env:TEMP\modules.psm1" -Force -ErrorAction SilentlyContinue

# Imports variables
[string]$branch = 'dev'
# [string]$module = "$Env:TEMP\modules.psm1"
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/psfer07/App-DL/$branch/modules.psm1" -OutFile $module
# Import-Module $module -DisableNameChecking -Force
# $json = Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/apps.json"
$json = Get-Content ".\apps.json" -Raw | ConvertFrom-Json
Import-Module ".\modules.psm1" -DisableNameChecking -Force

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
$n = $filteredApps[$pkg - 1]; $program = $n.Name; $exe = $n.Exe; $syn = $n.Syn; $folder = $n.folder; $url = $n.URL; $cmd = $n.Cmd; $cmd_syn = $n.Cmd_syn; $type = $n.type; $o = Split-Path $url -Leaf

Write-Main "$program selected"
Start-Sleep 1
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

$openString = $null
if ($open -eq $true) { $openString = ' and open' }

# Asks the user to open the program after downloading it
if ($open -ne $true) {
  Write-Main "Selected path: $p"
  Write-Point "Do you want to open it when finished? (y/n)"
  $openAns = Read-Host
  $open = $false
  if ($openAns -eq 'y' -or $openAns -eq 'Y') { $open = $true }
}

# Last confirmation
Write-Main "You are going to download$openString $program"
$confirm = Read-Host 'Confirmation press any key or go to the (R)estart menu)'
if ($confirm -eq 'R' -or $confirm -eq 'r') { Restart-App }

Clear-Host
$wc = New-Object System.Net.WebClient
$bytesReceived = 0
$total = $wc.DownloadFile($url, "$p\$o")
$timer = New-Object System.Timers.Timer -Property @{
  Interval  = 100
  AutoReset = $true
}

# Define the progress writer script block
$progressWriter = {
  $percentComplete = ($args[0].BytesReceived / $args[0].TotalBytesToReceive) * 100
  Write-Progress -Activity "Downloading $o" -Status 'Downloading' -PercentComplete $percentComplete
}

# Add event handler
$eventId = Register-ObjectEvent $wc DownloadProgressChanged -Action $progressWriter
$timer.Start()

# Wait for download to complete
while ($bytesReceived -lt $total) {
  $bytesReceived = $wc.BytesReceived
  Start-Sleep -Milliseconds 100
}

# Stop the timer and remove event handler
$timer.Stop()
Unregister-Event -SubscriptionId $eventId

if ($?) { Write-Main "File downloaded successfully" } else { Write-Warning "An error occurred while downloading the file" }
if ($open -eq $true) { Open-File }
Write-Point 'Do you want to download another app? (y/n)'
$repeat = Read-Host
if ($repeat -eq 'y' -or $repeat -eq 'Y') { Restart-App }