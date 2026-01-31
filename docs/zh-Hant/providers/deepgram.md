---
title: "deepgram(Deepgram)"
summary: "用於輸入語音訊息的 Deepgram 轉錄服務"
read_when:
  - 想要使用 Deepgram 進行音訊附件的語音轉文字時
  - 需要深層配置範例時 (Deepgram config example)
---

# Deepgram (音訊轉錄)

Deepgram 是一個語音轉文字 API。在 OpenClaw 中，它透過 `tools.media.audio` 用於**輸入音訊/語音訊息轉錄**。

啟用後，OpenClaw 會將音訊檔案上傳至 Deepgram，並將轉錄內容注入至回覆管道中 (`{{Transcript}}` + `[Audio]` 區塊)。這**並非串流**處理；它使用的是預錄轉錄端點。

網站：https://deepgram.com
文件：https://developers.deepgram.com

## 快速開始

1) 設定您的 API 金鑰：
```
DEEPGRAM_API_KEY=dg_...
```

2) 啟用供應商：
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

## 選項

- `model`: Deepgram 模型 ID（預設：`nova-3`）
- `language`: 語言提示（選用）
- `tools.media.audio.providerOptions.deepgram.detect_language`: 啟用語言偵測（選用）
- `tools.media.audio.providerOptions.deepgram.punctuate`: 啟用標點符號（選用）
- `tools.media.audio.providerOptions.deepgram.smart_format`: 啟用智慧格式化（選用）

包含語言設定的範例：
```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        models: [
          { provider: "deepgram", model: "nova-3", language: "zh-Hant" }
        ]
      }
    }
  }
}
```

包含 Deepgram 選項的範例：
```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        providerOptions: {
          deepgram: {
            detect_language: true,
            punctuate: true,
            smart_format: true
          }
        },
        models: [{ provider: "deepgram", model: "nova-3" }]
      }
    }
  }
}
```

## 注意事項

- 認證遵循標準供應商認證順序；`DEEPGRAM_API_KEY` 是最簡單的路徑。
- 若使用代理，可透過 `tools.media.audio.baseUrl` 與 `tools.media.audio.headers` 覆寫端點或標頭。
- 輸出遵循與其他供應商相同的音訊規則（大小上限、逾時、轉錄注入）。
