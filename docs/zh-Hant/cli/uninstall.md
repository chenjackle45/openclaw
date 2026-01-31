---
title: "uninstall(解除安裝)"
summary: "`openclaw uninstall` CLI 參考（移除 Gateway 服務與本地資料）"
read_when:
  - 想要移除 Gateway 服務及/或本地狀態時
  - 想要先執行乾跑 (Dry-run) 預覽變動時
---

# `openclaw uninstall`

解除安裝 Gateway 服務與本地資料（CLI 執行檔本身會保留）。

```bash
# 解除安裝
openclaw uninstall

# 解除安裝所有資料並跳過確認提示
openclaw uninstall --all --yes

# 預覽解除安裝動作（不會實際刪除）
openclaw uninstall --dry-run
```
