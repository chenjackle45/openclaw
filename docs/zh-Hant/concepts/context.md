---
title: "Context（上下文）"
summary: "上下文：模型看到什麼、如何建構以及如何檢查"
read_when:
  - 您想了解 OpenClaw 中「上下文」的含義
  - 您正在除錯模型「知道」某事（或忘記它）的原因
  - 您想減少上下文開銷（/context、/status、/compact）
---

# 上下文

「上下文」是 **OpenClaw 為一次執行傳送給模型的所有內容**。它受模型的**上下文視窗**（token 限制）限制。

初學者心智模型：

- **System prompt**（OpenClaw 建構的）：規則、工具、技能列表、時間/執行時，以及注入的工作區檔案。
- **對話歷史**：你的訊息 + 這個工作階段的助理訊息。
- **工具呼叫/結果 + 附件**：指令輸出、檔案讀取、圖片/音訊等。

上下文與「記憶體」**不同**：記憶體可以儲存在磁碟並在之後重新載入；上下文是模型當前視窗中的內容。

## 快速開始（檢查上下文）

- `/status` → 「我的視窗有多滿？」快速查看 + 工作階段設定。
- `/context list` → 注入了什麼 + 大致大小（每個檔案 + 總計）。
- `/context detail` → 更深入的分解：每個檔案、每個工具 schema 大小、每個技能條目大小，以及 system prompt 大小。
- `/usage tokens` → 在正常回覆中附加每回覆的使用量頁腳。
- `/compact` → 將較舊的歷史摘要為緊湊條目以釋放視窗空間。

另請參閱：[Slash commands](/zh-Hant/tools/slash-commands)、[Token use & costs](/zh-Hant/reference/token-use)、[Compaction](/zh-Hant/concepts/compaction)。

## 輸出範例

值因模型、provider、工具政策和工作區中的內容而異。

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

- System prompt（所有章節）。
- 對話歷史。
- 工具呼叫 + 工具結果。
- 附件/轉錄（圖片/音訊/檔案）。
- 壓縮摘要和修剪工件。
- Provider「包裝器」或隱藏標頭（不可見，但仍計算）。

## OpenClaw 如何建構 system prompt

System prompt 是 **OpenClaw 擁有**的，每次執行都重新建構。它包括：

- 工具列表 + 簡短描述。
- 技能列表（僅 metadata；見下方）。
- 工作區位置。
- 時間（UTC + 已設定時轉換的用戶時間）。
- 執行時 metadata（主機/OS/模型/思考）。
- **Project Context** 下注入的工作區 bootstrap 檔案。

完整分解：[System Prompt](/zh-Hant/concepts/system-prompt)。

## 注入的工作區檔案（Project Context）

預設情況下，OpenClaw 注入一組固定的工作區檔案（若存在）：

- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md`（僅首次執行）

使用 `agents.defaults.bootstrapMaxChars`（預設 `20000` 字元）按檔案截斷大型檔案。OpenClaw 也使用 `agents.defaults.bootstrapTotalMaxChars`（預設 `150000` 字元）對所有檔案的總 bootstrap 注入量強制執行上限。`/context` 顯示**原始 vs 注入**大小以及是否發生截斷。

當發生截斷時，執行時可以在 Project Context 下注入提示中的警告區塊。使用 `agents.defaults.bootstrapPromptTruncationWarning` 設定此項（`off`、`once`、`always`；預設 `once`）。

## 技能：什麼被注入 vs 按需載入

System prompt 包含一個緊湊的**技能列表**（名稱 + 描述 + 位置）。此列表有實際開銷。

技能指令**預設不**包含。模型預計只在需要時 `read` 技能的 `SKILL.md`。

## 工具：有兩種費用

工具以兩種方式影響上下文：

1. System prompt 中的**工具列表文字**（你看到的「Tooling」）。
2. **工具 schema**（JSON）。這些傳送給模型以便它可以呼叫工具。它們計入上下文，即使你不以純文字形式看到它們。

`/context detail` 分解最大的工具 schema，以便你可以看到什麼佔主導地位。

## 指令、指示和「內聯快捷方式」

斜線指令由 Gateway 處理。有幾種不同的行為：

- **獨立指令**：只有 `/...` 的訊息作為指令執行。
- **指示**：`/think`、`/verbose`、`/reasoning`、`/elevated`、`/model`、`/queue` 在模型看到訊息前被去除。
  - 僅指示的訊息持久化工作階段設定。
  - 普通訊息中的內聯指示作為每訊息提示。
- **內聯快捷方式**（僅限 allowlist 發送者）：普通訊息中的某些 `/...` token 可以立即執行（例如：「hey /status」），並在模型看到剩餘文字前被去除。

詳情：[Slash commands](/zh-Hant/tools/slash-commands)。

## 工作階段、壓縮和修剪（什麼持久化）

跨訊息持久化的內容取決於機制：

- **一般歷史**在工作階段轉錄中持久化，直到按政策壓縮/修剪。
- **壓縮**將摘要持久化到轉錄中，並保持最近的訊息完整。
- **修剪**從執行的*記憶體*中移除舊的工具結果，但不重寫轉錄。

文件：[Session](/zh-Hant/concepts/session)、[Compaction](/zh-Hant/concepts/compaction)、[Session pruning](/zh-Hant/concepts/session-pruning)。

預設情況下，OpenClaw 使用內建的 `legacy` 上下文引擎進行組裝和壓縮。若你安裝提供 `kind: "context-engine"` 的外掛程式並使用 `plugins.slots.contextEngine` 選擇它，OpenClaw 會將上下文組裝、`/compact` 和相關子 agent 上下文生命週期 hooks 委託給該引擎。

## `/context` 實際報告什麼

`/context` 在可用時優先使用最新的**執行時建構**的 system prompt 報告：

- `System prompt (run)` = 從最後一次嵌入式（支援工具的）執行中捕獲，並持久化在工作階段儲存中。
- `System prompt (estimate)` = 在沒有執行報告時（或透過不生成報告的 CLI 後端執行時）即時計算。

無論哪種方式，它都報告大小和最大貢獻者；它**不**轉存完整的 system prompt 或工具 schema。
