# ============================================================
# Кейс №4: Hot-Warm архитектура OpenSearch
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}
$ErrorActionPreference = "Stop"

$BaseUrl = "http://localhost:9200"
$PolicyId = "logs-hot-warm-delete"
$TemplateName = "logs-data-stream-template"
$DataStreamName = "logs"

function Show-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================"
    Write-Host $Text
    Write-Host "============================================================"
}

function New-Url {
    param([string]$Path)
    return ($BaseUrl + $Path)
}

function Invoke-OpenSearch {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [object]$Body = $null
    )

    $uri = New-Url $Path

    try {
        if ($null -eq $Body) {
            return Invoke-RestMethod -Method $Method -Uri $uri
        }

        $json = $Body | ConvertTo-Json -Depth 80
        return Invoke-RestMethod -Method $Method -Uri $uri -Body $json -ContentType "application/json"
    }
    catch {
        Write-Host ""
        Write-Host "ОШИБКА ЗАПРОСА К OPENSEARCH:" -ForegroundColor Red
        Write-Host "$Method $uri" -ForegroundColor Yellow

        if ($null -ne $Body) {
            Write-Host "Тело запроса:" -ForegroundColor Yellow
            Write-Host ($Body | ConvertTo-Json -Depth 80)
        }

        if ($_.Exception.Response -ne $null) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Host "Ответ OpenSearch:" -ForegroundColor Yellow
                Write-Host $responseBody
            } catch {}
        }
        throw
    }
}

function Invoke-OpenSearchText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $uri = $BaseUrl + $Path

    try {
        return (Invoke-WebRequest -Uri $uri -UseBasicParsing).Content
    }
    catch {
        Write-Host ""
        Write-Host "ОШИБКА ТЕКСТОВОГО ЗАПРОСА К OPENSEARCH:" -ForegroundColor Red
        Write-Host "GET $uri" -ForegroundColor Yellow

        if ($_.Exception.Response -ne $null) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Host "Ответ OpenSearch:" -ForegroundColor Yellow
                Write-Host $responseBody
            }
            catch {
                Write-Host "Не удалось прочитать тело ответа OpenSearch."
            }
        }

        throw
    }
}

function Wait-ClusterReady {
    Show-Header "[3/9] Ожидание готовности кластера OpenSearch"

    $healthUrl = $BaseUrl + "/_cluster/health?wait_for_nodes=5&wait_for_status=yellow&timeout=5s"

    for ($i = 1; $i -le 90; $i++) {
        try {
            $health = Invoke-RestMethod -Method "GET" -Uri $healthUrl -TimeoutSec 10

            $status = $health.status
            $nodes = [int]$health.number_of_nodes

            Write-Host "Попытка ${i}: статус=$status, нод=$nodes"

            if ($nodes -eq 5 -and ($status -eq "yellow" -or $status -eq "green")) {
                Write-Host "Кластер готов." -ForegroundColor Green
                return
            }
        }
        catch {
            Write-Host "Попытка ${i}: OpenSearch еще запускается..."
        }

        Start-Sleep -Seconds 5
    }

    Write-Host ""
    Write-Host "Кластер не стал готовым. Показываю статус контейнеров:" -ForegroundColor Yellow
    docker compose ps

    Write-Host ""
    Write-Host "Последние логи os-master:" -ForegroundColor Yellow
    docker logs os-master --tail 80

    throw "Кластер OpenSearch не стал готовым за отведенное время."
}

function Wait-NoShardMovement {
    Write-Host ""
    Write-Host "Ожидание завершения перемещения/инициализации шардов..."

    for ($i = 1; $i -le 30; $i++) {
        $health = Invoke-OpenSearch -Method 'GET' -Path '/_cluster/health'

        $relocating = [int]$health.relocating_shards
        $initializing = [int]$health.initializing_shards
        $unassigned = [int]$health.unassigned_shards

        if ($relocating -eq 0 -and $initializing -eq 0 -and $unassigned -eq 0) {
            Write-Host "Шарды стабильны." -ForegroundColor Green
            return
        }

        Write-Host "Попытка ${i}: relocating=$relocating, initializing=$initializing, unassigned=$unassigned"
        Start-Sleep -Seconds 3
    }

    Write-Host "Предупреждение: часть шардов еще может перемещаться." -ForegroundColor Yellow
}

function Get-DataStreamSummary {
    try {
        $dsResponse = Invoke-OpenSearch -Method 'GET' -Path "/_data_stream/$DataStreamName"

        if ($dsResponse.data_streams.Count -eq 0) {
            Write-Host "Data stream '$DataStreamName' пока не найден."
            return
        }

        $ds = $dsResponse.data_streams[0]
        Write-Host ""
        Write-Host "DATA STREAM:"
        Write-Host "Имя: $($ds.name)"
        Write-Host "Поколение: $($ds.generation)"
        Write-Host "Статус: $($ds.status)"
        Write-Host "Backing indices:"
        foreach ($idx in $ds.indices) {
            Write-Host "  - $($idx.index_name)"
        }
    }
    catch {
        Write-Host "Не удалось получить data stream."
    }
}

