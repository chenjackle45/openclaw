---
title: "openresponses-http-api(OpenResponses API (HTTP))"
summary: "從 Gateway 暴露 OpenResponses 相容的 /v1/responses HTTP Endpoint"
read_when:
  - 整合使用 OpenResponses API 的 Clients 時
  - 想要 Item-based Inputs, Client Tool Calls, 或 SSE Events 時
---

# OpenResponses API (HTTP)

OpenClaw 的 Gateway 可以服務一個 OpenResponses 相容的 `POST /v1/responses` Endpoint。

此 Endpoint **預設為停用**。請先在 Config 中啟用它。

- `POST /v1/responses`
- 與 Gateway 相同的 Port (WS + HTTP multiplex): `http://<gateway-host>:<port>/v1/responses`

在底層，請求會作為正常的 Gateway Agent Run 執行 (與 `openclaw agent` 相同的 Codepath)，因此 Routing/Permissions/Config 皆符合您的 Gateway 設定。

## 認證 (Authentication)

使用 Gateway Auth 設定。傳送 Bearer Token：

- `Authorization: Bearer <token>`

註記：
- 當 `gateway.auth.mode="token"`，使用 `gateway.auth.token` (或 `OPENCLAW_GATEWAY_TOKEN`)。
- 當 `gateway.auth.mode="password"`，使用 `gateway.auth.password` (或 `OPENCLAW_GATEWAY_PASSWORD`)。

## 選擇 Agent

無需自訂 Headers：將 Agent ID 編碼在 OpenResponses `model` 欄位中：

- `model: "openclaw:<agentId>"` (範例: `"openclaw:main"`, `"openclaw:beta"`)
- `model: "agent:<agentId>"` (別名)

或透過 Header 指定 OpenClaw Agent：

- `x-openclaw-agent-id: <agentId>` (預設: `main`)

進階：
- `x-openclaw-session-key: <sessionKey>` 以完全控制 Session Routing。

## 啟用 Endpoint

將 `gateway.http.endpoints.responses.enabled` 設定為 `true`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        responses: { enabled: true }
      }
    }
  }
}
```

## 停用 Endpoint

將 `gateway.http.endpoints.responses.enabled` 設定為 `false`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        responses: { enabled: false }
      }
    }
  }
}
```

## Session 行為

預設情況下，此 Endpoint 是 **Stateless per request** (每次呼叫產生新的 Session Key)。

若請求包含 OpenResponses `user` 字串，Gateway 會從中推導出穩定的 Session Key，因此重複呼叫可以共用 Agent Session。

## 請求形狀 (Request Shape)

請求遵循 Item-based Input 的 OpenResponses API。目前支援：

- `input`: 字串或 Item Objects 陣列。
- `instructions`: 合併入 System Prompt。
- `tools`: Client Tool Definitions (Function Tools)。
- `tool_choice`: 過濾或強制 Client Tools。
- `stream`: 啟用 SSE Streaming。
- `max_output_tokens`: 盡力而為的 Output Limit (相依於 Provider)。
- `user`: 穩定的 Session Routing。

接受但 **目前忽略**：

- `max_tool_calls`
- `reasoning`
- `metadata`
- `store`
- `previous_response_id`
- `truncation`

## Items (Input)

### `message`
Roles: `system`, `developer`, `user`, `assistant`.

- `system` 與 `developer` 被附加到 System Prompt。
- 最近的 `user` 或 `function_call_output` Item 成為“目前的訊息”。
- 較早的 User/Assistant 訊息作為 History 包含在 Context 中。

### `function_call_output` (Turn-based Tools)

將 Tool 結果送回給 Model：

```json
{
  "type": "function_call_output",
  "call_id": "call_123",
  "output": "{\"temperature\": \"72F\"}"
}
```

### `reasoning` 與 `item_reference`

為 Schema 相容性而接受，但在建置 Prompt 時被忽略。

## Tools (Client-side Function Tools)

透過 `tools: [{ type: "function", function: { name, description?, parameters? } }]` 提供 Tools。

若 Agent 決定呼叫 Tool，Response 會回傳 `function_call` Output Item。您接著發送帶有 `function_call_output` 的後續請求以繼續 Turn。

## Images (`input_image`)

支援 Base64 或 URL 來源：

