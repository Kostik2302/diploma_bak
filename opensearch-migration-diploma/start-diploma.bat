@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo ========================================
echo    OpenSearch migration — старт
echo ========================================
echo.
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker не запущен. Запустите Docker Desktop.
    pause
    exit /b 1
)
echo Docker OK.
echo.
call "%~dp0menu.bat"
