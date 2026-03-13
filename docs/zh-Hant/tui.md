---
title: "TUI（終端 UI）"
summary: "終端 UI（TUI）：從任何機器連接到 Gateway"
read_when:
  - 您想要初學者友善的 TUI 逐步講解
  - 您需要完整的 TUI 功能、命令和快速鍵清單
---

# TUI（終端 UI）

## 快速開始

1. 啟動 Gateway。

```bash
openclaw gateway
```

2. 開啟 TUI。

```bash
openclaw tui
```

3. 鍵入訊息並按 Enter。

遠端 Gateway：

```bash
openclaw tui --url ws://<host>:<port> --token <gateway-token>
```

如果您的 Gateway 使用密碼驗證，使用 `--password`。

## 您看到的內容

- 標頭：連接 URL、目前代理、目前工作階段。
- 聊天記錄：使用者訊息、助理回覆、系統通知、工具卡。
- 狀態行：連接／執行狀態（連接中、執行中、串流中、閒置、錯誤）。
- 頁腳：連接狀態 + 代理 + 工作階段 + 模型 + 思考／快速／詳細／推理 + 令牌計數 + 傳遞。
- 輸入：具有自動完成的文字編輯器。

## 心智模型：代理 + 工作階段

- 代理是唯一 slug（例如 `main`、`research`）。Gateway 公開清單。
- 工作階段屬於目前代理。
- 工作階段金鑰儲存為 `agent:<agentId>:<sessionKey>`。
  - 如果您鍵入 `/session main`，TUI 將其展開為 `agent:<currentAgent>:main`。
  - 如果您鍵入 `/session agent:other:main`，您明確切換到該代理工作階段。
- 工作階段範圍：
  - `per-sender`（預設）：每個代理有許多工作階段。
  - `global`：TUI 始終使用 `global` 工作階段（挑選器可能為空）。
- 目前代理 + 工作階段始終在頁腳中可見。

## 傳送 + 傳遞

- 訊息傳送到 Gateway；傳遞到提供者預設為關閉。
- 開啟傳遞：
  - `/deliver on`
  - 或設定面板
  - 或使用 `openclaw tui --deliver` 啟動

## 挑選器 + 覆蓋

- 模型挑選器：列出可用模型並設定工作階段覆寫。
- 代理挑選器：選擇不同代理。
- 工作階段挑選器：僅顯示目前代理的工作階段。
- 設定：切換傳遞、工具輸出展開和思考可見性。

## 鍵盤快速鍵

- Enter：傳送訊息
- Esc：停止作用中執行
- Ctrl+C：清除輸入（按兩次以結束）
- Ctrl+D：結束
- Ctrl+L：模型挑選器
- Ctrl+G：代理挑選器
- Ctrl+P：工作階段挑選器
- Ctrl+O：切換工具輸出展開
- Ctrl+T：切換思考可見性（重新載入歷史記錄）

## 斜線命令

核心：

- `/help`
- `/status`
- `/agent <id>`（或 `/agents`）
- `/session <key>`（或 `/sessions`）
- `/model <provider/model>`（或 `/models`）

工作階段控制：

- `/think <off|minimal|low|medium|high>`
- `/fast <status|on|off>`
- `/verbose <on|full|off>`
- `/reasoning <on|off|stream>`
- `/usage <off|tokens|full>`
- `/elevated <on|off|ask|full>`（別名：`/elev`）
- `/activation <mention|always>`
- `/deliver <on|off>`

工作階段生命週期：

- `/new` 或 `/reset`（重設工作階段）
- `/abort`（停止作用中執行）
- `/settings`
- `/exit`

其他 Gateway 斜線命令（例如 `/context`）轉發到 Gateway 並顯示為系統輸出。參閱 [斜線命令](/zh-Hant/tools/slash-commands)。

## 本地 shell 命令

- 使用 `!` 前綴行在 TUI 主機上執行本地 shell 命令。
- TUI 每個工作階段提示一次以允許本地執行；拒絕使 `!` 針對工作階段停用。
- 命令在 TUI 工作目錄中的全新非互動 shell 中執行（無持續 `cd`／env）。
- 本地 shell 命令在其環境中接收 `OPENCLAW_SHELL=tui-local`。
- 單一 `!` 作為普通訊息傳送；開頭空格不觸發本地 exec。

## 工具輸出

- 工具呼叫顯示為帶引數 + 結果的卡。
- Ctrl+O 在折疊／展開檢視之間切換。
- 當工具執行時，部分更新串流進同一卡。

## 終端顏色

- TUI 將助理正文文字保持在您的終端預設前景中，讓深色和淺色終端保持可讀。
- 如果您的終端使用淺色背景且自動偵測錯誤，在啟動 `openclaw tui` 前設定 `OPENCLAW_THEME=light`。
- 強制原始深色調色板，設定 `OPENCLAW_THEME=dark`。

## 歷史 + 串流

- 連接時，TUI 載入最新歷史（預設 200 條訊息）。
- 串流回應在原處更新直到最終化。
- TUI 也聆聽代理工具事件以取得更豐富的工具卡。

## 連接詳細資料

- TUI 向 Gateway 登錄為 `mode: "tui"`。
- 重新連接顯示系統訊息；事件間隙在日誌中出現。

## 選項

- `--url <url>`：Gateway WebSocket URL（預設為設定或 `ws://127.0.0.1:<port>`）
- `--token <token>`：Gateway 令牌（如果需要）
- `--password <password>`：Gateway 密碼（如果需要）
- `--session <key>`：工作階段金鑰（預設：`main`，或全域範圍時 `global`）
- `--deliver`：傳遞助理回覆到提供者（預設關閉）
- `--thinking <level>`：覆寫傳送的思考層級
- `--timeout-ms <ms>`：代理逾時（毫秒）（預設為 `agents.defaults.timeoutSeconds`）

備註：當您設定 `--url` 時，TUI 不會回退到設定或環境認證。明確傳遞 `--token` 或 `--password`。遺留明確認證是錯誤。

## 故障排除

傳送訊息後沒有輸出：

- 在 TUI 中執行 `/status` 以確認 Gateway 已連接且閒置／忙碌。
- 檢查 Gateway 記錄：`openclaw logs --follow`。
- 確認代理可以執行：`openclaw status` 和 `openclaw models status`。
- 如果您期望聊天頻道中的訊息，啟用傳遞（`/deliver on` 或 `--deliver`）。
- `--history-limit <n>`：載入的歷史條目（預設 200）

## 連接故障排除

- `disconnected`：確保 Gateway 執行中且您的 `--url/--token/--password` 正確。
- 挑選器中沒有代理：檢查 `openclaw agents list` 和您的路由設定。
- 空工作階段挑選器：您可能在全域範圍中或還沒有工作階段。
