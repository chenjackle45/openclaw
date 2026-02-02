---
title: "廣播群組"
summary: "向多個代理廣播 WhatsApp 訊息"
read_when:
  - 設定廣播群組
  - 除錯 WhatsApp 中的多代理回覆
status: experimental
---

# Broadcast Groups(廣播群組)

**狀態：** 實驗性  
**版本：** 於 2026.1.9 新增

## 概覽

廣播群組使多個代理能夠同時處理並回應相同訊息。這允許您建立專門的代理團隊，在單一 WhatsApp 群組或 DM 中協同工作 —  全部使用一個電話號碼。

當前範圍：**僅限 WhatsApp**（web 頻道）。

廣播群組在頻道允許清單和群組啟動規則之後評估。在 WhatsApp 群組中，這意味著當 OpenClaw 通常會回覆時（例如：提及時，取決於您的群組設定）會發生廣播。

## 使用案例

### 1. 專門代理團隊
部署具有原子、集中職責的多個代理：
```
群組：「Development Team」
代理：
  - CodeReviewer（審查程式碼片段）
  - DocumentationBot（生成文件）
  - SecurityAuditor（檢查漏洞）
  - TestGenerator（建議測試案例）
```

每個代理處理相同訊息並提供其專業視角。

### 2. 多語言支援
```
群組：「International Support」
代理：
  - Agent_EN（以英文回應）
  - Agent_DE（以德文回應）
  - Agent_ES（以西班牙文回應）
```

### 3. 品質保證工作流程
```
群組：「Customer Support」
代理：
  - SupportAgent（提供答案）
  - QAAgent（審查品質，僅在發現問題時回應）
```

### 4. 任務自動化
```
群組：「Project Management」
代理：
  - TaskTracker（更新任務資料庫）
  - TimeLogger（記錄花費時間）
  - ReportGenerator（建立摘要）
```

## 設定

### 基本設定

新增頂層 `broadcast` 區段（在 `bindings` 旁邊）。鍵是 WhatsApp peer ids：
- 群組聊天：group JID（例如 `120363403215116621@g.us`）
- DM：E.164 電話號碼（例如 `+15551234567`）

```json
{
  "broadcast": {
    "120363403215116621@g.us": ["alfred", "baerbel", "assistant3"]
  }
}
```

**結果：**當 OpenClaw 在此聊天中回覆時，它將執行所有三個代理。

### 處理策略

控制代理如何處理訊息：

#### Parallel（預設）
所有代理同時處理：
```json
{
  "broadcast": {
    "strategy": "parallel",
    "120363403215116621@g.us": ["alfred", "baerbel"]
  }
}
```

#### Sequential
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

## 運作方式

### 訊息流程

1. **入站訊息**到達 WhatsApp 群組
2. **廣播檢查**：系統檢查 peer ID 是否在 `broadcast` 中
3. **如果在廣播清單中**：
   - 所有列出的代理處理訊息
   - 每個代理都有自己的會話鍵和隔離上下文
   - 代理平行（預設）或依序處理
4. **如果不在廣播清單中**：
   - 套用正常路由（第一個匹配的綁定）

注意：廣播群組不會繞過頻道允許清單或群組啟動規則（提及/指令等）。它們只會變更訊息符合處理條件時*哪些代理執行*。

### 會話隔離

廣播群組中的每個代理維護完全分離的：

- **會話鍵**（`agent:alfred:whatsapp:group:120363...` vs `agent:baerbel:whatsapp:group:120363...`）
- **對話歷史**（代理看不到其他代理的訊息）
- **工作區**（如果設定，則為單獨的沙盒）
- **工具存取**（不同的 allow/deny 清單）
- **記憶/上下文**（單獨的 IDENTITY.md、SOUL.md 等）
- **群組上下文緩衝區**（用於上下文的最近群組訊息）按 peer 共享，因此所有廣播代理在觸發時看到相同的上下文

這允許每個代理擁有：
- 不同的個性
- 不同的工具存取（例如：唯讀 vs. 讀寫）
- 不同的模型（例如：opus vs. sonnet）
- 安裝不同的 skills

### 範例：隔離會話

在具有代理 `["alfred", "baerbel"]` 的群組 `120363403215116621@g.us` 中：

**Alfred 的上下文：**
```
會話：agent:alfred:whatsapp:group:120363403215116621@g.us
歷史：[使用者訊息，alfred 的先前回應]
工作區：/Users/pascal/openclaw-alfred/
工具：read、write、exec
```

