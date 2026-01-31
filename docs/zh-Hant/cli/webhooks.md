---
title: "webhooks(網路鉤子)"
summary: "`openclaw webhooks` CLI 參考（Webhook 協助工具與 Gmail Pub/Sub）"
read_when:
  - 想要將 Gmail Pub/Sub 事件介接到 OpenClaw 時
  - 想要使用 Webhook 相關的輔助指令時
---

# `openclaw webhooks`

Webhook 協助工具與整合功能（包含 Gmail Pub/Sub 的連動）。

相關資訊：
- Webhook 概念：[網路鉤子 (Webhook)](/automation/webhook)
- Gmail Pub/Sub 整合：[Gmail Pub/Sub 說明](/automation/gmail-pubsub)

## Gmail 整合

```bash
# 設定 Gmail 帳戶以進行 Pub/Sub
openclaw webhooks gmail setup --account 使用者@example.com

# 執行 Gmail Webhook 處理程序
openclaw webhooks gmail run
```

詳細設定流程請參閱 [Gmail Pub/Sub 技術文件](/automation/gmail-pubsub)。
