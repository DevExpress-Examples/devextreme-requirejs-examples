# For local testing, you can pass buildVersion.
# Example usage:
# ./test-example.ps1 -buildVersion 25.2.7
param (
    [string]$buildVersion = $Env:CodeCentralBuildVersion
)

# Masstest-specific parameter. Specifies the minor version (example: '25.2.7')
$global:BUILD_VERSION = $buildVersion

$global:ERROR_CODE = 0
$global:FAILED_PROJECTS = @()

function Test-NpmVersionExists {
    param ([string]$Pkg, [string]$Ver)
    npm view "$Pkg@$Ver" > $null 2>&1
    return ($LASTEXITCODE -eq 0)
}

function Get-ValidNpmVersion {
    param (
        [string]$PackageName,
        [string]$Version
    )

    Write-Host "Checking $PackageName@$Version..."
    if (Test-NpmVersionExists -Pkg $PackageName -Ver $Version) {
        Write-Host "$PackageName@$Version exists."
        return $Version
    }

    try {
        $v = [version]$Version
        $fallback = "$($v.Major).$($v.Minor)-stable"
    } catch {
        Write-Host "Invalid version format: $Version"
        return $null
    }

    Write-Host "$PackageName@$Version not found. Trying fallback: $PackageName@$fallback..."
    if (Test-NpmVersionExists -Pkg $PackageName -Ver $fallback) {
        Write-Host "$PackageName@$fallback exists (fallback)."
        return $fallback
    }

    Write-Host "Neither $PackageName@$Version nor @$fallback exist."
    return $null
}

function Install-Packages {
    param (
        [string]$folderName,
        [string[]]$packages,
        [string]$buildVersion
    )

    Write-Output "`nInstalling packages in folder: $folderName"

    foreach ($package in $packages) {
        $packageVersion = Get-ValidNpmVersion -PackageName $package -Version $buildVersion
        $packageWithVersion = "$package@$packageVersion"
        Write-Output "Installing $packageWithVersion..."

        npm install --save --save-exact --no-fund --loglevel=error --force $packageWithVersion
        if (-not $?) {
            Write-Error "`nERROR: Failed to install $packageWithVersion in $folderName"
            throw "Installation failed for $packageWithVersion in $folderName"
        }
    }

    Write-Output "`nAll packages installed successfully in $folderName"
}

function Process-Project {
    param (
        [string]$buildVersion
    )
    Write-Output "`n--== Starting RequireJS Project Processing ==--"

    $folderName = "requirejs-jquery"
    $packages = @("devextreme")

    Push-Location $folderName

    try {
        Write-Output "`nRemoving node_modules and generated AMD modules: $pwd"
        Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
        Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force devextreme_amd -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force '@devextreme' -ErrorAction SilentlyContinue
        Install-Packages -folderName $folderName -packages $packages -buildVersion $buildVersion
        Write-Output "`nInstalling remaining packages in $folderName (postinstall converts DevExtreme to AMD)"
        npm install --no-fund --loglevel=error
        if (-not $?) {
            throw "ERROR: Failed to install packages in $folderName"
        }
        if (-not (Test-Path "devextreme_amd")) {
            throw "ERROR: AMD conversion output 'devextreme_amd' was not generated in $folderName"
        }
        Write-Output "`nAMD conversion output found."
    } catch {
        Write-Error "`nAn error occurred: $_"
        $global:LASTEXITCODE = 1
        $global:ERROR_CODE = 1
        $global:FAILED_PROJECTS += $folderName
    } finally {
        Pop-Location
    }

    Write-Output "`n--== RequireJS Project Processing Completed ==--"
}

function Write-BuildInfo {
    $BUILD_VERSION = if ($global:BUILD_VERSION -ne $null -and $global:BUILD_VERSION -ne "") {
        $global:BUILD_VERSION
    } else {
        "(empty)"
    }

    Write-Output "Build Version: $BUILD_VERSION"
}

Write-BuildInfo
Process-Project -buildVersion $global:BUILD_VERSION

Write-Output "`nFinished testing version: $global:BUILD_VERSION. Error code: $global:ERROR_CODE"
if ($global:ERROR_CODE -ne 0 -and $global:FAILED_PROJECTS.Count -gt 0) {
    Write-Output "`FAILED PROJECTS: $(($global:FAILED_PROJECTS -join ", "))"
}

exit $global:ERROR_CODE
