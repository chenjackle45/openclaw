---
summary: "語音通話外掛程式：透過 Twilio／Telnyx／Plivo 的出站 + 入站通話（外掛程式安裝 + 設定 + CLI）"
read_when:
  - 想從 OpenClaw 撥打出站語音通話時
  - 正在設定或開發語音通話外掛程式時
title: "Voice Call Plugin（語音通話外掛程式）"
---

# 語音通話（外掛程式）

透過外掛程式為 OpenClaw 進行語音通話。支援出站通知和具有入站原則的多回合對話。

目前的提供商：

- `twilio`（Programmable Voice + Media Streams）
- `telnyx`（Call Control v2）
- `plivo`（Voice API + XML transfer + GetInput speech）
- `mock`（dev／無網路）

快速心智模型：

- 安裝外掛程式
- 重新啟動 Gateway
- 在 `plugins.entries.voice-call.config` 下設定
- 使用 `openclaw voicecall ...` 或 `voice_call` 工具

## 執行位置（本地 vs 遠端）

語音通話外掛程式在 **Gateway 進程內執行**。

如果使用遠端 Gateway，請在**執行 Gateway 的機器**上安裝／設定外掛程式，然後重新啟動 Gateway 以載入它。

## 安裝

### 選項 A：從 npm 安裝（建議）

```bash
openclaw plugins install @openclaw/voice-call
```

之後重新啟動 Gateway。

### 選項 B：從本地資料夾安裝（開發，無複製）

```bash
openclaw plugins install ./extensions/voice-call
cd ./extensions/voice-call && pnpm install
```

之後重新啟動 Gateway。

## Config

Set config under `plugins.entries.voice-call.config`:

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        enabled: true,
        config: {
          provider: "twilio", // or "telnyx" | "plivo" | "mock"
          fromNumber: "+15550001234",
          toNumber: "+15550005678",

          twilio: {
            accountSid: "ACxxxxxxxx",
            authToken: "...",
          },

          telnyx: {
            apiKey: "...",
            connectionId: "...",
            // Telnyx webhook public key from the Telnyx Mission Control Portal
            // (Base64 string; can also be set via TELNYX_PUBLIC_KEY).
            publicKey: "...",
          },

          plivo: {
            authId: "MAxxxxxxxxxxxxxxxxxxxx",
            authToken: "...",
          },

          // Webhook server
          serve: {
            port: 3334,
            path: "/voice/webhook",
          },

          // Webhook security (recommended for tunnels/proxies)
          webhookSecurity: {
            allowedHosts: ["voice.example.com"],
            trustedProxyIPs: ["100.64.0.1"],
          },

          // Public exposure (pick one)
          // publicUrl: "https://example.ngrok.app/voice/webhook",
          // tunnel: { provider: "ngrok" },
          // tailscale: { mode: "funnel", path: "/voice/webhook" }

          outbound: {
            defaultMode: "notify", // notify | conversation
          },

          streaming: {
            enabled: true,
            streamPath: "/voice/stream",
            preStartTimeoutMs: 5000,
            maxPendingConnections: 32,
            maxPendingConnectionsPerIp: 4,
            maxConnections: 128,
          },
        },
      },
    },
  },
}
```

Notes:

- Twilio/Telnyx require a **publicly reachable** webhook URL.
- Plivo requires a **publicly reachable** webhook URL.
- `mock` is a local dev provider (no network calls).
- Telnyx requires `telnyx.publicKey` (or `TELNYX_PUBLIC_KEY`) unless `skipSignatureVerification` is true.
- `skipSignatureVerification` is for local testing only.
- If you use ngrok free tier, set `publicUrl` to the exact ngrok URL; signature verification is always enforced.
- `tunnel.allowNgrokFreeTierLoopbackBypass: true` allows Twilio webhooks with invalid signatures **only** when `tunnel.provider="ngrok"` and `serve.bind` is loopback (ngrok local agent). Use for local dev only.
- Ngrok free tier URLs can change or add interstitial behavior; if `publicUrl` drifts, Twilio signatures will fail. For production, prefer a stable domain or Tailscale funnel.
- Streaming security defaults:
  - `streaming.preStartTimeoutMs` closes sockets that never send a valid `start` frame.
  - `streaming.maxPendingConnections` caps total unauthenticated pre-start sockets.
  - `streaming.maxPendingConnectionsPerIp` caps unauthenticated pre-start sockets per source IP.
  - `streaming.maxConnections` caps total open media stream sockets (pending + active).

## Stale call reaper

Use `staleCallReaperSeconds` to end calls that never receive a terminal webhook
(for example, notify-mode calls that never complete). The default is `0`
(disabled).

Recommended ranges:

- **Production:** `120`–`300` seconds for notify-style flows.
- Keep this value **higher than `maxDurationSeconds`** so normal calls can
  finish. A good starting point is `maxDurationSeconds + 30–60` seconds.

Example:

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        config: {
          maxDurationSeconds: 300,
          staleCallReaperSeconds: 360,
        },
      },
    },
  },
}
```

