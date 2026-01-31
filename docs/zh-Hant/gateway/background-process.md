---
title: "background-process(Background Exec & Process)"
summary: "背景執行與程序管理"
read_when:
  - 新增或修改背景執行行為時
  - 除錯長執行的 exec 任務時
---

# Background Exec + Process Tool

OpenClaw 透過 `exec` 工具執行 Shell 指令，並將長執行的任務保留在記憶體中。`process` 工具則負責管理這些背景工作階段 (Sessions)。

## exec tool

關鍵參數:
- `command` (必填)
- `yieldMs` (預設 10000): 超過此延遲後自動背景化
- `background` (bool): 立即背景化
- `timeout` (秒, 預設 1800): 超時後殺死程序
- `elevated` (bool): 若啟用/允許 Elevated 模式，則在 Host 上以提升權限執行
- 需要真實 TTY? 設定 `pty: true`。
- `workdir`, `env`

行為:
- 前景執行直接回傳輸出。
- 當背景化時 (明確指定或超時)，工具回傳 `status: "running"` + `sessionId` 以及簡短的尾端輸出 (Tail)。
- 輸出保留在記憶體中，直到工作階段被輪詢 (Poll) 或清除 (Clear)。
- 若 `process` 工具被停用，`exec` 會同步執行並忽略 `yieldMs`/`background`。

## Child process bridging

當在 exec/process 工具之外衍生長執行的子程序時 (例如 CLI respawns 或 Gateway helpers)，請附加 Child-process Bridge Helper，以便轉發終止訊號並在退出/錯誤時卸離聆聽者。這能避免 systemd 上的孤兒程序 (Orphaned Processes)，並保持跨平台的關閉行為一致。

環境變數覆蓋:
- `PI_BASH_YIELD_MS`: 預設 Yield (ms)
- `PI_BASH_MAX_OUTPUT_CHARS`: 記憶體內輸出上限 (chars)
- `OPENCLAW_BASH_PENDING_MAX_OUTPUT_CHARS`: 每個 Stream 的待處理 stdout/stderr 上限 (chars)
- `PI_BASH_JOB_TTL_MS`: 完成工作階段的 TTL (ms, 範圍 1m–3h)

設定 (建議):
- `tools.exec.backgroundMs` (預設 10000)
- `tools.exec.timeoutSec` (預設 1800)
- `tools.exec.cleanupMs` (預設 1800000)
- `tools.exec.notifyOnExit` (預設 true): 當背景 exec 退出時，將系統事件排入佇列 + 請求 Heartbeat。

## process tool

動作 (Actions):
- `list`: 列出執行中 + 已完成的工作階段
- `poll`: 取出 (Drain) 工作階段的新輸出 (亦報告退出狀態)
- `log`: 讀取聚合的輸出 (支援 `offset` + `limit`)
- `write`: 發送 stdin (`data`, 選填 `eof`)
- `kill`: 終止背景工作階段
- `clear`: 從記憶體中移除已完成的工作階段
- `remove`: 若執行中則殺死，若已完成則清除

備註:
- 僅背景化的工作階段會被列出/持久化在記憶體中。
- 程序重啟後工作階段會遺失 (無磁碟持久化)。
- 只有當您執行 `process poll/log` 且工具結果被記錄時，工作階段日誌才會儲存至聊天記錄。
- `process` 是以 Agent 為範疇的 (Scoped per agent)；它只能看見該 Agent 啟動的工作階段。
- `process list` 包含衍生的 `name` (指令動詞 + 目標) 以供快速瀏覽。
- `process log` 使用基於行的 `offset`/`limit` (省略 `offset` 以抓取最後 N 行)。

## 範例

執行長任務並稍後輪詢：
```json
{"tool": "exec", "command": "sleep 5 && echo done", "yieldMs": 1000}
```
```json
{"tool": "process", "action": "poll", "sessionId": "<id>"}
```

立即在背景啟動：
```json
{"tool": "exec", "command": "npm run build", "background": true}
```

發送 stdin：
```json
{"tool": "process", "action": "write", "sessionId": "<id>", "data": "y\n"}
```
