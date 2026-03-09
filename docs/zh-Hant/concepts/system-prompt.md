---
title: "System Prompt（系統提示詞）"
summary: "OpenClaw 系統提示詞包含什麼以及如何組裝"
read_when:
  - 編輯系統提示詞文字、工具列表或時間/心跳部分
  - 變更工作區 bootstrap 或技能注入行為
---

# System Prompt

OpenClaw 為每次 agent 執行建構自訂 system prompt。此 prompt 由 **OpenClaw 擁有**，不使用 pi-coding-agent 的預設 prompt。

Prompt 由 OpenClaw 組裝並注入每次 agent 執行。

## 結構

Prompt 刻意保持緊湊並使用固定章節：

- **Tooling**：當前工具列表 + 簡短描述。
- **Safety**：短暫的護欄提醒，避免尋求權力的行為或繞過監督。
- **Skills**（可用時）：告知模型如何按需載入技能說明。
- **OpenClaw Self-Update**：如何執行 `config.apply` 和 `update.run`。
- **Workspace**：工作目錄（`agents.defaults.workspace`）。
- **Documentation**：OpenClaw 文件的本地路徑（repo 或 npm 套件）以及何時讀取。
- **Workspace Files（注入的）**：指示下方包含 bootstrap 檔案。
- **Sandbox**（啟用時）：指示沙盒執行時、沙盒路徑以及是否可使用提升的 exec。
- **Current Date & Time**：用戶本地時間、時區和時間格式。
- **Reply Tags**：支援供應商的選用回覆標籤語法。
- **Heartbeats**：心跳 prompt 和確認行為。
- **Runtime**：主機、OS、node、模型、repo 根目錄（偵測到時）、thinking 層級（一行）。
- **Reasoning**：當前可見性層級 + /reasoning 切換提示。

System prompt 中的安全護欄是建議性的。它們指導模型行為但不強制執行政策。使用工具政策、exec 核准、沙盒和頻道 allowlist 進行硬性執行；操作者可依設計停用這些。

## Prompt 模式

OpenClaw 可以為子 agent 渲染較小的 system prompt。執行時為每次執行設定 `promptMode`（不是用戶端設定）：

- `full`（預設）：包含上述所有章節。
- `minimal`：用於子 agent；省略 **Skills**、**Memory Recall**、**OpenClaw
  Self-Update**、**Model Aliases**、**User Identity**、**Reply Tags**、
  **Messaging**、**Silent Replies** 和 **Heartbeats**。Tooling、**Safety**、
  Workspace、Sandbox、Current Date & Time（已知時）、Runtime 和注入的
  上下文仍然可用。
- `none`：僅返回基礎身份行。

當 `promptMode=minimal` 時，額外注入的 prompt 標記為 **Subagent
Context** 而非 **Group Chat Context**。

## 工作區 bootstrap 注入

Bootstrap 檔案被修剪並附加在 **Project Context** 下，讓模型在不需要明確讀取的情況下看到身份和設定檔上下文：

- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md`（僅限全新工作區）
- `MEMORY.md` 和/或 `memory.md`（工作區中存在時；任一或兩者都可能被注入）

所有這些檔案在**每次輪次都注入到上下文視窗中**，
這意味著它們消耗 token。保持簡潔——尤其是 `MEMORY.md`，它可能隨時間增長並導致意外的高上下文使用量和更頻繁的壓縮。

> **注意：** `memory/*.md` 每日檔案**不會**自動注入。它們
> 透過 `memory_search` 和 `memory_get` 工具按需存取，因此
> 除非模型明確讀取，否則不計入上下文視窗。

大型檔案以標記截斷。每個檔案的最大大小由
`agents.defaults.bootstrapMaxChars`（預設：20000）控制。所有檔案的總注入 bootstrap 內容以 `agents.defaults.bootstrapTotalMaxChars`
（預設：150000）為上限。缺失的檔案注入短暫的缺失檔案標記。當發生截斷時，OpenClaw 可在 Project Context 中注入警告區塊；使用 `agents.defaults.bootstrapPromptTruncationWarning` 控制（`off`、`once`、`always`；
預設：`once`）。

子 agent 工作階段只注入 `AGENTS.md` 和 `TOOLS.md`（其他 bootstrap 檔案被過濾以保持子 agent 上下文小）。

內部 hooks 可透過 `agent:bootstrap` 攔截此步驟以修改或替換注入的 bootstrap 檔案（例如將 `SOUL.md` 替換為備用角色設定）。

要檢查每個注入檔案的貢獻量（原始 vs 注入、截斷以及工具 schema 開銷），使用 `/context list` 或 `/context detail`。見 [Context](/zh-Hant/concepts/context)。

## 時間處理

System prompt 在用戶時區已知時包含專用的 **Current Date & Time** 章節。為保持 prompt 快取穩定，現在只包含**時區**（不含動態時鐘或時間格式）。

需要當前時間時使用 `session_status`；狀態卡包含時間戳行。

設定方式：

- `agents.defaults.userTimezone`
- `agents.defaults.timeFormat`（`auto` | `12` | `24`）

完整行為詳情見 [Date & Time](/zh-Hant/date-time)。

## 技能

當存在符合條件的技能時，OpenClaw 注入緊湊的**可用技能列表**
（`formatSkillsForPrompt`），包含每個技能的**檔案路徑**。Prompt 指示模型使用 `read` 載入列出位置（工作區、managed 或捆綁）的 SKILL.md。若沒有符合條件的技能，Skills 章節被省略。

```
<available_skills>
  <skill>
    <name>...</name>
    <description>...</description>
    <location>...</location>
  </skill>
</available_skills>
```

這在仍能按需啟用技能的情況下保持基礎 prompt 小巧。

## Documentation

可用時，system prompt 包含 **Documentation** 章節，指向本地 OpenClaw 文件目錄（repo 工作區中的 `docs/` 或捆綁的 npm 套件文件），並指出公共鏡像、原始碼 repo、社群 Discord 和 ClawHub（[https://clawhub.com](https://clawhub.com)）以供技能探索。Prompt 指示模型在詢問 OpenClaw 行為、指令、設定或架構時優先參考本地文件，並在可能時自行執行 `openclaw status`（只在無法存取時才詢問用戶）。
