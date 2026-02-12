---
summary: "外部 CLI 的 RPC 適配器（signal-cli、舊版 imsg）和 Gateway 模式"
read_when:
  - 新增或更改外部 CLI 整合
  - 調試 RPC 適配器（signal-cli、imsg）
title: "RPC Adapters（RPC 適配器）"
---

# RPC 適配器

OpenClaw 透過 JSON-RPC 整合外部 CLI。今天使用了兩種模式。

## 模式 A：HTTP 守護程式（signal-cli）

- `signal-cli` 作為 JSON-RPC over HTTP 守護程式執行。
- 事件流是 SSE（`/api/v1/events`）。
- 健康探針：`/api/v1/check`。
- 當 `channels.signal.autoStart=true` 時，OpenClaw 擁有生命週期。

詳見[Signal](/zh-Hant/channels/signal)了解設定和端點。

## 模式 B：stdio 子進程（舊版：imsg）

> **注意：** 對於新 iMessage 設定，請改用 [BlueBubbles](/zh-Hant/channels/bluebubbles)。

- OpenClaw 生成 `imsg rpc` 作為子進程（舊版 iMessage 整合）。
- JSON-RPC 是透過 stdin/stdout 的行分隔符（每行一個 JSON 物件）。
- 無 TCP 連接埠，無需守護程式。

使用的核心方法：

- `watch.subscribe` → 通知（`method: "message"`）
- `watch.unsubscribe`
- `send`
- `chats.list`（探針/診斷）

詳見[iMessage](/zh-Hant/channels/imessage)了解舊版設定和尋址（偏好 `chat_id`）。

## 適配器指南

- Gateway 擁有進程（啟動/停止與提供者生命週期繫結）。
- 保持 RPC 用戶端具有彈性：逾時、在退出時重新啟動。
- 偏好穩定的 ID（例如 `chat_id`）而非顯示字串。
