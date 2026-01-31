---
title: "Text-to-speech(文字轉語音)"
summary: "出站回覆的文字轉語音（TTS）"
read_when:
  - 為回覆啟用文字轉語音
  - 設定 TTS 供應商或限制
  - 使用 /tts 指令
---

# Text-to-speech (TTS)(文字轉語音（TTS）)

OpenClaw 可以使用 ElevenLabs、OpenAI 或 Edge TTS 將出站回覆轉換為音訊。
它在 OpenClaw 可以發送音訊的任何地方工作；Telegram 獲得圓形語音筆記泡泡。

## 支援的服務

- **ElevenLabs**（主要或回退供應商）
- **OpenAI**（主要或回退供應商；也用於摘要）
- **Edge TTS**（主要或回退供應商；使用 `node-edge-tts`，無 API 金鑰時的預設）

### Edge TTS 注意事項

Edge TTS 透過 `node-edge-tts` 程式庫使用 Microsoft Edge 的線上神經 TTS 服務。它是託管服務（非本地），使用 Microsoft 的端點，並且不需要 API 金鑰。`node-edge-tts` 公開語音設定選項和輸出格式，但並非所有選項都受 Edge 服務支援。

因為 Edge TTS 是沒有已發布 SLA 或配額的公共 web 服務，請將其視為盡力而為。如果您需要保證的限制和支援，請使用 OpenAI 或 ElevenLabs。Microsoft 的 Speech REST API 記錄每個請求 10 分鐘音訊限制；Edge TTS 不發布限制，因此假設類似或更低的限制。

## 可選金鑰

如果您想要 OpenAI 或 ElevenLabs：
- `ELEVENLABS_API_KEY`（或 `XI_API_KEY`）
- `OPENAI_API_KEY`

Edge TTS **不**需要 API 金鑰。如果找不到 API 金鑰，OpenClaw 預設為 Edge TTS（除非透過 `messages.tts.edge.enabled=false` 停用）。

如果設定了多個供應商，則首先使用選定的供應商，其他供應商是回退選項。
自動摘要使用設定的 `summaryModel`（或 `agents.defaults.model.primary`），因此如果您啟用摘要，該供應商也必須經過認證。

## 服務連結

