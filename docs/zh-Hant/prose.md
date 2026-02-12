---
summary: "OpenProse：.prose 工作流程、斜線命令和 OpenClaw 中的狀態"
read_when:
  - 你想執行或編寫 .prose 工作流程
  - 你想啟用 OpenProse 外掛程式
  - 你需要了解狀態存儲
title: "OpenProse（OpenProse）"
---

# OpenProse

OpenProse 是一個便攜式、markdown 優先的工作流程格式，用於協調 AI 會話。在 OpenClaw 中，它作為外掛程式出現，安裝 OpenProse 技能套件加上 `/prose` 斜線命令。程式存在於 `.prose` 檔案中，可以生成多個具有明確控制流程的子 Agent。

官方網站：[https://www.prose.md](https://www.prose.md)

## 它能做什麼

- 具有明確並行性的多 Agent 研究 + 合成。
- 可重複的核准安全工作流程（程式碼審查、事件分類、內容管道）。
- 你可以在支援的 Agent 執行時期間執行的可重複使用 `.prose` 程式。

## 安裝和啟用

打包外掛程式預設為停用。啟用 OpenProse：

```bash
openclaw plugins enable open-prose
```

啟用外掛程式後重新啟動 Gateway。

開發/本機檢出：`openclaw plugins install ./extensions/open-prose`

相關文件：[外掛程式](/zh-Hant/tools/plugin)、[外掛程式清單](/zh-Hant/plugins/manifest)、[技能](/zh-Hant/tools/skills)。

## 斜線命令

OpenProse 將 `/prose` 註冊為使用者可呼叫的技能命令。它路由到 OpenProse VM 指令，並在後台使用 OpenClaw 工具。

常見命令：

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
# 以兩個並行執行的 Agent 進行研究 + 合成。

input topic: "我們應該研究什麼？"

agent researcher:
  model: sonnet
  prompt: "你徹底研究並引用來源。"

agent writer:
  model: opus
  prompt: "你編寫一個簡明摘要。"

parallel:
  findings = session: researcher
    prompt: "研究 {topic}。"
  draft = session: writer
    prompt: "摘要 {topic}。"

session "將調查結果 + 草稿合併為最終答案。"
context: { findings, draft }
```

## 檔案位置

OpenProse 在工作區中的 `.prose/` 下保留狀態：

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

使用者級別的持久 Agent 位於：

```
~/.prose/agents/
```

## 狀態模式

OpenProse 支援多個狀態後端：

- **filesystem**（預設）：`.prose/runs/...`
- **in-context**：暫時，用於小型程式
- **sqlite**（實驗性）：需要 `sqlite3` 二進位檔
- **postgres**（實驗性）：需要 `psql` 和連接字串

注意事項：

- sqlite/postgres 是選擇性和實驗性的。
- postgres 認證流入子 Agent 日誌；使用專用、最少權限的 DB。

## 遠端程式

`/prose run <handle/slug>` 解析為 `https://p.prose.md/<handle>/<slug>`。
直接 URL 按原樣提取。這使用 `web_fetch` 工具（或 `exec` 用於 POST）。

## OpenClaw 執行時期間對應

OpenProse 程式對應至 OpenClaw 基元：

| OpenProse 概念       | OpenClaw 工具    |
| -------------------- | ---------------- |
| 生成會話 / Task 工具 | `sessions_spawn` |
| 檔案讀取/寫入        | `read` / `write` |
| Web 擷取             | `web_fetch`      |

如果工具允許清單阻止這些工具，OpenProse 程式將失敗。詳見[技能設定](/zh-Hant/tools/skills-config)。

## 安全和核准

將 `.prose` 檔案當作程式碼對待。執行前檢查。使用 OpenClaw 工具允許清單和核准門來控制副作用。

對於決定性、核准閘道的工作流程，與[Lobster](/zh-Hant/tools/lobster)比較。
