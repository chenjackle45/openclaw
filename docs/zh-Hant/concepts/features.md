---
title: "Features（功能）"
summary: "OpenClaw 在頻道、路由、媒體和使用者體驗方面的功能"
read_when:
  - 您想了解 OpenClaw 支援的全部功能
---

## 亮點

<Columns>
  <Card title="頻道" icon="message-square">
    WhatsApp、Telegram、Discord 和 iMessage，單一 Gateway 統一管理。
  </Card>
  <Card title="外掛" icon="plug">
    透過擴充功能新增 Mattermost 及其他功能。
  </Card>
  <Card title="路由" icon="route">
    多代理路由，隔離的會話。
  </Card>
  <Card title="媒體" icon="image">
    進出的圖片、音訊和文件。
  </Card>
  <Card title="應用程式和 UI" icon="monitor">
    網頁控制 UI 和 macOS 伴侶應用程式。
  </Card>
  <Card title="行動節點" icon="smartphone">
    iOS 和 Android 節點，支援 Canvas。
  </Card>
</Columns>

## 完整清單

- 透過 WhatsApp Web (Baileys) 的 WhatsApp 整合
- Telegram 機器人支援 (grammY)
- Discord 機器人支援 (channels.discord.js)
- Mattermost 機器人支援（外掛）
- 透過本機 imsg CLI (macOS) 的 iMessage 整合
- 具有工具串流功能的 Pi RPC 模式代理橋接
- 長回覆的串流和分塊
- 多代理路由，用於每個工作區或寄件者的隔離會話
- Anthropic 和 OpenAI 的訂閱式驗證 (OAuth)
- 會話：直接聊天會合併為共享的 `main`；群組會隔離
- 群組聊天支援，基於提及的啟用
- 圖片、音訊和文件的媒體支援
- 可選的語音筆記轉錄鉤子
- WebChat 和 macOS 功能表列應用程式
- iOS 節點，支援配對和 Canvas 介面
- Android 節點，支援配對、Canvas、聊天和相機

<Note>
已移除舊版 Claude、Codex、Gemini 和 Opencode 路徑。Pi 是唯一的程式設計代理路徑。
</Note>
