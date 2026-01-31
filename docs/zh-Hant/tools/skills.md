---
title: "Skills(技能系統)"
summary: "技能：管理型與工作區技能、過濾規則以及配置與環境變數接入"
read_when:
  - 新增或修改技能時
  - 變更技能過濾或載入規則時
---

# 技能系統 (Skills)

OpenClaw 使用與 **[AgentSkills](https://agentskills.io) 相容**的技能資料夾來教導 Agent 如何使用工具。每個技能都是一個目錄，其中包含一個帶有 YAML 前置資料 (frontmatter) 與指令說明的 `SKILL.md`。OpenClaw 會載入**內置技能**以及選用的本地覆寫，並在載入時根據環境、配置與執行檔是否存在進行過濾。

## 位置與優先權

技能從**三個**地方載入：
1. **內置技能 (Bundled skills)**：隨安裝套件提供。
2. **管理/本地技能 (Managed/local skills)**：位於 `~/.openclaw/skills`。
3. **工作區技能 (Workspace skills)**：位於各 Agent 的 `<workspace>/skills`。

若名稱衝突，優先順序為：
**工作區 (**最高**) → 管理/本地 → 內置 (**最低**)**

## 每位 Agent vs 共用技能
- **個別 Agent 技能**：僅對該 Agent 可見。
- **共用技能**：位於 `~/.openclaw/skills`，對同一台機器上的**所有 Agent** 可見。

## ClawdHub (安裝與同步)
ClawdHub 是 OpenClaw 的公共技能註冊表。您可以透由 [clawdhub.com](https://clawdhub.com) 瀏覽其餘技能。
常用指令：
- `clawdhub install <slug>`：安裝技能至目前工作區。
- `clawdhub update --all`：更新所有已安裝技能。

## 格式規範 (SKILL.md)
`SKILL.md` 必須包含名稱與描述。OpenClaw 的解析器支援單行 JSON 物件格式的 `metadata`：
```markdown
---
name: 技能名稱
description: 技能描述
metadata: {"openclaw": {"requires": {"bins": ["執行檔名稱"]}}}
---
```

## 過濾機制 (Gating)
OpenClaw 在載入時會根據 `metadata` 進行過濾：
- `requires.bins`：清單中的執行檔必須存在於 `PATH` 中。
- `requires.env`：環境變數必須存在或已在配置中提供。
- `requires.config`：`openclaw.json` 中的特定路徑值必須為真值 (Truthy)。

## 配置覆寫
您可以在 `openclaw.json` 中啟用/停用技能並提供 API Key：
```json5
{
  skills: {
    entries: {
      "skill-name": {
        enabled: true,
        apiKey: "您的金鑰"
      }
    }
  }
}
```

## 注意事項
- **安全性**：第三方技能應視為自定義程式碼，請在啟用前先行閱讀內容。
- **Token 消耗**：每增加一個技能，系統提示詞約會增加 97 個字元（約 24 個 Tokens）的基礎開銷，再加上標題與描述的長度。
