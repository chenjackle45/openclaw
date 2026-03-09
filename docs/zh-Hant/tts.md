---
summary: "文字轉語音（TTS）用於外送回覆"
read_when:
  - 啟用回覆的文字轉語音功能
  - 設定 TTS 提供商或限制
  - 使用 /tts 指令
title: "Text-to-Speech（文字轉語音）"
---

# Text-to-speech（文字轉語音）

OpenClaw 可以使用 ElevenLabs、OpenAI 或 Edge TTS 將外送回覆轉換為音訊。
它適用於 OpenClaw 可以傳送音訊的任何地方；Telegram 會獲得圓形語音備忘錄氣泡。

## 支援的服務

- **ElevenLabs**（主要或退備提供商）
- **OpenAI**（主要或退備提供商；也用於摘要）
- **Edge TTS**（主要或退備提供商；使用 `node-edge-tts`，無 API 金鑰時的預設）

### Edge TTS 注意事項

Edge TTS 透過 `node-edge-tts` 函式庫使用 Microsoft Edge 的線上神經 TTS 服務。它是託管服務（非本地），使用 Microsoft 的端點，不需要 API 金鑰。`node-edge-tts` 公開語音設定選項和輸出格式，但並非所有選項都受 Edge 服務支援。

由於 Edge TTS 是沒有已發布 SLA 或配額的公開網路服務，請將其視為盡力而為。若你需要保證的限制和支援，請使用 OpenAI 或 ElevenLabs。Microsoft 的 Speech REST API 記錄每個請求 10 分鐘的音訊限制；Edge TTS 未發布限制，因此假設類似或更低的限制。

## 選用金鑰

若你想要 OpenAI 或 ElevenLabs：

- `ELEVENLABS_API_KEY`（或 `XI_API_KEY`）
- `OPENAI_API_KEY`

Edge TTS **不需要** API 金鑰。若找不到 API 金鑰，OpenClaw 預設使用 Edge TTS（除非透過 `messages.tts.edge.enabled=false` 停用）。

若設定了多個提供商，選定的提供商優先使用，其他提供商作為退備選項。
自動摘要使用設定的 `summaryModel`（或 `agents.defaults.model.primary`），因此若啟用摘要，該提供商也必須通過驗證。

## 服務連結

