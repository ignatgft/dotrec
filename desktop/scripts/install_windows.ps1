# PowerShell Installer & Launcher for DotRec Link Desktop
$ErrorActionPreference = "Stop"

$SourceDir = "D:\dev\recorder\desktop\build\dist\DotRec-Link-v1.0.0-windows-x64"
$InstallDir = "$env:LOCALAPPDATA\Programs\DotRec Link"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  DotRec Link Desktop v1.0.0 Installer" -ForegroundColor White
Write-Host "  Destination: $InstallDir" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Stop existing DotRec processes
Stop-Process -Name "*DotRec*" -Force -ErrorAction SilentlyContinue

# 2. Create directories
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
if (!(Test-Path "$InstallDir\assets\fonts")) {
    New-Item -ItemType Directory -Path "$InstallDir\assets\fonts" -Force | Out-Null
}

# 3. Copy files
Write-Host "[1/4] Copying files..." -ForegroundColor Yellow
Copy-Item "$SourceDir\DotRec-Link-App.exe" "$InstallDir\DotRec-Link-App.exe" -Force
Copy-Item "$SourceDir\DotRec-Link.exe" "$InstallDir\DotRec-Link.exe" -Force
Copy-Item "$SourceDir\README.txt" "$InstallDir\README.txt" -Force
Copy-Item "$SourceDir\LICENSE.txt" "$InstallDir\LICENSE.txt" -Force
Copy-Item "$SourceDir\config.default.json" "$InstallDir\config.default.json" -Force
Copy-Item "$SourceDir\manifest.json" "$InstallDir\manifest.json" -Force
Copy-Item "$SourceDir\assets\fonts\Doto-Variable.ttf" "$InstallDir\assets\fonts\Doto-Variable.ttf" -Force

Write-Host "  [OK] Files copied to $InstallDir" -ForegroundColor Green

# 4. Create Shortcuts (Desktop & Start Menu)
Write-Host "[2/4] Creating shortcuts..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell

# Desktop shortcut
$DesktopDir = [Environment]::GetFolderPath('Desktop')
$DesktopShortcut = $WshShell.CreateShortcut("$DesktopDir\DotRec Link.lnk")
$DesktopShortcut.TargetPath = "$InstallDir\DotRec-Link-App.exe"
$DesktopShortcut.WorkingDirectory = $InstallDir
$DesktopShortcut.Description = "DotRec Link Desktop"
$DesktopShortcut.Save()
Write-Host "  [OK] Desktop shortcut created: $DesktopDir\DotRec Link.lnk" -ForegroundColor Green

# Start Menu shortcuts
$StartMenuDir = "$([Environment]::GetFolderPath('Programs'))\DotRec Link"
if (!(Test-Path $StartMenuDir)) {
    New-Item -ItemType Directory -Path $StartMenuDir -Force | Out-Null
}
$StartShortcut = $WshShell.CreateShortcut("$StartMenuDir\DotRec Link.lnk")
$StartShortcut.TargetPath = "$InstallDir\DotRec-Link-App.exe"
$StartShortcut.WorkingDirectory = $InstallDir
$StartShortcut.Description = "DotRec Link Desktop"
$StartShortcut.Save()

$StartConsoleShortcut = $WshShell.CreateShortcut("$StartMenuDir\DotRec Link Service.lnk")
$StartConsoleShortcut.TargetPath = "$InstallDir\DotRec-Link.exe"
$StartConsoleShortcut.WorkingDirectory = $InstallDir
$StartConsoleShortcut.Description = "DotRec Link Service"
$StartConsoleShortcut.Save()
Write-Host "  [OK] Start Menu shortcuts created" -ForegroundColor Green

# 5. Registry Uninstall registration
Write-Host "[3/4] Registering in Windows Add/Remove Programs..." -ForegroundColor Yellow
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\DotRecLink"
if (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
Set-ItemProperty -Path $RegPath -Name "DisplayName" -Value "DotRec Link Desktop" -Force
Set-ItemProperty -Path $RegPath -Name "DisplayVersion" -Value "1.0.0" -Force
Set-ItemProperty -Path $RegPath -Name "Publisher" -Value "ignatgft" -Force
Set-ItemProperty -Path $RegPath -Name "InstallLocation" -Value $InstallDir -Force
Set-ItemProperty -Path $RegPath -Name "DisplayIcon" -Value "$InstallDir\DotRec-Link-App.exe,0" -Force
Set-ItemProperty -Path $RegPath -Name "UninstallString" -Value "powershell -Command Remove-Item -Recurse -Force '$InstallDir'" -Force
Write-Host "  [OK] Registered in Windows Registry" -ForegroundColor Green

# 6. Launch installed application
Write-Host "[4/4] Launching installed DotRec Link Desktop..." -ForegroundColor Cyan
Start-Process -FilePath "$InstallDir\DotRec-Link-App.exe" -WorkingDirectory $InstallDir

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  [SUCCESS] DotRec Link Desktop installed and launched!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
