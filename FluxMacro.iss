[Setup]
AppName=FluxMacro
AppVersion=2.0
AppPublisher=strangeststar
AppPublisherURL=https://github.com/strangeststar
DefaultDirName={autopf}\FluxMacro
DefaultGroupName=FluxMacro
OutputDir=installer_out
OutputBaseFilename=FluxMacro_Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
DisableProgramGroupPage=yes
UninstallDisplayName=FluxMacro
UninstallDisplayIcon={app}\FluxMacro.exe
SetupIconFile=CMakeProject1\icon.ico
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: checkedonce

[Files]
; Everything windeployqt staged into installer_stage\
Source: "installer_stage\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\FluxMacro"; Filename: "{app}\FluxMacro.exe"; Tasks: desktopicon
Name: "{group}\FluxMacro"; Filename: "{app}\FluxMacro.exe"
Name: "{group}\Uninstall FluxMacro"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\FluxMacro.exe"; Description: "Launch FluxMacro"; Flags: nowait postinstall skipifsilent
