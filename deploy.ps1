$currentDateTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$newDirName = "AutoBiographer_$currentDateTime"
New-Item -Path ".\Deploys" -Name $newDirName -ItemType "directory" | Out-Null
$newDirPath = ".\Deploys\$newDirName"

Copy-Item ".\*" -Destination "$newDirPath" -Include *.lua,*.md,*.toc
Copy-Item ".\Classes" -Destination "$newDirPath" -Recurse
Copy-Item ".\UI" -Destination "$newDirPath" -Recurse

Write-Host "Successfully deployed to $newDirPath."
