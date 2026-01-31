---
title: "Timezone(時區處理)"
summary: "代理、封裝與提示詞的時區處理"
read_when:
  - 您需要了解時間戳記如何為模型進行標準化
  - 在系統提示詞中設定使用者時區
---

# Timezones（時區）

OpenClaw 將時間戳記標準化，以便模型看到一個**統一的基準時間**。

## 訊息封裝 (Message envelopes)（預設為本地時間）

入站訊息會被包裝在如下的封裝（envelope）中：

```
[Provider ... 2026-01-05 16:26 PST] message text
```

封裝中的時間戳記**預設為主機本地時間**，精確度為分鐘。

您可以透過以下方式覆寫：

```json5
{
  agents: {
    defaults: {
      envelopeTimezone: "local", // "utc" | "local" | "user" | IANA 時區
      envelopeTimestamp: "on", // "on" | "off"
      envelopeElapsed: "on" // "on" | "off"
    }
  }
}
```

- `envelopeTimezone: "utc"` 使用 UTC。
- `envelopeTimezone: "user"` 使用 `agents.defaults.userTimezone`（若未設定則回退到主機時區）。
- 使用明確的 IANA 時區（例如 `"Asia/Taipei"`）來設定固定偏移量。
- `envelopeTimestamp: "off"` 從封裝標頭中移除絕對時間戳記。
- `envelopeElapsed: "off"` 移除經過時間後綴（例如 `+2m` 的樣式）。

### 範例

**本地時間（預設）：**

```
[Signal Alice +1555 2026-01-18 00:19 PST] hello
```

**固定時區：**

```
[Signal Alice +1555 2026-01-18 06:19 GMT+1] hello
```

**經過時間：**

```
[Signal Alice +1555 +2m 2026-01-18T05:19Z] follow-up
```

## 工具負載（原始供應商數據 + 標準化欄位）

工具呼叫（`channels.discord.readMessages`, `channels.slack.readMessages` 等）會返回**原始的供應商時間戳記**。
我們還會附加標準化欄位以保持一致性：

- `timestampMs`（UTC 紀元毫秒）
- `timestampUtc`（ISO 8601 UTC 字串）

原始供應商欄位將被保留。

## 系統提示詞的使用者時區

設定 `agents.defaults.userTimezone` 以告知模型使用者的本地時區。如果未設定，OpenClaw 會在**運行時解析主機時區**（不會寫入設定檔）。

```json5
{
  agents: { defaults: { userTimezone: "Asia/Taipei" } }
}
```

系統提示詞將包含：
- `Current Date & Time` 區塊，包含當地時間與時區。
- 時間格式：12 小時制或 24 小時制。

您可以透過 `agents.defaults.timeFormat` 控制提示詞格式（`auto` | `12` | `24`）。

詳情請參閱 [Date & Time（日期與時間）](/date-time) 以了解完整行為與範例。
