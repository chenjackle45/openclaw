---
summary: "用於出站回覆的文字轉語音 (TTS)"
read_when:
  - Enabling text-to-speech for replies
  - Configuring TTS providers or limits
  - Using /tts commands
title: "Text-to-Speech（Text-to-Speech）"
---

# 文字轉語音 (TTS)

OpenClaw 可以使用 ElevenLabs、Microsoft 或 OpenAI 將出站回覆轉換為音訊。它可以在 OpenClaw 能夠傳送音訊的任何地方使用；Telegram 會取得圓形語音備註氣泡。

## 支援的服務

- **ElevenLabs**（主要或後備提供者）
- **Microsoft**（主要或後備提供者；目前綑綁的實作使用 `node-edge-tts`，當沒有 API 金鑰時為預設）
- **OpenAI**（主要或後備提供者；也用於摘要）

### Microsoft 語音筆記

綑綁的 Microsoft 語音提供者目前透過 `node-edge-tts` 程式庫使用 Microsoft Edge 的線上神經 TTS 服務。它是一個託管服務（不是本機），使用 Microsoft 端點，不需要 API 金鑰。`node-edge-tts` 公開語音設定選項和輸出格式，但不是所有選項都由該服務支援。使用 `edge` 的舊版設定和指令輸入仍然有效，並被標準化為 `microsoft`。

因為此路徑是沒有已發佈 SLA 或配額的公開網站服務，請將其視為盡力而為。如果您需要保證的限制和支援，請使用 OpenAI 或 ElevenLabs。

## 可選金鑰

如果您想要 OpenAI 或 ElevenLabs：

- `ELEVENLABS_API_KEY`（或 `XI_API_KEY`）
- `OPENAI_API_KEY`

Microsoft 語音**不**需要 API 金鑰。如果找不到 API 金鑰，OpenClaw 會預設為 Microsoft（除非透過 `messages.tts.microsoft.enabled=false` 或 `messages.tts.edge.enabled=false` 停用）。

如果設定了多個提供者，所選提供者會首先使用，其他提供者是後備選項。自動摘要使用設定的 `summaryModel`（或 `agents.defaults.model.primary`），因此如果您啟用摘要，該提供者也必須進行驗證。

## 服務連結

