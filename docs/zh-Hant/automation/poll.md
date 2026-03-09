---
summary: "透過 Gateway 與 CLI 發送投票"
read_when:
  - 新增或修改投票支援時
  - 除錯 CLI 或 Gateway 的投票發送功能時
title: "Polls（投票）"
---

# 投票

## 支援的頻道

- Telegram
- WhatsApp（web 頻道）
- Discord
- MS Teams（Adaptive Cards）

## CLI

```bash
# Telegram
openclaw message poll --channel telegram --target 123456789 \
  --poll-question "Ship it?" --poll-option "Yes" --poll-option "No"
openclaw message poll --channel telegram --target -1001234567890:topic:42 \
  --poll-question "Pick a time" --poll-option "10am" --poll-option "2pm" \
  --poll-duration-seconds 300

# WhatsApp
openclaw message poll --target +15555550123 \
  --poll-question "Lunch today?" --poll-option "Yes" --poll-option "No" --poll-option "Maybe"
openclaw message poll --target 123456789@g.us \
  --poll-question "Meeting time?" --poll-option "10am" --poll-option "2pm" --poll-option "4pm" --poll-multi

# Discord
openclaw message poll --channel discord --target channel:123456789 \
  --poll-question "Snack?" --poll-option "Pizza" --poll-option "Sushi"
openclaw message poll --channel discord --target channel:123456789 \
  --poll-question "Plan?" --poll-option "A" --poll-option "B" --poll-duration-hours 48

# MS Teams
openclaw message poll --channel msteams --target conversation:19:abc@thread.tacv2 \
  --poll-question "Lunch?" --poll-option "Pizza" --poll-option "Sushi"
```

選項：

- `--channel`：`whatsapp`（預設）、`telegram`、`discord` 或 `msteams`
- `--poll-multi`：允許選擇多個選項
- `--poll-duration-hours`：僅限 Discord（省略時預設 24）
- `--poll-duration-seconds`：僅限 Telegram（5-600 秒）
- `--poll-anonymous` / `--poll-public`：僅限 Telegram 的投票可見性

## Gateway RPC

方法：`poll`

參數：

- `to`（string，必填）
- `question`（string，必填）
- `options`（string[]，必填）
- `maxSelections`（number，選填）
- `durationHours`（number，選填）
- `durationSeconds`（number，選填，僅限 Telegram）
- `isAnonymous`（boolean，選填，僅限 Telegram）
- `channel`（string，選填，預設：`whatsapp`）
- `idempotencyKey`（string，必填）

## 頻道差異

- Telegram：2-10 個選項。透過 `threadId` 或 `:topic:` 目標支援論壇話題。使用 `durationSeconds` 而非 `durationHours`，限制在 5-600 秒。支援匿名和公開投票。
- WhatsApp：2-12 個選項，`maxSelections` 必須在選項數量範圍內，忽略 `durationHours`。
- Discord：2-10 個選項，`durationHours` 限制在 1-768 小時（預設 24）。`maxSelections > 1` 啟用多選；Discord 不支援嚴格的選擇數量限制。
- MS Teams：Adaptive Card 投票（OpenClaw 管理）。無原生投票 API；`durationHours` 被忽略。

## Agent 工具（Message）

使用 `message` 工具並帶上 `poll` 動作（`to`、`pollQuestion`、`pollOption`，選填 `pollMulti`、`pollDurationHours`、`channel`）。

對於 Telegram，工具也接受 `pollDurationSeconds`、`pollAnonymous` 和 `pollPublic`。

使用 `action: "poll"` 建立投票。帶有 `action: "send"` 的投票欄位會被拒絕。

注意：Discord 沒有「精確選 N 個」模式；`pollMulti` 對應到多選。
Teams 投票以 Adaptive Cards 渲染，需要 Gateway 持續在線以在
`~/.openclaw/msteams-polls.json` 中記錄投票。
