---
title: "Line(LINE 插件)"
summary: "LINE Messaging API 插件設定、配置與使用指南"
read_when:
  - 您想將 OpenClaw 連接至 LINE 時
  - 您需要設定 LINE Webhook 與認證資訊時
---
# LINE (插件)

OpenClaw 透過 LINE Messaging API 與 LINE 連接。此插件在 Gateway 上作為 Webhook 接收器運行，並使用您的頻道存取令牌 (Channel Access Token) 與頻道密鑰 (Channel Secret) 進行驗證。

狀態：透過插件支援。支援私訊、群組對話、媒體、位置、Flex 訊息、範本訊息與快速回覆。目前不支援表情符號反應與執行緒。

## 安裝插件
```bash
openclaw plugins install @openclaw/line
```

## 設定流程
1. 建立 LINE Developers 帳號並進入控制台。
2. 建立一個 **Messaging API** 頻道。
3. 複製 **Channel access token** 與 **Channel secret**。
4. 在 Messaging API 設定中啟用 **Use webhook**。
5. 將 Webhook URL 設定為您的 Gateway 端點（必須為 HTTPS）：
   `https://您的主機網址/line/webhook`

## 基本設定
```json5
{
  channels: {
    line: {
      enabled: true,
      channelAccessToken: "您的存取令牌",
      channelSecret: "您的頻道密鑰",
      dmPolicy: "pairing"
    }
  }
}
```

## 存取控制
私訊預設使用配對模式。未知發送者會收到配對碼，其訊息在核准前會被忽略。
- 核准指令：`openclaw pairing approve line <代碼>`
- 允許清單：可在 `channels.line.allowFrom` 中設定允許的 LINE 使用者 ID。

## 訊息行為
- 文字會在超過 5000 字時分塊。
- 串流回應會被緩衝處理；LINE 會在代理運算時顯示「讀取中」動畫。

## 頻道數據（富文本訊息）
您可以使用 `channelData.line` 來發送快速回覆、位置、Flex 訊息或範本訊息。
```json5
{
  text: "這是您的圖卡",
  channelData: {
    line: {
      flexMessage: {
        altText: "狀態圖卡",
        contents: { /* Flex 負載 */ }
      }
    }
  }
}
```

## 故障排除
- **Webhook 驗證失敗**：請確保網址為 HTTPS 且 `channelSecret` 與控制台一致。
- **無法收到事件**：確認 Webhook 路徑與 `channels.line.webhookPath` 是否匹配。
