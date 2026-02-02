---
title: "圖片與媒體支援"
summary: "發送、Gateway 與 Agent 回應的圖片與媒體處理規則"
read_when:
  - 修改媒體流水線或附件處理邏輯時
---

# 圖片與媒體支援 — 2025-12-05

WhatsApp 頻道透由 **Baileys Web** 執行。本文件記錄發送、Gateway 和 Agent 回應的目前媒體處理規則。

## 目標

- 透由 `openclaw message send --media` 發送帶有選擇性說明文字的媒體。
- 允許來自網頁收件匣的自動回應包含媒體及文字。
- 保持各類型的限制合理且可預測。

## CLI 介面

- `openclaw message send --media <path-or-url> [--message <caption>]`
  - `--media` 為選用；說明文字可為空（僅限媒體發送）。
  - `--dry-run` 列印已解析的酬載；`--json` 發出 `{ channel, to, messageId, mediaUrl, caption }`。

## WhatsApp Web 頻道行為

- 輸入：本地檔案路徑**或** HTTP(S) URL。
- 流程：載入至 Buffer、偵測媒體種類並建置正確的酬載：
  - **圖片**：重設大小並重新壓縮為 JPEG（最大邊 2048px），目標 `agents.defaults.mediaMaxMb`（預設 5 MB），上限 6 MB。
  - **音訊/語音/影片**：穿過最多 16 MB；音訊以語音訊息傳送（`ptt: true`）。
  - **文件**：其他任何東西，最多 100 MB，當可用時保留檔名。
- WhatsApp GIF 樣式播放：發送帶有 `gifPlayback: true`（CLI：`--gif-playback`）的 MP4，使行動用戶端內連迴圈。
- MIME 偵測優先使用 magic bytes，接著 headers，最後檔案副檔名。
- 說明文字來自 `--message` 或 `reply.text`；允許空說明文字。
- 日誌：非詳細模式顯示 `↩️`/`✅`；詳細模式包含大小與來源路徑/URL。

## 自動回應流水線

- `getReplyFromConfig` 回傳 `{ text?, mediaUrl?, mediaUrls? }`。
- 當媒體存在時，網頁發送器使用與 `openclaw message send` 相同的流水線解析本地路徑或 URL。
- 若提供多個媒體項目，會依序發送。

## 傳入媒體至指令（Pi）

- 當傳入網頁訊息包含媒體時，OpenClaw 下載至暫存檔並公開模板變數：
  - `{{MediaUrl}}` 傳入媒體的虛擬 URL。
  - `{{MediaPath}}` 執行指令前寫入的本地暫存路徑。
- 當啟用了各工作階段 Docker 沙盒時，傳入媒體會被複製到沙盒工作區，且 `MediaPath`/`MediaUrl` 會被重寫為相對路徑，如 `media/inbound/<filename>`。
- 媒體理解（若透由 `tools.media.*` 或共享 `tools.media.models` 配置）在模板之前執行，可將 `[Image]`、`[Audio]` 和 `[Video]` 區塊插入 `Body`。
  - 音訊設定 `{{Transcript}}` 並使用轉錄進行指令解析，所以斜線指令仍可生效。
  - 影片和圖片描述保留任何說明文字用於指令解析。
- 預設僅處理第一個符合的圖片/音訊/影片附件；設定 `tools.media.<cap>.attachments` 以處理多個附件。

## 限制與錯誤

**傳出發送上限（WhatsApp Web 發送）**

- 圖片：重新壓縮後約 6 MB 上限。
- 音訊/語音/影片：16 MB 上限；文件：100 MB 上限。
- 超大或無法讀取的媒體 → 日誌中清晰的錯誤且回應被略過。

**媒體理解上限（轉錄/描述）**

- 圖片預設：10 MB（`tools.media.image.maxBytes`）。
- 音訊預設：20 MB（`tools.media.audio.maxBytes`）。
- 影片預設：50 MB（`tools.media.video.maxBytes`）。
- 超大媒體略過理解，但回應仍用原始主體進行。

## 測試筆記

- 涵蓋圖片/音訊/文件案例的發送及回應流程。
- 驗證圖片重新壓縮（大小限制）和音訊語音訊息旗標。
- 確保多媒體回應作為依序發送的扇出。
