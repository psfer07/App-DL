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
function Read-FileSize() {
  Param ([int]$size)
  if ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
  elseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
  elseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
  elseIf ($size -gt 0) {[string]::Format("{0:0.00} B", $size)}
  else {""}
  }
function Select-App {
  Write-Main 'Available apps'
  foreach ($i in 0..($filteredApps.Count - 1)) {
    $app = $filteredApps[$i]
    $n = $i + 1
    Write-Point "$n. $($app.Name)"
  }
  Write-Host "`nType a dot before the number to display all the program properties, for example: '.1'"
}
function Redo-AppSelection {
  $response = Invoke-WebRequest -Uri $url -Method Head
  $size = Read-FileSize ([long]$response.Headers.'Content-Length'[0])
  
  Write-Point "$program is $syn"
  Write-Point "Size: $size"
  if ($exe) { Write-Point "Executable: $exe" }
  if ($cmd_syn) { Write-Point $cmd_syn }
  if ($cmd) { Write-Point "Parameters are: $cmd)" }
  Pause
  Select-App
}
function Show-Paths {
  Write-Point '1. Saves it inside of Desktop'
  Write-Point '2. Saves it inside of Documents'
  Write-Point '3. Saves it inside of Downloads'
  Write-Point '4. Save it inside of C:'
  Write-Point '5. Saves it inside of Program Files'
  Write-Point "6. Save it inside of the user profile`n"
  Write-Point 'X. Introduce a custom path'
  Write-Point '0. Goes back to change the app'
}
function Read-Ext {

}
function Revoke-Path {
  
  Write-Warning 'It seems that $program is currently allocated in this path'
  $restart = Read-Host 'Write "r" to restart the app and start again, "o" to launch the existing app or e to exiting'
  switch ($restart) {
    'r' { Restart-Menu }
    'o' { Open-File }
    'e' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    default { Write-Warning 'Non-valid character, exiting...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Open-File {
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
function Restart-Menu {
  #Salir de la app / Volver al inicio
  Start-Process powershell.exe "-File `"$PSCommandPath`""
  Start-Sleep 1
  Exit
}