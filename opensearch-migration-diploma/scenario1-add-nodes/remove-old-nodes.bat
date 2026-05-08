@echo off
chcp 65001 > nul
echo ========================================
echo    ЗАВЕРШЕНИЕ МИГРАЦИИ
echo ========================================
echo.

cd /d %~dp0

echo [1/5] Текущее расположение шардов:
curl -X GET "localhost:9200/_cat/shards/test-index?v"
echo.
echo Если шарды еще на старых нодах — подождите и снова запустите этот скрипт.
pause

echo [2/5] Переключаем nginx на только НОВЫЕ ноды...
copy /Y nginx-new.conf nginx.conf
if %errorlevel% neq 0 (
    echo ОШИБКА: нет файла nginx-new.conf
    pause
    exit /b 1
)
docker-compose restart opensearch-proxy
echo nginx перенастроен.
echo.

echo [3/5] Останавливаем старые ноды...
docker-compose stop old-node-1 old-node-2

echo [4/5] Пауза 10 сек...
timeout /t 10 /nobreak

echo [5/5] Финальная проверка...
echo.
echo НОДЫ:
curl -X GET "localhost:9200/_cat/nodes?v"
echo.
echo ШАРДЫ:
curl -X GET "localhost:9200/_cat/shards/test-index?v"
echo.
echo ЗДОРОВЬЕ КЛАСТЕРА:
curl -X GET "localhost:9200/_cluster/health?pretty"
echo.
echo ДОКУМЕНТЫ:
curl -X GET "localhost:9200/test-index/_count?pretty"

echo.
echo ========================================
echo МИГРАЦИЯ ЗАВЕРШЕНА.
echo API: http://localhost:9200  Dashboards: http://localhost:5601
echo Прямой доступ: new-node-1 :9203, new-node-2 :9204
echo ========================================
pause
