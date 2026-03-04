---
summary: “macOS app 如何嵌入 Gateway WebChat 以及如何除錯”
read_when:
  - 除錯 macOS WebChat 檢視或迴路埠
title: "WebChat"
---

# WebChat (macOS app)

macOS 選單欄應用程式將 WebChat UI 嵌入為原生 SwiftUI 檢視。它連線到 Gateway 並預設為所選 Agent 的**主要工作階段**（使用工作階段切換器切換至其他工作階段）。

- **本地模式**：直接連線到本地 Gateway WebSocket。
- **遠端模式**：通過 SSH 轉發 Gateway 控制埠並使用該隧道作為資料平面。

## 啟動與除錯

- 手動：Lobster 選單 → 「開啟聊天」。
- 自動開啟以進行測試：

  ```bash
  dist/OpenClaw.app/Contents/MacOS/OpenClaw --webchat
  ```

- 日誌：`./scripts/clawlog.sh`（子系統 `ai.openclaw`，類別 `WebChatSwiftUI`）。

## 如何連線

- 資料平面：Gateway WS 方法 `chat.history`、`chat.send`、`chat.abort`、`chat.inject` 和事件 `chat`、`agent`、`presence`、`tick`、`health`。
- 工作階段：預設為主要工作階段（`main`，或當範圍是全域時為 `global`）。UI 可以在工作階段之間切換。
- 上線使用專用工作階段以將首次執行設置分離。

## 安全表面

- 遠端模式只通過 SSH 轉發 Gateway WebSocket 控制埠。

## 已知限制

- UI 針對聊天工作階段進行最佳化（不是完整的瀏覽器沙箱）。