**Bärbel 的上下文：**
```
會話：agent:baerbel:whatsapp:group:120363403215116621@g.us  
歷史：[使用者訊息，baerbel 的先前回應]
工作區：/Users/pascal/openclaw-baerbel/
工具：僅 read
```

## 最佳實踐

### 1. 保持代理專注

設計每個代理具有單一、明確的職責：

```json
{
  "broadcast": {
    "DEV_GROUP": ["formatter", "linter", "tester"]
  }
}
```

✅ **好：**每個代理有一個工作  
❌ **壞：**一個通用的「dev-helper」代理

### 2. 使用描述性名稱

清楚表明每個代理的作用：

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

僅給代理它們需要的工具：

```json
{
  "agents": {
    "reviewer": {
      "tools": { "allow": ["read", "exec"] }  // 唯讀
    },
    "fixer": {
      "tools": { "allow": ["read", "write", "edit", "exec"] }  // 讀寫
    }
  }
}
```

### 4. 監控效能

使用多個代理時，考慮：
- 使用 `"strategy": "parallel"`（預設）以提高速度
- 將廣播群組限制為 5-10 個代理
- 對較簡單的代理使用更快的模型

### 5. 優雅地處理失敗

代理獨立失敗。一個代理的錯誤不會阻止其他代理：

```
訊息 → [Agent A ✓, Agent B ✗ 錯誤, Agent C ✓]
結果：Agent A 和 C 回應，Agent B 記錄錯誤
```

## 相容性

### 供應商

廣播群組目前適用於：
- ✅ WhatsApp（已實作）
- 🚧 Telegram（計畫中）
- 🚧 Discord（計畫中）
- 🚧 Slack（計畫中）

### 路由

廣播群組與現有路由一起運作：

```json
{
  "bindings": [
    { "match": { "channel": "whatsapp", "peer": { "kind": "group", "id": "GROUP_A" } }, "agentId": "alfred" }
  ],
  "broadcast": {
    "GROUP_B": ["agent1", "agent2"]
  }
}
```

- `GROUP_A`：僅 alfred 回應（正常路由）
- `GROUP_B`：agent1 和 agent2 回應（廣播）

**優先順序：**`broadcast` 優先於 `bindings`。

## 疑難排解

### 代理未回應

**檢查：**
1. Agent ID 存在於 `agents.list` 中
2. Peer ID 格式正確（例如 `120363403215116621@g.us`）
3. 代理不在拒絕清單中

**除錯：**
```bash
tail -f ~/.openclaw/logs/gateway.log | grep broadcast
```

### 僅一個代理回應

**原因：**Peer ID 可能在 `bindings` 中但不在 `broadcast` 中。

**修復：**新增到廣播設定或從 bindings 中移除。

### 效能問題

**如果使用多個代理很慢：**
- 減少每組的代理數量
- 使用較輕的模型（sonnet 而非 opus）
- 檢查沙盒啟動時間

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
      { "id": "code-formatter", "workspace": "~/agents/formatter", "tools": { "allow": ["read", "write"] } },
      { "id": "security-scanner", "workspace": "~/agents/security", "tools": { "allow": ["read", "exec"] } },
      { "id": "test-coverage", "workspace": "~/agents/testing", "tools": { "allow": ["read", "exec"] } },
      { "id": "docs-checker", "workspace": "~/agents/docs", "tools": { "allow": ["read"] } }
    ]
  }
}
```

**使用者發送：**程式碼片段  
**回應：**
- code-formatter：「Fixed indentation and added type hints」
- security-scanner：「⚠️ SQL injection vulnerability in line 12」
- test-coverage：「Coverage is 45%, missing tests for error cases」
- docs-checker：「Missing docstring for function `process_data`」

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

### Config Schema

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
  - `"sequential"`：代理按陣列順序處理
  
- `[peerId]`：WhatsApp group JID、E.164 號碼或其他 peer ID
  - 值：應處理訊息的代理 ID 陣列

## 限制

1. **最大代理數：**無硬性限制，但 10+ 個代理可能很慢
2. **共享上下文：**代理看不到彼此的回應（設計如此）
3. **訊息順序：**平行回應可能以任何順序到達
4. **速率限制：**所有代理計入 WhatsApp 速率限制

## 未來增強

計畫中的功能：
- [ ] 共享上下文模式（代理看到彼此的回應）
- [ ] 代理協調（代理可以互相發出訊號）
- [ ] 動態代理選擇（基於訊息內容選擇代理）
- [ ] 代理優先順序（某些代理在其他代理之前回應）

## 另請參閱

- [Multi-Agent Configuration](/multi-agent-sandbox-tools)
- [Routing Configuration](/concepts/channel-routing)
- [Session Management](/concepts/sessions)