- [OpenAI 文字轉語音指南](https://platform.openai.com/docs/guides/text-to-speech)
- [OpenAI 音訊 API 參考](https://platform.openai.com/docs/api-reference/audio)
- [ElevenLabs 文字轉語音](https://elevenlabs.io/docs/api-reference/text-to-speech)
- [ElevenLabs 驗證](https://elevenlabs.io/docs/api-reference/authentication)
- [node-edge-tts](https://github.com/SchneeHertz/node-edge-tts)
- [Microsoft 語音輸出格式](https://learn.microsoft.com/azure/ai-services/speech-service/rest-text-to-speech#audio-outputs)

## 預設啟用嗎？

否。自動 TTS 預設**關閉**。在設定中使用 `messages.tts.auto` 或使用 `/tts always`（別名：`/tts on`）按工作階段啟用。

Microsoft 語音在啟用 TTS 後預設**啟用**，當沒有 OpenAI 或 ElevenLabs API 金鑰可用時會自動使用。

## 設定

TTS 設定位於 `openclaw.json` 中的 `messages.tts` 下。完整架構在 [閘道設定](/zh-Hant/gateway/configuration) 中。

### 最小設定（啟用 + 提供者）

\`\`\`json5
{
messages: {
tts: {
auto: "always",
provider: "elevenlabs",
},
},
}
\`\`\`

### OpenAI 主要，ElevenLabs 後備

\`\`\`json5
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
\`\`\`

### Microsoft 主要（無 API 金鑰）

\`\`\`json5
{
messages: {
tts: {
auto: "always",
provider: "microsoft",
microsoft: {
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
\`\`\`

### 停用 Microsoft 語音

\`\`\`json5
{
messages: {
tts: {
microsoft: {
enabled: false,
},
},
},
}
\`\`\`

### 自訂限制 + 首選項路徑

\`\`\`json5
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
\`\`\`

### 僅在入站語音備註後回覆音訊

\`\`\`json5
{
messages: {
tts: {
auto: "inbound",
},
},
}
\`\`\`

### 停用長回覆的自動摘要

\`\`\`json5
{
messages: {
tts: {
auto: "always",
},
},
}
\`\`\`

然後執行：

\`\`\`
/tts summary off
\`\`\`

### 欄位筆記

- `auto`：自動 TTS 模式（`off`、`always`、`inbound`、`tagged`）。
  - `inbound` 僅在入站語音備註後傳送音訊。
  - `tagged` 僅在回覆包含 `[[tts]]` 標籤時傳送音訊。
- `enabled`：舊版切換（doctor 將其遷移至 `auto`）。
- `mode`：`"final"`（預設）或 `"all"`（包括工具 / 區塊回覆）。
- `provider`：語音提供者 ID，例如 `"elevenlabs"`、`"microsoft"` 或 `"openai"`（後備自動）。
- 如果 `provider` **未設定**，OpenClaw 偏好 `openai`（如果有金鑰），然後 `elevenlabs`（如果有金鑰），否則 `microsoft`。
- 舊版 `provider: "edge"` 仍然有效，並被標準化為 `microsoft`。
- `summaryModel`：自動摘要的可選便宜模型；預設為 `agents.defaults.model.primary`。
  - 接受 `provider/model` 或設定的模型別名。
- `modelOverrides`：允許模型發出 TTS 指令（預設開啟）。
  - `allowProvider` 預設為 `false`（提供者切換是選擇加入）。
- `maxTextLength`：TTS 輸入的硬上限（字元）。如果超過，`/tts audio` 會失敗。
- `timeoutMs`：要求逾時 (ms)。
- `prefsPath`：覆蓋本機首選項 JSON 路徑（提供者 / 限制 / 摘要）。
- `apiKey` 值回退至環境變數（`ELEVENLABS_API_KEY`/`XI_API_KEY`、`OPENAI_API_KEY`）。
- `elevenlabs.baseUrl`：覆蓋 ElevenLabs API 基礎 URL。
- `openai.baseUrl`：覆蓋 OpenAI TTS 端點。
  - 解析順序：`messages.tts.openai.baseUrl` -> `OPENAI_TTS_BASE_URL` -> `https://api.openai.com/v1`
  - 非預設值被視為 OpenAI 相容 TTS 端點，因此接受自訂模型和語音名稱。
- `elevenlabs.voiceSettings`：
  - `stability`、`similarityBoost`、`style`：`0..1`
  - `useSpeakerBoost`：`true|false`
  - `speed`：`0.5..2.0`（1.0 = 正常）
- `elevenlabs.applyTextNormalization`：`auto|on|off`
- `elevenlabs.languageCode`：2 字母 ISO 639-1（例如 `en`、`de`）
- `elevenlabs.seed`：整數 `0..4294967295`（盡力而為決定論）
- `microsoft.enabled`：允許 Microsoft 語音使用（預設 `true`；無 API 金鑰）。
- `microsoft.voice`：Microsoft 神經語音名稱（例如 `en-US-MichelleNeural`）。
- `microsoft.lang`：語言代碼（例如 `en-US`）。
- `microsoft.outputFormat`：Microsoft 輸出格式（例如 `audio-24khz-48kbitrate-mono-mp3`）。
  - 請參閱 Microsoft 語音輸出格式以取得有效值；並非所有格式都由綑綁的 Edge 後端傳輸支援。
- `microsoft.rate` / `microsoft.pitch` / `microsoft.volume`：百分比字串（例如 `+10%`、`-5%`）。
- `microsoft.saveSubtitles`：將 JSON 字幕寫入音訊檔案旁邊。
- `microsoft.proxy`：Microsoft 語音要求的代理 URL。
- `microsoft.timeoutMs`：要求逾時覆蓋 (ms)。
- `edge.*`：相同 Microsoft 設定的舊版別名。

## 模型驅動的覆蓋（預設開啟）

預設情況下，模型**可以**為單一回覆發出 TTS 指令。當 `messages.tts.auto` 為 `tagged` 時，這些指令是觸發音訊的必要條件。

啟用後，模型可以發出 `[[tts:...]]` 指令以覆蓋單一回覆的語音，加上可選的 `[[tts:text]]`...`[[/tts:text]]` 區塊，以提供只應出現在音訊中的表情標籤（笑聲、唱歌提示等）。

除非 `modelOverrides.allowProvider: true`，否則忽略 `provider=...` 指令。

範例回覆承載：

\`\`\`
Here you go.

[[tts:voiceId=pMsXgVXv3BLzUgSXRplE model=eleven_v3 speed=1.1]]
[[tts:text]](laughs) Read the song once more.[[/tts:text]]
\`\`\`

可用指令金鑰（啟用時）：

- `provider`（已註冊的語音提供者 ID，例如 `openai`、`elevenlabs` 或 `microsoft`；需要 `allowProvider: true`）
- `voice`（OpenAI 語音）或 `voiceId`（ElevenLabs）
- `model`（OpenAI TTS 模型或 ElevenLabs 模型 ID）
- `stability`、`similarityBoost`、`style`、`speed`、`useSpeakerBoost`
- `applyTextNormalization`（`auto|on|off`）
- `languageCode`（ISO 639-1）
- `seed`

停用所有模型覆蓋：

\`\`\`json5
{
messages: {
tts: {
modelOverrides: {
enabled: false,
},
},
},
}
\`\`\`

可選的允許清單（啟用提供者切換，同時保持其他旋鈕可設定）：

\`\`\`json5
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
\`\`\`

## 每個使用者的首選項

斜線命令將本機覆蓋寫入 `prefsPath`（預設：`~/.openclaw/settings/tts.json`，使用 `OPENCLAW_TTS_PREFS` 或 `messages.tts.prefsPath` 覆蓋）。

儲存的欄位：

- `enabled`
- `provider`
- `maxLength`（摘要閾值；預設 1500 字元）
- `summarize`（預設 `true`）

這些為該主機覆蓋 `messages.tts.*`。

## 輸出格式（固定）

- **Telegram**：Opus 語音備註（ElevenLabs 為 `opus_48000_64`，OpenAI 為 `opus`）。
  - 48kHz / 64kbps 是一個很好的語音備註權衡，也是圓形氣泡所需的。
- **其他通道**：MP3（ElevenLabs 為 `mp3_44100_128`，OpenAI 為 `mp3`）。
  - 44.1kHz / 128kbps 是語音清晰度的預設平衡。
- **Microsoft**：使用 `microsoft.outputFormat`（預設 `audio-24khz-48kbitrate-mono-mp3`）。
  - 綑綁的傳輸接受 `outputFormat`，但並非所有格式都可從服務取得。
  - 輸出格式值遵循 Microsoft 語音輸出格式（包括 Ogg/WebM Opus）。
  - Telegram `sendVoice` 接受 OGG/MP3/M4A；如果您需要保證的 Opus 語音備註，請使用 OpenAI/ElevenLabs。
  - 如果設定的 Microsoft 輸出格式失敗，OpenClaw 會以 MP3 重試。

OpenAI/ElevenLabs 格式是固定的；Telegram 需要 Opus 以取得語音備註 UX。

## 自動 TTS 行為

啟用時，OpenClaw：

- 如果回覆已包含媒體或 `MEDIA:` 指令，則跳過 TTS。
- 跳過非常短的回覆（< 10 字元）。
- 使用 `agents.defaults.model.primary`（或 `summaryModel`）在啟用時摘要長回覆。
- 將產生的音訊附加到回覆。

如果回覆超過 `maxLength` 且摘要關閉（或沒有摘要模型的 API 金鑰），音訊會被跳過，並傳送正常的文字回覆。

## 流程圖

\`\`\`
Reply -> TTS enabled?
no -> send text
yes -> has media / MEDIA: / short?
yes -> send text
no -> length > limit?
no -> TTS -> attach audio
yes -> summary enabled?
no -> send text
yes -> summarize (summaryModel or agents.defaults.model.primary)
-> TTS -> attach audio
\`\`\`

## 斜線命令用法

有一個命令：`/tts`。請參閱 [斜線命令](/zh-Hant/tools/slash-commands) 以取得啟用詳情。

Discord 注意：`/tts` 是內建 Discord 命令，所以 OpenClaw 在那裡將 `/voice` 註冊為本機命令。文字 `/tts ...` 仍然有效。

\`\`\`
/tts off
/tts always
/tts inbound
/tts tagged
/tts status
/tts provider openai
/tts limit 2000
/tts summary off
/tts audio Hello from OpenClaw
\`\`\`

筆記：

- 命令需要授權的傳送者（允許清單 / 擁有者規則仍然適用）。
- `commands.text` 或本機命令註冊必須啟用。
- `off|always|inbound|tagged` 是按工作階段切換（`/tts on` 是 `/tts always` 的別名）。
- `limit` 和 `summary` 儲存在本機首選項中，而不是主設定中。
- `/tts audio` 產生一個一次性音訊回覆（不切換 TTS 開啟）。

## 代理程式工具

`tts` 工具將文字轉換為語音，並傳回用於回覆傳遞的音訊附件。當結果與 Telegram 相容時，OpenClaw 會將其標記為語音氣泡傳遞。

## 閘道 RPC

閘道方法：

- `tts.status`
- `tts.enable`
- `tts.disable`
- `tts.convert`
- `tts.setProvider`
- `tts.providers`
