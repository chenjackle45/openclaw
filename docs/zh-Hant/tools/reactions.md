---
title: "Reactions(Reaction 工具)"
summary: "跨 Channels 共享的 Reaction 語意"
read_when:
  - 在任何 Channel 中處理 Reactions
---
# Reaction 工具

跨 Channels 共享的 Reaction 語意：

- 新增 Reaction 時必須提供 `emoji`。
- `emoji=""` 在支援時移除 Bot 的 Reaction(s)。
- `remove: true` 在支援時移除指定的 Emoji（需要 `emoji`）。

Channel 注意事項：

- **Discord/Slack**：空 `emoji` 移除 Bot 在該訊息上的所有 Reactions；`remove: true` 僅移除該 Emoji。
- **Google Chat**：空 `emoji` 移除 App 在該訊息上的 Reactions；`remove: true` 僅移除該 Emoji。
- **Telegram**：空 `emoji` 移除 Bot 的 Reactions；`remove: true` 也會移除 Reactions 但仍需要非空 `emoji` 以通過 Tool 驗證。
- **WhatsApp**：空 `emoji` 移除 Bot Reaction；`remove: true` 對應至空 Emoji（仍需要 `emoji`）。
- **Signal**：當 `channels.signal.reactionNotifications` 啟用時，Inbound Reaction 通知會發出 System Events。
