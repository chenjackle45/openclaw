---
summary: "日誌概述：檔案日誌、主控台輸出、CLI 即時尾隨和 Control UI"
read_when:
  - 您需要初學者友善的日誌概述
  - 您想配置日誌級別或格式
  - 您正在進行故障排除並需要快速找到日誌
title: "Logging Overview（日誌）"
---

# Logging（日誌）

OpenClaw 在兩個地方記錄日誌：

- **檔案日誌** (JSON lines) 由 Gateway 寫入
- **主控台輸出** 顯示在終端和 Control UI 中

此頁面說明日誌位置、如何讀取日誌，以及如何配置日誌級別和格式。

## 日誌位置

預設情況下，Gateway 在以下位置寫入滾動日誌檔案：

`/tmp/openclaw/openclaw-YYYY-MM-DD.log`

日期使用 gateway host 的本地時區。

您可以在 `~/.openclaw/openclaw.json` 中覆寫此設定：

```json
{
  "logging": {
    "file": "/path/to/openclaw.log"
  }
}
```

## 如何讀取日誌

### CLI：即時尾隨（推薦）

使用 CLI 通過 RPC 尾隨 gateway 日誌檔案：

```bash
openclaw logs --follow
```

輸出模式：

- **TTY sessions**：漂亮、彩色、結構化日誌行
- **Non-TTY sessions**：純文字
- `--json`：換行分隔 JSON（每行一個日誌事件）
- `--plain`：在 TTY sessions 中強制使用純文字
- `--no-color`：禁用 ANSI 顏色

在 JSON 模式中，CLI 發出 `type` 標記的對象：

- `meta`：串流中繼資料（檔案、遊標、大小）
- `log`：解析的日誌條目
- `notice`：截斷 / 輪換提示
- `raw`：未解析的日誌行

如果 Gateway 無法連接，CLI 會列印簡短提示以執行：

```bash
openclaw doctor
```

### Control UI（網頁）

Control UI 的 **Logs** 標籤使用 `logs.tail` 尾隨同一檔案。
請參閱 [/web/control-ui](/zh-Hant/web/control-ui) 瞭解如何開啟它。

### 僅限頻道的日誌

若要篩選頻道活動 (WhatsApp/Telegram 等)，請使用：

```bash
openclaw channels logs --channel whatsapp
```

## 日誌格式

### 檔案日誌 (JSONL)

日誌檔案中的每一行都是 JSON 物件。CLI 和 Control UI 解析這些條目以呈現結構化輸出（時間、級別、子系統、訊息）。

### 主控台輸出

主控台日誌為 **TTY 感知**，並為可讀性進行格式化：

- 子系統前綴（例如 `gateway/channels/whatsapp`）
- 級別著色（info/warn/error）
- 可選的簡潔或 JSON 模式

主控台格式由 `logging.consoleStyle` 控制。

## 配置日誌

所有日誌配置都位於 `~/.openclaw/openclaw.json` 中的 `logging` 下。

```json
{
  "logging": {
    "level": "info",
    "file": "/tmp/openclaw/openclaw-YYYY-MM-DD.log",
    "consoleLevel": "info",
    "consoleStyle": "pretty",
    "redactSensitive": "tools",
    "redactPatterns": ["sk-.*"]
  }
}
```

### 日誌級別

- `logging.level`：**檔案日誌** (JSONL) 級別
- `logging.consoleLevel`：**主控台**詳細程度級別

您可以通過 **`OPENCLAW_LOG_LEVEL`** 環境變數（例如 `OPENCLAW_LOG_LEVEL=debug`）覆寫兩者。環境變數優先於配置檔案，因此您可以在不編輯 `openclaw.json` 的情況下提高單次執行的詳細程度。您也可以傳遞全域 CLI 選項 **`--log-level <level>`**（例如，`openclaw --log-level debug gateway run`），它會覆寫該命令的環境變數。

`--verbose` 只影響主控台輸出；它不改變檔案日誌級別。

### 主控台樣式

`logging.consoleStyle`：

- `pretty`：人類友善、彩色、帶時間戳
- `compact`：更緊湊的輸出（最適合長會話）
- `json`：每行 JSON（用於日誌處理器）

### 審訂

工具摘要可以在到達主控台前審訂敏感令牌：

- `logging.redactSensitive`：`off` | `tools` (預設：`tools`)
- `logging.redactPatterns`：正規表達式字符串清單以覆寫預設集

