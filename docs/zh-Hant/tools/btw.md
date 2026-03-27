---
summary: "使用 /btw 進行短暫側問查詢"
read_when:
  - 你想對目前工作階段提出快速側問
  - 你在實作或除錯跨客戶端的 BTW 行為
title: "BTW Side Questions（BTW 側問查詢）"
---

# BTW 側問查詢

`/btw` 可以讓你對**目前工作階段**提出快速側問，而不會將該問題轉換為一般對話歷史。

它是以 Claude Code 的 `/btw` 行為為基礎，但適配了 OpenClaw 的 Gateway 和多通道架構。

## 其運作原理

當你傳送：

```text
/btw what changed?
```

OpenClaw 會：

1. 快照目前的工作階段內容，
2. 執行一個獨立的**無工具**模型呼叫，
3. 只回答側問，
4. 保留主要執行流程不動，
5. **不會**將 BTW 問題或回答寫入工作階段歷史，
6. 將回答作為**直播側結果**而非一般助理訊息發出。

重要的心智模型是：

- 相同的工作階段內容
- 獨立的一次性側查詢
- 無工具呼叫
- 無未來內容污染
- 無記錄持久化

## 其不執行的事項

`/btw` **不會**：

- 建立新的永久工作階段，
- 繼續未完成的主要任務，
- 執行工具或代理工具迴圈，
- 將 BTW 問題/回答寫入記錄歷史，
- 出現在 `chat.history` 中，
- 在重新載入後存活。

它刻意是**短暫的**。

## 內容如何運作

BTW 只使用目前工作階段作為**背景內容**。

如果主要執行流程目前有效，OpenClaw 會快照目前訊息狀態，並將進行中的主提示作為背景內容，同時明確告訴模型：

- 只回答側問，
- 不要繼續或完成未完成的主要任務，
- 不要發出工具呼叫或虛擬工具呼叫。

這樣可保持 BTW 與主執行流程隔離，同時讓它仍能感知工作階段的內容。

## 傳遞模型

BTW **不是**作為一般助理記錄訊息傳遞的。

在 Gateway 協議層級：

- 一般助理聊天使用 `chat` 事件
- BTW 使用 `chat.side_result` 事件

這個分離是刻意的。如果 BTW 重複使用一般 `chat` 事件路徑，客戶端會將其視為一般對話歷史。

因為 BTW 使用獨立的直播事件，且不會從 `chat.history` 重新播放，所以它在重新載入後會消失。

## 表面行為

### TUI

在 TUI 中，BTW 在目前工作階段檢視中內嵌呈現，但仍保持短暫：

- 視覺上與一般助理回覆不同
- 可用 `Enter` 或 `Esc` 關閉
- 重新載入時不重新播放

### 外部通道

在 Telegram、WhatsApp 和 Discord 等通道上，BTW 是以清楚標籤的一次性回覆傳遞，因為這些表面不具有本地短暫疊加層概念。

該回答仍被視為側結果，而非一般工作階段歷史。

### 控制 UI / 網路

Gateway 會正確地將 BTW 作為 `chat.side_result` 發出，且 BTW 不包含在 `chat.history` 中，所以網路的持久化合約已正確。

目前的 Control UI 仍需要專用的 `chat.side_result` 消費者，以在瀏覽器中即時呈現 BTW。在該客戶端支援準備好之前，BTW 是具有完整 TUI 和外部通道行為的 Gateway 層級功能，但尚未具有完整瀏覽器 UX。

## 何時使用 BTW

當你想要以下情況時，請使用 `/btw`：

- 對目前工作的快速澄清，
- 長時間執行仍在進行時的事實側答案，
- 不應成為未來工作階段內容一部分的暫時答案。

範例：

```text
/btw what file are we editing?
/btw what does this error mean?
/btw summarize the current task in one sentence
/btw what is 17 * 19?
```

## 何時不使用 BTW

當你想讓回答成為工作階段未來工作內容的一部分時，不要使用 `/btw`。

在該情況下，改為在主工作階段中正常提問，而非使用 BTW。

## 相關

- [Slash 命令](/zh-Hant/tools/slash-commands)
- [思考層級](/zh-Hant/tools/thinking)
- [工作階段](/zh-Hant/concepts/session)