- [OpenAI 文字轉語音指南](https://platform.openai.com/docs/guides/text-to-speech)
- [OpenAI Audio API 參考](https://platform.openai.com/docs/api-reference/audio)
- [ElevenLabs Text to Speech](https://elevenlabs.io/docs/api-reference/text-to-speech)
- [ElevenLabs 驗證](https://elevenlabs.io/docs/api-reference/authentication)
- [node-edge-tts](https://github.com/SchneeHertz/node-edge-tts)
- [Microsoft Speech 輸出格式](https://learn.microsoft.com/azure/ai-services/speech-service/rest-text-to-speech#audio-outputs)

## 預設啟用嗎？

否。自動 TTS **預設關閉**。透過設定中的 `messages.tts.auto` 或每個 session 使用 `/tts always`（別名：`/tts on`）啟用。

一旦 TTS 啟用，Edge TTS **就會啟用**，並在沒有 OpenAI 或 ElevenLabs API 金鑰時自動使用。

## 設定

TTS 設定位於 `openclaw.json` 中的 `messages.tts` 下。
完整 schema 請見 [Gateway 設定](/zh-Hant/gateway/configuration)。

### 最少設定（啟用 + 提供商）

```json5
{
  messages: {
    tts: {
      auto: "always",
      provider: "elevenlabs",
    },
  },
}
```

### OpenAI 主要搭配 ElevenLabs 退備

```json5
{
  messages: {
    tts: {
      auto: "always",
      provider: "openai",
      summaryModel: "openai/gpt-4.1-mini",
      modelOverrides: {
        enabled: true,
      },
      openai: {
        apiKey: "openai_api_key",
        baseUrl: "https://api.openai.com/v1",
        model: "gpt-4o-mini-tts",
        voice: "alloy",
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
          speed: 1.0,
        },
      },
    },
  },
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
        pitch: "-5%",
      },
    },
  },
}
```

### 停用 Edge TTS

```json5
{
  messages: {
    tts: {
      edge: {
        enabled: false,
      },
    },
  },
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
      prefsPath: "~/.openclaw/settings/tts.json",
    },
  },
}
```

### 僅在收到語音備忘錄後以音訊回覆

```json5
{
  messages: {
    tts: {
      auto: "inbound",
    },
  },
}
```

### 停用長回覆的自動摘要

```json5
{
  messages: {
    tts: {
      auto: "always",
    },
  },
}
```

然後執行：

```
/tts summary off
```

### 欄位說明

- `auto`：自動 TTS 模式（`off`、`always`、`inbound`、`tagged`）。
  - `inbound` 僅在收到語音備忘錄後傳送音訊。
  - `tagged` 僅在回覆包含 `[[tts]]` 標籤時傳送音訊。
- `enabled`：舊版開關（doctor 會將其遷移至 `auto`）。
- `mode`：`"final"`（預設）或 `"all"`（包含工具/區塊回覆）。
- `provider`：`"elevenlabs"`、`"openai"` 或 `"edge"`（退備自動）。
- 若 `provider` **未設定**，OpenClaw 優先選 `openai`（若有金鑰），然後 `elevenlabs`（若有金鑰），否則 `edge`。
- `summaryModel`：自動摘要的選用低成本模型；預設為 `agents.defaults.model.primary`。
  - 接受 `provider/model` 或已設定的模型別名。
- `modelOverrides`：允許模型發出 TTS 指令（預設開啟）。
  - `allowProvider` 預設為 `false`（提供商切換需選擇性啟用）。
- `maxTextLength`：TTS 輸入的硬限制（字元數）。`/tts audio` 若超過則失敗。
- `timeoutMs`：請求逾時（毫秒）。
- `prefsPath`：覆蓋本地 prefs JSON 路徑（提供商/限制/摘要）。
- `apiKey` 值退備至環境變數（`ELEVENLABS_API_KEY`/`XI_API_KEY`、`OPENAI_API_KEY`）。
- `elevenlabs.baseUrl`：覆蓋 ElevenLabs API 基礎 URL。
- `openai.baseUrl`：覆蓋 OpenAI TTS 端點。
  - 解析順序：`messages.tts.openai.baseUrl` -> `OPENAI_TTS_BASE_URL` -> `https://api.openai.com/v1`
  - 非預設值視為 OpenAI 相容的 TTS 端點，因此接受自訂模型和語音名稱。
- `elevenlabs.voiceSettings`：
  - `stability`、`similarityBoost`、`style`：`0..1`
  - `useSpeakerBoost`：`true|false`
  - `speed`：`0.5..2.0`（1.0 = 正常）
- `elevenlabs.applyTextNormalization`：`auto|on|off`
- `elevenlabs.languageCode`：2 字母 ISO 639-1（例如 `en`、`de`）
- `elevenlabs.seed`：整數 `0..4294967295`（盡力確定性）
- `edge.enabled`：允許使用 Edge TTS（預設 `true`；無需 API 金鑰）。
- `edge.voice`：Edge 神經語音名稱（例如 `en-US-MichelleNeural`）。
- `edge.lang`：語言代碼（例如 `en-US`）。
- `edge.outputFormat`：Edge 輸出格式（例如 `audio-24khz-48kbitrate-mono-mp3`）。
  - 有效值請見 Microsoft Speech 輸出格式；並非所有格式都受 Edge 支援。
- `edge.rate` / `edge.pitch` / `edge.volume`：百分比字串（例如 `+10%`、`-5%`）。
- `edge.saveSubtitles`：在音訊檔案旁寫入 JSON 字幕。
- `edge.proxy`：Edge TTS 請求的代理 URL。
- `edge.timeoutMs`：請求逾時覆蓋（毫秒）。

## 模型驅動的覆蓋（預設開啟）

預設情況下，模型**可以**為單一回覆發出 TTS 指令。
當 `messages.tts.auto` 為 `tagged` 時，這些指令是觸發音訊的必要條件。

啟用後，模型可以發出 `[[tts:...]]` 指令來覆蓋單一回覆的語音，加上可選的 `[[tts:text]]...[[/tts:text]]` 區塊，提供僅應出現在音訊中的表達標籤（笑聲、歌唱提示等）。

除非設定 `modelOverrides.allowProvider: true`，否則忽略 `provider=...` 指令。

回覆酬載範例：

```
Here you go.

[[tts:voiceId=pMsXgVXv3BLzUgSXRplE model=eleven_v3 speed=1.1]]
[[tts:text]](laughs) Read the song once more.[[/tts:text]]
```

可用的指令鍵（啟用後）：

- `provider`（`openai` | `elevenlabs` | `edge`，需要 `allowProvider: true`）
- `voice`（OpenAI 語音）或 `voiceId`（ElevenLabs）
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
        enabled: false,
      },
    },
  },
}
```

選用允許清單（啟用提供商切換同時保持其他選項可設定）：

```json5
{
  messages: {
    tts: {
      modelOverrides: {
        enabled: true,
        allowProvider: true,
        allowSeed: false,
      },
    },
  },
}
```

## 每使用者偏好設定

斜線指令將本地覆蓋寫入 `prefsPath`（預設：`~/.openclaw/settings/tts.json`，可透過 `OPENCLAW_TTS_PREFS` 或 `messages.tts.prefsPath` 覆蓋）。

儲存的欄位：

- `enabled`
- `provider`
- `maxLength`（摘要閾值；預設 1500 字元）
- `summarize`（預設 `true`）

這些設定會覆蓋該主機的 `messages.tts.*`。

## 輸出格式（固定）

- **Telegram**：Opus 語音備忘錄（ElevenLabs 的 `opus_48000_64`，OpenAI 的 `opus`）。
  - 48kHz / 64kbps 是語音備忘錄的良好平衡點，且圓形氣泡需要此格式。
- **其他頻道**：MP3（ElevenLabs 的 `mp3_44100_128`，OpenAI 的 `mp3`）。
  - 44.1kHz / 128kbps 是語音清晰度的預設平衡點。
- **Edge TTS**：使用 `edge.outputFormat`（預設 `audio-24khz-48kbitrate-mono-mp3`）。
  - `node-edge-tts` 接受 `outputFormat`，但並非所有格式都受 Edge 服務提供。
  - 輸出格式值遵循 Microsoft Speech 輸出格式（包含 Ogg/WebM Opus）。
  - Telegram `sendVoice` 接受 OGG/MP3/M4A；若需要保證的 Opus 語音備忘錄請使用 OpenAI/ElevenLabs。
  - 若設定的 Edge 輸出格式失敗，OpenClaw 以 MP3 重試。

OpenAI/ElevenLabs 格式是固定的；Telegram 期望 Opus 以獲得語音備忘錄 UX。

## 自動 TTS 行為

啟用時，OpenClaw：

- 若回覆已包含媒體或 `MEDIA:` 指令，則跳過 TTS。
- 跳過非常短的回覆（< 10 字元）。
- 啟用時，使用 `agents.defaults.model.primary`（或 `summaryModel`）摘要長回覆。
- 將生成的音訊附加至回覆。

若回覆超過 `maxLength` 且摘要已關閉（或摘要模型無 API 金鑰），則跳過音訊並傳送正常文字回覆。

## 流程圖

```
回覆 -> TTS 啟用？
  否  -> 傳送文字
  是  -> 有媒體 / MEDIA: / 很短？
          是 -> 傳送文字
          否  -> 長度 > 限制？
                   否  -> TTS -> 附加音訊
                   是  -> 摘要啟用？
                            否  -> 傳送文字
                            是  -> 摘要（summaryModel 或 agents.defaults.model.primary）
                                      -> TTS -> 附加音訊
```

## 斜線指令使用

只有一個指令：`/tts`。
啟用詳情請見 [斜線指令](/zh-Hant/tools/slash-commands)。

Discord 注意：`/tts` 是 Discord 的內建指令，因此 OpenClaw 在 Discord 上將 `/voice` 註冊為原生指令。文字 `/tts ...` 仍然有效。

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

- 指令需要授權的傳送者（允許清單/擁有者規則仍適用）。
- 必須啟用 `commands.text` 或原生指令註冊。
- `off|always|inbound|tagged` 是按 session 的切換（`/tts on` 是 `/tts always` 的別名）。
- `limit` 和 `summary` 儲存在本地 prefs 中，不在主設定中。
- `/tts audio` 產生一次性音訊回覆（不切換 TTS 啟用）。

## Agent 工具

`tts` 工具將文字轉換為語音並返回 `MEDIA:` 路徑。當結果與 Telegram 相容時，工具包含 `[[audio_as_voice]]`，讓 Telegram 傳送語音氣泡。

## Gateway RPC

Gateway 方法：

- `tts.status`
- `tts.enable`
- `tts.disable`
- `tts.convert`
- `tts.setProvider`
- `tts.providers`
