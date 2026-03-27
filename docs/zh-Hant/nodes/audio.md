---
title: "Audio and Voice Notes（音訊與語音訊息）"
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

## 設定範例

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

### 僅供應商（Mistral Voxtral）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        models: [{ provider: "mistral", model: "voxtral-mini-latest" }],
      },
    },
  },
}
```

### 回音轉錄至聊天（選擇加入）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        echoTranscript: true, // 預設為 false
        echoFormat: '📝 "{transcript}"', // 選用，支援 {transcript}
        models: [{ provider: "openai", model: "gpt-4o-mini-transcribe" }],
      },
    },
  },
}
```

## 注意事項與限制

- 供應商認證遵循標準模型認證順序（認證設定檔、環境變數、`models.providers.*.apiKey`）。
- Deepgram 在使用 `provider: "deepgram"` 時會讀取 `DEEPGRAM_API_KEY`。
- Deepgram 設定詳情：[Deepgram（音訊轉錄）](/zh-Hant/providers/deepgram)。
- Mistral 設定詳情：[Mistral](/zh-Hant/providers/mistral)。
- 音訊供應商可透過 `tools.media.audio` 覆蓋 `baseUrl`、`headers` 和 `providerOptions`。
- 預設大小上限為 20MB（`tools.media.audio.maxBytes`）。超過大小的音訊會跳過該模型，嘗試下一個項目。
- 小於 1024 位元組的微小／空音訊檔案在供應商/CLI 轉錄前會被跳過。
- 音訊的預設 `maxChars` 為**未設定**（完整轉錄）。設定 `tools.media.audio.maxChars` 或每項的 `maxChars` 以修剪輸出。
- OpenAI 自動預設為 `gpt-4o-mini-transcribe`；設定 `model: "gpt-4o-transcribe"` 以獲得更高準確度。
- 使用 `tools.media.audio.attachments` 處理多個語音訊息（`mode: "all"` + `maxAttachments`）。
- 轉錄內容可透過 `{{Transcript}}` 在模板中使用。
- `tools.media.audio.echoTranscript` 預設為關閉；啟用它以在代理程式處理前將轉錄確認傳送回原始聊天。
- `tools.media.audio.echoFormat` 自訂回音文字（預留位置：`{transcript}`）。
- CLI stdout 有上限（5MB）；保持 CLI 輸出簡潔。

### Proxy 環境支援

基於提供商的音訊轉錄遵循標準出站 Proxy 環境變數：

- `HTTPS_PROXY`
- `HTTP_PROXY`
- `https_proxy`
- `http_proxy`

若未設定 Proxy 環境變數，則使用直接出站。若 Proxy 設定格式不正確，OpenClaw 會記錄警告並回退至直接擷取。

## 群組中的提及偵測

當為群組聊天設定 `requireMention: true` 時，OpenClaw 現在會在檢查提及前轉錄音訊。這允許語音訊息即使包含提及也能被處理。

**運作方式：**

1. 若語音訊息沒有文字主體且群組需要提及，OpenClaw 會執行「預檢」轉錄。
2. 轉錄內容會被檢查是否有提及模式（例如 `@BotName`、emoji 觸發）。
3. 若找到提及，訊息會通過完整回應管道。
4. 轉錄會用於提及偵測，因此語音訊息可以通過提及門檻。

**後退行為：**

- 若預檢期間轉錄失敗（逾時、API 錯誤等），訊息會根據純文字提及偵測進行處理。
- 這確保混合訊息（文字 + 音訊）永遠不會被錯誤地丟棄。

**每個 Telegram 群組／主題選擇退出：**

- 設定 `channels.telegram.groups.<chatId>.disableAudioPreflight: true` 以跳過該群組的預檢轉錄提及檢查。
- 設定 `channels.telegram.groups.<chatId>.topics.<threadId>.disableAudioPreflight` 以逐主題覆蓋（`true` 跳過，`false` 強制啟用）。
- 預設為 `false`（當提及限制條件符合時預檢已啟用）。

**範例：** 使用者在有 `requireMention: true` 的 Telegram 群組中傳送語音訊息說「嘿 @Claude，天氣如何？」。語音訊息被轉錄，提及被偵測，代理程式會回覆。

## 常見陷阱

- 範圍規則遵循先匹配先贏。`chatType` 被標準化為 `direct`、`group` 或 `room`。
- 請確保您的 CLI 結束狀態碼為 0 並印出純文字；JSON 需透過 `jq -r .text` 進行處理。
- 對於 `parakeet-mlx`，若您傳遞 `--output-dir`，OpenClaw 會在 `--output-format` 為 `txt`（或省略）時讀取 `<output-dir>/<media-basename>.txt`；非 `txt` 輸出格式回退至 stdout 解析。
- 保持合理的逾時時間（`timeoutSeconds`，預設 60 秒）以避免阻塞回應佇列。
- 預檢轉錄只處理**第一個**音訊附件以進行提及偵測。其他音訊會在主媒體理解階段進行處理。
