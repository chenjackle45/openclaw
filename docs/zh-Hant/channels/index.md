---
title: "Index(頻道概覽)"
summary: "OpenClaw 可以連接的訊息平台"
read_when:
  - 您想要為 OpenClaw 選擇一個聊天頻道
  - 您需要快速了解支援的訊息平台
---
# Channels（聊天頻道）

OpenClaw 可以在您已經使用的任何聊天應用程式上與您對話。每個頻道都透過 Gateway 連接。
所有平台都支援文字；媒體和表情符號反應因頻道而異。

## 支援的頻道

- [WhatsApp](/channels/whatsapp) — 最受歡迎；使用 Baileys，需要 QR 配對。
- [Telegram](/channels/telegram) — 透過 grammY 的 Bot API；支援群組。
- [Discord](/channels/discord) — Discord Bot API + Gateway；支援伺服器、頻道和私訊。
- [Slack](/channels/slack) — Bolt SDK；工作區應用程式。
- [Google Chat](/channels/googlechat) — 透過 HTTP webhook 的 Google Chat API 應用程式。
- [Mattermost](/channels/mattermost) — Bot API + WebSocket；頻道、群組、私訊（插件，需單獨安裝）。
- [Signal](/channels/signal) — signal-cli；注重隱私。
- [BlueBubbles](/channels/bluebubbles) — **iMessage 推薦選擇**；使用 BlueBubbles macOS 伺服器 REST API，具備完整功能支援（編輯、取消傳送、效果、表情符號反應、群組管理 — 編輯功能在 macOS 26 Tahoe 上目前有問題）。
- [iMessage](/channels/imessage) — 僅限 macOS；透過 imsg 的原生整合（舊版，新設定建議使用 BlueBubbles）。
- [Microsoft Teams](/channels/msteams) — Bot Framework；企業支援（插件，需單獨安裝）。
- [LINE](/channels/line) — LINE Messaging API 機器人（插件，需單獨安裝）。
- [Nextcloud Talk](/channels/nextcloud-talk) — 透過 Nextcloud Talk 的自託管聊天（插件，需單獨安裝）。
- [Matrix](/channels/matrix) — Matrix 協議（插件，需單獨安裝）。
- [Nostr](/channels/nostr) — 透過 NIP-04 的去中心化私訊（插件，需單獨安裝）。
- [Tlon](/channels/tlon) — 基於 Urbit 的訊息應用（插件，需單獨安裝）。
- [Twitch](/channels/twitch) — 透過 IRC 連線的 Twitch 聊天（插件，需單獨安裝）。
- [Zalo](/channels/zalo) — Zalo Bot API；越南流行的訊息應用（插件，需單獨安裝）。
- [Zalo Personal](/channels/zalouser) — 透過 QR 登入的 Zalo 個人帳戶（插件，需單獨安裝）。
- [WebChat](/web/webchat) — 透過 WebSocket 的 Gateway WebChat UI。

## 備註

- 頻道可以同時運行；設定多個頻道後，OpenClaw 會按聊天路由。
- 最快的設定通常是 **Telegram**（簡單的機器人令牌）。WhatsApp 需要 QR 配對，並在磁碟上儲存更多狀態。
- 群組行為因頻道而異；請參閱 [群組](/concepts/groups)。
- 為了安全，會強制執行私訊配對和允許清單；請參閱 [安全性](/gateway/security)。
- Telegram 內部：[grammY 備註](/channels/grammy)。
- 疑難排解：[頻道疑難排解](/channels/troubleshooting)。
- 模型供應商另有文件記錄；請參閱 [模型供應商](/providers/models)。