## Webhook Security

When a proxy or tunnel sits in front of the Gateway, the plugin reconstructs the
public URL for signature verification. These options control which forwarded
headers are trusted.

`webhookSecurity.allowedHosts` allowlists hosts from forwarding headers.

`webhookSecurity.trustForwardingHeaders` trusts forwarded headers without an allowlist.

`webhookSecurity.trustedProxyIPs` only trusts forwarded headers when the request
remote IP matches the list.

Webhook replay protection is enabled for Twilio and Plivo. Replayed valid webhook
requests are acknowledged but skipped for side effects.

Twilio conversation turns include a per-turn token in `<Gather>` callbacks, so
stale/replayed speech callbacks cannot satisfy a newer pending transcript turn.

Example with a stable public host:

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        config: {
          publicUrl: "https://voice.example.com/voice/webhook",
          webhookSecurity: {
            allowedHosts: ["voice.example.com"],
          },
        },
      },
    },
  },
}
```

## TTS for calls

Voice Call uses the core `messages.tts` configuration (OpenAI or ElevenLabs) for
streaming speech on calls. You can override it under the plugin config with the
**same shape** — it deep‑merges with `messages.tts`.

```json5
{
  tts: {
    provider: "elevenlabs",
    elevenlabs: {
      voiceId: "pMsXgVXv3BLzUgSXRplE",
      modelId: "eleven_multilingual_v2",
    },
  },
}
```

Notes:

- **Edge TTS is ignored for voice calls** (telephony audio needs PCM; Edge output is unreliable).
- Core TTS is used when Twilio media streaming is enabled; otherwise calls fall back to provider native voices.

### More examples

Use core TTS only (no override):

```json5
{
  messages: {
    tts: {
      provider: "openai",
      openai: { voice: "alloy" },
    },
  },
}
```

Override to ElevenLabs just for calls (keep core default elsewhere):

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
              modelId: "eleven_multilingual_v2",
            },
          },
        },
      },
    },
  },
}
```

Override only the OpenAI model for calls (deep‑merge example):

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        config: {
          tts: {
            openai: {
              model: "gpt-4o-mini-tts",
              voice: "marin",
            },
          },
        },
      },
    },
  },
}
```

## Inbound calls

Inbound policy defaults to `disabled`. To enable inbound calls, set:

```json5
{
  inboundPolicy: "allowlist",
  allowFrom: ["+15550001234"],
  inboundGreeting: "Hello! How can I help?",
}
```

Auto-responses use the agent system. Tune with:

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

## Agent tool

Tool name: `voice_call`

Actions:

- `initiate_call` (message, to?, mode?)
- `continue_call` (callId, message)
- `speak_to_user` (callId, message)
- `end_call` (callId)
- `get_status` (callId)

This repo ships a matching skill doc at `skills/voice-call/SKILL.md`.

## Gateway RPC

- `voicecall.initiate` (`to?`, `message`, `mode?`)
- `voicecall.continue` (`callId`, `message`)
- `voicecall.speak` (`callId`, `message`)
- `voicecall.end` (`callId`)
- `voicecall.status` (`callId`)
