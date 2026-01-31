---
title: "OpenResponses gateway(OpenResponses gateway 整合)"
summary: "計畫：新增 OpenResponses /v1/responses 端點並乾淨地棄用 chat completions"
owner: "openclaw"
status: "draft"
last_updated: "2026-01-19"
---

# OpenResponses Gateway Integration Plan(OpenResponses Gateway 整合計畫)

## 背景

OpenClaw Gateway 目前在 `/v1/chat/completions` 公開最小的 OpenAI 相容 Chat Completions 端點（請參閱 [OpenAI Chat Completions](/gateway/openai-http-api)）。

Open Responses 是基於 OpenAI Responses API 的開放推理標準。它專為
代理工作流程設計，並使用基於項目的輸入加上語意串流事件。OpenResponses
規格定義 `/v1/responses`，而非 `/v1/chat/completions`。

## 目標

- 新增符合 OpenResponses 語意的 `/v1/responses` 端點。
- 將 Chat Completions 保留為易於停用並最終移除的相容性層。
- 使用隔離、可重複使用的 schemas 標準化驗證和解析。

## 非目標

- 第一階段的完整 Open Responses 功能平價（images、files、hosted tools）。
- 取代內部 agent 執行邏輯或工具編排。
- 在第一階段變更現有的 `/v1/chat/completions` 行為。

## 研究摘要

來源：OpenResponses OpenAPI、OpenResponses 規格網站和 Hugging Face 部落格文章。

提取的關鍵點：

- `POST /v1/responses` 接受 `CreateResponseBody` 欄位，如 `model`、`input`（字串或 `ItemParam[]`）、`instructions`、`tools`、`tool_choice`、`stream`、`max_output_tokens` 和 `max_tool_calls`。
- `ItemParam` 是以下的區分聯合：
  - 具有角色 `system`、`developer`、`user`、`assistant` 的 `message` 項目
  - `function_call` 和 `function_call_output`
  - `reasoning`
  - `item_reference`
- 成功的回應返回具有 `object: "response"`、`status` 和 `output` 項目的 `ResponseResource`。
- 串流使用語意事件，例如：
  - `response.created`、`response.in_progress`、`response.completed`、`response.failed`
  - `response.output_item.added`、`response.output_item.done`
  - `response.content_part.added`、`response.content_part.done`
  - `response.output_text.delta`、`response.output_text.done`
- 規格要求：
  - `Content-Type: text/event-stream`
  - `event:` 必須匹配 JSON `type` 欄位
  - 終端事件必須是字面值 `[DONE]`
- Reasoning 項目可能公開 `content`、`encrypted_content` 和 `summary`。
- HF 範例在請求中包含 `OpenResponses-Version: latest`（選用標頭）。

## 提議的架構

- 新增 `src/gateway/open-responses.schema.ts`，僅包含 Zod schemas（無 gateway 匯入）。
- 為 `/v1/responses` 新增 `src/gateway/openresponses-http.ts`（或 `open-responses-http.ts`）。
- 保持 `src/gateway/openai-http.ts` 完整作為舊版相容性適配器。
- 新增設定 `gateway.http.endpoints.responses.enabled`（預設 `false`）。
- 保持 `gateway.http.endpoints.chatCompletions.enabled` 獨立；允許兩個端點分別切換。
- 當 Chat Completions 啟用時發出啟動警告以發出舊版狀態訊號。

## Chat Completions 的棄用路徑

- 維護嚴格的模組邊界：responses 和 chat completions 之間沒有共享 schema 類型。
- 透過設定使 Chat Completions 選用，以便可以在沒有程式碼變更的情況下停用它。
- 一旦 `/v1/responses` 穩定，更新文件以將 Chat Completions 標記為舊版。
- 選用的未來步驟：將 Chat Completions 請求對應到 Responses 處理器，以獲得更簡單的移除路徑。

## 第 1 階段支援子集

- 接受 `input` 作為字串或具有訊息角色和 `function_call_output` 的 `ItemParam[]`。
- 將 system 和 developer 訊息提取到 `extraSystemPrompt` 中。
- 使用最近的 `user` 或 `function_call_output` 作為 agent 執行的當前訊息。
- 拒絕不支援的內容部分（image/file），使用 `invalid_request_error`。
- 返回具有 `output_text` 內容的單一 assistant 訊息。
- 返回具有歸零值的 `usage`，直到 token 計算被連線。

## 驗證策略（無 SDK）

- 為以下支援子集實作 Zod schemas：
  - `CreateResponseBody`
  - `ItemParam` + 訊息內容部分聯合
  - `ResponseResource`
  - gateway 使用的串流事件形狀
- 將 schemas 保存在單一、隔離的模組中，以避免偏差並允許未來的 codegen。

## 串流實作（第 1 階段）

- 具有 `event:` 和 `data:` 的 SSE 行。
- 所需序列（最小可行）：
  - `response.created`
  - `response.output_item.added`
  - `response.content_part.added`
  - `response.output_text.delta`（根據需要重複）
  - `response.output_text.done`
  - `response.content_part.done`
  - `response.completed`
  - `[DONE]`

## 測試和驗證計畫

- 為 `/v1/responses` 新增 e2e 覆蓋：
  - 需要認證
  - 非串流回應形狀
  - 串流事件順序和 `[DONE]`
  - 具有標頭和 `user` 的會話路由
- 保持 `src/gateway/openai-http.e2e.test.ts` 不變。
- 手動：使用 `stream: true` curl 到 `/v1/responses` 並驗證事件順序和終端 `[DONE]`。

## 文件更新（後續行動）

- 為 `/v1/responses` 使用和範例新增新的文件頁面。
- 使用舊版注意事項和指向 `/v1/responses` 的指標更新 `/gateway/openai-http-api`。
