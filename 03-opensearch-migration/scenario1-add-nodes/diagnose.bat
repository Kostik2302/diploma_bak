@echo off
chcp 65001 > nul
echo ========================================
echo    ДИАГНОСТИКА ПРОБЛЕМ
echo ========================================
echo.

echo [1/5] Статус всех контейнеров:
docker ps -a
echo.

echo [2/5] Логи old-node-1 (последние 20 строк):
docker logs old-node-1 --tail 20
echo.

echo [3/5] Логи old-node-2 (последние 20 строк):
docker logs old-node-2 --tail 20
echo.

echo [4/5] Использование памяти Docker:
docker system df
echo.

echo [5/5] Свободная память системы:
wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value
echo.

echo ========================================
echo    Проверка портов:
netstat -ano | findstr :9200
netstat -ano | findstr :5601
echo ========================================
pause