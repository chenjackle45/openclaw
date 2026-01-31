---
title: "openai-http-api(OpenAI Chat Completions (HTTP))"
summary: "從 Gateway 暴露 OpenAI 相容的 /v1/chat/completions HTTP Endpoint"
read_when:
  - 整合預期 OpenAI Chat Completions 格式的工具時
---

# OpenAI Chat Completions (HTTP)

OpenClaw 的 Gateway 可以服務一個小型、OpenAI 相容的 Chat Completions Endpoint。

此 Endpoint **預設為停用**。請先在 Config 中啟用它。

- `POST /v1/chat/completions`
- 與 Gateway 相同的 Port (WS + HTTP multiplex): `http://<gateway-host>:<port>/v1/chat/completions`

在底層，請求會作為正常的 Gateway Agent Run 執行 (與 `openclaw agent` 相同的 Codepath)，因此 Routing/Permissions/Config 皆符合您的 Gateway 設定。

## 認證 (Authentication)

使用 Gateway Auth 設定。傳送 Bearer Token：

- `Authorization: Bearer <token>`

註記：
- 當 `gateway.auth.mode="token"`，使用 `gateway.auth.token` (或 `OPENCLAW_GATEWAY_TOKEN`)。
- 當 `gateway.auth.mode="password"`，使用 `gateway.auth.password` (或 `OPENCLAW_GATEWAY_PASSWORD`)。

## 選擇 Agent

無需自訂 Headers：將 Agent ID 編碼在 OpenAI `model` 欄位中：

- `model: "openclaw:<agentId>"` (範例: `"openclaw:main"`, `"openclaw:beta"`)
- `model: "agent:<agentId>"` (別名)

或透過 Header 指定 OpenClaw Agent：

- `x-openclaw-agent-id: <agentId>` (預設: `main`)

進階：
- `x-openclaw-session-key: <sessionKey>` 以完全控制 Session Routing。

## 啟用 Endpoint

將 `gateway.http.endpoints.chatCompletions.enabled` 設定為 `true`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        chatCompletions: { enabled: true }
      }
    }
  }
}
```

## 停用 Endpoint

將 `gateway.http.endpoints.chatCompletions.enabled` 設定為 `false`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        chatCompletions: { enabled: false }
      }
    }
  }
}
```

## Session 行為

預設情況下，此 Endpoint 是 **Stateless per request** (每次呼叫產生新的 Session Key)。

若請求包含 OpenAI `user` 字串，Gateway 會從中推導出穩定的 Session Key，因此重複呼叫可以共用 Agent Session。

## Streaming (SSE)

設定 `stream: true` 以接收 Server-Sent Events (SSE)：

- `Content-Type: text/event-stream`
- 每個 Event Line 為 `data: <json>`
- Stream 結束於 `data: [DONE]`

## 範例

Non-streaming:
```bash
curl -sS http://127.0.0.1:18789/v1/chat/completions \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'x-openclaw-agent-id: main' \
  -d '{
    "model": "openclaw",
    "messages": [{"role":"user","content":"hi"}]
  }'
```

Streaming:
```bash
curl -N http://127.0.0.1:18789/v1/chat/completions \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'x-openclaw-agent-id: main' \
  -d '{
    "model": "openclaw",
    "stream": true,
    "messages": [{"role":"user","content":"hi"}]
  }'
```
