---
title: "Msteams(Microsoft Teams 插件)"
summary: "Microsoft Teams 機器人支援狀態、功能與設定"
read_when:
  - 處理 MS Teams 頻道功能時
---
# Microsoft Teams (插件)

> 「入此門者，放棄一切希望。」(Abandon all hope, ye who enter here.)

更新日期：2026-01-21

狀態：支援文字與私訊附件；頻道/群組檔案發送需要 `sharePointSiteId` 與 Graph 權限。投票功能透過 Adaptive Cards 發動。

## 安裝插件
此功能已移出核心包，需單獨安裝：
```bash
openclaw plugins install @openclaw/msteams
```

## 快速設定（初學者）
1. 安裝 MS Teams 插件。
2. 建立一個 **Azure Bot**（取得 App ID、用戶端密鑰與租戶 ID）。
3. 設定 OpenClaw 憑證。
4. 暴露 `/api/messages`（預設連接埠 3978）至公開網址或隧道（如 ngrok 或 Tailscale Funnel）。
5. 安裝 Teams 應用程式包並啟動 Gateway。

## 存取控制 (DMs + Groups)
- **私訊 (DM)**：預設使用配對模式，核准後方可對話。
- **群組/頻道**：預設為 `allowlist` 模式，且需要 @提及機器人（除非另行設定）。
- **允許清單**：可在 `channels.msteams.teams` 中列出允許的團隊與頻道 ID。

## 運作原理
1. 建立 Azure Bot 資源。
2. 封裝一個 Teams 應用程式清單 (manifest.json)，包含圖示與權限要求。
3. 將 App 上載至 Teams 團隊或個人範圍。
4. Gateway 監聽 Bot Framework 的 Webhook 流量。

## Azure Bot 設定要點
- 建立資源時選擇 **Single Tenant (單租戶)**。
- 在 **Configuration** 中設定 **Messaging endpoint**。
- 在 **Channels** 中啟用 **Microsoft Teams** 頻道。

## RSC 權限與 Graph API
- **RSC (Resource-Specific Consent)**：僅需 App 清單設定，支援即時讀寫訊息文字。
- **Microsoft Graph API**：需要管理員核准權限，支援下載頻道內的圖片/附件、讀取歷史訊息等進階功能。若需要處理頻道內的媒體檔案，**必須**啟用 Graph 權限。

## 回覆樣式：執行緒 vs 貼文
Teams 支援兩種 UI 樣式：
- **Posts (傳統)**：訊息以圖卡顯示，下方有回覆。建議 `replyStyle: "thread"`。
- **Threads (類 Slack)**：訊息線性流動。建議 `replyStyle: "top-level"`。

## 附件與檔案發送
- **私訊**：直接支援檔案傳送。
- **群組/頻道**：機器人需將檔案上傳至 **SharePoint** 並分享連結。這需要設定 `sharePointSiteId` 並具備 Graph 權限。

## 投票與 Adaptive Cards
OpenClaw 使用 **Adaptive Cards** 發送投票與富文本訊息。
您可以透過 `message` 工具發送自定義的 Adaptive Card JSON 負載。

## 故障排除
- **頻道內圖片不顯示**：通常是缺少 Graph 權限或未核准管理員同意。
- **機器人不回覆**：確認是否已 @提及機器人，或檢查 `requireMention` 設定。
- **Webhook 逾時**：Teams 對 Webhook 回應時間有嚴格限制（約 10-15 秒）。
