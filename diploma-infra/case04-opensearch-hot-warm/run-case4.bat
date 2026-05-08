@echo off
chcp 65001 >nul
setlocal EnableExtensions

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-case4.ps1"

set "SCRIPT_EXIT_CODE=%ERRORLEVEL%"

if not "%SCRIPT_EXIT_CODE%"=="0" (
    echo.
    echo PowerShell script failed with exit code %SCRIPT_EXIT_CODE%.
    echo Press any key to close this window.
    pause >nul
    exit /b %SCRIPT_EXIT_CODE%
)

echo.
echo Done.
pause >nul
