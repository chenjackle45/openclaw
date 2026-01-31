---
title: "Session pruning(會話修剪)"
summary: "會話修剪：修剪工具結果以減少上下文膨脹"
read_when:
  - 您想要減少工具輸出的 LLM 上下文增長
  - 您正在調整 agents.defaults.contextPruning
---
# Session Pruning（會話修剪）

會話修剪在每次 LLM 呼叫之前，從記憶體上下文（in-memory context）中修剪**舊的工具結果**。它**不會**重寫磁碟上的會話歷史 (`*.jsonl`)。

## 何時執行
- 當啟用 `mode: "cache-ttl"` 且該會話的最後一次 Anthropic 呼叫早於 `ttl` 時。
- 僅影響發送給該請求模型的訊息。
- 僅對 Anthropic API 呼叫（及 OpenRouter 的 Anthropic 模型）有效。
- 為了獲得最佳效果，請使 `ttl` 與您的模型 `cacheControlTtl` 相匹配。
- 修剪後，TTL 窗口會重置，因此後續請求會保持快取，直到 `ttl` 再次過期。

## 智慧預設 (Anthropic)
- **OAuth 或 setup-token** 設定檔：啟用 `cache-ttl` 修剪，並將心跳（heartbeat）設定為 `1h`。
- **API Key** 設定檔：啟用 `cache-ttl` 修剪，將心跳設定為 `30m`，並在 Anthropic 模型上將預設 `cacheControlTtl` 設定為 `1h`。
- 如果您明確設定了這些值，OpenClaw **不會**覆寫它們。

## 改進了什麼（成本 + 快取行為）
- **為何修剪：** Anthropic 的提示快取（prompt caching）僅在 TTL 內有效。如果會話在 TTL 之後閒置，下一次請求會重新快取完整提示，除非您先對其進行修剪。
- **什麼變便宜了：** 修剪減少了 TTL 過期後第一次請求的 **cacheWrite** 大小。
- **為何 TTL 重置很重要：** 一旦執行修剪，快取窗口就會重置，因此後續請求可以重用新快取的提示，而不是再次重新快取完整歷史。
- **它不會做什麼：** 修剪不會增加 token 或「加倍」成本；它只會改變 TTL 後第一次請求中被快取的內容。

## 哪些內容可以被修剪
- 僅限 `toolResult` 訊息。
- 使用者 + 助手訊息**絕不會**被修改。
- 最後 `keepLastAssistants` 個助手訊息受到保護；該切斷點之後的工具結果不被修剪。
- 如果沒有足夠的助手訊息來建立切斷點，則跳過修剪。
- 包含**圖片區塊 (image blocks)** 的工具結果會被跳過（絕不修剪/清除）。

## 上下文視窗估計
修剪使用估計的上下文視窗（字元數 ≈ token 數 × 4）。視窗大小按以下順序解析：
1) 模型定義的 `contextWindow`（來自模型註冊表）。
2) `models.providers.*.models[].contextWindow` 覆寫值。
3) `agents.defaults.contextTokens`。
4) 預設 `200000` tokens。

## 模式
### cache-ttl
- 僅在最後一次 Anthropic 呼叫早於 `ttl`（預設 `5m`）時執行修剪。
- 執行時：與之前相同的軟修剪 (soft-trim) + 硬清除 (hard-clear) 行為。

## 軟修剪 vs 硬清除
- **軟修剪 (Soft-trim)**：僅針對過大的工具結果。
  - 保留頭部 + 尾部，插入 `...`，並附上原始大小的說明。
  - 跳過帶有圖片區塊的結果。
- **硬清除 (Hard-clear)**：將整個工具結果替換為 `hardClear.placeholder`。

## 工具選擇
- `tools.allow` / `tools.deny` 支援 `*` 通配符。
- 拒絕優先。
- 匹配不區分大小寫。
- 空的允許清單 => 允許所有工具。

## 與其他限制的互動
- 內建工具已經會截斷自己的輸出；會話修剪是一個額外的層級，防止長時間運行的聊天在模型上下文中累積過多工具輸出。
- 壓縮 (Compaction) 是分開的：壓縮會進行摘要並持久化，而修剪是針對每個請求的暫時行為。請參閱 [/concepts/compaction](/concepts/compaction)。

## 預設值（啟用時）
- `ttl`: `"5m"`
- `keepLastAssistants`: `3`
- `softTrimRatio`: `0.3`
- `hardClearRatio`: `0.5`
- `minPrunableToolChars`: `50000`
- `softTrim`: `{ maxChars: 4000, headChars: 1500, tailChars: 1500 }`
- `hardClear`: `{ enabled: true, placeholder: "[Old tool result content cleared]" }`

## 範例
預設（關閉）：
```json5
{
  agent: {
    contextPruning: { mode: "off" }
  }
}
```

啟用 TTL 感知修剪：
```json5
{
  agent: {
    contextPruning: { mode: "cache-ttl", ttl: "5m" }
  }
}
```

限制修剪特定工具：
```json5
{
  agent: {
    contextPruning: {
      mode: "cache-ttl",
      tools: { allow: ["exec", "read"], deny: ["*image*"] }
    }
  }
}
```

請參閱設定參考：[Gateway 設定](/gateway/configuration)
