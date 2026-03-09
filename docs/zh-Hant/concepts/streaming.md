---
title: "Streaming and Chunking（串流與分塊）"
summary: "串流 + 分塊行為（區塊回覆、草稿串流、限制）"
read_when:
  - 解釋串流或分塊在頻道上如何運作
  - 變更區塊串流或頻道分塊行為
  - 除錯重複/提早的區塊回覆或頻道預覽串流
---

# 串流 + 分塊

OpenClaw 有兩個獨立的串流層：

- **區塊串流（頻道）：** 在助理撰寫時發送完成的**區塊**。這些是正常的頻道訊息（不是 token delta）。
- **預覽串流（Telegram/Discord/Slack）：** 在生成時更新暫時的**預覽訊息**。

目前**沒有真正的 token delta 串流**到頻道訊息。預覽串流基於訊息（傳送 + 編輯/附加）。

## 區塊串流（頻道訊息）

區塊串流在助理輸出可用時以粗粒度區塊傳送。

```
Model output
  └─ text_delta/events
       ├─ (blockStreamingBreak=text_end)
       │    └─ chunker emits blocks as buffer grows
       └─ (blockStreamingBreak=message_end)
            └─ chunker flushes at message_end
                   └─ channel send (block replies)
```

說明：

- `text_delta/events`：模型串流事件（非串流模型可能稀疏）。
- `chunker`：`EmbeddedBlockChunker` 套用最小/最大邊界 + 分割偏好。
- `channel send`：實際的出站訊息（區塊回覆）。

**控制項：**

- `agents.defaults.blockStreamingDefault`：`"on"`/`"off"`（預設關閉）。
- 頻道覆蓋：`*.blockStreaming`（及每帳號變體）強制每個頻道 `"on"`/`"off"`。
- `agents.defaults.blockStreamingBreak`：`"text_end"` 或 `"message_end"`。
- `agents.defaults.blockStreamingChunk`：`{ minChars, maxChars, breakPreference? }`。
- `agents.defaults.blockStreamingCoalesce`：`{ minChars?, maxChars?, idleMs? }`（傳送前合併串流區塊）。
- 頻道硬性上限：`*.textChunkLimit`（例如 `channels.whatsapp.textChunkLimit`）。
- 頻道分塊模式：`*.chunkMode`（`length` 預設，`newline` 在長度分塊前以空行（段落邊界）分割）。
- Discord 軟性上限：`channels.discord.maxLinesPerMessage`（預設 17）分割高回覆以避免 UI 截斷。

**邊界語義：**

- `text_end`：chunker 發送時立即串流區塊；在每個 `text_end` 時清空。
- `message_end`：等待助理訊息完成，然後清空緩衝輸出。

`message_end` 若緩衝文字超過 `maxChars` 仍使用 chunker，因此可在結束時發送多個區塊。

## 分塊演算法（低/高邊界）

區塊分塊由 `EmbeddedBlockChunker` 實作：

- **低邊界：** 在緩衝區 >= `minChars` 前不發送（除非強制）。
- **高邊界：** 偏好在 `maxChars` 前分割；若強制，在 `maxChars` 處分割。
- **分割偏好：** `paragraph` → `newline` → `sentence` → `whitespace` → 硬分割。
- **程式碼圍欄：** 永不在圍欄內分割；在 `maxChars` 強制時，關閉 + 重新開啟圍欄以保持 Markdown 有效。

`maxChars` 被夾在頻道 `textChunkLimit`，因此無法超過每頻道上限。

## 合併（合併串流區塊）

啟用區塊串流時，OpenClaw 可以在傳送前**合併連續的區塊**。
這在仍提供漸進式輸出的同時減少「單行訊息轟炸」。

- 合併等待**閒置間隔**（`idleMs`）後清空。
- 緩衝區以 `maxChars` 為上限，超過時清空。
- `minChars` 防止微小片段傳送，直到積累足夠文字
  （最終清空始終傳送剩餘文字）。
- 連接符源自 `blockStreamingChunk.breakPreference`
  （`paragraph` → `\n\n`，`newline` → `\n`，`sentence` → 空格）。
- 可透過 `*.blockStreamingCoalesce` 設定頻道覆蓋（包括每帳號設定）。
- 預設合併 `minChars` 對 Signal/Slack/Discord 提升至 1500，除非被覆蓋。

## 區塊間的人性化節奏

啟用區塊串流時，可以在區塊回覆之間添加**隨機暫停**（在第一個區塊之後）。這讓多泡泡回覆感覺更自然。

- 設定：`agents.defaults.humanDelay`（透過 `agents.list[].humanDelay` 按 agent 覆蓋）。
- 模式：`off`（預設）、`natural`（800-2500ms）、`custom`（`minMs`/`maxMs`）。
- 僅適用於**區塊回覆**，不適用於最終回覆或工具摘要。

## 「串流區塊或全部」

對應關係：

- **串流區塊：** `blockStreamingDefault: "on"` + `blockStreamingBreak: "text_end"`（隨時發送）。非 Telegram 頻道也需要 `*.blockStreaming: true`。
- **全部在結束時串流：** `blockStreamingBreak: "message_end"`（清空一次，若很長可能有多個區塊）。
- **無區塊串流：** `blockStreamingDefault: "off"`（僅最終回覆）。

**頻道注意：** 區塊串流**預設關閉**，除非
`*.blockStreaming` 明確設為 `true`。頻道可以串流即時預覽
（`channels.<channel>.streaming`）而不使用區塊回覆。

設定位置提醒：`blockStreaming*` 預設值位於
`agents.defaults` 下，不在根設定中。

## 預覽串流模式

標準 key：`channels.<channel>.streaming`

模式：

- `off`：停用預覽串流。
- `partial`：單一預覽，以最新文字替換。
- `block`：以分塊/附加步驟更新預覽。
- `progress`：生成期間的進度/狀態預覽，完成時顯示最終答案。

### 頻道對應

| 頻道     | `off` | `partial` | `block` | `progress`     |
| -------- | ----- | --------- | ------- | -------------- |
| Telegram | ✅    | ✅        | ✅      | 對應 `partial` |
| Discord  | ✅    | ✅        | ✅      | 對應 `partial` |
| Slack    | ✅    | ✅        | ✅      | ✅             |

僅 Slack：

- `channels.slack.nativeStreaming` 在 `streaming=partial` 時切換 Slack 原生串流 API 呼叫（預設：`true`）。

舊版 key 遷移：

- Telegram：`streamMode` + 布林值 `streaming` 自動遷移至 `streaming` enum。
- Discord：`streamMode` + 布林值 `streaming` 自動遷移至 `streaming` enum。
- Slack：`streamMode` 自動遷移至 `streaming` enum；布林值 `streaming` 自動遷移至 `nativeStreaming`。

### 執行時行為

Telegram：

- 在 DM 和群組/主題中使用 `sendMessage` + `editMessageText` 預覽更新。
- 當 Telegram 區塊串流明確啟用時跳過預覽串流（以避免雙重串流）。
- `/reasoning stream` 可將推理寫入預覽。

Discord：

- 使用傳送 + 編輯預覽訊息。
- `block` 模式使用草稿分塊（`draftChunk`）。
- 當 Discord 區塊串流明確啟用時跳過預覽串流。

Slack：

- `partial` 可在可用時使用 Slack 原生串流（`chat.startStream`/`append`/`stop`）。
- `block` 使用附加式草稿預覽。
- `progress` 使用狀態預覽文字，然後顯示最終答案。
