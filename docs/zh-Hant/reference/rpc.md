---
title: "Rpc(RPC 適配器)"
summary: "外部 CLIs（signal-cli、imsg）和 Gateway 模式的 RPC 適配器"
read_when:
  - 新增或變更外部 CLI 整合
  - 除錯 RPC 適配器（signal-cli、imsg）
---
# RPC 適配器

OpenClaw 透過 JSON-RPC 整合外部 CLIs。目前使用兩種模式。

## 模式 A：HTTP Daemon (signal-cli)
- `signal-cli` 以 Daemon 執行，透過 HTTP 使用 JSON-RPC。
- Event Stream 是 SSE（`/api/v1/events`）。
- Health Probe：`/api/v1/check`。
- 當 `channels.signal.autoStart=true` 時，OpenClaw 管理 Lifecycle。

請見 [Signal](/channels/signal) 了解設定和端點。

## 模式 B：stdio Child Process (imsg)
- OpenClaw 將 `imsg rpc` 作為 Child Process 生成。
- JSON-RPC 透過 stdin/stdout 以行分隔（每行一個 JSON 物件）。
- 無 TCP Port，無需 Daemon。

使用的核心方法：
- `watch.subscribe` → 通知（`method: "message"`）
- `watch.unsubscribe`
- `send`
- `chats.list`（Probe/Diagnostics）

請見 [iMessage](/channels/imessage) 了解設定和 Addressing（建議使用 `chat_id`）。

## 適配器指南
- Gateway 管理 Process（Start/Stop 與 Provider Lifecycle 綁定）。
- 保持 RPC Clients 有彈性：Timeouts、Exit 時重新啟動。
- 優先使用穩定 IDs（例如 `chat_id`）而非 Display Strings。
