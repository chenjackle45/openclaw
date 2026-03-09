---
summary: "從 Gateway 暴露 OpenAI 相容的 /v1/chat/completions HTTP endpoint"
read_when:
  - 整合預期 OpenAI Chat Completions 格式的工具時
title: "OpenAI Chat Completions（OpenAI Chat Completions API）"
---

# OpenAI Chat Completions（HTTP）

OpenClaw 的 Gateway 可以提供小型的 OpenAI 相容 Chat Completions endpoint。

此 endpoint **預設停用**。請先在設定中啟用。

- `POST /v1/chat/completions`
- 與 Gateway 使用相同埠（WS + HTTP 多工）：`http://<gateway-host>:<port>/v1/chat/completions`

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

不需要自訂 header：在 OpenAI `model` 欄位中編碼 agent id：

- `model: "openclaw:<agentId>"`（範例：`"openclaw:main"`、`"openclaw:beta"`）
- `model: "agent:<agentId>"`（別名）

或透過 header 指定特定的 OpenClaw agent：

- `x-openclaw-agent-id: <agentId>`（預設：`main`）

進階：

- `x-openclaw-session-key: <sessionKey>` 完全控制 session 路由。

## 啟用 endpoint

將 `gateway.http.endpoints.chatCompletions.enabled` 設為 `true`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        chatCompletions: { enabled: true },
      },
    },
  },
}
```

## 停用 endpoint

將 `gateway.http.endpoints.chatCompletions.enabled` 設為 `false`：

```json5
{
  gateway: {
    http: {
      endpoints: {
        chatCompletions: { enabled: false },
      },
    },
  },
}
```

## Session 行為

預設情況下，endpoint **每個請求無狀態**（每次呼叫生成新的 session 鍵）。

若請求包含 OpenAI `user` 字串，Gateway 會從中衍生穩定的 session 鍵，讓重複呼叫可以共享 agent session。

## Streaming（SSE）

設定 `stream: true` 以接收 Server-Sent Events（SSE）：

- `Content-Type: text/event-stream`
- 每個事件行為 `data: <json>`
- 串流以 `data: [DONE]` 結束

## 範例

非串流：

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

串流：

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
