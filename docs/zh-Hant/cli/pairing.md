---
title: "pairing(裝置配對)"
summary: "`openclaw pairing` CLI 參考（核准與列出配對請求）"
read_when:
  - 正在使用配對模式的私訊 (DM) 且需要核准發送者時
---

# `openclaw pairing`

核准或查看私訊 (DM) 配對請求（適用於支援配對機制的頻道）。

相關資訊：
- 配對流程導覽：[配對流程 (Pairing)](/start/pairing)

## 指令範例

```bash
# 列出特定的頻道（如 WhatsApp）的待處理配對請求
openclaw pairing list whatsapp

# 核准特定代碼的配對請求，並發送通知
openclaw pairing approve whatsapp <代碼> --notify
```
