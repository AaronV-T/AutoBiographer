$outputDirectoryPath = ".\Deploys"
$tempDirectoryPath = "$outputDirectoryPath\Temp"
$tempSubDirectoryPath = "$tempDirectoryPath\AutoBiographer"
New-Item -Path ".\Deploys\Temp" -Name "AutoBiographer" -ItemType "directory" | Out-Null

Copy-Item ".\*" -Destination "$tempSubDirectoryPath" -Include *.lua,*.md,*.toc
Copy-Item ".\Classes" -Destination "$tempSubDirectoryPath" -Recurse
Copy-Item ".\UI" -Destination "$tempSubDirectoryPath" -Recurse

$currentDateTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$outputFileName = "AutoBiographer_$currentDateTime"
Compress-Archive -Path "$tempDirectoryPath\*" -DestinationPath "$outputDirectoryPath\$outputFileName"

Remove-Item $tempDirectoryPath -Recurse

Write-Host "Successfully created deployment package."
