﻿$ErrorActionPreference = 'Stop'

# This code is borrowed from the awesome Microsoft-Windows-Terminal package
# https://community.chocolatey.org/packages/microsoft-windows-terminal
#
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$internalAppXPackage = @{
    SoftwareName = 'WinGet-CLI'
    PackageName  = 'Microsoft.DesktopAppInstaller'
    Version      = '2023.417.2324.0'
}

$appxFileName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
$appxLicenseFilename = 'License.xml'

# As the dependencies are all x64, I don't think this will run in x86
if (-not (Get-OSArchitectureWidth -compare '64')) {
    throw 'Requires Windows x64. Other architectures are not supported.'
}
$windowsVersion = [Environment]::OSVersion.Version
if ($windowsVersion.Major -ne "10") {
    throw "This package requires Windows 10 / Server 2019."
}

# .appx is not supported on Windows 10 version 1709 and 1803. https://docs.microsoft.com/en-us/windows/msix/msix-1709-and-1803-support
if ($windowsVersion.Build -lt "17763") {
    throw "This package requires at least Windows 10 / Server 2019 version 1809 / OS build 17763.x. See https://github.com/microsoft/microsoft-ui-xaml#version-support for more information."
}

# Winget-CLI is not supported on Server OS's but can be installed.
if ($env:OS_NAME -like "*Server*") {
    Write-Warning "This version of winget-cli is not officially supported on Windows Server operating systems."
    Write-Warning "It does however install, so we will continue and assume you know what you're doing!"
    Write-Warning "See https://github.com/microsoft/winget-cli#installing-the-client for more information."
}

$installedAppXPackage = Get-AppxProvisionedPackage -Online | Where-Object -Property DisplayName -eq $internalAppXPackage.PackageName

$removeAppXPackage = $false
if ([version]$installedAppXPackage.Version -gt [version]$internalAppXPackage.Version) {
    # you can't install an older version of an installed appx package, you'd need to remove it first
    Write-Warning "The installed $installedAppxVersion version is newer than this package version, it may have been automatically updated on your computer."
    $removeAppXPackage = $true
}
elseif ([version]$installedAppXPackage.Version -eq [version]$internalAppxPackage.Version) {
    if ($env:ChocolateyForce) {
        # you can't install the same version of an appx package, you need to remove it first
        Write-Host 'Removing already installed version.'
        $removeAppXPackage = $true
    }
    else {
        Write-Host "The $($internalAppXPackage.Version) version of $($internalAppXPackage.PackageName) is already installed. If you want to reinstall use --force."
        return
    }
}

if ($removeAppXPackage) {
    Write-Host "Removing version $($installedAppXPackage.Version) of $($internalAppXPackage.PackageName)."
    $null = Remove-AppxProvisionedPackage -PackageName $installedAppXPackage.PackageName -Online
}

$null = Add-AppXProvisionedPackage -Online `
    -PackagePath (Join-Path -Path $toolsDir -ChildPath $appxFileName) `
    -LicensePath (Join-Path -Path $toolsDir -ChildPath $appxLicenseFilename)

Write-Warning 'Note that the Microsoft collects data when the WinGet-CLI software is installed.'
Write-Warning 'Please see https://github.com/microsoft/winget-cli#datatelemetry for more information on how to opt-out.'
