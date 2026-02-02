---
title: "投票 (Polls)"
summary: "透過 Gateway 與 CLI 發送投票"
read_when:
  - 新增或修改投票支援時
  - 除錯 CLI 或 Gateway 的投票發送功能時
---

# 投票

## 支援的頻道

- WhatsApp (Web 頻道)
- Discord
- MS Teams (Adaptive Cards)

## CLI

```bash
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

- `--channel`：`whatsapp` (預設)、`discord` 或 `msteams`
- `--poll-multi`：允許選擇多個選項
- `--poll-duration-hours`：僅限 Discord（未指定時預設為 24）

## Gateway RPC

方法：`poll`

參數：

- `to` (字串, 必要)
- `question` (字串, 必要)
- `options` (字串[], 必要)
- `maxSelections` (數字, 選用)
- `durationHours` (數字, 選用)
- `channel` (字串, 選用, 預設：`whatsapp`)
- `idempotencyKey` (字串, 必要)

## 頻道差異

- WhatsApp：2-12 個選項，`maxSelections` 必須在選項計數內，忽略 `durationHours`。
- Discord：2-10 個選項，`durationHours` 限制為 1-768 小時（預設 24）。`maxSelections > 1` 啟用多選；Discord 不支援嚴格的選擇計數模式。
- MS Teams：Adaptive Card 投票 (OpenClaw 管理)。無原生投票 API；`durationHours` 被忽略。

## Agent 工具 (Message)

使用 `message` 工具搭配 `poll` 動作（`to`、`pollQuestion`、`pollOption`、選用的 `pollMulti`、`pollDurationHours`、`channel`）。

註：Discord 沒有「精確選擇 N」模式；`pollMulti` 映射到多選。
Teams 投票以 Adaptive Cards 呈現，需要 Gateway 保持在線以在 `~/.openclaw/msteams-polls.json` 中紀錄投票。
