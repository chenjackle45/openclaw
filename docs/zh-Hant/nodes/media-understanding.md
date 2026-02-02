---
title: "媒體理解"
summary: "傳入圖片/音訊/影片理解（選用），具有供應商 + CLI 備援"
read_when:
  - 設計或重構媒體理解時
  - 調整傳入音訊/影片/圖片預處理時
---

# 媒體理解（傳入）— 2026-01-17

OpenClaw 可在回應流水線執行前**摘要傳入媒體**（圖片/音訊/影片）。它自動偵測當本地工具或供應商金鑰可用時，並可停用或自訂。若理解關閉，模型仍照常接收原始檔案/URL。

## 目標

- 選用：預先消化傳入媒體至短文字，以加快路由 + 更好的指令解析。
- 保留原始媒體遞送至模型（始終）。
- 支援**供應商 API** 和 **CLI 備援**。
- 允許多個模型搭配有序備援（錯誤/大小/逾時）。

## 高階行為

1. 彙整傳入附件（`MediaPaths`、`MediaUrls`、`MediaTypes`）。
2. 針對各啟用能力（圖片/音訊/影片），根據策略選擇附件（預設：**first**）。
3. 選擇第一個符合的模型項目（大小 + 能力 + 認證）。
4. 若模型失敗或媒體太大，**回退至下一項**。
5. 成功時：
   - `Body` 變成 `[Image]`、`[Audio]` 或 `[Video]` 區塊。
   - 音訊設定 `{{Transcript}}`；指令解析使用說明文字若存在，
     否則使用轉錄。
   - 說明文字保留為區塊內的 `User text:`。

若理解失敗或停用，**回應流程繼續**使用原始主體 + 附件。

## 配置概覽

`tools.media` 支援**共享模型**及各能力覆蓋：

- `tools.media.models`：共享模型列表（使用 `capabilities` 限制）。
- `tools.media.image` / `tools.media.audio` / `tools.media.video`：
  - 預設值（`prompt`、`maxChars`、`maxBytes`、`timeoutSeconds`、`language`）
  - 供應商覆蓋（`baseUrl`、`headers`、`providerOptions`）
  - Deepgram 音訊選項透由 `tools.media.audio.providerOptions.deepgram`
  - 選用**各能力 `models` 列表**（優先於共享模型）
  - `attachments` 策略（`mode`、`maxAttachments`、`prefer`）
  - `scope`（選用按頻道/chatType/工作階段金鑰限制）
- `tools.media.concurrency`：最大並行能力執行（預設 **2**）。

```json5
{
  tools: {
    media: {
      models: [
        /* shared list */
      ],
      image: {
        /* optional overrides */
      },
      audio: {
        /* optional overrides */
      },
      video: {
        /* optional overrides */
      },
    },
  },
}
```

### 模型項目

各 `models[]` 項目可為**供應商**或 **CLI**：

