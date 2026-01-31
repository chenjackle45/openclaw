---
title: "logs(日誌查看)"
summary: "`openclaw logs` CLI 參考（透過 RPC 追蹤 Gateway 日誌）"
read_when:
  - 需要在不使用 SSH 的情況下遠端追蹤 Gateway 日誌時
  - 想要獲取 JSON 格式的日誌行以供其它工具處理時
---

# `openclaw logs`

透過 RPC 追蹤 Gateway 的檔案日誌（支援遠端模式）。

相關資訊：
- 日誌配置總覽：[日誌配置 (Logging)](/logging)

## 指令範例

```bash
# 顯示近期日誌內容
openclaw logs

# 持續追蹤（即時更新）
openclaw logs --follow

# 以 JSON 格式輸出日誌行
openclaw logs --json

# 限制顯示最近的 500 行內容
openclaw logs --limit 500
```
