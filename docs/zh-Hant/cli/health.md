---
title: "health(健康狀態)"
summary: "`openclaw health` CLI 參考（透過 RPC 獲取 Gateway 健康狀態）"
read_when:
  - 想要快速檢查運行中 Gateway 的健康狀態時
---

# `openclaw health`

從運行中的 Gateway 獲取健康狀態。

```bash
# 獲取健康狀態
openclaw health

# 以 JSON 格式輸出
openclaw health --json

# 顯示詳細資訊（即時探測）
openclaw health --verbose
```

**注意事項**：
- `--verbose` 會執行即時探測；當配置了多個帳戶時，會列出每個帳戶的計時資訊。
- 當配置了多個 Agent 時，輸出結果會包含各個 Agent 的會話儲存狀態。
