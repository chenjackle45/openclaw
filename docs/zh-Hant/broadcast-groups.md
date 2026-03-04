---
summary: "廣播 WhatsApp 訊息到多個代理"
read_when:
  - 設定廣播群組
  - 在 WhatsApp 中偵錯多代理回覆
status: experimental
title: "Broadcast Groups（廣播群組）"
---

# 廣播群組

**狀態：** 實驗性  
**版本：** 在 2026.1.9 中新增

## 概述

廣播群組使多個代理能夠同時處理並回應相同的訊息。這使您能夠建立專門的代理團隊，在單一 WhatsApp 群組或 DM 中一起工作 — 全部使用一個電話號碼。

當前範圍：**僅 WhatsApp**（Web 頻道）。

廣播群組在頻道允許清單和群組啟動規則之後進行評估。在 WhatsApp 群組中，這意味著廣播發生在 OpenClaw 通常會回覆的時候（例如：在提及時，取決於您的群組設定）。

## 使用案例

### 1. 專門代理團隊

部署多個具有原子型、聚焦責任的代理：

```
群組："Development Team"
代理：
  - CodeReviewer（審查程式碼片段）
  - DocumentationBot（產生文件）
  - SecurityAuditor（檢查漏洞）
  - TestGenerator（建議測試案例）
```

每個代理處理相同的訊息並提供其專業視角。

### 2. 多語言支援

```
群組："International Support"
代理：
  - Agent_EN（以英文回應）
  - Agent_DE（以德文回應）
  - Agent_ES（以西班牙文回應）
```

### 3. 品質保證工作流程

```
群組："Customer Support"
代理：
  - SupportAgent（提供回答）
  - QAAgent（檢查品質，僅在發現問題時回應）
```

### 4. 任務自動化

```
群組："Project Management"
代理：
  - TaskTracker（更新任務資料庫）
  - TimeLogger（記錄花費的時間）
  - ReportGenerator（建立摘要）
```

## 設定

### 基本設定

在頂級新增 `broadcast` 區段（在 `bindings` 旁邊）。鍵是 WhatsApp peer ID：

- 群組聊天：群組 JID（例如 `120363403215116621@g.us`）
- DM：E.164 電話號碼（例如 `+15551234567`）

```json
{
  "broadcast": {
    "120363403215116621@g.us": ["alfred", "baerbel", "assistant3"]
  }
}
```

**結果：** 當 OpenClaw 會在此聊天中回覆時，它將執行所有三個代理。

### 處理策略

控制代理處理訊息的方式：

#### 平行（預設）

所有代理同時處理：

```json
{
  "broadcast": {
    "strategy": "parallel",
    "120363403215116621@g.us": ["alfred", "baerbel"]
  }
}
```

#### 連續

代理依序處理（一個等待前一個完成）：

```json
{
  "broadcast": {
    "strategy": "sequential",
    "120363403215116621@g.us": ["alfred", "baerbel"]
  }
}
```

### 完整範例

```json
{
  "agents": {
    "list": [
      {
        "id": "code-reviewer",
        "name": "Code Reviewer",
        "workspace": "/path/to/code-reviewer",
        "sandbox": { "mode": "all" }
      },
      {
        "id": "security-auditor",
        "name": "Security Auditor",
        "workspace": "/path/to/security-auditor",
        "sandbox": { "mode": "all" }
      },
      {
        "id": "docs-generator",
        "name": "Documentation Generator",
        "workspace": "/path/to/docs-generator",
        "sandbox": { "mode": "all" }
      }
    ]
  },
  "broadcast": {
    "strategy": "parallel",
    "120363403215116621@g.us": ["code-reviewer", "security-auditor", "docs-generator"],
    "120363424282127706@g.us": ["support-en", "support-de"],
    "+15555550123": ["assistant", "logger"]
  }
}
```

## 如何運作

### 訊息流程

