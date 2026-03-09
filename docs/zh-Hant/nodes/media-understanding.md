---
summary: "收到的影像/音訊/影片理解（選用），搭配提供商 + CLI 退備"
read_when:
  - 設計或重構媒體理解
  - 調整收到的音訊/影片/影像前處理
title: "Media Understanding（媒體理解）"
---

# 媒體理解（收到的）— 2026-01-17

OpenClaw 可以在回覆流程執行前**摘要收到的媒體**（影像/音訊/影片）。它會自動偵測本地工具或提供商金鑰何時可用，並可停用或自訂。若理解關閉，模型仍會照常接收原始檔案/URL。

## 目標

- 選用：將收到的媒體預先摘要為簡短文字，以加快路由並改善指令解析。
- 始終保留對模型的原始媒體傳遞。
- 支援**提供商 API** 和 **CLI 退備**。
- 允許多個模型搭配有序退備（錯誤/大小/逾時）。

## 高階行為

1. 收集收到的附件（`MediaPaths`、`MediaUrls`、`MediaTypes`）。
2. 對每個已啟用的功能（影像/音訊/影片），根據策略選擇附件（預設：**第一個**）。
3. 選擇第一個符合資格的模型條目（大小 + 功能 + 驗證）。
4. 若模型失敗或媒體過大，**退備至下一個條目**。
5. 成功時：
   - `Body` 變成 `[Image]`、`[Audio]` 或 `[Video]` 區塊。
   - 音訊設定 `{{Transcript}}`；指令解析在字幕存在時使用字幕文字，否則使用轉錄文字。
   - 字幕保留為區塊內的 `User text:`。

若理解失敗或停用，**回覆流程繼續**使用原始本文 + 附件。

## 設定概述

`tools.media` 支援**共享模型**加上每個功能的覆蓋：

- `tools.media.models`：共享模型清單（使用 `capabilities` 進行限制）。
- `tools.media.image` / `tools.media.audio` / `tools.media.video`：
  - 預設值（`prompt`、`maxChars`、`maxBytes`、`timeoutSeconds`、`language`）
  - 提供商覆蓋（`baseUrl`、`headers`、`providerOptions`）
  - 透過 `tools.media.audio.providerOptions.deepgram` 設定 Deepgram 音訊選項
  - 音訊轉錄回顯控制（`echoTranscript`，預設 `false`；`echoFormat`）
  - 可選的**每個功能 `models` 清單**（優先於共享模型）
  - `attachments` 策略（`mode`、`maxAttachments`、`prefer`）
  - `scope`（可選，依頻道/chatType/session 鍵限制）
- `tools.media.concurrency`：最大並行功能執行數（預設 **2**）。

```json5
{
  tools: {
    media: {
      models: [
        /* 共享清單 */
      ],
      image: {
        /* 可選覆蓋 */
      },
      audio: {
        /* 可選覆蓋 */
        echoTranscript: true,
        echoFormat: '📝 "{transcript}"',
      },
      video: {
        /* 可選覆蓋 */
      },
    },
  },
}
```

### 模型條目

每個 `models[]` 條目可以是**提供商**或 **CLI**：

```json5
{
  type: "provider", // 若省略則為預設
  provider: "openai",
  model: "gpt-5.2",
  prompt: "Describe the image in <= 500 chars.",
  maxChars: 500,
  maxBytes: 10485760,
  timeoutSeconds: 60,
  capabilities: ["image"], // 可選，用於多模態條目
  profile: "vision-profile",
  preferredProfile: "vision-fallback",
}
```

```json5
{
  type: "cli",
  command: "gemini",
  args: [
    "-m",
    "gemini-3-flash",
    "--allowed-tools",
    "read_file",
    "Read the media at {{MediaPath}} and describe it in <= {{MaxChars}} characters.",
  ],
  maxChars: 500,
  maxBytes: 52428800,
  timeoutSeconds: 120,
  capabilities: ["video", "image"],
}
```

CLI 範本也可以使用：

