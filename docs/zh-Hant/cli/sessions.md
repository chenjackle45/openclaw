---
title: "sessions(會話列表)"
summary: "`openclaw sessions` CLI 參考（列出儲存的會話與使用量）"
read_when:
  - 想要列出儲存的會話並查看近期活動時
---

# `openclaw sessions`

列出儲存的對話會話。

```bash
# 列出所有會話
openclaw sessions

# 僅列出最近 120 分鐘內有活動的會話
openclaw sessions --active 120

# 以 JSON 格式輸出
openclaw sessions --json
```
