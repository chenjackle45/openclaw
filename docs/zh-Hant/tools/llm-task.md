---
summary: "用於工作流程的僅限 JSON LLM 任務（選擇性 plugin 工具）"
read_when:
  - 你想在工作流程中使用僅限 JSON 的 LLM 步驟
  - 你需要針對自動化的 schema 驗證 LLM 輸出
title: "LLM Task"
---

# LLM Task

`llm-task` 是一個 **選擇性 plugin 工具**，執行僅限 JSON 的 LLM 任務並傳回結構化輸出（可選地針對 JSON Schema 驗證）。

這對於 Lobster 等工作流程引擎是理想的：你可以新增單個 LLM 步驟，而不用為每個工作流程撰寫自訂 OpenClaw 程式碼。

## 啟用 plugin

1. 啟用 plugin：

```json
{
  "plugins": {
    "entries": {
      "llm-task": { "enabled": true }
    }
  }
}
```

2. 允許列表工具（它以 `optional: true` 註冊）：

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

## 配置（選擇性）

```json
{
  "plugins": {
    "entries": {
      "llm-task": {
        "enabled": true,
        "config": {
          "defaultProvider": "openai-codex",
          "defaultModel": "gpt-5.4",
          "defaultAuthProfileId": "main",
          "allowedModels": ["openai-codex/gpt-5.4"],
          "maxTokens": 800,
          "timeoutMs": 30000
        }
      }
    }
  }
}
```

`allowedModels` 是 `provider/model` 字串的允許列表。如果設定，任何列表外的請求都會被拒絕。

## 工具參數

- `prompt`（字串，必需）
- `input`（任何，選擇性）
- `schema`（物件，選擇性 JSON Schema）
- `provider`（字串，選擇性）
- `model`（字串，選擇性）
- `thinking`（字串，選擇性）
- `authProfileId`（字串，選擇性）
- `temperature`（數字，選擇性）
- `maxTokens`（數字，選擇性）
- `timeoutMs`（數字，選擇性）

`thinking` 接受標準 OpenClaw 推理預設集，例如 `low` 或 `medium`。

## 輸出

傳回包含已解析 JSON 的 `details.json`（並在提供時針對 `schema` 驗證）。

## 範例：Lobster 工作流程步驟

```lobster
openclaw.invoke --tool llm-task --action json --args-json '{
  "prompt": "Given the input email, return intent and draft.",
  "thinking": "low",
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

## 安全注意事項

- 工具是 **僅限 JSON**，指示模型僅輸出 JSON（無程式碼柵欄，無評論）。
- 沒有工具公開給此執行中的模型。
- 除非使用 `schema` 驗證，否則將輸出視為不信任。
- 在任何副作用步驟（傳送、發佈、exec）前放置核准。
