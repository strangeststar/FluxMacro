@echo off
setlocal

set EXE="%~dp0out\build\x64-release\CMakeProject1\FluxMacro.exe"
set DIST="%~dp0dist"
set WINDEPLOYQT=C:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe

if not exist %EXE% (
    echo [ERROR] FluxMacro.exe not found. Build the Release configuration first.
    echo         Expected: %EXE%
    pause
    exit /b 1
)

if not exist %WINDEPLOYQT% (
    echo [ERROR] windeployqt.exe not found at %WINDEPLOYQT%
    echo         Adjust the WINDEPLOYQT variable in this script to match your Qt installation.
    pause
    exit /b 1
)

echo [1/3] Cleaning dist folder...
if exist %DIST% rmdir /s /q %DIST%
mkdir %DIST%

echo [2/3] Copying executable...
copy /y %EXE% %DIST%\

echo [3/3] Deploying Qt dependencies...
%WINDEPLOYQT% --qmldir "%~dp0CMakeProject1\qml" --release %DIST%\FluxMacro.exe

echo.
echo Done! Standalone build is in: %DIST%
echo You can zip and distribute that folder freely.
pause
