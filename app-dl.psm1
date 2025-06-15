function Write-Title
{
  param (
    [string]$t,
    [switch]$warn
  )
  
  if ($warn) { $bColor = "Red" } else { $bColor = "Blue" }
  if ($t.Length % 2 -ne 0, 1) { [string]$extra = 'o' }
  
  $b = "o" * (4 + $t.Length)
  Write-Host "`n`nooo$b$extra" -ForegroundColor $bColor
  Write-Host "oo$extra " -NoNewline -ForegroundColor $bColor
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " oo$extra" -ForegroundColor $bColor
  Write-Host "ooo$b$extra" -ForegroundColor $bColor
}


function Write-Subtitle
{
  param (
    [string]$t,
    [int]$pad = 40
  )
  
  if ($t.Length % 2 -ne 0) { [string]$extra = 'o' }
  
  $b = "o" * (($pad - $t.Length - 3) / 2)
  Write-Host "`n<$b " -NoNewline -ForegroundColor Blue
  Write-Host "$t" -NoNewline -ForegroundColor White
  Write-Host " $b$extra>" -ForegroundColor Blue
}


function Write-Point
{
  param(
    [string]$t,
    [string]$ForegroundColor = 'White',
    [switch]$NoNewLine = $false
  )
  
  if ($NoNewLine)
  {
    Write-Host '==> ' -NoNewline -ForegroundColor Magenta
    Write-Host "$t" -NoNewline -ForegroundColor $ForegroundColor
  }
  else
  {
    Write-Host '==> ' -NoNewline -ForegroundColor Magenta
    Write-Host "$t" -ForegroundColor $ForegroundColor
  }
}


function Get-AppSize($size)
{
  $suffixes = "B", "kB", "MB", "GB"
  for ($i = 0; $i -lt $suffixes.Length; $i++)
  {
    if ($size -lt 1024)
    {
      return [string]::Format("{0:0.00} {1}", $size, $suffixes[$i])
    }
    
    $size /= 1024
  }
  return [string]::Format("{0:0.00} {1}", $size, $suffixes[-1])
}


function Revoke-Path
{
  param (
    [string]$p,
    [string]$fileName,
    [string]$App,
    [string]$folder,
    [string]$exe,
    [string]$details,
    [string]$cmd,
    [string]$cmd_syn,
    [switch]$AutomaticInstallation
  )
  
  Write-Title -warn "It seems that $App is currently allocated in this path"
  
  while ($reset -ne 'r' -and $reset -ne 'o' -and $reset -ne 'e')
  {
    Write-Host
    Write-Point -NoNewLine
    $reset = Read-Host 'You can (r)estart, (o)pen, or (e)xit the app'
  }
  
  switch ($reset)
  {
    'r'
    {
      Start-Main
    }
    'o'
    {
      $params = @{
        p         = $p
        fileName  = $fileName
        app       = $App
        folder    = $folder
        exe       = $exe
        details   = $details
        cmd       = $cmd
        cmd_syn   = $cmd_syn
        usecmd    = $AutomaticInstallation
      }
      Open-App @params
    }
    'e'
    {
      Write-Title 'Closing this terminal...'
      Start-Sleep -Milliseconds 500
      exit
    }
  }
}


function Open-App
{
  param (
    [string]$p,
    [string]$fileName,
    [string]$App,
    [string]$folder,
    [string]$exe,
    [string]$details,
    [string]$cmd,
    [string]$cmd_syn,
    [switch]$Launch,
    [switch]$AutomaticInstallation
  )
  
  Start-Sleep -Milliseconds 100
  Clear-Host
  $folder = $ExecutionContext.InvokeCommand.ExpandString($folder)
  $cmd = $ExecutionContext.InvokeCommand.ExpandString($cmd)
  
  switch -Wildcard ($fileName)
  {
    "*.zip"
    {
      if (Test-Path -Path "$p\$App\$folder\$exe") { $openFlag = $true }
      
      if (Test-Path -Path "$p\$fileName")
      {
        Write-Title 'Zip file detected'
        Write-Point "$App is saved as a zip file, so uncompressing..."
        Expand-Archive -Literalpath "$p\$fileName" -DestinationPath "$p\$App" -Force
        $openFlag = $true
        
        if ($?) { Write-Title 'Package successfully extracted...' }
        else
        {
          Write-Warning 'Failed to extract package.'
          Write-Title -warn $_.Exception.Message
          Read-Host 'Press any key to continue...'
          exit 1
        }
      }
    }
    "*.exe"
    {
      Write-Title 'Exe file detected'
      Write-Subtitle 'Attempting to launch the program...' -pad 50
      
      if ($details -eq 'a') { $openFlag = $false }
      else
      {
        $openFlag = $true
        $isInstaller = "'s installer"
      }

      if ($AutomaticInstallation)
      {
        Write-Title "Running this program by $cmd_syn"
        Start-Process -FilePath "$p\$fileName" -ArgumentList $($cmd) `
                      -ErrorAction SilentlyContinue -Wait
      }
      else
      {
        if ($cmd)
        {
          Write-Point "This preset is available for this app: $cmd_syn" `
                      -NoNewLine
          Write-Point "Launch it with the preset?"
          
          while ($runcmd -ne 'y' -and $runcmd -ne 'n')
          {
            Write-Host
            Write-Point -NoNewLine
            $runcmd = Read-Host 'y/n' 
          }
          
          if ($runcmd -eq 'n')
          {
            Write-Title "Launching $App$isInstaller..."
            Start-Process -FilePath "$p\$fileName" `
                          -ErrorAction SilentlyContinue -Wait
          }
          else
          {
            Write-Title "Running this program by $cmd_syn"
            Start-Process -FilePath "$p\$fileName" -ArgumentList $($cmd) `
                          -ErrorAction SilentlyContinue -Wait
          }
        }
        else
        {
          Start-Process -FilePath "$p\$fileName" -ErrorAction SilentlyContinue
        }
      }
    }
    "*.msi"
    {
      Write-Title 'Microsoft installer detected'
      Write-Title "Installing $App automatically"
      
      if ($Launch) { Start-Process -FilePath "$folder\$exe" }
      else
      {
        Write-Point 'Do you want to launch it after installation?'
        while ($openInst -ne 'y' -and $openInst -ne 'n')
        {
          Write-Host
          Write-Point -NoNewLine
          $openInst = Read-Host 'y/n' 
        }
        
        Start-Process -FilePath msiexec.exe -Wait `
                      -ArgumentList "/i `"$p\$fileName`" /passive /promptrestart"
        Write-Title "$App successfully installed"
        
        if ($openInst -eq 'y') {
          Start-Process -FilePath "$folder\$exe"
        }
      }
      
      $openFlag = $true
    }
    default
    {
      Write-Title 'Bundle Microsoft app detected'
      Add-AppPackage -Path "$p\$fileName" -ForceApplicationShutdown -Confirm:$false
      $openFlag = $true
    }
  }
  
  if ($details -in @('b', 'i') -and $openFlag)
  { $exePath = "$folder\$exe" }
  else
  {
  
    if ($folder)
    {
      $exePath = "$p\$App\$folder\$exe"
    }
    else
    {
      $exePath = "$p\$App\$exe"
    }
  }
  Write-Point "App available in: $exePath"
  
  if ($Launch)
  {
    Start-Process -FilePath $exePath -ErrorAction SilentlyContinue
  }
}
