---
summary: "OpenClaw 可以連接的通訊平台"
read_when:
  - 你想為 OpenClaw 選擇聊天頻道
  - 你需要快速了解支援的通訊平台
title: "Chat Channels（聊天頻道）"
---

# 聊天頻道

OpenClaw 可以在你已使用的任何聊天應用中與你交談。每個頻道都透過 Gateway 連接。
文字在所有頻道上都受支援，媒體和反應因頻道而異。

## 支援的頻道

- [BlueBubbles](/zh-Hant/channels/bluebubbles) — **iMessage 推薦**；使用 BlueBubbles macOS 伺服器 REST API，支援完整功能（編輯、撤銷、效果、反應、群組管理 — 編輯功能在 macOS 26 Tahoe 上目前損壞）。
- [Discord](/zh-Hant/channels/discord) — Discord Bot API + Gateway；支援伺服器、頻道和私訊。
- [Feishu](/zh-Hant/channels/feishu) — 飛書／Lark bot 透過 WebSocket（外掛程式，需單獨安裝）。
- [Google Chat](/zh-Hant/channels/googlechat) — Google Chat API 應用透過 HTTP webhook。
- [iMessage（舊版）](/zh-Hant/channels/imessage) — 舊版 macOS 整合透過 imsg CLI（已棄用，新設置使用 BlueBubbles）。
- [IRC](/zh-Hant/channels/irc) — 經典 IRC 伺服器；頻道 + 私訊，支援配對／允許清單控制。
- [LINE](/zh-Hant/channels/line) — LINE Messaging API bot（外掛程式，需單獨安裝）。
- [Matrix](/zh-Hant/channels/matrix) — Matrix 協定（外掛程式，需單獨安裝）。
- [Mattermost](/zh-Hant/channels/mattermost) — Bot API + WebSocket；頻道、群組、私訊（外掛程式，需單獨安裝）。
- [Microsoft Teams](/zh-Hant/channels/msteams) — Bot Framework；企業支援（外掛程式，需單獨安裝）。
- [Nextcloud Talk](/zh-Hant/channels/nextcloud-talk) — 透過 Nextcloud Talk 進行自架聊天（外掛程式，需單獨安裝）。
- [Nostr](/zh-Hant/channels/nostr) — 透過 NIP-04 進行去中心化私訊（外掛程式，需單獨安裝）。
- [Signal](/zh-Hant/channels/signal) — signal-cli；隱私優先。
- [Slack](/zh-Hant/channels/slack) — Bolt SDK；工作區應用。
- [Synology Chat](/zh-Hant/channels/synology-chat) — 透過傳出 + 傳入 webhook 的 Synology NAS Chat（外掛程式，需單獨安裝）。
- [Telegram](/zh-Hant/channels/telegram) — 透過 grammY 的 Bot API；支援群組。
- [Tlon](/zh-Hant/channels/tlon) — 基於 Urbit 的即時通訊（外掛程式，需單獨安裝）。
- [Twitch](/zh-Hant/channels/twitch) — 透過 IRC 連接的 Twitch 聊天（外掛程式，需單獨安裝）。
- [Voice Call](/zh-Hant/plugins/voice-call) — 透過 Plivo 或 Twilio 的電話服務（外掛程式，需單獨安裝）。
- [WebChat](/zh-Hant/web/webchat) — 透過 WebSocket 的 Gateway WebChat UI。
- [WhatsApp](/zh-Hant/channels/whatsapp) — 最受歡迎；使用 Baileys，需要 QR 配對。
- [Zalo](/zh-Hant/channels/zalo) — Zalo Bot API；越南流行通訊工具（外掛程式，需單獨安裝）。
- [Zalo Personal](/zh-Hant/channels/zalouser) — 透過 QR 登入的 Zalo 個人帳戶（外掛程式，需單獨安裝）。

## 備註

- 多個頻道可同時運行；配置多個後 OpenClaw 將按聊天進行路由。
- 最快的設置通常是 **Telegram**（簡單的 bot token）。WhatsApp 需要 QR 配對，並在磁碟上儲存更多狀態。
- 群組行為因頻道而異；參見[群組](/zh-Hant/channels/groups)。
- DM 配對和允許清單會被強制執行以確保安全；參見[安全](/zh-Hant/gateway/security)。
- 疑難排解：[頻道疑難排解](/zh-Hant/channels/troubleshooting)。
- 模型提供者單獨記錄；參見[模型提供者](/zh-Hant/providers/models)。
