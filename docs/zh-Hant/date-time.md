---
title: "Date time(日期與時間)"
summary: "跨 envelopes、prompts、tools 和 connectors 的日期和時間處理"
read_when:
  - 您正在變更時間戳記如何顯示給模型或使用者
  - 您正在除錯訊息或系統提示詞輸出中的時間格式
---

# Date & Time(日期與時間)

OpenClaw 預設為**傳輸時間戳記使用主機本地時間**和**僅在系統提示詞中使用使用者時區**。
供應商時間戳記被保留，因此工具保留其原生語意（當前時間可透過 `session_status` 取得）。

## 訊息 envelopes（預設為本地）

入站訊息會包裝上時間戳記（分鐘精度）：

```
[Provider ... 2026-01-05 16:26 PST] message text
```

此 envelope 時間戳記**預設為主機本地時間**，無論供應商時區為何。

您可以覆蓋此行為：

```json5
{
  agents: {
    defaults: {
      envelopeTimezone: "local", // "utc" | "local" | "user" | IANA timezone
      envelopeTimestamp: "on", // "on" | "off"
      envelopeElapsed: "on" // "on" | "off"
    }
  }
}
```

- `envelopeTimezone: "utc"` 使用 UTC。
- `envelopeTimezone: "local"` 使用主機時區。
- `envelopeTimezone: "user"` 使用 `agents.defaults.userTimezone`（回退到主機時區）。
- 使用明確的 IANA 時區（例如 `"America/Chicago"`）作為固定區域。
- `envelopeTimestamp: "off"` 從 envelope headers 中移除絕對時間戳記。
- `envelopeElapsed: "off"` 移除經過時間後綴（`+2m` 樣式）。

### 範例

**Local（預設）：**

```
[WhatsApp +1555 2026-01-18 00:19 PST] hello
```

**User timezone：**

```
[WhatsApp +1555 2026-01-18 00:19 CST] hello
```

**經過時間已啟用：**

```
[WhatsApp +1555 +30s 2026-01-18T05:19Z] follow-up
```

## 系統提示詞：Current Date & Time

如果已知使用者時區，系統提示詞包含一個專用的
**Current Date & Time** 區段，**僅包含時區**（無時鐘/時間格式）
以保持提示詞快取穩定：

```
Time zone: America/Chicago
```

當代理需要當前時間時，使用 `session_status` 工具；狀態
卡片包含時間戳記行。

## 系統事件行（預設為本地）

插入到代理上下文中的排隊系統事件前綴有時間戳記，使用與
訊息 envelopes 相同的時區選擇（預設：主機本地）。

```
System: [2026-01-12 12:19:17 PST] Model switched.
```

### 設定使用者時區 + 格式

```json5
{
  agents: {
    defaults: {
      userTimezone: "America/Chicago",
      timeFormat: "auto" // auto | 12 | 24
    }
  }
}
```

- `userTimezone` 設定提示詞上下文的**使用者本地時區**。
- `timeFormat` 控制提示詞中的 **12h/24h 顯示**。`auto` 遵循 OS 偏好。

## 時間格式偵測（auto）

當 `timeFormat: "auto"` 時，OpenClaw 檢查 OS 偏好（macOS/Windows）
並回退到語言環境格式。偵測到的值在**每個程序中快取**
以避免重複的系統呼叫。

## 工具 payloads + connectors（原始供應商時間 + 標準化欄位）

頻道工具返回**供應商原生時間戳記**並新增標準化欄位以保持一致性：

- `timestampMs`：epoch 毫秒（UTC）
- `timestampUtc`：ISO 8601 UTC 字串

原始供應商欄位被保留，因此不會遺失任何資訊。

- Slack：來自 API 的 epoch-like 字串
- Discord：UTC ISO 時間戳記
- Telegram/WhatsApp：供應商特定的數字/ISO 時間戳記

如果您需要本地時間，請使用已知時區在下游轉換它。

## 相關文件

- [System Prompt](/concepts/system-prompt)
- [Timezones](/concepts/timezone)
- [Messages](/concepts/messages)
