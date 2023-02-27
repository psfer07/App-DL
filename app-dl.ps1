Clear-Host
function Write-Main() {
  [CmdletBinding()]
  param (
      [String] $Text = "Blank"
  )


  $loop = $Text.Length

  $center = for ($i = 1; $i -le $loop; $i++){ ("=") }

  Write-Host "`n<$center>" -ForegroundColor Blue
  Write-Host "   $Text" -ForegroundColor White -BackgroundColor Black
  Write-Host "<$center>" -ForegroundColor Blue -BackgroundColor Black
}
function Write-Secondary() {
  [CmdletBinding()]
  param (
      [String] $Text = "Blank"
  )

  Write-Host "`n<==========[" -NoNewline -ForegroundColor Green -BackgroundColor Black
  Write-Host " $Text " -NoNewline -ForegroundColor White -BackgroundColor Black
  Write-Host "]==========>`n" -ForegroundColor Green -BackgroundColor Black
}
function Write-Point() {
  [CmdletBinding()]
  param (
      [String] $Text = "Blank"
  )

  Write-Host "==[ " -NoNewline -ForegroundColor Green -BackgroundColor Black
  Write-Host "$Text" -ForegroundColor White -BackgroundColor Black
}
function Write-Warning() {
  [CmdletBinding()]
  param (
      [String] $Text = "Blank"
  )


  $loop = $Text.Length

  $center = for ($i = 1; $i -le $loop; $i++){ ("=") }

  Write-Host "`n<$center>" -ForegroundColor Red
  Write-Host "   $Text" -ForegroundColor White -BackgroundColor Black
  Write-Host "<$center>" -ForegroundColor Red -BackgroundColor Black
}

#Initialize variables
$json = Get-Content ".\apps.json" -Raw | ConvertFrom-Json
$nameArray = $json.psobject.Properties.Name
$propMapping = @{}
$filteredApps = @()

Clear-Host

#Assigns the JSON's properties into Powershell objects
foreach ($i in 0..($nameArray.Count - 1)) {
  $name = $nameArray[$i]
  $app = $json.$name
  $url = $app.URL
  $exe = $app.exe
  $size = $app.size
  $propMapping.Add($name, $url)
  $filteredApps += [PsCustomObject]@{Index = $i; Name = $name; URL = $url; Exe = $exe;Size = $size}
}

#List every app valid in the JSON file
Write-Main "Aviable apps"
foreach ($i in 0..($filteredApps.Count - 1)) {
  $app = $filteredApps[$i]
  $n = $i + 1
  Write-Secondary "$n. $($app.Name) - Size: $($app.Size)"
}
$pkg_number = Read-Host `n"Write the number of the app you want to get"
$program = $nameArray[$pkg_number - 1]

Clear-Host
Write-Main "$program selected"

# Prints off all the aviable paths to save the package
Write-Point "1. Saves it inside of Desktop"
Write-Point "2. Saves it inside of Documents"
Write-Point "3. Saves it inside of Downloads"
Write-Point "4. Save it inside of C:"
Write-Point "5. Saves it inside of Program Files"
Write-Point "6. Save it inside of the user profile"
$path = Read-Host "`nChoose a number $help"

switch ($path) {
  1         { $path = "$Env:USERPROFILE\Desktop"; break }
  2         { $path = "$Env:USERPROFILE\Documents"; break }
  3         { $path = "$Env:USERPROFILE\Downloads"; break }
  4         { $path = $Env:SystemDrive; break }
  5         { $path = $Env:ProgramFiles; break }
  6         { $path = $Env:HOMEPATH; break }
  default   { Write-Host "Invalid input. Using default path: $Env:USERPROFILE"; $path = $Env:USERPROFILE }
}
Write-Main "Selected path: $path"

#Checks if the program is installed or uncompressed in the selected folder
if (Test-Path "$path\$program") {
  Write-Host `n
  Write-Point "1. Restart App-dl"
  Write-Point "2. Leave powershell"
  $restart = Read-Host "This program is currently allocated in this path, so select the corresponding number if you want to start again or leaving this session"
if ($restart -eq 1) { Start-Process powershell.exe "-WindowStyle Maximized -File `"$PSCommandPath`""; break}
elseif ($launch -ne 1) {
  Write-Main "Closing this terminal..."
  Start-Sleep -Milliseconds 500
  exit
}}

# Assign specific variables to download and save the package
$selectedApp = $filteredApps | Where-Object {$_.Name -eq $program}
$url = $selectedApp.URL
$out_file = (Split-Path $url -Leaf) -split "/" | Select-Object -Last 1


# Downloads the app package
Write-Main "App to download: $program..."; Pause
Invoke-WebRequest -URI $url -OutFile "$path\$out_file"
if ($?) {
    Write-Secondary "File downloaded successfully"
} else {
    Write-Warning "An error occurred while downloading the file"
}

# Extracts the content from the package
if ($out_file -like "*.zip"){$extract = Read-Host "Do you want to unzip the package?(y/n)"
if ($extract -eq "y" -or $extract -eq "Y"){
  try {
    Expand-Archive -Path "$path\$out_file" -DestinationPath "$path\$program" -Force
    Write-Main "Package succesfully extracted..."
    Start-Sleep -Seconds 2
  }
  catch {
    Write-Host "Unable to extract. Error: $($_.Exception.Message)"; Pause
}}
}