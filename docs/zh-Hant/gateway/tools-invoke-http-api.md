---
title: "tools-invoke-http-api(Tools Invoke (HTTP))"
summary: "直接透過 Gateway HTTP Endpoint 呼叫單一工具"
read_when:
  - 無需運行完整 Agent Turn 即可呼叫工具時
  - 建置需要 Tool Policy 強制執行的自動化時
---

# Tools Invoke (HTTP)

OpenClaw 的 Gateway 暴露一個簡單的 HTTP Endpoint 用於直接呼叫單一工具。它永遠啟用，但受 Gateway Auth 與 Tool Policy 管控。

- `POST /tools/invoke`
- 與 Gateway 相同的 Port (WS + HTTP multiplex): `http://<gateway-host>:<port>/tools/invoke`

預設最大 Payload Size 為 2 MB。

## 認證 (Authentication)

使用 Gateway Auth 設定。傳送 Bearer Token：

- `Authorization: Bearer <token>`

註記：
- 當 `gateway.auth.mode="token"`，使用 `gateway.auth.token` (或 `OPENCLAW_GATEWAY_TOKEN`)。
- 當 `gateway.auth.mode="password"`，使用 `gateway.auth.password` (或 `OPENCLAW_GATEWAY_PASSWORD`)。

## Request Body

```json
{
  "tool": "sessions_list",
  "action": "json",
  "args": {},
  "sessionKey": "main",
  "dryRun": false
}
```

欄位:
- `tool` (string, required): 要呼叫的工具名稱。
- `action` (string, optional): 若 Tool Schema 支援 `action` 且 Args Payload 省略它，則映射至 Args。
- `args` (object, optional): 工具特定參數。
- `sessionKey` (string, optional): 目標 Session Key。若省略或為 `"main"`，Gateway 使用設定的 Main Session Key (尊重 `session.mainKey` 與預設 Agent，或在 Global Scope 下為 `global`)。
- `dryRun` (boolean, optional): 保留供未來使用；目前忽略。

## Policy + Routing 行為

工具可用性透過與 Gateway Agents 相同的 Policy Chain 進行過濾：
- `tools.profile` / `tools.byProvider.profile`
- `tools.allow` / `tools.byProvider.allow`
- `agents.<id>.tools.allow` / `agents.<id>.tools.byProvider.allow`
- Group Policies (若 Session Key 映射至 Group 或 Channel)
- Subagent Policy (當使用 Subagent Session Key 呼叫時)

若工具未被 Policy 允許，Endpoint 回傳 **404**。

為了協助 Group Policies 解析 Context，您可以選擇性地設定：
- `x-openclaw-message-channel: <channel>` (例如: `slack`, `telegram`)
- `x-openclaw-account-id: <accountId>` (當存在多個 Accounts 時)

## Responses

- `200` → `{ ok: true, result }`
- `400` → `{ ok: false, error: { type, message } }` (Invalid Request 或 Tool Error)
- `401` → Unauthorized
- `404` → Tool not available (Not found 或 Not allowlisted)
- `405` → Method Not Allowed

## 範例

```bash
curl -sS http://127.0.0.1:18789/tools/invoke \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "tool": "sessions_list",
    "action": "json",
    "args": {}
  }'
```
