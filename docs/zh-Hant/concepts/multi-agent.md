---
title: "Multi agent(多代理路由)"
summary: "多代理路由：隔離的代理、頻道帳戶與綁定"
read_when:
  - 您想要在一個 Gateway 程序中運行多個隔離的代理（工作區 + 認證）
---
# Multi-Agent Routing（多代理路由）

目標：在一個運行的 Gateway 中擁有多個**隔離的**代理（獨立的工作區 + `agentDir` + 會話），以及多個頻道帳戶（例如兩個 WhatsApp）。入站訊息透過「綁定 (bindings)」路由到特定的代理。

## 什麼是「一個代理」？

一個**代理 (agent)** 是一個完全範圍化的大腦，擁有自己的：

- **工作區 (Workspace)**：檔案、AGENTS.md/SOUL.md/USER.md、本地備註、人格規則。
- **狀態目錄 (`agentDir`)**：用於認證設定檔 (auth profiles)、模型註冊表和每代理設定。
- **會話儲存 (Session store)**：位於 `~/.openclaw/agents/<agentId>/sessions` 下的聊天歷史 + 路由狀態。

認證設定檔是**按代理**分配的。每個代理從自己的路徑讀取：

```
~/.openclaw/agents/<agentId>/agent/auth-profiles.json
```

主代理 (Main agent) 的憑證**不會**自動共享。切勿在代理之間重複使用 `agentDir`（這會導致認證/會話衝突）。如果您想共享憑證，請將 `auth-profiles.json` 複製到另一個代理的 `agentDir` 中。

