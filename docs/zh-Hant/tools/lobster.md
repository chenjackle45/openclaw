---
title: Lobster
summary: "具有可恢復核准閘門的 OpenClaw 型別工作流程 runtime。"
description: OpenClaw 型別工作流程 runtime — 帶有核准閘門的可組合管道。
read_when:
  - 你想要具有明確核准的確定性多步驟工作流程
  - 你需要恢復工作流程而不重新執行較早的步驟
---

# Lobster

Lobster 是一個工作流程 shell，讓 OpenClaw 以單個、確定性操作運行多步驟工具序列，具有明確的核准檢查點。

## Hook

你的助手可以建造管理自己的工具。要求一個工作流程，30 分鐘後你有一個 CLI 加上運行為單個呼叫的管道。Lobster 是遺漏的部分：確定性管道、明確的核准和可恢復的狀態。

## 為什麼

今天，複雜工作流程需要許多往返工具呼叫。每個呼叫都消耗 tokens，而 LLM 必須協調每個步驟。Lobster 將該協調移到型別 runtime 中：

- **一個呼叫而不是許多**：OpenClaw 執行一個 Lobster 工具呼叫並取得結構化結果。
- **內建核准**：副作用（傳送電子郵件、發佈評論）在明確核准前暫停工作流程。
- **可恢復**：暫停的工作流程傳回 token；核准並恢復而不重新執行一切。

## 為什麼是 DSL 而不是純程式？

Lobster 有意很小。目標不是「新語言」，而是具有一流核准和恢復 tokens 的可預測、AI 友善的管道規格。

- **核准／恢復是內建的**：普通程式可以提示人類，但它不能 _暫停並恢復_ 帶有耐久 token，而不用你自己發明該 runtime。
- **確定性 + 可審計性**：管道是資料，因此很容易記錄、diff、重播和審視。
- **為 AI 限制表面**：一個小文法 + JSON 管道減少「創意」程式碼路徑並使驗證現實。
- **安全原則內建**：逾時、輸出上限、sandbox 檢查和允許列表由 runtime 強制，而不是每個指令碼。
- **仍然是可程式化的**：每個步驟可以呼叫任何 CLI 或指令碼。如果你想要 JS／TS，從程式碼產生 `.lobster` 檔案。

## 它如何運作

OpenClaw 在 **tool mode** 中啟動本機 `lobster` CLI，並從 stdout 解析 JSON 信封。
如果管道為核准暫停，工具傳回 `resumeToken`，以便你稍後可以繼續。

## 模式：小 CLI + JSON pipes + 核准

建造說 JSON 的小命令，然後將它們鏈接到單個 Lobster 呼叫。（下面是範例命令名稱 — 交換到你的。）

```bash
inbox list --json
inbox categorize --json
inbox apply --json
```

```json
{
  "action": "run",
  "pipeline": "exec --json --shell 'inbox list --json' | exec --stdin json --shell 'inbox categorize --json' | exec --stdin json --shell 'inbox apply --json' | approve --preview-from-stdin --limit 5 --prompt 'Apply changes?'",
  "timeoutMs": 30000
}
```

如果管道要求核准，使用 token 恢復：

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

AI 觸發工作流程；Lobster 執行步驟。核准閘門保持副作用明確和可審計。

範例：將輸入項目對映到工具呼叫：

```bash
gog.gmail.search --query 'newer_than:1d' \
  | openclaw.invoke --tool message --action send --each --item-key message --args-json '{"provider":"telegram","to":"..."}'
```

## 僅限 JSON 的 LLM 步驟（llm-task）

對於需要 **結構化 LLM 步驟** 的工作流程，啟用選擇性 `llm-task` plugin 工具並從 Lobster 呼叫它。這保持工作流程確定性同時仍然讓你使用模型分類／總結／草稿。

啟用工具：

```json
{
  "plugins": {
    "entries": {
      "llm-task": { "enabled": true }
    }
  },
  "agents": {
    "list": [
      {
        "id": "main",
        "tools": { "allow": ["llm-task"] }
      }
    ]
  }
}
```

在管道中使用它：

```lobster
openclaw.invoke --tool llm-task --action json --args-json '{
  "prompt": "Given the input email, return intent and draft.",
  "thinking": "low",
  "input": { "subject": "Hello", "body": "Can you help?" },
  "schema": {
    "type": "object",
    "properties": {
      "intent": { "type": "string" },
      "draft": { "type": "string" }
    },
    "required": ["intent", "draft"],
    "additionalProperties": false
  }
}'
```

見 [LLM Task](/zh-Hant/tools/llm-task) 以了解詳細資訊和配置選項。

## 工作流程檔案 (.lobster)

Lobster 可以執行具有 `name`、`args`、`steps`、`env`、`condition` 和 `approval` 欄位的 YAML／JSON 工作流程檔案。在 OpenClaw 工具呼叫中，設定 `pipeline` 到檔案路徑。

```yaml
name: inbox-triage
args:
  tag:
    default: "family"
steps:
  - id: collect
    command: inbox list --json
  - id: categorize
    command: inbox categorize --json
    stdin: $collect.stdout
  - id: approve
    command: inbox apply --approve
    stdin: $categorize.stdout
    approval: required
  - id: execute
    command: inbox apply --execute
    stdin: $categorize.stdout
    condition: $approve.approved
```

注意：

- `stdin: $step.stdout` 和 `stdin: $step.json` 傳送先前步驟的輸出。
- `condition`（或 `when`）可以閘控 `$step.approved` 上的步驟。

## 安裝 Lobster

