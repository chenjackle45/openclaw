---
title: "Logging(日誌)"
summary: "日誌概覽：檔案日誌、控制台輸出、CLI 追蹤和 Control UI"
read_when:
  - 您需要日誌的初學者友善概覽
  - 您想要設定日誌層級或格式
  - 您正在疑難排解並需要快速找到日誌
---

# Logging(日誌)

OpenClaw 在兩個地方記錄日誌：

- **檔案日誌**（JSON 行）由 Gateway 寫入。
- **控制台輸出**顯示在終端機和 Control UI 中。

此頁面解釋日誌的位置、如何讀取以及如何設定日誌層級和格式。

## 日誌在哪裡

預設情況下，Gateway 在以下位置寫入滾動日誌檔案：

`/tmp/openclaw/openclaw-YYYY-MM-DD.log`

日期使用 gateway 主機的本地時區。

您可以在 `~/.openclaw/openclaw.json` 中覆蓋此設定：

```json
{
  "logging": {
    "file": "/path/to/openclaw.log"
  }
}
```

## 如何讀取日誌

### CLI：即時追蹤（推薦）

使用 CLI 透過 RPC 追蹤 gateway 日誌檔案：

```bash
openclaw logs --follow
```

輸出模式：

- **TTY 會話**：美觀、彩色、結構化的日誌行。
- **非 TTY 會話**：純文字。
- `--json`：行分隔的 JSON（每行一個日誌事件）。
- `--plain`：在 TTY 會話中強制使用純文字。
- `--no-color`：停用 ANSI 顏色。

在 JSON 模式下，CLI 發出 `type` 標記的物件：

- `meta`：串流 metadata（檔案、游標、大小）
- `log`：解析的日誌條目
- `notice`：截斷/輪換提示
- `raw`：未解析的日誌行

如果無法到達 Gateway，CLI 會列印一個簡短的提示以執行：

```bash
openclaw doctor
```

### Control UI（web）

Control UI 的 **Logs** 標籤使用 `logs.tail` 追蹤相同的檔案。
請參閱 [/web/control-ui](/web/control-ui) 以了解如何開啟它。

### 僅頻道日誌

要過濾頻道活動（WhatsApp/Telegram 等），請使用：

```bash
openclaw channels logs --channel whatsapp
```

## 日誌格式

### 檔案日誌（JSONL）

日誌檔案中的每一行都是一個 JSON 物件。CLI 和 Control UI 解析這些
條目以呈現結構化輸出（時間、層級、子系統、訊息）。

### 控制台輸出

控制台日誌是 **TTY 感知的**並格式化以提高可讀性：

- 子系統前綴（例如 `gateway/channels/whatsapp`）
- 層級著色（info/warn/error）
- 選用的緊湊或 JSON 模式

控制台格式由 `logging.consoleStyle` 控制。

## 設定日誌

所有日誌設定都在 `~/.openclaw/openclaw.json` 的 `logging` 下。

```json
{
  "logging": {
    "level": "info",
    "file": "/tmp/openclaw/openclaw-YYYY-MM-DD.log",
    "consoleLevel": "info",
    "consoleStyle": "pretty",
    "redactSensitive": "tools",
    "redactPatterns": [
      "sk-.*"
    ]
  }
}
```

### 日誌層級

- `logging.level`：**檔案日誌**（JSONL）層級。
- `logging.consoleLevel`：**控制台**詳細程度層級。

`--verbose` 僅影響控制台輸出；它不會變更檔案日誌層級。

### 控制台樣式

`logging.consoleStyle`：

- `pretty`：人類友善、彩色、帶時間戳記。
- `compact`：更緊湊的輸出（最適合長會話）。
- `json`：每行一個 JSON（用於日誌處理器）。

### 脫敏

工具摘要可以在到達控制台之前脫敏處理敏感 tokens：

- `logging.redactSensitive`：`off` | `tools`（預設：`tools`）
- `logging.redactPatterns`：regex 字串清單以覆蓋預設集

脫敏僅影響**控制台輸出**，不會更改檔案日誌。

## 診斷 + OpenTelemetry

