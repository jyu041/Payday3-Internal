param(
    [string]$GameBin = "G:\SteamLibrary\steamapps\common\PAYDAY3\PAYDAY3\Binaries\Win64",
    [string]$Out = "LocalBuild"
)

$ErrorActionPreference = "Stop"
$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (Get-Process -Name "PAYDAY3-Win64-Shipping" -ErrorAction SilentlyContinue) {
    throw "PAYDAY 3 is running. Close the game before building/deploying version.dll."
}

if (-not (Test-Path $GameBin -PathType Container)) {
    throw "PAYDAY 3 binary directory was not found: $GameBin"
}

$PackageRoot = if ([System.IO.Path]::IsPathRooted($Out)) {
    [System.IO.Path]::GetFullPath($Out)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Repo $Out))
}

Push-Location $Repo
try {
    git submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) { throw "git submodule update failed with exit code $LASTEXITCODE" }

    & (Join-Path $PSScriptRoot "BuildPackage.ps1") -Modes release -Out $PackageRoot
    if ($LASTEXITCODE -ne 0) { throw "release build failed with exit code $LASTEXITCODE" }

    $BuiltDll = Join-Path $PackageRoot "release\Proxy\version.dll"
    $BuiltPdb = Join-Path $PackageRoot "release\Proxy\version.pdb"
    if (-not (Test-Path $BuiltDll -PathType Leaf)) {
        throw "built proxy was not found: $BuiltDll"
    }
    if (-not (Test-Path $BuiltPdb -PathType Leaf)) {
        throw "release PDB was not found: $BuiltPdb"
    }

    $InstalledDll = Join-Path $GameBin "version.dll"
    if (Test-Path $InstalledDll -PathType Leaf) {
        $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $Backup = Join-Path $GameBin "version.pre-jerry-stable-$Stamp.dll"
        Copy-Item $InstalledDll $Backup -Force
        Write-Host "Backed up installed proxy to $Backup"
    }

    Copy-Item $BuiltDll $InstalledDll -Force

    $BuiltHash = (Get-FileHash $BuiltDll -Algorithm SHA256).Hash
    $InstalledHash = (Get-FileHash $InstalledDll -Algorithm SHA256).Hash
    if ($BuiltHash -ne $InstalledHash) {
        throw "installed version.dll hash does not match the built DLL"
    }

    $Commit = (git rev-parse --short HEAD).Trim()
    Write-Host ""
    Write-Host "Deployment complete"
    Write-Host "  commit:     $Commit"
    Write-Host "  version.dll $BuiltHash"
    Write-Host "  PDB:        $BuiltPdb"
    Write-Host "  game:       $InstalledDll"
}
finally {
    Pop-Location
}
