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
    'o' { Open-File }
    'e' { Write-Main 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
    default { Write-Warning 'Non-valid character, exiting...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Open-File {
  if ($o -like "*.zip") {
    if (Test-Path -Path "$p\$program\$folder") {
      Write-Main "$program is uncompressed in $p, so opening it directly..."
      Start-Sleep -Milliseconds 500
      Start-Process -FilePath "$p\$program\$folder\$exe" -ErrorAction SilentlyContinue
      Start-Sleep 1
      
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
      
    }
  }
  elseif ($o -like "*.exe") {
    Write-Main 'Exe file detected'

    # If there are any recommended parameters for the executable, asks for using them.
    if ($cmd) {
      Write-Point "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just launch it as normal)? (y/n)"
      $runcmd = Read-Host
      if ($runcmd -eq 'y' -or $runcmd -eq 'Y') {
      
        Write-Main "Running $program $($cmd_syn)"
        Start-Process -FilePath "$p\$o" -ArgumentList $($cmd) -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 200
      }
    }
    else {    
      Write-Main "Running $program directly"
      Start-Process -FilePath "$p\$o" -ErrorAction SilentlyContinue
      Start-Sleep -Milliseconds 200
    }
  }
  elseif ($o -like "*.msi") {
    Write-Main 'Microsoft installer detected'
    Write-Main "Installing $program passively"
    Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$p\$o`" /passive /promptrestart" -Wait
    Write-Main "$program successfully installed"
    Write-Point 'Do you want to launch it?(y/n)'
    $openInst = Read-Host
    if ($openInst -eq 'y' -or $openInst -eq 'Y') {
      Write-Main "Launching $program..."

      # Adapted from https://social.technet.microsoft.com/Forums/ie/en-US/1d50d2f7-f532-40b5-859e-d5cacab1f337/pull-a-msi-property-from-a-powershell-custom-object
      $windowsInstaller = New-Object -com WindowsInstaller.Installer
      $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", 'InvokeMethod', $Null, $windowsInstaller, @("$p\$o", 0))
      $query = "SELECT Value FROM Property WHERE Property='ProductName'"
      $view = $database.GetType().InvokeMember("OpenView", 'InvokeMethod', $Null, $database, ($query))
      $view.GetType().InvokeMember("Execute", 'InvokeMethod', $Null, $view, $Null)
      $record = $view.GetType().InvokeMember("Fetch", 'InvokeMethod', $Null, $view, $Null)
      $prod = $record.GetType().InvokeMember("StringData", 'GetProperty', $Null, $record, 1)
      $prod = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $prod }
      $Inst = $prod.InstallLocation
      Start-Process -FilePath "$Inst\$folder\$exe"
    }
  }
  elseif ($o -like "*.msix" -or $o -like "*.msixbundle" -or $o -like "*.appx" -or $o -like "*.appxbundle") {
    Write-Main 'Bundle Microsoft app detected'
    Add-AppPackage -Path "$p\$o"
  }
}
function Restart-App {
  Write-Main 'Leaving session...'
  powershell.exe -command "Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/app-dl.ps1" | Invoke-Expression"
}