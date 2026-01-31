---
title: "agent(直連 Agent)"
summary: "`openclaw agent` CLI 參考（透過 Gateway 發送單次 Agent 運行）"
read_when:
  - 想要透過腳本執行單次 Agent 運行時（可選用回應遞送功能）
---

# `openclaw agent`

透過 Gateway 執行單次 Agent 運行（使用 `--local` 可於嵌入式環境執行）。
使用 `--agent <ID>` 可直接指定已配置的 Agent。

相關資訊：
- Agent 發送工具：[Agent 發送 (agent-send)](/tools/agent-send)

## 指令範例

```bash
# 傳送狀態更新並遞送回應
openclaw agent --to +15555550123 --message "狀態更新" --deliver

# 指定 ops 代理進行日誌摘要
openclaw agent --agent ops --message "總結日誌"

# 針對特定會話進行摘要，並設定思考等級為 medium
openclaw agent --session-id 1234 --message "總結收件匣" --thinking medium

# 產生報告並遞送至 Slack 的指定頻道
openclaw agent --agent ops --message "產生報告" --deliver --reply-channel slack --reply-to "#reports"
```
