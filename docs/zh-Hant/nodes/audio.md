---
title: "音訊與語音訊息"
summary: "傳入的音訊與語音訊息如何被下載、轉錄並注入至回應中"
read_when:
  - 變更音訊轉錄或媒體處理方式時
---

# 音訊 / 語音訊息 — 2026-01-17

## 運作原理

- **媒體理解 (音訊)**：若啟用了音訊理解功能（或自動偵測到），OpenClaw 會執行：
  1. 定位第一個音訊附件（本地路徑或網址），並在需要時進行下載。
  2. 在發送至各模型前強制執行 `maxBytes` 大小限制。
  3. 依序執行第一個符合條件的模型項目（供應商或 CLI）。
  4. 若失敗或跳過（因大小/逾時），則嘗試下一個項目。
  5. 成功時，將訊息主體改為 `[Audio]` 區塊，並設定 `{{Transcript}}`。
- **指令解析**：轉錄成功後，`CommandBody`/`RawBody` 會被設定為轉錄內容，因此斜線指令仍可運作。
- **詳細日誌**：在 `--verbose` 模式下，我們會記錄轉錄執行的時機及其何時取代訊息主體。

## 自動偵測（預設）

如果您**未配置模型**且 `tools.media.audio.enabled` 未設為 `false`，OpenClaw 會依序偵測並停在第一個可用的選項：

1. **本地 CLI**（若已安裝）
   - `sherpa-onnx-offline`（需要 `SHERPA_ONNX_MODEL_DIR` 搭配 encoder/decoder/joiner/tokens）
   - `whisper-cli`（來自 `whisper-cpp`；使用 `WHISPER_CPP_MODEL` 或內附的 tiny 模型）
   - `whisper`（Python CLI；自動下載模型）
2. **Gemini CLI**（`gemini`）使用 `read_many_files`
3. **供應商金鑰**（OpenAI → Groq → Deepgram → Google）

若要停用自動偵測，請設定 `tools.media.audio.enabled: false`。
若要自訂，請設定 `tools.media.audio.models`。
注意：CLI 偵測在 macOS/Linux/Windows 上採用最佳效力；請確保 CLI 在 `PATH` 上（我們會展開 `~`），或設定完整命令路徑的明確 CLI 模型。

## 配置範例

### 供應商 + CLI 備援（OpenAI + Whisper CLI）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        maxBytes: 20971520,
        models: [
          { provider: "openai", model: "gpt-4o-mini-transcribe" },
          {
            type: "cli",
            command: "whisper",
            args: ["--model", "base", "{{MediaPath}}"],
            timeoutSeconds: 45,
          },
        ],
      },
    },
  },
}
```

### 供應商限制（含範圍限制）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        scope: {
          default: "allow",
          rules: [{ action: "deny", match: { chatType: "group" } }],
        },
        models: [{ provider: "openai", model: "gpt-4o-mini-transcribe" }],
      },
    },
  },
}
```

### 僅供應商（Deepgram）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        models: [{ provider: "deepgram", model: "nova-3" }],
      },
    },
  },
}
```

## 注意事項與限制

- 供應商認證遵循標準模型認證順序（認證設定檔、環境變數、`models.providers.*.apiKey`）。
- Deepgram 在使用 `provider: "deepgram"` 時會讀取 `DEEPGRAM_API_KEY`。
- Deepgram 設定詳情：[Deepgram（音訊轉錄）](/providers/deepgram)。
- 音訊供應商可透過 `tools.media.audio` 覆蓋 `baseUrl`、`headers` 和 `providerOptions`。
- 預設大小上限為 20MB（`tools.media.audio.maxBytes`）。超過大小的音訊會跳過該模型，嘗試下一個項目。
- 音訊的預設 `maxChars` 為**未設定**（完整轉錄）。設定 `tools.media.audio.maxChars` 或每項的 `maxChars` 以修剪輸出。
- OpenAI 自動預設為 `gpt-4o-mini-transcribe`；設定 `model: "gpt-4o-transcribe"` 以獲得更高準確度。
- 使用 `tools.media.audio.attachments` 處理多個語音訊息（`mode: "all"` + `maxAttachments`）。
- 轉錄內容可透過 `{{Transcript}}` 在模板中使用。
- CLI stdout 有上限（5MB）；保持 CLI 輸出簡潔。

## 常見陷阱

- 範圍規則遵循先匹配先贏。`chatType` 被標準化為 `direct`、`group` 或 `room`。
- 請確保您的 CLI 結束狀態碼為 0 並印出純文字；JSON 需透過 `jq -r .text` 進行處理。
- 保持合理的逾時時間（`timeoutSeconds`，預設 60 秒）以避免阻塞回應佇列。
