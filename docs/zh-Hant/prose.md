---
title: "Prose(OpenProse)"
summary: "OpenProse：.prose 工作流程、斜線指令以及 OpenClaw 中的狀態"
read_when:
  - 您想要執行或編寫 .prose 工作流程
  - 您想要啟用 OpenProse 外掛
  - 您需要了解狀態儲存
---
# OpenProse

OpenProse 是一種可攜式、以 markdown 為優先的工作流程格式，用於編排 AI 會話。在 OpenClaw 中，它作為外掛提供，安裝 OpenProse 技能包和 `/prose` 斜線指令。程式存放在 `.prose` 檔案中，可以使用明確的控制流程產生多個 sub-agents。

官方網站：https://www.prose.md

## 它可以做什麼

- 具有明確平行處理的多代理研究 + 綜合。
- 可重複的批准安全工作流程（程式碼審查、事件分類、內容管道）。
- 可重複使用的 `.prose` 程式，您可以在支援的代理執行時中執行。

## 安裝 + 啟用

預設情況下，捆綁外掛是停用的。啟用 OpenProse：

```bash
openclaw plugins enable open-prose
```

啟用外掛後重新啟動 Gateway。

開發/本地檢出：`openclaw plugins install ./extensions/open-prose`

相關文件：[Plugins](/plugin)、[Plugin manifest](/plugins/manifest)、[Skills](/tools/skills)。

## 斜線指令

OpenProse 註冊 `/prose` 作為使用者可調用的技能指令。它路由到 OpenProse VM 指令並在底層使用 OpenClaw 工具。

常見指令：

```
/prose help
/prose run <file.prose>
/prose run <handle/slug>
/prose run <https://example.com/file.prose>
/prose compile <file.prose>
/prose examples
/prose update
```

## 範例：一個簡單的 `.prose` 檔案

```prose
# 使用兩個平行執行的代理進行研究 + 綜合。

input topic: "What should we research?"

agent researcher:
  model: sonnet
  prompt: "You research thoroughly and cite sources."

agent writer:
  model: opus
  prompt: "You write a concise summary."

parallel:
  findings = session: researcher
    prompt: "Research {topic}."
  draft = session: writer
    prompt: "Summarize {topic}."

session "Merge the findings + draft into a final answer."
context: { findings, draft }
```

## 檔案位置

OpenProse 將狀態保存在工作區的 `.prose/` 下：

```
.prose/
├── .env
├── runs/
│   └── {YYYYMMDD}-{HHMMSS}-{random}/
│       ├── program.prose
│       ├── state.md
│       ├── bindings/
│       └── agents/
└── agents/
```

使用者層級的持久代理位於：

```
~/.prose/agents/
```

## 狀態模式

OpenProse 支援多種狀態後端：

- **filesystem**（預設）：`.prose/runs/...`
- **in-context**：暫時性的，適用於小型程式
- **sqlite**（實驗性）：需要 `sqlite3` 二進位檔
- **postgres**（實驗性）：需要 `psql` 和連線字串

注意事項：
- sqlite/postgres 是選用的並且是實驗性的。
- postgres 憑證流入 subagent 日誌；使用專用的、最小特權的資料庫。

## 遠端程式

`/prose run <handle/slug>` 解析為 `https://p.prose.md/<handle>/<slug>`。
直接 URL 會按原樣獲取。這使用 `web_fetch` 工具（或用於 POST 的 `exec`）。

## OpenClaw 執行時對應

OpenProse 程式對應到 OpenClaw 基本元件：

| OpenProse 概念 | OpenClaw 工具 |
| --- | --- |
| Spawn session / Task tool | `sessions_spawn` |
| File read/write | `read` / `write` |
| Web fetch | `web_fetch` |

如果您的工具允許清單阻止這些工具，OpenProse 程式將失敗。請參閱 [Skills config](/tools/skills-config)。

## 安全性 + 核准

將 `.prose` 檔案視為程式碼。執行前請先審查。使用 OpenClaw 工具允許清單和核准閘道來控制副作用。

對於確定性的、批准門控的工作流程，與 [Lobster](/tools/lobster) 比較。
