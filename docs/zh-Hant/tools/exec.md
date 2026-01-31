---
title: "Exec(執行工具)"
summary: "執行工具的使用方式、標準輸入 (Stdin) 模式與 TTY 支援說明"
read_when:
  - 使用或修改執行工具時
  - 偵錯標準輸入 (Stdin) 或 TTY 行為時
---

# 執行工具 (Exec tool)

在工作區執行 shell 指令。支援透由 `process` 工具進行前台與背景執行。如果 Agent 不具備 `process` 工具權限，則 `exec` 將一律採同步方式執行。

## 參數定義
- `command`：要執行的指令（必要）。
- `yieldMs`：在指定毫秒後自動轉入背景（預設 10000）。
- `background`：立即轉入背景。
- `pty`：是否在虛擬終端 (Pseudo-terminal) 中執行，適用於需要 TTY 的 CLI 或 TUI。
- `host`：執行位置，可選擇 `sandbox`（沙盒，預設）、`gateway`（宿主機）或 `node`（其它節點）。
- `security`：安全模式，包含 `deny`、`allowlist`（允許清單）或 `full`（無限制）。
- `ask`：核准請求模式，包含 `off`、`on-miss`（未匹配則詢問）或 `always`（一律詢問）。
- `elevated`：是否要求提權執行。

## 執行位置說明
- **宿主機 (Gateway)**：預設情況下，沙盒功能是**關閉**的，因此 `host=sandbox` 會直接執行在宿主機上且無需核准。若要強制執行核准，請啟用沙盒或設定 `host=gateway`。
- **節點 (Node)**：指向已配對的節點。
- **執行核准**：受 `~/.openclaw/exec-approvals.json` 中的規則控制。

## 配置說明 (`openclaw.json`)
- `tools.exec.host`：預設執行位置。
- `tools.exec.pathPrepend`：要預掛載至 `PATH` 前方的目錄列表。
- `tools.exec.safeBins`：定義無需允許清單即可執行的「安全」執行檔（僅限無副作用指令）。

## 會話級別覆寫 (`/exec`)
您可以使用 `/exec` 指令來調整當前會話的執行參數，例如：
```
/exec host=gateway security=allowlist ask=on-miss
```
發送不帶參數的 `/exec` 可以查看當前設定。

## 執行核准機制
當 Agent 執行於沙盒中且嘗試在宿主機或節點執行敏感指令時，會觸發核准流程。工具會立即回傳 `status: "approval-pending"` 與編號。使用者核准後，Agent 會收到執行結果。

## 操作範例
### 背景執行與輪詢：
```json
{"tool":"exec","command":"npm run build","yieldMs":1000}
{"tool":"process","action":"poll","sessionId":"會話ID"}
```

### 發送特定鍵位 (Tmux 風格)：
```json
{"tool":"process","action":"send-keys","sessionId":"ID","keys":["C-c"]}
{"tool":"process","action":"send-keys","sessionId":"ID","keys":["Up","Enter"]}
```

## `apply_patch` (實驗性功能)
這是一個用於結構化多檔案修改的子工具，目前僅支援部分 OpenAI 模型。您可以在 `tools.exec.applyPatch` 下進行啟用。
