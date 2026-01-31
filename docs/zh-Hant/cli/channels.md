---
title: "channels(聊天頻道)"
summary: "`openclaw channels` CLI 參考（帳戶管理、狀態查看、登入/登出與日誌）"
read_when:
  - 想要新增或移除頻道帳戶（如 WhatsApp, Telegram, Discord, Google Chat, Slack, Mattermost, Signal, iMessage）時
  - 想要檢查頻道狀態或追蹤頻道日誌時
---

# `openclaw channels`

管理聊天頻道帳戶及其在 Gateway 上的運行狀態。

相關資訊：
- 頻道指南總覽：[各類頻道介紹](/channels/index)
- Gateway 配置說明：[配置導覽](/gateway/configuration)

## 常見指令

```bash
# 列出所有配置的頻道帳戶
openclaw channels list

# 查看所有頻道的運行狀態
openclaw channels status

# 探測頻道功能權限 (Capabilities)
openclaw channels capabilities

# 針對特定 Discord 頻道探測權限
openclaw channels capabilities --channel discord --target channel:123

# 將 Slack 的名稱解析為 ID
openclaw channels resolve --channel slack "#general" "@jane"

# 查看所有頻道的即時日誌
openclaw channels logs --channel all
```

## 新增與移除帳戶

```bash
# 新增一個 Telegram 機器人帳戶
openclaw channels add --channel telegram --token <bot-token>

# 移除 Telegram 帳戶並刪除本地資料
openclaw channels remove --channel telegram --delete
```

提示：執行 `openclaw channels add --help` 可查看各個頻道的專屬參數（如權杖、路徑設定等）。

## 登入與登出（互動式）

```bash
# 執行 WhatsApp 的掃碼登入流程
openclaw channels login --channel whatsapp

# 登出 WhatsApp
openclaw channels logout --channel whatsapp
```

## 疑難排解

- 執行 `openclaw status --deep` 以進行全面的頻道健康探測。
- 使用 `openclaw doctor` 獲取引導式的修復建議。
- 若 `list` 指令顯示 `Claude: HTTP 403` 相關錯誤，代表 usage snapshot 功能缺少 `user:profile` 授權範圍。此時可使用 `--no-usage` 旗標，或提供 `CLAUDE_WEB_SESSION_KEY` 下的連線權杖，亦或透過 Claude Code CLI 重新認證。

## 功能權限探測 (Capabilities probe)

獲取供應商的功能提示（Intents/Scopes）以及靜態的功能支援度資訊：

```bash
openclaw channels capabilities
openclaw channels capabilities --channel discord --target channel:123
```

**注意事項**：
- `--channel` 為選用參數；若省略則會列出所有頻道（包含擴充功能）。
- 探測結果因供應商而異：例如 Discord 的 Intents 與頻道權限、Slack 的 Bot 與 User Scopes、Telegram 的機器人標記與 Webhook 設定以及 Signal 的背景程序版本等。

## 名稱解析 (Resolve names to IDs)

透過供應商的通訊錄將頻道或使用者名稱解析為 ID：

```bash
# 將 Slack 的頻道與使用者名稱解析為 ID
openclaw channels resolve --channel slack "#general" "@jane"

# 將 Discord 的伺服器/頻道路徑進行解析
openclaw channels resolve --channel discord "我的伺服器/#支援" "@某人"
```

提示：可使用 `--kind user|group|auto` 強制指定解析的目標類型。
