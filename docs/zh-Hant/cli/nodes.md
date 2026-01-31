---
title: "nodes(節點管理)"
summary: "`openclaw nodes` CLI 參考（列表、狀態、核准與調用，包含相機、畫布、螢幕等）"
read_when:
  - 正在管理已配對的節點（相機、螢幕、畫布）時
  - 需要核准配對請求或調用節點指令時
---

# `openclaw nodes`

管理已配對的節點（裝置）並調用節點功能。

相關資訊：
- 節點總覽：[節點 (Nodes)](/nodes)
- 相機節點：[相機 (Camera)](/nodes/camera)
- 圖像節點：[圖像 (Images)](/nodes/images)

**常用選項**：
- `--url`, `--token`, `--timeout`, `--json`

## 常見指令

```bash
# 列出所有配對節點
openclaw nodes list

# 僅列出目前連線中的節點
openclaw nodes list --connected

# 列出最近 24 小時內連線過的節點
openclaw nodes list --last-connected 24h

# 顯示待處理的配對請求
openclaw nodes pending

# 核准特定的配對請求
openclaw nodes approve <請求ID>

# 查看節點狀態總覽
openclaw nodes status
```

`nodes list` 會列印待處理與已配對的表格。已配對的列會包含最近一次連線的時間（Last Connect）。使用 `--connected` 可僅顯示目前連線中的節點。使用 `--last-connected <時長>`（例如 `24h`, `7d`）可依時間進行篩選。

## 調用與執行 (Invoke / run)

```bash
# 調用特定的節點指令
openclaw nodes invoke --node <ID|名稱|IP> --command <指令> --params <JSON>

# 執行節點上的系統指令 (exec 形式)
openclaw nodes run --node <ID|名稱|IP> <指令...>

# 執行原始 shell 字串
openclaw nodes run --raw "git status"

# 指定 Agent 並執行指令（套用該 Agent 的核准規則）
openclaw nodes run --agent main --node <ID|名稱|IP> --raw "git status"
```

**Invoke 旗標說明**：
- `--params <JSON>`：JSON 物件字串（預設為 `{}`）。
- `--invoke-timeout <ms>`：節點調用超時設定（預設為 `15000`）。
- `--idempotency-key <key>`：選用的冪等性金鑰。

### Exec 式預設行為

`nodes run` 反映了模型的執行行為（包含預設值與核准機制）：
- 讀取 `tools.exec.*` 配置（以及 `agents.list[].tools.exec.*` 的覆寫內容）。
- 在調用 `system.run` 前會先使用執行核准 (`exec.approval.request`) 機制。
- 若已在配置中設定 `tools.exec.node`，則可省略 `--node` 參數。
- 必須使用宣稱支援 `system.run` 的節點（例如 macOS 隨附應用程式或無頭節點主機）。

**指令旗標**：
- `--cwd <路徑>`：工作目錄。
- `--env <金鑰=數值>`：環境變數覆寫（可重複使用）。
- `--command-timeout <ms>`：指令執行超時設定。
- `--needs-screen-recording`：宣告需要螢幕錄影權限。
- `--raw <文字>`：執行 shell 字串。
- `--security <deny|allowlist|full>`：安全性等級覆寫。