```json5
{
  type: "provider", // default if omitted
  provider: "openai",
  model: "gpt-5.2",
  prompt: "Describe the image in <= 500 chars.",
  maxChars: 500,
  maxBytes: 10485760,
  timeoutSeconds: 60,
  capabilities: ["image"], // optional, used for multi-modal entries
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

CLI 樣板也可使用：

- `{{MediaDir}}`（包含媒體檔案的目錄）
- `{{OutputDir}}`（為此執行建立的暫存目錄）
- `{{OutputBase}}`（暫存檔案基本路徑，無副檔名）

## 預設值和限制

建議的預設值：

- `maxChars`：**500** 用於圖片/影片（短，指令友好）
- `maxChars`：**未設定** 用於音訊（完整轉錄，除非您設定限制）
- `maxBytes`：
  - 圖片：**10MB**
  - 音訊：**20MB**
  - 影片：**50MB**

規則：

- 若媒體超過 `maxBytes`，該模型被略過且**嘗試下一個模型**。
- 若模型回傳超過 `maxChars`，輸出被修剪。
- `prompt` 預設為簡單「Describe the {media}.」加上 `maxChars` 指導（僅圖片/影片）。
- 若 `<capability>.enabled: true` 但未配置模型，OpenClaw 當其供應商支援該能力時試用
  **活躍回應模型**。

### 自動偵測媒體理解（預設）

若 `tools.media.<capability>.enabled` **未**設為 `false` 且您未配置模型，OpenClaw 自動偵測此順序並**停在第一個工作選項**：

1. **本地 CLI**（音訊僅；若已安裝）
   - `sherpa-onnx-offline`（需要 `SHERPA_ONNX_MODEL_DIR` 搭配 encoder/decoder/joiner/tokens）
   - `whisper-cli`（`whisper-cpp`；使用 `WHISPER_CPP_MODEL` 或內附 tiny 模型）
   - `whisper`（Python CLI；自動下載模型）
2. **Gemini CLI**（`gemini`）使用 `read_many_files`
3. **供應商金鑰**
   - 音訊：OpenAI → Groq → Deepgram → Google
   - 圖片：OpenAI → Anthropic → Google → MiniMax
   - 影片：Google

停用自動偵測，設定：

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

注意：CLI 偵測在 macOS/Linux/Windows 上為最佳努力；確保 CLI 在 `PATH` 上（我們展開 `~`），或設定完整命令路徑的明確 CLI 模型。

## 能力（選用）

若您設定 `capabilities`，項目僅針對那些媒體類型執行。對於共享列表，OpenClaw 可推論預設值：

- `openai`、`anthropic`、`minimax`：**image**
- `google`（Gemini API）：**image + audio + video**
- `groq`：**audio**
- `deepgram`：**audio**

對於 CLI 項目，**明確設定 `capabilities`** 以避免驚人的符合。
若您省略 `capabilities`，項目符合其出現的列表。

## 供應商支援矩陣（OpenClaw 整合）

| 能力 | 供應商整合 | 注意 |
| ---------- | ------------------------------------------------ | ------------------------------------------------- |
| 圖片 | OpenAI / Anthropic / Google / 其他透由 `pi-ai` | 註冊表中任何圖片能力模型都有效。 |
| 音訊 | OpenAI、Groq、Deepgram、Google | 供應商轉錄（Whisper/Deepgram/Gemini）。 |
| 影片 | Google（Gemini API） | 供應商影片理解。 |

## 推薦供應商

**圖片**

- 偏好您活躍的模型若它支援圖片。
- 好的預設值：`openai/gpt-5.2`、`anthropic/claude-opus-4-5`、`google/gemini-3-pro-preview`。

**音訊**

- `openai/gpt-4o-mini-transcribe`、`groq/whisper-large-v3-turbo` 或 `deepgram/nova-3`。
- CLI 備援：`whisper-cli`（whisper-cpp）或 `whisper`。
- Deepgram 設定：[Deepgram（音訊轉錄）](/providers/deepgram)。

**影片**

- `google/gemini-3-flash-preview`（快速）、`google/gemini-3-pro-preview`（更豐富）。
- CLI 備援：`gemini` CLI（支援影片/音訊上的 `read_file`）。

## 附件策略

各能力 `attachments` 控制哪些附件被處理：

- `mode`：`first`（預設）或 `all`
- `maxAttachments`：上限處理數（預設 **1**）
- `prefer`：`first`、`last`、`path`、`url`

當 `mode: "all"` 時，輸出標記為 `[Image 1/2]`、`[Audio 2/2]` 等。

## 配置範例

### 1) 共享模型列表 + 覆蓋

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

### 2) 音訊 + 影片僅（圖片關閉）

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

### 3) 選用圖片理解

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
          { provider: "anthropic", model: "claude-opus-4-5" },
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

### 4) 多模態單項目（明確能力）

```json5
{
  tools: {
    media: {
      image: {
        models: [
          {
            provider: "google",
            model: "gemini-3-pro-preview",
            capabilities: ["image", "video", "audio"],
          },
        ],
      },
      audio: {
        models: [
          {
            provider: "google",
            model: "gemini-3-pro-preview",
            capabilities: ["image", "video", "audio"],
          },
        ],
      },
      video: {
        models: [
          {
            provider: "google",
            model: "gemini-3-pro-preview",
            capabilities: ["image", "video", "audio"],
          },
        ],
      },
    },
  },
}
```

## 狀態輸出

當媒體理解執行時，`/status` 包含簡短摘要行：

```
📎 Media: image ok (openai/gpt-5.2) · audio skipped (maxBytes)
```

這顯示各能力結果及適用時選擇的提供者/模型。

## 注意

- 理解是**最佳努力**。錯誤不阻止回應。
- 即使理解停用，附件仍傳至模型。
- 使用 `scope` 限制理解執行位置（例如僅 DM）。

## 相關文件

- [配置](/gateway/configuration)
- [圖片與媒體支援](/nodes/images)