1. **傳入訊息**到達 WhatsApp 群組
2. **廣播檢查**：系統檢查 peer ID 是否在 `broadcast` 中
3. **如果在廣播清單中**：
   - 所有列出的代理處理訊息
   - 每個代理都有其自己的會話金鑰和隔離的上下文
   - 代理平行（預設）或連續處理
4. **如果不在廣播清單中**：
   - 正常路由適用（第一個相符的綁定）

注意：廣播群組不會繞過頻道允許清單或群組啟動規則（提及/命令/等）。它們只在訊息符合處理條件時改變*哪些代理執行*。

### 會話隔離

廣播群組中的每個代理保持完全獨立的：

- **會話金鑰**（`agent:alfred:whatsapp:group:120363...` vs `agent:baerbel:whatsapp:group:120363...`）
- **對話歷史**（代理看不到其他代理的訊息）
- **工作區**（如果設定，單獨的沙箱）
- **工具存取**（不同的允許/拒絕清單）
- **記憶/上下文**（單獨的 IDENTITY.md、SOUL.md 等）
- **群組上下文緩衝**（用於上下文的最近群組訊息）按 peer 共享，所以所有廣播代理在觸發時看到相同的上下文

這使每個代理能夠有：

- 不同的個性
- 不同的工具存取（例如，唯讀 vs 讀寫）
- 不同的模型（例如，opus vs sonnet）
- 安裝的不同技能

### 範例：隔離會話

在具有代理 `["alfred", "baerbel"]` 的群組 `120363403215116621@g.us` 中：

**Alfred 的上下文：**

```
會話：agent:alfred:whatsapp:group:120363403215116621@g.us
歷史：[使用者訊息、alfred 的先前回應]
工作區：/Users/pascal/openclaw-alfred/
工具：讀、寫、執行
```

**Bärbel 的上下文：**

```
會話：agent:baerbel:whatsapp:group:120363403215116621@g.us
歷史：[使用者訊息、baerbel 的先前回應]
工作區：/Users/pascal/openclaw-baerbel/
工具：僅讀
```

## 最佳實踐

### 1. 保持代理聚焦

使用單一、清晰的責任設計每個代理：

```json
{
  "broadcast": {
    "DEV_GROUP": ["formatter", "linter", "tester"]
  }
}
```

✅ **好：** 每個代理有一項工作  
❌ **不好：** 一個通用的「dev-helper」代理

### 2. 使用描述性名稱

清楚說明每個代理做什麼：

```json
{
  "agents": {
    "security-scanner": { "name": "Security Scanner" },
    "code-formatter": { "name": "Code Formatter" },
    "test-generator": { "name": "Test Generator" }
  }
}
```

### 3. 設定不同的工具存取

只給代理它們需要的工具：

```json
{
  "agents": {
    "reviewer": {
      "tools": { "allow": ["read", "exec"] } // 唯讀
    },
    "fixer": {
      "tools": { "allow": ["read", "write", "edit", "exec"] } // 讀寫
    }
  }
}
```

### 4. 監控效能

在許多代理中，考慮：

- 使用 `"strategy": "parallel"`（預設）以獲得速度
- 將廣播群組限制為 5-10 個代理
- 為更簡單的代理使用更快的模型

### 5. 優雅地處理故障

代理獨立失敗。一個代理的錯誤不會阻止其他代理：

```
訊息 → [代理 A ✓、代理 B ✗ 錯誤、代理 C ✓]
結果：代理 A 和 C 回應，代理 B 記錄錯誤
```

## 相容性

### 供應商

廣播群組目前適用於：

- ✅ WhatsApp（已實現）
- 🚧 Telegram（計畫中）
- 🚧 Discord（計畫中）
- 🚧 Slack（計畫中）

### 路由

廣播群組與現有路由一起運作：

```json
{
  "bindings": [
    {
      "match": { "channel": "whatsapp", "peer": { "kind": "group", "id": "GROUP_A" } },
      "agentId": "alfred"
    }
  ],
  "broadcast": {
    "GROUP_B": ["agent1", "agent2"]
  }
}
```

