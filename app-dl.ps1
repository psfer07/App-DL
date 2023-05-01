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
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
  Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
  $pkg = Read-Host "`nWrite the number of the app you want to get"

# Assign the corresponding variables to the selected app
$pkg_n = [int]($pkg -replace "\.")
$selectedApp = $filteredApps[$pkg_n - 1]
$program = $selectedApp.Name
$exe = $selectedApp.Exe
$syn = $selectedApp.Syn
$folder = $selectedApp.folder
$url = $selectedApp.URL
$cmd = $selectedApp.Cmd
$cmd_syn = $selectedApp.Cmd_syn
$o = Split-Path $url -Leaf


Write-Main "$program selected"
if ($pkg -like ".*") {
  $response = Invoke-WebRequest -Uri $url -Method Head
  $size = Read-FileSize ([long]$response.Headers.'Content-Length'[0])
  
  Write-Point "$program is $syn"
  Write-Point "Size: $size"
  if ($exe) { Write-Point "Executable: $exe" }
  if ($cmd_syn) { Write-Point $cmd_syn }
  if ($cmd) { Write-Point "Parameters are: $cmd)" }
  Pause
  Clear-Host
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
  Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
$pkg = Read-Host "`nWrite the number of the app you want to get"
}

Write-Main "$program selected"

Clear-Host
Write-Main "Selected path: $p"


if (Test-Path "$p\$o") { Revoke-Path }
if (Test-Path "$p\$program\$folder\$exe") { Revoke-Path }

Write-Main "App to download: $program..."
Write-Secondary "Do you want to open when finished? (y/n)"
$open = Read-Host
do {$open = $false} while (!($open -eq 'y' -or $open -eq 'Y'))
if ($open -eq 'y' -or $open -eq 'Y') {$open = $true}
$dl = Read-Host 'Confirmation (press enter or any key to go to the (R)estart menu)'
if ($dl -eq 'R' -or $dl -eq 'r') { Restart-Menu }

try {
Invoke-WebRequest -URI $url -OutFile "$p\$o"
  Write-Secondary 'File downloaded successfully'
}
catch {Write-Warning "Failed to download package. Error: $($_.Exception.Message)"}

if ($open = $true) {
  Write-Main "Launching $program..."
  if ($o -like "*.zip") {
    if (Test-Path -eq "$p\$o") {
      Write-Main 'Zip file detected'
      Write-Secondary "$program is saved as a zip file, so uncompressing..."
      Start-Sleep -Milliseconds 200
      try {
        Expand-Archive -Path "$p\$o" -DestinationPath "$p\$program" -Force
        Write-Main 'Package succesfully extracted...'
      }
      catch { Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"; Pause }
      Start-Sleep -Milliseconds 500
      Exit
    }
    elseif (Test-Path -eq "$p\$program\$folder") {
      Start-Process -FilePath "$p\$program\$folder\$exe"
    }
  }
  if ($o -like "*.exe") {
    if ($null -ne $cmd) {
      Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just launch it as normal)? (y/n)"
      $runcmd = Read-Host
      if ($runcmd -eq 'y' -or $runcmd -eq 'Y') {
        Clear-Host
        Write-Main "Running $program $($cmd_syn)"
        Start-Process -FilePath "$p\$o" -ArgumentList $($cmd)
        Start-Sleep -Milliseconds 200
        Exit
      }
    }
    if ($runcmd -ne 'y' -or $runcmd -ne 'Y') {
      Clear-Host
      Write-Main "Running $program directly"
      Start-Process -FilePath "$p\$o"
      Start-Sleep -Milliseconds 200
      Exit
    }
  }
}