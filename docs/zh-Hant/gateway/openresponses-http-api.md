---
summary: "從 Gateway 暴露 OpenResponses 相容的 /v1/responses HTTP endpoint"
read_when:
  - 整合使用 OpenResponses API 的 client 時
  - 需要 item-based inputs、client tool calls 或 SSE events 時
title: "OpenResponses API（OpenResponses API）"
---

# OpenResponses API（HTTP）

OpenClaw 的 Gateway 可以提供 OpenResponses 相容的 `POST /v1/responses` endpoint。

此 endpoint **預設停用**。請先在設定中啟用。

- `POST /v1/responses`
- 與 Gateway 使用相同埠（WS + HTTP 多工）：`http://<gateway-host>:<port>/v1/responses`

在底層，請求以正常的 Gateway agent 執行方式處理（與 `openclaw agent` 相同的程式碼路徑），因此路由/權限/設定與您的 Gateway 一致。

## 認證

使用 Gateway 認證設定。傳送 bearer token：

- `Authorization: Bearer <token>`

注意事項：

- 當 `gateway.auth.mode="token"` 時，使用 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）。
- 當 `gateway.auth.mode="password"` 時，使用 `gateway.auth.password`（或 `OPENCLAW_GATEWAY_PASSWORD`）。
- 若設定了 `gateway.auth.rateLimit` 且發生太多認證失敗，endpoint 會返回帶有 `Retry-After` 的 `429`。

## 安全邊界（重要）

將此 endpoint 視為 gateway 實例的**完整 operator 存取**介面。

- 此處的 HTTP bearer 認證不是狹義的每使用者範圍模型。
- 此 endpoint 的有效 Gateway token/password 應視為擁有者/operator 憑證。
- 請求透過與受信任的 operator 操作相同的控制平面 agent 路徑執行。
- 此 endpoint 沒有獨立的非擁有者/每使用者工具邊界；一旦呼叫者通過此處的 Gateway 認證，OpenClaw 將該呼叫者視為此 gateway 的受信任 operator。
- 若目標 agent 政策允許敏感工具，此 endpoint 可以使用它們。
- 僅在 loopback/tailnet/私有 ingress 上保留此 endpoint；不要直接暴露到公共網路。

請參閱 [Security](/zh-Hant/gateway/security) 和 [Remote access](/zh-Hant/gateway/remote)。

## 選擇 Agent

不需要自訂 header：在 OpenResponses `model` 欄位中編碼 agent id：

- `model: "openclaw:<agentId>"`（範例：`"openclaw:main"`、`"openclaw:beta"`）
- `model: "agent:<agentId>"`（別名）

或透過 header 指定特定的 OpenClaw agent：

- `x-openclaw-agent-id: <agentId>`（預設：`main`）

進階：

- `x-openclaw-session-key: <sessionKey>` 完全控制 session 路由。

## 啟用 endpoint

將 `gateway.http.endpoints.responses.enabled` 設為 `true`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        responses: { enabled: true },
      },
    },
  },
}
```

## 停用 endpoint

將 `gateway.http.endpoints.responses.enabled` 設為 `false`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        responses: { enabled: false },
      },
    },
  },
}
```

## Session 行為

預設情況下，endpoint **每個請求無狀態**（每次呼叫生成新的 session 鍵）。

若請求包含 OpenResponses `user` 字串，Gateway 會從中衍生穩定的 session 鍵，讓重複呼叫可以共享 agent session。

## 請求格式（支援項目）

請求遵循 OpenResponses API 的 item-based 輸入格式。目前支援：

- `input`：字串或 item 物件陣列。
- `instructions`：合併至系統 prompt。
- `tools`：client tool 定義（function tools）。
- `tool_choice`：篩選或要求 client tools。
- `stream`：啟用 SSE streaming。
- `max_output_tokens`：盡力而為的輸出限制（取決於供應商）。
- `user`：穩定的 session 路由。

接受但**目前忽略**：

- `max_tool_calls`
- `reasoning`
- `metadata`
- `store`
- `previous_response_id`
- `truncation`

## Items（輸入）

### `message`

角色：`system`、`developer`、`user`、`assistant`。

- `system` 和 `developer` 附加至系統 prompt。
- 最近的 `user` 或 `function_call_output` item 成為「目前訊息」。
- 較早的 user/assistant 訊息作為上下文歷史記錄包含。

### `function_call_output`（輪次型工具）

將工具結果回傳給模型：

```json
{
  "type": "function_call_output",
  "call_id": "call_123",
  "output": "{\"temperature\": \"72F\"}"
}
```

### `reasoning` 和 `item_reference`

為了 schema 相容性而接受，但在建立 prompt 時忽略。

## Tools（client 端 function tools）

提供工具：`tools: [{ type: "function", function: { name, description?, parameters? } }]`。

