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
function Read-FileSize {
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [long]$sizeInBytes
  )
  
  $sizes = "B", "KB", "MB", "GB"
  $index = 0
  
  while ($sizeInBytes -ge 1024 -and $index -lt ($sizes.Count - 1)) {
    $sizeInBytes = $sizeInBytes / 1024
    $index++
  }
  return "{0:N2} {1}" -f $sizeInBytes, $sizes[$index]
}
function Select-App {
  Clear-Host
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
    Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
}
function Redo-AppSelection {
  if ($pkg -like ".*") {
    $response = Invoke-WebRequest -Uri $url -Method Head
    $size = Read-FileSize ([long]$response.Headers.'Content-Length'[0])
  
    Clear-Host
    Write-Main "$program selected"
    Write-Point "$program is $syn"
    Write-Point "Size: $size"
    if ($exe) { Write-Point "Executable: $exe" }
    if ($cmd_syn) { Write-Point $cmd_syn }
    if ($cmd) { Write-Point "Parameters are: $cmd)" }
    Pause
    Select-App
  }
}
function Select-Path {
  Clear-Host
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
    0 {  }
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
}
function Revoke-Path {
  Clear-Host
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
            Clear-Host
            Write-Main "Running $program $($cmd_syn)"
            Start-Process -FilePath "$p\$o" -ArgumentList $($cmd)
            Start-Sleep -Milliseconds 200
            Exit
          }
        }
        if ($runcmd -ne 'y', 'Y') {
          Clear-Host
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
function Restart-Menu {
  #Salir de la app / Volver al inicio
  Start-Process powershell.exe "-File `"$PSCommandPath`""
  Start-Sleep 1
  Exit
}