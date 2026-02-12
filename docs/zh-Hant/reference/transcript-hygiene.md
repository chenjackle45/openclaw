---
summary: "參考：特定提供者的文字記錄清理和修復規則"
read_when:
  - 你正在調試與文字記錄形狀相關的提供者請求拒絕
  - 你正在更改文字記錄清理或工具呼叫修復邏輯
  - 你正在調查提供者之間的工具呼叫 ID 不匹配
title: "Transcript Hygiene（文字記錄衛生）"
---

# 文字記錄衛生（提供者修正）

本文件描述在執行前（建置模型內容）應用於文字記錄的**特定提供者的修正**。這些是用於滿足嚴格提供者要求的**記憶體內**調整。這些衛生步驟**不會**重寫磁碟上儲存的 JSONL 文字記錄；但是，單獨的會話檔修復傳遞可能會透過在載入會話前刪除無效行來重寫格式不正確的 JSONL 檔案。當修復發生時，原始檔案會與會話檔案一起備份。

範圍包括：

- 工具呼叫 ID 清理
- 工具呼叫輸入驗證
- 工具結果配對修復
- 轉換驗證 / 排序
- 思考簽名清理
- 影像有效負載清理

如果你需要文字記錄存儲詳情，詳見：

- [/reference/session-management-compaction](/zh-Hant/reference/session-management-compaction)

---

## 這在哪裡執行

所有文字記錄衛生集中在嵌入式執行程式中：

- 原則選擇：`src/agents/transcript-policy.ts`
- 清理/修復應用：`src/agents/pi-embedded-runner/google.ts` 中的 `sanitizeSessionHistory`

原則使用 `provider`、`modelApi` 和 `modelId` 來決定要套用什麼。

與文字記錄衛生分開，會話檔在載入前會被修復（如果需要）：

- `src/agents/session-file-repair.ts` 中的 `repairSessionFileIfNeeded`
- 從 `run/attempt.ts` 和 `compact.ts`（嵌入式執行程式）呼叫

---

## 全域規則：影像清理

影像有效負載始終被清理以防止因大小限制而導致的提供者端拒絕（縮小/重新壓縮超大 base64 影像）。

實作：

- `src/agents/pi-embedded-helpers/images.ts` 中的 `sanitizeSessionMessagesImages`
- `src/agents/tool-images.ts` 中的 `sanitizeContentBlocksImages`

---

## 全域規則：格式不正確的工具呼叫

遺漏 `input` 和 `arguments` 的助手工具呼叫區塊在建置模型內容前會被刪除。這可防止來自部分持久化工具呼叫的提供者拒絕（例如，在費率限制失敗後）。

實作：

- `src/agents/session-transcript-repair.ts` 中的 `sanitizeToolCallInputs`
- 在 `src/agents/pi-embedded-runner/google.ts` 中的 `sanitizeSessionHistory` 中應用

---

## 提供者矩陣（目前行為）

**OpenAI / OpenAI Codex**

- 僅影像清理。
- 在模型切換到 OpenAI Responses/Codex 時，刪除孤立的推理簽名（不後跟內容區塊的獨立推理項目）。
- 無工具呼叫 ID 清理。
- 無工具結果配對修復。
- 無轉換驗證或重新排序。
- 無合成工具結果。
- 無思考簽名去除。

**Google（生成式 AI / Gemini CLI / Antigravity）**

- 工具呼叫 ID 清理：嚴格英數字。
- 工具結果配對修復和合成工具結果。
- 轉換驗證（Gemini 風格轉換交替）。
- Google 轉換排序修正（如果歷史以助手開始，則前置一個微小使用者引導程序）。
- Antigravity Claude：規範化思考簽名；刪除未簽名的思考區塊。

**Anthropic / Minimax（Anthropic 相容）**

- 工具結果配對修復和合成工具結果。
- 轉換驗證（合併連續使用者轉換以滿足嚴格交替）。

**Mistral（包括基於模型 ID 的檢測）**

- 工具呼叫 ID 清理：strict9（英數字長度 9）。

**OpenRouter Gemini**

- 思考簽名清理：去除非 base64 `thought_signature` 值（保留 base64）。

**其他所有項目**

- 僅影像清理。

---

## 歷史行為（2026.1.22 之前）

在 2026.1.22 版本之前，OpenClaw 應用多層文字記錄衛生：

- **文字記錄清理擴充套件**在每個內容建置上執行，可以：
  - 修復工具使用/結果配對。
  - 清理工具呼叫 ID（包括保留 `_`/`-` 的非嚴格模式）。
- 執行程式也執行了提供者特定的清理，這複製了工作。
- 其他變更發生在提供者原則之外，包括：
  - 在持久化前從助手文字去除 `<final>` 標籤。
  - 刪除空的助手錯誤轉換。
  - 在工具呼叫後修剪助手內容。

這種複雜性導致跨提供者回歸（特別是 `openai-responses` `call_id|fc_id` 配對）。2026.1.22 清理移除了擴充套件，集中了執行程式中的邏輯，使 OpenAI 在影像清理之外**無需觸及**。