在 **執行 OpenClaw Gateway 的相同主機** 上安裝 Lobster CLI（見 [Lobster repo](https://github.com/openclaw/lobster)），並確保 `lobster` 在 `PATH` 上。

## 啟用工具

Lobster 是一個 **選擇性** plugin 工具（預設未啟用）。

推薦（加法、安全）：

```json
{
  "tools": {
    "alsoAllow": ["lobster"]
  }
}
```

或 per agent：

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "tools": {
          "alsoAllow": ["lobster"]
        }
      }
    ]
  }
}
```

避免使用 `tools.allow: ["lobster"]`，除非你打算在限制性允許列表 mode 中執行。

注意：允許列表是選擇加入用於選擇性 plugins。如果你的允許列表僅命名 plugin 工具（如 `lobster`），OpenClaw 保持核心工具啟用。要限制核心工具，在允許列表中包含你想要的核心工具或群組。

## 範例：電子郵件分類

沒有 Lobster：

```
使用者：「檢查我的電子郵件並草稿回覆」
→ openclaw 呼叫 gmail.list
→ LLM 總結
→ 使用者：「草稿回覆到 #2 和 #5」
→ LLM 草稿
→ 使用者：「傳送 #2」
→ openclaw 呼叫 gmail.send
（每天重複，沒有分類內容的記憶）
```

使用 Lobster：

```json
{
  "action": "run",
  "pipeline": "email.triage --limit 20",
  "timeoutMs": 30000
}
```

傳回 JSON 信封（截短）：

```json
{
  "ok": true,
  "status": "needs_approval",
  "output": [{ "summary": "5 need replies, 2 need action" }],
  "requiresApproval": {
    "type": "approval_request",
    "prompt": "Send 2 draft replies?",
    "items": [],
    "resumeToken": "..."
  }
}
```

使用者核准 → 恢復：

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

一個工作流程。確定性。安全。

## 工具參數

### `run`

在 tool mode 中執行管道。

```json
{
  "action": "run",
  "pipeline": "gog.gmail.search --query 'newer_than:1d' | email.triage",
  "cwd": "workspace",
  "timeoutMs": 30000,
  "maxStdoutBytes": 512000
}
```

執行帶有 args 的工作流程檔案：

```json
{
  "action": "run",
  "pipeline": "/path/to/inbox-triage.lobster",
  "argsJson": "{\"tag\":\"family\"}"
}
```

### `resume`

在核准後繼續暫停的工作流程。

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

### 選擇性輸入

- `cwd`: 管道的相對工作目錄（必須保持在目前進程工作目錄內）。
- `timeoutMs`: 如果超過此持續時間，殺死子進程（預設：20000）。
- `maxStdoutBytes`: 如果 stdout 超過此大小，殺死子進程（預設：512000）。
- `argsJson`: 傳遞給 `lobster run --args-json` 的 JSON 字串（工作流程檔案僅限）。

## 輸出信封

Lobster 傳回具有三種狀態之一的 JSON 信封：

- `ok` → 成功完成
- `needs_approval` → 暫停；需要 `requiresApproval.resumeToken` 恢復
- `cancelled` → 明確被拒絕或取消

工具在 `content`（漂亮 JSON）和 `details`（原始物件）中表面信封。

## 核准

如果 `requiresApproval` 存在，檢查提示並決定：

- `approve: true` → 恢復並繼續副作用
- `approve: false` → 取消並終結工作流程

使用 `approve --preview-from-stdin --limit N` 將 JSON 預覽附加到核准請求，而不需要自訂 jq／heredoc glue。恢復 tokens 現在緊湊：Lobster 在其狀態目錄下儲存工作流程恢復狀態並遞交回小 token key。

## OpenProse

OpenProse 與 Lobster 配對良好：使用 `/prose` 協調多 agent 預備，然後為確定性核准執行 Lobster 管道。如果 Prose 程式需要 Lobster，透過 `tools.subagents.tools` 為 sub agents 允許 `lobster` 工具。見 [OpenProse](/zh-Hant/prose)。

## 安全

- **本機子進程僅限** — plugin 本身沒有網路呼叫。
- **沒有密碼** — Lobster 不管理 OAuth；它呼叫執行的 OpenClaw 工具。
- **Sandbox 感知** — 當工具 context 已沙箱化時停用。
- **強化** — 固定可執行名稱（`lobster`）在 `PATH` 上；逾時和輸出上限被強制。

## 疑難排解

- **`lobster subprocess timed out`** → 增加 `timeoutMs`，或分割長管道。
- **`lobster output exceeded maxStdoutBytes`** → 提高 `maxStdoutBytes` 或減少輸出大小。
- **`lobster returned invalid JSON`** → 確保管道在 tool mode 中執行且僅列印 JSON。
- **`lobster failed (code …)`** → 在終端機中執行相同管道以檢查 stderr。

## 深入學習

- [Plugins](/zh-Hant/tools/plugin)
- [Plugin tool authoring](/zh-Hant/plugins/agent-tools)

## 個案研究：社群工作流程

一個公開範例：「第二大腦」CLI + Lobster 管道，管理三個 Markdown vaults（個人、夥伴、共用）。CLI 發出 JSON 用於統計、inbox 列表和舊掃描；Lobster 將這些命令鏈接到 `weekly-review`、`inbox-triage`、`memory-consolidation` 和 `shared-task-sync` 等工作流程，每個都具有核准閘門。AI 在可用時處理判斷（分類），在沒有時回退到確定性規則。

- Thread: [https://x.com/plattenschieber/status/2014508656335770033](https://x.com/plattenschieber/status/2014508656335770033)
- Repo: [https://github.com/bloomedai/brain-cli](https://github.com/bloomedai/brain-cli)
