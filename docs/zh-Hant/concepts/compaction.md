---
title: "Compaction（上下文視窗與壓縮）"
summary: "上下文視窗 + 壓縮：OpenClaw 如何保持會話在模型限制內"
read_when:
  - 您想了解自動壓縮和 /compact
  - 您正在除錯遇到上下文限制的長會話
---

# 上下文視窗與壓縮

每個模型都有**上下文視窗**（它可以看到的最大 token 數量）。長時間執行的聊天會積累訊息和工具結果；一旦視窗變得緊張，OpenClaw 會**壓縮**較舊的歷史以保持在限制範圍內。

## 什麼是壓縮

壓縮**將較舊的對話摘要**為一個緊湊的摘要條目，並保持最近的訊息完整。摘要儲存在工作階段歷史中，因此未來的請求使用：

- 壓縮摘要
- 壓縮點之後的最近訊息

壓縮**持久化**在工作階段的 JSONL 歷史中。

## 設定

在你的 `openclaw.json` 中使用 `agents.defaults.compaction` 設定來設定壓縮行為（模式、目標 token 等）。
壓縮摘要預設保留不透明識別碼（`identifierPolicy: "strict"`）。你可以使用 `identifierPolicy: "off"` 覆蓋，或使用 `identifierPolicy: "custom"` 和 `identifierInstructions` 提供自訂文字。

你可以透過 `agents.defaults.compaction.model` 選擇性指定不同的壓縮摘要模型。當你的主要模型是本地或小型模型，而你希望壓縮摘要由更強大的模型產生時，這很有用。覆蓋接受任何 `provider/model-id` 字串：

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "model": "openrouter/anthropic/claude-sonnet-4-5"
      }
    }
  }
}
```

這也適用於本地模型，例如專用於摘要的第二個 Ollama 模型或微調的壓縮專家：

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "model": "ollama/llama3.1:8b"
      }
    }
  }
}
```

未設定時，壓縮使用 agent 的主要模型。

## 自動壓縮（預設開啟）

當工作階段接近或超過模型的上下文視窗時，OpenClaw 觸發自動壓縮，並可能使用壓縮後的上下文重試原始請求。

你會看到：

- 在詳細模式中顯示 `🧹 Auto-compaction complete`
- `/status` 顯示 `🧹 Compactions: <count>`

在壓縮之前，OpenClaw 可以執行**靜默記憶體刷新**回合，將持久性筆記儲存到磁碟。請參閱 [Memory](/zh-Hant/concepts/memory) 了解詳情和設定。

## 手動壓縮

使用 `/compact`（選擇性帶說明）強制壓縮：

```
/compact Focus on decisions and open questions
```

## 上下文視窗來源

上下文視窗是模型特定的。OpenClaw 使用設定的 provider 目錄中的模型定義來確定限制。

## 壓縮 vs 修剪

- **壓縮**：摘要並**持久化**在 JSONL 中。
- **工作階段修剪**：只修剪舊的**工具結果**，**在記憶體中**，每個請求。

請參閱 [/concepts/session-pruning](/zh-Hant/concepts/session-pruning) 了解修剪詳情。

## OpenAI 伺服器端壓縮

OpenClaw 也支援相容直接 OpenAI 模型的 OpenAI Responses 伺服器端壓縮提示。這與本地 OpenClaw 壓縮是分開的，可以同時執行。

- 本地壓縮：OpenClaw 摘要並持久化到工作階段 JSONL。
- 伺服器端壓縮：當啟用 `store` + `context_management` 時，OpenAI 在 provider 端壓縮上下文。

請參閱 [OpenAI provider](/zh-Hant/providers/openai) 了解模型參數和覆蓋。

## 技巧

- 當工作階段感覺陳舊或上下文膨脹時使用 `/compact`。
- 大型工具輸出已被截斷；修剪可以進一步減少工具結果積累。
- 若需要全新開始，`/new` 或 `/reset` 啟動新的工作階段 ID。