審訂僅影響 **主控台輸出**，不改變檔案日誌。

## 診斷 + OpenTelemetry

診斷是結構化、機械可讀事件，用於模型執行 **和** 訊息流遙測（webhooks、佇列、會話狀態）。它們不會 **取代** 日誌；它們存在以供應度量、追蹤和其他匯出器。

診斷事件在進程內發出，但匯出器僅在啟用診斷和匯出器外掛時才連接。

### OpenTelemetry vs OTLP

- **OpenTelemetry (OTel)**：追蹤、度量和日誌的資料模型 + SDK。
- **OTLP**：用於將 OTel 資料匯出到蒐集器/後端的網路協定。
- OpenClaw 今天透過 **OTLP/HTTP (protobuf)** 匯出。

### 匯出的信號

- **度量**：計數器 + 直方圖（令牌使用、訊息流、佇列）
- **追蹤**：模型使用 + webhook/訊息處理的跨度
- **日誌**：在啟用 `diagnostics.otel.logs` 時通過 OTLP 匯出。日誌量可能很高；請牢記 `logging.level` 和匯出器篩選器。

### 診斷事件目錄

模型使用：

- `model.usage`：令牌、成本、持續時間、上下文、提供者/模型/頻道、會話 id。

訊息流：

- `webhook.received`：每個頻道的 webhook 入口
- `webhook.processed`：webhook 已處理 + 持續時間
- `webhook.error`：webhook 處理器錯誤
- `message.queued`：訊息排隊等待處理
- `message.processed`：結果 + 持續時間 + 可選錯誤

佇列 + 會話：

- `queue.lane.enqueue`：命令佇列通道入隊 + 深度
- `queue.lane.dequeue`：命令佇列通道出隊 + 等待時間
- `session.state`：會話狀態轉換 + 原因
- `session.stuck`：會話卡住警告 + 年齡
- `run.attempt`：執行重試/嘗試中繼資料
- `diagnostic.heartbeat`：聚合計數器 (webhooks/queue/session)

### 啟用診斷（無匯出器）

如果您想讓診斷事件可供外掛或自訂接收器使用，請使用此選項：

```json
{
  "diagnostics": {
    "enabled": true
  }
}
```

### 診斷標誌（目標日誌）

使用標誌打開額外的、目標調試日誌，而無需提高 `logging.level`。
標誌不區分大小寫並支援萬用字符（例如 `telegram.*` 或 `*`）。

```json
{
  "diagnostics": {
    "flags": ["telegram.http"]
  }
}
```

環境覆寫（一次性）：

```
OPENCLAW_DIAGNOSTICS=telegram.http,telegram.payload
```

注意：

- 標誌日誌進入標準日誌檔案（與 `logging.file` 相同）。
- 輸出仍根據 `logging.redactSensitive` 進行審訂。
- 完整指南：[/diagnostics/flags](/zh-Hant/diagnostics/flags)。

### 匯出到 OpenTelemetry

診斷可通過 `diagnostics-otel` 外掛 (OTLP/HTTP) 匯出。這適用於任何接受 OTLP/HTTP 的 OpenTelemetry 蒐集器/後端。

```json
{
  "plugins": {
    "allow": ["diagnostics-otel"],
    "entries": {
      "diagnostics-otel": {
        "enabled": true
      }
    }
  },
  "diagnostics": {
    "enabled": true,
    "otel": {
      "enabled": true,
      "endpoint": "http://otel-collector:4318",
      "protocol": "http/protobuf",
      "serviceName": "openclaw-gateway",
      "traces": true,
      "metrics": true,
      "logs": true,
      "sampleRate": 0.2,
      "flushIntervalMs": 60000
    }
  }
}
```

注意：

- 您也可以使用 `openclaw plugins enable diagnostics-otel` 啟用外掛。
- `protocol` 目前僅支援 `http/protobuf`。`grpc` 被忽略。
- 度量包括令牌使用、成本、上下文大小、執行持續時間和訊息流計數器/直方圖 (webhooks、佇列、會話狀態、佇列深度/等待)。
- 追蹤/度量可以使用 `traces` / `metrics` 進行切換（預設：開啟）。追蹤在啟用時包括模型使用跨度加上 webhook/訊息處理跨度。
- 當您的蒐集器需要認證時設定 `headers`。
- 支援環境變數：`OTEL_EXPORTER_OTLP_ENDPOINT`、`OTEL_SERVICE_NAME`、`OTEL_EXPORTER_OTLP_PROTOCOL`。