技能是按代理透過每個工作區的 `skills/` 資料夾提供的，通用技能則位於 `~/.openclaw/skills`。請參閱 [技能：每代理 vs 共享](/tools/skills#per-agent-vs-shared-skills)。

Gateway 可以側並側地託管**一個代理**（預設）或**多個代理**。

**工作區備註：** 每個代理的工作區是**預設的 CWD**，而不是硬性沙盒。相對路徑在工作區內解析，但除非啟用了沙盒化，否則絕對路徑可以到達其他主機位置。請參閱 [沙盒化](/gateway/sandboxing)。

## 路徑（快速地圖）

- 設定：`~/.openclaw/openclaw.json`（或 `OPENCLAW_CONFIG_PATH`）
- 狀態目錄：`~/.openclaw`（或 `OPENCLAW_STATE_DIR`）
- 工作區：`~/.openclaw/workspace`（或 `~/.openclaw/workspace-<agentId>`）
- 代理目錄：`~/.openclaw/agents/<agentId>/agent`（或 `agents.list[].agentDir`）
- 會話：`~/.openclaw/agents/<agentId>/sessions`

### 單代理模式（預設）

如果您不進行任何操作，OpenClaw 會運行單個代理：

- `agentId` 預設為 **`main`**。
- 會話鍵格式為 `agent:main:<mainKey>`。
- 工作區預設為 `~/.openclaw/workspace`（或設定 `OPENCLAW_PROFILE` 時的 `~/.openclaw/workspace-<profile>`）。
- 狀態預設為 `~/.openclaw/agents/main/agent`。

## 代理輔助工具

使用代理精靈新增一個新的隔離代理：

```bash
openclaw agents add work
```

然後新增 `bindings`（或讓精靈自動完成）以路由入站訊息。

使用以下命令驗證：

```bash
openclaw agents list --bindings
```

## 多個代理 = 多個人物、多種性格

透過**多個代理**，每個 `agentId` 成為一個**完全隔離的人格**：

- **不同的電話號碼/帳戶**（按頻道 `accountId`）。
- **不同的個性**（按代理的工作區檔案，如 `AGENTS.md` 和 `SOUL.md`）。
- **獨立的認證 + 會話**（除非明確啟用，否則互不干擾）。

這讓**多個人**可以共享一個 Gateway 伺服器，同時保持他們的 AI「大腦」和數據隔離。

## 一個 WhatsApp 號碼，多個使用者 (DM 分流)

您可以將**不同的 WhatsApp DM** 路由到不同的代理，同時保持在**同一個 WhatsApp 帳戶**上。透過 `peer.kind: "dm"` 匹配發送者的 E.164 號碼（如 `+15551234567`）。回覆仍然來自同一個 WhatsApp 號碼（沒有每代理的發送者身份）。

重要細節：直接聊天會合併到代理的**主會話鍵**，因此真正的隔離需要**每人一個代理**。

範例：

```json5
{
  agents: {
    list: [
      { id: "alex", workspace: "~/.openclaw/workspace-alex" },
      { id: "mia", workspace: "~/.openclaw/workspace-mia" }
    ]
  },
  bindings: [
    { agentId: "alex", match: { channel: "whatsapp", peer: { kind: "dm", id: "+15551230001" } } },
    { agentId: "mia",  match: { channel: "whatsapp", peer: { kind: "dm", id: "+15551230002" } } }
  ],
  channels: {
    whatsapp: {
      dmPolicy: "allowlist",
      allowFrom: ["+15551230001", "+15551230002"]
    }
  }
}
```

備註：
- DM 存取控制是**全域按 WhatsApp 帳戶**（配對/允許清單）進行的，而不是按代理。
- 對於共享群組，將群組綁定到一個代理，或使用 [廣播群組 (Broadcast groups)](/broadcast-groups)。

## 路由規則（訊息如何挑選代理）

綁定是**確定性的**，且**最精確的優先**：

1. `peer` 匹配（精確的 DM/群組/頻道 ID）
2. `guildId` (Discord)
3. `teamId` (Slack)
4. 選定頻道的 `accountId` 匹配
5. 頻道級別匹配 (`accountId: "*"`)
6. 回退到預設代理 (`agents.list[].default`，若無則為列表第一項，預設為 `main`)

## 多個帳戶 / 電話號碼

支援**多個帳戶**的頻道（例如 WhatsApp）使用 `accountId` 來識別每次登入。每個 `accountId` 都可以路由到不同的代理，因此一台伺服器可以託管多個電話號碼而不會混淆會話。

## 概念

- `agentId`：一個「大腦」（工作區、每代理認證、每代理會話儲存）。
- `accountId`：一個頻道帳戶實例（例如 WhatsApp 帳戶 `"personal"` vs `"biz"`）。
- `binding`：透過 `(channel, accountId, peer)` 以及可選的伺服器/團隊 ID，將入站訊息路由到某個 `agentId`。
- 直接聊天會合併到 `agent:<agentId>:<mainKey>`（每代理的「主」會話；`session.mainKey`）。

## 範例：兩個 WhatsApp 帳戶 → 兩個代理

`~/.openclaw/openclaw.json` (JSON5):

```js
{
  agents: {
    list: [
      {
        id: "home",
        default: true,
        name: "Home",
        workspace: "~/.openclaw/workspace-home",
        agentDir: "~/.openclaw/agents/home/agent",
      },
      {
        id: "work",
        name: "Work",
        workspace: "~/.openclaw/workspace-work",
        agentDir: "~/.openclaw/agents/work/agent",
      },
    ],
  },
  // 確定性路由：第一個匹配的優先（最精確的排在前面）。
  bindings: [
    { agentId: "home", match: { channel: "whatsapp", accountId: "personal" } },
    { agentId: "work", match: { channel: "whatsapp", accountId: "biz" } },
    // 可選的每對象覆寫（範例：將特定群組發送到 work 代理）。
    {
      agentId: "work",
      match: {
        channel: "whatsapp",
        accountId: "personal",
        peer: { kind: "group", id: "1203630...@g.us" },
      },
    },
  ],
  // 預設關閉：代理對代理訊息必須明確啟用並列入允許清單。
  tools: {
    agentToAgent: {
      enabled: false,
      allow: ["home", "work"],
    },
  },
  channels: {
    whatsapp: {
      accounts: {
        personal: {
          // 可選覆寫。預設：~/.openclaw/credentials/whatsapp/personal
        },
        biz: {
          // 可選覆寫。預設：~/.openclaw/credentials/whatsapp/biz
        },
      },
    },
  },
}
```

## 範例：WhatsApp 日常聊天 + Telegram 深度工作

按頻道分流：將 WhatsApp 路由到一個快速的日常代理，將 Telegram 路由到一個 Opus 代理。

```json5
{
  agents: {
    list: [
      {
        id: "chat",
        name: "Everyday",
        workspace: "~/.openclaw/workspace-chat",
        model: "anthropic/claude-sonnet-4-5"
      },
      {
        id: "opus",
        name: "Deep Work",
        workspace: "~/.openclaw/workspace-opus",
        model: "anthropic/claude-opus-4-5"
      }
    ]
  },
  bindings: [
    { agentId: "chat", match: { channel: "whatsapp" } },
    { agentId: "opus", match: { channel: "telegram" } }
  ]
}
```

備註：
- 如果您在某個頻道有多個帳戶，請在綁定中新增 `accountId`（例如 `{ channel: "whatsapp", accountId: "personal" }`）。
- 欲將單個 DM/群組路由到 Opus 代理，而保持其他訊息在日常聊天代理，請為該對象新增一個 `match.peer` 綁定；對象匹配總是優先於全頻道規則。

## 範例：同頻道，將一個聯絡人路由到 Opus

保持 WhatsApp 在快速代理上，但將一個 DM 路由到 Opus：

```json5
{
  agents: {
    list: [
      { id: "chat", name: "Everyday", workspace: "~/.openclaw/workspace-chat", model: "anthropic/claude-sonnet-4-5" },
      { id: "opus", name: "Deep Work", workspace: "~/.openclaw/workspace-opus", model: "anthropic/claude-opus-4-5" }
    ]
  },
  bindings: [
    { agentId: "opus", match: { channel: "whatsapp", peer: { kind: "dm", id: "+15551234567" } } },
    { agentId: "chat", match: { channel: "whatsapp" } }
  ]
}
```

對象 (Peer) 綁定總是優先，因此請將它們放在全頻道規則之上。

## 綁定到 WhatsApp 群組的家庭代理

將專用的家庭代理綁定到單個 WhatsApp 群組，並設定提及控制和更嚴格的工具原則：

```json5
{
  agents: {
    list: [
      {
        id: "family",
        name: "Family",
        workspace: "~/.openclaw/workspace-family",
        identity: { name: "Family Bot" },
        groupChat: {
          mentionPatterns: ["@family", "@familybot", "@Family Bot"]
        },
        sandbox: {
          mode: "all",
          scope: "agent"
        },
        tools: {
          allow: ["exec", "read", "sessions_list", "sessions_history", "sessions_send", "sessions_spawn", "session_status"],
          deny: ["write", "edit", "apply_patch", "browser", "canvas", "nodes", "cron"]
        }
      }
    ]
  },
  bindings: [
    {
      agentId: "family",
      match: {
        channel: "whatsapp",
        peer: { kind: "group", id: "120363999999999999@g.us" }
      }
    }
  ]
}
```

備註：
- 工具允許/拒絕列表適用於**工具 (tools)**，而非技能。如果某項技能需要運行二進位檔案，請確保 `exec` 已被允許，且該二進位檔案存在於沙盒中。
- 欲進行更嚴格的控制，請設定 `agents.list[].groupChat.mentionPatterns` 並為該頻道啟用群組允許清單。

## 每代理沙盒與工具設定

從 v2026.1.6 開始，每個代理可以擁有自己的沙盒和工具限制：

```js
{
  agents: {
    list: [
      {
        id: "personal",
        workspace: "~/.openclaw/workspace-personal",
        sandbox: {
          mode: "off",  // 個人代理不進行沙盒化
        },
        // 無工具限制 - 所有工具均可用
      },
      {
        id: "family",
        workspace: "~/.openclaw/workspace-family",
        sandbox: {
          mode: "all",     // 始終進行沙盒化
          scope: "agent",  // 每個代理一個容器
          docker: {
            // 容器建立後的選用一次性設定
            setupCommand: "apt-get update && apt-get install -y git curl",
          },
        },
        tools: {
          allow: ["read"],                    // 僅限 read 工具
          deny: ["exec", "write", "edit", "apply_patch"],    // 拒絕其他工具
        },
      },
    ],
  },
}
```

備註：`setupCommand` 位於 `sandbox.docker` 下，於容器建立時運行一次。當解析範圍為 `"shared"` 時，會忽略每代理的 `sandbox.docker.*` 覆寫。

**優點：**
- **安全性隔離**：限制不受信任代理的工具權限
- **資源控制**：沙盒化特定代理，同時讓其他代理由主機運行
- **靈活原則**：每個代理有不同的權限

備註：`tools.elevated` 是**全域性**且基於發送者的；它無法按代理進行設定。如果您需要按代理劃分邊界，請使用 `agents.list[].tools` 來拒絕 `exec`。對於群組目標，請使用 `agents.list[].groupChat.mentionPatterns`，以便 @提及能乾淨地映射到預期的代理。

請參閱 [多代理沙盒與工具](/multi-agent-sandbox-tools) 了解詳細範例。
