---
title: "Features（功能）"
summary: "OpenClaw 在頻道、路由、媒體和使用者體驗方面的功能"
read_when:
  - 您想了解 OpenClaw 支援的全部功能
---

## 亮點

<Columns>
  <Card title="頻道" icon="message-square">
    WhatsApp、Telegram、Discord 和 iMessage，透過單一 Gateway。
  </Card>
  <Card title="外掛程式" icon="plug">
    使用擴展功能新增 Mattermost 和更多。
  </Card>
  <Card title="路由" icon="route">
    具有隔離工作階段的多 agent 路由。
  </Card>
  <Card title="媒體" icon="image">
    圖片、音訊和文件的輸入輸出。
  </Card>
  <Card title="應用程式與 UI" icon="monitor">
    網頁控制 UI 和 macOS 配套應用程式。
  </Card>
  <Card title="行動節點" icon="smartphone">
    iOS 和 Android 節點，具有配對、語音/聊天和豐富的裝置指令。
  </Card>
</Columns>

## 完整清單

- 透過 WhatsApp Web（Baileys）的 WhatsApp 整合
- Telegram bot 支援（grammY）
- Discord bot 支援（channels.discord.js）
- Mattermost bot 支援（外掛程式）
- 透過本地 imsg CLI 的 iMessage 整合（macOS）
- 在 RPC 模式下帶有工具串流的 Pi 的 Agent 橋接器
- 長回覆的串流和分塊
- 每個工作區或發送者隔離工作階段的多 agent 路由
- 透過 OAuth 的 Anthropic 和 OpenAI 訂閱驗證
- 工作階段：直接聊天合併到共享的 `main`；群組隔離
- 基於 mention 啟動的群組聊天支援
- 圖片、音訊和文件的媒體支援
- 選用語音筆記轉錄 hook
- WebChat 和 macOS 選單列應用程式
- iOS 節點，具有配對、Canvas、相機、螢幕錄製、位置和語音功能
- Android 節點，具有配對、Connect 分頁、聊天工作階段、語音分頁、Canvas/相機，以及裝置、通知、聯絡人/行事曆、動作、照片和 SMS 指令

<Note>
舊版 Claude、Codex、Gemini 和 Opencode 路徑已移除。Pi 是唯一的
程式碼 agent 路徑。
</Note>