- `{{MediaDir}}`（包含媒體檔案的目錄）
- `{{OutputDir}}`（為此次執行建立的暫存目錄）
- `{{OutputBase}}`（暫存檔案基礎路徑，無副檔名）

## 預設值與限制

建議的預設值：

- `maxChars`：影像/影片為 **500**（簡短、指令友善）
- `maxChars`：音訊**不設定**（完整轉錄，除非你設定限制）
- `maxBytes`：
  - 影像：**10MB**
  - 音訊：**20MB**
  - 影片：**50MB**

規則：

- 若媒體超過 `maxBytes`，該模型會被跳過並**嘗試下一個模型**。
- 小於 **1024 bytes** 的音訊檔案被視為空白/損毀，在提供商/CLI 轉錄前跳過。
- 若模型返回超過 `maxChars`，輸出會被截斷。
- `prompt` 預設為簡單的「Describe the {media}.」加上 `maxChars` 指引（僅限影像/影片）。
- 若 `<capability>.enabled: true` 但未設定模型，OpenClaw 在其提供商支援該功能時嘗試**目前的回覆模型**。

### 自動偵測媒體理解（預設）

若 `tools.media.<capability>.enabled` **未**設定為 `false` 且你未設定模型，OpenClaw 按此順序自動偵測並**在第一個有效選項時停止**：

1. **本地 CLI**（僅音訊；若已安裝）
   - `sherpa-onnx-offline`（需要含 encoder/decoder/joiner/tokens 的 `SHERPA_ONNX_MODEL_DIR`）
   - `whisper-cli`（`whisper-cpp`；使用 `WHISPER_CPP_MODEL` 或捆綁的 tiny 模型）
   - `whisper`（Python CLI；自動下載模型）
2. **Gemini CLI**（`gemini`）使用 `read_many_files`
3. **提供商金鑰**
   - 音訊：OpenAI → Groq → Deepgram → Google
   - 影像：OpenAI → Anthropic → Google → MiniMax
   - 影片：Google

若要停用自動偵測，設定：

```json5
{
  tools: {
    media: {
      audio: {
        enabled: false,
      },
    },
  },
}
```

注意：二進位偵測在 macOS/Linux/Windows 上是盡力而為；確保 CLI 在 `PATH` 上（我們會展開 `~`），或設定含完整指令路徑的明確 CLI 模型。

### 代理環境支援（提供商模型）

啟用基於提供商的**音訊**和**影片**媒體理解時，OpenClaw 會為提供商 HTTP 呼叫遵守標準的出站代理環境變數：

- `HTTPS_PROXY`
- `HTTP_PROXY`
- `https_proxy`
- `http_proxy`

若未設定代理環境變數，媒體理解使用直接出站。
若代理值格式錯誤，OpenClaw 記錄警告並退備至直接擷取。

## 功能（選用）

若你設定 `capabilities`，條目僅針對那些媒體類型執行。對於共享清單，OpenClaw 可推斷預設值：

- `openai`、`anthropic`、`minimax`：**影像**
- `google`（Gemini API）：**影像 + 音訊 + 影片**
- `groq`：**音訊**
- `deepgram`：**音訊**

對於 CLI 條目，**明確設定 `capabilities`** 以避免意外比對。
若省略 `capabilities`，條目符合其所在清單的資格。

## 提供商支援矩陣（OpenClaw 整合）

| 功能 | 提供商整合                                     | 備注                                            |
| ---- | ---------------------------------------------- | ----------------------------------------------- |
| 影像 | OpenAI / Anthropic / Google / 其他 via `pi-ai` | 任何支援影像的模型均可使用。                    |
| 音訊 | OpenAI、Groq、Deepgram、Google、Mistral        | 提供商轉錄（Whisper/Deepgram/Gemini/Voxtral）。 |
| 影片 | Google（Gemini API）                           | 提供商影片理解。                                |

## 模型選擇指引

