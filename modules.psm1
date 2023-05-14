function Write-Main($t) {
  $b = '============================================'
  Write-Host "`n`n<$b>" -ForegroundColor Blue
  Write-Host "   $t" -ForegroundColor White
  Write-Host "<$b>" -ForegroundColor Blue
}
function Write-Point($t) {
  Write-Host '==> ' -NoNewline -ForegroundColor Green
  Write-Host "$t" -ForegroundColor White
}
function Write-Warning($t) {
  $b = '============================================'
  Write-Host "`n`n<$b>" -ForegroundColor Red
  Write-Host "   $t" -ForegroundColor White
  Write-Host "<$b>" -ForegroundColor Red
}
function Get-AppSize {
  if ($length -gt 1GB) { [string]::Format("{0:0.00} GB", $length / 1GB) }
  elseIf ($length -gt 1MB) { [string]::Format("{0:0.00} MB", $length / 1MB) }
  elseIf ($length -gt 1KB) { [string]::Format("{0:0.00} kB", $length / 1KB) }
  elseIf ($length -gt 0) { [string]::Format("{0:0.00} B", $length) }
}
function Revoke-Path {
  Write-Warning "It seems that $program is currently allocated in this path"
  $restart = Read-Host "You can (r)estart, (o)pen $program or (e)xit the app"
  switch ($restart) {
    'r' { Restart-App }
    'o' {
      # Opens the app
      Write-Main "Launching $program..."
      if ($o -like "*.zip") {
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
        break
      }      elseif ($o -like "*.exe") {
        Write-Main 'Exe file detected'
      
        # If there are any recommended parameters for the executable, asks for using them.
        if ($cmd) {
          $runcmd = Read-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just launch it as normal)? (y/n)"
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
        break
      }      elseif ($o -like "*.msi") {
        Write-Main 'Windows installer detected'
        Write-Main "Installing $program silently"
        msiexec.exe /i "$p\$o" /passive /norestart
        Start-Sleep -Milliseconds 200
        break
      }      elseif ($o -like "*.msix" -or $o -like "*.msixbundle" -or $o -like "*.appx" -or $o -like "*.appxbundle") {
        Write-Main 'Bundle Microsoft app detected'
        Add-AppPackage -Path "$p\$o"
      }
  }
    'e' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    default { Write-Warning 'Non-valid character, exiting...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Restart-App {
  Write-Main 'Leaving session...'
  Start-Sleep -Milliseconds 200
  powershell.exe -command "Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/app-dl.ps1" | Invoke-Expression"
}