---
title: "Twitch"
summary: "Twitch 聊天機器人配置與設定"
read_when:
  - 為 OpenClaw 設定 Twitch 聊天整合功能時
---

# Twitch (插件)

透過 IRC 連線支援 Twitch 聊天。OpenClaw 作為 Twitch 使用者（機器人帳號）登入，並在頻道中接收與發送訊息。

## 安裝插件

Twitch 不隨核心安裝綑綁。

透過 CLI 安裝（npm 套件庫）：

```bash
openclaw plugins install @openclaw/twitch
```

本地簽出（從 git 儲存庫執行時）：

```bash
openclaw plugins install ./extensions/twitch
```

詳情：[插件](/plugin)

## 快速設定（初學者）

1. 為機器人建立專屬的 Twitch 帳號。
2. 產生憑證：[Twitch Token Generator](https://twitchtokengenerator.com/)
   - 選擇 **Bot Token**
   - 確保勾選 `chat:read` 與 `chat:write` 權限
   - 複製 **Client ID** 與 **Access Token**
3. 取得您的 Twitch 使用者 ID：https://www.streamweasels.com/tools/convert-twitch-username-to-user-id/
4. 設定令牌：
   - 環境變數：`OPENCLAW_TWITCH_ACCESS_TOKEN=...`（僅預設帳戶）
   - 或設定：`channels.twitch.accessToken`
   - 如果兩者都設定，設定優先（環境變數備選僅限預設帳戶）。
5. 啟動 Gateway。

**重要：** 新增存取控制（`allowFrom` 或 `allowedRoles`）以防止未授權使用者觸發機器人。`requireMention` 預設為 `true`。

最小設定：

```json5
{
  channels: {
    twitch: {
      enabled: true,
      username: "openclaw",        // 機器人的 Twitch 帳號
      accessToken: "oauth:abc123...",
      clientId: "xyz789...",
      channel: "vevisk",           // 要加入的 Twitch 頻道
      allowFrom: ["123456789"],    // （推薦）您的 Twitch 使用者 ID
    },
  },
}
```

## 這是什麼

- Gateway 擁有的 Twitch 頻道。
- 確定性路由：回覆始終回到 Twitch。
- 每個帳戶對應一個隔離會話鍵 `agent:<agentId>:twitch:<accountName>`。
- `username` 是機器人帳號（誰進行認證），`channel` 是要加入的聊天室。

## 設定（詳細）

### 產生憑證

使用 [Twitch Token Generator](https://twitchtokengenerator.com/)：

- 選擇 **Bot Token**
- 確認 `chat:read` 和 `chat:write` 範圍已選擇
- 複製 **Client ID** 和 **Access Token**

無需手動應用程式註冊。令牌在數小時後過期。

### 設定機器人

**環境變數（僅預設帳戶）：**

```bash
OPENCLAW_TWITCH_ACCESS_TOKEN=oauth:abc123...
```

**或設定：**

```json5
{
  channels: {
    twitch: {
      enabled: true,
      username: "openclaw",
      accessToken: "oauth:abc123...",
      clientId: "xyz789...",
      channel: "vevisk",
    },
  },
}
```

如果兩者都設定，設定優先。

### 存取控制（推薦）

```json5
{
  channels: {
    twitch: {
      allowFrom: ["123456789"],    // （推薦）僅您的 Twitch 使用者 ID
    },
  },
}
```

優先使用 `allowFrom` 作為硬允許清單。使用 `allowedRoles` 進行基於角色的存取。

**可用角色：** `"moderator"`、`"owner"`、`"vip"`、`"subscriber"`、`"all"`。

**為何使用使用者 ID？** 使用者名稱可以更改，允許冒充。使用者 ID 是永久的。

取得您的 Twitch 使用者 ID：https://www.streamweasels.com/tools/convert-twitch-username-to-user-id/

## 令牌刷新（可選）

來自 [Twitch Token Generator](https://twitchtokengenerator.com/) 的令牌無法自動刷新 - 過期時重新產生。

對於自動令牌刷新，在 [Twitch Developer Console](https://dev.twitch.tv/console) 建立自己的 Twitch 應用程式並新增到設定：

```json5
{
  channels: {
    twitch: {
      clientSecret: "your_client_secret",
      refreshToken: "your_refresh_token",
    },
  },
}
```

機器人會在過期前自動刷新令牌並記錄刷新事件。

## 多帳戶支援

使用 `channels.twitch.accounts` 與每帳戶令牌。請參閱 [`gateway/configuration`](/gateway/configuration) 了解共享模式。

範例（一個機器人帳號在兩個頻道）：

```json5
{
  channels: {
    twitch: {
      accounts: {
        channel1: {
          username: "openclaw",
          accessToken: "oauth:abc123...",
          clientId: "xyz789...",
          channel: "vevisk",
        },
        channel2: {
          username: "openclaw",
          accessToken: "oauth:def456...",
          clientId: "uvw012...",
          channel: "secondchannel",
        },
      },
    },
  },
}
```

**註：** 每個帳戶需要自己的令牌（每個頻道一個令牌）。

## 存取控制

### 基於角色的限制

```json5
{
  channels: {
    twitch: {
      accounts: {
        default: {
          allowedRoles: ["moderator", "vip"],
        },
      },
    },
  },
}
```

### 按使用者 ID 的允許清單（最安全）

```json5
{
  channels: {
    twitch: {
      accounts: {
        default: {
          allowFrom: ["123456789", "987654321"],
        },
      },
    },
  },
}
```

### 基於角色的存取（替代方案）

`allowFrom` 是硬允許清單。設定時，僅允許這些使用者 ID。

如果您想要基於角色的存取，不設定 `allowFrom` 並改為設定 `allowedRoles`：

```json5
{
  channels: {
    twitch: {
      accounts: {
        default: {
          allowedRoles: ["moderator"],
        },
      },
    },
  },
}
```

### 停用 @提及要求

預設情況下，`requireMention` 是 `true`。要停用並回應所有訊息：

```json5
{
  channels: {
    twitch: {
      accounts: {
        default: {
          requireMention: false,
        },
      },
    },
  },
}
```

## 疑難排解

首先執行診斷指令：

```bash
openclaw doctor
openclaw channels status --probe
```

### 機器人不回應訊息

**檢查存取控制：** 確保您的使用者 ID 在 `allowFrom` 中，或暫時移除 `allowFrom` 並設定 `allowedRoles: ["all"]` 進行測試。

**檢查機器人在頻道中：** 機器人必須加入在 `channel` 中指定的頻道。

### 令牌問題

**「連線失敗」或認證錯誤：**

- 驗證 `accessToken` 是 OAuth 存取令牌值（通常以 `oauth:` 前綴開始）
- 檢查令牌具有 `chat:read` 和 `chat:write` 範圍
- 如果使用令牌刷新，驗證 `clientSecret` 和 `refreshToken` 已設定

### 令牌刷新不起作用

**檢查日誌的刷新事件：**

```
Using env token source for mybot
Access token refreshed for user 123456 (expires in 14400s)
```

如果您看到「token refresh disabled (no refresh token)」：

- 確保提供了 `clientSecret`
- 確保提供了 `refreshToken`

## 限制

- **每條訊息 500 字元**（超過會自動分塊在字邊界）。
- Markdown 被移除後分塊。
- 無速率限制（使用 Twitch 的內建速率限制）。
