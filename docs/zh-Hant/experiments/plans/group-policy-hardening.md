---
title: "Group policy hardening(群組策略強化)"
summary: "Telegram 允許清單強化：前綴 + 空白正規化"
read_when:
  - 審查歷史 Telegram 允許清單變更
---
# Telegram Allowlist Hardening(Telegram 允許清單強化)

**日期**: 2026-01-05  
**狀態**: 完成  
**PR**: #216

## 摘要

Telegram 允許清單現在不區分大小寫地接受 `telegram:` 和 `tg:` 前綴，並容忍
意外的空白。這使入站允許清單檢查與出站發送正規化對齊。

## 變更內容

- 前綴 `telegram:` 和 `tg:` 被視為相同（不區分大小寫）。
- 允許清單條目被修剪；空條目被忽略。

## 範例

所有這些都被接受為相同 ID：

- `telegram:123456`
- `TG:123456`
- ` tg:123456 `

## 為什麼重要

從日誌或聊天 ID 複製/貼上通常包括前綴和空白。正規化可避免
在決定是否在 DM 或群組中回應時出現假陰性。

## 相關文件

- [Group Chats](/concepts/groups)
- [Telegram Provider](/channels/telegram)
