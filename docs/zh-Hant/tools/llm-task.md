---
summary: "工作流用 JSON-only LLM 任務（可選外掛工具）"
read_when:
  - You want a JSON-only LLM step inside workflows
  - You need schema-validated LLM output for automation
title: "LLM Task（LLM 任務）"
---

# LLM Task

`llm-task` 是一個**可選外掛工具**，執行 JSON-only LLM 任務並
返回結構化輸出（可選地針對 JSON Schema 驗證）。

這對工作流引擎（如 Lobster）理想：可以新增單一 LLM 步驟
無需為每個工作流寫自訂 OpenClaw 代碼。

## 啟用外掛

1. 啟用外掛：

```json
{
  "plugins": {
    "entries": {
      "llm-task": { "enabled": true }
    }
  }
}
```

2. Allowlist 工具（使用 `optional: true` 註冊）：

```json
{
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

## 設定（可選）

```json
{
  "plugins": {
    "entries": {
      "llm-task": {
        "enabled": true,
        "config": {
          "defaultProvider": "openai-codex",
          "defaultModel": "gpt-5.2",
          "defaultAuthProfileId": "main",
          "allowedModels": ["openai-codex/gpt-5.3-codex"],
          "maxTokens": 800,
          "timeoutMs": 30000
        }
      }
    }
  }
}
```

`allowedModels` 是 `provider/model` 字串的 allowlist。如果設定，任何在列表外的請求都被拒絕。

## 工具參數

- `prompt`（字串，必需）
- `input`（任何，可選）
- `schema`（物件，可選 JSON Schema）
- `provider`（字串，可選）
- `model`（字串，可選）
- `authProfileId`（字串，可選）
- `temperature`（數字，可選）
- `maxTokens`（數字，可選）
- `timeoutMs`（數字，可選）

## 輸出

返回 `details.json` 包含已解析 JSON（及在提供時針對 `schema` 驗證）。

## 範例：Lobster 工作流步驟

```lobster
openclaw.invoke --tool llm-task --action json --args-json '{
  "prompt": "Given the input email, return intent and draft.",
  "input": {
    "subject": "Hello",
    "body": "Can you help?"
  },
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

## 安全注意

- 工具是 **JSON-only** 及指示模型僅輸出 JSON（無代碼籬、無評論）。
- 無工具暴露給此執行的模型。
- 除非使用 `schema` 驗證，將輸出視為不可信。
- 在任何副作用步驟（發送、發佈、exec）之前放置許可。
