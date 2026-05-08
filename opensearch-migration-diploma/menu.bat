@echo off
chcp 65001 > nul
title OpenSearch migration (diploma)

:menu
cls
echo ========================================
echo    OpenSearch: кейс 3 (два сценария)
echo ========================================
echo.
echo    [1] Сценарий 1 - замена нод в кластере
echo        API через прокси: 9200, Dashboards: 5601
echo        Прямой доступ old: 9201, 9202  new: 9203, 9204
echo.
echo    [2] Сценарий 2 - remote reindex между кластерами
echo        Source API: 9201, Destination API: 9202
echo        Dashboards: 5602 (source), 5603 (dest)
echo.
echo    [3] Остановить сценарий 1 (docker-compose down -v)
echo    [4] Остановить сценарий 2 (docker-compose down -v)
echo    [5] Статус контейнеров Docker
echo    [6] Выход
echo.
echo    Внимание: не запускайте оба сценария сразу — порты 9201/9202 пересекаются.
echo ========================================
echo.

set /p choice="Выбор (1-6): "

if "%choice%"=="1" goto scenario1
if "%choice%"=="2" goto scenario2
if "%choice%"=="3" goto down1
if "%choice%"=="4" goto down2
if "%choice%"=="5" goto status
if "%choice%"=="6" exit /b 0

goto menu

:scenario1
cls
cd /d "%~dp0scenario1-add-nodes"
if not exist "docker-compose.yml" (
    echo Нет docker-compose.yml в scenario1-add-nodes
    pause
    cd /d "%~dp0"
    goto menu
)
echo Сценарий 1 — каталог: %cd%
echo  [1] setup-cluster.bat   [2] migrate-nodes.bat   [3] check-status.bat
echo  [4] _cat/nodes          [5] _cat/shards         [6] remove-old-nodes.bat
echo  [7] Назад
echo.
set /p action="Действие (1-7): "
if "%action%"=="1" call setup-cluster.bat
if "%action%"=="2" call migrate-nodes.bat
if "%action%"=="3" call check-status.bat
if "%action%"=="4" (
    curl -s "localhost:9200/_cat/nodes?v"
    echo.
    pause
)
if "%action%"=="5" (
    curl -s "localhost:9200/_cat/shards/test-index?v"
    echo.
    pause
)
if "%action%"=="6" call remove-old-nodes.bat
cd /d "%~dp0"
goto menu

:scenario2
cls
cd /d "%~dp0scenario2-remote-reindex"
if not exist "docker-compose.yml" (
    echo Нет docker-compose.yml в scenario2-remote-reindex
    pause
    cd /d "%~dp0"
    goto menu
)
echo Сценарий 2 — каталог: %cd%
echo  [1] setup-clusters.bat  [2] reindex-data.bat  [3] verify-reindex.bat
echo  [4] GET _cat/indices source  [5] dest  [6] Назад
echo.
set /p action="Действие (1-6): "
if "%action%"=="1" call setup-clusters.bat
if "%action%"=="2" call reindex-data.bat
if "%action%"=="3" call verify-reindex.bat
if "%action%"=="4" (
    curl -s "localhost:9201/_cat/indices?v"
    echo.
    pause
)
if "%action%"=="5" (
    curl -s "localhost:9202/_cat/indices?v"
    echo.
    pause
)
cd /d "%~dp0"
goto menu

:down1
cls
cd /d "%~dp0scenario1-add-nodes"
docker-compose down -v
cd /d "%~dp0"
pause
goto menu

:down2
cls
cd /d "%~dp0scenario2-remote-reindex"
docker-compose down -v
cd /d "%~dp0"
pause
goto menu

:status
cls
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
pause
goto menu
