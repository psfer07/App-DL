<#
.SYNOPSIS
    Easily grab and manage programs, choose apps from groups,
    control downloads, and set paths.

.DESCRIPTION
    This PowerShell script provides a user-friendly interface
    for downloading and managing various programs. It allows
    users to select applications from predefined categories,
    control the download process, and specify where the
    downloaded files should be saved.

    USAGE: app-dl.ps1 [PACKAGE] [PATH] [OTHER_FLAGS]
    Launch app-dl.ps1 -h OR app-dl.ps1 -help for more details

.PARAMETER App
  -App, -n
    Specifies the name of the application to be downloaded.

.PARAMETER Path
  -Path, -o
    Specifies the directory where the downloaded application
    will be saved.

    This parameter can also use key names with the most common
    folders such as 'desktop', 'documents', 'downloads', 'c',
    'appdl' (the temporal folder on AppData), 'programfiles'
    and 'userprofile'. The user can specify any other path if
    desired.

.PARAMETER Portable
  -Portable, -p
    Selects whether downloading the portable package or the
    installation one. Only accepts 'y' or 'n'.

.PARAMETER Launch
  -Launch, -l
    Specifies whether opening the app. Only accepts 'y' or 'n'.
    If not provided, the program will prompt the user for input.

.PARAMETER AutomaticInstallation
  -AutomaticInstallation, -a
    Tells the program to install the program without user's
    intervention, using the defaults provided by the installer. 
.PARAMETER NoVerbose
  -NoVerbose, -nv
    Ignore warnings and continues if no error is found.
.PARAMETER SelfDestruct
  -SelfDestruct, -d
    Removes the all the files created by the program, not the
    programs downloaded by the user unless they were downloaded
    in the 'appdl' folder.
#>

param (
  [Parameter(Position = 0)][Alias("n")][string]$App,
  [Parameter(Position = 1)][Alias("o")][string]$Path,
  [Parameter(Position = 2)][Alias("p")][string]$Portable = $null,
  [Parameter(Position = 3)][Alias("l")][string]$Launch   = $null,
  [Alias("a")] [switch]$AutomaticInstallation = $false,
  [Alias("nv")][switch]$NoVerbose            = $false,
  [Alias("d")] [switch]$SelfDestruct         = $false,
  [Alias("h")] [switch]$Help
)

