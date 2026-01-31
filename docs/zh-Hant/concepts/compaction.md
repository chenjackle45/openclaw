---
title: "Compaction(上下文視窗與壓縮)"
summary: "上下文視窗 + 壓縮：OpenClaw 如何保持會話在模型限制內"
read_when:
  - 您想了解自動壓縮和 /compact
  - 您正在除錯長會話達到上下文限制
---
# Context Window & Compaction（上下文視窗與壓縮）

每個模型都有一個**上下文視窗**（它能看到的最大 token 數）。長時間運行的聊天會累積訊息和工具結果；一旦視窗緊張，OpenClaw 會**壓縮**較舊的歷史以保持在限制內。

## 什麼是壓縮
壓縮**將較舊的對話摘要**為緊湊的摘要條目，並保持最近的訊息完整。摘要儲存在會話歷史中，因此未來的請求使用：
- 壓縮摘要
- 壓縮點之後的最近訊息

壓縮**持久化**在會話的 JSONL 歷史中。

## 設定
請參閱 [壓縮設定和模式](/concepts/compaction) 了解 `agents.defaults.compaction` 設定。

## 自動壓縮（預設開啟）
當會話接近或超過模型的上下文視窗時，OpenClaw 觸發自動壓縮，並可能使用壓縮的上下文重試原始請求。

您會看到：
- 詳細模式下的 `🧹 Auto-compaction complete`
- `/status` 顯示 `🧹 Compactions: <count>`

在壓縮之前，OpenClaw 可以運行**靜默記憶體刷新**輪次，將持久備註儲存到磁碟。請參閱 [記憶體](/concepts/memory) 了解詳情和設定。

## 手動壓縮
使用 `/compact`（可選帶說明）強制壓縮過程：
```
/compact Focus on decisions and open questions
```

## 上下文視窗來源
上下文視窗是模型特定的。OpenClaw 使用設定的供應商目錄中的模型定義來確定限制。

## 壓縮 vs 修剪
- **壓縮**：摘要並**持久化**在 JSONL 中。
- **會話修剪**：僅修剪舊的**工具結果**，**在記憶體中**，按請求。

請參閱 [/concepts/session-pruning](/concepts/session-pruning) 了解修剪詳情。

## 提示
- 當會話感覺陳舊或上下文膨脹時使用 `/compact`。
- 大型工具輸出已經被截斷；修剪可以進一步減少工具結果累積。
- 如果您需要全新開始，`/new` 或 `/reset` 開始新的會話 ID。
