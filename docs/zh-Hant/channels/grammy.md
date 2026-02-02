---
summary: "Telegram Bot API integration via grammY with setup notes"
read_when:
  - Working on Telegram or grammY pathways
title: grammY
---

# grammY 整合 (Telegram Bot API)

# 為什麼選擇 grammY

- TypeScript 優先的 Bot API 用戶端，內建長輪詢 + Webhook 輔助工具、中間件、錯誤處理和速率限制器。
- 比手動 `fetch` + `FormData` 更簡潔的媒體輔助工具；支援所有 Bot API 方法。
- 可擴展：透過自定義 fetch 支援代理、會話中間件（可選）、型別安全的上下文。

# 我們發布的內容

- **單一用戶端路徑：** 已移除基於 fetch 的實作；grammY 現在是唯一的 Telegram 客戶端（發送 + Gateway），預設啟用 grammY 節流器。
- **Gateway：** `monitorTelegramProvider` 建立 grammY `Bot`，連接提及/允許清單閘門、透過 `getFile`/`download` 下載媒體，並透過 `sendMessage/sendPhoto/sendVideo/sendAudio/sendDocument` 交付回覆。支援長輪詢或透過 `webhookCallback` 的 Webhook。
- **代理：** 可選的 `channels.telegram.proxy` 透過 grammY 的 `client.baseFetch` 使用 `undici.ProxyAgent`。
- **Webhook 支援：** `webhook-set.ts` 包裝 `setWebhook/deleteWebhook`；`webhook.ts` 主機託管具有健康檢查 + 優雅關閉的回調。當 `channels.telegram.webhookUrl` + `channels.telegram.webhookSecret` 被設定時，Gateway 啟用 Webhook 模式（否則長輪詢）。
- **會話：** 直接聊天折疊成代理主會話（`agent:<agentId>:<mainKey>`）；群組使用 `agent:<agentId>:telegram:group:<chatId>`；回覆路由回相同頻道。
- **設定選項：** `channels.telegram.botToken`、`channels.telegram.dmPolicy`、`channels.telegram.groups`（允許清單 + 提及預設值）、`channels.telegram.allowFrom`、`channels.telegram.groupAllowFrom`、`channels.telegram.groupPolicy`、`channels.telegram.mediaMaxMb`、`channels.telegram.linkPreview`、`channels.telegram.proxy`、`channels.telegram.webhookSecret`、`channels.telegram.webhookUrl`。
- **草稿串流：** 可選的 `channels.telegram.streamMode` 在私密主題聊天中使用 `sendMessageDraft`（Bot API 9.3+）。這與頻道區塊串流分開。
- **測試：** grammY mocks 涵蓋 DM + 群組提及閘門和出站發送；更多媒體/Webhook 夾具仍然歡迎。

開放問題

- 如果我們遇到 Bot API 429，選用 grammY 外掛（節流器）。
- 新增更多結構化媒體測試（貼圖、語音備忘）。
- 使 Webhook 監聽連接埠可設定（目前除非透過 Gateway 連接，否則固定為 8787）。
