---
title: "cron(排程管理)"
summary: "`openclaw cron` CLI 參考（排程與執行背景任務）"
read_when:
  - 想要排定任務或喚醒動作時
  - 正在偵錯排程執行與其日誌時
---

# `openclaw cron`

管理 Gateway 排程器中的排程任務 (Cron jobs)。

相關資訊：
- 排程任務概念：[排程任務 (Cron jobs)](/automation/cron-jobs)

提示：執行 `openclaw cron --help` 可查看完整的指令介面與參數。

## 常見編輯操作

在不變更訊息內容的情況下更新遞送設定：

```bash
openclaw cron edit <任務ID> --deliver --channel telegram --to "123456789"
```

為特定任務停用回應遞送功能：

```bash
openclaw cron edit <任務ID> --no-deliver
```
