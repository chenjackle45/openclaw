---
summary: "跨通道共用的反應語意"
read_when:
  - 在任何通道中處理反應時
title: "Reactions（反應）"
---

# 反應工具

跨通道共用的反應語意：

- 新增反應時需要 `emoji`。
- 當支援時，`emoji=""` 移除機器人的反應。
- 當支援時，`remove: true` 移除指定的表情符號（需要 `emoji`）。

通道筆記：

- **Discord/Slack**：空 `emoji` 移除訊息上機器人的所有反應；`remove: true` 只移除該表情符號。
- **Google Chat**：空 `emoji` 移除訊息上應用的反應；`remove: true` 只移除該表情符號。
- **Telegram**：空 `emoji` 移除機器人的反應；`remove: true` 也移除反應但仍需要非空 `emoji` 進行工具驗證。
- **WhatsApp**：空 `emoji` 移除機器人反應；`remove: true` 對應到空表情符號（仍需要 `emoji`）。
- **Signal**：當 `channels.signal.reactionNotifications` 啟用時，入站反應通知會發出系統事件。
