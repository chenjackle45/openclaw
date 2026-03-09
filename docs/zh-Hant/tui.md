---
summary: "Terminal UI（TUI）：從任何機器連線至 Gateway"
read_when:
  - 想要 TUI 的入門友善教學
  - 需要 TUI 功能、指令與快捷鍵的完整清單
title: "TUI（終端介面）"
---

# TUI（Terminal UI）

## 快速開始

1. 啟動 Gateway。

```bash
openclaw gateway
```

2. 開啟 TUI。

```bash
openclaw tui
```

3. 輸入訊息並按 Enter。

遠端 Gateway：

```bash
openclaw tui --url ws://<host>:<port> --token <gateway-token>
```

若 Gateway 使用密碼驗證，請使用 `--password`。

## 畫面說明

- Header：連線 URL、目前 agent、目前 session。
- 聊天記錄：使用者訊息、助理回覆、系統通知、工具卡片。
- 狀態列：連線/執行狀態（connecting、running、streaming、idle、error）。
- Footer：連線狀態 + agent + session + 模型 + think/verbose/reasoning + token 計數 + deliver。
- 輸入：具有自動完成功能的文字編輯器。

## 心智模型：agents + sessions

- Agents 是唯一的 slug（例如 `main`、`research`）。Gateway 公開清單。
- Sessions 屬於目前 agent。
- Session 鍵儲存為 `agent:<agentId>:<sessionKey>`。
  - 若你輸入 `/session main`，TUI 會展開為 `agent:<currentAgent>:main`。
  - 若你輸入 `/session agent:other:main`，會明確切換至該 agent session。
- Session 範圍：
  - `per-sender`（預設）：每個 agent 有多個 session。
  - `global`：TUI 總是使用 `global` session（選擇器可能為空）。
- 目前的 agent + session 始終顯示在 footer。

## 傳送 + 傳遞

- 訊息傳送至 Gateway；預設傳遞至提供商為關閉狀態。
- 開啟傳遞：
  - `/deliver on`
  - 或 Settings 面板
  - 或以 `openclaw tui --deliver` 啟動

## 選擇器 + 疊加層

- Model picker：列出可用模型並設定 session 覆蓋。
- Agent picker：選擇不同的 agent。
- Session picker：僅顯示目前 agent 的 session。
- Settings：切換 deliver、工具輸出展開與思考可見性。

## 鍵盤快捷鍵

- Enter：傳送訊息
- Esc：中止活躍執行
- Ctrl+C：清除輸入（按兩次退出）
- Ctrl+D：退出
- Ctrl+L：model picker
- Ctrl+G：agent picker
- Ctrl+P：session picker
- Ctrl+O：切換工具輸出展開
- Ctrl+T：切換思考可見性（重新載入歷程）

## 斜線指令

核心：

- `/help`
- `/status`
- `/agent <id>`（或 `/agents`）
- `/session <key>`（或 `/sessions`）
- `/model <provider/model>`（或 `/models`）

Session 控制：

- `/think <off|minimal|low|medium|high>`
- `/verbose <on|full|off>`
- `/reasoning <on|off|stream>`
- `/usage <off|tokens|full>`
- `/elevated <on|off|ask|full>`（別名：`/elev`）
- `/activation <mention|always>`
- `/deliver <on|off>`

Session 生命週期：

- `/new` 或 `/reset`（重設 session）
- `/abort`（中止活躍執行）
- `/settings`
- `/exit`

其他 Gateway 斜線指令（例如 `/context`）會轉發至 Gateway 並顯示為系統輸出。請見 [斜線指令](/zh-Hant/tools/slash-commands)。

## 本地 shell 指令

- 在行首加上 `!` 以在 TUI 主機上執行本地 shell 指令。
- TUI 每個 session 提示一次以允許本地執行；拒絕會使該 session 的 `!` 保持停用。
- 指令在 TUI 工作目錄的全新非互動式 shell 中執行（無持久的 `cd`/env）。
- 本地 shell 指令在環境中接收 `OPENCLAW_SHELL=tui-local`。
- 單獨的 `!` 作為正常訊息傳送；前導空格不會觸發本地執行。

## 工具輸出

- 工具呼叫顯示為包含 args + 結果的卡片。
- Ctrl+O 在摺疊/展開視圖之間切換。
- 工具執行時，部分更新串流至同一張卡片。

## 終端顏色

- TUI 將助理本文保持為你終端的預設前景色，使深色與淺色終端都保持可讀。
- 若你的終端使用淺色背景且自動偵測有誤，請在啟動 `openclaw tui` 前設定 `OPENCLAW_THEME=light`。
- 若要強制使用原本的深色調色盤，請設定 `OPENCLAW_THEME=dark`。

## 歷程 + 串流

- 連線時，TUI 載入最新的歷程（預設 200 則訊息）。
- 串流回應會原地更新直到完成。
- TUI 也監聽 agent 工具事件以獲得更豐富的工具卡片。

## 連線詳情

- TUI 以 `mode: "tui"` 向 Gateway 註冊。
- 重新連線顯示系統訊息；事件間隙會顯示在記錄中。

## 選項

- `--url <url>`：Gateway WebSocket URL（預設為設定或 `ws://127.0.0.1:<port>`）
- `--token <token>`：Gateway token（若需要）
- `--password <password>`：Gateway 密碼（若需要）
- `--session <key>`：Session 鍵（預設：`main`，或在範圍為 global 時為 `global`）
- `--deliver`：將助理回覆傳遞至提供商（預設關閉）
- `--thinking <level>`：覆蓋傳送的思考層級
- `--timeout-ms <ms>`：Agent 逾時（毫秒）（預設為 `agents.defaults.timeoutSeconds`）

注意：設定 `--url` 時，TUI 不會退回至設定或環境憑證。請明確傳入 `--token` 或 `--password`。缺少明確憑證會被視為錯誤。

## 疑難排解

傳送訊息後沒有輸出：

- 在 TUI 中執行 `/status` 以確認 Gateway 已連線且處於閒置/忙碌狀態。
- 檢查 Gateway 記錄：`openclaw logs --follow`。
- 確認 agent 可以執行：`openclaw status` 和 `openclaw models status`。
- 若期望在聊天頻道中看到訊息，請啟用傳遞（`/deliver on` 或 `--deliver`）。
- `--history-limit <n>`：要載入的歷程條目（預設 200）

## 連線疑難排解

- `disconnected`：確認 Gateway 正在執行且你的 `--url/--token/--password` 正確。
- 選擇器中沒有 agent：檢查 `openclaw agents list` 和你的路由設定。
- Session 選擇器為空：可能處於 global 範圍或尚未有 session。
