---
title: Lobster（龍蝦）
summary: "OpenClaw 的型別工作流執行時，具有可恢復許可閘控。"
description: OpenClaw 的型別工作流執行時 — 具有許可閘控的可組合管線。
read_when:
  - You want deterministic multi-step workflows with explicit approvals
  - You need to resume a workflow without re-running earlier steps
---

# Lobster

Lobster 是一個工作流 shell，讓 OpenClaw 執行多步驟工具序列作為單一、決定性的操作，具有明確許可檢查點。

## Hook

助手可以建立自己管理的工具。請求一個工作流，30 分鐘後有一個 CLI 加上作為一個呼叫執行的管線。Lobster 是缺失的片段：決定性管線、明確許可及可恢復狀態。

## 為什麼

今天，複雜工作流需要許多來回工具呼叫。每個呼叫耗費令牌，LLM 必須協調每個步驟。Lobster 將協調移到型別執行時：

- **一個呼叫而不是許多**：OpenClaw 執行一個 Lobster 工具呼叫並獲得結構化結果。
- **許可內建**：副作用（發送電郵、發佈評論）暫停工作流直到明確許可。
- **可恢復**：暫停工作流返回令牌；許可及恢復無需重新執行一切。

## 為什麼是 DSL 而不是普通程式？

Lobster 有意很小。目標不是"新語言"，是一個可預測、AI 友好的管線規格，有一級許可及恢復令牌。

- **許可/恢復內建**：普通程式可以提示人，但無法*暫停及恢復*具有耐久令牌，除非自己發明該執行時。
- **決定性＋可稽核性**：管線是資料，易於記錄、diff、重放及檢查。
- **AI 的受限表面**：微小文法＋ JSON 管線減少"創意"代碼路徑，使驗證實際。
- **安全政策烤入**：逾時、輸出上限、沙箱檢查及 allowlist 由執行時強制，不每個腳本。
- **仍可編程**：每步可呼叫任何 CLI 或腳本。如想要 JS/TS，生成 `.lobster` 檔案。

## 如何工作

OpenClaw 在**工具模式**中啟動本地 `lobster` CLI 並從 stdout 解析 JSON 信封。
如果管線暫停以許可，工具返回 `resumeToken` 可稍後繼續。

## 模式：小 CLI ＋ JSON 管道＋許可

建立微小命令，說 JSON，接著鏈到單一 Lobster 呼叫。（下面範例命令名稱 — 用你自己的交換）。

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

如果管線要求許可，使用令牌恢復：

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

AI 觸發工作流；Lobster 執行步驟。許可閘控保持副作用明確及可稽核。

範例：地圖輸入項目至工具呼叫：

```bash
gog.gmail.search --query 'newer_than:1d' \
  | openclaw.invoke --tool message --action send --each --item-key message --args-json '{"provider":"telegram","to":"..."}'
```

## JSON-only LLM 步驟（llm-task）

針對需要**結構化 LLM 步驟**的工作流，啟用可選
`llm-task` 外掛工具並從 Lobster 呼叫它。這保持工作流
決定性，同時仍讓用 model 分類/摘要/草稿。

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

在管線中使用它：

