---
title: "Grammy(grammY Telegram Bot API)"
summary: "透過 grammY 的 Telegram Bot API 整合與設定說明"
read_when:
  - 處理 Telegram 或 grammY 相關開發路徑時
---
# grammY 整合 (Telegram Bot API)

## 為什麼選擇 grammY
- **TypeScript 優先**：內建長輪詢 (Long-poll) 與 Webhook 輔助工具、中間件、錯誤處理與速率限制。
- **媒體處理更簡潔**：支援所有 Bot API 方法，比手寫 `fetch` + `FormData` 更穩定。
- **擴充性強**：支援自定義代理 (Proxy) 與型別安全的上下文 (Context)。

## 實作細節
- **單一用戶端路徑**：已移除基於 `fetch` 的舊版實作，grammY 現在是唯一的 Telegram 客戶端。
- **Gateway**：建立 grammY `Bot` 實例，整合標註 (Mention) 與允許清單過濾，透過 `getFile` 下載媒體並執行回覆發送。
- **代理 (Proxy)**：可選的 `channels.telegram.proxy` 支援。
- **Webhook 支援**：當 `channels.telegram.webhookUrl` 已設定時，Gateway 將切換至 Webhook 模式。
- **草稿串流 (Draft streaming)**：支援 Bot API 9.3+ 的 `sendMessageDraft`（僅限私密主題聊天）。

## 設定項目
包含 `botToken`, `dmPolicy`, `groups` 允許清單, `allowFrom`, `webhookUrl` 以及代理伺服器相關設定。

## 待解問題與規劃
- 若遇到 Bot API 429 錯誤，可能導入更多 grammY 插件。
- 增加更多結構化媒體測試（貼圖、語音訊息）。
- 使 Webhook 監聽連接埠可自定義（目前固定為 8787）。
