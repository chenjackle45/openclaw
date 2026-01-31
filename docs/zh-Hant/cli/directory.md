---
title: "directory(通訊錄)"
summary: "`openclaw directory` CLI 參考（自我、聯絡人、群組）"
read_when:
  - 想要查詢頻道的聯絡人、群組或自我 ID 時
  - 正在開發頻道目錄適配器 (Directory Adapter) 時
---

# `openclaw directory`

針對支援目錄功能的頻道進行查詢（聯絡人/對等端、群組與「自我」）。

## 常用參數

- `--channel <名稱>`：頻道 ID 或別名（當配置多個頻道時為必填；若僅配置一個則自動選定）。
- `--account <ID>`：帳戶 ID（預設為該頻道的預設帳戶）。
- `--json`：以 JSON 格式輸出。

## 注意事項

- `directory` 旨在協助您找到可用於其他指令（特別是 `openclaw message send --target ...`）的 ID。
- 對於許多頻道而言，查詢結果是基於配置（允許清單/已配置的群組），而非供應商的即時目錄。
- 預設輸出格式為以 Tab 分隔的 `id`（有時包含 `name`）；若需用於腳本請使用 `--json`。

## 搭配 `message send` 使用

```bash
# 查詢 Slack 中包含 "U0" 的對等端 (Peers)
openclaw directory peers list --channel slack --query "U0"

# 使用查到的 ID 發送訊息
openclaw message send --channel slack --target user:U012ABCDEF --message "你好"
```

## ID 格式（依頻道）

- **WhatsApp**: `+15551234567` (私訊), `1234567890-1234567890@g.us` (群組)
- **Telegram**: `@使用者名稱` 或數值聊天 ID；群組為數值 ID
- **Slack**: `user:U…` 與 `channel:C…`
- **Discord**: `user:<ID>` 與 `channel:<ID>`
- **Matrix (外掛)**: `user:@user:server`, `room:!roomId:server`, 或 `#alias:server`
- **Microsoft Teams (外掛)**: `user:<ID>` 與 `conversation:<ID>`
- **Zalo (外掛)**: 使用者 ID (Bot API)
- **Zalo Personal / `zalouser` (外掛)**: 來自 `zca` 的執行緒 ID（私訊/群組）（透過 `me`, `friend list`, `group list` 查詢）

## 自我查詢 (“me”)

```bash
openclaw directory self --channel zalouser
```

## 對等端 (聯絡人/使用者)

```bash
openclaw directory peers list --channel zalouser
openclaw directory peers list --channel zalouser --query "name"
openclaw directory peers list --channel zalouser --limit 50
```

## 群組

```bash
openclaw directory groups list --channel zalouser
openclaw directory groups list --channel zalouser --query "work"
openclaw directory groups members --channel zalouser --group-id <ID>
```
