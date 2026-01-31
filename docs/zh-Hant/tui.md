---
title: "Tui(終端介面)"
summary: "終端介面 (TUI)：從任何機器連接到 Gateway"
read_when:
  - 您想要 TUI 的初學者友善指南
  - 您需要 TUI 功能、指令和快捷鍵的完整列表
---
# TUI (Terminal UI)(終端介面)

## 快速開始
1) 啟動 Gateway。
```bash
openclaw gateway
```
2) 開啟 TUI。
```bash
openclaw tui
```
3) 輸入訊息並按 Enter。

遠端 Gateway：
```bash
openclaw tui --url ws://<host>:<port> --token <gateway-token>
```
如果您的 Gateway 使用密碼認證，請使用 `--password`。

## 您會看到什麼
- Header：連線 URL、當前代理、當前會話。
- Chat log：使用者訊息、助理回覆、系統通知、工具卡片。
- Status line：連線/執行狀態（連線中、執行中、串流中、閒置、錯誤）。
- Footer：連線狀態 + 代理 + 會話 + 模型 + think/verbose/reasoning + token 計數 + deliver。
- Input：具有自動完成功能的文字編輯器。

## 心智模型：agents + sessions
- Agents 是唯一的 slugs（例如 `main`、`research`）。Gateway 公開清單。
- Sessions 屬於當前代理。
- Session 鍵儲存為 `agent:<agentId>:<sessionKey>`。
  - 如果您輸入 `/session main`，TUI 會將其展開為 `agent:<currentAgent>:main`。
  - 如果您輸入 `/session agent:other:main`，您可以明確切換到該代理會話。
- Session 範圍：
  - `per-sender`（預設）：每個代理有許多會話。
  - `global`：TUI 總是使用 `global` 會話（選擇器可能為空）。
- 當前代理 + 會話始終在 footer 中可見。

## 發送 + 傳遞
- 訊息發送到 Gateway；預設情況下傳遞到供應商是關閉的。
- 開啟傳遞：
  - `/deliver on`
  - 或 Settings 面板
  - 或使用 `openclaw tui --deliver` 啟動

## 選擇器 + 疊加層
- Model picker：列出可用模型並設定會話覆蓋。
- Agent picker：選擇不同的代理。
- Session picker：僅顯示當前代理的會話。
- Settings：切換 deliver、工具輸出展開和思考可見性。

## 鍵盤快捷鍵
- Enter：發送訊息
- Esc：中止活動執行
- Ctrl+C：清除輸入（按兩次退出）
- Ctrl+D：退出
- Ctrl+L：model picker
- Ctrl+G：agent picker
- Ctrl+P：session picker
- Ctrl+O：切換工具輸出展開
- Ctrl+T：切換思考可見性（重新載入歷史）

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
- `/new` 或 `/reset`（重設會話）
- `/abort`（中止活動執行）
- `/settings`
- `/exit`

其他 Gateway 斜線指令（例如 `/context`）會轉發到 Gateway 並顯示為系統輸出。請參閱 [Slash commands](/tools/slash-commands)。

## 本地 shell 指令
- 在行首加上 `!` 以在 TUI 主機上執行本地 shell 指令。
- TUI 每個會話提示一次以允許本地執行；拒絕會使該會話的 `!` 保持停用。
- 指令在 TUI 工作目錄的全新非互動式 shell 中執行（沒有持久的 `cd`/env）。
- 單獨的 `!` 作為正常訊息發送；前導空格不會觸發本地執行。

## 工具輸出
- 工具呼叫顯示為包含 args + 結果的卡片。
- Ctrl+O 在摺疊/展開視圖之間切換。
- 當工具執行時，部分更新串流到同一張卡片。

## 歷史 + 串流
- 連接時，TUI 載入最新的歷史（預設 200 則訊息）。
- 串流回應會原地更新直到完成。
- TUI 也監聽代理工具事件以獲得更豐富的工具卡片。

## 連線詳情
- TUI 以 `mode: "tui"` 向 Gateway 註冊。
- 重新連線顯示系統訊息；事件間隙在日誌中顯示。

## 選項
- `--url <url>`：Gateway WebSocket URL（預設為設定或 `ws://127.0.0.1:<port>`）
- `--token <token>`：Gateway token（如果需要）
- `--password <password>`：Gateway 密碼（如果需要）
- `--session <key>`：Session 鍵（預設：`main`，或在範圍為 global 時為 `global`）
- `--deliver`：將助理回覆傳遞給供應商（預設關閉）
- `--thinking <level>`：覆蓋發送的思考層級
- `--timeout-ms <ms>`：代理超時（毫秒）（預設為 `agents.defaults.timeoutSeconds`）
- `--history-limit <n>`：要載入的歷史條目（預設 200）

## 疑難排解

發送訊息後沒有輸出：
- 在 TUI 中執行 `/status` 以確認 Gateway 已連接且處於閒置/忙碌狀態。
- 檢查 Gateway 日誌：`openclaw logs --follow`。
- 確認代理可以執行：`openclaw status` 和 `openclaw models status`。
- 如果您期望聊天頻道中的訊息，請啟用傳遞（`/deliver on` 或 `--deliver`）。

其他問題：
- `disconnected`：確保 Gateway 正在執行且您的 `--url/--token/--password` 正確。
- 選擇器中沒有代理：檢查 `openclaw agents list` 和您的路由設定。
- 會話選擇器為空：您可能處於 global 範圍或尚未有會話。
