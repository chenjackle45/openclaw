---
title: "Architecture(架構)"
summary: "WebSocket Gateway 架構、元件和客戶端流程"
read_when:
  - 處理 Gateway 協議、客戶端或傳輸
---
# Gateway architecture（Gateway 架構）

最後更新：2026-01-22

## 概述

- 一個單一長壽命的 **Gateway** 擁有所有訊息介面（WhatsApp 透過 Baileys、Telegram 透過 grammY、Slack、Discord、Signal、iMessage、WebChat）。
- 控制平面客戶端（macOS 應用程式、CLI、Web UI、自動化）透過 **WebSocket** 連接到 Gateway，在設定的綁定主機上（預設 `127.0.0.1:18789`）。
- **節點**（macOS/iOS/Android/無頭）也透過 **WebSocket** 連接，但宣告 `role: node` 並帶有明確的 caps/commands。
- 每台主機一個 Gateway；它是唯一開啟 WhatsApp 會話的地方。
- **Canvas 主機**（預設 `18793`）提供代理可編輯的 HTML 和 A2UI。

## 元件和流程

### Gateway（守護程序）
- 維護供應商連線。
- 公開類型化的 WS API（請求、回應、伺服器推送事件）。
- 對照 JSON Schema 驗證入站幀。
- 發出事件如 `agent`、`chat`、`presence`、`health`、`heartbeat`、`cron`。

### 客戶端（mac app / CLI / web admin）
- 每個客戶端一個 WS 連線。
- 發送請求（`health`、`status`、`send`、`agent`、`system-presence`）。
- 訂閱事件（`tick`、`agent`、`presence`、`shutdown`）。

### 節點（macOS / iOS / Android / 無頭）
- 使用 `role: node` 連接到**同一個 WS 伺服器**。
- 在 `connect` 中提供設備身份；配對是**基於設備的**（角色 `node`），批准存在於設備配對儲存中。
- 公開命令如 `canvas.*`、`camera.*`、`screen.record`、`location.get`。

協議詳情：
- [Gateway 協議](/gateway/protocol)

### WebChat
- 使用 Gateway WS API 進行聊天歷史和發送的靜態 UI。
- 在遠端設定中，透過與其他客戶端相同的 SSH/Tailscale 隧道連接。

## 連線生命週期（單一客戶端）

```
Client                    Gateway
  |                          |
  |---- req:connect -------->|
  |<------ res (ok) ---------|   (或 res error + close)
  |   (payload=hello-ok 攜帶快照: presence + health)
  |                          |
  |<------ event:presence ---|
  |<------ event:tick -------|
  |                          |
  |------- req:agent ------->|
  |<------ res:agent --------|   (ack: {runId,status:"accepted"})
  |<------ event:agent ------|   (串流)
  |<------ res:agent --------|   (最終: {runId,status,summary})
  |                          |
```

## Wire 協議（摘要）

- 傳輸：WebSocket，帶有 JSON 負載的文字幀。
- 第一幀**必須**是 `connect`。
- 握手後：
  - 請求：`{type:"req", id, method, params}` → `{type:"res", id, ok, payload|error}`
  - 事件：`{type:"event", event, payload, seq?, stateVersion?}`
- 如果設定了 `OPENCLAW_GATEWAY_TOKEN`（或 `--token`），`connect.params.auth.token` 必須匹配，否則 socket 關閉。
- 冪等鍵對於有副作用的方法（`send`、`agent`）是必需的，以便安全重試；伺服器保留短壽命的去重快取。
- 節點必須在 `connect` 中包含 `role: "node"` 加上 caps/commands/permissions。

## 配對 + 本地信任

- 所有 WS 客戶端（操作員 + 節點）在 `connect` 時包含**設備身份**。
- 新設備 ID 需要配對批准；Gateway 為後續連接發出**設備令牌**。
- **本地**連接（loopback 或 Gateway 主機自己的 tailnet 地址）可以自動批准以保持同主機 UX 順暢。
- **非本地**連接必須簽署 `connect.challenge` nonce 並需要明確批准。
- Gateway 認證（`gateway.auth.*`）仍適用於**所有**連接，無論本地或遠端。

詳情：[Gateway 協議](/gateway/protocol)、[配對](/start/pairing)、[安全](/gateway/security)。

## 協議類型和程式碼生成

- TypeBox schemas 定義協議。
- JSON Schema 從這些 schemas 生成。
- Swift 模型從 JSON Schema 生成。

## 遠端存取

- 首選：Tailscale 或 VPN。
- 替代方案：SSH 隧道
  ```bash
  ssh -N -L 18789:127.0.0.1:18789 user@host
  ```
- 相同的握手 + 認證令牌適用於隧道。
- 在遠端設定中可以為 WS 啟用 TLS + 可選的 pinning。

## 操作快照

- 啟動：`openclaw gateway`（前台，日誌輸出到 stdout）。
- 健康：透過 WS 的 `health`（也包含在 `hello-ok` 中）。
- 監督：launchd/systemd 用於自動重啟。

## 不變量

- 恰好一個 Gateway 控制每台主機的單一 Baileys 會話。
- 握手是強制的；任何非 JSON 或非 connect 的第一幀都會硬性關閉。
- 事件不會重播；客戶端必須在間隙時刷新。