- 在品質與安全性重要時，優先為每個媒體功能選擇最強的最新世代模型。
- 對於處理不受信任輸入的工具啟用 agent，避免使用舊版/較弱的媒體模型。
- 每個功能保留至少一個退備以確保可用性（高品質模型 + 更快/更便宜的模型）。
- CLI 退備（`whisper-cli`、`whisper`、`gemini`）在提供商 API 不可用時很有用。
- `parakeet-mlx` 注意：使用 `--output-dir` 時，OpenClaw 在輸出格式為 `txt`（或未指定）時讀取 `<output-dir>/<media-basename>.txt`；非 `txt` 格式退備至 stdout。

## 附件策略

每個功能的 `attachments` 控制哪些附件被處理：

- `mode`：`first`（預設）或 `all`
- `maxAttachments`：處理數量上限（預設 **1**）
- `prefer`：`first`、`last`、`path`、`url`

使用 `mode: "all"` 時，輸出標記為 `[Image 1/2]`、`[Audio 2/2]` 等。

## 設定範例

### 1）共享模型清單 + 覆蓋

```json5
{
  tools: {
    media: {
      models: [
        { provider: "openai", model: "gpt-5.2", capabilities: ["image"] },
        {
          provider: "google",
          model: "gemini-3-flash-preview",
          capabilities: ["image", "audio", "video"],
        },
        {
          type: "cli",
          command: "gemini",
          args: [
            "-m",
            "gemini-3-flash",
            "--allowed-tools",
            "read_file",
            "Read the media at {{MediaPath}} and describe it in <= {{MaxChars}} characters.",
          ],
          capabilities: ["image", "video"],
        },
      ],
      audio: {
        attachments: { mode: "all", maxAttachments: 2 },
      },
      video: {
        maxChars: 500,
      },
    },
  },
}
```

### 2）僅音訊 + 影片（影像關閉）

```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        models: [
          { provider: "openai", model: "gpt-4o-mini-transcribe" },
          {
            type: "cli",
            command: "whisper",
            args: ["--model", "base", "{{MediaPath}}"],
          },
        ],
      },
      video: {
        enabled: true,
        maxChars: 500,
        models: [
          { provider: "google", model: "gemini-3-flash-preview" },
          {
            type: "cli",
            command: "gemini",
            args: [
              "-m",
              "gemini-3-flash",
              "--allowed-tools",
              "read_file",
              "Read the media at {{MediaPath}} and describe it in <= {{MaxChars}} characters.",
            ],
          },
        ],
      },
    },
  },
}
```

### 3）選用影像理解

```json5
{
  tools: {
    media: {
      image: {
        enabled: true,
        maxBytes: 10485760,
        maxChars: 500,
        models: [
          { provider: "openai", model: "gpt-5.2" },
          { provider: "anthropic", model: "claude-opus-4-6" },
          {
            type: "cli",
            command: "gemini",
            args: [
              "-m",
              "gemini-3-flash",
              "--allowed-tools",
              "read_file",
              "Read the media at {{MediaPath}} and describe it in <= {{MaxChars}} characters.",
            ],
          },
        ],
      },
    },
  },
}
```

### 4）多模態單一條目（明確功能）

```json5
{
  tools: {
    media: {
      image: {
        models: [
          {
            provider: "google",
            model: "gemini-3.1-pro-preview",
            capabilities: ["image", "video", "audio"],
          },
        ],
      },
      audio: {
        models: [
          {
            provider: "google",
            model: "gemini-3.1-pro-preview",
            capabilities: ["image", "video", "audio"],
          },
        ],
      },
      video: {
        models: [
          {
            provider: "google",
            model: "gemini-3.1-pro-preview",
            capabilities: ["image", "video", "audio"],
          },
        ],
      },
    },
  },
}
```

## 狀態輸出

媒體理解執行時，`/status` 包含簡短摘要行：

```
📎 Media: image ok (openai/gpt-5.2) · audio skipped (maxBytes)
```

顯示每個功能的結果，以及適用時選用的提供商/模型。

## 注意事項

- 理解是**盡力而為**。錯誤不會阻擋回覆。
- 理解停用時，附件仍會傳遞至模型。
- 使用 `scope` 限制理解執行的位置（例如僅限 DM）。

## 相關文件

- [設定](/zh-Hant/gateway/configuration)
- [影像與媒體支援](/zh-Hant/nodes/images)
