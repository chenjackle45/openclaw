---
title: "Automation Troubleshooting（自動化故障排除）"
summary: "故障排除 cron 和心跳排程和傳遞"
read_when:
  - Cron 未執行
  - Cron 執行但未傳遞訊息
  - 心跳似乎無聲或被跳過
---

# 自動化疑難排解

使用本頁解決排程和傳遞問題（`cron` + `heartbeat`）。

## 命令梯度

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

然後執行自動化檢查：

```bash
openclaw cron status
openclaw cron list
openclaw system heartbeat last
```

## Cron 未啟動

```bash
openclaw cron status
openclaw cron list
openclaw cron runs --id <jobId> --limit 20
openclaw logs --follow
```

良好輸出看起來像：

- `cron status` 報告已啟用且未來 `nextWakeAtMs`。
- 工作已啟用且具有有效的排程/時區。
- `cron runs` 顯示 `ok` 或明確跳過原因。

常見簽名：

- `cron: scheduler disabled; jobs will not run automatically` → 設定/環境中停用了 cron。
- `cron: timer tick failed` → 排程器刻度失敗；檢查周邊堆疊/日誌內容。
- 執行輸出中的 `reason: not-due` → 手動執行呼叫不使用 `--force`，且工作尚未到期。

## Cron 啟動但未傳遞

```bash
openclaw cron runs --id <jobId> --limit 20
openclaw cron list
openclaw channels status --probe
openclaw logs --follow
```

良好輸出看起來像：

- 執行狀態為 `ok`。
- 已設定隔離工作的傳遞模式/目標。
- 頻道探測報告目標頻道已連接。

常見簽名：

- 執行成功但傳遞模式為 `none` → 不期望外部訊息。
- 傳遞目標遺失/無效（`channel`/`to`） → 執行可能成功但內部跳過出站。
- 頻道驗證錯誤（`unauthorized`、`missing_scope`、`Forbidden`） → 傳遞被頻道認證/權限阻止。

## 心跳被抑制或跳過

```bash
openclaw system heartbeat last
openclaw logs --follow
openclaw config get agents.defaults.heartbeat
openclaw channels status --probe
```

良好輸出看起來像：

- 心跳已啟用且具有非零間隔。
- 上次心跳結果為 `ran`（或跳過原因是可理解的）。

常見簽名：

- `heartbeat skipped` 附帶 `reason=quiet-hours` → 在 `activeHours` 外。
- `requests-in-flight` → 主通道忙碌；心跳喚醒被延遲。
- `empty-heartbeat-file` → `HEARTBEAT.md` 存在但沒有可操作的內容。
- `alerts-disabled` → 可見性設定禁止出站心跳訊息。

## 時區和 activeHours 陷阱

```bash
openclaw config get agents.defaults.heartbeat.activeHours
openclaw config get agents.defaults.heartbeat.activeHours.timezone
openclaw config get agents.defaults.userTimezone || echo "agents.defaults.userTimezone not set"
```

檢查時區是否設定正確，以及 `activeHours` 是否在預期範圍內。

## 相關文件

- [Cron 工作](/zh-Hant/automation/cron-jobs)
- [Cron 對比心跳](/zh-Hant/automation/cron-vs-heartbeat)
- [心跳](/zh-Hant/gateway/heartbeat)
- [Gateway 疑難排解](/zh-Hant/gateway/troubleshooting)
