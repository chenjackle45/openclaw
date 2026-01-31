---
title: "setup(環境初始化)"
summary: "`openclaw setup` CLI 參考（初始化配置與工作區）"
read_when:
  - 在不使用完整的新手導覽嚮導時執行首次設定
  - 想要設定預設的 Agent 工作區路徑時
---

# `openclaw setup`

初始化 `~/.openclaw/openclaw.json` 配置檔案與 Agent 工作區。

相關資訊：
- 新手引導：[馬上開始 (Getting started)](/start/getting-started)
- 配置嚮導：[新手導覽 (Onboarding)](/start/onboarding)

## 指令範例

```bash
# 執行基礎環境初始化
openclaw setup

# 指定 Agent 工作區的儲存路徑
openclaw setup --workspace ~/.openclaw/workspace
```

若要透過 `setup` 指令直接啟動新手導覽嚮導：

```bash
openclaw setup --wizard
```
