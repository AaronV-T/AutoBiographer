<# 
  Runs the local build, copies the produced zip to the anniversary WoW
  AddOns folder, and expands it there.
#>

param()

$repoRoot = Split-Path -Parent $PSCommandPath
$buildScript = Join-Path $repoRoot "build.ps1"
$deployDir = Join-Path $repoRoot "Deploys"
$targetAddOns = Join-Path $repoRoot "..\..\..\..\_anniversary_\Interface\AddOns"

Write-Host "Running build script..."
& $buildScript

if (-not (Test-Path -Path $deployDir)) {
  throw "Deploy directory '$deployDir' not found."
}

$zip = Get-ChildItem -Path $deployDir -Filter "AutoBiographer_*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $zip) {
  throw "No AutoBiographer_*.zip found in '$deployDir'."
}

if (-not (Test-Path -Path $targetAddOns)) {
  Write-Host "Creating target AddOns directory at '$targetAddOns'..."
  New-Item -ItemType Directory -Path $targetAddOns -Force | Out-Null
}

$copiedZip = Join-Path $targetAddOns $zip.Name
Write-Host "Copying '$($zip.FullName)' to '$copiedZip'..."
Copy-Item -Path $zip.FullName -Destination $copiedZip -Force

Write-Host "Expanding archive into '$targetAddOns'..."
Expand-Archive -Path $copiedZip -DestinationPath $targetAddOns -Force

Write-Host "Deleting built zip '$($zip.FullName)'..."
try {
  Remove-Item -Path $zip.FullName -Force -ErrorAction Stop
} catch {
  Write-Warning "Could not delete '$($zip.FullName)': $($_.Exception.Message)"
}

Write-Host "Deleting copied zip '$copiedZip'..."
try {
  Remove-Item -Path $copiedZip -Force -ErrorAction Stop
} catch {
  Write-Warning "Could not delete '$copiedZip': $($_.Exception.Message)"
}

Write-Host "Deploy complete."
