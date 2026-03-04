---
title: "Diffs（Diffs）"
summary: "代理的唯讀 diff 檢視器和檔案渲染器（選擇性外掛工具）"
description: "使用可選 Diffs 外掛以將文字前後或統一修補程式渲染為 gateway 代管的 diff 檢視、檔案（PNG 或 PDF）或兩者。"
read_when:
  - You want agents to show code or markdown edits as diffs
  - You want a canvas-ready viewer URL or a rendered diff file
  - You need controlled, temporary diff artifacts with secure defaults
---

# Diffs

`diffs` 是一個可選外掛工具，將變更內容轉換為唯讀 diff 工件。

它接受：

- `before` 和 `after` 文字
- 統一的 `patch`

它可以返回：

- 用於畫布演示的 gateway 檢視器 URL
- 渲染的檔案路徑（PNG 或 PDF）用於訊息傳遞
- 兩個輸出都在一次呼叫中

## 快速開始

1. 啟用外掛。
2. 使用 `mode: "view"` 呼叫 `diffs` 用於畫布優先流程。
3. 使用 `mode: "file"` 呼叫 `diffs` 用於聊天檔案傳遞流程。
4. 使用 `mode: "both"` 當需要兩個工件時。

## 啟用外掛

```json5
{
  plugins: {
    entries: {
      diffs: {
        enabled: true,
      },
    },
  },
}
```

詳見英文文件以了解完整配置...（篇幅限制）
