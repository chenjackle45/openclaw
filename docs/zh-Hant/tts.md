---
summary: "文字轉語音（TTS）用於出站回覆"
read_when:
  - 啟用回覆的文字轉語音功能
  - 配置 TTS 提供者或限制
  - 使用 /tts 命令
title: "Text-to-Speech（文字轉語音）"
---

# Text-to-speech（文字轉語音）

OpenClaw 可以使用 ElevenLabs、OpenAI 或 Edge TTS 將出站回覆轉換為音頻。
它適用於 OpenClaw 可以傳送音頻的任何地方；Telegram 會獲得圓形語音備忘錄氣泡。

## 支援的服務

- **ElevenLabs**（主要或後備提供者）
- **OpenAI**（主要或後備提供者；也用於摘要）
- **Edge TTS**（主要或後備提供者；使用 node-edge-tts，無 API 金鑰時預設）

### Edge TTS 注意事項

Edge TTS 通過 node-edge-tts 庫使用 Microsoft Edge 線上神經 TTS 服務。它是託管服務（非本地），使用 Microsoft 的端點，不需要 API 金鑰。node-edge-tts 公開語音配置選項和輸出格式，但並非所有選項都受 Edge 服務支援。

因為 Edge TTS 是沒有發佈 SLA 或配額的公開 Web 服務，請將其視為盡力而為。如果您需要保證的限制和支援，請使用 OpenAI 或 ElevenLabs。Microsoft 的 Speech REST API 記錄 10 分鐘音頻限制每個請求；Edge TTS 不發佈限制，所以假設類似或更低的限制。

## 可選金鑰

如果您想要 OpenAI 或 ElevenLabs：

- `ELEVENLABS_API_KEY`（或 `XI_API_KEY`）
- `OPENAI_API_KEY`

Edge TTS **不需要** API 金鑰。如果沒有找到 API 金鑰，OpenClaw 預設為 Edge TTS（除非通過 messages.tts.edge.enabled=false 禁用）。

如果配置了多個提供者，選定的提供者將首先使用，其他提供者是後備選項。
自動摘要使用配置的 summaryModel（或 agents.defaults.model.primary），
所以如果啟用摘要，該提供者也必須進行身份驗證。

## 服務連結

- [OpenAI 文字轉語音指南](https://platform.openai.com/docs/guides/text-to-speech)
- [OpenAI Audio API 參考](https://platform.openai.com/docs/api-reference/audio)
- [ElevenLabs 文字轉語音](https://elevenlabs.io/docs/api-reference/text-to-speech)
- [ElevenLabs 身份驗證](https://elevenlabs.io/docs/api-reference/authentication)
- [node-edge-tts](https://github.com/SchneeHertz/node-edge-tts)
- [Microsoft Speech 輸出格式](https://learn.microsoft.com/azure/ai-services/speech-service/rest-text-to-speech#audio-outputs)

## 預設啟用嗎？

否。自動 TTS **預設關閉**。使用 messages.tts.auto 或通過 /tts always（別名：/tts on）按會話啟用。

一旦啟用 TTS，Edge TTS **已啟用**，當沒有 OpenAI 或 ElevenLabs API 金鑰可用時會自動使用。

## 配置

TTS 配置位於 openclaw.json 中的 messages.tts 下。
完整架構在 [Gateway 配置](/zh-Hant/gateway/configuration) 中。

### 最少配置（啟用 + 提供者）

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

### OpenAI 主要，ElevenLabs 後備

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

### 禁用 Edge TTS

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

（完整配置選項請參考英文版原檔）

## 模型驅動的覆寫（預設開啟）

預設情況下，模型**可以**為單一回覆發出 TTS 指令。
當 messages.tts.auto 為 tagged 時，這些指令需要觸發音頻。

啟用後，模型可以發出 [[tts:...]] 指令以覆寫單一回覆的聲音，
加上可選的 [[tts:text]]...[[/tts:text]] 塊提供應該只在音頻中出現的表達標籤（笑聲、歌唱提示等）。

除非設定 modelOverrides.allowProvider: true，否則忽略 provider=... 指令。

回覆有效負載範例：

```
Here you go.

[[tts:voiceId=pMsXgVXv3BLzUgSXRplE model=eleven_v3 speed=1.1]]
[[tts:text]](laughs) Read the song once more.[[/tts:text]]
```

（完整指令清單請參考英文版）

## 斜線命令使用

有一個命令：/tts。
請參閱 [Slash 命令](/zh-Hant/tools/slash-commands) 瞭解啟用詳情。

Discord 注意：/tts 是內置 Discord 命令，所以 OpenClaw 在那裡註冊 /voice 作為原生命令。文字 /tts ... 仍然有效。

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

注意：

- 命令需要授權的發送者（允許清單/所有者規則仍然適用）。
- 必須啟用 commands.text 或原生命令註冊。
- off|always|inbound|tagged 是按會話切換（/tts on 是 /tts always 的別名）。
- limit 和 summary 存儲在本地偏好設定中，不是主配置。
- /tts audio 產生一次性音頻回覆（不啟用 TTS）。

## Agent 工具

tts 工具將文本轉換為語音並返回 MEDIA: 路徑。當結果是 Telegram 相容時，該工具包括 [[audio_as_voice]] 所以 Telegram 發送語音氣泡。

## Gateway RPC

Gateway 方法：

- `tts.status`
- `tts.enable`
- `tts.disable`
- `tts.convert`
- `tts.setProvider`
- `tts.providers`
