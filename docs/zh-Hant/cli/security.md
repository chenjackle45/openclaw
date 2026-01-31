---
title: "security(安全性審查)"
summary: "`openclaw security` CLI 參考（審查並修復常見的安全性設計錯誤）"
read_when:
  - 想要對配置或狀態進行快速安全性審查時
  - 想要套用安全的「修復」建議（如權限變更、收緊預設值）時
---

# `openclaw security`

安全性工具（包含審查與選用的修復操作）。

相關資訊：
- 安全性手冊：[安全性 (Security)](/gateway/security)

## 安全審查 (Audit)

```bash
# 執行基礎安全審查
openclaw security audit

# 執行深度審查
openclaw security audit --deep

# 執行審查並自動套用修復建議
openclaw security audit --fix
```

審查工具會在下列情況發出警告：
- 多個私訊 (DM) 發送者共享主要會話時。對於共享收件匣，建議將 `session.dmScope` 設定為 `"per-channel-peer"`（若為多帳戶頻道則設為 `"per-account-channel-peer"`）。
- 當使用小型模型 (`<=300B`) 且在未啟用沙盒的情況下開啟網頁或瀏覽器工具時。
