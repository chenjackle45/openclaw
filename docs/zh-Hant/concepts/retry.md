---
title: "Retry(重試機制)"
summary: "出站供應商呼叫的重試原則"
---
# Retry policy（重試原則）

## 目標
- 針對每個 HTTP 請求進行重試，而不是針對整個多步驟流程。
- 透過僅重試目前的步驟來保持順序。
- 避免重複執行非等冪 (non-idempotent) 的操作。

## 預設值
- 嘗試次數：3
- 最大延遲上限：30000 毫秒 (ms)
- 抖動 (Jitter)：0.1 (10%)
- 供應商預設值：
  - Telegram 最小延遲：400 ms
  - Discord 最小延遲：500 ms

## 行為
### Discord
- 僅在速率限制錯誤（HTTP 429）時進行重試。
- 如果有提供 Discord 的 `retry_after` 則使用之，否則使用指數退避。

### Telegram
- 在瞬時錯誤（429、超時、連線重置/關閉、暫時不可用）時進行重試。
- 如果有提供 `retry_after` 則使用之，否則使用指數退避。
- Markdown 解析錯誤不會重試；它們會回退到純文字。

## 設定
在 `~/.openclaw/openclaw.json` 中設定每個供應商的重試原則：

```json5
{
  channels: {
    telegram: {
      retry: {
        attempts: 3,
        minDelayMs: 400,
        maxDelayMs: 30000,
        jitter: 0.1
      }
    },
    discord: {
      retry: {
        attempts: 3,
        minDelayMs: 500,
        maxDelayMs: 30000,
        jitter: 0.1
      }
    }
  }
}
```

## 備註
- 重試適用於每個請求（發送訊息、上傳媒體、表情回應、投票、貼圖）。
- 複合流程不會重試已完成的步驟。
