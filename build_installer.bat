@echo off
setlocal

set QT_BIN=C:\Qt\6.8.3\msvc2022_64\bin
set BUILD_DIR=%~dp0out\build\x64-release\CMakeProject1
set STAGE_DIR=%~dp0installer_stage
set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

echo === 1. Building FluxMacro ===
call "C:\Users\medin\build_flux.bat"
if %ERRORLEVEL% neq 0 (
    echo BUILD FAILED
    exit /b 1
)

echo.
echo === 2. Staging files ===
if exist "%STAGE_DIR%" rmdir /s /q "%STAGE_DIR%"
mkdir "%STAGE_DIR%"
copy /y "%BUILD_DIR%\FluxMacro.exe" "%STAGE_DIR%\"

echo.
echo === 3. Running windeployqt ===
"%QT_BIN%\windeployqt.exe" --release --qmldir "%~dp0CMakeProject1\qml" "%STAGE_DIR%\FluxMacro.exe"
if %ERRORLEVEL% neq 0 (
    echo windeployqt FAILED
    exit /b 1
)

echo.
echo === 4. Compiling installer ===
if not exist %ISCC% (
    echo.
    echo ERROR: Inno Setup not found at %ISCC%
    echo Download and install it from: https://jrsoftware.org/isdl.php
    echo Then re-run this script.
    exit /b 1
)

if not exist "%~dp0installer_out" mkdir "%~dp0installer_out"
%ISCC% "%~dp0FluxMacro.iss"
if %ERRORLEVEL% neq 0 (
    echo Inno Setup compile FAILED
    exit /b 1
)

echo.
echo === DONE ===
echo Installer: %~dp0installer_out\FluxMacro_Setup.exe
