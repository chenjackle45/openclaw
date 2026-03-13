---
summary: "`openclaw agent` CLI 參考（透過 Gateway 發送單次 Agent 運行）"
read_when:
  - 想要透過腳本執行單次 Agent 運行時（可選用回應遞送功能）
title: "agent（直連 Agent）"
---

# `openclaw agent`

透過 Gateway 執行單次 Agent 運行（使用 `--local` 可於嵌入式環境執行）。
使用 `--agent <id>` 可直接指定已配置的 Agent。

相關資訊：

- Agent 發送工具：[Agent send](/zh-Hant/tools/agent-send)

## 指令範例

```bash
openclaw agent --to +15555550123 --message "status update" --deliver
openclaw agent --agent ops --message "Summarize logs"
openclaw agent --session-id 1234 --message "Summarize inbox" --thinking medium
openclaw agent --agent ops --message "Generate report" --deliver --reply-channel slack --reply-to "#reports"
```

## 注意事項

- 當此指令觸發 `models.json` 重新生成時，SecretRef 管理的供應商憑證會以非機密標記（例如 env var 名稱、`secretref-env:ENV_VAR_NAME` 或 `secretref-managed`）的形式儲存，而非解析後的明文密鑰。
- 標記寫入是來源權威：OpenClaw 保存來自活躍來源配置快照的標記，而非已解析的執行時機密值。
