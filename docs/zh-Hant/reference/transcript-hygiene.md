---
title: "Transcript hygiene(Transcript 衛生)"
summary: "參考：Provider-specific Transcript 清理和修復規則"
read_when:
  - 您正在除錯與 Transcript 形狀相關的 Provider 請求拒絕
  - 您正在變更 Transcript 清理或 Tool-call 修復邏輯
  - 您正在調查跨 Providers 的 Tool-call ID 不符
---
# Transcript 衛生（Provider 修正）

本文件描述執行前套用至 Transcripts 的 **Provider-specific 修正**（建構 Model Context）。這些是**記憶體內**調整，用於滿足嚴格的 Provider 需求。它們**不會**重寫儲存在磁碟上的 JSONL Transcript。

範圍包括：
- Tool Call ID 清理
- Tool Result 配對修復
- Turn 驗證 / 排序
- Thought Signature 清理
- Image Payload 清理

如果您需要 Transcript 儲存詳情，請見：
- [/zh-Hant/reference/session-management-compaction](/zh-Hant/reference/session-management-compaction)

---

## 執行位置

所有 Transcript Hygiene 都集中在 Embedded Runner 中：
- Policy 選擇：`src/agents/transcript-policy.ts`
- 清理/修復套用：`src/agents/pi-embedded-runner/google.ts` 中的 `sanitizeSessionHistory`

Policy 使用 `provider`、`modelApi` 和 `modelId` 來決定套用什麼。

---

## 全域規則：Image 清理

Image Payloads 始終會被清理，以防止因大小限制而導致的 Provider 端拒絕（縮小/重新壓縮過大的 Base64 Images）。

實作：
- `src/agents/pi-embedded-helpers/images.ts` 中的 `sanitizeSessionMessagesImages`
- `src/agents/tool-images.ts` 中的 `sanitizeContentBlocksImages`

---

## Provider 矩陣（目前行為）

**OpenAI / OpenAI Codex**
- 僅 Image 清理。
- 切換到 OpenAI Responses/Codex 時，刪除孤立的 Reasoning Signatures（沒有後續 Content Block 的獨立 Reasoning Items）。
- 無 Tool Call ID 清理。
- 無 Tool Result 配對修復。
- 無 Turn 驗證或重新排序。
- 無合成 Tool Results。
- 無 Thought Signature 剝離。

**Google（Generative AI / Gemini CLI / Antigravity）**
- Tool Call ID 清理：嚴格英數字元。
- Tool Result 配對修復和合成 Tool Results。
- Turn 驗證（Gemini-style Turn 交替）。
- Google Turn 排序修正（如果歷史以 Assistant 開始則前置一個小的 User Bootstrap）。
- Antigravity Claude：正規化 Thinking Signatures；刪除未簽名的 Thinking Blocks。

**Anthropic / Minimax（Anthropic-compatible）**
- Tool Result 配對修復和合成 Tool Results。
- Turn 驗證（合併連續的 User Turns 以滿足嚴格交替）。

**Mistral（包括基於 Model-id 的偵測）**
- Tool Call ID 清理：strict9（英數字元長度 9）。

**OpenRouter Gemini**
- Thought Signature 清理：剝離非 Base64 `thought_signature` 值（保留 Base64）。

**其他所有**
- 僅 Image 清理。

---

## 歷史行為（2026.1.22 之前）

在 2026.1.22 發布之前，OpenClaw 套用多層 Transcript Hygiene：

- 一個 **Transcript-sanitize Extension** 在每次 Context Build 時執行，可以：
  - 修復 Tool Use/Result 配對。
  - 清理 Tool Call IDs（包括保留 `_`/`-` 的非嚴格模式）。
- Runner 也執行 Provider-specific 清理，這導致重複工作。
- 額外的變動發生在 Provider Policy 之外，包括：
  - 持久化前從 Assistant 文字剝離 `<final>` 標籤。
  - 刪除空的 Assistant 錯誤 Turns。
  - 截斷 Tool Calls 之後的 Assistant 內容。

這種複雜性導致跨 Provider 迴歸（特別是 `openai-responses` `call_id|fc_id` 配對）。2026.1.22 清理移除了 Extension，將邏輯集中在 Runner 中，並使 OpenAI 除 Image 清理外**不觸碰**。
