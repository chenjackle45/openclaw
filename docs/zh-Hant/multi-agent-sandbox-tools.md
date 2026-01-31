---
title: "Multi agent sandbox tools(多代理沙盒與工具)"
summary: "每個代理的沙盒 + 工具限制、優先順序和範例"
read_when: "您想要在多代理 gateway 中實現每個代理的沙盒或每個代理的工具 allow/deny 策略。"
status: active
---

# Multi-Agent Sandbox & Tools Configuration(多代理沙盒與工具設定)

## 概覽

多代理設定中的每個代理現在可以擁有自己的：
- **沙盒設定**（`agents.list[].sandbox` 覆蓋 `agents.defaults.sandbox`）
- **工具限制**（`tools.allow` / `tools.deny`，加上 `agents.list[].tools`）

這允許您執行具有不同安全設定檔的多個代理：
- 具有完全存取權限的個人助理
- 具有受限工具的家庭/工作代理
- 沙盒中的面向公眾的代理

`setupCommand` 屬於 `sandbox.docker`（全域或每個代理）下，並在容器建立時執行一次。

認證是每個代理的：每個代理從其自己的 `agentDir` 認證儲存中讀取，位於：

```
~/.openclaw/agents/<agentId>/agent/auth-profiles.json
```

憑證在代理之間**不共享**。絕不要跨代理重複使用 `agentDir`。
如果您想要共享憑證，請將 `auth-profiles.json` 複製到其他代理的 `agentDir`。

有關沙盒在執行時的行為方式，請參閱 [Sandboxing](/gateway/sandboxing)。
有關除錯「為什麼這被阻止？」，請參閱 [Sandbox vs Tool Policy vs Elevated](/gateway/sandbox-vs-tool-policy-vs-elevated) 和 `openclaw sandbox explain`。

---

## 設定範例

### 範例 1：個人 + 受限家庭代理

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "name": "Personal Assistant",
        "workspace": "~/.openclaw/workspace",
        "sandbox": { "mode": "off" }
      },
      {
        "id": "family",
        "name": "Family Bot",
        "workspace": "~/.openclaw/workspace-family",
        "sandbox": {
          "mode": "all",
          "scope": "agent"
        },
        "tools": {
          "allow": ["read"],
          "deny": ["exec", "write", "edit", "apply_patch", "process", "browser"]
        }
      }
    ]
  },
  "bindings": [
    {
      "agentId": "family",
      "match": {
        "provider": "whatsapp",
        "accountId": "*",
        "peer": {
          "kind": "group",
          "id": "120363424282127706@g.us"
        }
      }
    }
  ]
}
```

**結果：**
- `main` 代理：在主機上執行，完全工具存取
- `family` 代理：在 Docker 中執行（每個代理一個容器），僅 `read` 工具

---

### 範例 2：具有共享沙盒的工作代理

```json
{
  "agents": {
    "list": [
      {
        "id": "personal",
        "workspace": "~/.openclaw/workspace-personal",
        "sandbox": { "mode": "off" }
      },
      {
        "id": "work",
        "workspace": "~/.openclaw/workspace-work",
        "sandbox": {
          "mode": "all",
          "scope": "shared",
          "workspaceRoot": "/tmp/work-sandboxes"
        },
        "tools": {
          "allow": ["read", "write", "apply_patch", "exec"],
          "deny": ["browser", "gateway", "discord"]
        }
      }
    ]
  }
}
```

---

### 範例 2b：全域 coding profile + 僅訊息代理

```json
{
  "tools": { "profile": "coding" },
  "agents": {
    "list": [
      {
        "id": "support",
        "tools": { "profile": "messaging", "allow": ["slack"] }
      }
    ]
  }
}
```

**結果：**
- 預設代理獲得 coding 工具
- `support` 代理僅訊息（+ Slack 工具）

---

### 範例 3：每個代理不同的沙盒模式

```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",  // 全域預設
        "scope": "session"
      }
    },
    "list": [
      {
        "id": "main",
        "workspace": "~/.openclaw/workspace",
        "sandbox": {
          "mode": "off"  // 覆蓋：main 從不沙盒
        }
      },
      {
        "id": "public",
        "workspace": "~/.openclaw/workspace-public",
        "sandbox": {
          "mode": "all",  // 覆蓋：public 總是沙盒
          "scope": "agent"
        },
        "tools": {
          "allow": ["read"],
          "deny": ["exec", "write", "edit", "apply_patch"]
        }
      }
    ]
  }
}
```

---

## 設定優先順序

當全域（`agents.defaults.*`）和代理特定（`agents.list[].*`）設定都存在時：

### 沙盒設定
代理特定設定覆蓋全域：
```
agents.list[].sandbox.mode > agents.defaults.sandbox.mode
agents.list[].sandbox.scope > agents.defaults.sandbox.scope
agents.list[].sandbox.workspaceRoot > agents.defaults.sandbox.workspaceRoot
agents.list[].sandbox.workspaceAccess > agents.defaults.sandbox.workspaceAccess
agents.list[].sandbox.docker.* > agents.defaults.sandbox.docker.*
agents.list[].sandbox.browser.* > agents.defaults.sandbox.browser.*
agents.list[].sandbox.prune.* > agents.defaults.sandbox.prune.*
```

**注意事項：**
- `agents.list[].sandbox.{docker,browser,prune}.*` 覆蓋該代理的 `agents.defaults.sandbox.{docker,browser,prune}.*`（當沙盒範圍解析為 `"shared"` 時忽略）。

### 工具限制
過濾順序為：
1. **工具 profile**（`tools.profile` 或 `agents.list[].tools.profile`）
2. **供應商工具 profile**（`tools.byProvider[provider].profile` 或 `agents.list[].tools.byProvider[provider].profile`）
3. **全域工具策略**（`tools.allow` / `tools.deny`）
4. **供應商工具策略**（`tools.byProvider[provider].allow/deny`）
5. **代理特定工具策略**（`agents.list[].tools.allow/deny`）
6. **代理供應商策略**（`agents.list[].tools.byProvider[provider].allow/deny`）
7. **沙盒工具策略**（`tools.sandbox.tools` 或 `agents.list[].tools.sandbox.tools`）
8. **Subagent 工具策略**（`tools.subagents.tools`，如果適用）

每個層級可以進一步限制工具，但不能授予從較早層級拒絕的工具。
如果設定了 `agents.list[].tools.sandbox.tools`，它將取代該代理的 `tools.sandbox.tools`。
如果設定了 `agents.list[].tools.profile`，它將覆蓋該代理的 `tools.profile`。
供應商工具鍵接受 `provider`（例如 `google-antigravity`）或 `provider/model`（例如 `openai/gpt-5.2`）。

### 工具群組（速記）

工具策略（全域、代理、沙盒）支援 `group:*` 條目，這些條目擴展為多個具體工具：

- `group:runtime`：`exec`、`bash`、`process`
- `group:fs`：`read`、`write`、`edit`、`apply_patch`
- `group:sessions`：`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- `group:memory`：`memory_search`、`memory_get`
- `group:ui`：`browser`、`canvas`
- `group:automation`：`cron`、`gateway`
- `group:messaging`：`message`
- `group:nodes`：`nodes`
- `group:openclaw`：所有內建 OpenClaw 工具（排除供應商外掛）

