---
title: "Troubleshooting(頻道疑難排解)"
summary: "頻道特定疑難排解快捷方式（Discord/Telegram/WhatsApp）"
read_when:
  - 頻道連線但訊息不流通
  - 調查頻道設定錯誤（意圖、權限、隱私模式）
---
# Channel troubleshooting（頻道疑難排解）

從以下命令開始：

```bash
openclaw doctor
openclaw channels status --probe
```

`channels status --probe` 在可以檢測到常見頻道設定錯誤時列印警告，並包含小型即時檢查（憑證、某些權限/成員資格）。

## 頻道
- Discord：[/channels/discord#troubleshooting](/channels/discord#troubleshooting)
- Telegram：[/channels/telegram#troubleshooting](/channels/telegram#troubleshooting)
- WhatsApp：[/channels/whatsapp#troubleshooting-quick](/channels/whatsapp#troubleshooting-quick)

## Telegram 快速修復
- 日誌顯示 `HttpError: Network request for 'sendMessage' failed` 或 `sendChatAction` → 檢查 IPv6 DNS。如果 `api.telegram.org` 首先解析為 IPv6 且主機缺少 IPv6 出口，強制使用 IPv4 或啟用 IPv6。請參閱 [/channels/telegram#troubleshooting](/channels/telegram#troubleshooting)。
- 日誌顯示 `setMyCommands failed` → 檢查到 `api.telegram.org` 的外發 HTTPS 和 DNS 可達性（在鎖定的 VPS 或代理上常見）。
