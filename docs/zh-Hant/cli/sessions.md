---
summary: "`openclaw sessions` CLI 參考（列出儲存的會話與使用量）"
read_when:
  - 想要列出儲存的會話並查看近期活動時
title: "sessions（會話列表）"
---

# `openclaw sessions`

列出儲存的對話會話。

```bash
openclaw sessions
openclaw sessions --agent work
openclaw sessions --all-agents
openclaw sessions --active 120
openclaw sessions --json
```

範圍選擇：

- 預設：已配置的預設 agent store
- `--agent <id>`：一個已配置的 agent store
- `--all-agents`：聚合所有已配置的 agent stores
- `--store <path>`：明確指定 store 路徑（不能與 `--agent` 或 `--all-agents` 合併）

`openclaw sessions --all-agents` 讀取已配置的 agent stores。Gateway 和 ACP 會話探索範圍更廣：它們也包括在預設 `agents/` 根目錄或樣版化 `session.store` 根目錄下發現的磁碟專屬 stores。這些發現的 stores 必須解析至 agent 根目錄內的規則 `sessions.json` 檔案；符號連結與超出根目錄的路徑會被跳過。

JSON 範例：

`openclaw sessions --all-agents --json`：

```json
{
  "path": null,
  "stores": [
    { "agentId": "main", "path": "/home/user/.openclaw/agents/main/sessions/sessions.json" },
    { "agentId": "work", "path": "/home/user/.openclaw/agents/work/sessions/sessions.json" }
  ],
  "allAgents": true,
  "count": 2,
  "activeMinutes": null,
  "sessions": [
    { "agentId": "main", "key": "agent:main:main", "model": "gpt-5" },
    { "agentId": "work", "key": "agent:work:main", "model": "claude-opus-4-5" }
  ]
}
```

## 清理維護

立即執行維護（不等待下次寫入週期）：

```bash
openclaw sessions cleanup --dry-run
openclaw sessions cleanup --agent work --dry-run
openclaw sessions cleanup --all-agents --dry-run
openclaw sessions cleanup --enforce
openclaw sessions cleanup --enforce --active-key "agent:main:telegram:dm:123"
openclaw sessions cleanup --json
```

`openclaw sessions cleanup` 使用 config 中的 `session.maintenance` 設定：

- 範圍注意：`openclaw sessions cleanup` 僅維護會話 stores/轉錄。它不清理 cron 執行日誌（`cron/runs/<jobId>.jsonl`），這些由 [Cron configuration](/zh-Hant/automation/cron-jobs#configuration) 中的 `cron.runLog.maxBytes` 和 `cron.runLog.keepLines` 管理，並在 [Cron maintenance](/zh-Hant/automation/cron-jobs#maintenance) 中說明。

- `--dry-run`：預覽不寫入情況下會清理/上限多少條目。
  - 在文字模式中，dry-run 會列印各會話動作表（`Action`、`Key`、`Age`、`Model`、`Flags`），讓您看到哪些會保留及移除。
- `--enforce`：即使 `session.maintenance.mode` 為 `warn` 也套用維護。
- `--active-key <key>`：保護特定活躍金鑰避免磁碟預算驅逐。
- `--agent <id>`：為一個已配置的 agent store 執行清理。
- `--all-agents`：為所有已配置的 agent stores 執行清理。
- `--store <path>`：針對特定 `sessions.json` 檔案執行。
- `--json`：列印 JSON 摘要。使用 `--all-agents` 時，輸出包含每個 store 的一個摘要。

`openclaw sessions cleanup --all-agents --dry-run --json`：

```json
{
  "allAgents": true,
  "mode": "warn",
  "dryRun": true,
  "stores": [
    {
      "agentId": "main",
      "storePath": "/home/user/.openclaw/agents/main/sessions/sessions.json",
      "beforeCount": 120,
      "afterCount": 80,
      "pruned": 40,
      "capped": 0
    },
    {
      "agentId": "work",
      "storePath": "/home/user/.openclaw/agents/work/sessions/sessions.json",
      "beforeCount": 18,
      "afterCount": 18,
      "pruned": 0,
      "capped": 0
    }
  ]
}
```

相關連結：

- Session 配置：[Configuration reference](/zh-Hant/gateway/configuration-reference#session)
