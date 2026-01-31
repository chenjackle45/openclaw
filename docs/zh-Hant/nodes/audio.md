---
title: "Audio(音訊/語音訊息)"
summary: "傳入的音訊與語音訊息如何被下載、轉錄並注入至回應中"
read_when:
  - 變更音訊轉錄或媒體處理方式時
---

# 音訊 / 語音訊息 (Audio / Voice Notes)

## 運作原理
- **媒體理解 (音訊)**：若啟用了音訊理解功能（或自動偵測到），OpenClaw 會執行：
  1. 定位第一個音訊附件（本地路徑或網址），並在需要時進行下載。
  2. 在發送至模型前強制執行 `maxBytes` 大小限制。
  3. 依序執行第一個符合條件的模型項目（供應商或 CLI）。
  4. 若失敗或跳過（因大小/逾時），則嘗試下一個項目。
  5. **成功時**：將訊息主體改為 `[Audio]` 區塊，並設定 `{{Transcript}}` 變數。
- **指令解析**：轉錄成功後，`CommandBody` 與 `RawBody` 會被設定為轉錄內容，因此斜線指令 (Slash commands) 仍可運作。
- **詳細日誌**：在 `--verbose` 模式下，我們會記錄轉錄執行的時機。

## 自動偵測 (預設行為)
如果您**未配置模型**且 `tools.media.audio.enabled` 未設為 `false`，OpenClaw 會依序偵測以下選項，並停在第一個可用的選項：

1. **本地 CLI 工具** (若已安裝)
   - `sherpa-onnx-offline` (需要設定 `SHERPA_ONNX_MODEL_DIR`)
   - `whisper-cli` (來自 `whisper-cpp`)
   - `whisper` (Python CLI)
2. **Gemini CLI** (`gemini`) 使用 `read_many_files` 模式。
3. **供應商金鑰** (排序：OpenAI → Groq → Deepgram → Google)。

若要停用自動偵測，請設定 `tools.media.audio.enabled: false`。

## 配置範例

### 供應商 + CLI 備援 (OpenAI + Whisper CLI)
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
            timeoutSeconds: 45
          }
        ]
      }
    }
  }
}
```

### 僅使用供應商 (Deepgram)
```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        models: [{ provider: "deepgram", model: "nova-3" }]
      }
    }
  }
}
```

## 注意事項與限制
- 供應商認證遵循標準順序（認證設定檔、環境變數、`models.providers.*.apiKey`）。
- 預設大小上限為 20MB (`tools.media.audio.maxBytes`)。
- 轉錄內容可透過 `{{Transcript}}` 變數在模板中使用。
- 建議設定合理的逾時時間 (`timeoutSeconds`，預設為 60 秒)，以免阻塞回應佇列。

## 常見陷阱
- 範圍規則 (Scope rules) 遵循「先匹配先贏」原則。`chatType` 被標準化為 `direct` (私訊)、`group` (群組) 或 `room` (聊天室)。
- 請確保您的 CLI 工具結束狀態碼為 0 並印出純文字。
