---
summary: "Voice Call 外掛程式：透過 Twilio/Telnyx/Plivo 的出站 + 入站呼叫（外掛程式安裝 + 設定 + CLI）"
read_when:
  - 你想從 OpenClaw 撥出語音呼叫
  - 你正在設定或開發 Voice Call 外掛程式
title: "Voice Call Plugin（Voice Call 外掛程式）"
---

# Voice Call（外掛程式）

透過外掛程式為 OpenClaw 提供語音呼叫。支援出站通知和帶有入站原則的多轉換交談。

目前提供者：

- `twilio`（Programmable Voice + Media Streams）
- `telnyx`（Call Control v2）
- `plivo`（Voice API + XML 傳輸 + GetInput 語音）
- `mock`（開發/無網路）

快速心理模型：

- 安裝外掛程式
- 重新啟動 Gateway
- 在 `plugins.entries.voice-call.config` 下設定
- 使用 `openclaw voicecall ...` 或 `voice_call` 工具

## 它在哪裡執行（本機與遠端）

Voice Call 外掛程式在 **Gateway 進程內執行**。

如果使用遠端 Gateway，在**執行 Gateway 的機器**上安裝/設定外掛程式，然後重新啟動 Gateway 以載入。

## 安裝

### 選項 A：從 npm 安裝（建議）

```bash
openclaw plugins install @openclaw/voice-call
```

之後重新啟動 Gateway。

### 選項 B：從本機資料夾安裝（開發、無複製）

```bash
openclaw plugins install ./extensions/voice-call
cd ./extensions/voice-call && pnpm install
```

之後重新啟動 Gateway。

## 設定

在 `plugins.entries.voice-call.config` 下設定：

```json5
{
  plugins: {
    entries: {
      "voice-call": {
        config: {
          provider: "twilio",
          // 提供者特定的設定
        },
      },
    },
  },
}
```

詳見外掛程式文件了解提供者特定設定。
