﻿$ErrorActionPreference = 'Stop'

$zipFolder  = 'KeeChallenge_1.5'

# create temp directory
do {
    $tempPath = Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString())
} while (Test-Path $tempPath)
New-Item -ItemType Directory -Path $tempPath | Out-Null

$packageArgs = @{
    packageName   = $env:ChocolateyPackageName
    unzipLocation = $tempPath
    url           = 'https://github.com/brush701/keechallenge/releases/download/1.5/KeeChallenge_1.5.zip'
    checksum      = '7a691e37858bee3a69ba81ed1c7ce6dd42de4096dfe9cd7b7547566399d3f369'
    checksumType  = 'SHA256'
}

$packageSearch = 'KeePass Password Safe*'
$installPath = ''

Write-Verbose "Searching for Keepass install location."
if ([array]$key = Get-UninstallRegistryKey -SoftwareName $packageSearch) {
    $installPath = $key.InstallLocation
}

if ([string]::IsNullOrEmpty($installPath)) {
    Write-Verbose "Searching '$env:ChocolateyBinRoot' for portable install..."
    $portPath = Join-Path -Path $env:ChocolateyBinRoot -ChildPath "keepass"
    $installPath = Get-ChildItem -Directory "$portPath*" -ErrorAction SilentlyContinue
}

if ([string]::IsNullOrEmpty($installPath)) {
    Write-Verbose "Searching '$env:Path' for unregistered install..."
    $installFullName = Get-Command -Name keepass -ErrorAction SilentlyContinue
    if ($installFullName) {
        $installPath = Split-Path $installFullName.Path -Parent
    }
}

if ([string]::IsNullOrEmpty($installPath)) {
    throw "$($packageSearch) not found."
}
else {
    Write-Verbose "Found Keepass install location at '$installPath'."
}

Install-ChocolateyZipPackage @packageArgs

# copy the items from the chocolatey install folder to the Keepass plugin folder
$installPath = Join-Path -Path $installPath -ChildPath 'plugins'
$sourcePath = Join-Path -Path $packageArgs.unzipLocation -ChildPath $zipFolder
Copy-Item -Path $sourcePath -Destination $installPath -Recurse -Force -ErrorAction SilentlyContinue -Verbose

if (Get-Process -Name 'KeePass' -ErrorAction SilentlyContinue ) {
    Write-Warning "Keepass is currently running. '$($packageArgs.packageName)' will be available at next restart."
}
else {
    Write-Host "'$($packageArgs.packageName)' will be loaded the next time KeePass is started."
}