- `GROUP_A`：僅 alfred 回應（正常路由）
- `GROUP_B`：agent1 AND agent2 回應（廣播）

**優先順序：** `broadcast` 優先於 `bindings`。

## 故障排除

### 代理未回應

**檢查：**

1. 代理 ID 存在於 `agents.list`
2. Peer ID 格式正確（例如，`120363403215116621@g.us`）
3. 代理不在拒絕清單中

**偵錯：**

```bash
tail -f ~/.openclaw/logs/gateway.log | grep broadcast
```

### 僅一個代理回應

**原因：** Peer ID 可能在 `bindings` 中但不在 `broadcast` 中。

**修復：** 新增至廣播設定或從綁定中移除。

### 效能問題

**如果許多代理很慢：**

- 減少每個群組的代理數量
- 使用較輕的模型（sonnet 而不是 opus）
- 檢查沙箱啟動時間

## 範例

### 範例 1：程式碼審查團隊

```json
{
  "broadcast": {
    "strategy": "parallel",
    "120363403215116621@g.us": [
      "code-formatter",
      "security-scanner",
      "test-coverage",
      "docs-checker"
    ]
  },
  "agents": {
    "list": [
      {
        "id": "code-formatter",
        "workspace": "~/agents/formatter",
        "tools": { "allow": ["read", "write"] }
      },
      {
        "id": "security-scanner",
        "workspace": "~/agents/security",
        "tools": { "allow": ["read", "exec"] }
      },
      {
        "id": "test-coverage",
        "workspace": "~/agents/testing",
        "tools": { "allow": ["read", "exec"] }
      },
      { "id": "docs-checker", "workspace": "~/agents/docs", "tools": { "allow": ["read"] } }
    ]
  }
}
```

**使用者傳送：** 程式碼片段  
**回應：**

- code-formatter："修復縮排並新增型別提示"
- security-scanner："⚠️ 第 12 行中的 SQL 注入漏洞"
- test-coverage："覆蓋率為 45%，缺少錯誤案例的測試"
- docs-checker："缺少函式 `process_data` 的文件字串"

### 範例 2：多語言支援

```json
{
  "broadcast": {
    "strategy": "sequential",
    "+15555550123": ["detect-language", "translator-en", "translator-de"]
  },
  "agents": {
    "list": [
      { "id": "detect-language", "workspace": "~/agents/lang-detect" },
      { "id": "translator-en", "workspace": "~/agents/translate-en" },
      { "id": "translator-de", "workspace": "~/agents/translate-de" }
    ]
  }
}
```

## API 參考

### 配置架構

```typescript
interface OpenClawConfig {
  broadcast?: {
    strategy?: "parallel" | "sequential";
    [peerId: string]: string[];
  };
}
```

### 欄位

- `strategy`（選用）：如何處理代理
  - `"parallel"`（預設）：所有代理同時處理
  - `"sequential"`：代理依序處理
- `[peerId]`：WhatsApp 群組 JID、E.164 號碼或其他 peer ID
  - 值：應處理訊息的代理 ID 陣列

## 限制

1. **最大代理：** 無硬性限制，但 10+ 個代理可能很慢
2. **共享上下文：** 代理看不到彼此的回應（根據設計）
3. **訊息順序：** 平行回應可能按任何順序到達
4. **速率限制：** 所有代理計入 WhatsApp 速率限制

## 未來增強

計畫的功能：

- [ ] 共享上下文模式（代理看到彼此的回應）
- [ ] 代理協調（代理可以相互發信號）
- [ ] 動態代理選擇（根據訊息內容選擇代理）
- [ ] 代理優先順序（某些代理在其他代理之前回應）

## 另見

- [多代理設定](/zh-Hant/tools/multi-agent-sandbox-tools)
- [路由設定](/zh-Hant/channels/channel-routing)
- [會話管理](/zh-Hant/concepts/session)
