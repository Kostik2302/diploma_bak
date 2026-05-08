@echo off
chcp 65001 > nul
echo ========================================
echo    СЦЕНАРИЙ 1: Миграция на новые ноды
echo ========================================
echo.

cd /d %~dp0

echo [1/6] Отключаем автоматическую ребалансировку...
curl -X PUT "localhost:9200/_cluster/settings" -H "Content-Type: application/json" -d "{\"persistent\":{\"cluster.routing.allocation.enable\":\"none\"}}"
echo ✅ Ребалансировка отключена
echo.

echo [2/6] Запускаем новые ноды...
docker-compose up -d new-node-1 new-node-2
echo Ждем 30 секунд для инициализации...
timeout /t 30 /nobreak

echo [3/6] Проверяем все ноды кластера...
echo.
echo ТЕКУЩИЕ НОДЫ В КЛАСТЕРЕ:
curl -X GET "localhost:9200/_cat/nodes?v"
echo.

echo [4/6] Добавляем старые ноды в исключение...
curl -X PUT "localhost:9200/_cluster/settings" -H "Content-Type: application/json" -d "{\"persistent\":{\"cluster.routing.allocation.exclude._name\":\"old-node-1,old-node-2\"}}"
echo ✅ Старые ноды помечены для исключения

echo [5/6] Включаем автоматическую ребалансировку...
curl -X PUT "localhost:9200/_cluster/settings" -H "Content-Type: application/json" -d "{\"persistent\":{\"cluster.routing.allocation.enable\":\"all\"}}"
echo ✅ Ребалансировка включена, началось перемещение шардов

echo [6/6] Статус после запуска...
echo.
echo РАСПОЛОЖЕНИЕ ШАРДОВ:
curl -X GET "localhost:9200/_cat/shards/test-index?v"

echo.
echo ========================================
echo    МИГРАЦИЯ ЗАПУЩЕНА!
echo    Используйте пункт 3 для отслеживания
echo ========================================
pause