function Get-IsmSummary {
    try {
        $explain = Invoke-OpenSearch -Method 'GET' -Path '/_plugins/_ism/explain/.ds-logs-*'

        Write-Host ""
        Write-Host "ISM LIFECYCLE:"

        $properties = $explain.PSObject.Properties | Where-Object { $_.Name -like '.ds-logs-*' }

        if ($properties.Count -eq 0) {
            Write-Host "Нет managed indices."
            return
        }

        foreach ($prop in $properties) {
            $name = $prop.Name
            $value = $prop.Value

            $policy = $value.policy_id
            $enabled = $value.enabled
            $state = '-'
            $transition = '-'
            $action = '-'
            $step = '-'
            $message = '-'

            if ($value.state -ne $null) { $state = $value.state.name }
            if ($value.transition_to -ne $null) { $transition = $value.transition_to }
            if ($value.action -ne $null) { $action = $value.action.name }
            if ($value.step -ne $null) { $step = $value.step.name }
            if ($value.info -ne $null -and $value.info.message -ne $null) { $message = $value.info.message }

            Write-Host ""
            Write-Host "Индекс: $name"
            Write-Host "  policy:     $policy"
            Write-Host "  enabled:    $enabled"
            Write-Host "  state:      $state"
            Write-Host "  action:     $action"
            Write-Host "  step:       $step"
            Write-Host "  transition: $transition"
            Write-Host "  info:       $message"
        }
    }
    catch {
        Write-Host "Не удалось получить ISM explain."
    }
}

function Get-ShardsSummary {
    Write-Host ""
    Write-Host "ШАРДЫ DATA STREAM:"
    $path = '/_cat/shards/.ds-logs-*?v&h=index,shard,prirep,state,docs,store,node'
    Write-Host (Invoke-OpenSearchText -Path $path)
}

function Get-IndicesSummary {
    Write-Host ""
    Write-Host "ИНДЕКСЫ:"
    $path = '/_cat/indices/.ds-logs-*?v&h=health,status,index,pri,rep,docs.count,store.size'
    Write-Host (Invoke-OpenSearchText -Path $path)
}

function Get-NodeAttributesSummary {
    Write-Host ""
    Write-Host "АТРИБУТЫ НОД:"
    $path = '/_cat/nodeattrs?v&h=node,attr,value'
    Write-Host (Invoke-OpenSearchText -Path $path)
}

function Show-CurrentStateExplanation {
    Write-Host ""
    Write-Host "КАК ЧИТАТЬ РЕЗУЛЬТАТ:" -ForegroundColor Cyan
    Write-Host "1. Новый write-index сначала должен находиться на hot-нодах: os-hot1 / os-hot2."
    Write-Host "2. После rollover старый индекс должен перейти в состояние warm."
    Write-Host "3. После allocation шарды старого индекса должны переехать на os-warm1 / os-warm2."
    Write-Host "4. После перехода в delete старый индекс должен исчезнуть из data stream."
    Write-Host "5. Если новые индексы имеют 0 documents — это нормально, если после rollover новые логи не загружались."
}

function Show-CompactCheck {
    param([int]$Number, [int]$Total)

    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host ""
    Write-Host "================ ПРОВЕРКА $Number / $Total | $now ================" -ForegroundColor Cyan

    Get-DataStreamSummary
    Get-IsmSummary
    Get-ShardsSummary
    Get-IndicesSummary

    Write-Host ""
    Write-Host "Кратко:"
    Write-Host "- Смотри поле state в ISM: hot -> warm -> delete."
    Write-Host "- Смотри колонку node в SHARDS: сначала os-hot*, потом os-warm*."
    Write-Host "- После delete старый индекс исчезнет из DATA STREAM и INDICES."
}

Show-Header "КЕЙС №4: Hot-Warm архитектура OpenSearch"

Show-Header "[1/9] Очистка старых контейнеров и volume"
docker compose down -v

Show-Header "[2/9] Запуск кластера OpenSearch"
docker compose up -d

Wait-ClusterReady

Show-Header "[4/9] Проверка health и температурных атрибутов нод"

$clusterHealth = Invoke-OpenSearch -Method 'GET' -Path '/_cluster/health'
Write-Host ($clusterHealth | ConvertTo-Json -Depth 10)

Write-Host ""
Write-Host "НОДЫ:"
$nodesPath = '/_cat/nodes?v&h=name,ip,node.role,master'
Write-Host (Invoke-OpenSearchText -Path $nodesPath)

Get-NodeAttributesSummary
Wait-NoShardMovement

Show-Header "[5/9] Ускорение интервала ISM до 1 минуты"

$settingsBody = @{
    persistent = @{
        plugins = @{
            index_state_management = @{
                job_interval = 1
            }
        }
    }
}

Write-Host (Invoke-OpenSearch -Method 'PUT' -Path '/_cluster/settings' -Body $settingsBody | ConvertTo-Json -Depth 20)

Show-Header "[6/9] Создание политики жизненного цикла: hot -> warm -> delete"

