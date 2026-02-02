---
summary: "Mattermost bot setup and OpenClaw config"
read_when:
  - Setting up Mattermost
  - Debugging Mattermost routing
title: "Mattermost"
---

# Mattermost (plugin)

狀態：透過外掛支援（bot token + WebSocket 事件）。支援頻道、群組和 DM。Mattermost 是自可託管的團隊訊息平台；見官方網站 [mattermost.com](https://mattermost.com) 了解產品詳情和下載。

## 需要外掛

Mattermost 作為外掛提供，並未與核心安裝綑綁。

透過 CLI 安裝（npm registry）：

```bash
openclaw plugins install @openclaw/mattermost
```

本地簽出（從 git repo 執行時）：

```bash
openclaw plugins install ./extensions/mattermost
```

如果您在設定/入門期間選擇 Mattermost 並偵測到 git 簽出，OpenClaw 將自動提供本地安裝路徑。

詳情：[外掛](/plugin)

## 快速設定

1. 安裝 Mattermost 外掛。
2. 建立 Mattermost bot 帳戶並複製 **bot token**。
3. 複製 Mattermost **base URL**（例如 `https://chat.example.com`）。
4. 設定 OpenClaw 並啟動 Gateway。

最小設定：

```json5
{
  channels: {
    mattermost: {
      enabled: true,
      botToken: "mm-token",
      baseUrl: "https://chat.example.com",
      dmPolicy: "pairing",
    },
  },
}
```

## 環境變數（預設帳號）

如果您偏好環境變數，設定在 Gateway 主機上：

- `MATTERMOST_BOT_TOKEN=...`
- `MATTERMOST_URL=https://chat.example.com`

環境變數僅適用於**預設**帳號（`default`）。其他帳號必須使用設定值。

## 聊天模式

Mattermost 自動回應 DM。頻道行為由 `chatmode` 控制：

- `oncall`（預設）：僅在頻道中被 @提及時回應。
- `onmessage`：回應每條頻道訊息。
- `onchar`：當訊息以觸發前綴開始時回應。

設定範例：

```json5
{
  channels: {
    mattermost: {
      chatmode: "onchar",
      oncharPrefixes: [">", "!"],
    },
  },
}
```

注意：

- `onchar` 仍回應顯式 @提及。
- `channels.mattermost.requireMention` 被接受用於舊版設定，但偏好 `chatmode`。

## 存取控制 (DM)

- 預設：`channels.mattermost.dmPolicy = "pairing"`（未知發送者獲得配對碼）。
- 透過以下方式批准：
  - `openclaw pairing list mattermost`
  - `openclaw pairing approve mattermost <CODE>`
- 公開 DM：`channels.mattermost.dmPolicy="open"` 加上 `channels.mattermost.allowFrom=["*"]`。

## 頻道（群組）

- 預設：`channels.mattermost.groupPolicy = "allowlist"`（提及閘門）。
- 使用 `channels.mattermost.groupAllowFrom` 允許清單發送者（使用者 ID 或 `@username`）。
- 開放頻道：`channels.mattermost.groupPolicy="open"`（提及閘門）。

## 出站交付目標

使用這些目標格式搭配 `openclaw message send` 或 cron/webhook：

- `channel:<id>`：用於頻道
- `user:<id>`：用於 DM
- `@username`：用於 DM（透過 Mattermost API 解析）

裸 ID 被視為頻道。

## 多帳號

Mattermost 支援 `channels.mattermost.accounts` 下的多個帳號：

```json5
{
  channels: {
    mattermost: {
      accounts: {
        default: { name: "Primary", botToken: "mm-token", baseUrl: "https://chat.example.com" },
        alerts: { name: "Alerts", botToken: "mm-token-2", baseUrl: "https://alerts.example.com" },
      },
    },
  },
}
```

## 故障排除

- 頻道中無回覆：確保機器人在頻道中且提及它（oncall）、使用觸發前綴（onchar）或設定 `chatmode: "onmessage"`。
- 認證錯誤：檢查 bot token、base URL 和帳號是否啟用。
- 多帳號問題：環境變數僅適用於 `default` 帳號。