診斷是結構化、機器可讀的事件，用於模型執行**和**
訊息流遙測（webhooks、排隊、會話狀態）。它們**不**
取代日誌；它們的存在是為了提供度量、追蹤和其他匯出器。

診斷事件在程序內發出，但匯出器僅在
診斷 + 匯出器外掛啟用時附加。

### OpenTelemetry vs OTLP

- **OpenTelemetry (OTel)**：trace、metrics 和 logs 的資料模型 + SDK。
- **OTLP**：用於將 OTel 資料匯出到收集器/後端的線協定。
- OpenClaw 目前透過 **OTLP/HTTP (protobuf)** 匯出。

### 匯出的訊號

- **Metrics**：計數器 + 直方圖（token 使用量、訊息流、排隊）。
- **Traces**：用於模型使用 + webhook/訊息處理的 spans。
- **Logs**：當啟用 `diagnostics.otel.logs` 時透過 OTLP 匯出。日誌量可能很高；請記住 `logging.level` 和匯出器過濾器。

### 診斷事件目錄

模型使用：
- `model.usage`：tokens、成本、持續時間、上下文、provider/model/channel、會話 ids。

訊息流：
- `webhook.received`：每個頻道的 webhook 入口。
- `webhook.processed`：webhook 已處理 + 持續時間。
- `webhook.error`：webhook 處理器錯誤。
- `message.queued`：訊息排隊處理。
- `message.processed`：結果 + 持續時間 + 選用錯誤。

Queue + session：
- `queue.lane.enqueue`：指令佇列 lane enqueue + 深度。
- `queue.lane.dequeue`：指令佇列 lane dequeue + 等待時間。
- `session.state`：會話狀態轉換 + 原因。
- `session.stuck`：會話卡住警告 + 時長。
- `run.attempt`：執行重試/嘗試 metadata。
- `diagnostic.heartbeat`：彙總計數器（webhooks/queue/session）。

### 啟用診斷（無匯出器）

如果您希望診斷事件可用於外掛或自訂 sinks，請使用此設定：

```json
{
  "diagnostics": {
    "enabled": true
  }
}
```

### 診斷標誌（針對性日誌）

使用標誌來開啟額外的、針對性的除錯日誌，而無需提高 `logging.level`。
標誌不區分大小寫並支援萬用字元（例如 `telegram.*` 或 `*`）。

```json
{
  "diagnostics": {
    "flags": ["telegram.http"]
  }
}
```

環境變數覆蓋（一次性）：

```
OPENCLAW_DIAGNOSTICS=telegram.http,telegram.payload
```

注意事項：
- 標誌日誌進入標準日誌檔案（與 `logging.file` 相同）。
- 輸出仍根據 `logging.redactSensitive` 脫敏。
- 完整指南：[/diagnostics/flags](/diagnostics/flags)。

### 匯出到 OpenTelemetry

診斷可以透過 `diagnostics-otel` 外掛（OTLP/HTTP）匯出。這
適用於任何接受 OTLP/HTTP 的 OpenTelemetry 收集器/後端。

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

注意事項：
- 您也可以使用 `openclaw plugins enable diagnostics-otel` 啟用外掛。
- `protocol` 目前僅支援 `http/protobuf`。`grpc` 被忽略。
- Metrics 包括 token 使用量、成本、上下文大小、執行持續時間以及訊息流計數器/直方圖（webhooks、排隊、會話狀態、佇列深度/等待）。
- Traces/metrics 可以使用 `traces` / `metrics` 切換（預設：開啟）。Traces 包括模型使用 spans 加上啟用時的 webhook/訊息處理 spans。
- 當您的收集器需要認證時設定 `headers`。
- 支援的環境變數：`OTEL_EXPORTER_OTLP_ENDPOINT`、`OTEL_SERVICE_NAME`、`OTEL_EXPORTER_OTLP_PROTOCOL`。

### 匯出的 metrics（名稱 + 類型）

