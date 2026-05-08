@echo off
chcp 65001 > nul
echo ========================================
echo    СЦЕНАРИЙ 2: Два кластера (Source + Destination)
echo ========================================
echo.

cd /d %~dp0

echo [1/7] Очищаем контейнеры и тома...
docker-compose down -v
docker-compose rm -f

echo [2/7] Запускаем кластеры и Dashboards...
docker-compose up -d source-node-1 source-node-2 destination-node-1 destination-node-2 dashboards-source dashboards-dest

echo [3/7] Ждем 60 секунд...
timeout /t 60 /nobreak

echo [4/7] Ждем Source (localhost:9201)...
set attempts=0
:check_source
set /a attempts+=1
if %attempts% gtr 30 goto :check_dest
curl -s -f http://localhost:9201 >nul
if %errorlevel% neq 0 (
    echo    Попытка %attempts% из 30...
    timeout /t 5 /nobreak
    goto check_source
)

:check_dest
echo Source отвечает.
set attempts=0
:check_dest_loop
set /a attempts+=1
if %attempts% gtr 30 goto :ready
curl -s -f http://localhost:9202 >nul
if %errorlevel% neq 0 (
    echo    Destination: попытка %attempts% из 30...
    timeout /t 5 /nobreak
    goto check_dest_loop
)

:ready
echo Destination отвечает.
echo.

echo [5/7] Индекс и данные в Source (9201)...
curl -X PUT "localhost:9201/test-index" -H "Content-Type: application/json" --data-binary "@index-definition.json"
echo.

for /l %%i in (1,1,10) do (
    curl -X POST "localhost:9201/test-index/_doc/%%i?refresh=wait_for" -H "Content-Type: application/json" -d "{\"title\":\"Документ %%i\",\"views\":%%i}" -s >nul
)
curl -X POST "localhost:9201/test-index/_refresh" -s >nul
echo Данные в Source загружены.

echo [6/7] Пустой индекс в Destination (те же settings/mappings)...
curl -X PUT "localhost:9202/test-index" -H "Content-Type: application/json" --data-binary "@index-definition.json"
echo.

echo [7/7] Проверка...
curl -X GET "localhost:9201/_cat/indices/test-index?v"
curl -X GET "localhost:9202/_cat/indices/test-index?v"
echo.
echo Документы в Source:
curl -X GET "localhost:9201/test-index/_count?pretty"
echo Документы в Destination (ожидается 0):
curl -X GET "localhost:9202/test-index/_count?pretty"

echo.
echo ========================================
echo ГОТОВО. Дальше: reindex-data.bat
echo Source API:9201  Dest API:9202
echo ========================================
pause
