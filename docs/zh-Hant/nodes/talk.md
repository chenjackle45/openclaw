---
summary: "Talk 模式：使用 ElevenLabs TTS 進行連續語音對話"
read_when:
  - 在 macOS/iOS/Android 上實作 Talk 模式
  - 變更語音/TTS/中斷行為
title: "Talk Mode（Talk 模式）"
---

# Talk 模式

Talk 模式是連續語音對話循環：

1. 聆聽語音
2. 將轉錄傳送至模型（主 session，chat.send）
3. 等待回應
4. 透過 ElevenLabs 朗讀（串流播放）

## 行為（macOS）

- **始終顯示覆蓋層**：Talk 模式啟用時。
- **聆聽 → 思考 → 說話**階段轉換。
- 在**短暫停頓**（靜音視窗）時，目前轉錄被傳送。
- 回應被**寫入 WebChat**（與打字相同）。
- **語音時中斷**（預設開啟）：若使用者在助理說話時開始說話，停止播放並記錄中斷時間戳記供下次提示使用。

## 回應中的語音指令

助理可能在回應前加上**單一 JSON 行**來控制語音：

```json
{ "voice": "<voice-id>", "once": true }
```

規則：

- 僅第一個非空行。
- 未知金鑰被忽略。
- `once: true` 僅適用於目前回應。
- 不帶 `once`，語音成為 Talk 模式的新預設。
- JSON 行在 TTS 播放前被移除。

支援的金鑰：

- `voice` / `voice_id` / `voiceId`
- `model` / `model_id` / `modelId`
- `speed`、`rate`（WPM）、`stability`、`similarity`、`style`、`speakerBoost`
- `seed`、`normalize`、`lang`、`output_format`、`latency_tier`
- `once`

## 設定（`~/.openclaw/openclaw.json`）

```json5
{
  talk: {
    voiceId: "elevenlabs_voice_id",
    modelId: "eleven_v3",
    outputFormat: "mp3_44100_128",
    apiKey: "elevenlabs_api_key",
    silenceTimeoutMs: 1500,
    interruptOnSpeech: true,
  },
}
```

預設值：

- `interruptOnSpeech`：true
- `silenceTimeoutMs`：未設定時，Talk 保持平台預設的停頓視窗後才傳送轉錄（`macOS 和 Android 為 700 ms，iOS 為 900 ms`）
- `voiceId`：退備至 `ELEVENLABS_VOICE_ID` / `SAG_VOICE_ID`（或 API 金鑰可用時的第一個 ElevenLabs 語音）
- `modelId`：未設定時預設為 `eleven_v3`
- `apiKey`：退備至 `ELEVENLABS_API_KEY`（或 gateway shell 設定若可用）
- `outputFormat`：macOS/iOS 預設為 `pcm_44100`，Android 預設為 `pcm_24000`（設定 `mp3_*` 強制 MP3 串流）

## macOS UI

- 選單列開關：**Talk**
- 設定分頁：**Talk Mode** 群組（語音 id + 中斷開關）
- 覆蓋層：
  - **Listening**：雲朵以麥克風音量脈動
  - **Thinking**：下沉動畫
  - **Speaking**：輻射圓環
  - 點擊雲朵：停止朗讀
  - 點擊 X：結束 Talk 模式

## 注意事項

- 需要語音 + 麥克風權限。
- 對 session 鍵 `main` 使用 `chat.send`。
- TTS 使用 ElevenLabs 串流 API 搭配 `ELEVENLABS_API_KEY`，並在 macOS/iOS/Android 上漸進式播放以降低延遲。
- `eleven_v3` 的 `stability` 驗證為 `0.0`、`0.5` 或 `1.0`；其他模型接受 `0..1`。
- `latency_tier` 設定時驗證為 `0..4`。
- Android 支援 `pcm_16000`、`pcm_22050`、`pcm_24000` 和 `pcm_44100` 輸出格式，用於低延遲 AudioTrack 串流。
