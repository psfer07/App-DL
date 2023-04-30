[string]$branch = 'dev'

#Clear-Host

function Write-Main($Text) {
  $border = '============================================'
  Write-Host "`n`n<$border>" -ForegroundColor Blue
  Write-Host "   $Text" -ForegroundColor White
  Write-Host "<$border>" -ForegroundColor Blue
}
function Write-Secondary($Text) {
  Write-Host "`n<==========[" -NoNewline -ForegroundColor Green
  Write-Host " $Text " -NoNewline -ForegroundColor White
  Write-Host "]==========>`n" -ForegroundColor Green
}
function Write-Point($Text) {
  Write-Host '==> ' -NoNewline -ForegroundColor Green
  Write-Host "$Text" -ForegroundColor White
}
function Write-Warning($Text) {
  $border = '============================================'
  Write-Host "`n`n<$border>" -ForegroundColor Red
  Write-Host "   $Text" -ForegroundColor White
  Write-Host "<$border>" -ForegroundColor Red
}
function Use-Path {
  #Clear-Host
  Write-Warning 'It seems that $program is currently allocated in this path'
  $restart = Read-Host 'Write "r" to restart the app and start again, "o" to open the existing app or e to exiting'
  switch ($restart) {
    'r' { Restart }
    'o' {
      Write-Main "Opening $program..."
      if ($o -like "*.zip") {
        if (Test-Path -eq "$p\$o") {
          Write-Main 'Zip file detected'
          Write-Secondary "$program is saved as a zip file, so uncompressing..."
          Start-Sleep -Milliseconds 200
          Expand-Archive -Path "$p\$o" -DestinationPath "$p\$program" -Force
          Write-Main 'Package succesfully extracted...'
          Start-Sleep -Milliseconds 500
          Exit
        }
        elseif (Test-Path -eq "$p\$program\$folder") {
          Start-Process -FilePath "$p\$program\$folder\$exe"
        }
      }
      if ($o -like "*.exe") {
        if ($null -ne $cmd) {
          Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just open it as normal)? (y/n)"
          $runcmd = Read-Host
          if ($runcmd -eq 'y', 'Y') {
            #Clear-Host
            Write-Main "Running $program $($cmd_syn)"
            Start-Process -FilePath "$p\$o" -ArgumentList $($cmd)
            Start-Sleep -Milliseconds 200
            Exit
          }
        }
        if ($runcmd -ne 'y', 'Y') {
          #Clear-Host
          Write-Main "Running $program directly"
          Start-Process -FilePath "$p\$o"
          Start-Sleep -Milliseconds 200
          Exit
        }
      }
    }
    'e' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    default { Write-Warning 'Non-valid character, exiting...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Get-FileSize() {
  param ([int]$size)
  if ($size -gt 1GB) { [string]::Format("{0:0.00} TB", $size / 1GB) }
  elseif ($size -gt 1MB) { [string]::Format("{0:0.00} MB", $size / 1MB) }
  elseif ($size -gt 1KB) { [string]::Format("{0:0.00} KB", $size / 1KB) }
  elseif ($size -gt 0) { [string]::Format("{0:0.00} B", $size) }
}
function Restart {
  Start-Process powershell.exe "-File `"$PSCommandPath`""
  Start-Sleep 1
  Exit
}
function Show-Apps {
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
}
function Show-Details {
  Write-Main "$program selected"
  Write-Point "$program is $syn"
  Write-Point "Size: $size"
  if ($exe) { Write-Point "Executable: $exe" }
  if ($cmd_syn) { Write-Point $cmd_syn }
  if ($cmd) { Write-Point "Parameters are: $cmd)" }
}


#Initializes variables
$json = Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/apps.json"
$nameArray = $json.psobject.Properties.Name
$filteredApps = @()
foreach ($i in 0..($nameArray.Count - 1)) {
  $name = $nameArray[$i]; $app = $json.$name; $folder = $app.folder; $url = $app.URL; $exe = $app.exe; $syn = $app.syn; $cmd = $app.cmd; $cmd_syn = $app.cmd_syn
  $filteredApps += [PsCustomObject]@{Index = $i; Name = $name; Folder = $folder; URL = $url; Exe = $exe; Size = $size; Syn = $syn; Cmd = $cmd; Cmd_syn = $cmd_syn }
}

#Clear-Host
Show-Apps

Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
$pkg = Read-Host "`nWrite the number of the app you want to get"
$pkg_n = [int]($pkg -replace "\.")

# Assign the corresponding variables to the selected app
$program = $filteredApps[$pkg_n - 1].Name
$exe = $filteredApps[$pkg_n - 1].Exe
$folder = $filteredApps[$pkg_n - 1].folder
$url = $filteredApps[$pkg_n - 1].URL
$cmd = $filteredApps[$pkg_n - 1].Cmd
$cmd_syn = $filteredApps[$pkg_n - 1].Cmd_syn
$o = Split-Path $url -Leaf


if ($pkg -like ".*") {
  $program = $filteredApps[$pkg_n - 1].Name
  $response = Invoke-WebRequest $url
  $size = Get-FileSize $($response.Content.Length)
  #Clear-Host
  Show-Details
  Pause
  Show-Apps
  Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
  $pkg = Read-Host "`nWrite the number of the app you want to get"
}

Write-Main "$program selected"

# Saving path selection
Write-Point '1. Saves it inside of Desktop'
Write-Point '2. Saves it inside of Documents'
Write-Point '3. Saves it inside of Downloads'
Write-Point '4. Save it inside of C:'
Write-Point '5. Saves it inside of Program Files'
Write-Point "6. Save it inside of the user profile`n"
Write-Point 'X. Introduce a custom path'
Write-Point '0. Goes back to change the app'
[string]$p = Read-Host "`nChoose a number"

switch ($p) {
  0 {
    #Clear-Host
    Show-Apps
    Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
    $pkg = Read-Host "`nWrite the number of the app you want to get"
    #Clear-Host
    Show-Details
  }
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


#Clear-Host
Write-Main "Selected path: $p"

#Checks if the program is installed or uncompressed in the selected folder
if (Test-Path "$p\$o") { Use-Path }
if (Test-Path "$p\$program\$folder\$exe") { Use-Path }

Write-Main "App to download: $program..."
$d = Read-Host 'Confirmation (press enter or any key to go to the (R)estart menu)'
if ($d -eq 'R' -or $d -eq 'r') { Restart }

Invoke-WebRequest -URI $url -OutFile "$p\$o"
if ($?) {
  Write-Secondary 'File downloaded successfully'
}
else {
  Write-Warning "Failed to download package. Error: $($_.Exception.Message)"
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
  if ($null -ne $cmd) {
    Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just open it as normal)? (y/n)"
    $runcmd = Read-Host
    if ($runcmd -eq 'y' -or $runcmd -eq 'Y') {
      #Clear-Host
      Write-Main "Running $program $($cmd_syn)"
      Start-Process -FilePath "$p\$o" -ArgumentList $($cmd)
    }
    if ($runcmd -ne 'y' -or $runcmd -ne 'Y') {
      #Clear-Host
      Write-Main "Running $program directly"
      Start-Process -FilePath "$p\$o"
    }
  }
}