模型使用：
- `openclaw.tokens`（計數器，屬性：`openclaw.token`、`openclaw.channel`、`openclaw.provider`、`openclaw.model`）
- `openclaw.cost.usd`（計數器，屬性：`openclaw.channel`、`openclaw.provider`、`openclaw.model`）
- `openclaw.run.duration_ms`（直方圖，屬性：`openclaw.channel`、`openclaw.provider`、`openclaw.model`）
- `openclaw.context.tokens`（直方圖，屬性：`openclaw.context`、`openclaw.channel`、`openclaw.provider`、`openclaw.model`）

訊息流：
- `openclaw.webhook.received`（計數器，屬性：`openclaw.channel`、`openclaw.webhook`）
- `openclaw.webhook.error`（計數器，屬性：`openclaw.channel`、`openclaw.webhook`）
- `openclaw.webhook.duration_ms`（直方圖，屬性：`openclaw.channel`、`openclaw.webhook`）
- `openclaw.message.queued`（計數器，屬性：`openclaw.channel`、`openclaw.source`）
- `openclaw.message.processed`（計數器，屬性：`openclaw.channel`、`openclaw.outcome`）
- `openclaw.message.duration_ms`（直方圖，屬性：`openclaw.channel`、`openclaw.outcome`）

Queues + sessions：
- `openclaw.queue.lane.enqueue`（計數器，屬性：`openclaw.lane`）
- `openclaw.queue.lane.dequeue`（計數器，屬性：`openclaw.lane`）
- `openclaw.queue.depth`（直方圖，屬性：`openclaw.lane` 或 `openclaw.channel=heartbeat`）
- `openclaw.queue.wait_ms`（直方圖，屬性：`openclaw.lane`）
- `openclaw.session.state`（計數器，屬性：`openclaw.state`、`openclaw.reason`）
- `openclaw.session.stuck`（計數器，屬性：`openclaw.state`）
- `openclaw.session.stuck_age_ms`（直方圖，屬性：`openclaw.state`）
- `openclaw.run.attempt`（計數器，屬性：`openclaw.attempt`）

### 匯出的 spans（名稱 + 關鍵屬性）

- `openclaw.model.usage`
  - `openclaw.channel`、`openclaw.provider`、`openclaw.model`
  - `openclaw.sessionKey`、`openclaw.sessionId`
  - `openclaw.tokens.*`（input/output/cache_read/cache_write/total）
- `openclaw.webhook.processed`
  - `openclaw.channel`、`openclaw.webhook`、`openclaw.chatId`
- `openclaw.webhook.error`
  - `openclaw.channel`、`openclaw.webhook`、`openclaw.chatId`、`openclaw.error`
- `openclaw.message.processed`
  - `openclaw.channel`、`openclaw.outcome`、`openclaw.chatId`、`openclaw.messageId`、`openclaw.sessionKey`、`openclaw.sessionId`、`openclaw.reason`
- `openclaw.session.stuck`
  - `openclaw.state`、`openclaw.ageMs`、`openclaw.queueDepth`、`openclaw.sessionKey`、`openclaw.sessionId`

### 取樣 + flush

- Trace 取樣：`diagnostics.otel.sampleRate`（0.0–1.0，僅根 spans）。
- Metric 匯出間隔：`diagnostics.otel.flushIntervalMs`（最小 1000ms）。

### 協定注意事項

- OTLP/HTTP 端點可以透過 `diagnostics.otel.endpoint` 或 `OTEL_EXPORTER_OTLP_ENDPOINT` 設定。
- 如果端點已包含 `/v1/traces` 或 `/v1/metrics`，則按原樣使用。
- 如果端點已包含 `/v1/logs`，則按原樣用於日誌。
- `diagnostics.otel.logs` 啟用主日誌記錄器輸出的 OTLP 日誌匯出。

### 日誌匯出行為

- OTLP 日誌使用寫入 `logging.file` 的相同結構化記錄。
- 遵守 `logging.level`（檔案日誌層級）。控制台脫敏**不**適用於 OTLP 日誌。
- 大量安裝應優先使用 OTLP 收集器取樣/過濾。

## 疑難排解提示

- **Gateway 無法到達？**先執行 `openclaw doctor`。
- **日誌為空？**檢查 Gateway 是否正在執行並寫入 `logging.file` 中的檔案路徑。
- **需要更多詳情？**將 `logging.level` 設定為 `debug` 或 `trace` 並重試。
