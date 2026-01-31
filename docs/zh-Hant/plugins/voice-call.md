---
title: "Voice call(Voice Call Plugin)"
summary: "Voice Call Plugin：透過 Twilio/Telnyx/Plivo 進行 Outbound + Inbound 通話（Plugin 安裝 + Config + CLI）"
read_when:
  - 您想從 OpenClaw 撥打 Outbound 語音通話
  - 您正在設定或開發 Voice-call Plugin
---

# Voice Call (Plugin)

透過 Plugin 為 OpenClaw 提供語音通話。支援 Outbound 通知和具有 Inbound Policies 的多輪對話。

目前支援的 Providers：
- `twilio`（Programmable Voice + Media Streams）
- `telnyx`（Call Control v2）
- `plivo`（Voice API + XML Transfer + GetInput Speech）
- `mock`（開發/無網路）

快速心智模型：
- 安裝 Plugin
- 重新啟動 Gateway
- 在 `plugins.entries.voice-call.config` 下設定
- 使用 `openclaw voicecall ...` 或 `voice_call` Tool

## 執行位置（Local vs Remote）

Voice Call Plugin 在 **Gateway Process 內執行**。

如果您使用 Remote Gateway，請在**執行 Gateway 的機器**上安裝/設定 Plugin，然後重新啟動 Gateway 以載入它。

## 安裝

### 選項 A：從 npm 安裝（建議）

```bash
openclaw plugins install @openclaw/voice-call
```

之後重新啟動 Gateway。

### 選項 B：從 Local 資料夾安裝（開發，不複製）

```bash
openclaw plugins install ./extensions/voice-call
cd ./extensions/voice-call && pnpm install
```

之後重新啟動 Gateway。

## Config

在 `plugins.entries.voice-call.config` 下設定 Config：

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        enabled: true,
        config: {
          provider: "twilio", // 或 "telnyx" | "plivo" | "mock"
          fromNumber: "+15550001234",
          toNumber: "+15550005678",

          twilio: {
            accountSid: "ACxxxxxxxx",
            authToken: "..."
          },

          plivo: {
            authId: "MAxxxxxxxxxxxxxxxxxxxx",
            authToken: "..."
          },

          // Webhook Server
          serve: {
            port: 3334,
            path: "/voice/webhook"
          },

          // 公開曝露（選擇一種）
          // publicUrl: "https://example.ngrok.app/voice/webhook",
          // tunnel: { provider: "ngrok" },
          // tailscale: { mode: "funnel", path: "/voice/webhook" }

          outbound: {
            defaultMode: "notify" // notify | conversation
          },

          streaming: {
            enabled: true,
            streamPath: "/voice/stream"
          }
        }
      }
    }
  }
}
```

注意事項：
- Twilio/Telnyx 需要**可公開存取的** Webhook URL。
- Plivo 需要**可公開存取的** Webhook URL。
- `mock` 是 Local 開發 Provider（無網路呼叫）。
- `skipSignatureVerification` 僅用於 Local 測試。
- 如果您使用 ngrok 免費方案，請將 `publicUrl` 設為確切的 ngrok URL；簽章驗證始終強制執行。
- `tunnel.allowNgrokFreeTierLoopbackBypass: true` 僅在 `tunnel.provider="ngrok"` 且 `serve.bind` 是 Loopback（ngrok Local Agent）時允許具有無效簽章的 Twilio Webhooks。僅用於 Local 開發。
- Ngrok 免費方案 URL 可能會變更或新增 Interstitial 行為；如果 `publicUrl` 漂移，Twilio 簽章將失敗。對於生產環境，建議使用穩定網域或 Tailscale Funnel。

## 通話 TTS

Voice Call 使用核心 `messages.tts` 設定（OpenAI 或 ElevenLabs）進行通話中的串流語音。您可以在 Plugin Config 下使用**相同結構**覆寫它 — 它會與 `messages.tts` 深度合併。

```json5
{
  tts: {
    provider: "elevenlabs",
    elevenlabs: {
      voiceId: "pMsXgVXv3BLzUgSXRplE",
      modelId: "eleven_multilingual_v2"
    }
  }
}
```

注意事項：
- **語音通話會忽略 Edge TTS**（電話音訊需要 PCM；Edge 輸出不可靠）。
- 當 Twilio Media Streaming 啟用時使用 Core TTS；否則通話會回退到 Provider 原生語音。

### 更多範例

僅使用 Core TTS（無覆寫）：

```json5
{
  messages: {
    tts: {
      provider: "openai",
      openai: { voice: "alloy" }
    }
  }
}
```

僅為通話覆寫為 ElevenLabs（在其他地方保持 Core 預設）：

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        config: {
          tts: {
            provider: "elevenlabs",
            elevenlabs: {
              apiKey: "elevenlabs_key",
              voiceId: "pMsXgVXv3BLzUgSXRplE",
              modelId: "eleven_multilingual_v2"
            }
          }
        }
      }
    }
  }
}
```

僅為通話覆寫 OpenAI 模型（深度合併範例）：

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        config: {
          tts: {
            openai: {
              model: "gpt-4o-mini-tts",
              voice: "marin"
            }
          }
        }
      }
    }
  }
}
```

## Inbound 通話

Inbound Policy 預設為 `disabled`。要啟用 Inbound 通話，請設定：

```json5
{
  inboundPolicy: "allowlist",
  allowFrom: ["+15550001234"],
  inboundGreeting: "Hello! How can I help?"
}
```

自動回應使用 Agent 系統。透過以下調整：
- `responseModel`
- `responseSystemPrompt`
- `responseTimeoutMs`

## CLI

```bash
openclaw voicecall call --to "+15555550123" --message "Hello from OpenClaw"
openclaw voicecall continue --call-id <id> --message "Any questions?"
openclaw voicecall speak --call-id <id> --message "One moment"
openclaw voicecall end --call-id <id>
openclaw voicecall status --call-id <id>
openclaw voicecall tail
openclaw voicecall expose --mode funnel
```

## Agent Tool

Tool 名稱：`voice_call`

動作：
- `initiate_call`（message、to?、mode?）
- `continue_call`（callId、message）
- `speak_to_user`（callId、message）
- `end_call`（callId）
- `get_status`（callId）

此 Repo 在 `skills/voice-call/SKILL.md` 提供對應的 Skill 文件。

## Gateway RPC

- `voicecall.initiate`（`to?`、`message`、`mode?`）
- `voicecall.continue`（`callId`、`message`）
- `voicecall.speak`（`callId`、`message`）
- `voicecall.end`（`callId`）
- `voicecall.status`（`callId`）
