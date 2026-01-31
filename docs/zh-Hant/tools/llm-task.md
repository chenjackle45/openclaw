---
title: "LLM task(LLM 任務)"
summary: "工作流程中的純 JSON LLM 任務（選用 Plugin Tool）"
read_when:
  - 您想在工作流程中加入純 JSON 的 LLM 步驟
  - 您需要 Schema 驗證的 LLM 輸出以進行自動化
---

# LLM 任務

`llm-task` 是一個**選用 Plugin Tool**，用於執行純 JSON 的 LLM 任務並回傳結構化輸出（可選擇使用 JSON Schema 驗證）。

這非常適合 Lobster 等工作流程引擎：您可以新增單一 LLM 步驟，無需為每個工作流程撰寫自訂 OpenClaw 程式碼。

## 啟用 Plugin

1) 啟用 Plugin：

```json
{
  "plugins": {
    "entries": {
      "llm-task": { "enabled": true }
    }
  }
}
```

2) 將 Tool 加入 Allowlist（它以 `optional: true` 註冊）：

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

## 設定（選用）

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
          "allowedModels": ["openai-codex/gpt-5.2"],
          "maxTokens": 800,
          "timeoutMs": 30000
        }
      }
    }
  }
}
```

`allowedModels` 是 `provider/model` 字串的 Allowlist。如果設定，任何不在清單中的請求都會被拒絕。

## Tool 參數

- `prompt`（string，必填）
- `input`（any，選填）
- `schema`（object，選填 JSON Schema）
- `provider`（string，選填）
- `model`（string，選填）
- `authProfileId`（string，選填）
- `temperature`（number，選填）
- `maxTokens`（number，選填）
- `timeoutMs`（number，選填）

## 輸出

回傳 `details.json`，包含解析的 JSON（提供 `schema` 時會進行驗證）。

## 範例：Lobster 工作流程步驟

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

## 安全注意事項

- 此 Tool 是**純 JSON** 的，會指示模型僅輸出 JSON（無 Code Fences、無註解）。
- 此次執行不會向模型公開任何 Tools。
- 除非使用 `schema` 驗證，否則應將輸出視為不受信任。
- 在任何有副作用的步驟（send、post、exec）之前設定 Approvals。
