---
summary: "`openclaw cron` CLI 參考（排程與執行背景任務）"
read_when:
  - 想要排定任務或喚醒動作時
  - 正在偵錯排程執行與其日誌時
title: "cron（排程管理）"
---

# `openclaw cron`

管理 Gateway 排程器中的排程任務。

相關資訊：

- 排程任務：[Cron jobs](/zh-Hant/automation/cron-jobs)

提示：執行 `openclaw cron --help` 可查看完整的指令介面。

注意：獨立的 `cron add` 任務預設使用 `--announce` 遞送。使用 `--no-deliver` 可讓輸出保持內部。`--deliver` 仍作為已棄用的別名保留。

注意：一次性任務（`--at`）預設在成功後刪除。使用 `--keep-after-run` 可保留它們。

注意：重複性任務現在在連續錯誤後使用指數退避重試（30s → 1m → 5m → 15m → 60m），並在下次成功執行後恢復正常排程。

注意：`openclaw cron run` 現在在手動執行排入佇列後立即返回。成功回應包含 `{ ok: true, enqueued: true, runId }`；使用 `openclaw cron runs --id <job-id>` 追蹤最終結果。

注意：保留/清理由設定控制：

- `cron.sessionRetention`（預設 `24h`）清理已完成的獨立執行會話。
- `cron.runLog.maxBytes` + `cron.runLog.keepLines` 清理 `~/.openclaw/cron/runs/<jobId>.jsonl`。

## 常見編輯操作

在不變更訊息內容的情況下更新遞送設定：

```bash
openclaw cron edit <job-id> --announce --channel telegram --to "123456789"
```

為獨立任務停用遞送：

```bash
openclaw cron edit <job-id> --no-deliver
```

為獨立任務啟用輕量啟動情境：

```bash
openclaw cron edit <job-id> --light-context
```

對特定頻道進行公告：

```bash
openclaw cron edit <job-id> --announce --channel slack --to "channel:C1234567890"
```

建立帶有輕量啟動情境的獨立任務：

```bash
openclaw cron add \
  --name "Lightweight morning brief" \
  --cron "0 7 * * *" \
  --session isolated \
  --message "Summarize overnight updates." \
  --light-context \
  --no-deliver
```

`--light-context` 僅適用於獨立的 agent-turn 任務。對於 cron 執行，輕量模式讓啟動情境保持為空，而非注入完整的工作區啟動集。
