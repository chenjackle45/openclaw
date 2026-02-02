# 翻譯規則

## 基本原則

| 項目 | 處理方式 |
|------|----------|
| 一般文字 | 翻譯成繁體中文（台灣用語）|
| 技術術語 | 保留英文（API, CLI, Gateway, WebSocket, OAuth 等）|
| 程式碼區塊 | 不翻譯 |
| frontmatter title | 英文原文在前，括號標註中文翻譯，格式：`"English Title（中文標題）"` |
| frontmatter summary | 翻譯 |
| 連結路徑 | 不翻譯，保持原樣 |
| Markdown 格式 | 保持原樣 |

## 常見技術術語（保留英文）

- API, CLI, SDK, MCP
- Gateway, WebSocket, OAuth
- Token, Agent, Provider
- Webhook, Polling, Heartbeat
- YAML, JSON, Markdown
- Docker, Node.js, npm, pnpm

## 範例

### 原文
```markdown
---
title: "Getting Started"
summary: "Learn how to set up your OpenClaw Gateway"
---

# Getting Started

Install the CLI using npm:
```

### 翻譯後
```markdown
---
title: "Getting Started（開始使用）"
summary: "學習如何設定你的 OpenClaw Gateway"
---

# Getting Started（開始使用）

使用 npm 安裝 CLI：
```

## 注意事項

- 不要加入額外的說明或註解
- 保持原本的段落結構
- 連結路徑不要修改
