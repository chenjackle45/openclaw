---
title: "Agent(Agent Runtime 代理執行時)"
summary: "代理執行時（嵌入式 p-mono）、工作區契約和會話啟動"
read_when:
  - 更改代理執行時、工作區啟動或會話行為
---
# Agent Runtime（代理執行時） 🤖

OpenClaw 運行一個從 **p-mono** 衍生的單一嵌入式代理執行時。

## 工作區（必需）

OpenClaw 使用單一代理工作區目錄（`agents.defaults.workspace`）作為代理對工具和上下文的**唯一**工作目錄（`cwd`）。

建議：使用 `openclaw setup` 在缺失時建立 `~/.openclaw/openclaw.json` 並初始化工作區檔案。

完整工作區佈局 + 備份指南：[代理工作區](/concepts/agent-workspace)

如果 `agents.defaults.sandbox` 已啟用，非主會話可以在 `agents.defaults.sandbox.workspaceRoot` 下使用每會話工作區覆寫此設定（請參閱 [Gateway 設定](/gateway/configuration)）。

## 啟動檔案（注入）

在 `agents.defaults.workspace` 內，OpenClaw 期望這些使用者可編輯的檔案：
- `AGENTS.md` — 操作指令 + 「記憶」
- `SOUL.md` — 人格、邊界、語氣
- `TOOLS.md` — 使用者維護的工具備註（例如 `imsg`、`sag`、慣例）
- `BOOTSTRAP.md` — 一次性首次運行儀式（完成後刪除）
- `IDENTITY.md` — 代理名稱/氛圍/表情符號
- `USER.md` — 使用者設定檔 + 偏好稱呼

在新會話的第一個輪次，OpenClaw 將這些檔案的內容直接注入代理上下文。

空白檔案會被跳過。大型檔案會被修剪和截斷並帶有標記，以保持提示精簡（閱讀檔案以獲取完整內容）。

如果檔案缺失，OpenClaw 會注入單一的「缺失檔案」標記行（而 `openclaw setup` 會建立安全的預設範本）。

`BOOTSTRAP.md` 僅在 **全新工作區** 時建立（沒有其他啟動檔案存在）。如果您在完成儀式後刪除它，它不應該在稍後的重啟時被重新建立。

要完全停用啟動檔案建立（對於預先種子化的工作區），設定：

```json5
{ agent: { skipBootstrap: true } }
```

## 內建工具

核心工具（read/exec/edit/write 和相關系統工具）始終可用，受工具策略限制。`apply_patch` 是可選的，由 `tools.exec.applyPatch` 控制。`TOOLS.md` **不**控制哪些工具存在；它是關於*您*希望如何使用它們的指導。

## 技能

OpenClaw 從三個位置載入技能（工作區在名稱衝突時優先）：
- 綁定（隨安裝一起提供）
- 管理/本地：`~/.openclaw/skills`
- 工作區：`<workspace>/skills`

技能可以透過設定/env 控制（請參閱 [Gateway 設定](/gateway/configuration) 中的 `skills`）。

## p-mono 整合

OpenClaw 重用 p-mono 程式碼庫的部分（models/tools），但 **會話管理、發現和工具連接由 OpenClaw 擁有**。

- 沒有 p-coding 代理執行時。
- 不會查閱 `~/.pi/agent` 或 `<workspace>/.pi` 設定。

## 會話

會話轉錄以 JSONL 格式儲存於：
- `~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`

會話 ID 是穩定的，由 OpenClaw 選擇。
舊版 Pi/Tau 會話資料夾**不**會被讀取。

## 串流時的引導

當佇列模式為 `steer` 時，入站訊息會被注入當前運行。佇列在**每次工具呼叫後**檢查；如果存在排隊的訊息，當前助手訊息的剩餘工具呼叫會被跳過（錯誤工具結果為「因排隊的使用者訊息而跳過。」），然後排隊的使用者訊息會在下一個助手回應之前被注入。

當佇列模式為 `followup` 或 `collect` 時，入站訊息會被保留直到當前輪次結束，然後新的代理輪次會以排隊的負載開始。請參閱 [佇列](/concepts/queue) 了解模式 + 防抖/上限行為。

區塊串流在完成後立即發送完成的助手區塊；它**預設關閉**（`agents.defaults.blockStreamingDefault: "off"`）。
透過 `agents.defaults.blockStreamingBreak` 調整邊界（`text_end` vs `message_end`；預設為 text_end）。
使用 `agents.defaults.blockStreamingChunk` 控制軟區塊分塊（預設為 800-1200 字元；偏好段落斷行，然後換行；句子最後）。
使用 `agents.defaults.blockStreamingCoalesce` 合併串流區塊以減少單行垃圾訊息（發送前基於閒置的合併）。非 Telegram 頻道需要明確的 `*.blockStreaming: true` 來啟用區塊回覆。
詳細工具摘要在工具啟動時發出（無防抖）；Control UI 在可用時透過代理事件串流工具輸出。
更多詳情：[串流 + 分塊](/concepts/streaming)。

## 模型參考

設定中的模型參考（例如 `agents.defaults.model` 和 `agents.defaults.models`）透過在**第一個** `/` 處分割來解析。

- 設定模型時使用 `provider/model`。
- 如果模型 ID 本身包含 `/`（OpenRouter 風格），請包含供應商前綴（例如：`openrouter/moonshotai/kimi-k2`）。
- 如果您省略供應商，OpenClaw 會將輸入視為別名或**預設供應商**的模型（僅當模型 ID 中沒有 `/` 時有效）。

## 設定（最小）

至少設定：
- `agents.defaults.workspace`
- `channels.whatsapp.allowFrom`（強烈建議）

---

*下一步：[群組聊天](/concepts/group-messages)* 🦞
