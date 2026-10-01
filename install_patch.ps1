param(
    [Parameter(Mandatory = $true)]
    [string]$Project
)

$ErrorActionPreference = "Stop"
$Project = (Resolve-Path -LiteralPath $Project).Path
$PatchRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$copies = @(
    @{
        Source = Join-Path $PatchRoot "training\run_hybrid_ai_fixed.ps1"
        Destination = Join-Path $Project "training\run_hybrid_ai_fixed.ps1"
    },
    @{
        Source = Join-Path $PatchRoot "tests\training_preflight.gd"
        Destination = Join-Path $Project "tests\training_preflight.gd"
    }
)

$configSource = Join-Path $PatchRoot "training\configs"
$configDestination = Join-Path $Project "training\configs"

New-Item -ItemType Directory -Force -Path $configDestination | Out-Null

foreach ($copy in $copies) {
    $destinationDirectory = Split-Path -Parent $copy.Destination
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
    Copy-Item -LiteralPath $copy.Source -Destination $copy.Destination -Force
    Write-Host "Installed: $($copy.Destination)"
}

Copy-Item -LiteralPath (Join-Path $configSource "*.json") `
    -Destination $configDestination `
    -Force

Write-Host ""
Write-Host "Hybrid AI repair/training helper files installed." -ForegroundColor Green
Write-Host "No existing gameplay or AI scripts were overwritten." -ForegroundColor Green
