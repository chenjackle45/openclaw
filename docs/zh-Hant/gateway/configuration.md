---
title: "configuration(Configuration 🔧)"
summary: "~/.openclaw/openclaw.json 的所有設定選項與範例"
read_when:
  - 新增或修改 Config 欄位時
---

# 組態設定 (Configuration 🔧)

OpenClaw 會讀取位於 `~/.openclaw/openclaw.json` 的選擇性 **JSON5** 設定檔（允許註解與結尾逗號）。

若檔案遺失，OpenClaw 會使用安全的預設值（內建 Pi Agent + Per-sender sessions + Workspace `~/.openclaw/workspace`）。您通常只需要 Config 來：
- 限制誰可以觸發機器人 (`channels.whatsapp.allowFrom`, `channels.telegram.allowFrom` 等)
- 控制群組允許清單 + Mention 行為 (`channels.whatsapp.groups`, `channels.telegram.groups`, `channels.discord.guilds`, `agents.list[].groupChat`)
- 自訂訊息前綴 (`messages`)
- 設定 Agent 的 Workspace (`agents.defaults.workspace` 或 `agents.list[].workspace`)
- 調整內建 Agent 預設值 (`agents.defaults`) 與 Session 行為 (`session`)
- 設定 Per-agent 身分 (`agents.list[].identity`)

> **剛接觸組態設定？** 查看 [Configuration Examples](/gateway/configuration-examples) 指南以獲取包含詳細解釋的完整範例！

## 嚴格設定驗證 (Strict config validation)

OpenClaw 僅接受完全符合 Schema 的設定。
未知的 Keys、格式錯誤的 Types 或無效的值會導致 Gateway **拒絕啟動**以確保安全。

當驗證失敗時：
- Gateway 不會啟動。
- 僅允許診斷指令（例如：`openclaw doctor`, `openclaw logs`, `openclaw health`, `openclaw status`, `openclaw service`, `openclaw help`）。
- 運行 `openclaw doctor` 查看確切問題。
- 運行 `openclaw doctor --fix` (或 `--yes`) 以套用遷移/修復。

Doctor 除非您明確選擇 `--fix`/`--yes`，否則絕不會寫入變更。

## Schema + UI 提示 (Schema + UI hints)

Gateway 透過 `config.schema` 暴露 Config 的 JSON Schema 表示法以供 UI 編輯器使用。
Control UI 根據此 Schema 渲染表單，並提供 **Raw JSON** 編輯器作為逃生艙。

Channel Plugins 與 Extensions 可以為其 Config 註冊 Schema + UI hints，因此 Channel 設定可以跨 Apps 保持 Schema 驅動，無需寫死表單。

Hints（標籤、分組、敏感欄位）與 Schema 一起發布，因此客戶端可以渲染更好的表單而無需寫死 Config 知識。

## 套用 + 重啟 (Apply + restart via RPC)

使用 `config.apply` 驗證 + 寫入完整 Config 並在一步驟內重啟 Gateway。
它會寫入一個 Restart Sentinel 並在 Gateway 回來後 Ping 最後活躍的 Session。

警告：`config.apply` 會替換 **整個 Config**。若您只想變更少數 Keys，請使用 `config.patch` 或 `openclaw config set`。請保留 `~/.openclaw/openclaw.json` 的備份。

參數：
- `raw` (string) — 整個 Config 的 JSON5 Payload
- `baseHash` (optional) — 來自 `config.get` 的 Config Hash（當 Config 已存在時為必填）
- `sessionKey` (optional) — 用於 Wake-up Ping 的最後活躍 Session Key
- `note` (optional) — 包含在 Restart Sentinel 中的註記
- `restartDelayMs` (optional) — 重啟前的延遲（預設 2000）

範例 (透過 `gateway call`)：

```bash
openclaw gateway call config.get --params '{}' # capture payload.hash
openclaw gateway call config.apply --params '{
  "raw": "{\\n  agents: { defaults: { workspace: \\"~/.openclaw/workspace\\" } }\\n}\\n",
  "baseHash": "<hash-from-config.get>",
  "sessionKey": "agent:main:whatsapp:dm:+15555550123",
  "restartDelayMs": 1000
}'
```

## 部分更新 (Partial updates via RPC)

使用 `config.patch` 將部分更新合併到現有 Config 中，而不覆蓋不相關的 Keys。它應用 JSON Merge Patch 語意：
- 物件遞迴合併
- `null` 刪除 Key
- 陣列替換
如同 `config.apply`，它會驗證、寫入 Config、儲存 Restart Sentinel 並排程 Gateway 重啟（當提供 `sessionKey` 時可選喚醒）。

參數：
- `raw` (string) — 僅包含要變更 Keys 的 JSON5 Payload
- `baseHash` (required) — 來自 `config.get` 的 Config Hash
- `sessionKey` (optional) — 用於 Wake-up Ping 的最後活躍 Session Key
- `note` (optional) — 包含在 Restart Sentinel 中的註記
- `restartDelayMs` (optional) — 重啟前的延遲（預設 2000）

範例：

```bash
openclaw gateway call config.get --params '{}' # capture payload.hash
openclaw gateway call config.patch --params '{
  "raw": "{\\n  channels: { telegram: { groups: { \\"*\\": { requireMention: false } } } }\\n}\\n",
  "baseHash": "<hash-from-config.get>",
  "sessionKey": "agent:main:whatsapp:dm:+15555550123",
  "restartDelayMs": 1000
}'
```

