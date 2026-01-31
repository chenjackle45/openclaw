---
title: "Lobster(Lobster 工作流執行環境)"
summary: "具備可續傳核准關卡的強型別 OpenClaw 工作流執行環境"
description: "Lobster：透過具備核准關卡的組合式管線達成確定性的多步驟工作流"
read_when:
  - 需要確定性的多步驟工作流且具備顯式核准檢查點時
  - 需要在不重複執行先前步驟的情況下續傳工作流時
---

# Lobster

Lobster 是一個工作流外殼 (Workflow Shell)，讓 OpenClaw 能將多步驟的工具呼叫序列合併為單一的確定性操作，並具備顯式的核准檢查點。

## 為什麼需要 Lobster？
目前的複雜工作流通常需要多次 Agent 與工具之間的來回紀錄，這既消耗 Token 也容易導致模型在編排時出錯。Lobster 將這種編排轉移到了強型別的執行環境中：
- **減少呼叫次數**：將一連串操作封裝成一次 Lobster 呼叫。
- **內建核准機制**：具副作用的操作（如發送郵件）會暫停工作流，直到使用者顯式核准。
- **可續傳性**：暫停的工作流會回傳權杖 (Token)，核准後即可從中斷點續行。

## 運作原理
OpenClaw 在「工具模式」下啟動本地的 `lobster` CLI，並解析標準輸出的 JSON 資料夾。若管線需要核准，工具會回傳一個 `resumeToken` 供後續續傳使用。

### 模式範例：JSON 管線 + 核准
```json
{
  "action": "run",
  "pipeline": "exec --json 'inbox list' | exec --stdin json 'inbox categorize' | approve --prompt '套用變更？'",
  "timeoutMs": 30000
}
```

## `.lobster` 工作流檔案
Lobster 可以執行 YAML/JSON 格式的工作流定義，支援參數、步驟、環境變數與條件判定。
```yaml
name: inbox-triage
steps:
  - id: collect
    command: inbox list --json
  - id: approve
    command: inbox apply --approve
    stdin: $collect.stdout
    approval: required
  - id: execute
    command: inbox apply --execute
    condition: $approve.approved
```

## 啟用與安裝
1. **安裝**：確保 `lobster` CLI 已安裝於 Gateway 同台主機並位於 `PATH` 中。
2. **啟用工具**：在 `openclaw.json` 中將 `lobster` 加入允許清單。
```json
{
  "tools": {
    "alsoAllow": ["lobster"]
  }
}
```

## 工具參數說明
- **run**：執行新的管線或檔案。
  - `pipeline`：指令字串或 `.lobster` 檔案路徑。
  - `argsJson`：傳遞給工作流檔案的參數。
- **resume**：續傳先前中斷的工作流。
  - `token`：續傳權杖。
  - `approve`：設為 `true` 以核准並繼續。

## 輸出狀態
Lobster 會回傳以下三種狀態之一：
- `ok`：成功執行完畢。
- `needs_approval`：已暫停，等待核准並提供續傳權杖。
- `cancelled`：已被使用者顯式拒絕或取消。

## 安全性與疑難排解
- **僅限本地子進程**：外掛程式本身不會發起網路連線。
- **超時處理**：若管線執行過久，請調大 `timeoutMs` 或拆分管線。
- **日誌觀察**：若 JSON 格式錯誤，請在終端機手動執行管線以觀察 stderr 錯誤訊息。
