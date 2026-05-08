@echo off
chcp 65001 > nul
echo ========================================
echo    СЦЕНАРИЙ 1: Настройка старого кластера
echo ========================================
echo.

cd /d %~dp0

echo [0/7] Сбрасываем nginx на upstream со СТАРЫМИ нодами...
copy /Y nginx-old.conf nginx.conf >nul
if %errorlevel% neq 0 (
    echo ОШИБКА: нет файла nginx-old.conf
    pause
    exit /b 1
)

echo [1/7] Очищаем старые контейнеры и данные...
docker-compose down -v
docker-compose rm -f

echo [2/7] Запускаем ТОЛЬКО старые ноды и инфраструктуру...
echo    - Старые ноды (old-node-1, old-node-2)
echo    - Балансировщик (порт 9200)
echo    - Dashboards (порт 5601)
docker-compose up -d old-node-1 old-node-2 opensearch-proxy opensearch-dashboards

echo [3/7] Ждем 45 секунд для инициализации...
timeout /t 45 /nobreak

echo [4/7] Проверяем доступность OpenSearch через балансировщик...
set attempts=0
:check
set /a attempts+=1
if %attempts% gtr 30 goto :continue

curl -s -f http://localhost:9200 >nul
if %errorlevel% neq 0 (
    echo    Попытка %attempts% из 30: OpenSearch еще не готов...
    timeout /t 5 /nobreak
    goto check
)

:continue
echo OpenSearch работает через балансировщик!
echo.

echo [5/7] Создаем индекс с 1 репликой и маппингом...
curl -X PUT "localhost:9200/test-index" -H "Content-Type: application/json" --data-binary "@index-definition.json"
echo.

echo [6/7] Добавляем 10 тестовых документов...
for /l %%i in (1,1,10) do (
    curl -X POST "localhost:9200/test-index/_doc/%%i?refresh=wait_for" -H "Content-Type: application/json" -d "{\"title\":\"Документ %%i\",\"views\":%%i}" -s >nul
    if %%i==1 echo    Загрузка: 10%%...
    if %%i==5 echo    Загрузка: 50%%...
    if %%i==10 echo    Загрузка: 100%%...
)

timeout /t 2 /nobreak
curl -X POST "localhost:9200/test-index/_refresh" -s >nul

echo [7/7] ПРОВЕРКА РЕЗУЛЬТАТА:
echo.
echo ШАРДЫ ИНДЕКСА:
curl -X GET "localhost:9200/_cat/shards/test-index?v"
echo.
echo КОЛИЧЕСТВО ДОКУМЕНТОВ:
curl -X GET "localhost:9200/test-index/_count?pretty"

echo.
echo ========================================
echo ГОТОВО. Старый кластер настроен.
echo Дальше: migrate-nodes.bat, затем remove-old-nodes.bat
echo ========================================
pause
