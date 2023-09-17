param (
  [Parameter(Position = 0)] [string]$app,
  [Parameter(Position = 1)] [string]$path,
  [string]$portable = $null,
  [string]$open = $null,
  [switch]$launch
)
try {
  # Bypass any execution policy
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
  $Host.UI.RawUI.BackGroundColor = 'Black'
  $Host.UI.RawUI.WindowTitle = 'App-DL'
  Clear-Host
  function Start-Main {
    param (
      [Parameter(Position = 0)] [string]$app,
      [Parameter(Position = 1)] [string]$path,
      [string]$portable = $null,
      [string]$open = $null,
      [switch]$launch
    )
    $wc = New-Object System.Net.WebClient
    $branch = 'dev'
    $tempFolder = Join-Path $Env:TEMP 'AppDL'
    $assets = Join-Path $tempFolder 'assets'
    if (!(Test-Path $assets -PathType Container)) { New-Item -ItemType Directory -Path $assets -Force | Out-Null }
    foreach ($lib in 'apps.json', 'app-dl.psm1') { $wc.DownloadFile("https://raw.githubusercontent.com/psfer07/App-DL/$branch/$lib", "$assets\$lib") }
    Import-Module <# "$assets\app-dl.psm1" #> '.\app-dl.psm1' -DisableNameChecking -Force
    $json = Get-Content <# "$assets\apps.json" #> '.\apps.json' -Raw | ConvertFrom-Json

    if ($app) {
      # Extracts the exact name from the JSON using the app parameter
      foreach ($category in $json.PSobject.Properties) {
        $appsInCategory = $category.Value.PSobject.Properties.Name
        $matchedApp = $appsInCategory | Where-Object { $_ -ieq $app }
        if ($matchedApp) { $matchedAppKey = $matchedApp; break }
      }
      if (-not $matchedAppKey) {
        Write-Warning "No app recognized, starting App-DL by default"
        Start-Sleep 1
        Start-Main
      }
      $app = $matchedAppKey
    }
    else {
      do {
        $categories = $json.psobject.Properties.Name
        Clear-Host
        Write-Title 'Available categories' 
        for ($i = 0; $i -lt $categories.Count; $i++) { Write-Subtitle "$($i+1). $($categories[$i])" }
        do {
          Write-Host
          Write-Point -NoNewLine
          $categoryN = Read-Host "Write the number of the category you want to see"
        } while ($categoryN -notmatch '^\d+$' -or !([int]::TryParse($categoryN, [ref]$categoryN)) -or $categoryN -lt 1 -or $categoryN -gt $categories.Count)
        $category = $categories[$categoryN - 1]
        Clear-Host
        $programs = $json.$category.psobject.Properties
        Write-Title "Available apps in $($category.ToLower())"
        
        $i = 1

        foreach ($program in $programs) {
          $name = $program.Name
          $versions = $program.value.versions
          $details = $program.value.details
          if ($details -eq 'i') { $indicator = '(!)' } else { $indicator = '   ' }
          $outputString = "$i. $name $indicator"
          $spaces = " " * (28 - $name.Length)
        
          if ($versions -match 'PI') {
            Write-Point $outputString -NoNewline
            Write-Host "$spaces[PORTABLE]" -NoNewLine -ForegroundColor Green
            Write-Host ' & ' -NoNewLine
            Write-Host '[INSTALLS] ' -ForegroundColor Red
          }
          elseif ($versions -match 'P') {
            Write-Point $outputString -NoNewline
            Write-Host "$spaces[PORTABLE]              " -ForegroundColor Green
          }
          elseif ($versions -match 'I') {
            Write-Point $outputString -NoNewline
            Write-Host "$spaces             [INSTALLS]" -ForegroundColor Red
          }
        
          $i++
        }
        
        Write-Subtitle '0. Return to categories'
        Write-Host '(!) --> Only manual installation supported'
        
        do {
          Write-Host
          Write-Point -NoNewLine
          $appN = Read-Host "Write the number of the app you want to get"
        } while ($appN -notmatch '^\d+$' -or !([int]::TryParse($appN, [ref]$appN)) -or $appN -lt 0 -or $appN -gt $($programs.Name).Count)
      } while ($null -eq $appN -or $appN -eq 0)
      $app = $programs.Name[$appN - 1]
    }
    $appCategory = $json.PSobject.Properties | Where-Object { $_.Value.PSObject.Properties.Name -ieq $app } | Select-Object -ExpandProperty Name
    $appProperties = $json.$appCategory.$app
    switch ($portable) {
      y { $ver = 1 }
      n { $ver = 0 }
      default {
        if ($portable) {
          Write-Warning "Non-valid entry for portable: $portable"
          Start-Sleep 1
        }
        if ($appProperties.versions -match 'PI') {
          Write-Title "$app also has a portable version"
          Write-Point "Write (Y)es or (N)o to select the portable version`n"
          do {
            Write-Host
            Write-Point -NoNewLine
            $selectPortable = Read-Host 'y/n' 
          } while ($selectPortable -ne 'y' -and $selectPortable -ne 'n')
          switch ($selectPortable) {
            y { $ver = 1 }
            n { $ver = 0 }
          }
        }
      }
    }
    if ($appProperties.versions -cnotmatch 'PI' -and $portable) {
      Write-Warning "$app does not support an alternative version"
      Start-Sleep -Milliseconds 1500
    }
    
    Write-Title 'Importing data...'
    $properties = 'app', 'url', 'folder', 'versions', 'exe', 'details', 'size', 'syn', 'cmd', 'cmd_syn'
    foreach ($property in $properties) {
      if ($appProperties.$property -is [array]) { $value = $appProperties.$property[$ver] } else { $value = $appProperties.$property }
      if ($property -eq 'details' -and ($ver -eq 0 -or $ver -eq 1)) { $value = $value.Substring($ver, 1) }
      New-Variable -Name $property -Value $value -ErrorAction SilentlyContinue
    }
    Write-Subtitle 'Verifying access to host...'
    $uri = [System.Uri]$url
    $reachable = Test-Connection -ComputerName $uri.Host -Count 1 -ErrorAction SilentlyContinue

    if ($reachable) {
      $request = Invoke-WebRequest $uri -Method Head -UseBasicParsing
      $length = [int]$request.Headers['Content-Length']
    }
    else {
      Write-Warning "Host is not reachable. Please check your network connection or contact the developer."
      Start-Sleep 4
      Clear-Host
      Start-Main
    }
    $filesize = Get-AppSize $length
    Clear-Host
    if (!($matchedAppKey -and $portable -and $path -and $open)) {
      if ($ver -eq 1) { Write-Title "$app (portable version)" } else { Write-Title $app }
      if ($size) {
        if ($ver -eq 0) { $pkgOinst = 'Installer' } else { $pkgOinst = 'Package' }
        Write-Point "$pkgOinst size: $filesize`n"
        Write-Point "Total app size: $size`n"
      }
      else { Write-Point "Total app size: $filesize`n" }
      Write-Point "This program is $syn`n"
      if ($cmd_syn) { Write-Point "You can open it $cmd_syn`n" }
    }

    $paths = @{
      'desktop'       = "$Env:USERPROFILE\Desktop" 
      'documents'     = "$Env:USERPROFILE\Documents"
      'downloads'     = "$Env:USERPROFILE\Downloads"
      'c'             = $Env:SystemDrive
      'programfiles'  = $Env:ProgramFiles
      'program files' = $Env:ProgramFiles
      'userprofile'   = $Env:HOMEPATH
      'user profile'  = $Env:HOMEPATH
      'appdl'         = "$tempFolder\Downloads"
    }
    if ($path) {
      $inputPath = $path.ToLower()
      $p = $paths["$inputPath"]
      if (!(Test-Path $p) -and $path -notlike 'appdl') {
        do {
          Write-Title -warn 'The provided path does not exist'
          Write-Host "Path: $p"
          Write-Point 'Do you want to (C)reate it now or use (A)nother path?'
          do {
            Write-Host
            Write-Point -NoNewLine
            $newPath = Read-Host 'Write a letter' 
          } while ($newPath -ne 'c' -and $newPath -ne 'a')
          if ($newPath -eq 'c') { New-Item -ItemType Directory -Path $path -Force }
          elseif ($newPath -eq 'a') { $path = Read-Host 'Write the full path' }
        } while ((Test-Path $path) -ne $true)
        $p = $path
        $path = 'a custom directory'
      }
      elseif ($path -like 'appdl') { New-Item -ItemType $p -force | Out-Null }
      else { $path = $inputPath }
    }
    else {
      Write-Title 'Path selecting'
      [string]$s = 'Save it'
      $pathOptions = @("$s in Desktop", "$s in Documents", "$s in Downloads", "$s in C:", "$s in Program Files", "$s in the user profile", "$s in the roaming folder`n", "$s in App-DL's temp folder (opens the program automatically)`n")
    
      for ($i = 1; $i -le $pathOptions.Length; $i++) { 
        Write-Point "$i. $($pathOptions[$i-1])" 
      }
    
      Write-Point 'X. Introduce a custom path'
      Write-Point "0. Resets the program to select another app`n"
    
      do {
        Write-Host
        Write-Point -NoNewLine
        $pathN = Read-Host "Choose an option" 
      } while ($pathN -notmatch '^\d+$' -or $pathN -lt 0 -or $pathN -gt $pathOptions.Count -and $pathN -ne 'x')
    
      switch ($pathN) {
        0 { Start-Main }
        1 { $p = "$Env:USERPROFILE\Desktop"; break }
        2 { $p = "$Env:USERPROFILE\Documents"; break }
        3 { $p = "$Env:USERPROFILE\Downloads"; break }
        4 { $p = $Env:SystemDrive; break }
        5 { $p = $Env:ProgramFiles; break }
        6 { $p = $Env:HOMEPATH; break }
        7 { $p = "$Env:APPDATA\roaming"; break }
        8 { $p = "$tempfolder\downloads"; New-Item -ItemType Container -Path $p -Force | Out-Null; $opens = $true; break }
        x { $p = Read-Host 'Set the whole custom path'; break }
      }
      $matchingPath = $paths.Keys | Where-Object { $paths[$_] -eq $p }
      if ($matchingPath) { $path = $matchingPath }
      else {
        if (!(Test-Path $p)) {
          do {
            Write-Title -warn 'The provided path does not exist'
            Write-Host $path
            Write-Subtitle 'Do you want to (C)reate it now or use (A)nother path?' -pad 50
            do {
              Write-Host
              Write-Point -NoNewLine
              $newPath = Read-Host 'Write a letter' 
            } while ($newPath -ne 'c' -or $newPath -ne 'a')
            if ($newPath -eq 'c') { New-Item -ItemType Directory -Path $path -Force }
            elseif ($newPath -eq 'a') { $path = Read-Host 'Write the full path' }
          } while ((!(Test-Path $path)))
          $path = 'a custom directory'
        }
      }
    }

    $o = $uri.Segments[-1]
    if ((Test-Path "$p\$o") -or (Test-Path "$p\$app\$folder\$exe")) { Revoke-Path -p $p -o $o -app $app -folder $folder -exe $exe -details $details -cmd $cmd -cmd_syn $cmd_syn -launch:$launch; break }
    if (!($matchedAppKey -and $portable -and $path -and $open)) { Write-Subtitle "$app will be saved in $path" -pad 70 }
  
    switch ($open) {
      y { $opens = $true; $openString = ' and open' }
      n { $opens = $false; $openString = $null }
      default {
        if ($open) {
          Write-Warning "Non-valid entry in open: $open"
          Start-Sleep 1
        }
        Write-Host
        Write-Point 'Do you want to open the file when downloaded?'
        do {
          Write-Host
          Write-Point -NoNewLine
          $openAns = Read-Host 'y/n' 
        } while ( $openAns -ne 'y' -and $openAns -ne 'n' )
        switch ($openAns) {
          'y' { $opens = $true }
          'n' { $opens = $false }
        }
      }
    }

    if (!($matchedAppKey -and $portable -and $path -and $open)) {
      Write-Title "You are going to download$openString $app"
      $confirm = Read-Host 'Confirmation press any key or go to the (R)estart menu'
      if ($confirm -eq 'r') { Start-Main }
    }
    
    # Update progress bar
    $wc.DownloadFileAsync($uri, "$p\$o")
    while ($wc.IsBusy) {
      $downloadedOld = (Get-Item "$p\$o").Length
      Start-Sleep -Milliseconds 250
      $Downloaded = (Get-Item "$p\$o").Length
      $MBs = [Math]::Round(($downloaded - $DownloadedOld) * 4) / 1MB
      $percentage = [Math]::Round(($downloaded / $length) * 100)
      $downloadedString = "{0:N2} MB / {1:N2} MB at {2:N2} MB/s" -f ($downloaded / 1MB), ($length / 1MB), $MBs
      Write-Progress -Activity "Downloading $app..." -Status "$downloadedString ($percentage%) complete" -PercentComplete $percentage
    }

    if ($o -notlike "*.7z") { $wc.Dispose | Out-Null }
    if ($opens -eq $true) { Clear-Host; Open-App -p $p -o $o -app $app -folder $folder -exe $exe -details $details -cmd $cmd -cmd_syn $cmd_syn -launch:$launch }
    Write-Subtitle 'Continue downloading?'
    $repeat = Read-Host '==> (y/n)'
    if ($repeat -eq 'y') { Clear-Host; Start-Main }
    else { Clear-Host; Exit }
  
  }
  Start-Main -app $app -path $path -portable $portable -open $open -launch:$launch
}
finally { Remove-Item "$Env:TEMP\AppDL" -Recurse -Force | Out-Null }