## 最小 Config (推薦起點)

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } },
  channels: { whatsapp: { allowFrom: ["+15555550123"] } }
}
```

使用以下指令建置一次預設 Image：
```bash
scripts/sandbox-setup.sh
```

## Self-chat 模式 (建議用於群組控制)

防止機器人在群組中回應 WhatsApp @-mentions（僅回應特定文字觸發）：

```json5
{
  agents: {
    defaults: { workspace: "~/.openclaw/workspace" },
    list: [
      {
        id: "main",
        groupChat: { mentionPatterns: ["@openclaw", "reisponde"] }
      }
    ]
  },
  channels: {
    whatsapp: {
      // Allowlist 僅適用於 DMs；包含您自己的號碼以啟用 Self-chat 模式。
      allowFrom: ["+15555550123"],
      groups: { "*": { requireMention: true } }
    }
  }
}
```

## Config Includes (`$include`)

使用 `$include` 指令將 Config 拆分為多個檔案。這適用於：
- 組織大型 Configs（例如：Per-client Agent Definitions）
- 跨環境共用通用設定
- 將敏感 Configs 分開存放

### 基本用法

```json5
// ~/.openclaw/openclaw.json
{
  gateway: { port: 18789 },
  
  // 引入單一檔案（替換 Key 的值）
  agents: { "$include": "./agents.json5" },
  
  // 引入多個檔案（依序 Deep-merged）
  broadcast: { 
    "$include": [
      "./clients/mueller.json5",
      "./clients/schmidt.json5"
    ]
  }
}
```

```json5
// ~/.openclaw/agents.json5
{
  defaults: { sandbox: { mode: "all", scope: "session" } },
  list: [
    { id: "main", workspace: "~/.openclaw/workspace" }
  ]
}
```

### 合併行為 (Merge behavior)

- **單一檔案**：替換包含 `$include` 的物件
- **檔案陣列**：依序 Deep-merge 檔案（後面的檔案覆蓋前面的）
- **與 Sibling Keys**：Sibling Keys 在 Includes 之後合併（覆蓋 included 的值）
- **Sibling Keys + Arrays/Primitives**：不支援（included 內容必須是物件）

```json5
// Sibling keys 覆蓋 included values
{
  "$include": "./base.json5",   // { a: 1, b: 2 }
  b: 99                          // 結果: { a: 1, b: 99 }
}
```

### 巢狀 Includes (Nested includes)

被引入的檔案本身可以包含 `$include` 指令（最多 10 層深）：

```json5
// clients/mueller.json5
{
  agents: { "$include": "./mueller/agents.json5" },
  broadcast: { "$include": "./mueller/broadcast.json5" }
}
```

###路徑解析 (Path resolution)

- **相對路徑**：相對於引入檔案的解析
- **絕對路徑**：原樣使用
- **父目錄**：`../` 引用如預期運作

```json5
{ "$include": "./sub/config.json5" }      // relative
{ "$include": "/etc/openclaw/base.json5" } // absolute
{ "$include": "../shared/common.json5" }   // parent dir
```

### 錯誤處理 (Error handling)

- **檔案遺失**：顯示包含解析路徑的清楚錯誤
- **解析錯誤**：顯示哪個 Included File 失敗
- **循環 Includes**：偵測並報告 Include Chain

### 範例：多客戶端 Legal Setup

```json5
// ~/.openclaw/openclaw.json
{
  gateway: { port: 18789, auth: { token: "secret" } },
  
  // 通用 Agent Defaults
  agents: {
    defaults: {
      sandbox: { mode: "all", scope: "session" }
    },
    // 合併來自所有 Clients 的 Agent Lists
    list: { "$include": [
      "./clients/mueller/agents.json5",
      "./clients/schmidt/agents.json5"
    ]}
  },
  
  // 合併 Broadcast Configs
  broadcast: { "$include": [
    "./clients/mueller/broadcast.json5",
    "./clients/schmidt/broadcast.json5"
  ]},
  
  channels: { whatsapp: { groupPolicy: "allowlist" } }
}
```

```json5
// ~/.openclaw/clients/mueller/agents.json5
[
  { id: "mueller-transcribe", workspace: "~/clients/mueller/transcribe" },
  { id: "mueller-docs", workspace: "~/clients/mueller/docs" }
]
```

```json5
// ~/.openclaw/clients/mueller/broadcast.json5
{
  "120363403215116621@g.us": ["mueller-transcribe", "mueller-docs"]
}
```

## 通用選項 (Common options)

### Env vars + `.env`

OpenClaw 從父行程（Shell, launchd/systemd, CI 等）讀取 Env Vars。

此外，它載入：
- 當前工作目錄中的 `.env`（如果存在）
- 全域 Fallback `.env` 位於 `~/.openclaw/.env` (即 `$OPENCLAW_STATE_DIR/.env`)

任一 `.env` 檔案都不會覆蓋現有的 Env Vars。

您也可以在 Config 中提供行內 Env Vars。這些僅在 Process Env 缺少該 Key 時應用（相同的 Non-overriding 規則）：

```json5
{
  env: {
    OPENROUTER_API_KEY: "sk-or-...",
    vars: {
      GROQ_API_KEY: "gsk-..."
    }
  }
}
```

參閱 [/environment](/environment) 以獲取完整優先順序與來源。

### `env.shellEnv` (optional)

可選的便利功能：若啟用且預期的 Keys 尚未設定，OpenClaw 會運行您的 Login Shell 並僅匯入缺少的預期 Keys（絕不覆蓋）。
這有效地 Source 您的 Shell Profile。

```json5
{
  env: {
    shellEnv: {
      enabled: true,
      timeoutMs: 15000
    }
  }
}
```

Env var 等效項：
- `OPENCLAW_LOAD_SHELL_ENV=1`
- `OPENCLAW_SHELL_ENV_TIMEOUT_MS=15000`

### Config 中的 Env var 替換

您可以使用 `${VAR_NAME}` 語法在任何 Config 字串值中直接引用環境變數。變數在 Config 載入時替換，驗證之前。

```json5
{
  models: {
    providers: {
      "vercel-gateway": {
        apiKey: "${VERCEL_GATEWAY_API_KEY}"
      }
    }
  },
  gateway: {
    auth: {
      token: "${OPENCLAW_GATEWAY_TOKEN}"
    }
  }
}
```

**規則：**
- 僅匹配大寫 Env Var 名稱：`[A-Z_][A-Z0-9_]*`
- 遺失或空的 Env Vars 在 Config 載入時拋出錯誤
- 使用 `$${VAR}` 轉義以輸出文字 `${VAR}`
- 適用於 `$include`（Included files 也獲得替換）

**行內替換:**

```json5
{
  models: {
    providers: {
      custom: {
        baseUrl: "${CUSTOM_API_BASE}/v1"  // → "https://api.example.com/v1"
      }
    }
  }
}
```

### Auth 儲存 (OAuth + API keys)

OpenClaw 儲存 **Per-agent** Auth Profiles (OAuth + API keys) 於：
- `<agentDir>/auth-profiles.json` (預設: `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`)

亦參閱: [/concepts/oauth](/concepts/oauth)

Legacy OAuth 匯入:
- `~/.openclaw/credentials/oauth.json` (或 `$OPENCLAW_STATE_DIR/credentials/oauth.json`)

內建 Pi Agent 維護一個 Runtime Cache 於：
- `<agentDir>/auth.json` (自動管理；請勿手動編輯)

Legacy Agent Dir (Pre multi-agent):
- `~/.openclaw/agent/*` (由 `openclaw doctor` 遷移至 `~/.openclaw/agents/<defaultAgentId>/agent/*`)

Overrides:
- OAuth dir (僅 Legacy import): `OPENCLAW_OAUTH_DIR`
- Agent dir (Default Agent Root Override): `OPENCLAW_AGENT_DIR` (偏好), `PI_CODING_AGENT_DIR` (Legacy)

首次使用時，OpenClaw 將 `oauth.json` 項目匯入 `auth-profiles.json`。

### `auth`

Auth Profiles 的選擇性 Metadata。這 **不** 儲存 Secrets；它將 Profile IDs 對應到 Provider + Mode（與可選的 Email）並定義 Failover 使用的 Provider 輪替順序。

```json5
{
  auth: {
    profiles: {
      "anthropic:me@example.com": { provider: "anthropic", mode: "oauth", email: "me@example.com" },
      "anthropic:work": { provider: "anthropic", mode: "api_key" }
    },
    order: {
      anthropic: ["anthropic:me@example.com", "anthropic:work"]
    }
  }
}
```

### `agents.list[].identity`

用於 Defaults 與 UX 的選擇性 Per-agent Identity。這由 macOS Onboarding Assistant 寫入。

若設定，OpenClaw 推導 Defaults（僅當您未明確設定它們時）：
- 從 **Active Agent** 的 `identity.emoji` 推導 `messages.ackReaction`（ fallback 至 👀）
- 從 Agent 的 `identity.name`/`identity.emoji` 推導 `agents.list[].groupChat.mentionPatterns`（因此 “@Samantha” 在 Telegram/Slack/Discord/Google Chat/iMessage/WhatsApp 群組中適用）
- `identity.avatar` 接受 Workspace-relative Image Path 或 Remote URL/Data URL。本地檔案必須位於 Agent Workspace 內。

`identity.avatar` 接受：
- Workspace-relative path (必須停留在 Agent Workspace 內)
- `http(s)` URL
- `data:` URI

```json5
{
  agents: {
    list: [
      {
        id: "main",
        identity: {
          name: "Samantha",
          theme: "helpful sloth",
          emoji: "🦥",
          avatar: "avatars/samantha.png"
        }
      }
    ]
  }
}
```

### `wizard`

由 CLI Wizards (`onboard`, `configure`, `doctor`) 寫入的 Metadata。

```json5
{
  wizard: {
    lastRunAt: "2026-01-01T00:00:00.000Z",
    lastRunVersion: "2026.1.4",
    lastRunCommit: "abc1234",
    lastRunCommand: "configure",
    lastRunMode: "local"
  }
}
```

### `logging`

- 預設 Log File: `/tmp/openclaw/openclaw-YYYY-MM-DD.log`
- 若您想要穩定的路徑，設定 `logging.file` 為 `/tmp/openclaw/openclaw.log`。
- Console 輸出可單獨調整：
  - `logging.consoleLevel` (預設為 `info`，當 `--verbose` 時升至 `debug`)
  - `logging.consoleStyle` (`pretty` | `compact` | `json`)
- Tool Summaries 可以編輯以避免洩露 Secrets：
  - `logging.redactSensitive` (`off` | `tools`, 預設: `tools`)
  - `logging.redactPatterns` (Regex 字串陣列；覆蓋預設值)

```json5
{
  logging: {
    level: "info",
    file: "/tmp/openclaw/openclaw.log",
    consoleLevel: "info",
    consoleStyle: "pretty",
    redactSensitive: "tools",
    redactPatterns: [
      // 範例：用您自己的規則覆蓋預設值。
      "\\bTOKEN\\b\\s*[=:]\\s*([\"']?)([^\\s\"']+)\\1",
      "/\\bsk-[A-Za-z0-9_-]{8,}\\b/gi"
    ]
  }
}
```

### `channels.whatsapp.dmPolicy`

控制 WhatsApp Direct Chats (DMs) 如何處理：
- `"pairing"` (預設): 未知發送者收到 Pairing Code；擁有者必須核准
- `"allowlist"`: 僅允許 `channels.whatsapp.allowFrom` (或 Paired Allow Store) 中的發送者
- `"open"`: 允許所有 Inbound DMs (**需要** `channels.whatsapp.allowFrom` 包含 `"*"`)
- `"disabled"`: 忽略所有 Inbound DMs

Pairing Codes 在 1 小時後過期；機器人僅在建立新請求時發送 Pairing Code。Pending DM Pairing Requests 預設上限為 **每 Channel 3 個**。

Pairing 核准：
- `openclaw pairing list whatsapp`
- `openclaw pairing approve whatsapp <code>`

### `channels.whatsapp.allowFrom`

允許觸發 WhatsApp Auto-replies 的 E.164 電話號碼清單 (**僅限 DMs**)。
若為空且 `channels.whatsapp.dmPolicy="pairing"`，未知發送者將收到 Pairing Code。
對於群組，使用 `channels.whatsapp.groupPolicy` + `channels.whatsapp.groupAllowFrom`。

```json5
{
  channels: {
    whatsapp: {
      dmPolicy: "pairing", // pairing | allowlist | open | disabled
      allowFrom: ["+15555550123", "+447700900123"],
      textChunkLimit: 4000, // optional outbound chunk size (chars)
      chunkMode: "length", // optional chunking mode (length | newline)
      mediaMaxMb: 50 // optional inbound media cap (MB)
    }
  }
}
```

### `channels.whatsapp.sendReadReceipts`

控制 Inbound WhatsApp 訊息是否標記為已讀（藍勾勾）。預設值：`true`。

Self-chat 模式總是跳過 Read Receipts，即使啟用。

Per-account override: `channels.whatsapp.accounts.<id>.sendReadReceipts`。

```json5
{
  channels: {
    whatsapp: { sendReadReceipts: false }
  }
}
```

### `channels.whatsapp.accounts` (多帳號)

在一個 Gateway 中運行多個 WhatsApp 帳號：

```json5
{
  channels: {
    whatsapp: {
      accounts: {
        default: {}, // optional; 保持預設 id 穩定
        personal: {},
        biz: {
          // Optional override. Default: ~/.openclaw/credentials/whatsapp/biz
          // authDir: "~/.openclaw/credentials/whatsapp/biz",
        }
      }
    }
  }
}
```

註記：
- Outbound Commands 預設為 Account `default`（如果存在）；否則是第一個設定的 Account Id（排序後）。
- Legacy Single-account Baileys Auth Dir 由 `openclaw doctor` 遷移至 `whatsapp/default`。

### `channels.telegram.accounts` / `channels.discord.accounts` / `channels.googlechat.accounts` / `channels.slack.accounts` / `channels.mattermost.accounts` / `channels.signal.accounts` / `channels.imessage.accounts`

每個 Channel 運行多個帳號（每個帳號有自己的 `accountId` 和可選的 `name`）：

```json5
{
  channels: {
    telegram: {
      accounts: {
        default: {
          name: "Primary bot",
          botToken: "123456:ABC..."
        },
        alerts: {
          name: "Alerts bot",
          botToken: "987654:XYZ..."
        }
      }
    }
  }
}
```

註記：
- 當省略 `accountId` 時使用 `default` (CLI + Routing)。
- Env Tokens 僅適用於 **Default** Account。
- Base Channel Settings (Group Policy, Mention Gating 等) 適用於所有帳號，除非 Per Account 覆蓋。
- 使用 `bindings[].match.accountId` 將每個帳號路由到不同的 agents.defaults。

### Group chat mention gating (`agents.list[].groupChat` + `messages.groupChat`)

群組訊息預設為 **Require Mention**（Metadata Mention 或 Regex Patterns）。適用於 WhatsApp, Telegram, Discord, Google Chat, 與 iMessage Group Chats。

**Mention 類型：**
- **Metadata Mentions**：原生平台 @-mentions（例如：WhatsApp Tap-to-mention）。在 WhatsApp Self-chat 模式中忽略（參見 `channels.whatsapp.allowFrom`）。
- **Text Patterns**：定義於 `agents.list[].groupChat.mentionPatterns` 的 Regex Patterns。無論 Self-chat 模式為何皆會檢查。
- Mention Gating 僅在 Mention Detection 可能時強制執行（Native Mentions 或至少一個 `mentionPattern`）。

```json5
{
  messages: {
    groupChat: { historyLimit: 50 }
  },
  agents: {
    list: [
      { id: "main", groupChat: { mentionPatterns: ["@openclaw", "openclaw"] } }
    ]
  }
}
```

`messages.groupChat.historyLimit` 設定 Group History Context 的全域預設值。Channels 可以透過 `channels.<channel>.historyLimit` (或 `channels.<channel>.accounts.*.historyLimit` 用於多帳號) 覆蓋。設定 `0` 以停用 History wrapping。

#### DM history limits

DM Conversations 使用由 Agent 管理的 Session-based History。您可以限制每個 DM Session 保留的使用者 Turns 數量：

```json5
{
  channels: {
    telegram: {
      dmHistoryLimit: 30,  // limit DM sessions to 30 user turns
      dms: {
        "123456789": { historyLimit: 50 }  // per-user override (user ID)
      }
    }
  }
}
```

解析順序：
1. Per-DM override: `channels.<provider>.dms[userId].historyLimit`
2. Provider default: `channels.<provider>.dmHistoryLimit`
3. No limit (保留所有記錄)

支援的 Providers: `telegram`, `whatsapp`, `discord`, `slack`, `signal`, `imessage`, `msteams`。

Per-agent override (當設定時優先，即使是 `[]`):
```json5
{
  agents: {
    list: [
      { id: "work", groupChat: { mentionPatterns: ["@workbot", "\\+15555550123"] } },
      { id: "personal", groupChat: { mentionPatterns: ["@homebot", "\\+15555550999"] } }
    ]
  }
}
```

Mention Gating Defaults 存在於每個 Channel (`channels.whatsapp.groups`, `channels.telegram.groups`, `channels.imessage.groups`, `channels.discord.guilds`)。當設定 `*.groups` 時，它也作為 Group Allowlist；包含 `"*"` 以允許所有群組。

若要 **僅** 回應特定文字觸發（忽略原生 @-mentions）：
```json5
{
  channels: {
    whatsapp: {
      // 包含您自己的號碼以啟用 Self-chat 模式 (忽略原生 @-mentions)。
      allowFrom: ["+15555550123"],
      groups: { "*": { requireMention: true } }
    }
  },
  agents: {
    list: [
      {
        id: "main",
        groupChat: {
          // 僅這些文字模式會觸發回應
          mentionPatterns: ["reisponde", "@openclaw"]
        }
      }
    ]
  }
}
```

### Group policy (per channel)

使用 `channels.*.groupPolicy` 控制是否接受 Group/Room 訊息：

```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"]
    },
    telegram: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["tg:123456789", "@alice"]
    },
    signal: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"]
    },
    imessage: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["chat_id:123"]
    },
    msteams: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["user@org.com"]
    },
    discord: {
      groupPolicy: "allowlist",
      guilds: {
        "GUILD_ID": {
          channels: { help: { allow: true } }
        }
      }
    },
    slack: {
      groupPolicy: "allowlist",
      channels: { "#general": { allow: true } }
    }
  }
}
```

註記：
- `"open"`: 群組繞過 Allowlist；Mention-gating 仍然適用。
- `"disabled"`: 封鎖所有 Group/Room 訊息。
- `"allowlist"`: 僅允許符合設定 Allowlist 的 Groups/Rooms。
- `channels.defaults.groupPolicy` 設定當 Provider 的 `groupPolicy` 未設定時的預設值。
- WhatsApp/Telegram/Signal/iMessage/Microsoft Teams 使用 `groupAllowFrom` (Fallback: 顯式 `allowFrom`)。
- Discord/Slack 使用 Channel Allowlists (`channels.discord.guilds.*.channels`, `channels.slack.channels`)。
- Group DMs (Discord/Slack) 仍由 `dm.groupEnabled` + `dm.groupChannels` 控制。
- 預設為 `groupPolicy: "allowlist"`（除非由 `channels.defaults.groupPolicy` 覆蓋）；若未設定 Allowlist，群組訊息會被封鎖。

### Multi-agent routing (`agents.list` + `bindings`)

在一個 Gateway 內運行多個隔離的 Agents（獨立 Workspace, `agentDir`, Sessions）。
Inbound 訊息透過 Bindings 路由至 Agent。

- `agents.list[]`: Per-agent overrides.
  - `id`: 穩定的 Agent Id (Required).
  - `default`: Optional; 當設定多個時，第一個獲勝並記錄警告。
    若無設定，清單中的 **第一個 Entry** 為 Default Agent。
  - `name`: Agent 的顯示名稱。
  - `workspace`: 預設 `~/.openclaw/workspace-<agentId>` (對於 `main`，Fallback 至 `agents.defaults.workspace`).
  - `agentDir`: 預設 `~/.openclaw/agents/<agentId>/agent`.
  - `model`: Per-agent Default Model，覆蓋該 Agent 的 `agents.defaults.model`。
    - String form: `"provider/model"`, 僅覆蓋 `agents.defaults.model.primary`
    - Object form: `{ primary, fallbacks }` (fallbacks 覆蓋 `agents.defaults.model.fallbacks`; `[]` 停用該 Agent 的 Global Fallbacks)
  - `identity`: Per-agent Name/Theme/Emoji (用於 Mention Patterns + Ack Reactions).
  - `groupChat`: Per-agent Mention-gating (`mentionPatterns`).
  - `sandbox`: Per-agent Sandbox Config (覆蓋 `agents.defaults.sandbox`)。
    - `mode`: `"off"` | `"non-main"` | `"all"`
    - `workspaceAccess`: `"none"` | `"ro"` | `"rw"`
    - `scope`: `"session"` | `"agent"` | `"shared"`
    - `workspaceRoot`: 自訂 Sandbox Workspace Root
    - `docker`: Per-agent Docker Overrides (例如 `image`, `network`, `env`, `setupCommand`, limits; 當 `scope: "shared"` 時忽略)
    - `browser`: Per-agent Sandboxed Browser Overrides (當 `scope: "shared"` 時忽略)
    - `prune`: Per-agent Sandbox Pruning Overrides (當 `scope: "shared"` 時忽略)
  - `subagents`: Per-agent Sub-agent Defaults.
    - `allowAgents`: 來自此 Agent 的 `sessions_spawn` 允許的 Agent Ids 清單 (`["*"]` = 允許任何; 預設: 僅同一個 Agent)
  - `tools`: Per-agent Tool Restrictions (在 Sandbox Tool Policy 之前應用)。
    - `profile`: Base Tool Profile (在 Allow/Deny 之前應用)
    - `allow`: 允許的 Tool Names 陣列
    - `deny`: 拒絕的 Tool Names 陣列 (Deny Wins)
- `agents.defaults`: 共用 Agent Defaults (Model, Workspace, Sandbox 等)。
- `bindings[]`: 將 Inbound 訊息路由至 `agentId`。
  - `match.channel` (Required)
  - `match.accountId` (Optional; `*` = 任何 Account; Omitted = Default Account)
  - `match.peer` (Optional; `{ kind: dm|group|channel, id }`)
  - `match.guildId` / `match.teamId` (Optional; Channel-specific)

確定性匹配順序：
1) `match.peer`
2) `match.guildId`
3) `match.teamId`
4) `match.accountId` (Exact, No Peer/Guild/Team)
5) `match.accountId: "*"` (Channel-wide, No Peer/Guild/Team)
6) Default Agent (`agents.list[].default`, 否則 First List Entry, 否則 `"main"`)

在每個 Match Tier 中，`bindings` 中的第一個匹配項目獲勝。

#### Per-agent access profiles (multi-agent)

每個 Agent 可以攜帶自己的 Sandbox + Tool Policy。利用此在一個 Gateway 中混合存取層級：
- **Full access** (Personal Agent)
- **Read-only** Tools + Workspace
- **No filesystem access** (Messaging/Session Tools Only)

參閱 [Multi-Agent Sandbox & Tools](/multi-agent-sandbox-tools) 以獲取優先順序與其他範例。

Full access (No Sandbox):
```json5
{
  agents: {
    list: [
      {
        id: "personal",
        workspace: "~/.openclaw/workspace-personal",
        sandbox: { mode: "off" }
      }
    ]
  }
}
```

Read-only tools + read-only workspace:
```json5
{
  agents: {
    list: [
      {
        id: "family",
        workspace: "~/.openclaw/workspace-family",
        sandbox: {
          mode: "all",
          scope: "agent",
          workspaceAccess: "ro"
        },
        tools: {
          allow: ["read"],
          deny: ["write", "edit", "apply_patch", "exec", "process", "browser"]
        }
      }
    ]
  }
}
```

No filesystem access (messaging/session tools enabled):
```json5
{
  agents: {
    list: [
      {
        id: "public",
        workspace: "~/.openclaw/workspace-public",
        sandbox: {
          mode: "all",
          scope: "agent",
          workspaceAccess: "none"
        },
        tools: {
          allow: ["sessions_list", "sessions_history", "sessions_send", "sessions_spawn", "session_status", "whatsapp", "telegram", "slack", "discord", "gateway"],
          deny: ["read", "write", "edit", "apply_patch", "exec", "process", "browser", "canvas", "nodes", "cron", "gateway", "image"]
        }
      }
    ]
  }
}
```

範例：兩個 WhatsApp 帳號 → 兩個 Agents：

```json5
{
  agents: {
    list: [
      { id: "home", default: true, workspace: "~/.openclaw/workspace-home" },
      { id: "work", workspace: "~/.openclaw/workspace-work" }
    ]
  },
  bindings: [
    { agentId: "home", match: { channel: "whatsapp", accountId: "personal" } },
    { agentId: "work", match: { channel: "whatsapp", accountId: "biz" } }
  ],
  channels: {
    whatsapp: {
      accounts: {
        personal: {},
        biz: {},
      }
    }
  }
}
```

### `tools.agentToAgent` (optional)

Agent-to-agent Messaging 是 Opt-in 的：

```json5
{
  tools: {
    agentToAgent: {
      enabled: false,
      allow: ["home", "work"]
    }
  }
}
```

### `messages.queue`

控制當 Agent Run 已經活躍時，Inbound 訊息的行為。

```json5
{
  messages: {
    queue: {
      mode: "collect", // steer | followup | collect | steer-backlog (steer+backlog ok) | interrupt (queue=steer legacy)
      debounceMs: 1000,
      cap: 20,
      drop: "summarize", // old | new | summarize
      byChannel: {
        whatsapp: "collect",
        telegram: "collect",
        discord: "collect",
        imessage: "collect",
        webchat: "collect"
      }
    }
  }
}
```

### `messages.inbound`

Debounce 來自 **同一發送者** 的快速 Inbound 訊息，使多個連續訊息成為單一 Agent Turn。
Debouncing 是每個 Channel + Conversation 範圍的，並使用最近的訊息進行 Reply Threading/IDs。

```json5
{
  messages: {
    inbound: {
      debounceMs: 2000, // 0 disables
      byChannel: {
        whatsapp: 5000,
        slack: 1500,
        discord: 1500
      }
    }
  }
}
```

註記：
- Debounce 批次處理 **Text-only** 訊息；Media/Attachments 立即 Flush。
- Control Commands (例如 `/queue`, `/new`) 繞過 Debouncing 以保持獨立。

### `commands` (chat command handling)

控制 Chat Commands 在 Connectors 之間的啟用方式。

```json5
{
  commands: {
    native: "auto",         // 當支援時註冊 Native Commands (Auto)
    text: true,             // 解析 Chat Messages 中的 Slash Commands
    bash: false,            // 允許 ! (別名: /bash) (Host-only; 需要 tools.elevated allowlists)
    bashForegroundMs: 2000, // Bash Foreground Window (0 立即背景化)
    config: false,          // 允許 /config (寫入 Disk)
    debug: false,           // 允許 /debug (Runtime-only Overrides)
    restart: false,         // 允許 /restart + Gateway Restart Tool
    useAccessGroups: true   // 強制 Access-group Allowlists/Policies 用於 Commands
  }
}
```

註記：
- Text Commands 必須作為 **Standalone** 訊息發送並使用開頭 `/`（無純文字別名）。
- `commands.text: false` 停用解析 Chat Messages 中的 Commands。
- `commands.native: "auto"` (Default) 為 Discord/Telegram 開啟 Native Commands 並保持 Slack 關閉；不支援的 Channels 保持 Text-only。
- 設定 `commands.native: true|false` 以強制全部，或透過 `channels.discord.commands.native`, `channels.telegram.commands.native`, `channels.slack.commands.native` (bool or `"auto"`) 每個 Channel 覆蓋。`false` 會在啟動時清除 Discord/Telegram 上先前註冊的 Commands；Slack Commands 在 Slack App 中管理。
- `channels.telegram.customCommands` 新增額外 Telegram Bot Menu 項目。名稱會標準化；與 Native Commands 的衝突會被忽略。
- `commands.bash: true` 啟用 `! <cmd>` 以運行 Host Shell Commands (`/bash <cmd>` 也作為別名運作)。需要 `tools.elevated.enabled` 並在 `tools.elevated.allowFrom.<channel>` 中將發送者加入 Allowlist。
- `commands.bashForegroundMs` 控制 Bash 在背景化之前等待多久。當 Bash Job 運行時，新的 `! <cmd>` 請求會被拒絕（一次一個）。
- `commands.config: true` 啟用 `/config` (讀/寫 `openclaw.json`)。
- `channels.<provider>.configWrites` 控制該 Channel 發起的 Config Mutations（預設: True）。這適用於 `/config set|unset` 加上 Provider-specific Auto-migrations (Telegram Supergroup ID changes, Slack Channel ID changes)。
- `commands.debug: true` 啟用 `/debug` (Runtime-only Overrides)。
- `commands.restart: true` 啟用 `/restart` 和 Gateway Tool Restart Action。
- `commands.useAccessGroups: false` 允許 Commands 繞過 Access-group Allowlists/Policies。
- Slash Commands 和 Directives 僅對 **Authorized Senders** 生效。授權衍生自 Channel Allowlists/Pairing 加上 `commands.useAccessGroups`。

### `web` (WhatsApp web channel runtime)

WhatsApp 透過 Gateway 的 Web Channel (Baileys Web) 運行。當存在 Linked Session 時它會自動啟動。
設定 `web.enabled: false` 以預設保持關閉。

```json5
{
  web: {
    enabled: true,
    heartbeatSeconds: 60,
    reconnect: {
      initialMs: 2000,
      maxMs: 120000,
      factor: 1.4,
      jitter: 0.2,
      maxAttempts: 0
    }
  }
}
```

### `channels.telegram` (bot transport)

OpenClaw 僅在 `channels.telegram` Config Section 存在時啟動 Telegram。Bot Token 從 `channels.telegram.botToken` (或 `channels.telegram.tokenFile`) 解析，並以 `TELEGRAM_BOT_TOKEN` 作為預設帳號的 Fallback。
設定 `channels.telegram.enabled: false` 以停用自動啟動。
多帳號支援位於 `channels.telegram.accounts` 下（見上方多帳號章節）。Env Tokens 僅適用於預設帳號。
設定 `channels.telegram.configWrites: false` 以阻擋 Telegram 發起的 Config Writes（包括 Supergroup ID Migrations 和 `/config set|unset`）。

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "your-bot-token",
      dmPolicy: "pairing",                 // pairing | allowlist | open | disabled
      allowFrom: ["tg:123456789"],         // optional; "open" requires ["*"]
      groups: {
        "*": { requireMention: true },
        "-1001234567890": {
          allowFrom: ["@admin"],
          systemPrompt: "Keep answers brief.",
          topics: {
            "99": {
              requireMention: false,
              skills: ["search"],
              systemPrompt: "Stay on topic."
            }
          }
        }
      },
      customCommands: [
        { command: "backup", description: "Git backup" },
        { command: "generate", description: "Create an image" }
      ],
      historyLimit: 50,                     // 包含最後 N 則群組訊息作為 Context (0 停用)
      replyToMode: "first",                 // off | first | all
      linkPreview: true,                   // Toggle Outbound Link Previews
      streamMode: "partial",               // off | partial | block (Draft Streaming; 與 Block Streaming 分開)
      draftChunk: {                        // optional; 僅當 streamMode=block
        minChars: 200,
        maxChars: 800,
        breakPreference: "paragraph"       // paragraph | newline | sentence
      },
      actions: { reactions: true, sendMessage: true }, // Tool Action Gates (False 停用)
      reactionNotifications: "own",   // off | own | all
      mediaMaxMb: 5,
      retry: {                             // Outbound Retry Policy
        attempts: 3,
        minDelayMs: 400,
        maxDelayMs: 30000,
        jitter: 0.1
      },
      network: {                           // Transport Overrides
        autoSelectFamily: false
      },
      proxy: "socks5://localhost:9050",
      webhookUrl: "https://example.com/telegram-webhook",
      webhookSecret: "secret",
      webhookPath: "/telegram-webhook"
    }
  }
}
```

Draft streaming 註記：
- 使用 Telegram `sendMessageDraft` (Draft Bubble, 非真實訊息)。
- 需要 **Private Chat Topics** (Message Thread ID in DMs; Bot 啟用 Topics)。
- `/reasoning stream` 將 Reasoning 串流至 Draft，然後發送最終答案。
Retry Policy 預設值與行為記錄在 [Retry policy](/concepts/retry)。

### `channels.discord` (bot transport)

透過設定 Bot Token 與可選的 Gating 來設定 Discord Bot：
多帳號支援位於 `channels.discord.accounts` 下（見上方多帳號章節）。Env Tokens 僅適用於預設帳號。

```json5
{
  channels: {
    discord: {
      enabled: true,
      token: "your-bot-token",
      mediaMaxMb: 8,                          // Clamp Inbound Media Size
      allowBots: false,                       // Allow Bot-authored Messages
      actions: {                              // Tool Action Gates (False 停用)
        reactions: true,
        stickers: true,
        polls: true,
        permissions: true,
        messages: true,
        threads: true,
        pins: true,
        search: true,
        memberInfo: true,
        roleInfo: true,
        roles: false,
        channelInfo: true,
        voiceStatus: true,
        events: true,
        moderation: false
      },
      replyToMode: "off",                     // off | first | all
      dm: {
        enabled: true,                        // 當 False 時停用所有 DMs
        policy: "pairing",                    // pairing | allowlist | open | disabled
        allowFrom: ["1234567890", "steipete"], // Optional DM Allowlist ("open" 需要 ["*"])
        groupEnabled: false,                 // Enable Group DMs
        groupChannels: ["openclaw-dm"]          // Optional Group DM Allowlist
      },
      guilds: {
        "123456789012345678": {               // Guild ID (Preferred) 或 Slug
          slug: "friends-of-openclaw",
          requireMention: false,              // Per-guild Default
          reactionNotifications: "own",       // off | own | all | allowlist
          users: ["987654321098765432"],      // Optional Per-guild User Allowlist
          channels: {
            general: { allow: true },
            help: {
              allow: true,
              requireMention: true,
              users: ["987654321098765432"],
              skills: ["docs"],
              systemPrompt: "Short answers only."
            }
          }
        }
      },
      historyLimit: 20,                       // 包含最後 N 則 Guild 訊息作為 Context
      textChunkLimit: 2000,                   // Optional Outbound Text Chunk Size (Chars)
      chunkMode: "length",                    // Optional Chunking Mode (length | newline)
      maxLinesPerMessage: 17,                 // Soft Max Lines Per Message (Discord UI Clipping)
      retry: {                                // Outbound Retry Policy
        attempts: 3,
        minDelayMs: 500,
        maxDelayMs: 30000,
        jitter: 0.1
      }
    }
  }
}
```

OpenClaw 僅在 `channels.discord` Config Section 存在時啟動 Discord。Token 從 `channels.discord.token` 解析，並以 `DISCORD_BOT_TOKEN` 作為預設帳號的 Fallback（除非 `channels.discord.enabled` 為 `false`）。
當指定 Cron/CLI Commands 的傳遞目標時，使用 `user:<id>` (DM) 或 `channel:<id>` (Guild Channel)；純數字 IDs 含糊不清將被拒絕。
Guild Slugs 為小寫並將空格替換為 `-`；Channel Keys 使用 Slugged Channel Name（無前導 `#`）。偏好使用 Guild IDs 作為 Keys 以避免更名歧義。
Bot-authored 訊息預設被忽略。透過 `channels.discord.allowBots` 啟用（自己的訊息仍被過濾以防止 Self-reply Loops）。

Reaction 通知模式：
- `off`: 無 Reaction Events。
- `own`: Bot 自己訊息上的 Reactions (預設)。
- `all`: 所有訊息上的所有 Reactions。
- `allowlist`: 來自 `guilds.<id>.users` 的 Reactions 於所有訊息 (空清單停用)。

Outbound 文字由 `channels.discord.textChunkLimit` (預設 2000) 分塊。設定 `channels.discord.chunkMode="newline"` 在 Length Chunking 之前於空行（段落邊界）分割。Discord Clients 可能會裁切非常高的訊息，因此 `channels.discord.maxLinesPerMessage` (預設 17) 甚至在低於 2000 Chars 時分割長多行回覆。
Retry Policy 預設值與行為記錄在 [Retry policy](/concepts/retry)。

### `channels.googlechat` (Chat API webhook)

Google Chat 透過 App-level Auth (Service Account) 的 HTTP Webhooks 運行。
多帳號支援位於 `channels.googlechat.accounts` 下（見上方多帳號章節）。Env Vars 僅適用於預設帳號。

```json5
{
  channels: {
    "googlechat": {
      enabled: true,
      serviceAccountFile: "/path/to/service-account.json",
      audienceType: "app-url",             // app-url | project-number
      audience: "https://gateway.example.com/googlechat",
      webhookPath: "/googlechat",
      botUser: "users/1234567890",        // optional; improves mention detection
      dm: {
        enabled: true,
        policy: "pairing",                // pairing | allowlist | open | disabled
        allowFrom: ["users/1234567890"]   // optional; "open" requires ["*"]
      },
      groupPolicy: "allowlist",
      groups: {
        "spaces/AAAA": { allow: true, requireMention: true }
      },
      actions: { reactions: true },
      typingIndicator: "message",
      mediaMaxMb: 20
    }
  }
}
```

註記：
- Service Account JSON 可以是 Inline (`serviceAccount`) 或 File-based (`serviceAccountFile`)。
- 預設帳號的 Env Fallbacks: `GOOGLE_CHAT_SERVICE_ACCOUNT` 或 `GOOGLE_CHAT_SERVICE_ACCOUNT_FILE`。
- `audienceType` + `audience` 必須符合 Chat App 的 Webhook Auth Config。
- 設定傳遞目標時使用 `spaces/<spaceId>` 或 `users/<userId|email>`。

### `channels.slack` (socket mode)

Slack 運行於 Socket Mode 且需要 Bot Token 與 App Token：

```json5
{
  channels: {
    slack: {
      enabled: true,
      botToken: "xoxb-...",
      appToken: "xapp-...",
      dm: {
        enabled: true,
        policy: "pairing", // pairing | allowlist | open | disabled
        allowFrom: ["U123", "U456", "*"], // optional; "open" requires ["*"]
        groupEnabled: false,
        groupChannels: ["G123"]
      },
      channels: {
        C123: { allow: true, requireMention: true, allowBots: false },
        "#general": {
          allow: true,
          requireMention: true,
          allowBots: false,
          users: ["U123"],
          skills: ["docs"],
          systemPrompt: "Short answers only."
        }
      },
      historyLimit: 50,          // 包含最後 N 則 Channel/Group 訊息作為 Context (0 停用)
      allowBots: false,
      reactionNotifications: "own", // off | own | all | allowlist
      reactionAllowlist: ["U123"],
      replyToMode: "off",           // off | first | all
      thread: {
        historyScope: "thread",     // thread | channel
        inheritParent: false
      },
      actions: {
        reactions: true,
        messages: true,
        pins: true,
        memberInfo: true,
        emojiList: true
      },
      slashCommand: {
        enabled: true,
        name: "openclaw",
        sessionPrefix: "slack:slash",
        ephemeral: true
      },
      textChunkLimit: 4000,
      chunkMode: "length",
      mediaMaxMb: 20
    }
  }
}
```

多帳號支援位於 `channels.slack.accounts` 下（見上方多帳號章節）。Env Tokens 僅適用於預設帳號。

OpenClaw 僅在 Provider 啟用且兩個 Tokens 已設定時（透過 Config 或 `SLACK_BOT_TOKEN` + `SLACK_APP_TOKEN`）啟動 Slack。當指定 Cron/CLI Commands 的傳遞目標時，使用 `user:<id>` (DM) 或 `channel:<id>`。
設定 `channels.slack.configWrites: false` 以阻擋 Slack 發起的 Config Writes（包括 Channel ID Migrations 和 `/config set|unset`）。

Bot-authored 訊息預設被忽略。透過 `channels.slack.allowBots` 或 `channels.slack.channels.<id>.allowBots` 啟用。

Reaction 通知模式：
- `off`: 無 Reaction Events。
- `own`: Bot 自己訊息上的 Reactions (預設)。
- `all`: 所有訊息上的所有 Reactions。
- `allowlist`: 來自 `channels.slack.reactionAllowlist` 的 Reactions 於所有訊息 (空清單停用)。

Thread Session 隔離：
- `channels.slack.thread.historyScope` 控制 Thread History 是 Per-thread (`thread`，預設) 還是跨 Channel 共用 (`channel`)。
- `channels.slack.thread.inheritParent` 控制新 Thread Sessions 是否繼承 Parent Channel Transcript (預設: False)。

Slack Action Groups (Gate `slack` Tool Actions):
| Action group | Default | Notes |
| --- | --- | --- |
| reactions | enabled | React + List Reactions |
| messages | enabled | Read/Send/Edit/Delete |
| pins | enabled | Pin/Unpin/List |
| memberInfo | enabled | Member Info |
| emojiList | enabled | Custom Emoji List |

### `channels.mattermost` (bot token)

Mattermost 作為 Plugin 發布，未綁定於 Core Install。
請先安裝：`openclaw plugins install @openclaw/mattermost` (或 `./extensions/mattermost` from a git checkout)。

Mattermost 需要 Bot Token 加上 Server 的 Base URL：

```json5
{
  channels: {
    mattermost: {
      enabled: true,
      botToken: "mm-token",
      baseUrl: "https://chat.example.com",
      dmPolicy: "pairing",
      chatmode: "oncall", // oncall | onmessage | onchar
      oncharPrefixes: [">", "!"],
      textChunkLimit: 4000,
      chunkMode: "length"
    }
  }
}
```

OpenClaw 僅在 Account 被設定（Bot Token + Base URL）並啟用時啟動 Mattermost。Token + Base URL 從 `channels.mattermost.botToken` + `channels.mattermost.baseUrl` 或 `MATTERMOST_BOT_TOKEN` + `MATTERMOST_URL` 解析為預設帳號（除非 `channels.mattermost.enabled` 為 `false`）。

Chat modes:
- `oncall` (default): 僅在被 @mentioned 時回應 Channel 訊息。
- `onmessage`: 回應每則 Channel 訊息。
- `onchar`: 當訊息以 Trigger Prefix 開頭時回應 (`channels.mattermost.oncharPrefixes`，預設 `[">", "!"]`)。

存取控制：
- Default DMs: `channels.mattermost.dmPolicy="pairing"` (未知發送者收到 Pairing Code)。
- Public DMs: `channels.mattermost.dmPolicy="open"` 加上 `channels.mattermost.allowFrom=["*"]`。
- Groups: `channels.mattermost.groupPolicy="allowlist"` 預設 (Mention-gated)。使用 `channels.mattermost.groupAllowFrom` 限制發送者。

多帳號支援位於 `channels.mattermost.accounts` 下（見上方多帳號章節）。Env Vars 僅適用於預設帳號。
當指定傳遞目標時，使用 `channel:<id>` 或 `user:<id>` (或 `@username`)；裸 IDs 被視為 Channel IDs。

### `channels.signal` (signal-cli)

Signal Reactions 可發出 System Events (Shared Reaction Tooling):

```json5
{
  channels: {
    signal: {
      reactionNotifications: "own", // off | own | all | allowlist
      reactionAllowlist: ["+15551234567", "uuid:123e4567-e89b-12d3-a456-426614174000"],
      historyLimit: 50 // 包含最後 N 則群組訊息作為 Context (0 停用)
    }
  }
}
```

Reaction 通知模式：
- `off`: 無 Reaction Events。
- `own`: Bot 自己訊息上的 Reactions (預設)。
- `all`: 所有訊息上的所有 Reactions。
- `allowlist`: 來自 `channels.signal.reactionAllowlist` 的 Reactions 於所有訊息 (空清單停用)。

### `channels.imessage` (imsg CLI)

OpenClaw 啟動 `imsg rpc` (JSON-RPC over stdio)。無需 Daemon 或 Port。

```json5
{
  channels: {
    imessage: {
      enabled: true,
      cliPath: "imsg",
      dbPath: "~/Library/Messages/chat.db",
      remoteHost: "user@gateway-host", // 當使用 SSH Wrapper 時，透過 SCP 取得 Remote Attachments
      dmPolicy: "pairing", // pairing | allowlist | open | disabled
      allowFrom: ["+15555550123", "user@example.com", "chat_id:123"],
      historyLimit: 50,    // 包含最後 N 則群組訊息作為 Context (0 停用)
      includeAttachments: false,
      mediaMaxMb: 16,
      service: "auto",
      region: "US"
    }
  }
}
```

多帳號支援位於 `channels.imessage.accounts` 下（見上方多帳號章節）。

註記：
- 需要 Messages DB 的 Full Disk Access。
- 第一次發送時會提示 Messages Automation Permission。
- 偏好 `chat_id:<id>` 目標。使用 `imsg chats --limit 20` 列出 Chats。
- `channels.imessage.cliPath` 可指向 Wrapper Script (例如 `ssh` 到另一台執行 `imsg rpc` 的 Mac)；使用 SSH Keys 避免密碼提示。
- 對於 Remote SSH Wrappers，設定 `channels.imessage.remoteHost` 以在 `includeAttachments` 啟用時透過 SCP 獲取附件。

Wrapper 範例：
```bash
#!/usr/bin/env bash
exec ssh -T gateway-host imsg "$@"
```

### `agents.defaults.workspace`

設定 Agent 用於檔案操作的 **單一全域 Workspace 目錄**。

預設：`~/.openclaw/workspace`。

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } }
}
```

如果啟用了 `agents.defaults.sandbox`，Non-main Sessions 可以在 `agents.defaults.sandbox.workspaceRoot` 下使用它們自己的 Per-scope Workspaces 覆蓋此設定。

### `agents.defaults.repoRoot`

選擇性的儲存庫根目錄，顯示在 System Prompt 的 Runtime 行。若未設定，OpenClaw 會嘗試通過從 Workspace（和當前工作目錄）向上遍歷來檢測 `.git` 目錄。路徑必須存在才能被使用。

```json5
{
  agents: { defaults: { repoRoot: "~/Projects/openclaw" } }
}
```

### `agents.defaults.skipBootstrap`

停用自動建立 Workspace Bootstrap 檔案 (`AGENTS.md`, `SOUL.md`, `TOOLS.md`, `IDENTITY.md`, `USER.md`, 和 `BOOTSTRAP.md`)。

將此用於 Workspace 檔案來自 Repo 的 Pre-seeded Deployments。

```json5
{
  agents: { defaults: { skipBootstrap: true } }
}
```

### `agents.defaults.bootstrapMaxChars`

每個注入到 System Prompt 的 Workspace Bootstrap 檔案的最大字元數（截斷前）。預設：`20000`。

當檔案超過此限制時，OpenClaw 會記錄警告並注入帶有標記的截斷 Head/Tail。

```json5
{
  agents: { defaults: { bootstrapMaxChars: 20000 } }
}
```

### `agents.defaults.userTimezone`

設定使用者的時區用於 **System Prompt Context**（不影響 Message Envelopes 中的時間戳記）。若未設定，OpenClaw 在 Runtime 使用 Host Timezone。

```json5
{
  agents: { defaults: { userTimezone: "America/Chicago" } }
}
```

### `agents.defaults.timeFormat`

控制 System Prompt 的 Current Date & Time 部分顯示的 **時間格式**。
預設：`auto` (OS Preference).

```json5
{
  agents: { defaults: { timeFormat: "auto" } } // auto | 12 | 24
}
```

### `messages`

控制 Inbound/Outbound Prefixes 和可選的 Ack Reactions。
參見 [Messages](/concepts/messages) 以了解 Queueing, Sessions, 與 Streaming Context。

```json5
{
  messages: {
    responsePrefix: "🦞", // or "auto"
    ackReaction: "👀",
    ackReactionScope: "group-mentions",
    removeAckAfterReply: false
  }
}
```

`responsePrefix` 應用於所有 Channels 的 **所有 Outbound Replies**（Tool Summaries, Block Streaming, Final Replies），除非已經存在。

如果 `messages.responsePrefix` 未設定，預設不應用任何前綴。WhatsApp Self-chat Replies 是例外：當設定時預設為 `[{identity.name}]`，否則為 `[openclaw]`，以保持同手機對話的可讀性。
設定為 `"auto"` 以為路由的 Agent 推導 `[{identity.name}]`（當設定時）。

#### 模板變數 (Template variables)

`responsePrefix` 字串可以包含動態解析的模板變數：

| Variable | Description | Example |
|----------|-------------|---------|
| `{model}` | Short Model Name | `claude-opus-4-5`, `gpt-4o` |
| `{modelFull}` | Full Model Identifier | `anthropic/claude-opus-4-5` |
| `{provider}` | Provider Name | `anthropic`, `openai` |
| `{thinkingLevel}` | Current Thinking Level | `high`, `low`, `off` |
| `{identity.name}` | Agent Identity Name | (同 `"auto"` 模式) |

變數區分大小寫 (`{MODEL}` = `{model}`)。`{think}` 是 `{thinkingLevel}` 的別名。
未解析的變數保持為文字。

```json5
{
  messages: {
    responsePrefix: "[{model} | think:{thinkingLevel}]"
  }
}
```

範例輸出：`[claude-opus-4-5 | think:high] Here's my response...`

WhatsApp Inbound Prefix 透過 `channels.whatsapp.messagePrefix` (Deprecated: `messages.messagePrefix`) 設定。預設值 **保持不變**：當 `channels.whatsapp.allowFrom` 為空時為 `"[openclaw]"`，否則為 `""`（無前綴）。當使用 `"[openclaw]"` 時，若路由的 Agent 設定了 `identity.name`，OpenClaw 會改用 `[{identity.name}]`。

`ackReaction` 發送 Best-effort Emoji Reaction 以確認 Inbound 訊息（在支援 Reactions 的 Channels 上：Slack/Discord/Telegram/Google Chat）。當設定時預設為活躍 Agent 的 `identity.emoji`，否則為 `"👀"`。設定為 `""` 以停用。

`ackReactionScope` 控制何時觸發 Reactions：
- `group-mentions` (default): 僅當 Group/Room 需要 Mentions **且** Bot 被 Mention 時
- `group-all`: 所有 Group/Room 訊息
- `direct`: 僅 Direct Messages
- `all`: 所有訊息

`removeAckAfterReply` 在發送回覆後移除 Bot 的 Ack Reaction (僅 Slack/Discord/Telegram/Google Chat)。預設：`false`。

#### `messages.tts`

啟用 Outbound Replies 的文字轉語音。啟用時，OpenClaw 使用 ElevenLabs 或 OpenAI 生成音訊並將其附加到回應中。Telegram 使用 Opus Voice Notes；其他 Channels 發送 MP3 Audio。

```json5
{
  messages: {
    tts: {
      auto: "always", // off | always | inbound | tagged
      mode: "final", // final | all (包含 Tool/Block Replies)
      provider: "elevenlabs",
      summaryModel: "openai/gpt-4.1-mini",
      modelOverrides: {
        enabled: true
      },
      maxTextLength: 4000,
      timeoutMs: 30000,
      prefsPath: "~/.openclaw/settings/tts.json",
      elevenlabs: {
        apiKey: "elevenlabs_api_key",
        baseUrl: "https://api.elevenlabs.io",
        voiceId: "voice_id",
        modelId: "eleven_multilingual_v2",
        seed: 42,
        applyTextNormalization: "auto",
        languageCode: "en",
        voiceSettings: {
          stability: 0.5,
          similarityBoost: 0.75,
          style: 0.0,
          useSpeakerBoost: true,
          speed: 1.0
        }
      },
      openai: {
        apiKey: "openai_api_key",
        model: "gpt-4o-mini-tts",
        voice: "alloy"
      }
    }
  }
}
```

註記：
- `messages.tts.auto` 控制 Auto‑TTS (`off`, `always`, `inbound`, `tagged`)。
- `/tts off|always|inbound|tagged` 設定 Per‑session Auto Mode（覆蓋 Config）。
- `messages.tts.enabled` 已棄用；Doctor 將其遷移至 `messages.tts.auto`。
- `prefsPath` 儲存本地 Overrides (Provider/Limit/Summarize)。
- `maxTextLength` 是 TTS Input 的硬限制；Summaries 會被截斷以符合。
- `summaryModel` 覆蓋 `agents.defaults.model.primary` 用於 Auto-summary。
  - 接受 `provider/model` 或來自 `agents.defaults.models` 的 Alias。
- `modelOverrides` 啟用 Model-driven Overrides 如 `[[tts:...]]` Tags（預設開啟）。
- `/tts limit` 與 `/tts summary` 控制 Per-user Summarization Settings。
- `apiKey` 值 Fallback 至 `ELEVENLABS_API_KEY`/`XI_API_KEY` 與 `OPENAI_API_KEY`。
- `elevenlabs.baseUrl` 覆蓋 ElevenLabs API Base URL。
- `elevenlabs.voiceSettings` 支援 `stability`/`similarityBoost`/`style` (0..1), `useSpeakerBoost`, 以及 `speed` (0.5..2.0)。

### `talk`

Talk Mode (macOS/iOS/Android) 的預設值。當未設定時，Voice IDs Fallback 至 `ELEVENLABS_VOICE_ID` 或 `SAG_VOICE_ID`。
`apiKey` 當未設定時 Fallback 至 `ELEVENLABS_API_KEY`（或 Gateway 的 Shell Profile）。
`voiceAliases` 讓 Talk Directives 使用友善名稱（例如 `"voice":"Clawd"`）。

```json5
{
  talk: {
    voiceId: "elevenlabs_voice_id",
    voiceAliases: {
      Clawd: "EXAVITQu4vr4xnSDxMaL",
      Roger: "CwhRBWXzGAHq8TQ4Fs17"
    },
    modelId: "eleven_v3",
    outputFormat: "mp3_44100_128",
    apiKey: "elevenlabs_api_key",
    interruptOnSpeech: true
  }
}
```

### `agents.defaults`

控制內建 Agent Runtime (Model/Thinking/Verbose/Timeouts)。
`agents.defaults.models` 定義已設定的 Model Catalog（並作為 `/model` 的 Allowlist）。
`agents.defaults.model.primary` 設定預設模型；`agents.defaults.model.fallbacks` 是 Global Failovers。
`agents.defaults.imageModel` 是選擇性的，**僅在 Primary Model 缺乏 Image Input 時使用**。
每個 `agents.defaults.models` 項目可以包含：
- `alias` (Optional Model Shortcut, 例如 `/opus`)。
- `params` (Optional Provider-specific API Params，傳遞給 Model Request)。

`params` 也應用於 Streaming Runs (Embedded Agent + Compaction)。目前支援的 Keys: `temperature`, `maxTokens`。這些與 Call-time Options 合併；Caller 提供的值獲勝。`temperature` 是進階旋鈕——除非您知道模型的預設值並需要更改，否則請保留未設定。

範例：

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-sonnet-4-5-20250929": {
          params: { temperature: 0.6 }
        },
        "openai/gpt-5.2": {
          params: { maxTokens: 8192 }
        }
      }
    }
  }
}
```

Z.AI GLM-4.x Models 自動啟用 Thinking Mode，除非您：
- 設定 `--thinking off`，或
- 自行定義 `agents.defaults.models["zai/<model>"].params.thinking`。

OpenClaw 也內建了一些 Alias Shorthands。Defaults 僅在 Model 已存在於 `agents.defaults.models` 時適用：

- `opus` -> `anthropic/claude-opus-4-5`
- `sonnet` -> `anthropic/claude-sonnet-4-5`
- `gpt` -> `openai/gpt-5.2`
- `gpt-mini` -> `openai/gpt-5-mini`
- `gemini` -> `google/gemini-3-pro-preview`
- `gemini-flash` -> `google/gemini-3-flash-preview`

若您自行設定了相同的 Alias Name（不區分大小寫），您的值獲勝（Defaults 絕不覆蓋）。

範例：Opus 4.5 Primary 搭配 MiniMax M2.1 Fallback (Hosted MiniMax):

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-5": { alias: "opus" },
        "minimax/MiniMax-M2.1": { alias: "minimax" }
      },
      model: {
        primary: "anthropic/claude-opus-4-5",
        fallbacks: ["minimax/MiniMax-M2.1"]
      }
    }
  }
}
```

MiniMax Auth: 設定 `MINIMAX_API_KEY` (Env) 或設定 `models.providers.minimax`。

#### `agents.defaults.cliBackends` (CLI fallback)

用於 Text-only Fallback Runs (No Tool Calls) 的選擇性 CLI Backends。當 API Providers 失敗時，這些作為備份路徑非常有用。當您設定接受 File Paths 的 `imageArg` 時，支援 Image Pass-through。

註記：
- CLI Backends 是 **Text-first**；Tools 總是停用。
- 當設定 `sessionArg` 時支援 Sessions；Session IDs 每個 Backend 持久化。
- 對於 `claude-cli`，預設值已內建。若 PATH 極簡 (launchd/systemd)，請覆蓋 Command Path。

範例：

```json5
{
  agents: {
    defaults: {
      cliBackends: {
        "claude-cli": {
          command: "/opt/homebrew/bin/claude"
        },
        "my-cli": {
          command: "my-cli",
          args: ["--json"],
          output: "json",
          modelArg: "--model",
          sessionArg: "--session",
          sessionMode: "existing",
          systemPromptArg: "--system",
          systemPromptWhen: "first",
          imageArg: "--image",
          imageMode: "repeat"
        }
      }
    }
  }
}
```

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-5": { alias: "Opus" },
        "anthropic/claude-sonnet-4-1": { alias: "Sonnet" },
        "openrouter/deepseek/deepseek-r1:free": {},
        "zai/glm-4.7": {
          alias: "GLM",
          params: {
            thinking: {
              type: "enabled",
              clear_thinking: false
            }
          }
        }
      },
      model: {
        primary: "anthropic/claude-opus-4-5",
        fallbacks: [
          "openrouter/deepseek/deepseek-r1:free",
          "openrouter/meta-llama/llama-3.3-70b-instruct:free"
        ]
      },
      imageModel: {
        primary: "openrouter/qwen/qwen-2.5-vl-72b-instruct:free",
        fallbacks: [
          "openrouter/google/gemini-2.0-flash-vision:free"
        ]
      },
      thinkingDefault: "low",
      verboseDefault: "off",
      elevatedDefault: "on",
      timeoutSeconds: 600,
      mediaMaxMb: 5,
      heartbeat: {
        every: "30m",
        target: "last"
      },
      maxConcurrent: 3,
      subagents: {
        model: "minimax/MiniMax-M2.1",
        maxConcurrent: 1,
        archiveAfterMinutes: 60
      },
      exec: {
        backgroundMs: 10000,
        timeoutSec: 1800,
        cleanupMs: 1800000
      },
      contextTokens: 200000
    }
  }
}
```

#### `agents.defaults.contextPruning` (tool-result pruning)

`agents.defaults.contextPruning` 在請求發送給 LLM 之前，從 In-memory Context 中修剪 **舊的 Tool Results**。
它 **不** 修改 Disk 上的 Session History (`*.jsonl` 保持完整)。

這旨在減少累積大量 Tool Outputs 的 Chatty Agents 的 Token 使用量。

High level:
- 絕不觸碰 User/Assistant 訊息。
- 保護最後 `keepLastAssistants` 則 Assistant 訊息（該點之後的 Tool Results 不會被修剪）。
- 保護 Bootstrap 前綴（第一則 User 訊息之前的任何內容都不會被修剪）。
- 模式：
  - `adaptive`: 當估計的 Context Ratio 超過 `softTrimRatio` 時，Soft-trim 過大的 Tool Results (保留 Head/Tail)。
    然後當估計的 Context Ratio 超過 `hardClearRatio` **且** 有足夠的可修剪 Tool-result Bulk (`minPrunableToolChars`) 時，Hard-clear 最舊的合格 Tool Results。
  - `aggressive`: 在截止點之前總是將合格的 Tool Results 替換為 `hardClear.placeholder` (無 Ratio Checks)。

Soft vs Hard Pruning (傳送給 LLM 的 Context 中的變化):
- **Soft-trim**: 僅針對 *Oversized* Tool Results。保留開頭 + 結尾並在中間插入 `...`。
  - Before: `toolResult("…very long output…")`
  - After: `toolResult("HEAD…\n...\n…TAIL\n\n[Tool result trimmed: …]")`
- **Hard-clear**: 將整個 Tool Result 替換為 Placeholder。
  - Before: `toolResult("…very long output…")`
  - After: `toolResult("[Old tool result content cleared]")`

註記 / 目前限制：
- 包含 **Image Blocks** 的 Tool Results 目前被跳過（絕不 Trimmed/Cleared）。
- 估計的 “Context Ratio” 基於 **字元**（近似），非精確 Tokens。
- 若 Session 尚未包含至少 `keepLastAssistants` 則 Assistant 訊息，則跳過修剪。
- 在 `aggressive` 模式中，`hardClear.enabled` 被忽略（合格的 Tool Results 總是被替換為 `hardClear.placeholder`）。

預設 (Adaptive):
```json5
{
  agents: { defaults: { contextPruning: { mode: "adaptive" } } }
}
```

停用：
```json5
{
  agents: { defaults: { contextPruning: { mode: "off" } } }
}
```

預設值 (當 `mode` 為 `"adaptive"` 或 `"aggressive"`):
- `keepLastAssistants`: `3`
- `softTrimRatio`: `0.3` (Adaptive Only)
- `hardClearRatio`: `0.5` (Adaptive Only)
- `minPrunableToolChars`: `50000` (Adaptive Only)
- `softTrim`: `{ maxChars: 4000, headChars: 1500, tailChars: 1500 }` (Adaptive Only)
- `hardClear`: `{ enabled: true, placeholder: "[Old tool result content cleared]" }`

範例 (Aggressive, Minimal):
```json5
{
  agents: { defaults: { contextPruning: { mode: "aggressive" } } }
}
```

範例 (Adaptive Tuned):
```json5
{
  agents: {
    defaults: {
      contextPruning: {
        mode: "adaptive",
        keepLastAssistants: 3,
        softTrimRatio: 0.3,
        hardClearRatio: 0.5,
        minPrunableToolChars: 50000,
        softTrim: { maxChars: 4000, headChars: 1500, tailChars: 1500 },
        hardClear: { enabled: true, placeholder: "[Old tool result content cleared]" },
        // Optional: 限制修剪至特定 Tools (Deny Wins; 支援 "*" Wildcards)
        tools: { deny: ["browser", "canvas"] },
      }
    }
  }
}
```

參閱 [/concepts/session-pruning](/concepts/session-pruning) 以了解行為細節。

#### `agents.defaults.compaction` (reserve headroom + memory flush)

`agents.defaults.compaction.mode` 選擇 Compaction Summarization Strategy。預設為 `default`；設定 `safeguard` 以啟用針對極長 Histories 的 Chunked Summarization。參閱 [/concepts/compaction](/concepts/compaction)。

`agents.defaults.compaction.reserveTokensFloor` 強制執行 Pi Compaction 的最小 `reserveTokens` 值（預設：`20000`）。設定為 `0` 以停用 Floor。

`agents.defaults.compaction.memoryFlush` 在 Auto-compaction 之前運行一個 **Silent** Agentic Turn，指示模型將持久 Memories 儲存在 Disk 上（例如 `memory/YYYY-MM-DD.md`）。當 Session Token Estimate 超過 Compaction Limit 下方的 Soft Threshold 時觸發。

Legacy Defaults:
- `memoryFlush.enabled`: `true`
- `memoryFlush.softThresholdTokens`: `4000`
- `memoryFlush.prompt` / `memoryFlush.systemPrompt`: Built-in Defaults with `NO_REPLY`
- 註記：當 Session Workspace 為 Read-only 時跳過 Memory Flush (`agents.defaults.sandbox.workspaceAccess: "ro"` 或 `"none"`)。

範例 (Tuned):
```json5
{
  agents: {
    defaults: {
      compaction: {
        mode: "safeguard",
        reserveTokensFloor: 24000,
        memoryFlush: {
          enabled: true,
          softThresholdTokens: 6000,
          systemPrompt: "Session nearing compaction. Store durable memories now.",
          prompt: "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY if nothing to store."
        }
      }
    }
  }
}
```

Block streaming:
- `agents.defaults.blockStreamingDefault`: `"on"`/`"off"` (預設 Off).
- Channel Overrides: `*.blockStreaming` (和 Per-account Variants) 強制開啟/關閉 Block Streaming。
  Non-Telegram Channels 需要顯式 `*.blockStreaming: true` 以啟用 Block Replies。
- `agents.defaults.blockStreamingBreak`: `"text_end"` 或 `"message_end"` (預設: text_end).
- `agents.defaults.blockStreamingChunk`: Streamed Blocks 的 Soft Chunking。預設為 800–1200 Chars，偏好段落分隔 (`\n\n`)，其次 Newlines，然後 Sentences。
  範例：
  ```json5
  {
    agents: { defaults: { blockStreamingChunk: { minChars: 800, maxChars: 1200 } } }
  }
  ```
- `agents.defaults.blockStreamingCoalesce`: 發送前合併 Streamed Blocks。
  預設為 `{ idleMs: 1000 }` 並繼承 `blockStreamingChunk` 的 `minChars`，`maxChars` 上限為 Channel Text Limit。Signal/Slack/Discord/Google Chat 預設為 `minChars: 1500`（除非被覆蓋）。
  Channel Overrides: `channels.whatsapp.blockStreamingCoalesce` 等 (和 Per-account Variants)。
- `agents.defaults.humanDelay`: 第一個 Block Reply 之後的隨機暫停。
  Modes: `off` (default), `natural` (800–2500ms), `custom` (use `minMs`/`maxMs`).
  Per-agent Override: `agents.list[].humanDelay`.
  範例：
  ```json5
  {
    agents: { defaults: { humanDelay: { mode: "natural" } } }
  }
  ```
參閱 [/concepts/streaming](/concepts/streaming) 以了解行為 + Chunking 細節。

Typing indicators:
- `agents.defaults.typingMode`: `"never" | "instant" | "thinking" | "message"`. Direct Chats / Mentions 預設為 `instant`，Unmentioned Group Chats 預設為 `message`。
- `session.typingMode`: Per-session Mode Override.
- `agents.defaults.typingIntervalSeconds`: Typing Signal 重新整理頻率（預設：6s）。
- `session.typingIntervalSeconds`: Per-session Refresh Interval Override.
參閱 [/concepts/typing-indicators](/concepts/typing-indicators) 以了解行為細節。

`agents.defaults.model.primary` 應設定為 `provider/model` (例如 `anthropic/claude-opus-4-5`)。
Aliases 來自 `agents.defaults.models.*.alias` (例如 `Opus`)。
若您省略 Provider，OpenClaw 目前假設 `anthropic` 作為暫時的 Deprecation Fallback。
Z.AI Models 作為 `zai/<model>` 提供 (例如 `zai/glm-4.7`) 並需要在環境變數中設定 `ZAI_API_KEY` (或 Legacy `Z_AI_API_KEY`)。

`agents.defaults.heartbeat` 設定週期性 Heartbeat Runs:
- `every`: Duration String (`ms`, `s`, `m`, `h`); Default Unit Minutes. 預設：`30m`. 設定 `0m` 以停用。
- `model`: Optional Override Model for Heartbeat Runs (`provider/model`).
- `includeReasoning`: 當 `true` 時，Heartbeats 也會傳遞單獨的 `Reasoning:` 訊息（當可用時，格式同 `/reasoning on`）。預設：`false`。
- `session`: Optional Session Key 用於控制 Heartbeat 運行於哪個 Session。預設：`main`。
- `to`: Optional Recipient Override (Channel-specific ID, e.g. E.164 for WhatsApp, Chat ID for Telegram).
- `target`: Optional Delivery Channel (`last`, `whatsapp`, `telegram`, `discord`, `slack`, `msteams`, `signal`, `imessage`, `none`). 預設：`last`。
- `prompt`: Optional Override for Heartbeat Body (預設: `Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`). Overrides 逐字發送；若您仍希望讀取檔案，請包含 `Read HEARTBEAT.md` 行。
- `ackMaxChars`: `HEARTBEAT_OK` 之後允許的最大字元數（預設：300）。

Per-agent heartbeats:
- 設定 `agents.list[].heartbeat` 以啟用或覆蓋特定 Agent 的 Heartbeat 設定。
- 若任何 Agent Entry 定義了 `heartbeat`，**僅這些 Agents** 運行 Heartbeats；Defaults 成為這些 Agents 的共用基準。

Heartbeats 運行完整的 Agent Turns。較短的間隔會消耗更多 Tokens；請留意 `every`，保持 `HEARTBEAT.md` 精簡，和/或選擇較便宜的 `model`。

`tools.exec` 設定 Background Exec Defaults:
- `backgroundMs`: Auto-background 前的時間 (ms, default 10000)
- `timeoutSec`: Auto-kill AFTER THIS RUNTIME (seconds, default 1800)
- `cleanupMs`: 在記憶體中保留 Finished Sessions 多久 (ms, default 1800000)
- `notifyOnExit`: Enqueue System Event + Request Heartbeat 當 Backgrounded Exec Exits (default true)
- `applyPatch.enabled`: Enable Experimental `apply_patch` (OpenAI/OpenAI Codex only; default false)
- `applyPatch.allowModels`: Optional Allowlist of Model IDs (e.g. `gpt-5.2` or `openai/gpt-5.2`)
註記：`applyPatch` 僅在 `tools.exec` 下。

`tools.web` 設定 Web Search + Fetch Tools:
- `tools.web.search.enabled` (default: true when key is present)
- `tools.web.search.apiKey` (recommended: set via `openclaw configure --section web`, or use `BRAVE_API_KEY` env var)
- `tools.web.search.maxResults` (1–10, default 5)
- `tools.web.search.timeoutSeconds` (default 30)
- `tools.web.search.cacheTtlMinutes` (default 15)
- `tools.web.fetch.enabled` (default true)
- `tools.web.fetch.maxChars` (default 50000)
- `tools.web.fetch.timeoutSeconds` (default 30)
- `tools.web.fetch.cacheTtlMinutes` (default 15)
- `tools.web.fetch.userAgent` (optional override)
- `tools.web.fetch.readability` (default true; disable to use basic HTML cleanup only)
- `tools.web.fetch.firecrawl.enabled` (default true when an API key is set)
- `tools.web.fetch.firecrawl.apiKey` (optional; defaults to `FIRECRAWL_API_KEY`)
- `tools.web.fetch.firecrawl.baseUrl` (default https://api.firecrawl.dev)
- `tools.web.fetch.firecrawl.onlyMainContent` (default true)
- `tools.web.fetch.firecrawl.maxAgeMs` (optional)
- `tools.web.fetch.firecrawl.timeoutSeconds` (optional)

`tools.media` 設定 Inbound Media Understanding (Image/Audio/Video):
- `tools.media.models`: Shared Model List (Capability-tagged; used after per-cap lists).
- `tools.media.concurrency`: Max Concurrent Capability Runs (default 2).
- `tools.media.image` / `tools.media.audio` / `tools.media.video`:
  - `enabled`: Opt-out Switch (default true when models are configured).
  - `prompt`: Optional Prompt Override (Image/Video append a `maxChars` hint automatically).
  - `maxChars`: Max Output Characters (default 500 for image/video; unset for audio).
  - `maxBytes`: Max Media Size to Send (defaults: image 10MB, audio 20MB, video 50MB).
  - `timeoutSeconds`: Request Timeout (defaults: image 60s, audio 60s, video 120s).
  - `language`: Optional Audio Hint.
  - `attachments`: Attachment Policy (`mode`, `maxAttachments`, `prefer`).
  - `scope`: Optional Gating (first match wins) with `match.channel`, `match.chatType`, or `match.keyPrefix`.
  - `models`: Ordered List of Model Entries; failures or oversize media fall back to the next entry.
- 每個 `models[]` 項目：
  - Provider Entry (`type: "provider"` or omitted):
    - `provider`: API Provider ID (`openai`, `anthropic`, `google`/`gemini`, `groq`, etc).
    - `model`: Model ID Override (Required for Image; Defaults to `gpt-4o-mini-transcribe`/`whisper-large-v3-turbo` for Audio Providers, and `gemini-3-flash-preview` for Video).
    - `profile` / `preferredProfile`: Auth Profile Selection.
  - CLI Entry (`type: "cli"`):
    - `command`: Executable to run.
    - `args`: Templated Args (Supports `{{MediaPath}}`, `{{Prompt}}`, `{{MaxChars}}`, etc).
  - `capabilities`: Optional List (`image`, `audio`, `video`) to gate a shared entry. omited defaults: `openai`/`anthropic`/`minimax` → image, `google` → image+audio+video, `groq` → audio.
  - `prompt`, `maxChars`, `maxBytes`, `timeoutSeconds`, `language` can be overridden per entry.

若無配置 Models (或 `enabled: false`)，Understanding 被跳過；模型仍接收原始 Attachments。

Provider Auth 遵循標準 Model Auth Order (Auth Profiles, Env Vars like `OPENAI_API_KEY`/`GROQ_API_KEY`/`GEMINI_API_KEY`, or `models.providers.*.apiKey`).

範例：
```json5
{
  tools: {
    media: {
      audio: {
        enabled: true,
        maxBytes: 20971520,
        scope: {
          default: "deny",
          rules: [{ action: "allow", match: { chatType: "direct" } }]
        },
        models: [
          { provider: "openai", model: "gpt-4o-mini-transcribe" },
          { type: "cli", command: "whisper", args: ["--model", "base", "{{MediaPath}}"] }
        ]
      },
      video: {
        enabled: true,
        maxBytes: 52428800,
        models: [{ provider: "google", model: "gemini-3-flash-preview" }]
      }
    }
  }
}
```

`agents.defaults.subagents` 設定 Sub-agent Defaults:
- `model`: Spawned Sub-agents 的預設模型 (String or `{ primary, fallbacks }`)。若省略，Sub-agents 繼承 Caller 的模型，除非 Per Agent 或 Per Call 覆蓋。
- `maxConcurrent`: Max Concurrent Sub-agent Runs (default 1)
- `archiveAfterMinutes`: Auto-archive Sub-agent Sessions after N minutes (default 60; set `0` to disable)
- Per-subagent Tool Policy: `tools.subagents.tools.allow` / `tools.subagents.tools.deny` (Deny Wins)

`tools.profile` 設定 **Base Tool Allowlist** (在 `tools.allow`/`tools.deny` 之前):
- `minimal`: 僅 `session_status`
- `coding`: `group:fs`, `group:runtime`, `group:sessions`, `group:memory`, `image`
- `messaging`: `group:messaging`, `sessions_list`, `sessions_history`, `sessions_send`, `session_status`
- `full`: 無限制 (同 Unset)

Per-agent Override: `agents.list[].tools.profile`.

範例 (Messaging-only by default, allow Slack + Discord tools too):
```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"]
  }
}
```

範例 (Coding Profile, but deny exec/process everywhere):
```json5
{
  tools: {
    profile: "coding",
    deny: ["group:runtime"]
  }
}
```

`tools.byProvider` 讓您 **進一步限制** 特定 Providers (或單一 `provider/model`) 的 Tools。
Per-agent Override: `agents.list[].tools.byProvider`。

順序：Base Profile → Provider Profile → Allow/Deny Policies。
Provider Keys 接受 `provider` (e.g. `google-antigravity`) 或 `provider/model` (e.g. `openai/gpt-5.2`)。

範例 (Keep global coding profile, but minimal tools for Google Antigravity):
```json5
{
  tools: {
    profile: "coding",
    byProvider: {
      "google-antigravity": { profile: "minimal" }
    }
  }
}
```

範例 (Provider/Model-specific Allowlist):
```json5
{
  tools: {
    allow: ["group:fs", "group:runtime", "sessions_list"],
    byProvider: {
      "openai/gpt-5.2": { allow: ["group:fs", "sessions_list"] }
    }
  }
}
```

`tools.allow` / `tools.deny` 設定全域 Tool Allow/Deny Policy (Deny Wins)。
匹配不區分大小寫並支援 `*` Wildcards (`"*"` 意指所有 Tools)。
這甚至在 Docker Sandbox 為 **Off** 時也適用。

範例 (Disable browser/canvas everywhere):
```json5
{
  tools: { deny: ["browser", "canvas"] }
}
```

Tool Group Shorthands 在 **Global** 和 **Per-agent** Tool Policies 中運作：
- `group:runtime`: `exec`, `bash`, `process`
- `group:fs`: `read`, `write`, `edit`, `apply_patch`
- `group:sessions`: `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status`
- `group:memory`: `memory_search`, `memory_get`
- `group:web`: `web_search`, `web_fetch`
- `group:ui`: `browser`, `canvas`
- `group:automation`: `cron`, `gateway`
- `group:messaging`: `message`
- `group:nodes`: `nodes`
- `group:openclaw`: 所有內建 OpenClaw Tools (排除 Provider Plugins)

`tools.elevated` 控制 Elevated (Host) Exec Access:
- `enabled`: 允許 Elevated Mode (default true)
- `allowFrom`: Per-channel Allowlists (Empty = Disabled)
  - `whatsapp`: E.164 Numbers
  - `telegram`: Chat IDs or Usernames
  - `discord`: User IDs or Usernames (falls back to `channels.discord.dm.allowFrom` if omitted)
  - `signal`: E.164 Numbers
  - `imessage`: Handles/Chat IDs
  - `webchat`: Session IDs or Usernames

範例：
```json5
{
  tools: {
    elevated: {
      enabled: true,
      allowFrom: {
        whatsapp: ["+15555550123"],
        discord: ["steipete", "1234567890123"]
      }
    }
  }
}
```

Per-agent Override (Further Restrict):
```json5
{
  agents: {
    list: [
      {
        id: "family",
        tools: {
          elevated: { enabled: false }
        }
      }
    ]
  }
}
```

註記：
- `tools.elevated` 是 Global Baseline。`agents.list[].tools.elevated` 只能進一步限制（兩者都必須允許）。
- `/elevated on|off|ask|full` 儲存 Per Session Key 的狀態；Inline Directives 適用於單一訊息。
- Elevated `exec` 在 Host 上運行並繞過 Sandboxing。
- Tool Policy 仍然適用；若 `exec` 被拒絕，Elevated 無法使用。

`agents.defaults.maxConcurrent` 設定可以跨 Sessions 並行執行的最大 Embedded Agent Runs 數量。每個 Session 仍然依序執行（一次一個 Run per Session Key）。預設：1。

### `agents.defaults.sandbox`

選擇性的 **Docker Sandboxing** 用於 Embedded Agent。旨在讓 Non-main Sessions 無法存取您的 Host System。

詳情：[Sandboxing](/gateway/sandboxing)

Defaults (If enabled):
- scope: `"agent"` (One container + workspace per agent)
-基於 Debian bookworm-slim 的 Image
- Agent Workspace Access: `workspaceAccess: "none"` (Default)
  - `"none"`: 在 `~/.openclaw/sandboxes` 下使用 Per-scope Sandbox Workspace
- `"ro"`: 保持 Sandbox Workspace 於 `/workspace`，並將 Agent Workspace Read-only 掛載於 `/agent` (停用 `write`/`edit`/`apply_patch`)
  - `"rw"`: 將 Agent Workspace Read/Write 掛載於 `/workspace`
- Auto-prune: Idle > 24h OR Age > 7d
- Tool Policy: 僅允許 `exec`, `process`, `read`, `write`, `edit`, `apply_patch`, `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status` (Deny Wins)
  - 透過 `tools.sandbox.tools` 設定，透過 `agents.list[].tools.sandbox.tools` Per-agent 覆蓋
  - Sandbox Policy 中支援 Tool Group Shorthands: `group:runtime`, `group:fs`, `group:sessions`, `group:memory` (參見 [Sandbox vs Tool Policy vs Elevated](/gateway/sandbox-vs-tool-policy-vs-elevated#tool-groups-shorthands))
- Optional Sandboxed Browser (Chromium + CDP, noVNC observer)
- Hardening Knobs: `network`, `user`, `pidsLimit`, `memory`, `cpus`, `ulimits`, `seccompProfile`, `apparmorProfile`

警告：`scope: "shared"` 意味著 Shared Container 和 Shared Workspace。無 Cross-session Isolation。使用 `scope: "session"` 進行 Per-session Isolation。

Legacy: `perSession` 仍支援 (`true` → `scope: "session"`, `false` → `scope: "shared"`)。

`setupCommand` 在 Container 建立後運行 **一次**（在 Container 內透過 `sh -lc`）。
對於 Package Installs，確保 Network Egress，Writable Root FS，和 Root User。

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // off | non-main | all
        scope: "agent", // session | agent | shared (agent is default)
        workspaceAccess: "none", // none | ro | rw
        workspaceRoot: "~/.openclaw/sandboxes",
        docker: {
          image: "openclaw-sandbox:bookworm-slim",
          containerPrefix: "openclaw-sbx-",
          workdir: "/workspace",
          readOnlyRoot: true,
          tmpfs: ["/tmp", "/var/tmp", "/run"],
          network: "none",
          user: "1000:1000",
          capDrop: ["ALL"],
          env: { LANG: "C.UTF-8" },
          setupCommand: "apt-get update && apt-get install -y git curl jq",
          // Per-agent override (multi-agent): agents.list[].sandbox.docker.*
          pidsLimit: 256,
          memory: "1g",
          memorySwap: "2g",
          cpus: 1,
          ulimits: {
            nofile: { soft: 1024, hard: 2048 },
            nproc: 256
          },
          seccompProfile: "/path/to/seccomp.json",
          apparmorProfile: "openclaw-sandbox",
          dns: ["1.1.1.1", "8.8.8.8"],
          extraHosts: ["internal.service:10.0.0.5"],
          binds: ["/var/run/docker.sock:/var/run/docker.sock", "/home/user/source:/source:rw"]
        },
        browser: {
          enabled: false,
          image: "openclaw-sandbox-browser:bookworm-slim",
          containerPrefix: "openclaw-sbx-browser-",
          cdpPort: 9222,
          vncPort: 5900,
          noVncPort: 6080,
          headless: false,
          enableNoVnc: true,
          allowHostControl: false,
          allowedControlUrls: ["http://10.0.0.42:18791"],
          allowedControlHosts: ["browser.lab.local", "10.0.0.42"],
          allowedControlPorts: [18791],
          autoStart: true,
          autoStartTimeoutMs: 12000
        },
        prune: {
          idleHours: 24,  // 0 disables idle pruning
          maxAgeDays: 7   // 0 disables max-age pruning
        }
      }
    }
  },
  tools: {
    sandbox: {
      tools: {
        allow: ["exec", "process", "read", "write", "edit", "apply_patch", "sessions_list", "sessions_history", "sessions_send", "sessions_spawn", "session_status"],
        deny: ["browser", "canvas", "nodes", "cron", "discord", "gateway"]
      }
    }
  }
}
```

使用以下指令建置一次預設 Sandbox Image：
```bash
scripts/sandbox-setup.sh
```

註記：Sandbox Containers 預設為 `network: "none"`；若 Agent 需要 Outbound Access，設定 `agents.defaults.sandbox.docker.network` 為 `"bridge"` (或您的 Custom Network)。

註記：Inbound Attachments 分階段存入 Active Workspace 的 `media/inbound/*`。使用 `workspaceAccess: "rw"`，這意指檔案寫入 Agent Workspace。

註記：`docker.binds` 掛載額外的 Host Directories；Global 和 Per-agent Binds 會合併。

使用以下指令建置可選的 Browser Image：
```bash
scripts/sandbox-browser-setup.sh
```

當 `agents.defaults.sandbox.browser.enabled=true` 時，Browser Tool 使用 sandboxed Chromium Instance (CDP)。若 nonVNC 啟用（當 headless=false 時預設啟用），noVNC URL 會注入 System Prompt 以便 Agent 引用。這不需要 Main Config 中的 `browser.enabled`；Sandbox Control URL 是 Per Session 注入的。

`agents.defaults.sandbox.browser.allowHostControl` (預設: false) 允許 Sandboxed Sessions 透過 Browser Tool (`target: "host"`) 明確鎖定 **Host** Browser Control Server。若您想要 Strict Sandbox Isolation，請保持此項關閉。

Remote Control Allowlists:
- `allowedControlUrls`: `target: "custom"` 允許的精確 Control URLs。
- `allowedControlHosts`: 允許的 Hostnames (Hostname Only, No Port)。
- `allowedControlPorts`: 允許的 Ports (Defaults: http=80, https=443)。
Defaults: 所有 Allowlists 未設定 (No Restriction)。`allowHostControl` 預設為 False。

### `models` (provider configurations)

設定 Custom Providers 或覆蓋內建設定。
預設行為是 **Merge**：您定義的 keys 會新增至或覆蓋內建清單。
- 設定 `models.mode: "replace"` 以覆蓋檔案內容

透過 `agents.defaults.model.primary` (provider/model) 選擇模型。

```json5
{
  agents: {
    defaults: {
      model: { primary: "custom-proxy/llama-3.1-8b" },
      models: {
        "custom-proxy/llama-3.1-8b": {}
      }
    }
  },
  models: {
    mode: "merge",
    providers: {
      "custom-proxy": {
        baseUrl: "http://localhost:4000/v1",
        apiKey: "LITELLM_KEY",
        api: "openai-completions",
        models: ["llama-3.1-8b"]
      }
    }
  }
}
```

#### OpenCode Zen (DeepSeek V3/R1)

```json5
{
  agents: {
    defaults: {
      model: { primary: "open-code-zen/deepseek-v3" }
    }
  },
  models: {
    providers: {
      "open-code-zen": {
        baseUrl: "https://api.opencodezen.com/v1",
        apiKey: "sk-...",
        api: "openai",
        models: ["deepseek-v3", "deepseek-r1"],
        // Zen-specific headers if needed
        extraHeaders: { "X-Zen-Org": "my-org" }
      }
    }
  }
}
```

#### Z.AI (GLM-4)

Z.AI Models 內建為 `zai/<model>`。您需要設定 `ZAI_API_KEY` 環境變數。
若要透過 Config 明確設定：

```json5
{
  models: {
    providers: {
      zai: {
        apiKey: "z-...",
        baseUrl: "https://open.bigmodel.cn/api/paas/v4"
      }
    }
  }
}
```

#### Moonshot (Kimi)

```json5
{
  agents: {
    defaults: { model: { primary: "moonshot/moonshot-v1-8k" } }
  },
  models: {
    providers: {
      moonshot: {
        baseUrl: "https://api.moonshot.cn/v1",
        apiKey: "sk-...",
        api: "openai",
        models: ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]
      }
    }
  }
}
```

#### Synthetic (Testing)

```json5
{
  models: {
    providers: {
      synthetic: {
        api: "synthetic",
        models: ["event-stream", "text-stream", "static"]
      }
    }
  }
}
```

#### Local Models (Ollama / vLLM / LM Studio)

指向任何相容 OpenAI 的 Local Server：

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://localhost:11434/v1",
        apiKey: "ollama",
        api: "openai",
        models: ["llama3:latest", "mistral:latest"]
      },
      lmstudio: {
        baseUrl: "http://localhost:1234/v1",
        apiKey: "lm-studio",
        api: "openai",
        models: ["local-model"]
      }
    }
  }
}
```

#### MiniMax

MiniMax (abab6.5 等) 內建 (provider `minimax`)，但您也可以覆蓋它：

```json5
{
  models: {
    providers: {
      minimax: {
        baseUrl: "https://api.minimax.chat/v1",
        apiKey: "sk-...",
        groupId: "123456" // Optional; legacy API requirement
      }
    }
  }
}
```

#### Cerebras (Fast Inference)

```json5
{
  models: {
    providers: {
      cerebras: {
        baseUrl: "https://api.cerebras.ai/v1",
        apiKey: "sk-...",
        api: "openai",
        models: ["llama3.1-70b"]
      }
    }
  }
}
```

#### Groq (Fast Inference)

```json5
{
  models: {
    providers: {
      groq: {
        apiKey: "gsk_...",
        api: "openai", // Groq uses OpenAI-compatible API
        baseUrl: "https://api.groq.com/openai/v1"
      }
    }
  }
}
```

#### Azure OpenAI

```json5
{
  models: {
    providers: {
      azure: {
        api: "openai",
        baseUrl: "https://YOUR_RESOURCE_NAME.openai.azure.com",
        apiKey: "YOUR_API_KEY",
        apiVersion: "2024-02-15-preview",
        deployment: "gpt-4-turbo" 
      }
    }
  }
}
```

#### Cloudflare Workers AI

```json5
{
  models: {
    providers: {
      cloudflare: {
        api: "openai",
        baseUrl: "https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/v1",
        apiKey: "YOUR_WORKERS_AI_TOKEN",
        models: ["@cf/meta/llama-3-8b-instruct"]
      }
    }
  }
}
```

### `session`

控制 Session 生命週期與 persistence:
- `contextLimit`: 載入到記憶體的最大 Turns 數 (sliding window)。預設 40 (約 25k tokens + system prompt)。
- `autoCreate`: 當 Session ID 未知時自動建立新 Session (預設: `true`)。
- `idleTimeout`: Non-main Sessions 在記憶體中保留多久 (ms)。預設 30 分鐘 (`1800000`)。
- `persistence`: Session 儲存位置。預設 `~/.openclaw/sessions`。
- `gc`: Garbage Collection 設定。
  - `enabled`: default true
  - `intervalSeconds`: default 3600 (1 hour)
  - `inactiveHours`: default 72 (3 days) — Sessions older than this (last active) are archived to `persistence/archive`.

```json5
{
  session: {
    contextLimit: 60,
    idleTimeout: 3600000,
    persistence: "~/.openclaw/sessions",
    gc: {
      enabled: true,
      inactiveHours: 48
    }
  }
}
```

### `skills`

設定額外的 Skill Pack 路徑。
Skills 自動從 Agent Workspace 的 `skills/` 和 `~/.openclaw/skills/` 載入。

```json5
{
  skills: {
    path: ["~/my-skills", "/opt/shared/skills"],
    refreshInterval: 60000 // hot reload interval (ms)
  }
}
```

### `plugins`

啟用/停用 Plugin Loading。OpenClaw 從 `~/.openclaw/extensions` (source) 和 `node_modules` (npm packages) 載入 Plugins。
Allowlist 嚴格限制載入的 Plugins。

```json5
{
  plugins: {
    enabled: true,
    allow: ["@openclaw/plugin-search", "my-local-plugin"]
  }
}
```

### `browser` (legacy global config)

**Deprecated.** 請使用 `agents.defaults.sandbox.browser` (Sandboxed Browser) 或 `tools.browser` (Host Browser Policy)。
這裡僅用於歷史參考：

```json5
{
  browser: {
    enabled: false,           // Global toggle
    headless: false,          // Show UI
    timeout: 30000,
    viewport: { width: 1280, height: 800 }
  }
}
```

### `ui` (Web interface for humans)

OpenClaw Control UI (aka `a2ui`) 服務於 Gateway Port（預設 `18789`）。
您可以將其綁定到不同的 Interface 或 Port。

```json5
{
  ui: {
    enabled: true,
    host: "0.0.0.0", // Expose to LAN (Be careful with auth!)
    port: 3000,      // Separate port from Gateway RPC
    baseUrl: "/ui",  // Path prefix
    theme: "dark"
  }
}
```

Dashboard 驗證：
- Localhost (Loopback): 無需 Auth (除非 `gateway.auth.token` 強制)。
- Remote (LAN/Tailscale): 需要 `gateway.auth.token` (Bearer Token 或 Cookie)。

使用 `openclaw ui-token` 生成 Login Link。

### `gateway` (Server mode)

Gateway Server 處理 RPC (`gateway.call`)、HTTP Bridges、Webhooks、WebSocket Events 與 Static Assets。

- `port`: default 18789
- `host`: default "127.0.0.1" (Localhost only)。設定 `"0.0.0.0"` 以暴露給網路。
- `auth`: RPC/HTTP Auth。
  - `token`: Shared Secret (Bearer Token)。若設定，所有非 Loopback 請求都受此保護。
- `tls`: HTTPS/WSS 設定。
  - `cert`: Path to certificate (PEM)
  - `key`: Path to private key (PEM)
  - `ca`: Optional CA cert
- `admin`: Admin RPC Access Policy (Defaults to Loopback-only)。
- `ws`: WebSocket Config (Heartbeat, Max Payload)。
- `multiInstance`: 允許在同一 Host 上運行多個 Gateway (預設 false；鎖定 `~/.openclaw/gateway.lock`)。

```json5
{
  gateway: {
    port: 18789,
    host: "0.0.0.0",
    auth: { token: "s3cr3t-t0k3n" },
    tls: {
      cert: "/etc/ssl/certs/openclaw.crt",
      key: "/etc/ssl/private/openclaw.key"
    },
    admin: {
      allowRemote: false // Require SSH Tunnel for Admin RPC (recommended)
    },
    multiInstance: false
  }
}
```

### `hooks`

Lifecycle Hooks 用於自訂行為。
目前支援：`onStartup` (Gateway 啟動後執行一次)。

```json5
{
  hooks: {
    onStartup: [
      "echo 'Gateway Started!' >> /tmp/gateway.log",
      "curl -X POST https://stats.example.com/gateway/start"
    ]
  }
}
```

### `canvasHost` (UI rendering server)

OpenClaw Canvas 用於透過 Live-reloading Web Server 渲染 HTML/JS Artifacts。
預設連接埠：`18793`（選擇以避開 OpenClaw Browser CDP 連接埠 `18792`）。
Server 監聽於 **Gateway Bind Host** (LAN or Tailnet) 以便 Nodes 可以存取它。

Server:
- 服務 `canvasHost.root` 下的檔案
- 注入微型 Live-reload Client 到服務的 HTML 中
- 監看目錄並透過WebSocket Endpoint `/__openclaw__/ws` 廣播 Reloads
- 當目錄為空時自動建立 Starter `index.html`（讓您立即看到內容）
- 也服務 A2UI 於 `/__openclaw__/a2ui/` 並向 Nodes 廣播為 `canvasHostUrl`

Config defaults:
```json5
{
  canvasHost: {
    enabled: true,
    port: 18793,     // Static port (default)
    portRange: null, // Or use range: [19000, 19100]
    host: "0.0.0.0", // Match gateway host
    root: "/tmp/openclaw-canvas", // Auto-created temp dir
    indexParams: { theme: "dark" }
  }
}
```

### `bridge` (legacy HTTP bridge)

公開 HTTP Endpoint `POST /bridge/message` 以將訊息注入 Gateway。
**Deprecated** in favor of `tools-invoke-http-api`.

```json5
{
  bridge: {
    enabled: false,
    port: 18790
  }
}
```

### `discovery` (Bonjour/mDNS)

Gateway 透過 Bonjour (mDNS) 廣播其存在，以便本地 Clients (Dashboard, Mobile App) 能夠發現它。
Service Type: `_openclaw-gateway._tcp`

```json5
{
  discovery: {
    enabled: true,
    name: "My Gateway" // Optional override
  }
}
```

### Template variables (prompts)

您可以定義自訂變數用於 System Prompts 與 Tool Responses。

```json5
{
  templates: {
    vars: {
      user_name: "Jackle",
      project_code: "PHX-99"
    }
  }
}
```

在 Prompts 中使用 `{{user_name}}` 引用它們。

### `cron` (scheduled jobs)

Gateway 內建 Cron 排程器。Jobs 作為可以調用任何 Tool (通常是 `sessions_send`) 的 Agent Tasks 執行。

Timezone: 預設為 Local Time (Host OS)。您可以透過 `cron.timezone` 設定 (e.g. "Asia/Taipei")。

```json5
{
  cron: {
    enabled: true,
    timezone: "Asia/Taipei",
    jobs: [
      {
        name: "Morning Briefing",
        schedule: "0 9 * * 1-5", // Mon-Fri 9:00 AM
        command: "sessions_send",
        args: {
            // Target specific channel/user
            to: "whatsapp:+15555550123", 
            message: "Good morning! Please check the news and summarize key tech headlines."
        }
      },
      {
        name: "Weekend Cleanup",
        schedule: "0 0 * * 0", // Sunday midnight
        command: "exec",
        args: { command: "docker system prune -f" }
      }
    ]
  }
}
```

使用 `openclaw cron list` 查看排程 Jobs 與下一次執行時間。
使用 `openclaw cron run <name>` 立即測試 Job。
使用 `openclaw cron history` 查看執行 Logs。

Job 屬性：
- `name`: Unique ID
- `schedule`: Cron Expression (5 or 6 fields)
- `command`: Tool Name to execute
- `args`: Arguments object for the tool
- `agentId`: Optional Agent ID to execute the task (defaut: "main")
- `timeoutSeconds`: Execution hard limit (default 600)
