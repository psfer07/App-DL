[string]$branch = "dev"

Clear-Host

function Write-Main($Text) {
  $border = "============================================"
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
  Write-Host "==[ " -NoNewline -ForegroundColor Green
  Write-Host "$Text" -ForegroundColor White
}
function Write-Warning($Text) {
  $border = "============================================"
  Write-Host "`n`n<$border>" -ForegroundColor Red
  Write-Host "   $Text" -ForegroundColor White
  Write-Host "<$border>" -ForegroundColor Red
}
function Use-Path{
    Clear-Host
    Write-Warning "It seems that $program is currently allocated in this path"
    $restart = Read-Host "Write 'r' to restart the app and start again, 'o' to open the existing app or 'e' to exiting"
    switch ($restart) {
      "r"   { Start-Process powershell.exe "-File `"$PSCommandPath`""; Start-Sleep -Milliseconds 200; exit }
      "o"   { Write-Main "Opening $program..."
      if ($output -like "*.zip")
        {if (Test-Path -eq "$p\$output")
        {
          Write-Main "Zip file detected"
          Write-Secondary "$program is saved as a zip file, so uncompressing..."
          Start-Sleep -Milliseconds 200
          Expand-Archive -Path "$p\$output" -DestinationPath "$p\$program" -Force
          Write-Main "Package succesfully extracted..."
          Start-Sleep -Milliseconds 500
          Exit
        }
        elseif (Test-Path -eq "$p\$program\$folder")
        {
          Start-Process -FilePath "$p\$program\$folder\$exe"}}
          if ($output -like "*.exe")
          {
            if ($null -ne $cmd)
            {
              Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just open it as normal)? (y/n)"
              $runcmd = Read-Host
              if ($runcmd -eq 'y','Y')
              {
                Clear-Host
                Write-Main "Running $program $($cmd_syn)"
                Start-Process -FilePath "$p\$output" -ArgumentList $($cmd)
                Start-Sleep -Milliseconds 200
                Exit
              }
            }
            if ($runcmd -ne 'y','Y')
            {
              Clear-Host
              Write-Main "Running $program directly"
              Start-Process -FilePath "$p\$output"
              Start-Sleep -Milliseconds 200
              Exit
            }
          }
        }
      "e"   { Write-Main "Closing this terminal..."; Start-Sleep -Milliseconds 500; exit }
      default { Write-Warning "Non-valid character, exiting..."; Start-Sleep -Milliseconds 500; exit }
    }
}
function Get-FileSize() {
  param ([int]$size)
  if ($size -gt 1GB) {[string]::Format("{0:0.00} TB", $size / 1GB)}
  elseif ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
  elseif ($size -gt 1KB) {[string]::Format("{0:0.00} KB", $size / 1KB)}
  elseif ($size -gt 0) {[string]::Format("{0:0.00} B", $size)}
  }
function Restart {
    Start-Process powershell.exe "-File `"$PSCommandPath`""
    Start-Sleep 1
    Exit
}


#Initialize variables
$json = Invoke-RestMethod "https://raw.githubusercontent.com/psfer07/App-DL/$branch/apps.json"
$nameArray = $json.psobject.Properties.Name
$propMapping = @{}
$filteredApps = @()


#Assigns the JSON's properties into Powershell objects
foreach ($i in 0..($nameArray.Count - 1)) {
  $name = $nameArray[$i]
  $app = $json.$name
  $folder = $app.folder
  $url = $app.URL
  $exe = $app.exe
  $cmd = $app.cmd
  $syn = $app.syn
  $cmd_syn = $app.cmd_syn
  $propMapping.Add($name, $url)
  $filteredApps += [PsCustomObject]@{Index = $i; Name = $name; Folder = $folder; URL = $url; Exe = $exe; Size = $size; Cmd = $cmd; Syn = $syn; Cmd_syn = $cmd_syn}
}


#List every valid app in the JSON file
Clear-Host
Write-Main "Available apps"
foreach ($i in 0..($filteredApps.Count - 1)) {
  $app = $filteredApps[$i]
  $n = $i + 1
  Write-Point "$n. $($app.Name)"
}
Write-Host "`nType a dot and a space before the number to display all the program properties, for example: '. 1'"
$pkg_n = Read-Host `n"Write the number of the app you want to get"

#Assign the corresponding variables to the selected app
$program =    $filteredApps[$pkg_n - 1].Name
$exe =        $filteredApps[$pkg_n - 1].Exe
$folder =     $filteredApps[$pkg_n - 1].folder
$url =        $filteredApps[$pkg_n - 1].URL
$cmd_syn =    $filteredApps[$pkg_n - 1].Cmd_syn
$cmd =        $filteredApps[$pkg_n - 1].Cmd
$output =   Split-Path $url -split "/" -Leaf

#$size = Get-FileSize((Invoke-RestMethod $url).length)

Clear-Host
Write-Main "$program selected"


# Prints out all the aviable paths to save the package
Write-Point "1. Saves it inside of Desktop"
Write-Point "2. Saves it inside of Documents"
Write-Point "3. Saves it inside of Downloads"
Write-Point "4. Save it inside of C:"
Write-Point "5. Saves it inside of Program Files"
Write-Point "6. Save it inside of the user profile`n"
Write-Point "0. Goes back to change the app"
[string]$p = Read-Host "`nChoose a number"

switch ($p) {
  0         { Restart }
  1         { $p = "$Env:USERPROFILE\Desktop"; break }
  2         { $p = "$Env:USERPROFILE\Documents"; break }
  3         { $p = "$Env:USERPROFILE\Downloads"; break }
  4         { $p = $Env:SystemDrive; break }
  5         { $p = $Env:ProgramFiles; break }
  6         { $p = $Env:HOMEPATH; break }
  default   { Write-Host "Invalid input. Using default path: $Env:USERPROFILE"; $p = $Env:USERPROFILE }
}
Clear-Host
Write-Main "Selected path: $p"

#Checks if the program is installed or uncompressed in the selected folder
if (Test-Path "$p\$output") {Use-Path}

# Downloads the app package
Write-Main "App to download: $program..."
$download = Read-Host "Confirmation (press enter or (C)ancel)"
if ($download -eq 'C'){Restart}
Invoke-WebRequest -URI $url -OutFile "$p\$output"
if ($?) {
    Write-Secondary "File downloaded successfully"
} else {
    Write-Warning "An error occurred while downloading the file: $_.Exception"
  }

# Extracts or launches the app installer depending on its extension
if ($output -like "*.zip"){$extract = Read-Host "Do you want to unzip the package?(y/n)"
if ($extract -eq 'y','Y'){
  try {
    Expand-Archive -Path "$p\$output" -DestinationPath "$p\$program" -Force
    Write-Main "Package succesfully extracted..."
  }
  catch { Write-Warning "Failed to extract package. Error: $($_.Exception.Message)"; Pause }
}
if ($extract -ne 'y','Y'){
  Write-Main "Leaving session..."
  Start-Sleep 1
  Exit
}

$open = Read-Host "Open the app?(y/n)"
if ($open -eq "y" -or $open -eq "y"){ Start-Process -FilePath "$p\$program\$folder\$exe" }
}

if ($output -like "*.exe"){
  if ($null -ne $cmd) {
    Write-Host "There is a preset for running $program $($cmd_syn). Do you want to do it (if not, it will just open it as normal)? (y/n)"
    $runcmd = Read-Host
    if ($runcmd -eq 'y','Y'){
      Clear-Host
      Write-Main "Running $program $($cmd_syn)"
      Start-Process -FilePath "$p\$output" -ArgumentList $($cmd)
    }
    if ($runcmd -eq 'n','N'){
      Clear-Host
      Write-Main "Running $program directly"
      Start-Process -FilePath "$p\$output"
    }
  }
}