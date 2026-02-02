---
title: "建立自訂 Skills"
---
# 建立自訂 Skills 🛠

OpenClaw 的設計易於擴展。「Skills」是為您的助手新增功能的主要方式。

## 什麼是 Skill？
Skill 是一個包含 `SKILL.md` 檔案（為 LLM 提供指令和 Tool 定義）的目錄，可選擇包含一些腳本或資源。

## 逐步教學：您的第一個 Skill

### 1. 建立目錄
Skills 位於您的 Workspace 中，通常是 `~/.openclaw/workspace/skills/`。為您的 Skill 建立一個新資料夾：
```bash
mkdir -p ~/.openclaw/workspace/skills/hello-world
```

### 2. 定義 `SKILL.md`
在該目錄中建立 `SKILL.md` 檔案。此檔案使用 YAML Frontmatter 作為 Metadata，Markdown 作為指令。

```markdown
---
name: hello_world
description: A simple skill that says hello.
---

# Hello World Skill
When the user asks for a greeting, use the `echo` tool to say "Hello from your custom skill!".
```

### 3. 新增 Tools（選用）
您可以在 Frontmatter 中定義自訂 Tools，或指示 Agent 使用現有的 System Tools（如 `bash` 或 `browser`）。

### 4. 重新整理 OpenClaw
請您的 Agent「refresh skills」或重新啟動 Gateway。OpenClaw 會探索新目錄並索引 `SKILL.md`。

## 最佳實踐
- **保持簡潔**：指示模型*要做什麼*，而非如何成為 AI。
- **安全第一**：如果您的 Skill 使用 `bash`，確保 Prompts 不會允許來自不受信任使用者輸入的任意指令注入。
- **本地測試**：使用 `openclaw agent --message "use my new skill"` 進行測試。

## 分享的 Skills
您也可以在 [ClawHub](https://clawhub.com) 瀏覽和貢獻 Skills。
