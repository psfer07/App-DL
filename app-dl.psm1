function Write-Title {
  param ([string]$t, [switch]$warn)
  if ($warn) { $bColor = "Red" } else { $bColor = "Blue" }
  if ($t.Length % 2 -ne 0, 1) { [string]$extra = 'o' }
  $b = "o" * (4 + $t.Length)
  Write-Host "`n`nooo$b$extra" -ForegroundColor $bColor
  Write-Host "oo$extra " -NoNewline -ForegroundColor $bColor
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " oo$extra" -ForegroundColor $bColor
  Write-Host "ooo$b$extra" -ForegroundColor $bColor
}
function Write-Subtitle {
  param ([string]$t, [int]$pad = 40)
  if ($t.Length % 2 -ne 0) { [string]$extra = 'o' }
  $b = "o" * (($pad - $t.Length - 3) / 2)
  Write-Host "`n<$b " -NoNewline -ForegroundColor Blue
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " $b$extra>" -ForegroundColor Blue
}
function Write-Point {
  param([string]$t, [string]$ForegroundColor = 'White', [switch]$NoNewLine = $false)
  if ($NoNewLine) {
    Write-Host '==> ' -NoNewline -ForegroundColor Magenta
    Write-Host "$t" -NoNewline -ForegroundColor $ForegroundColor
  }
  else {
    Write-Host '==> ' -NoNewline -ForegroundColor Magenta
    Write-Host "$t" -ForegroundColor $ForegroundColor
  }
}
function Get-AppSize($size) {
  $suffixes = "B", "kB", "MB", "GB"
  for ($i = 0; $i -lt $suffixes.Length; $i++) {
    if ($size -lt 1024) { return [string]::Format("{0:0.00} {1}", $size, $suffixes[$i]) }
    $size /= 1024
  }
  return [string]::Format("{0:0.00} {1}", $size, $suffixes[-1])
}
function Revoke-Path {
  param ([string]$p, [string]$o, [string]$app, [string]$folder, [string]$exe, [string]$details, [string]$cmd, [string]$cmd_syn, [switch]$launch)
  Write-Title -warn "It seems that $app is currently allocated in this path"
  do {
    Write-Host
    Write-Point -NoNewLine
    $reset = Read-Host 'You can (r)estart, (o)pen, or (e)xit the app'
  } while ($reset -ne 'r' -and $reset -ne 'o' -and $reset -ne 'e')
  switch ($reset) {
    'r' { Start-Main }
    'o' { Open-App -p $p -o $o -app $app -folder $folder -exe $exe -details $details -cmd $cmd -cmd_syn $cmd_syn -launch:$launch }
    'e' { Write-Title 'Closing this terminal...'; Start-Sleep -Milliseconds 500; exit }
  }
}
function Open-App {
  param ([string]$p, [string]$o, [string]$app, [string]$folder, [string]$exe, [string]$details, [string]$cmd, [string]$cmd_syn, [switch]$launch)
  function Open-Extracted {
    param ([string]$p, [string]$app, [string]$folder, [string]$exe, [string]$details, [string]$cmd, [string]$cmd_syn, [switch]$launch)
    Clear-Host
    $exePath = "$p\$app\$folder\$exe"
    if ($cmd) {
      Write-Point "There is a preset for running this program $cmd_syn. Launch it with presets?" 
      do {
        Write-Host; Write-Point -NoNewLine; $runcmd = Read-Host 'y/n' 
      } while ($runcmd -ne 'y' -and $runcmd -ne 'n')
      if ($runcmd -eq 'n') {
        Write-Title "Launching $app..."
        Start-Process -FilePath $exePath -ErrorAction SilentlyContinue
      }
      else {    
        Write-Title "Running this program $cmd_syn"
        Start-Process -FilePath $exePath -ArgumentList $($cmd) -ErrorAction SilentlyContinue
      }
    }
    else { Write-Host "Path is $exePath"; pause; Start-Process -FilePath "$exePath" -ErrorAction SilentlyContinue }
  }
  $folder = $ExecutionContext.InvokeCommand.ExpandString($folder)
  $cmd = $ExecutionContext.InvokeCommand.ExpandString($cmd)
  switch -Wildcard ($o) {
    "*.zip" {
      if (Test-Path -Path "$p\$app\$folder\$exe") {
        Write-Title "$app is Available in $path, so opening..."
        Open-Extracted -p $p -app $app -folder $folder -exe $exe -details $details -cmd $cmd -cmd_syn $cmd_syn -launch:$launch
      }
      if (Test-Path -LiteralPath "$p\$o") {
        Write-Title 'Zip file detected'
        Write-Point "$app is saved as a zip file, so uncompressing..."
        Expand-Archive -Literalpath "$p\$o" -DestinationPath "$p\$app" -Force
        if ($?) { Write-Title 'Package successfully extracted...' }
        else {
          Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"
          Read-Host "Press any key to continue..."
        }
      }
    }
    "*.7z" {
      foreach ($lib in '7z.exe', '7z.dll') { $wc.DownloadFile("https://raw.githubusercontent.com/psfer07/App-DL/$branch/7z/$lib", "$Env:TEMP\$lib") }
      $wc.Dispose()
      if ($details -eq 'portapps') { $exe = $app.ToLower() + '-portable.exe' }
      Write-Title '7z file detected'
      if (Test-Path -Path "$p\$app\$folder\$exe") {
        Write-Title "$app is available in $path, so opening..."
        Open-Extracted -p $p -app $app -folder $folder -exe $exe -details $details -cmd $cmd -cmd_syn $cmd_syn -launch:$launch
      }
      elseif (Test-Path -Path "$p\$o") {
        Write-Point "$app is saved as a 7z file, so uncompressing..."
        Start-Process <# "$assets\7z.exe" #> '.\7z\7z.exe' -ArgumentList "x `"$p\$o`" -o`"$p\$app`"" -Wait -NoNewWindow
        if ($?) { Write-Title 'Package successfully extracted...' }
        else {
          Write-Warning "Failed to extract package. $($_.Exception)"
          Read-Host 'Press any key to continue...'
        }
      }
    }
    "*.exe" {
      Write-Title 'Exe file detected'
      Write-Subtitle 'Attempting to launch the program...' -pad 50
      if ($cmd) {
        Write-Point "There is a preset for running this program $cmd_syn. Launch it with presets?" 
        do {
          Write-Host; Write-Point -NoNewLine; $runcmd = Read-Host 'y/n' 
        } while ($runcmd -ne 'y' -and $runcmd -ne 'n')
        $exePath = "$p\$app\$folder\$exe"
        if ($runcmd -eq 'n') {
          Write-Title "Launching $app..."
          Start-Process -FilePath $exePath -ErrorAction SilentlyContinue
        }
        else {    
          Write-Title "Running this program $cmd_syn"
          Start-Process -FilePath $exePath -ArgumentList $($cmd) -ErrorAction SilentlyContinue
        }
      }
      else { Start-Process -FilePath $exePath -ErrorAction SilentlyContinue }
    }
    "*.msi" {
      Write-Title 'Microsoft installer detected'
      Write-Title "Installing $app automatically"
      Write-Point 'Do you want to launch it after installation?'
      Write-Host $details
      pause
      do {
        Write-Host
        Write-Point -NoNewLine
        $openInst = Read-Host 'y/n' 
      } while ($openInst -ne 'y' -and $openInst -ne 'n')
      Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$p\$o`" /passive /promptrestart" -Wait
      Write-Title "$app successfully installed"
      if ($openInst -eq 'y') {
        $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", 'InvokeMethod', $Null, $windowsInstaller, @("$p\$o", 0))
        $view = $database.GetType().InvokeMember("OpenView", 'InvokeMethod', $Null, $database, ("SELECT Value FROM Property WHERE Property='ProductName'"))
        $view.GetType().InvokeMember("Execute", 'InvokeMethod', $Null, $view, $Null)
        $record = $view.GetType().InvokeMember("Fetch", 'InvokeMethod', $Null, $view, $Null)
        $prod = $record.GetType().InvokeMember("StringData", 'GetProperty', $Null, $record, 1)
        Start-Process -FilePath "$($prod.InstallLocation)\$folder\$exe"
      }
    }
    default {
      Write-Title 'Bundle Microsoft app detected'
      Add-AppPackage -Path "$p\$o" -ForceApplicationShutdown -Confirm:$false
    }
  }
  Write-Subtitle "Launching $app..."
  Open-Extracted -p $p -app $app -folder $folder -exe $exe -details $details -cmd $cmd -cmd_syn $cmd_syn -launch:$launch
}