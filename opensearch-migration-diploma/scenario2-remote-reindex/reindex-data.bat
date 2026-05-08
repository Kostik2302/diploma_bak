@echo off
chcp 65001 > nul
echo ========================================
echo    REINDEX: Source -^> Destination
echo    Запрос выполняется на localhost:9202
echo ========================================
echo.

cd /d %~dp0

echo [1/4] Документы в Source:
curl -s "localhost:9201/test-index/_count?pretty"
echo.

echo [2/4] Запуск _reindex (wait_for_completion=true, малый объем)...
curl -X POST "localhost:9202/_reindex?wait_for_completion=true&pretty" -H "Content-Type: application/json" -d "{\"source\":{\"remote\":{\"host\":\"http://source-node-1:9200\"},\"index\":\"test-index\",\"size\":100},\"dest\":{\"index\":\"test-index\"}}"
echo.

echo [3/4] Refresh индекса на приёмнике (чтобы _count сразу видел документы)...
curl -s -X POST "localhost:9202/test-index/_refresh"
echo.

echo [4/4] Документы в Destination:
curl -s "localhost:9202/test-index/_count?pretty"
echo.
echo Шарды Destination:
curl -s "localhost:9202/_cat/shards/test-index?v"
echo.
echo ========================================
echo Готово. Проверка: verify-reindex.bat
echo ========================================
pause
