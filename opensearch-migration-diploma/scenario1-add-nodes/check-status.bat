@echo off
chcp 65001 > nul
:loop
cls
echo ========================================
echo    СТАТУС МИГРАЦИИ (обновление каждые 5 сек)
echo    Нажми Ctrl+C для выхода
echo ========================================
echo.
echo ТЕКУЩЕЕ РАСПОЛОЖЕНИЕ ШАРДОВ:
curl -X GET "localhost:9200/_cat/shards/test-index?v" 2>nul
echo.
echo СТАТУС КЛАСТЕРА:
curl -X GET "localhost:9200/_cluster/health?pretty" 2>nul | findstr "status"
echo.
echo НОДЫ В КЛАСТЕРЕ:
curl -X GET "localhost:9200/_cat/nodes?v" 2>nul
echo.
echo КОЛИЧЕСТВО ДОКУМЕНТОВ:
curl -X GET "localhost:9200/test-index/_count?pretty" 2>nul | findstr "count"
timeout /t 5 /nobreak >nul
goto loop