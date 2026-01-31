---
title: "reset(重設配置)"
summary: "`openclaw reset` CLI 參考（重設本地狀態與配置）"
read_when:
  - 想要清除本地狀態但保留 CLI 安裝時
  - 想要預覽哪些項目將被移除（乾跑模式）時
---

# `openclaw reset`

重設本地配置與狀態（此動作不會解除安裝 CLI）。

```bash
# 執行重設
openclaw reset

# 預覽重設動作（不會實際刪除）
openclaw reset --dry-run

# 指定範圍進行強制重設（非互動模式）
openclaw reset --scope config+creds+sessions --yes --non-interactive
```
