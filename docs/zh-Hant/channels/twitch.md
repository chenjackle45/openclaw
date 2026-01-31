---
title: "Twitch(Twitch 聊天機器人)"
summary: "Twitch 聊天機器人配置與設定指南"
read_when:
  - 為 OpenClaw 設定 Twitch 聊天整合功能時
---
# Twitch (插件)

透過 IRC 連線支援 Twitch 聊天。OpenClaw 作為 Twitch 使用者（機器人帳號）登入，並在特定頻道中接收與發送訊息。

## 安裝插件
此插件不隨核心程式綑綁，需單獨安裝：
```bash
openclaw plugins install @openclaw/twitch
```

## 快速設定（初學者）
1. 為機器人建立專屬的 Twitch 帳號。
2. 產生憑證：使用 [Twitch Token Generator](https://twitchtokengenerator.com/)。
   - 選擇 **Bot Token**。
   - 確保勾選 `chat:read` 與 `chat:write` 權限。
   - 複製 **Client ID** 與 **Access Token**。
3. 取得您的 Twitch 使用者 ID（推薦使用 ID 而非使用者名稱以防攻擊）。
4. 在 OpenClaw 設定中加入 `accessToken` 與 `clientId`。
5. 啟動 Gateway。

## 基本設定範例
```json5
{
  channels: {
    twitch: {
      enabled: true,
      username: "機器人帳號",
      accessToken: "oauth:abc123...",
      clientId: "您的用戶端ID",
      channel: "要加入的頻道名稱",
      allowFrom: ["您的使用者ID"]
    }
  }
}
```

## 存取控制實務
- **角色限制**：可透過 `allowedRoles` 限制僅限 `moderator`（板主）、`owner`（台主）或 `vip` 觸發機器人。
- **使用者 ID 允許清單**：最安全的方式，使用具體的數字 ID。

## 令牌自動刷新
若要實現長期穩定運行，建議在 [Twitch Developer Console](https://dev.twitch.tv/console) 建立應用程式，並在設定中提供 `clientSecret` 與 `refreshToken`。OpenClaw 會在過期前自動更新令牌。

## 限制
- 每條訊息上限為 **500 字元**（超過會自動分塊）。
- Markdown 格式會被移除。
- 遵循 Twitch 原生的速率限制 (Rate limits)。
