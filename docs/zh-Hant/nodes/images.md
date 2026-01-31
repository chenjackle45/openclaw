---
title: "Images(圖片與媒體支援)"
summary: "發送、Gateway 與 Agent 回應的圖片與媒體處理規則"
read_when:
  - 修改媒體流水線或附件處理邏輯時
---

# 圖片與媒體支援 (Image & Media Support)

本文件說明發送、Gateway 轉錄以及 Agent 回應在處理媒體時的各項規則。

## 核心設計目標
- 透過 `openclaw message send --media` 發送帶有選擇性說明文字 (Caption) 的媒體。
- 支援網頁收件匣的自動回覆功能包含文字與媒體。
- 制定明確且可預測的各類型媒體大小上限。

## CLI 操作
- `openclaw message send --media <路徑或網址> [--message 說明文字]`
  - `--media` 為選填；說明文字可為空（僅發送媒體）。
  - `--dry-run` 用於預演並印出酬載；`--json` 則以 JSON 格式輸出。

## WhatsApp Web 頻道行為
- **輸入來源**：本地檔案路徑或 HTTP(S) 網址。
- **處理流程**：載入至 Buffer、偵測媒體類型並建置正確酬載：
  - **圖片**：重設大小並重新壓縮為 JPEG (單邊最大 2048px)，目標大小為 5MB (上限 6MB)。
  - **音訊/語音/影片**：支援最大 16MB；音訊會以語音訊息 (PTT) 形式發送。
  - **文件**：其餘類型皆視為文件，上限 100MB，會盡可能保留原始檔名。
- **GIF 播放**：發送帶有 `--gif-playback` 標籤的 MP4 影片，讓行動端能循環播放。
- **MIME 偵測**：優先順序為 magic bytes > 標頭 > 副檔名。

## 自動回覆流水線 (Auto-Reply Pipeline)
- 當回覆中包含媒體時，網頁發送器會採用與 `message send` 相同的處理邏輯。
- 多個媒體條目會依序發送。

## 傳入媒體處理 (Pi)
- 當傳入訊息包含媒體時，OpenClaw 會將其下載至暫存檔，並提供以下模板變數：
  - `{{MediaUrl}}`：傳入媒體的虛擬網址。
  - `{{MediaPath}}`：執行指令前的本地暫存路徑。
- **沙盒整合**：若啟用了 Docker 沙盒，媒體會被複製到沙盒工作區，並將上述路徑重寫為相對路徑（如 `media/inbound/<檔名>`）。
- **媒體理解**：在套用模板前，系統會嘗試進行媒體理解（若有配置），並在訊息主體中插入 `[Image]`、`[Audio]` 或 `[Video]` 標記。
  - 音訊轉錄內容會設定為 `{{Transcript}}` 並用於指令解析，因此斜線指令仍可生效。

## 限制與錯誤處理

**傳出限制 (WhatsApp Web 發送)**
- 圖片：壓縮後約 6MB。
- 音訊/語音/影片：16MB；文件：100MB。
- **超限**：會在日誌中顯示明確錯誤並跳過該回覆。

**媒體理解限制 (轉錄/分析)**
- 圖片預設：10MB (`tools.media.image.maxBytes`)。
- 音訊預設：20MB (`tools.media.audio.maxBytes`)。
- 影片預設：50MB (`tools.media.video.maxBytes`)。
- **超限**：跳過媒體理解，但 Agent 仍會收到原始訊息主體。
