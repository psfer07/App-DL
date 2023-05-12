function Write-Main($T) {
  $b = '============================================'
  Write-Host "`n`n<$b>" -ForegroundColor Blue
  Write-Host "   $T" -ForegroundColor White
  Write-Host "<$b>" -ForegroundColor Blue
}
function Write-Point($T) {
  Write-Host '==> ' -NoNewline -ForegroundColor Green
  Write-Host "$T" -ForegroundColor White
}
function Write-Warning($T) {
  $b = '============================================'
  Write-Host "`n`n<$b>" -ForegroundColor Red
  Write-Host "   $T" -ForegroundColor White
  Write-Host "<$b>" -ForegroundColor Red
}
function Select-App {
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
}
function Read-FileSize {
  Param ([int]$length)
  if ($length -gt 1GB) { [string]::Format("{0:0.00} GB", $length / 1GB) }
  elseIf ($length -gt 1MB) { [string]::Format("{0:0.00} MB", $length / 1MB) }
  elseIf ($length -gt 1KB) { [string]::Format("{0:0.00} kB", $length / 1KB) }
  elseIf ($length -gt 0) { [string]::Format("{0:0.00} B", $length) }
}

function Show-Details {
  $request = Invoke-WebRequest $url -Method Head
  $length = [int]$request.Headers['Content-Length']
  $size = Read-FileSize $length
  Write-Main "$program selected"
  Write-Point "$program is $syn"
  Write-Point "Size: $size"
  if ($folder) { Write-Point "Saved in: $folder" }
  if ($exe) { Write-Point "Executable: $exe" }
  if ($cmd_syn) { Write-Point $cmd_syn }
  if ($cmd) { Write-Point "Parameters are: $cmd)" }
}
function Show-Paths {
  Write-Main 'Path selecting'
  Write-Point '1. Saves it inside of Desktop'
  Write-Point '2. Saves it inside of Documents'
  Write-Point '3. Saves it inside of Downloads'
  Write-Point '4. Saves it inside of C:'
  Write-Point '5. Saves it inside of Program Files'
  Write-Point "6. Saves it inside of the user profile`n"
  Write-Point 'X. Introduce a custom path'
  Write-Point '0. Resets the program to select another app'
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
}
function Revoke-Path {
  Write-Warning 'It seems that $program is currently allocated in this path'
  $restart = Read-Host "You can (r)estart, (o)pen $program or (e)xit the app"
  switch ($restart) {
    'r' { Restart-App }
    'o' { Open-File }
    'e' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    default { Write-Warning 'Non-valid character, exiting...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Open-File {
  # Opens the app
  Write-Main "Launching $program..."
  if ($o -like "*.zip") { Open-Zip }
  if ($o -like "*.exe") { Open-Exe }
  if ($o -like "*.msixbundle" -or "*.appxbundle" -or "*.msix" -or "*.appx") { Open-MSApp }
}
function Open-Zip {
  if (Test-Path -Path "$p\$program\$folder") {
    Write-Main "$program is uncompressed in $p, so opening it directly..."
    Start-Sleep -Milliseconds 500
    Start-Process -FilePath "$p\$program\$folder\$exe" -ErrorAction SilentlyContinue
    Start-Sleep 1
    Exit
  }
  # It uncompresses it and opens the app
  elseif (Test-Path -LiteralPath "$p\$o") {
    Write-Main 'Zip file detected'
    Write-Point "$program is saved as a zip file, so uncompressing..."
    Start-Sleep -Milliseconds 200
    Expand-Archive -Literalpath "$p\$o" -DestinationPath "$p\$program" -Force
    if ($?) {
      Write-Main 'Package successfully extracted...'
    }
    else {
      Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"
      Read-Host "Press any key to continue..."
    }
    Start-Sleep 2
    Clear-Host
    Write-Main "Running $program directly"
    Start-Sleep -Milliseconds 500
    Start-Process -FilePath "$p\$program\$folder\$exe" -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 200
    Exit
  }
}
function Open-Exe {
  Write-Main 'Exe file detected'
# If there are any recommended parameters for the executable, asks for using them.
if ($cmd) {
  Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just launch it as normal)? (y/n)"
  $runcmd = Read-Host
  if ($runcmd -eq 'y' -or $runcmd -eq 'Y') {
    
    Write-Main "Running $program $($cmd_syn)"
    Start-Process -FilePath "$p\$o" -ArgumentList $($cmd) -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 200
    Exit
  }
}
if ($runcmd -ne 'y' -or $runcmd -ne 'Y') {
  
  Write-Main "Running $program directly"
  Start-Process -FilePath "$p\$o" -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 200
  Exit
}
}
function Open-MSApp {
  Write-Main 'Bundle Microsoft app detected'
  Add-AppPackage -Path "$p\$o"
}
function Restart-App {
  powershell.exe -command "Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/app-dl.ps1" | Invoke-Expression"
}