- [OpenAI Text-to-Speech guide](https://platform.openai.com/docs/guides/text-to-speech)
- [OpenAI Audio API reference](https://platform.openai.com/docs/api-reference/audio)
- [ElevenLabs Text to Speech](https://elevenlabs.io/docs/api-reference/text-to-speech)
- [ElevenLabs Authentication](https://elevenlabs.io/docs/api-reference/authentication)
- [node-edge-tts](https://github.com/SchneeHertz/node-edge-tts)
- [Microsoft Speech output formats](https://learn.microsoft.com/azure/ai-services/speech-service/rest-text-to-speech#audio-outputs)

## 它預設啟用嗎？

否。自動 TTS 預設**關閉**。在設定中使用 `messages.tts.auto` 啟用它，或每個會話使用 `/tts always`（別名：`/tts on`）。

一旦啟用 TTS，Edge TTS **預設啟用**，並在沒有 OpenAI 或 ElevenLabs API 金鑰時自動使用。

## 設定

TTS 設定位於 `openclaw.json` 中的 `messages.tts` 下。
完整 schema 在 [Gateway configuration](/gateway/configuration) 中。

### 最小設定（啟用 + 供應商）

```json5
{
  messages: {
    tts: {
      auto: "always",
      provider: "elevenlabs"
    }
  }
}
```

### OpenAI 主要加 ElevenLabs 回退

```json5
{
  messages: {
    tts: {
      auto: "always",
      provider: "openai",
      summaryModel: "openai/gpt-4.1-mini",
      modelOverrides: {
        enabled: true
      },
      openai: {
        apiKey: "openai_api_key",
        model: "gpt-4o-mini-tts",
        voice: "alloy"
      },
      elevenlabs: {
        apiKey: "elevenlabs_api_key",
        baseUrl: "https://api.elevenlabs.io",
        voiceId: "voice_id",
        modelId: "eleven_multilingual_v2",
        seed: 42,
        applyTextNormalization: "auto",
        languageCode: "en",
        voiceSettings: {
          stability: 0.5,
          similarityBoost: 0.75,
          style: 0.0,
          useSpeakerBoost: true,
          speed: 1.0
        }
      }
    }
  }
}
```

### Edge TTS 主要（無 API 金鑰）

```json5
{
  messages: {
    tts: {
      auto: "always",
      provider: "edge",
      edge: {
        enabled: true,
        voice: "en-US-MichelleNeural",
        lang: "en-US",
        outputFormat: "audio-24khz-48kbitrate-mono-mp3",
        rate: "+10%",
        pitch: "-5%"
      }
    }
  }
}
```

### 停用 Edge TTS

```json5
{
  messages: {
    tts: {
      edge: {
        enabled: false
      }
    }
  }
}
```

### 自訂限制 + prefs 路徑

```json5
{
  messages: {
    tts: {
      auto: "always",
      maxTextLength: 4000,
      timeoutMs: 30000,
      prefsPath: "~/.openclaw/settings/tts.json"
    }
  }
}
```

### 僅在入站語音筆記後以音訊回覆

```json5
{
  messages: {
    tts: {
      auto: "inbound"
    }
  }
}
```

### 為長回覆停用自動摘要

```json5
{
  messages: {
    tts: {
      auto: "always"
    }
  }
}
```

然後執行：

```
/tts summary off
```

### 欄位注意事項

- `auto`：自動 TTS 模式（`off`、`always`、`inbound`、`tagged`）。
  - `inbound` 僅在入站語音筆記後發送音訊。
  - `tagged` 僅當回覆包含 `[[tts]]` 標籤時發送音訊。
- `enabled`：舊版切換（doctor 將其遷移到 `auto`）。
- `mode`：`"final"`（預設）或 `"all"`（包括 tool/block 回覆）。
- `provider`：`"elevenlabs"`、`"openai"` 或 `"edge"`（回退是自動的）。
- 如果 `provider` **未設定**，OpenClaw 偏好 `openai`（如果有金鑰），然後 `elevenlabs`（如果有金鑰），否則 `edge`。
- `summaryModel`：自動摘要的可選便宜模型；預設為 `agents.defaults.model.primary`。
  - 接受 `provider/model` 或已設定的模型別名。
- `modelOverrides`：允許模型發出 TTS 指令（預設開啟）。
- `maxTextLength`：TTS 輸入的硬上限（字元）。如果超過，`/tts audio` 失敗。
- `timeoutMs`：請求逾時（ms）。
- `prefsPath`：覆蓋本地 prefs JSON 路徑（provider/limit/summary）。
- `apiKey` 值回退到環境變數（`ELEVENLABS_API_KEY`/`XI_API_KEY`、`OPENAI_API_KEY`）。
- `elevenlabs.baseUrl`：覆蓋 ElevenLabs API base URL。
- `elevenlabs.voiceSettings`：
  - `stability`、`similarityBoost`、`style`：`0..1`
  - `useSpeakerBoost`：`true|false`
  - `speed`：`0.5..2.0`（1.0 = 正常）
- `elevenlabs.applyTextNormalization`：`auto|on|off`
- `elevenlabs.languageCode`：2 字母 ISO 639-1（例如 `en`、`de`）
- `elevenlabs.seed`：整數 `0..4294967295`（盡力確定性）
- `edge.enabled`：允許 Edge TTS 使用（預設 `true`；無 API 金鑰）。
- `edge.voice`：Edge 神經語音名稱（例如 `en-US-MichelleNeural`）。
- `edge.lang`：語言代碼（例如 `en-US`）。
- `edge.outputFormat`：Edge 輸出格式（例如 `audio-24khz-48kbitrate-mono-mp3`）。
  - 請參閱 Microsoft Speech 輸出格式以取得有效值；並非所有格式都受 Edge 支援。
- `edge.rate` / `edge.pitch` / `edge.volume`：百分比字串（例如 `+10%`、`-5%`）。
- `edge.saveSubtitles`：在音訊檔案旁邊寫入 JSON 字幕。
- `edge.proxy`：Edge TTS 請求的 proxy URL。
- `edge.timeoutMs`：請求逾時覆蓋（ms）。

## 模型驅動的覆蓋（預設開啟）

預設情況下，模型**可以**為單個回覆發出 TTS 指令。
當 `messages.tts.auto` 為 `tagged` 時，需要這些指令來觸發音訊。

啟用時，模型可以發出 `[[tts:...]]` 指令來覆蓋單個回覆的語音，加上可選的 `[[tts:text]]...[[/tts:text]]` 區塊以提供僅應出現在音訊中的表達標籤（笑聲、歌唱提示等）。

範例回覆 payload：

```
Here you go.

[[tts:provider=elevenlabs voiceId=pMsXgVXv3BLzUgSXRplE model=eleven_v3 speed=1.1]]
[[tts:text]](laughs) Read the song once more.[[/tts:text]]
```

可用的指令鍵（啟用時）：
- `provider`（`openai` | `elevenlabs` | `edge`）
- `voice`（OpenAI voice）或 `voiceId`（ElevenLabs）
- `model`（OpenAI TTS 模型或 ElevenLabs 模型 id）
- `stability`、`similarityBoost`、`style`、`speed`、`useSpeakerBoost`
- `applyTextNormalization`（`auto|on|off`）
- `languageCode`（ISO 639-1）
- `seed`

停用所有模型覆蓋：

```json5
{
  messages: {
    tts: {
      modelOverrides: {
        enabled: false
      }
    }
  }
}
```

可選允許清單（在保持標籤啟用的同時停用特定覆蓋）：

```json5
{
  messages: {
    tts: {
      modelOverrides: {
        enabled: true,
        allowProvider: false,
        allowSeed: false
      }
    }
  }
}
```

## 每個使用者偏好

Slash 指令將本地覆蓋寫入 `prefsPath`（預設：`~/.openclaw/settings/tts.json`，使用 `OPENCLAW_TTS_PREFS` 或 `messages.tts.prefsPath` 覆蓋）。

儲存的欄位：
- `enabled`
- `provider`
- `maxLength`（摘要閾值；預設 1500 個字元）
- `summarize`（預設 `true`）

這些為該 host 覆蓋 `messages.tts.*`。

## 輸出格式（固定）

- **Telegram**：Opus 語音筆記（來自 ElevenLabs 的 `opus_48000_64`，來自 OpenAI 的 `opus`）。
  - 48kHz / 64kbps 是良好的語音筆記權衡，並且圓形泡泡所需。
- **其他頻道**：MP3（來自 ElevenLabs 的 `mp3_44100_128`，來自 OpenAI 的 `mp3`）。
  - 44.1kHz / 128kbps 是語音清晰度的預設平衡。
- **Edge TTS**：使用 `edge.outputFormat`（預設 `audio-24khz-48kbitrate-mono-mp3`）。
  - `node-edge-tts` 接受 `outputFormat`，但並非所有格式都可從 Edge 服務獲得。
  - 輸出格式值遵循 Microsoft Speech 輸出格式（包括 Ogg/WebM Opus）。
  - Telegram `sendVoice` 接受 OGG/MP3/M4A；如果您需要保證的 Opus 語音筆記，請使用 OpenAI/ElevenLabs。
  - 如果設定的 Edge 輸出格式失敗，OpenClaw 使用 MP3 重試。

OpenAI/ElevenLabs 格式是固定的；Telegram 期望 Opus 用於語音筆記 UX。

## 自動 TTS 行為

啟用時，OpenClaw：
- 如果回覆已包含媒體或 `MEDIA:` 指令，則跳過 TTS。
- 跳過非常短的回覆（< 10 個字元）。
- 使用 `agents.defaults.model.primary`（或 `summaryModel`）在啟用時總結長回覆。
- 將生成的音訊附加到回覆。

如果回覆超過 `maxLength` 且摘要關閉（或摘要模型沒有 API 金鑰），則跳過音訊並發送正常文字回覆。

## 流程圖

```
Reply -> TTS enabled?
  no  -> send text
  yes -> has media / MEDIA: / short?
          yes -> send text
          no  -> length > limit?
                   no  -> TTS -> attach audio
                   yes -> summary enabled?
                            no  -> send text
                            yes -> summarize (summaryModel or agents.defaults.model.primary)
                                      -> TTS -> attach audio
```

## Slash 指令使用

有一個指令：`/tts`。
請參閱 [Slash commands](/tools/slash-commands) 以取得啟用詳細資訊。

Discord 注意事項：`/tts` 是內建的 Discord 指令，因此 OpenClaw 在那裡註冊 `/voice` 作為原生指令。文字 `/tts ...` 仍然有效。

```
/tts off
/tts always
/tts inbound
/tts tagged
/tts status
/tts provider openai
/tts limit 2000
/tts summary off
/tts audio Hello from OpenClaw
```

注意事項：
- 指令需要授權發送者（允許清單/擁有者規則仍然適用）。
- 必須啟用 `commands.text` 或原生指令註冊。
- `off|always|inbound|tagged` 是每個會話的切換（`/tts on` 是 `/tts always` 的別名）。
- `limit` 和 `summary` 儲存在本地 prefs 中，而不是主設定中。
- `/tts audio` 生成一次性音訊回覆（不切換 TTS 開啟）。

## Agent 工具

`tts` 工具將文字轉換為語音並返回 `MEDIA:` 路徑。當結果與 Telegram 相容時，工具包含 `[[audio_as_voice]]`，以便 Telegram 發送語音泡泡。

## Gateway RPC

Gateway 方法：
- `tts.status`
- `tts.enable`
- `tts.disable`
- `tts.convert`
- `tts.setProvider`
- `tts.providers`
