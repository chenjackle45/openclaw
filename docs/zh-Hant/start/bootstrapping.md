---
summary: "Agent 啟動儀式，播種工作區和身份檔案"
read_when:
  - 瞭解第一次 agent 執行時發生的情況
  - 解釋啟動檔案位置的地方
  - 調試入門身份設定
title: "Agent Bootstrapping（Agent 啟動）"
sidebarTitle: "Bootstrapping"
---

# Agent 啟動

啟動是為 agent 工作區和收集身份詳細資訊做準備的**首次執行**儀式。它發生在入門後，當 agent 第一次啟動時。

## 啟動做了什麼

在第一次 agent 執行時，OpenClaw 啟動工作區（預設為 `~/.openclaw/workspace`）：

- 播種 `AGENTS.md`、`BOOTSTRAP.md`、`IDENTITY.md`、`USER.md`。
- 執行簡短的問答儀式（一次一個問題）。
- 將身份和偏好寫入 `IDENTITY.md`、`USER.md`、`SOUL.md`。
- 完成後移除 `BOOTSTRAP.md`，以便它只執行一次。

## 在何處執行

啟動總是在 **Gateway 主機**上執行。如果 macOS 應用連接到遠端 Gateway，工作區和啟動檔案位於該遠端機器上。

<Note>
當 Gateway 在另一台機器上執行時，在 Gateway 主機上編輯工作區檔案（例如 `user@gateway-host:~/.openclaw/workspace`）。
</Note>

## 相關文件

- macOS 應用入門：[入門](/zh-Hant/start/onboarding)
- 工作區配置：[Agent 工作區](/zh-Hant/concepts/agent-workspace)
