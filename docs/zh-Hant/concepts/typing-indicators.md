---
title: "Typing indicators(輸入指示器)"
summary: "OpenClaw 何時顯示輸入指示器以及如何調整它們"
read_when:
  - 更改輸入指示器行為或預設值
---
# Typing indicators（輸入指示器）

當有運行處於活動狀態時，輸入指示器（Typing indicators）會被發送到聊天頻道。使用 `agents.defaults.typingMode` 控制**何時**開始顯示輸入指示，並使用 `typingIntervalSeconds` 控制其重新整理的**頻率**。

## 預設值
當 `agents.defaults.typingMode` **未設定**時，OpenClaw 保持舊有行為：
- **直接聊天**：一旦模型循環開始，立即顯示輸入中。
- **帶有提及的群組聊天**：立即顯示輸入中。
- **不帶提及的群組聊天**：僅當訊息文字開始串流時才顯示輸入中。
- **心跳 (Heartbeat) 運行**：停用輸入指示。

## 模式
將 `agents.defaults.typingMode` 設定為以下之一：
- `never` — 永不顯示輸入指示。
- `instant` — **模型循環一開始**就發送輸入中，即使該次運行最後僅返回靜默回覆權仗。
- `thinking` — 在**第一個推理 (reasoning) 增量**時顯示輸入中（此運行需具備 `reasoningLevel: "stream"`）。
- `message` — 在**第一個非靜默文字增量**時顯示輸入中（忽略 `NO_REPLY` 權仗）。

「觸發早晚」順序：
`never` → `message` → `thinking` → `instant`

## 設定
```json5
{
  agent: {
    typingMode: "thinking",
    typingIntervalSeconds: 6
  }
}
```

您可以按會話覆寫模式或頻率：
```json5
{
  session: {
    typingMode: "message",
    typingIntervalSeconds: 4
  }
}
```

## 備註
- `message` 模式在僅有靜默回覆時（例如使用 `NO_REPLY` 權令牌抑制輸出）不會顯示輸入中。
- `thinking` 模式僅在運行串流推理過程時生效。如果模型不發送推理增量，則不會顯示輸入中。
- 無論何種模式，心跳運行都絕不顯示輸入中。
- `typingIntervalSeconds` 控制的是**重新整理頻率**，而非啟動時間。預設為 6 秒。
