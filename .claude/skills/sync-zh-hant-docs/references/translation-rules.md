# 翻譯規則

## 基本原則

| 項目                | 處理方式                                                                |
| ------------------- | ----------------------------------------------------------------------- |
| 一般文字            | 翻譯成繁體中文（台灣用語）                                              |
| 技術術語            | 保留英文（API, CLI, Gateway, WebSocket, OAuth 等）                      |
| 程式碼區塊          | 不翻譯                                                                  |
| frontmatter title   | **必須**使用全形括號，英文原文在前，格式：`"English Title（中文標題）"` |
| frontmatter summary | 翻譯成中文                                                              |
| 連結路徑            | 不翻譯，保持原樣                                                        |
| Markdown 格式       | 保持原樣                                                                |

## frontmatter title 格式（重要）

**這是最常出錯的地方，請務必遵守：**

### 正確格式

```
title: "English Title（中文翻譯）"
```

- 使用**全形括號** `（）`，不是半形 `()`
- **英文在前**，中文在括號內
- 英文部分必須與英文原檔的 title 完全一致

### 錯誤範例

```
❌ title: "開始使用"                        # 只有中文
❌ title: "Getting Started"                  # 只有英文（除非是品牌名）
❌ title: "開始使用（Getting Started）"      # 中文在前
❌ title: "Getting Started(開始使用)"        # 使用半形括號
❌ title: "getting started（開始使用）"      # 英文大小寫不一致
```

### 品牌名例外

以下品牌名/專有名詞不需要加中文翻譯，直接保留英文即可：

Discord, Telegram, WhatsApp, Signal, Slack, LINE, Matrix, Mattermost,
iMessage, Google Chat, Microsoft Teams, Anthropic, OpenAI, Webhooks,
BlueBubbles, grammY, Nostr, Tlon, Twitch, Zalo, Amazon Bedrock,
Gmail PubSub, GitHub Copilot, Firecrawl, ClawdHub

### 正確範例

```markdown
title: "Getting Started（開始使用）" # 一般頁面
title: "Agent Loop（Agent 迴圈）" # 技術術語保留
title: "CLI Backends（CLI 後端）" # 縮寫保留
title: "Discord" # 品牌名，不加中文
title: "Cron Jobs（排程任務）" # 英文概念+中文翻譯
```

## 常見技術術語（保留英文）

- API, CLI, SDK, MCP, RPC
- Gateway, WebSocket, OAuth, SSO
- Token, Agent, Provider, Plugin
- Webhook, Polling, Heartbeat, Cron
- YAML, JSON, Markdown, TypeBox
- Docker, Node.js, npm, pnpm, Bun

## 完整翻譯範例

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
- frontmatter title 的英文部分必須與英文原檔完全一致
- 全形括號 `（）` 不可用半形 `()`
