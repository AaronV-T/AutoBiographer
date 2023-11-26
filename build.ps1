$addonVersionLineTbc = Select-String -Pattern "## Version" -Path ".\AutoBiographer_TBC.toc"
$addonVersionTbc = $addonVersionLineTbc.ToString().Substring($addonVersionLineTbc.ToString().LastIndexOf(" ") + 1)
$addonVersionLineVanilla = Select-String -Pattern "## Version" -Path ".\AutoBiographer_Vanilla.toc"
$addonVersionVanilla = $addonVersionLineVanilla.ToString().Substring($addonVersionLineVanilla.ToString().LastIndexOf(" ") + 1)
$addonVersionLineWotlk = Select-String -Pattern "## Version" -Path ".\AutoBiographer_Wrath.toc"
$addonVersionWotlk = $addonVersionLineWotlk.ToString().Substring($addonVersionLineWotlk.ToString().LastIndexOf(" ") + 1)

if ($addonVersionVanilla -ne $addonVersionTbc -or $addonVersionTbc -ne $addonVersionWotlk) {
  throw "Versions don't match in TOC files."
}

$outputDirectoryPath = ".\Deploys"
$outputFileName = "AutoBiographer_$addonVersionVanilla"
if ((git branch).IndexOf("* master") -lt 0 -or (git status --porcelain).length -ne 0) {
  Write-Host "You are on a development branch or have uncommited changes."
  $currentDateTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
  $outputFileName = "$outputFileName-dev-$currentDateTime"
}

$outputFilePath = "$outputDirectoryPath\$outputFileName.zip"

if (Test-Path -Path "$outputFilePath") {
  throw "Output file with the same name already exists."
}

$tempDirectoryPath = "$outputDirectoryPath\Temp"
$tempSubDirectoryPath = "$tempDirectoryPath\AutoBiographer"
New-Item -Path ".\Deploys\Temp" -Name "AutoBiographer" -ItemType "directory" | Out-Null

Copy-Item ".\*" -Destination "$tempSubDirectoryPath" -Include *.lua,*.md,*.toc
Copy-Item ".\Classes" -Destination "$tempSubDirectoryPath" -Recurse
Copy-Item ".\Data" -Destination "$tempSubDirectoryPath" -Recurse
Copy-Item ".\Icons" -Destination "$tempSubDirectoryPath" -Recurse
Copy-Item ".\Libs" -Destination "$tempSubDirectoryPath" -Recurse
Copy-Item ".\UI" -Destination "$tempSubDirectoryPath" -Recurse

$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
if (-not (Test-Path -Path $7zipPath -PathType Leaf)) {
  throw "7 zip file '$7zipPath' not found"
}

Set-Alias 7zip $7zipPath
7zip a $outputFilePath $tempSubDirectoryPath

Remove-Item $tempDirectoryPath -Recurse

Write-Host "Successfully created deployment package: '$outputFilePath'"