### Elevated 模式
`tools.elevated` 是全域基準（基於發送者的允許清單）。`agents.list[].tools.elevated` 可以進一步限制特定代理的 elevated（兩者都必須允許）。

緩解模式：
- 對不受信任的代理拒絕 `exec`（`agents.list[].tools.deny: ["exec"]`）
- 避免將路由到受限代理的發送者列入允許清單
- 如果您只想要沙盒執行，請全域停用 elevated（`tools.elevated.enabled: false`）
- 對敏感設定檔禁用每個代理的 elevated（`agents.list[].tools.elevated.enabled: false`）

---

## 從單一代理遷移

**之前（單一代理）：**
```json
{
  "agents": {
    "defaults": {
      "workspace": "~/.openclaw/workspace",
      "sandbox": {
        "mode": "non-main"
      }
    }
  },
  "tools": {
    "sandbox": {
      "tools": {
        "allow": ["read", "write", "apply_patch", "exec"],
        "deny": []
      }
    }
  }
}
```

**之後（具有不同設定檔的多代理）：**
```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "~/.openclaw/workspace",
        "sandbox": { "mode": "off" }
      }
    ]
  }
}
```

舊版 `agent.*` 設定由 `openclaw doctor` 遷移；往後請優先使用 `agents.defaults` + `agents.list`。

---

## 工具限制範例

### 唯讀代理
```json
{
  "tools": {
    "allow": ["read"],
    "deny": ["exec", "write", "edit", "apply_patch", "process"]
  }
}
```

### 安全執行代理（無檔案修改）
```json
{
  "tools": {
    "allow": ["read", "exec", "process"],
    "deny": ["write", "edit", "apply_patch", "browser", "gateway"]
  }
}
```

### 僅通訊代理
```json
{
  "tools": {
    "allow": ["sessions_list", "sessions_send", "sessions_history", "session_status"],
    "deny": ["exec", "write", "edit", "apply_patch", "read", "browser"]
  }
}
```

---

## 常見陷阱："non-main"

`agents.defaults.sandbox.mode: "non-main"` 基於 `session.mainKey`（預設 `"main"`），
而不是代理 id。群組/頻道會話總是獲得它們自己的鍵，因此它們
被視為 non-main 並將被沙盒化。如果您希望代理從不
沙盒，請設定 `agents.list[].sandbox.mode: "off"`。

---

## 測試

設定多代理沙盒和工具後：

1. **檢查代理解析：**
   ```exec
   openclaw agents list --bindings
   ```

2. **驗證沙盒容器：**
   ```exec
   docker ps --filter "name=openclaw-sbx-"
   ```

3. **測試工具限制：**
   - 發送需要受限工具的訊息
   - 驗證代理無法使用被拒絕的工具

4. **監視日誌：**
   ```exec
   tail -f "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/logs/gateway.log" | grep -E "routing|sandbox|tools"
   ```

---

## 疑難排解

### 儘管 `mode: "all"`，代理未被沙盒化
- 檢查是否有全域 `agents.defaults.sandbox.mode` 覆蓋它
- 代理特定設定優先，因此請設定 `agents.list[].sandbox.mode: "all"`

### 工具儘管拒絕清單仍可用
- 檢查工具過濾順序：全域 → 代理 → 沙盒 → subagent
- 每個層級只能進一步限制，不能授予回來
- 使用日誌驗證：`[tools] filtering tools for agent:${agentId}`

### 容器未按代理隔離
- 在代理特定沙盒設定中設定 `scope: "agent"`
- 預設是 `"session"`，它為每個會話建立一個容器

---

## 另請參閱

- [Multi-Agent Routing](/concepts/multi-agent)
- [Sandbox Configuration](/gateway/configuration#agentsdefaults-sandbox)
- [Session Management](/concepts/session)
