function Write-Main($T) {
  $b = '============================================'
  Write-Host "`n`n<$b>" -ForegroundColor Blue
  Write-Host "   $T" -ForegroundColor White
  Write-Host "<$b>" -ForegroundColor Blue
}
function Write-Secondary($T) {
  $b = '=========='
  Write-Host "`n<$b[" -NoNewline -ForegroundColor Green
  Write-Host " $T " -NoNewline -ForegroundColor White
  Write-Host "]$b>`n" -ForegroundColor Green
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
function Read-FileSize() {
  Param ([int]$size)
  if ($size -gt 1GB) { [string]::Format("{0:0.00} GB", $size / 1GB) }
  elseIf ($size -gt 1MB) { [string]::Format("{0:0.00} MB", $size / 1MB) }
  elseIf ($size -gt 1KB) { [string]::Format("{0:0.00} kB", $size / 1KB) }
  elseIf ($size -gt 0) { [string]::Format("{0:0.00} B", $size) }
  else { "" }
}
function Select-App {
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
}
function Show-Details {
  $response = Invoke-WebRequest -Uri $url -Method Head
  $size = Read-FileSize ([long]$response.Headers.'Content-Length')
  Write-Point "$program is $syn"
  Write-Host $url
  Write-Point "Size: $size"
  if ($exe) { Write-Point "Executable: $exe" }
  if ($cmd_syn) { Write-Point $cmd_syn }
  if ($cmd) { Write-Point "Parameters are: $cmd)" }
}
function Show-Paths {
  Write-Main 'Path selecting'
  Write-Point '1. Saves it inside of Desktop'
  Write-Point '2. Saves it inside of Documents'
  Write-Point '3. Saves it inside of Downloads'
  Write-Point '4. Save it inside of C:'
  Write-Point '5. Saves it inside of Program Files'
  Write-Point "6. Save it inside of the user profile`n"
  Write-Point 'X. Introduce a custom path'
  Write-Point '0. Resets the program to select another app'
}
function Revoke-Path {

  Write-Warning 'It seems that $program is currently allocated in this path'
  $restart = Read-Host "You can (r)estart, (o)pen $program or (e)xit the app"
  switch ($restart) {
    'r' { Restart-App }
    'R' { Restart-App }
    'o' { Open-File }
    'O' { Open-File }
    'e' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    'E' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    default { Write-Warning 'Non-valid character, exiting...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Open-File {
  
  Write-Main "Launching $program..."

  if ($o -match 'zip') {
    if (Test-Path -Path "$p\$program\$folder") {
      Write-Main "$program is uncompressed in $p, so opening it directly..."
      Start-Sleep -Milliseconds 500
      Start-Process -FilePath "$p\$program\$folder\$exe"
      Start-Sleep 1
      Exit
    }

    elseif (Test-Path -LiteralPath "$p\$o") {
      Write-Main 'Zip file detected'
      Write-Secondary "$program is saved as a zip file, so uncompressing..."
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
      Start-Process -FilePath "$p\$program\$folder\$exe"
      Start-Sleep -Milliseconds 200
      Exit
    }
  }

  if ($o -match 'exe') {
    if ($null -ne $cmd) {
      Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just launch it as normal)? (y/n)"
      $runcmd = Read-Host
      if ($runcmd -eq 'y' -or $runcmd -eq 'Y') {
        
        Write-Main "Running $program $($cmd_syn)"
        Start-Process -FilePath "$p\$o" -ArgumentList $($cmd)
        Start-Sleep -Milliseconds 200
        Exit
      }
    }
    if ($runcmd -ne 'y' -or $runcmd -ne 'Y') {
      
      Write-Main "Running $program directly"
      Start-Process -FilePath "$p\$o"
      Start-Sleep -Milliseconds 200
      Exit
    }
  }
}
function Restart-App {
  powershell.exe -command "Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/app-dl.ps1" | Invoke-Expression"
}