---
summary: "使用 ACP 執行時階段執行 Pi、Claude Code、Codex、OpenCode、Gemini CLI 和其他治具代理"
read_when:
  - Running coding harnesses through ACP
  - Setting up thread-bound ACP sessions on thread-capable channels
  - Troubleshooting ACP backend and plugin wiring
  - Operating /acp commands from chat
title: "ACP Agents（ACP Agents）"
---

# ACP 代理

[代理用戶端協議（ACP）](https://agentclientprotocol.com/) 階段讓 OpenClaw 透過 ACP 後端外掛執行外部編碼治具（例如 Pi、Claude Code、Codex、OpenCode 和 Gemini CLI）。

如果您在 OpenClaw 中用普通語言要求「在 Codex 中執行此」或「在執行緒中啟動 Claude Code」，OpenClaw 應將該請求路由到 ACP 執行時（不是原生子代理執行時）。

## 快速操作流程

在需要實際 `/acp` 工作簿時使用：

1. 建立階段：
   - `/acp spawn codex --mode persistent --thread auto`
2. 在綁定執行緒中工作（或明確目標該階段鑰）。
3. 檢查執行時狀態：
   - `/acp status`
4. 根據需要調整執行時選項：
   - `/acp model <provider/model>`
   - `/acp permissions <profile>`
   - `/acp timeout <seconds>`
5. 輕推活躍階段，不替換內容：
   - `/acp steer tighten logging and continue`
6. 停止工作：
   - `/acp cancel`（停止目前轉向），或
   - `/acp close`（關閉階段 + 移除綁定）

## 快速開始用於人類

自然要求的範例：

- "啟動持久 Codex 階段並在執行緒中保持聚焦。"
- "以單次 Claude Code ACP 階段執行此並總結結果。"
- "在執行緒中為此任務使用 Gemini CLI，然後在該相同執行緒中保留後續追蹤。"

OpenClaw 應該執行的操作：

1. 選擇 `runtime: "acp"`。
2. 解析要求的治具目標（`agentId`，例如 `codex`）。
3. 如果要求執行緒綁定，且目前頻道支援它，將 ACP 階段綁定到執行緒。
4. 將後續執行緒訊息路由到該相同 ACP 階段，直到取消聚焦 / 關閉 / 過期。

詳見英文文件以了解完整配置...（篇幅限制）
