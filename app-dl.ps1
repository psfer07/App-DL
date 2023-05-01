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

Select-App
Set-AppData
Get-AppDetails
Select-Path

#Checks if the program is installed or uncompressed in the selected folder
if (Test-Path "$p\$o") { Revoke-Path }
if (Test-Path "$p\$program\$folder\$exe") { Revoke-Path }

Write-Main "App to download: $program..."
$d = Read-Host 'Confirmation (press enter or any key to go to the (R)estart menu)'
if ($d -eq 'R' -or $d -eq 'r') { Restart-Menu }

Invoke-WebRequest -URI $url -OutFile "$p\$output"
if ($?) {
    Write-Secondary "File downloaded successfully"
} else {
    Write-Warning "An error occurred while downloading the file: $_.Exception"
  }

# Checks the package extension for extracting or installing it
if ($o -like "*.zip") {
  $e = Read-Host 'Do you want to unzip the package?(y/n)'
  if ($e -eq 'y' -or 'Y') {
    try {
      Expand-Archive -Path "$p\$o" -DestinationPath "$p\$program" -Force
      Write-Main 'Package succesfully extracted...'
    }
    catch { Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"; Pause }
  }
  if ($e -ne 'y' -or $e -ne 'Y') {
    Write-Main 'Leaving session...'
    Start-Sleep 1
    Exit
  }

  $open = Read-Host 'Open the app?(y/n)'
  if ($open -eq 'y' -or $open -eq 'Y') { Start-Process -FilePath "$p\$program\$folder\$exe" }
}
if ($o -like "*.exe") {
  if ($cmd) {
    Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just open it as normal)? (y/n)"
    $runcmd = Read-Host
    if ($runcmd -eq 'y' -or $runcmd -eq 'Y') {
      Clear-Host
      Write-Main "Running $program $($cmd_syn)"
      Start-Process -FilePath "$p\$o" -ArgumentList $($cmd)
    }
    if ($runcmd -ne 'y' -or $runcmd -ne 'Y') {
      Clear-Host
      Write-Main "Running $program directly"
      Start-Process -FilePath "$p\$o"
    }
  }
}