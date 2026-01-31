---
title: "Context(上下文)"
summary: "上下文：模型看到什麼、如何建構以及如何檢查"
read_when:
  - 您想了解 OpenClaw 中「上下文」的含義
  - 您正在除錯為什麼模型「知道」某些東西（或忘記了它）
  - 您想減少上下文開銷（/context、/status、/compact）
---
# Context（上下文）

「上下文」是 **OpenClaw 為一次運行發送給模型的所有內容**。它受模型的**上下文視窗**（token 限制）限制。

初學者的心智模型：
- **系統提示**（OpenClaw 建構）：規則、工具、技能列表、時間/執行時間和注入的工作區檔案。
- **對話歷史**：您的訊息 + 此會話中助手的訊息。
- **工具呼叫/結果 + 附件**：命令輸出、檔案讀取、圖片/音訊等。

上下文*不等同於*「記憶」：記憶可以儲存在磁碟上並稍後重新載入；上下文是模型當前視窗內的內容。

## 快速入門（檢查上下文）

- `/status` → 快速「我的視窗有多滿？」視圖 + 會話設定。
- `/context list` → 注入了什麼 + 粗略大小（每檔案 + 總計）。
- `/context detail` → 更深入的明細：每檔案、每工具 schema 大小、每技能條目大小和系統提示大小。
- `/usage tokens` → 在正常回覆後附加每回覆使用量頁腳。
- `/compact` → 將較舊的歷史摘要為緊湊條目以釋放視窗空間。

另請參閱：[斜線命令](/tools/slash-commands)、[Token 使用與成本](/token-use)、[壓縮](/concepts/compaction)。

## 範例輸出

值因模型、供應商、工具策略和您工作區中的內容而異。

### `/context list`

```
🧠 Context breakdown
Workspace: <workspaceDir>
Bootstrap max/file: 20,000 chars
Sandbox: mode=non-main sandboxed=false
System prompt (run): 38,412 chars (~9,603 tok) (Project Context 23,901 chars (~5,976 tok))

Injected workspace files:
- AGENTS.md: OK | raw 1,742 chars (~436 tok) | injected 1,742 chars (~436 tok)
- SOUL.md: OK | raw 912 chars (~228 tok) | injected 912 chars (~228 tok)
- TOOLS.md: TRUNCATED | raw 54,210 chars (~13,553 tok) | injected 20,962 chars (~5,241 tok)
- IDENTITY.md: OK | raw 211 chars (~53 tok) | injected 211 chars (~53 tok)
- USER.md: OK | raw 388 chars (~97 tok) | injected 388 chars (~97 tok)
- HEARTBEAT.md: MISSING | raw 0 | injected 0
- BOOTSTRAP.md: OK | raw 0 chars (~0 tok) | injected 0 chars (~0 tok)

Skills list (system prompt text): 2,184 chars (~546 tok) (12 skills)
Tools: read, edit, write, exec, process, browser, message, sessions_send, …
Tool list (system prompt text): 1,032 chars (~258 tok)
Tool schemas (JSON): 31,988 chars (~7,997 tok) (counts toward context; not shown as text)
Tools: (same as above)

Session tokens (cached): 14,250 total / ctx=32,000
```

### `/context detail`

```
🧠 Context breakdown (detailed)
…
Top skills (prompt entry size):
- frontend-design: 412 chars (~103 tok)
- oracle: 401 chars (~101 tok)
… (+10 more skills)

Top tools (schema size):
- browser: 9,812 chars (~2,453 tok)
- exec: 6,240 chars (~1,560 tok)
… (+N more tools)
```

## 什麼計入上下文視窗

模型接收的所有內容都計入，包括：
- 系統提示（所有部分）。
- 對話歷史。
- 工具呼叫 + 工具結果。
- 附件/轉錄（圖片/音訊/檔案）。
- 壓縮摘要和修剪產物。
- 供應商「包裝器」或隱藏標頭（不可見，仍然計入）。

## OpenClaw 如何建構系統提示

系統提示**由 OpenClaw 擁有**，每次運行重新建構。它包括：
- 工具列表 + 簡短描述。
- 技能列表（僅元資料；見下文）。
- 工作區位置。
- 時間（UTC + 如果設定則轉換的使用者時間）。
- 執行時間元資料（主機/作業系統/模型/思考）。
- 在**專案上下文**下注入的工作區啟動檔案。

完整明細：[系統提示](/concepts/system-prompt)。

## 注入的工作區檔案（專案上下文）

預設情況下，OpenClaw 注入一組固定的工作區檔案（如果存在）：
- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md`（僅首次運行）

大檔案使用 `agents.defaults.bootstrapMaxChars`（預設 `20000` 字元）按檔案截斷。`/context` 顯示**原始 vs 注入**大小以及是否發生截斷。

## 技能：注入了什麼 vs 按需載入

系統提示包含緊湊的**技能列表**（名稱 + 描述 + 位置）。此列表有實際開銷。

技能說明預設*不*包含。模型被期望**僅在需要時** `read` 技能的 `SKILL.md`。

## 工具：有兩種成本

工具以兩種方式影響上下文：
1) 系統提示中的**工具列表文字**（您看到的「Tooling」）。
2) **工具 schemas**（JSON）。這些發送給模型以便它可以呼叫工具。它們計入上下文，即使您不會看到它們作為純文字。

`/context detail` 分解最大的工具 schemas，以便您可以看到什麼占主導地位。

## 命令、指令和「內嵌捷徑」

斜線命令由 Gateway 處理。有幾種不同的行為：
- **獨立命令**：僅為 `/...` 的訊息作為命令運行。
- **指令**：`/think`、`/verbose`、`/reasoning`、`/elevated`、`/model`、`/queue` 在模型看到訊息之前被剝離。
  - 僅指令訊息持久化會話設定。
  - 正常訊息中的內嵌指令作為每訊息提示。
- **內嵌捷徑**（僅限允許清單發送者）：正常訊息中的某些 `/...` 令牌可以立即運行（例如：「hey /status」），並在模型看到剩餘文字之前被剝離。

詳情：[斜線命令](/tools/slash-commands)。

## 會話、壓縮和修剪（什麼持久化）

跨訊息持久化的內容取決於機制：
- **正常歷史**持久化在會話轉錄中，直到被策略壓縮/修剪。
- **壓縮**將摘要持久化到轉錄中並保持最近的訊息完整。
- **修剪**從運行的*記憶體中*提示移除舊工具結果，但不重寫轉錄。

文件：[會話](/concepts/session)、[壓縮](/concepts/compaction)、[會話修剪](/concepts/session-pruning)。

## `/context` 實際報告什麼

`/context` 在可用時偏好最新的**運行建構**系統提示報告：
- `System prompt (run)` = 從最後一次嵌入式（具工具能力）運行捕獲並持久化在會話儲存中。
- `System prompt (estimate)` = 當沒有運行報告存在時（或透過不生成報告的 CLI 後端運行時）即時計算。

無論哪種方式，它報告大小和主要貢獻者；它**不會**傾印完整的系統提示或工具 schemas。