```json
{
  "type": "input_image",
  "source": { "type": "url", "url": "https://example.com/image.png" }
}
```

允許的 MIME Types (目前): `image/jpeg`, `image/png`, `image/gif`, `image/webp`.
最大尺寸 (目前): 10MB.

## Files (`input_file`)

支援 Base64 或 URL 來源：

```json
{
  "type": "input_file",
  "source": {
    "type": "base64",
    "media_type": "text/plain",
    "data": "SGVsbG8gV29ybGQh",
    "filename": "hello.txt"
  }
}
```

允許的 MIME Types (目前): `text/plain`, `text/markdown`, `text/html`, `text/csv`, `application/json`, `application/pdf`.

最大尺寸 (目前): 5MB.

目前行為：
- 檔案內容被解碼並新增至 **System Prompt**，而非 User Message，因此它保持短暫存在 (Ephemeral) (不持久化於 Session History)。
- PDFs 會被解析為文字。若發現很少文字，前幾頁會被光柵化 (Rasterized) 為圖片並傳遞給 Model。

PDF 解析使用 Node 友善的 `pdfjs-dist` Legacy Build (無 Worker)。現代 PDF.js Build 預期 Browser Workers/DOM Globals，因此不在 Gateway 中使用。

URL Fetch 預設值:
- `files.allowUrl`: `true`
- `images.allowUrl`: `true`
- 請求受防護 (DNS Resolution, Private IP Blocking, Redirect Caps, Timeouts)。

## File + Image 限制 (Config)

預設值可在 `gateway.http.endpoints.responses` 下調整：

```json5
{
  gateway: {
    http: {
      endpoints: {
        responses: {
          enabled: true,
          maxBodyBytes: 20000000,
          files: {
            allowUrl: true,
            allowedMimes: ["text/plain", "text/markdown", "text/html", "text/csv", "application/json", "application/pdf"],
            maxBytes: 5242880,
            maxChars: 200000,
            maxRedirects: 3,
            timeoutMs: 10000,
            pdf: {
              maxPages: 4,
              maxPixels: 4000000,
              minTextChars: 200
            }
          },
          images: {
            allowUrl: true,
            allowedMimes: ["image/jpeg", "image/png", "image/gif", "image/webp"],
            maxBytes: 10485760,
            maxRedirects: 3,
            timeoutMs: 10000
          }
        }
      }
    }
  }
}
```

省略時的預設值：
- `maxBodyBytes`: 20MB
- `files.maxBytes`: 5MB
- `files.maxChars`: 200k
- `files.maxRedirects`: 3
- `files.timeoutMs`: 10s
- `files.pdf.maxPages`: 4
- `files.pdf.maxPixels`: 4,000,000
- `files.pdf.minTextChars`: 200
- `images.maxBytes`: 10MB
- `images.maxRedirects`: 3
- `images.timeoutMs`: 10s

## Streaming (SSE)

設定 `stream: true` 以接收 Server-Sent Events (SSE)：

- `Content-Type: text/event-stream`
- 每個 Event Line 為 `event: <type>` 與 `data: <json>`
- Stream 結束於 `data: [DONE]`

目前發出的 Event Types：
- `response.created`
- `response.in_progress`
- `response.output_item.added`
- `response.content_part.added`
- `response.output_text.delta`
- `response.output_text.done`
- `response.content_part.done`
- `response.output_item.done`
- `response.completed`
- `response.failed` (發生錯誤時)

## Usage

當底層 Provider 報告 Token Counts 時，`usage` 會被填充。

## 錯誤 (Errors)

錯誤使用如下的 JSON 物件：

```json
{ "error": { "message": "...", "type": "invalid_request_error" } }
```

常見情況：
- `401` Missing/Invalid Auth
- `400` Invalid Request Body
- `405` Wrong Method

## 範例

Non-streaming:
```bash
curl -sS http://127.0.0.1:18789/v1/responses \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'x-openclaw-agent-id: main' \
  -d '{
    "model": "openclaw",
    "input": "hi"
  }'
```

Streaming:
```bash
curl -N http://127.0.0.1:18789/v1/responses \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'x-openclaw-agent-id: main' \
  -d '{
    "model": "openclaw",
    "stream": true,
    "input": "hi"
  }'
```
