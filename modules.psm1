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