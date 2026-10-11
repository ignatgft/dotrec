; Inno Setup Script for DotRec Link Desktop
#define MyAppName "DotRec Link"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "ignatgft"
#define MyAppURL "https://github.com/ignatgft/dotrec"
#define MyAppExeName "DotRec-Link.exe"
#define MyDistDir "..\build\dist\DotRec-Link-v1.0.0-windows-x64"

[Setup]
AppId={{5E21F648-93FA-427E-971B-391487677DA8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\DotRec Link
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile={#MyDistDir}\LICENSE.txt
OutputDir=..\build\dist
OutputBaseFilename=DotRec-Link-Setup-v1.0.0
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
ShowLanguageDialog=no
CloseApplications=no
RestartApplications=no

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MyDistDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyDistDir}\DotRec-Link-App.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyDistDir}\README.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyDistDir}\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyDistDir}\config.default.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyDistDir}\manifest.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyDistDir}\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\DotRec-Link-App.exe"
Name: "{group}\DotRec Link Service (Console)"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\DotRec-Link-App.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\DotRec-Link-App.exe"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