### 匯出的度量（名稱 + 類型）

模型使用：

- `openclaw.tokens` (counter, attrs: `openclaw.token`, `openclaw.channel`, `openclaw.provider`, `openclaw.model`)
- `openclaw.cost.usd` (counter, attrs: `openclaw.channel`, `openclaw.provider`, `openclaw.model`)
- `openclaw.run.duration_ms` (histogram, attrs: `openclaw.channel`, `openclaw.provider`, `openclaw.model`)
- `openclaw.context.tokens` (histogram, attrs: `openclaw.context`, `openclaw.channel`, `openclaw.provider`, `openclaw.model`)

訊息流：

- `openclaw.webhook.received` (counter, attrs: `openclaw.channel`, `openclaw.webhook`)
- `openclaw.webhook.error` (counter, attrs: `openclaw.channel`, `openclaw.webhook`)
- `openclaw.webhook.duration_ms` (histogram, attrs: `openclaw.channel`, `openclaw.webhook`)
- `openclaw.message.queued` (counter, attrs: `openclaw.channel`, `openclaw.source`)
- `openclaw.message.processed` (counter, attrs: `openclaw.channel`, `openclaw.outcome`)
- `openclaw.message.duration_ms` (histogram, attrs: `openclaw.channel`, `openclaw.outcome`)

佇列 + 會話：

- `openclaw.queue.lane.enqueue` (counter, attrs: `openclaw.lane`)
- `openclaw.queue.lane.dequeue` (counter, attrs: `openclaw.lane`)
- `openclaw.queue.depth` (histogram, attrs: `openclaw.lane` or `openclaw.channel=heartbeat`)
- `openclaw.queue.wait_ms` (histogram, attrs: `openclaw.lane`)
- `openclaw.session.state` (counter, attrs: `openclaw.state`, `openclaw.reason`)
- `openclaw.session.stuck` (counter, attrs: `openclaw.state`)
- `openclaw.session.stuck_age_ms` (histogram, attrs: `openclaw.state`)
- `openclaw.run.attempt` (counter, attrs: `openclaw.attempt`)

### 匯出的跨度（名稱 + 關鍵屬性）

- `openclaw.model.usage`
  - `openclaw.channel`, `openclaw.provider`, `openclaw.model`
  - `openclaw.sessionKey`, `openclaw.sessionId`
  - `openclaw.tokens.*` (input/output/cache_read/cache_write/total)
- `openclaw.webhook.processed`
  - `openclaw.channel`, `openclaw.webhook`, `openclaw.chatId`
- `openclaw.webhook.error`
  - `openclaw.channel`, `openclaw.webhook`, `openclaw.chatId`, `openclaw.error`
- `openclaw.message.processed`
  - `openclaw.channel`, `openclaw.outcome`, `openclaw.chatId`, `openclaw.messageId`, `openclaw.sessionKey`, `openclaw.sessionId`, `openclaw.reason`
- `openclaw.session.stuck`
  - `openclaw.state`, `openclaw.ageMs`, `openclaw.queueDepth`, `openclaw.sessionKey`, `openclaw.sessionId`

### 採樣 + 刷新

- 追蹤採樣：`diagnostics.otel.sampleRate` (0.0–1.0，僅根跨度)。
- 度量匯出間隔：`diagnostics.otel.flushIntervalMs` (最小 1000ms)。

### 協定注意事項

- OTLP/HTTP 端點可通過 `diagnostics.otel.endpoint` 或 `OTEL_EXPORTER_OTLP_ENDPOINT` 設定。
- 如果端點已包含 `/v1/traces` 或 `/v1/metrics`，則按原樣使用。
- 如果端點已包含 `/v1/logs`，則按原樣用於日誌。
- `diagnostics.otel.logs` 啟用主記錄器輸出的 OTLP 日誌匯出。

### 日誌匯出行為

- OTLP 日誌使用寫入 `logging.file` 的相同結構化記錄。
- 尊重 `logging.level` (檔案日誌級別)。主控台審訂 **不** 適用於 OTLP 日誌。
- 大規模安裝應優先進行 OTLP 蒐集器採樣/篩選。

## 故障排除提示

- **Gateway 無法連接？** 先執行 `openclaw doctor`。
- **日誌為空？** 檢查 Gateway 是否正在執行並寫入 `logging.file` 中的檔案路徑。
- **需要更多詳細資訊？** 將 `logging.level` 設為 `debug` 或 `trace` 並重試。
