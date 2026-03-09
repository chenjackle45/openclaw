---
title: "Tool-loop detection（工具迴圈偵測）"
description: "設定防止重複或停滯工具呼叫迴圈的可選護欄"
summary: "如何啟用並調整偵測重複工具呼叫迴圈的護欄"
read_when:
  - 使用者回報 agent 卡在重複的工具呼叫中
  - 你需要調整重複呼叫保護
  - 你正在編輯 agent 工具/執行期政策
---

# Tool-loop detection

OpenClaw 可防止 agent 卡在重複的工具呼叫模式中。此護欄**預設停用**。

請僅在有需要時啟用，因為嚴格設定可能會封鎖合法的重複呼叫。

## 存在的原因

- 偵測無法取得進展的重複序列。
- 偵測高頻無結果迴圈（相同工具、相同輸入、重複錯誤）。
- 偵測已知輪詢工具的特定重複呼叫模式。

## 設定區塊

全域預設值：

```json5
{
  tools: {
    loopDetection: {
      enabled: false,
      historySize: 30,
      warningThreshold: 10,
      criticalThreshold: 20,
      globalCircuitBreakerThreshold: 30,
      detectors: {
        genericRepeat: true,
        knownPollNoProgress: true,
        pingPong: true,
      },
    },
  },
}
```

每個 agent 的覆寫（可選）：

```json5
{
  agents: {
    list: [
      {
        id: "safe-runner",
        tools: {
          loopDetection: {
            enabled: true,
            warningThreshold: 8,
            criticalThreshold: 16,
          },
        },
      },
    ],
  },
}
```

### 欄位行為

- `enabled`：主開關。`false` 表示不執行迴圈偵測。
- `historySize`：保留用於分析的最近工具呼叫數量。
- `warningThreshold`：將模式分類為僅警告前的閾值。
- `criticalThreshold`：封鎖重複迴圈模式的閾值。
- `globalCircuitBreakerThreshold`：全域無進展斷路閾值。
- `detectors.genericRepeat`：偵測重複的相同工具 + 相同參數模式。
- `detectors.knownPollNoProgress`：偵測沒有狀態變化的已知輪詢類模式。
- `detectors.pingPong`：偵測交替乒乓模式。

## 建議設定

- 以 `enabled: true` 開始，保持預設值不變。
- 保持閾值順序：`warningThreshold < criticalThreshold < globalCircuitBreakerThreshold`。
- 若發生誤判：
  - 提高 `warningThreshold` 和/或 `criticalThreshold`
  - （可選）提高 `globalCircuitBreakerThreshold`
  - 僅停用造成問題的偵測器
  - 減少 `historySize` 以降低歷史 context 嚴格度

## 日誌與預期行為

偵測到迴圈時，OpenClaw 會回報迴圈事件，並根據嚴重程度封鎖或抑制下一個工具週期。
這可保護使用者免於失控的 token 消耗和鎖死，同時維持正常的工具存取。

- 優先使用警告和暫時抑制。
- 僅在重複證據累積時才升級。

## 注意事項

- `tools.loopDetection` 與 agent 層級的覆寫合併。
- 每個 agent 的設定完全覆寫或擴充全域值。
- 若不存在設定，護欄保持關閉。
