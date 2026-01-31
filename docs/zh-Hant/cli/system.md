---
title: "system(系統操作)"
summary: "`openclaw system` CLI 參考（系統事件、心跳與在線狀態）"
read_when:
  - 想要在不建立排程任務的情況下發送系統事件時
  - 需要啟用或停用心跳機制時
  - 想要檢查系統在線狀態 (Presence) 條目時
---

# `openclaw system`

針對 Gateway 的系統級協助工具：發送系統事件、控制心跳機制並檢視在線狀態。

## 常見指令

```bash
# 立即觸發一個系統事件
openclaw system event --text "檢查緊急追蹤事項" --mode now

# 啟用心跳機制
openclaw system heartbeat enable

# 顯示最後一次心跳事件
openclaw system heartbeat last

# 顯示系統在線狀態
openclaw system presence
```

## `system event` (系統事件)

將系統事件排入**主要 (main)** 會話的隊列中。下一次心跳觸發時，系統會將其作為 `System:` 行注入提示詞 (Prompt) 中。使用 `--mode now` 可立即觸發心跳；`next-heartbeat` (預設值) 則會等待下一次排定的週期。

**旗標說明**：
- `--text <文字>`：(必要) 系統事件內容。
- `--mode <模式>`：`now` 或 `next-heartbeat`。
- `--json`：機器可讀輸出。

## `system heartbeat last|enable|disable` (心跳控制)

- `last`：顯示最近一次的心跳事件資訊。
- `enable`：重新啟用心跳機制（若先前已被停用）。
- `disable`：暫停心跳機制。

**旗標說明**：
- `--json`：機器可讀輸出。

## `system presence` (在線狀態)

列出 Gateway 目前掌握的系統在線條目（包含節點、執行實例及類似的狀態資訊）。

**旗標說明**：
- `--json`：機器可讀輸出。

## 注意事項

- 需要一個運行中且目前配置可觸達（本地或遠端）的 Gateway。
- 系統事件是**臨時性 (Ephemeral)** 的，重啟後將不會保留。