```lobster
openclaw.invoke --tool llm-task --action json --args-json '{
  "prompt": "Given the input email, return intent and draft.",
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

見 [LLM Task](/zh-Hant/tools/llm-task) 用於詳情及設定選項。

## 工作流檔案（.lobster）

Lobster 可執行有 `name`、`args`、`steps`、`env`、`condition` 及 `approval` 欄位的 YAML/JSON 工作流檔案。在 OpenClaw 工具呼叫中，設定 `pipeline` 至檔案路徑。

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

- `stdin: $step.stdout` 及 `stdin: $step.json` 傳遞前步驟的輸出。
- `condition`（或 `when`）可閘控 `$step.approved` 上的步驟。

## 安裝 Lobster

在執行 OpenClaw Gateway 的**同一主機**上安裝 Lobster CLI（見 [Lobster repo](https://github.com/openclaw/lobster)），並確保 `lobster` 在 `PATH`。
如想使用自訂二進位位置，在工具呼叫中傳遞絕對 `lobsterPath`。

## 啟用工具

Lobster 是一個**可選**外掛工具（預設不啟用）。

推薦（附加、安全）：

```json
{
  "tools": {
    "alsoAllow": ["lobster"]
  }
}
```

或每個代理：

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

避免使用 `tools.allow: ["lobster"]`，除非打算在限制性 allowlist 模式下執行。

注意：allowlist 對可選外掛是可選的。如果 allowlist 僅命名外掛工具（如 `lobster`），OpenClaw 保持核心工具啟用。若要限制核心工具，在 allowlist 中包含想要的核心工具或群組。

## 例子：郵件分類

不用 Lobster：

```
使用者："檢查我的郵件及草稿回覆"
→ openclaw 呼叫 gmail.list
→ LLM 摘要
→ 使用者："草稿回覆至 #2 及 #5"
→ LLM 草稿
→ 使用者："發送 #2"
→ openclaw 呼叫 gmail.send
（每日重複，未分類者的記憶）
```

用 Lobster：

```json
{
  "action": "run",
  "pipeline": "email.triage --limit 20",
  "timeoutMs": 30000
}
```

返回 JSON 信封（截斷）：

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

使用者許可 → 恢復：

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

一個工作流。決定性。安全。

## 工具參數

### `run`

在工具模式下執行管線。

```json
{
  "action": "run",
  "pipeline": "gog.gmail.search --query 'newer_than:1d' | email.triage",
  "cwd": "/path/to/workspace",
  "timeoutMs": 30000,
  "maxStdoutBytes": 512000
}
```

執行帶引數的工作流檔案：

```json
{
  "action": "run",
  "pipeline": "/path/to/inbox-triage.lobster",
  "argsJson": "{\"tag\":\"family\"}"
}
```

### `resume`

在許可後繼續暫停的工作流。

```json
{
  "action": "resume",
  "token": "<resumeToken>",
  "approve": true
}
```

### 可選輸入

- `lobsterPath`：Lobster 二進位的絕對路徑（省略以使用 `PATH`）。
- `cwd`：管線的工作目錄（預設為當前程序工作目錄）。
- `timeoutMs`：如超過此持續時間，殺死子程序（預設：20000）。
- `maxStdoutBytes`：如 stdout 超過此大小，殺死子程序（預設：512000）。
- `argsJson`：傳遞給 `lobster run --args-json` 的 JSON 字串（僅工作流檔案）。

## 輸出信封

Lobster 返回具有三個狀態之一的 JSON 信封：

- `ok` → 成功完成
- `needs_approval` → 暫停；需要 `requiresApproval.resumeToken` 以恢復
- `cancelled` → 明確拒絕或取消

工具在 `content`（美化 JSON）及 `details`（原始物件）中出現信封。

## 許可

如 `requiresApproval` 存在，檢查提示及決定：

- `approve: true` → 恢復及繼續副作用
- `approve: false` → 取消及完成工作流

使用 `approve --preview-from-stdin --limit N` 附加 JSON 預覽至許可請求無自訂 jq/heredoc 膠水。恢復令牌現在緊湊：Lobster 在其狀態目錄儲存工作流恢復狀態及交還小令牌鑰。

## OpenProse

OpenProse 與 Lobster 配好：使用 `/prose` 協調多代理準備，接著執行 Lobster 管線用於決定性許可。如 Prose 程式需要 Lobster，允許 `lobster` 工具用於子代理透過 `tools.subagents.tools`。見 [OpenProse](/zh-Hant/prose)。

## 安全

- **本地子程序僅** — 外掛本身無網路呼叫。
- **無秘密** — Lobster 不管理 OAuth；它呼叫做的 OpenClaw 工具。
- **沙箱感知** — 當工具 context 沙箱化時停用。
- **強化** — `lobsterPath` 如指定必須是絕對；逾時及輸出上限強制。

## 疑難排解

- **`lobster subprocess timed out`** → 增加 `timeoutMs`，或分割長管線。
- **`lobster output exceeded maxStdoutBytes`** → 提升 `maxStdoutBytes` 或縮小輸出大小。
- **`lobster returned invalid JSON`** → 確保管線在工具模式執行且僅列印 JSON。
- **`lobster failed (code …)`** → 在終端執行相同管線以檢查 stderr。

## 進一步瞭解

- [Plugins](/zh-Hant/tools/plugin)
- [Plugin tool authoring](/zh-Hant/plugins/agent-tools)

## 案例研究：社群工作流

一個公開例子：一個"第二大腦" CLI ＋ Lobster 管線，管理三個 Markdown vault（個人、伴侶、共享）。CLI 針對統計、inbox 列表及陳舊掃描發出 JSON；Lobster 鏈那些命令至工作流，如 `weekly-review`、`inbox-triage`、`memory-consolidation` 及 `shared-task-sync`，各帶許可閘控。AI 處理判斷（分類）何時可用，及當不時退回至決定性規則。

- Thread：[https://x.com/plattenschieber/status/2014508656335770033](https://x.com/plattenschieber/status/2014508656335770033)
- Repo：[https://github.com/bloomedai/brain-cli](https://github.com/bloomedai/brain-cli)
