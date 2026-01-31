---
title: "Streaming(串流與分塊)"
summary: "串流 + 分塊行為（區塊回覆、草稿串流、限制）"
read_when:
  - 解釋串流或分塊在頻道上如何運作
  - 更改區塊串流或頻道分塊行為
  - 除錯重複/過早的區塊回覆或草稿串流
---
# Streaming + chunking（串流 + 分塊）

OpenClaw 有兩個獨立的「串流」層：
- **區塊串流（頻道）：** 在助手寫入時發出完成的**區塊**。這些是正常的頻道訊息（不是 token 增量）。
- **類 Token 串流（僅 Telegram）：** 在生成時用部分文字更新**草稿氣泡**；最終訊息在結束時發送。

今天**沒有真正的 token 串流**到外部頻道訊息。Telegram 草稿串流是唯一的部分串流介面。

## 區塊串流（頻道訊息）

區塊串流在可用時以粗塊發送助手輸出。

```
Model output
  └─ text_delta/events
       ├─ (blockStreamingBreak=text_end)
       │    └─ chunker emits blocks as buffer grows
       └─ (blockStreamingBreak=message_end)
            └─ chunker flushes at message_end
                   └─ channel send (block replies)
```
圖例：
- `text_delta/events`：模型串流事件（對於非串流模型可能稀疏）。
- `chunker`：`EmbeddedBlockChunker` 套用最小/最大邊界 + 斷開偏好。
- `channel send`：實際出站訊息（區塊回覆）。

**控制：**
- `agents.defaults.blockStreamingDefault`：`"on"`/`"off"`（預設 off）。
- 頻道覆寫：`*.blockStreaming`（和每帳戶變體）強制每頻道 `"on"`/`"off"`。
- `agents.defaults.blockStreamingBreak`：`"text_end"` 或 `"message_end"`。
- `agents.defaults.blockStreamingChunk`：`{ minChars, maxChars, breakPreference? }`。
- `agents.defaults.blockStreamingCoalesce`：`{ minChars?, maxChars?, idleMs? }`（發送前合併串流區塊）。
- 頻道硬上限：`*.textChunkLimit`（例如 `channels.whatsapp.textChunkLimit`）。
- 頻道分塊模式：`*.chunkMode`（`length` 預設，`newline` 在空行（段落邊界）處分割，然後進行長度分塊）。
- Discord 軟上限：`channels.discord.maxLinesPerMessage`（預設 17）分割高回覆以避免 UI 裁剪。

**邊界語意：**
- `text_end`：chunker 發出後立即串流區塊；在每個 `text_end` 處刷新。
- `message_end`：等到助手訊息完成，然後刷新緩衝輸出。

`message_end` 如果緩衝文字超過 `maxChars` 仍然使用 chunker，所以它可以在最後發出多個塊。

## 分塊演算法（低/高邊界）

區塊分塊由 `EmbeddedBlockChunker` 實現：
- **低邊界：** 在緩衝區 >= `minChars` 之前不發出（除非強制）。
- **高邊界：** 偏好在 `maxChars` 之前分割；如果強制，在 `maxChars` 處分割。
- **斷開偏好：** `paragraph` → `newline` → `sentence` → `whitespace` → 硬斷開。
- **程式碼區塊：** 永不在區塊內分割；當在 `maxChars` 處強制時，關閉 + 重新開啟區塊以保持 Markdown 有效。

`maxChars` 被限制在頻道 `textChunkLimit`，所以您不能超過每頻道上限。

## 合併（合併串流區塊）

當區塊串流啟用時，OpenClaw 可以在發送之前**合併連續區塊塊**。這減少了「單行垃圾訊息」同時仍提供漸進式輸出。

- 合併等待**閒置間隙**（`idleMs`）然後刷新。
- 緩衝區受 `maxChars` 限制，如果超過則刷新。
- `minChars` 防止微小片段發送，直到累積足夠文字（最終刷新始終發送剩餘文字）。
- 連接器從 `blockStreamingChunk.breakPreference` 衍生（`paragraph` → `\n\n`，`newline` → `\n`，`sentence` → 空格）。
- 頻道覆寫可透過 `*.blockStreamingCoalesce`（包括每帳戶設定）。
- 對於 Signal/Slack/Discord，預設合併 `minChars` 被提升到 1500，除非覆寫。

## 區塊之間的人性化節奏

當區塊串流啟用時，您可以在區塊回覆之間新增**隨機暫停**（在第一個區塊之後）。這使多氣泡回應感覺更自然。

- 設定：`agents.defaults.humanDelay`（透過 `agents.list[].humanDelay` 每代理覆寫）。
- 模式：`off`（預設）、`natural`（800-2500ms）、`custom`（`minMs`/`maxMs`）。
- 僅適用於**區塊回覆**，不適用於最終回覆或工具摘要。

## 「串流塊或全部」

這映射到：
- **串流塊：** `blockStreamingDefault: "on"` + `blockStreamingBreak: "text_end"`（邊生成邊發）。非 Telegram 頻道還需要 `*.blockStreaming: true`。
- **最後全部串流：** `blockStreamingBreak: "message_end"`（刷新一次，如果很長可能多個塊）。
- **無區塊串流：** `blockStreamingDefault: "off"`（僅最終回覆）。

**頻道備註：** 對於非 Telegram 頻道，區塊串流**預設關閉除非** `*.blockStreaming` 明確設為 `true`。Telegram 可以串流草稿（`channels.telegram.streamMode`）而無需區塊回覆。

設定位置提醒：`blockStreaming*` 預設值位於 `agents.defaults` 下，而不是根設定。

## Telegram 草稿串流（類 Token）

Telegram 是唯一有草稿串流的頻道：
- 在**帶主題的私人聊天**中使用 Bot API `sendMessageDraft`。
- `channels.telegram.streamMode: "partial" | "block" | "off"`。
  - `partial`：使用最新串流文字更新草稿。
  - `block`：以分塊區塊更新草稿（相同 chunker 規則）。
  - `off`：無草稿串流。
- 草稿分塊設定（僅用於 `streamMode: "block"`）：`channels.telegram.draftChunk`（預設：`minChars: 200`、`maxChars: 800`）。
- 草稿串流與區塊串流分開；區塊回覆預設關閉，僅透過非 Telegram 頻道上的 `*.blockStreaming: true` 啟用。
- 最終回覆仍是正常訊息。
- `/reasoning stream` 將推理寫入草稿氣泡（僅 Telegram）。

當草稿串流活動時，OpenClaw 停用該回覆的區塊串流以避免雙重串流。

```
Telegram (private + topics)
  └─ sendMessageDraft (draft bubble)
       ├─ streamMode=partial → update latest text
       └─ streamMode=block   → chunker updates draft
  └─ final reply → normal message
```
圖例：
- `sendMessageDraft`：Telegram 草稿氣泡（不是真正的訊息）。
- `final reply`：正常的 Telegram 訊息發送。
