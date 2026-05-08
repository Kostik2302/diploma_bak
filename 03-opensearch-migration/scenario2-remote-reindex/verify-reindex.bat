@echo off
chcp 65001 > nul
echo ========================================
echo    ПРОВЕРКА REINDEX
echo ========================================
echo.

cd /d %~dp0

echo Source (9201) _count:
curl -s "localhost:9201/test-index/_count?pretty"
echo.

echo Destination (9202) _count:
curl -s "localhost:9202/test-index/_count?pretty"
echo.

echo Документ id=1 в Source:
curl -s "localhost:9201/test-index/_doc/1?pretty"
echo.

echo Документ id=1 в Destination:
curl -s "localhost:9202/test-index/_doc/1?pretty"
echo.

echo Шарды Destination:
curl -s "localhost:9202/_cat/shards/test-index?v"
echo.
pause