若 agent 決定呼叫工具，回應會返回 `function_call` 輸出 item。然後您發送包含 `function_call_output` 的後續請求以繼續輪次。

## 圖片（`input_image`）

支援 base64 或 URL 來源：

```json
{
  "type": "input_image",
  "source": { "type": "url", "url": "https://example.com/image.png" }
}
```

允許的 MIME 類型（目前）：`image/jpeg`、`image/png`、`image/gif`、`image/webp`、`image/heic`、`image/heif`。
最大大小（目前）：10MB。

## 檔案（`input_file`）

支援 base64 或 URL 來源：

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

允許的 MIME 類型（目前）：`text/plain`、`text/markdown`、`text/html`、`text/csv`、
`application/json`、`application/pdf`。

最大大小（目前）：5MB。

目前行為：

- 檔案內容被解碼並加入**系統 prompt**，而非使用者訊息，
  因此保持短暫性（不持久化在 session 歷史記錄中）。
- PDF 會進行文字解析。若找到的文字很少，前幾頁會被柵格化
  為圖片並傳給模型。

PDF 解析使用 Node 友善的 `pdfjs-dist` 舊版構建（無 worker）。現代
PDF.js 構建需要瀏覽器 workers/DOM globals，因此不在 Gateway 中使用。

URL 取得預設值：

- `files.allowUrl`：`true`
- `images.allowUrl`：`true`
- `maxUrlParts`：`8`（每個請求基於 URL 的 `input_file` + `input_image` 部分總數）
- 請求受到保護（DNS 解析、私有 IP 封鎖、重新導向上限、逾時）。
- 每個輸入類型支援選用的 hostname allowlists（`files.urlAllowlist`、`images.urlAllowlist`）。
  - 完全比對 host：`"cdn.example.com"`
  - 萬用字元子網域：`"*.assets.example.com"`（不比對 apex）

## 檔案 + 圖片限制（設定）

預設值可在 `gateway.http.endpoints.responses` 下調整：

```json5
{
  gateway: {
    http: {
      endpoints: {
        responses: {
          enabled: true,
          maxBodyBytes: 20000000,
          maxUrlParts: 8,
          files: {
            allowUrl: true,
            urlAllowlist: ["cdn.example.com", "*.assets.example.com"],
            allowedMimes: [
              "text/plain",
              "text/markdown",
              "text/html",
              "text/csv",
              "application/json",
              "application/pdf",
            ],
            maxBytes: 5242880,
            maxChars: 200000,
            maxRedirects: 3,
            timeoutMs: 10000,
            pdf: {
              maxPages: 4,
              maxPixels: 4000000,
              minTextChars: 200,
            },
          },
          images: {
            allowUrl: true,
            urlAllowlist: ["images.example.com"],
            allowedMimes: [
              "image/jpeg",
              "image/png",
              "image/gif",
              "image/webp",
              "image/heic",
              "image/heif",
            ],
            maxBytes: 10485760,
            maxRedirects: 3,
            timeoutMs: 10000,
          },
        },
      },
    },
  },
}
```

省略時的預設值：

- `maxBodyBytes`：20MB
- `maxUrlParts`：8
- `files.maxBytes`：5MB
- `files.maxChars`：200k
- `files.maxRedirects`：3
- `files.timeoutMs`：10s
- `files.pdf.maxPages`：4
- `files.pdf.maxPixels`：4,000,000
- `files.pdf.minTextChars`：200
- `images.maxBytes`：10MB
- `images.maxRedirects`：3
- `images.timeoutMs`：10s
- HEIC/HEIF `input_image` 來源被接受並在傳遞給供應商前正規化為 JPEG。

安全說明：

- URL allowlists 在取得前和重新導向跳轉時強制執行。
- 將 hostname 加入 allowlist 不會繞過私有/內部 IP 封鎖。
- 對於暴露到網路的 gateway，除了應用層面的防護外，還需套用網路出口控制。
  請參閱 [Security](/zh-Hant/gateway/security)。

## Streaming（SSE）

設定 `stream: true` 以接收 Server-Sent Events（SSE）：

- `Content-Type: text/event-stream`
- 每個事件行為 `event: <type>` 和 `data: <json>`
- 串流以 `data: [DONE]` 結束

目前發出的事件類型：

- `response.created`
- `response.in_progress`
- `response.output_item.added`
- `response.content_part.added`
- `response.output_text.delta`
- `response.output_text.done`
- `response.content_part.done`
- `response.output_item.done`
- `response.completed`
- `response.failed`（發生錯誤時）

## 使用量

當底層供應商回報 token 數量時，`usage` 會被填充。

## 錯誤

錯誤使用如下 JSON 物件：

```json
{ "error": { "message": "...", "type": "invalid_request_error" } }
```

常見情況：

- `401` 遺失/無效的認證
- `400` 無效的請求本體
- `405` 錯誤的方法

## 範例

非串流：

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

串流：

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
