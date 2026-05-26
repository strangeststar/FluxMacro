@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
set PATH=C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%
cd /d "C:\Users\medin\source\repos\CMakeProject1\out\build\x64-debug"
ninja -j4 2>&1
echo BUILD_EXIT=%ERRORLEVEL%