$policyBody = @{
    policy = @{
        description = 'Case 4: hot-warm-delete lifecycle for logs data stream backing indexes'
        schema_version = 1
        default_state = 'hot'
        states = @(
            @{
                name = 'hot'
                actions = @(
                    @{
                        rollover = @{
                            min_index_age = '1m'
                            min_size = '100mb'
                        }
                    }
                )
                transitions = @(
                    @{
                        state_name = 'warm'
                        conditions = @{
                            min_rollover_age = '1m'
                        }
                    }
                )
            },
            @{
                name = 'warm'
                actions = @(
                    @{
                        allocation = @{
                            require = @{
                                temp = 'warm'
                            }
                        }
                    }
                )
                transitions = @(
                    @{
                        state_name = 'delete'
                        conditions = @{
                            min_index_age = '3m'
                        }
                    }
                )
            },
            @{
                name = 'delete'
                actions = @(
                    @{
                        delete = @{}
                    }
                )
                transitions = @()
            }
        )
        ism_template = @(
            @{
                index_patterns = @('.ds-logs-*')
                priority = 100
            }
        )
    }
}

Write-Host (Invoke-OpenSearch -Method 'PUT' -Path "/_plugins/_ism/policies/$PolicyId" -Body $policyBody | ConvertTo-Json -Depth 80)

Show-Header "[7/9] Создание index template для data stream logs"

$templateBody = @{
    index_patterns = @('logs')
    data_stream = @{
        timestamp_field = @{
            name = '@timestamp'
        }
    }
    template = @{
        settings = @{
            number_of_shards = 1
            number_of_replicas = 1
            'index.routing.allocation.require.temp' = 'hot'
            'plugins.index_state_management.policy_id' = $PolicyId
        }
        mappings = @{
            properties = @{
                level = @{ type = 'keyword' }
                trace_id = @{ type = 'keyword' }
                service = @{ type = 'keyword' }
                host = @{ type = 'keyword' }
                '@timestamp' = @{ type = 'date' }
                message = @{ type = 'text' }
            }
        }
    }
    priority = 500
}

Write-Host (Invoke-OpenSearch -Method 'PUT' -Path "/_index_template/$TemplateName" -Body $templateBody | ConvertTo-Json -Depth 80)

Show-Header "[8/9] Загрузка тестовых логов в data stream"

$bulkLines = New-Object System.Collections.Generic.List[string]

for ($i = 1; $i -le 5000; $i++) {
    $bulkLines.Add('{ "create": { } }')

    $doc = @{
        '@timestamp' = (Get-Date).ToUniversalTime().ToString('o')
        level = 'INFO'
        trace_id = "trace-$i"
        service = 'payment-service'
        host = "app-$((($i - 1) % 3) + 1)"
        message = "Test log message number $i for OpenSearch hot-warm lifecycle case"
    }

    $bulkLines.Add(($doc | ConvertTo-Json -Compress))
}

$bulkBody = ($bulkLines -join "`n") + "`n"

try {
    $bulkResponse = Invoke-RestMethod -Method 'POST' -Uri (New-Url "/$DataStreamName/_bulk") -Body $bulkBody -ContentType 'application/x-ndjson'
    Write-Host "Загружено тестовых документов: 5000"
    Write-Host "Bulk errors: $($bulkResponse.errors)"

    if ($bulkResponse.errors -eq $true) {
        Write-Host "ВНИМАНИЕ: bulk-загрузка вернула ошибки." -ForegroundColor Yellow
        Write-Host ($bulkResponse | ConvertTo-Json -Depth 20)
    }
}
catch {
    Write-Host "Ошибка bulk-загрузки." -ForegroundColor Red

    if ($_.Exception.Response -ne $null) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host $responseBody
        } catch {}
    }
    throw
}

Wait-NoShardMovement

Write-Host ""
Write-Host "Принудительно применяем ISM policy к существующим backing indices, если template не успел сделать это автоматически."

$addPolicyBody = @{ policy_id = $PolicyId }

try {
    Write-Host (Invoke-OpenSearch -Method 'POST' -Path '/_plugins/_ism/add/.ds-logs-*' -Body $addPolicyBody | ConvertTo-Json -Depth 20)
}
catch {
    Write-Host "Policy add мог вернуть ошибку, если policy уже применена. Продолжаем." -ForegroundColor Yellow
}

Show-Header "[9/9] Наблюдение за жизненным циклом индексов"
Show-CurrentStateExplanation

for ($check = 1; $check -le 15; $check++) {
    Show-CompactCheck -Number $check -Total 15

    if ($check -lt 15) {
        Write-Host ""
        Write-Host "Ждем 65 секунд до следующей проверки..."
        Start-Sleep -Seconds 65
    }
}

Show-Header "Кейс завершен"
Write-Host "Что должно было произойти:"
Write-Host "1. .ds-logs-000001 сначала находился на hot-нодах."
Write-Host "2. После rollover появился .ds-logs-000002."
Write-Host "3. Старый индекс .ds-logs-000001 перешел в warm."
Write-Host "4. Его шарды переехали на os-warm1 / os-warm2."
Write-Host "5. Затем старый индекс был удален."
Write-Host ""
Write-Host "Если новые индексы содержат 0 документов — это нормально."
Write-Host "Это значит, что после rollover новые документы не загружались."
