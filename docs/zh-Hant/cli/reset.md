---
summary: "`openclaw reset` CLI 參考（重設本地狀態/config）"
read_when:
  - 想要清除本地狀態但保留 CLI 安裝時
  - 想要預覽哪些項目將被移除時
title: "reset（重設配置）"
---

# `openclaw reset`

重設本地 config/狀態（保留 CLI 安裝）。

```bash
openclaw backup create
openclaw reset
openclaw reset --dry-run
openclaw reset --scope config+creds+sessions --yes --non-interactive
```

若您想在移除本地狀態前保留可還原的快照，請先執行 `openclaw backup create`。
