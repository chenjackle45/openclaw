---
title: "投票功能 (Polls)"
summary: "透過 Gateway 與 CLI 發送投票訊息"
read_when:
  - 新增或修改投票支援時
  - 偵錯 CLI 或 Gateway 的投票發送功能時
---
# 投票功能 (Polls)

## 支援的頻道
- WhatsApp (Web 頻道)
- Discord
- MS Teams (使用 Adaptive Cards)

## CLI 操作範例

使用 `openclaw message poll` 指令發起投票：

```bash
# WhatsApp 範例
openclaw message poll --target +886912345678 \
  --poll-question "今天午餐吃什麼？" --poll-option "披薩" --poll-option "壽司" --poll-option "炸雞"

# Discord 範例
openclaw message poll --channel discord --target channel:123456789 \
  --poll-question "點心？" --poll-option "披薩" --poll-option "壽司"

# MS Teams 範例
openclaw message poll --channel msteams --target conversation:19:abc@thread.tacv2 \
  --poll-question "午餐？" --poll-option "披薩" --poll-option "壽司"
```

指令選項：
- `--channel`：指定頻道，預設為 `whatsapp`。
- `--poll-multi`：允許複選。
- `--poll-duration-hours`：僅限 Discord（預設 24 小時）。

## 頻道特性差異
- **WhatsApp**：支援 2-12 個選項，不支援設定持續時間。
- **Discord**：支援 2-10 個選項，持續時間範圍為 1-768 小時。複選模式不支援限制精確的選擇數量。
- **MS Teams**：使用 Adaptive Cards 模擬投票功能。由於沒有原生 API，Gateway 必須保持在線以在 `~/.openclaw/msteams-polls.json` 中紀錄投票結果。

## Agent 工具
使用 `message` 工具搭配 `poll` 動作即可在對話中觸發投票功能。
