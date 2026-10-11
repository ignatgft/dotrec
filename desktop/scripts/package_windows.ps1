# Packaging script for DotRec Link Desktop (Windows x64)
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DesktopDir = Split-Path -Parent $ScriptDir
Set-Location $DesktopDir

Write-Host "Running DotRec Link packager..." -ForegroundColor Cyan
& D:\flutter\bin\dart.exe run tool/package_windows.dart

if ($LASTEXITCODE -eq 0) {
    Write-Host "Packaging successful!" -ForegroundColor Green
} else {
    Write-Host "Packaging failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
