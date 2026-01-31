---
title: "Media understanding(媒體理解)"
summary: "針對傳入的圖片/音訊/影片進行媒體理解（選用），支援供應商 API 與 CLI 備援機制"
read_when:
  - 設計或重構媒體理解邏輯時
  - 調整傳入音訊/影片/圖片的預處理流程時
---

# 媒體理解 (傳入) — 2026-01-17

OpenClaw 可以在回覆流水線執行前，對傳出的**媒體（圖片/音訊/影片）進行摘要**。系統會自動偵測可用的本地工具或供應商金鑰，並支援自訂或停用。即使關閉了媒體理解，模型仍會照常收到原始檔案或網址。

## 設計目標
- **選用性**：將傳入媒體預先「消化」成短文字，以實現更快的路由與更精確的指令解析。
- **保留原始媒體**：原始檔案始終會傳送給模型。
- **多元支援**：支援**供應商 API** 與 **CLI 備援**。
- **順序備援**：支援多組模型，並依序處理報錯、大小限制或逾時等例外情況。

## 高階行為說明
1. **媒體收集**：彙整傳入的附件（路徑、網址、類型）。
2. **能力過濾**：針對啟用的能力（圖片/音訊/影片），根據原則選擇附件（預設：第一個）。
3. **模型選擇**：挑選第一個符合條件（大小、能力、認證）的模型。
4. **備援路徑**：若該模型失敗或媒體過大，則**自動嘗試下一個項目**。
5. **成功結果**：
   - 訊息主體 (`Body`) 會改為 `[Image]`、`[Audio]` 或 `[Video]` 區塊。
   - 音訊會設定 `{{Transcript}}`；指令解析會優先使用說明文字（若存在），否則使用轉錄內容。

## 配置總覽
`tools.media` 支援**共享模型**以及各項能力的獨立覆寫：

- `tools.media.models`：共享的模型列表（透過 `capabilities` 過濾適用類型）。
- `tools.media.image` / `audio` / `video`：
  - 預設值（`prompt`、`maxChars`、`maxBytes`、`timeoutSeconds`）。
  - 供應商覆寫（`baseUrl`、`headers`）。
  - 深層配置（如 Deepgram 特有選項）。
  - **附件原則** (Attachment policy)：`mode` (單個/全部)、`maxAttachments`、`prefer`。
- `tools.media.concurrency`：最大並行執行數（預設為 **2**）。

### 自動偵測媒體理解 (預設行為)
若您未手動配置模型且未明確停用，OpenClaw 會依序偵測並**停在第一個可用的選項**：

1. **本地 CLI 工具** (僅音訊)：`sherpa-onnx-offline`、`whisper-cli`、`whisper`。
2. **Gemini CLI** (`gemini`)：使用 `read_many_files`。
3. **供應商金鑰**：
   - 音訊：OpenAI → Groq → Deepgram → Google
   - 圖片：OpenAI → Anthropic → Google → MiniMax
   - 影片：Google

## 供應商支援矩陣
| 能力 | 供應商整合 | 備註 |
|------------|----------------------|-------|
| 圖片 (Image) | OpenAI / Anthropic / Google / 等 | 註冊表中支援視覺的模型皆可運作。 |
| 音訊 (Audio) | OpenAI, Groq, Deepgram, Google | 提供轉錄服務 (Whisper/Deepgram/Gemini)。 |
| 影片 (Video) | Google (Gemini API) | 提供影片內容理解。 |

## 推薦供應商配置
- **圖片**：優先使用您目前的主力模型（如果支援圖片）。
- **音訊**：推薦 `openai/gpt-4o-mini-transcribe` 或 `deepgram/nova-3`。
- **影片**：推薦 `google/gemini-3-flash-preview` (速度快) 或 `google/gemini-3-pro-preview` (描述更豐富)。

## 附件原則 (Attachment Policy)
您可以控制如何處理多個附件：
- `mode`: `first` (僅處理第一個) 或 `all` (處理全部，輸出時會標記為 `[Image 1/2]` 等)。
- `maxAttachments`: 處理數量上限（預設為 **1**）。

## 注意事項
- 媒體理解屬於**盡力而為** (Best-effort)。若執行報錯，並不會阻斷後續的回覆流程。
- 即使媒體理解功能已停用，附件仍會被傳遞給後端模型。
- 可使用 `scope` 設定來限制媒體理解僅在特定場景（例如僅限私訊）執行。
