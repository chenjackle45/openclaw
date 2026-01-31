---
title: "Mattermost(Mattermost 插件)"
summary: "Mattermost 機器人設定與 OpenClaw 配置"
read_when:
  - 設定 Mattermost 時
  - 偵錯 Mattermost 路由時
---
# Mattermost (插件)

狀態：透過插件（機器人令牌 + WebSocket 事件）支援。支援頻道 (Channels)、群組與私訊 (DMs)。Mattermost 是一個可自託管的團隊通訊平台。

## 安裝插件
此插件不隨核心程式綑綁，需單獨安裝：
```bash
openclaw plugins install @openclaw/matrix
```

## 快速設定
1. 安裝 Mattermost 插件。
2. 建立一個 Mattermost 機器人帳號並複製 **機器人令牌 (Bot Token)**。
3. 取得 Mattermost 的 **基礎網址 (Base URL)**（例如 `https://chat.example.com`）。
4. 設定 OpenClaw 並啟動 Gateway。

## 基本設定
```json5
{
  channels: {
    mattermost: {
      enabled: true,
      botToken: "mm-token",
      baseUrl: "https://chat.example.com",
      dmPolicy: "pairing"
    }
  }
}
```

## 對話模式 (Chat modes)
頻道行為由 `chatmode` 控制：
- `oncall`（預設）：僅在被 @提及時回應。
- `onmessage`：回應頻道內的所有訊息。
- `onchar`：當訊息以特定前綴（如 `>` 或 `!`）開始時回應。

## 存取控制
- **私訊**：預設使用配對模式。未知發送者會收到配對碼，需執行 `openclaw pairing approve mattermost <代碼>` 核准。
- **頻道**：預設使用允許清單模式。

## 出站目標 (Targets)
- `channel:<id>` 用於頻道。
- `user:<id>` 或 `@username` 用於私訊。

## 故障排除
- **頻道不回覆**：請確認機器人是否已加入該頻道。
- **認證錯誤**：檢查機器人令牌與基礎網址是否正確。