if ($help)
{
  Get-Help -Name $PSCommandPath -detailed
  return
}
try
{
  # Bypass any execution policy
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
  $Host.UI.RawUI.BackGroundColor = 'Black'
  $Host.UI.RawUI.WindowTitle = 'App-DL'
  # Clear-Host
  
  function Start-Main
  {
    param (
      [Parameter(Position = 0)] [string]$App,
      [Parameter(Position = 1)] [string]$Path,
      [string]$Portable = $null,
      [string]$Launch = $null,
      [switch]$AutomaticInstallation = $false
    )
    
    $wc = New-Object System.Net.WebClient
    $branch = 'main'
    $repo_url= 'https://raw.githubusercontent.com/psfer07/App-DL'
    $tempFolder = Join-Path $Env:TEMP 'AppDL'
    $assets = Join-Path $tempFolder 'assets'
    
    if (!(Test-Path $assets -PathType Container))
    {
        New-Item -ItemType Directory -Path $assets -Force | Out-Null
    }
    foreach ($lib in 'apps.json','app-dl.psm1')
    {
        $wc.DownloadFile("$repo_url/$branch/$lib", "$assets\$lib")
    }
    Import-Module "$assets\app-dl.psm1" -DisableNameChecking -Force
    $json = Get-Content "$assets\apps.json" -Raw | ConvertFrom-Json

    if ($App)
    {
      # Extracts the exact name from the JSON using the app parameter
      foreach ($category in $json.PSobject.Properties) {
        $appsInCategory = $category.Value.PSobject.Properties.Name
        $matchedApp = $appsInCategory | Where-Object { $_ -ieq $App }
        
        if ($matchedApp)
        {
            $matchedAppKey = $matchedApp
            break
        }
      }
      if (-not $matchedAppKey)
      {

        if (!$NoVerbose)
        {
          Write-Warning "No app recognized, starting App-DL by default"
        }
        Start-Sleep 1
        Start-Main
      }
      $App = $matchedAppKey
    }
    else {
      while ($null -eq $appN -or $appN -eq 0)
      {
        $categories = $json.psobject.Properties.Name
        Clear-Host
        Write-Title 'Available categories'
        
        for ($i = 0; $i -lt $categories.Count; $i++)
        {
            Write-Subtitle "$($i+1). $($categories[$i])"
        }
        
        while ($categoryN -notmatch '^\d+$' -or `
              !([int]::TryParse($categoryN, [ref]$categoryN)) -or `
              $categoryN -lt 1 -or $categoryN -gt $categories.Count
              )
        {
            Write-Host
            Write-Point -NoNewLine
            $categoryN = Read-Host "Write the number of the category desired"
        }

        $category = $categories[$categoryN - 1]
        Clear-Host
        $programs = $json.$category.psobject.Properties
        Write-Title "Available apps in $($category.ToLower())"
        
        $i = 1

        foreach ($program in $programs)
        {
          $name = $program.Name
          $versions = $program.value.versions
          $details = $program.value.details
          if ($details -eq 'i')
          {
              $indicator = '(!)'
          }
          else {
              $indicator = '   '
          }
          $outputString = "$i. $name $indicator"
          $spaces = " " * (28 - $name.Length)
        
          if ($versions -match 'PI')
          {
            Write-Point $outputString -NoNewline
            Write-Host "$spaces[PORTABLE]" -NoNewLine -ForegroundColor Green
            Write-Host ' & ' -NoNewLine
            Write-Host '[INSTALLS] ' -ForegroundColor Red
          }
          elseif ($versions -match 'P')
          {
            Write-Point $outputString -NoNewline
            Write-Host "$spaces[PORTABLE]              " -ForegroundColor Green
          }
          elseif ($versions -match 'I')
          {
            Write-Point $outputString -NoNewline
            Write-Host "$spaces             [INSTALLS]" -ForegroundColor Red
          }
        
          $i++
        }
        
        Write-Subtitle '0. Return to categories'
        Write-Host '(!) --> Only manual installation supported'
        
        while ($appN -notmatch '^\d+$' -or `
               !([int]::TryParse($appN, [ref]$appN)) -or `
               $appN -lt 0 -or $appN -gt $($programs.Name).Count
               )
        {
          Write-Host
          Write-Point -NoNewLine
          $appN = Read-Host "Write the number of the app you want to get"
        }
      }
      $App = $programs.Name[$appN - 1]
    }
    
    $matchingProperties = $json.PSobject.Properties | Where-Object {
        $_.Value.PSObject.Properties.Name -ieq $App
    }
    $appCategory = $matchingProperties | Select-Object -ExpandProperty Name   
    $appProperties = $json.$appCategory.$App
    switch ($Portable)
    {
      y { $ver = 1 }
      n { $ver = 0 }
      default
      {
        if ($Portable)
        {

          if (!$NoVerbose)
          {
            Write-Warning "Non-valid entry for portable: $Portable"
          }
          Start-Sleep 1
        }
        if ($appProperties.versions -match 'PI')
        {
          Write-Title "$App also has a portable version"
          Write-Point "Write (Y)es or (N)o to select the portable version`n"
          
          while ($selectPortable -ne 'y' -and $selectPortable -ne 'n')
          {
            Write-Host
            Write-Point -NoNewLine
            $selectPortable = Read-Host 'y/n' 
          }
          switch ($selectPortable)
          {
            y { $ver = 1 }
            n { $ver = 0 }
          }
        }
      }
    }
    if ($appProperties.versions -cnotmatch 'PI' -and $Portable) {

      if (!$NoVerbose)
      {
        Write-Warning "$App does not support an alternative version"
      }
      Start-Sleep -Milliseconds 1500
      $ver = 0
    }
    
    Write-Title 'Importing data...'
    $properties = @(
        'app', 'url', 'folder', 'versions', 'exe',
        'details', 'size', 'syn', 'cmd', 'cmd_syn'
    )

    foreach ($property in $properties)
    {
      if ($appProperties.$property -is [array])
      {
          $value = $appProperties.$property[$ver]
      }
      else {
          $value = $appProperties.$property
      }
      
      if ($property -eq 'details' -and ($ver -eq 0 -or $ver -eq 1))
      {
          $value = $value.Substring($ver, 1)
      }
      New-Variable -Name $property -Value $value -ErrorAction SilentlyContinue
    }
    Write-Subtitle 'Verifying access to host...'
    $uri = [System.Uri]$url
    $reachable = Test-Connection -ComputerName $uri.Host -Count 1 `
                                 -ErrorAction SilentlyContinue

    if ($reachable) {
      $request = Invoke-WebRequest $uri -Method Head -UseBasicParsing
      $length = [int]$request.Headers['Content-Length']
    }
    else
    {
      Write-Point "Host is not reachable." -ForegroundColor Red
      Write-Host "This may be because the url may be invalid"
      Write-Host "or maybe it is just your internet connection."
      Start-Sleep 4
      Clear-Host
      Start-Main
    }
    $filesize = Get-AppSize $length
    Clear-Host
    if (!($matchedAppKey -and $Portable -and $Path -and $Launch))
    {
      if ($ver -eq 1) { Write-Title "$App (portable version)" }
      else { Write-Title $App }
      
      if ($size)
      {
        if ($ver -eq 0) { $pkgOinst = 'Installer' }
        else { $pkgOinst = 'Package' }
        Write-Point "$pkgOinst size: $filesize`n"
        Write-Point "Total app size: $size`n"
      }
      else {
          Write-Point "Total app size: $filesize`n"
      }
      Write-Point "This program is $syn`n"
      if ($cmd_syn)
      {
          Write-Point "You can open it $cmd_syn`n"
      }
    }

    $paths = @{
      'desktop' = @{
        route = "$Env:USERPROFILE\Desktop"
        aka   = 'Desktop'
      }

      'documents' = @{
        route = "$Env:USERPROFILE\Documents"
        aka   = 'Documents'
      }

      'downloads' = @{
        route = "$Env:USERPROFILE\Downloads"
        aka   = 'Downloads'
      }

      'c' = @{
        route = $Env:SystemDrive
        aka   = 'C:'
      }

      'programfiles' = @{
        route = $Env:ProgramFiles
        aka   = 'Program Files'
      } 

      'userprofile' = @{
        route = $Env:HOMEPATH
        aka   = 'the user profile'
      }

      'appdata' = @{
        route = "$Env:LOCALAPPDATA"
        aka   = "the local AppData folder`n"
      }

      'roaming' = @{
        route = "$Env:APPDATA"
        aka   = "the roaming folder`n"
      }

      'appdl' = @{
        route = "$tempFolder\Downloads"
        aka   = "App-DL's temp folder (opens the program automatically)`n"
      }
    }

    if ($Path) {
      $inputPath = $Path.ToLower()
      $p = $paths["$inputPath"]
      if (!(Test-Path $p) -and $Path -notlike 'appdl') {
      
        while (!(Test-Path $Path))
        {
          Write-Title -warn 'The provided path does not exist'
          Write-Host "Path: $p"
          Write-Point 'Do you want to (C)reate it now or use (A)nother path?'
          
          while ($newPath -ne 'c' -and $newPath -ne 'a')
          {
            Write-Host
            Write-Point -NoNewLine
            $newPath = Read-Host 'Write a letter' 
          }
          
          if ($newPath -eq 'c')
          {
              New-Item -ItemType Directory -Path $Path -Force
          }
          elseif ($newPath -eq 'a') { $Path = Read-Host 'Write the full path' }
        }
        
        $p = $Path
        $Path = 'a custom directory'
      }
      elseif ($Path -like 'appdl') { New-Item -ItemType $p -force | Out-Null }
      else { $Path = $inputPath }
    }
    else {
      Write-Title 'Path selecting'
    
      for ($i = 1; $i -le $paths.Length; $i++)
      { 
        Write-Point "$i. Save it in $($paths[$i-1].aka)" 
      }
    
      Write-Point 'X. Introduce a custom path'
      Write-Point "0. Resets the program to select another app`n"
    
      while ($pathN -notmatch '^\d+$' -or `
             $pathN -lt 0 -or `
             $pathN -gt $paths.Count -and `
             $pathN -ne 'x'
            )
      {
        Write-Host
        Write-Point -NoNewLine
        $pathN = Read-Host "Choose an option" 
      }
    
    switch ($pathN) {
        0 {
            Start-Main
        }
        1 {
            $p = "$Env:USERPROFILE\Desktop"
        }
        2 {
            $p = "$Env:USERPROFILE\Documents"
        }
        3 {
            $p = "$Env:USERPROFILE\Downloads"
        }
        4 {
            $p = $Env:SystemDrive
        }
        5 {
            $p = $Env:ProgramFiles
        }
        6 {
            $p = $Env:HOMEPATH
        }
        7 {
            $p = "$Env:APPDATA"
        }
        8 {
            $p = "$tempfolder\downloads"
            New-Item -ItemType Container -Path $p -Force | Out-Null
            $IsLaunched = $true
        }
        x {
            $p = Read-Host 'Set the whole custom path'
        }
    }
     
      $matchingPath = $paths.Keys | Where-Object {
          $paths[$_] -eq $p
      }
      if ($matchingPath) { $Path = $matchingPath }
      else {
        if (!(Test-Path $p)) {
        
          while (!(Test-Path $Path))
          {
            Write-Title -warn 'The provided path does not exist'
            Write-Host $Path
            Write-Subtitle 'Do you want to (C)reate it now or use (A)nother path?' -pad 50
            
            while ($newPath -ne 'c' -or $newPath -ne 'a')
            {
              Write-Host
              Write-Point -NoNewLine
              $newPath = Read-Host 'Write a letter' 
            }
            
            if ($newPath -eq 'c') { New-Item -ItemType Directory -Path $Path -Force }
            elseif ($newPath -eq 'a') { $Path = Read-Host 'Write the full path' }
          }
          
          $Path = 'a custom directory'
        }
      }
    }

    $o = $uri.Segments[-1]
    
    if ((Test-Path "$p\$o") -or `
       (Test-Path "$p\$App\$folder\$exe")
       )
    {
        $params = @{
            p                       = $p
            o                       = $o
            App                     = $App
            folder                  = $folder
            exe                     = $exe
            details                 = $details
            cmd                     = $cmd
            cmd_syn                 = $cmd_syn
            AutomaticInstallation   = $AutomaticInstallation
        }
        Revoke-Path @params
        break
    }
    
    if (!($matchedAppKey -and $Portable -and $Path -and $Launch))
    {
        Write-Subtitle "$App will be saved in $Path" -pad 70
    }
  
    switch ($Launch)
    {
      y { $IsLaunched = $true; $openString = ' and open' }
      n { $IsLaunched = $false; $openString = $null }
      default {
      
        if ($Launch)
        {

          if (!noverbose)
          {
            Write-Warning "Non-valid entry in open: $Launch"
            $Launch = "n"
          }
          Start-Sleep 1
        }
        
        Write-Host
        Write-Point 'Do you want to open the file when downloaded?'
        
        while ( $openAns -ne 'y' -and $openAns -ne 'n' )
        {
          Write-Host
          Write-Point -NoNewLine
          $openAns = Read-Host 'y/n' 
        }
        
        switch ($openAns)
        {
          'y' { $IsLaunched = $true }
          'n' { $IsLaunched = $false }
        }
      }
    }

    if (!($matchedAppKey -and $Portable -and $Path -and $Launch))
    {
      Write-Title "You are going to download$openString $App"
      $confirm = Read-Host "Confirmation press any key or 'r' to restart."
      if ($confirm -eq 'r') { Start-Main }
    }
    
    # Update progress bar
    $wc.DownloadFileAsync($uri, "$p\$o")
    
    while ($wc.IsBusy)
    {
      $downloadedOld = (Get-Item "$p\$o").Length
      Start-Sleep -Milliseconds 250
      
      $Downloaded = (Get-Item "$p\$o").Length
      $MBs = [Math]::Round(($downloaded - $DownloadedOld) * 4) / 1MB
      $percentage = [Math]::Round(($downloaded / $length) * 100)
      
      $downloadedMB = $downloaded / 1MB
      $totalLengthMB = $length / 1MB
      $formatString = "{0:N2} MB / {1:N2} MB at {2:N2} MB/s"
      $downloadedString = $formatString -f $downloadedMB, $totalLengthMB, $MBs
    
      Write-Progress -Activity "Downloading $App..." `
                     -Status "$downloadedString ($percentage%) complete" `
                     -PercentComplete $percentage
    }
    
    if ($IsLaunched -eq $true)
    {
        Clear-Host
        $params = @{
            p                       = $p
            o                       = $o
            app                     = $App
            folder                  = $folder
            exe                     = $exe
            details                 = $details
            cmd                     = $cmd
            cmd_syn                 = $cmd_syn
            AutomaticInstallation   = $AutomaticInstallation
        }
        Open-App @params    
    }
    
    Write-Subtitle 'Continue downloading?'
    $repeat = Read-Host '==> (y/n)'
    if ($repeat -eq 'y') { Clear-Host; Start-Main }
    else { Clear-Host; Exit }
    }
    
    $params = @{
        App                     = $App
        Path                    = $Path
        Portable                = $Portable
        Launch                  = $Launch
        AutomaticInstallation   = $AutomaticInstallation
    }
    Start-Main @params
}
finally {
    
  if ($SelfDestruct)
  {
    Remove-Item "$Env:TEMP\AppDL" -Recurse -Force | Out-Null
  }
}
