function Write-Title {
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [string]$t,

    [Parameter(Position = 1)]
    [int]$pad
  )
  if ($t.Length % 2 -ne 0, 1) { [string]$extra = 'o' }
  $b = "o" * (4 + $t.Length)
  Write-Host "`n`nooo$b$extra" -ForegroundColor DarkBlue
  Write-Host "oo$extra " -NoNewline -ForegroundColor DarkBlue
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " oo$extra" -ForegroundColor DarkBlue
  Write-Host "ooo$b$extra" -ForegroundColor DarkBlue
}
function Write-Subtitle {
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [string]$t,

    [Parameter(Position = 1)]
    [int]$pad = 40
  )
  if ($t.Length % 2 -ne 0) { [string]$extra = 'o' }
  $b = "o" * (($pad - $t.Length - 3) / 2)
  Write-Host "`n<$b " -NoNewline -ForegroundColor DarkBlue
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " $b$extra>" -ForegroundColor DarkBlue
}
function Write-Point {
  param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [string]$t,

    [Parameter(Position = 1)]
    [int]$pad = 2
  )

  $b = "=" * $pad
  Write-Host "$b> " -NoNewline -ForegroundColor Magenta
  Write-Host "$t" -NoNewline -ForegroundColor White
}
function Write-Warning {
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [string]$t,

    [Parameter(Position = 1)]
    [int]$pad
  )
  if ($t.Length % 2 -ne 0, 1) { [string]$extra = 'o' }
  $b = "o" * (4 + $t.Length)
  Write-Host "`n`nooo$b$extra" -ForegroundColor DarkRed
  Write-Host "oo$extra " -NoNewline -ForegroundColor DarkRed
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " oo$extra" -ForegroundColor DarkRed
  Write-Host "ooo$b$extra" -ForegroundColor DarkRed
}
function Get-AppSize {
  if ($length -gt 1GB) { [string]::Format("{0:0.00} GB", $length / 1GB) }
  elseIf ($length -gt 1MB) { [string]::Format("{0:0.00} MB", $length / 1MB) }
  elseIf ($length -gt 1KB) { [string]::Format("{0:0.00} kB", $length / 1KB) }
  elseIf ($length -gt 0) { [string]::Format("{0:0.00} B", $length) }
}
function Revoke-Path {
  Write-Warning "It seems that $program is currently allocated in this path"
  do { $reset = Read-Host "You can (r)estart, (o)pen, or (e)xit the app (OPEN default)" } while ($reset -ne 'r' -and $reset -ne 'o' -and $reset -ne 'e')

  switch ($reset) {
    'r' { Reset-App }
    'o' { Open-App }
    'e' { Write-Title 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Open-App {
  function Open-Extracted {
    if ($cmd) {
      Write-Point "There is a preset for running $program $($cmd_syn). Launch it with presets?" 
      do { $runcmd = Read-Host '==> (y/n)' } while ($runcmd -ne 'y' -and $runcmd -ne 'n')
      if ($runcmd -eq 'n') {
        Write-Title "Running $program..."
        Start-Process -FilePath "$p\$program\$folder\$exe" -ErrorAction SilentlyContinue
      }
      else {    
        Write-Title "Running $program $($cmd_syn)"
        Start-Process -FilePath "$p\$program\$folder\$exe" -ArgumentList $($cmd) -ErrorAction SilentlyContinue
      }
    }
    else {
      Write-Title "Running $program..."
      Start-Process -FilePath "$p\$program\$folder\$exe" -ErrorAction SilentlyContinue
    }
  }
  switch -Wildcard ($o) {
    "*.zip" {
      Write-Title "Zip file detected"
      if (Test-Path -Path "$p\$program\$folder") {
        Write-Title "$program is Available in $path, so opening..."
        Open-Extracted
      }
      # Expand and open the app
      elseif (Test-Path -LiteralPath "$p\$o") {
        Write-Title 'Zip file detected'
        Write-Point "$program is saved as a zip file, so uncompressing..."
        Expand-Archive -Literalpath "$p\$o" -DestinationPath "$p\$program" -Force
        if ($?) {
          Write-Title 'Package successfully extracted...'
        }
        else {
          Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"
          Read-Host "Press any key to continue..."
        }
        Write-Subtitle "Running $program directly"
        Open-Extracted
       
      }
    }
    "*.7z" {
      $wc = New-Object System.Net.WebClient
      $7z_libs = '7z.exe', '7z.dll'
      foreach ($7z_lib in $7z_libs) { $wc.DownloadFile("$repoURL/7z/$7z_lib", "$Env:TEMP\$7z_lib") }
      $wc.Dispose()
      $7z = "$assets\7z.exe"
      # $7z = '.\7z\7z.exe'
      if ($portapps) { $exe = "$program".ToLower() + '.exe' }
      Write-Title '7z file detected'
      if (Test-Path -Path "$p\$program\$folder") {
        Clear-Host
        Write-Title "$program is available in $path, so opening..."
        Open-Extracted
      
      }
      # Expand and open the app
      elseif (Test-Path -LiteralPath "$p\$o") {
        Write-Title '7z file detected'
        Write-Point "$program is saved as a 7z file, so uncompressing..."
        Start-Process $7z -ArgumentList "x `"$p\$o`" -o`"$p\$program`"" -Wait -NoNewWindow
        if ($?) {
          Write-Title 'Package successfully extracted...'
        }
        else {
          Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"
          Read-Host 'Press any key to continue...'
        }
        Clear-Host
        Open-Extracted
      }
    }
    "*.exe" {
      Write-Title 'Exe file detected'

      if ($cmd) { Write-Point "There is a preset for running $program $($cmd_syn). Launch it with that configuration?" }
      do { $runcmd = Read-Host '==> (y/n)' } while ($runcmd -ne 'y' -and $runcmd -ne 'n')
      if ($runcmd -eq 'n') {
        Write-Title "Running $program directly"
        Start-Process -FilePath "$p\$o" -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 200
      }
      else {    
        Write-Title "Running $program $($cmd_syn)"
        Write-Title "Wait until the installation finishes, be patient"
        Start-Process -FilePath "$p\$o" -ArgumentList $($cmd) -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 200
      }
    }
    "*.msi" {
      Write-Title 'Microsoft installer detected'
      Write-Title "Installing $program automatically"
      Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$p\$o`" /passive /promptrestart" -Wait
      Write-Title "$program successfully installed"
      Write-Point 'Do you want to launch it?(y/n)'
      $openInst = Read-Host
      if ($openInst -eq 'y' -or $openInst -eq 'Y') {
        Write-Title "Launching $program..."
        # Function to display a progress bar
        function Show-Progress {
          param (
            [int]$Current,
            [int]$Total
          )
          $PercentComplete = ($Current / $Total) * 100
          Write-Progress -Activity "Processing actions" -Status "Action $Current of $Total" -PercentComplete $PercentComplete
        }
        $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        Show-Progress -Current 1 -Total 6
        $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", 'InvokeMethod', $Null, $windowsInstaller, @("$p\$o", 0))
        Show-Progress -Current 2 -Total 6
        $view = $database.GetType().InvokeMember("OpenView", 'InvokeMethod', $Null, $database, ("SELECT Value FROM Property WHERE Property='ProductName'"))
        Show-Progress -Current 3 -Total 6
        $view.GetType().InvokeMember("Execute", 'InvokeMethod', $Null, $view, $Null)
        Show-Progress -Current 4 -Total 6
        $record = $view.GetType().InvokeMember("Fetch", 'InvokeMethod', $Null, $view, $Null)
        Show-Progress -Current 5 -Total 6
        $prod = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq ($record.GetType().InvokeMember("StringData", 'GetProperty', $Null, $record, 1)) }
        Show-Progress -Current 6 -Total 6
        Start-Process -FilePath "$($prod.InstallLocation)\$folder\$exe" -Wait
      }
    }
    default {
      if ($o -like "*.msix" -or $o -like "*.msixbundle" -or $o -like "*.appx" -or $o -like "*.appxbundle") {
        Write-Title 'Bundle Microsoft app detected'
        Add-AppPackage -Path "$p\$o"
      }
    }
  }
}
function Reset-App {
  Clear-Host
  Write-Title 'Leaving session...'
  # powershell.exe -command Invoke-Expression '.\app-dl.ps1'
  powershell.exe -command "Invoke-RestMethod '$repoURL/app-dl.ps1' | Invoke-Expression"
}