$currentVersion = Get-Content "$PSScriptRoot\..\ALZ-Bicep\.version"
$allreleases = Invoke-RestMethod https://api.github.com/repos/Azure/ALZ-Bicep/releases
$latestRelease = $allreleases | Where-Object {$_.prerelease -eq $false} | Sort-Object -Descending published_at | Select-Object -First 1

if ($latestRelease.name -eq $currentVersion) {
    Write-Host "##[section] $(Get-Date -Format u) - ALZ-Bicep are already up to date" -ForegroundColor Green
    exit 0
}

Write-Host "##[section] $(Get-Date -Format u) - Updating ALZ-Bicep to version $($latestRelease.name)" -ForegroundColor Green

$tempFolder = "$PSScriptRoot\.local"
if (Test-Path -Path $tempFolder) {
    Remove-Item -Path $tempFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $tempFolder
New-Item -ItemType Directory -Path "$tempFolder\Download"
New-Item -ItemType Directory -Path "$tempFolder\Extract"
Invoke-WebRequest -Uri $latestRelease.zipball_url -OutFile "$tempFolder\Download\ALZ-Bicep.zip"
Expand-Archive -Path "$tempFolder\Download\ALZ-Bicep.zip" -DestinationPath "$tempFolder\Extract\"
$extractSubFolder = Get-ChildItem "$tempFolder\Extract\Azure-ALZ-Bicep-*" -Directory

if (Test-Path -Path "$PSScriptRoot\..\ALZ-Bicep") {
    Remove-Item -Path "$PSScriptRoot\..\ALZ-Bicep" -Recurse -Force
}
New-Item -ItemType Directory -Path "$PSScriptRoot\..\ALZ-Bicep"
Move-Item -Path "$($extractSubFolder.FullName)\*" -Destination "$PSScriptRoot\..\ALZ-Bicep\"

$latestRelease.name | Out-File -Path "$PSScriptRoot\..\ALZ-Bicep\.version"
git add "$PSScriptRoot\..\ALZ-Bicep"
git commit -m "Standard: Update ALZ-Bicep to version $($latestRelease.name)"
