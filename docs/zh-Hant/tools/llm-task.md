---
summary: "工作流用 JSON-only LLM 任務（可選 plugin 工具）"
read_when:
  - 你想在工作流中加入一個 JSON-only LLM 步驟
  - 你需要對自動化進行 schema 驗證的 LLM 輸出
title: "LLM Task（LLM 任務）"
---

# LLM Task

`llm-task` 是一個**可選的 plugin 工具**，執行 JSON-only LLM 任務並回傳結構化輸出（可選擇對照 JSON Schema 驗證）。

這非常適合 Lobster 等工作流引擎：你可以新增單一 LLM 步驟，而無需為每個工作流撰寫自訂的 OpenClaw 程式碼。

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

2. 將工具加入允許清單（已以 `optional: true` 註冊）：

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

`allowedModels` 是 `provider/model` 字串的允許清單。若設定後，清單外的任何請求都會被拒絕。

## 工具參數

- `prompt`（string，必填）
- `input`（any，可選）
- `schema`（object，可選 JSON Schema）
- `provider`（string，可選）
- `model`（string，可選）
- `authProfileId`（string，可選）
- `temperature`（number，可選）
- `maxTokens`（number，可選）
- `timeoutMs`（number，可選）

## 輸出

回傳包含解析後 JSON 的 `details.json`（提供 `schema` 時進行驗證）。

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

## 安全注意事項

- 此工具**僅限 JSON**，並指示模型只輸出 JSON（無程式碼圍欄，無說明文字）。
- 此執行不向模型公開任何工具。
- 除非以 `schema` 驗證，否則將輸出視為不受信任。
- 在任何有副作用的步驟（send、post、exec）之前加入審批。
