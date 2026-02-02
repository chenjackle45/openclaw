---
title: "對話模式"
summary: "對話模式：使用 ElevenLabs TTS 進行連續語音對話"
read_when:
  - 在 macOS/iOS/Android 上實作對話模式時
  - 變更聲音/TTS/中斷行為時
---

# 對話模式

對話模式是連續語音對話循環：

1. 聆聽語音
2. 將轉錄傳至模型（主要工作階段，chat.send）
3. 等待回應
4. 透由 ElevenLabs 發言（串流播放）

## 行為（macOS）

- **始終在上覆蓋層**：對話模式啟用時。
- **聆聽 → 思考 → 說話**階段轉換。
- 在**短暫停頓**（靜音視窗）時，目前轉錄被發送。
- 回應被**寫至 WebChat**（同打字）。
- **在語音上中斷**（預設開啟）：若使用者在助理說話時開始說話，我們停止播放並記錄中斷時間戳記供下次提示。

## 回應中的語音指令

助理可能以**單一 JSON 行**前綴其回應來控制聲音：

```json
{ "voice": "<voice-id>", "once": true }
```

規則：

- 僅第一個非空行。
- 未知金鑰被忽略。
- `once: true` 僅適用於目前回應。
- 不帶 `once`，聲音成為對話模式的新預設。
- JSON 行在 TTS 播放前被移除。

支援的金鑰：

- `voice` / `voice_id` / `voiceId`
- `model` / `model_id` / `modelId`
- `speed`、`rate`（WPM）、`stability`、`similarity`、`style`、`speakerBoost`
- `seed`、`normalize`、`lang`、`output_format`、`latency_tier`
- `once`

## 配置（`~/.openclaw/openclaw.json`）

```json5
{
  talk: {
    voiceId: "elevenlabs_voice_id",
    modelId: "eleven_v3",
    outputFormat: "mp3_44100_128",
    apiKey: "elevenlabs_api_key",
    interruptOnSpeech: true,
  },
}
```

預設值：

- `interruptOnSpeech`：true
- `voiceId`：回退至 `ELEVENLABS_VOICE_ID` / `SAG_VOICE_ID`（或 API 金鑰可用時第一個 ElevenLabs 聲音）
- `modelId`：未設定時預設 `eleven_v3`
- `apiKey`：回退至 `ELEVENLABS_API_KEY`（或 Gateway shell 設定若可用）
- `outputFormat`：macOS/iOS 上預設 `pcm_44100`，Android 上 `pcm_24000`（設定 `mp3_*` 強制 MP3 串流）

## macOS UI

- 選單列開關：**Talk**
- 配置分頁：**Talk Mode** 群組（聲音 id + 中斷開關）
- 覆蓋層：
  - **Listening**：雲朵以麥克風電平脈動
  - **Thinking**：下沉動畫
  - **Speaking**：輻射圓環
  - 點擊雲朵：停止說話
  - 點擊 X：結束對話模式

## 注意

- 需要語音 + 麥克風權限。
- 使用 `chat.send`對著工作階段金鑰 `main`。
- TTS 使用 ElevenLabs 串流 API 搭配 `ELEVENLABS_API_KEY` 和漸進式播放在 macOS/iOS/Android 上以獲得更低延遲。
- `eleven_v3` 的 `stability` 驗證至 `0.0`、`0.5` 或 `1.0`；其他模型接受 `0..1`。
- `latency_tier` 設定時驗證至 `0..4`。
- Android 支援 `pcm_16000`、`pcm_22050`、`pcm_24000` 和 `pcm_44100` 輸出格式用於低延遲 AudioTrack 串流。
