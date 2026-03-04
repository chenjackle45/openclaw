---
title: "Tool-loop detection（工具迴圈偵測）"
description: "設定防止重複或停滯工具呼叫迴圈的可選護欄"
summary: "如何啟用和調整檢測重複工具呼叫迴圈的護欄"
read_when:
  - A user reports agents getting stuck repeating tool calls
  - You need to tune repetitive-call protection
  - You are editing agent tool/runtime policies
---

# 工具迴圈偵測

OpenClaw 可以防止代理卡在重複工具呼叫模式中。
護欄**預設停用**。

只在需要的地方啟用，因為它可以用嚴格設定阻止合法重複呼叫。

## 為什麼存在

- 偵測不進行任何進展的重複序列。
- 偵測高頻無結果迴圈（相同工具、相同輸入、重複錯誤）。
- 偵測已知輪詢工具的特定重複呼叫模式。

## 設定區塊

全域預設值：

```json5
{
  tools: {
    loopDetection: {
      enabled: false,
      historySize: 20,
      detectorCooldownMs: 12000,
      repeatThreshold: 3,
      criticalThreshold: 6,
      detectors: {
        repeatedFailure: true,
        knownPollLoop: true,
        repeatingNoProgress: true,
      },
    },
  },
}
```

詳見英文文件以了解完整配置...（篇幅限制）
