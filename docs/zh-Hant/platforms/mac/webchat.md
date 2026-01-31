---
title: "webchat(macOS WebChat)"
summary: "macOS 應用程式如何嵌入 Gateway WebChat 以及如何進行除錯"
read_when:
  - 除錯 mac WebChat 視圖或 loopback 通訊埠時
---

# WebChat (macOS 應用程式)

macOS 選單列應用程式將 WebChat UI 嵌入為原生的 SwiftUI 視圖。它連接至 Gateway，並預設使用所選 Agent 的 **Main Session**（附帶切換其他工作階段的選擇器）。

- **Local 模式**: 直接連接至本地 Gateway WebSocket。
- **Remote 模式**: 透過 SSH 轉發 Gateway 控制通訊埠，並使用該通道作為資料平面。

## 啟動與除錯

- 手動: 龍蝦選單 (Lobster menu) → “Open Chat”。
- 測試用自動開啟:
  ```bash
  dist/OpenClaw.app/Contents/MacOS/OpenClaw --webchat
  ```
- 日誌: `./scripts/clawlog.sh` (子系統 `bot.molt`,  類別 `WebChatSwiftUI`)。

## 接線方式

- 資料平面: Gateway WS 方法 `chat.history`, `chat.send`, `chat.abort`, `chat.inject` 以及事件 `chat`, `agent`, `presence`, `tick`, `health`。
- 工作階段: 預設為主要工作階段 (`main`，或當範圍為全域時為 `global`)。UI 可以在工作階段間切換。
- Onboarding 使用專用工作階段以將首次執行設定分開。

## 安全性介面

- Remote 模式僅透過 SSH 轉發 Gateway WebSocket 控制通訊埠。

## 已知限制

- 此 UI 針對聊天會話進行了最佳化（非完整的瀏覽器沙盒）。
