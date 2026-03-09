---
summary: "`openclaw uninstall` CLI 參考（移除 Gateway 服務與本地資料）"
read_when:
  - 想要移除 Gateway 服務及/或本地狀態時
  - 想要先執行 dry-run 預覽時
title: "uninstall（解除安裝）"
---

# `openclaw uninstall`

解除安裝 Gateway 服務 + 本地資料（CLI 保留）。

```bash
openclaw backup create
openclaw uninstall
openclaw uninstall --all --yes
openclaw uninstall --dry-run
```

若您想在移除狀態或工作區前保留可還原的快照，請先執行 `openclaw backup create`。
