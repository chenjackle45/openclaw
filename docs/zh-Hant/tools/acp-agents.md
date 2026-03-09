---
summary: "為 Pi、Claude Code、Codex、OpenCode、Gemini CLI 及其他 harness agent 使用 ACP runtime sessions"
read_when:
  - 透過 ACP 執行 coding harness
  - 在支援 thread 的 channel 上設定 thread-bound ACP sessions
  - 將 Discord channel 或 Telegram forum topic 綁定至持久 ACP sessions
  - 排除 ACP backend 和 plugin 接線問題
  - 從聊天室操作 /acp 命令
title: "ACP Agents（ACP 代理）"
---

# ACP agents

[Agent Client Protocol (ACP)](https://agentclientprotocol.com/) sessions 讓 OpenClaw 能透過 ACP backend plugin 執行外部 coding harness（例如 Pi、Claude Code、Codex、OpenCode 和 Gemini CLI）。

如果你用自然語言要求 OpenClaw「在 Codex 中執行這個」或「在 thread 中啟動 Claude Code」，OpenClaw 應將該請求路由至 ACP runtime（而非原生 sub-agent runtime）。

## 快速操作流程

當你需要實用的 `/acp` 操作手冊時使用：

1. 建立 session：
   - `/acp spawn codex --mode persistent --thread auto`
2. 在綁定的 thread 中工作（或明確指定該 session key）。
3. 檢查 runtime 狀態：
   - `/acp status`
4. 視需要調整 runtime 選項：
   - `/acp model <provider/model>`
   - `/acp permissions <profile>`
   - `/acp timeout <seconds>`
5. 在不替換 context 的情況下引導活躍 session：
   - `/acp steer tighten logging and continue`
6. 停止工作：
   - `/acp cancel`（停止當前 turn），或
   - `/acp close`（關閉 session 並移除綁定）

## 人類快速上手

自然語言請求範例：

- 「在此建立一個持久 Codex session 並保持專注。」
- 「將此作為一次性 Claude Code ACP session 執行並摘要結果。」
- 「在 thread 中使用 Gemini CLI 處理此任務，並在同一 thread 中繼續後續工作。」

OpenClaw 應執行的動作：

1. 選擇 `runtime: "acp"`。
2. 解析請求的 harness 目標（`agentId`，例如 `codex`）。
3. 若請求 thread 綁定且當前 channel 支援，將 ACP session 綁定至 thread。
4. 將後續 thread 訊息路由至同一 ACP session，直到取消焦點/關閉/過期。

## ACP 與 sub-agent 的比較

當你需要外部 harness runtime 時使用 ACP；當你需要 OpenClaw 原生委派執行時使用 sub-agent。

| 面向        | ACP session                         | Sub-agent run                     |
| ----------- | ----------------------------------- | --------------------------------- |
| Runtime     | ACP backend plugin（例如 acpx）     | OpenClaw 原生 sub-agent runtime   |
| Session key | `agent:<agentId>:acp:<uuid>`        | `agent:<agentId>:subagent:<uuid>` |
| 主要命令    | `/acp ...`                          | `/subagents ...`                  |
| Spawn 工具  | `sessions_spawn` 加 `runtime:"acp"` | `sessions_spawn`（預設 runtime）  |

另見 [Sub-agents](/zh-Hant/tools/subagents)。

## Thread-bound sessions（channel 通用）

當 channel adapter 啟用 thread bindings 時，ACP sessions 可以綁定至 threads：

- OpenClaw 將 thread 綁定至目標 ACP session。
- 該 thread 中的後續訊息會路由至已綁定的 ACP session。
- ACP 輸出傳遞回同一 thread。
- 取消焦點/關閉/封存/閒置逾時或最大存活時間到期時，移除綁定。

Thread binding 支援因 adapter 而異。若當前 channel adapter 不支援 thread bindings，OpenClaw 會回傳明確的不支援/不可用訊息。

Thread-bound ACP 所需的功能旗標：

- `acp.enabled=true`
- `acp.dispatch.enabled` 預設為啟用（設為 `false` 可暫停 ACP dispatch）
- Channel-adapter ACP thread-spawn 旗標已啟用（因 adapter 而異）
  - Discord：`channels.discord.threadBindings.spawnAcpSessions=true`
  - Telegram：`channels.telegram.threadBindings.spawnAcpSessions=true`

### 支援 thread 的 channel

- 任何公開 session/thread binding 能力的 channel adapter。
- 目前內建支援：
  - Discord threads/channels
  - Telegram topics（群組/超級群組中的 forum topics 以及 DM topics）
- Plugin channels 可透過相同的 binding 介面新增支援。

## Channel 特定設定

對於非暫時性工作流程，在頂層 `bindings[]` 項目中設定持久 ACP bindings。

### Binding 模型

- `bindings[].type="acp"` 標記持久 ACP 對話 binding。
- `bindings[].match` 識別目標對話：
  - Discord channel 或 thread：`match.channel="discord"` + `match.peer.id="<channelOrThreadId>"`
  - Telegram forum topic：`match.channel="telegram"` + `match.peer.id="<chatId>:topic:<topicId>"`
- `bindings[].agentId` 是擁有者 OpenClaw agent id。
- 選用 ACP 覆寫設定位於 `bindings[].acp` 下：
  - `mode`（`persistent` 或 `oneshot`）
  - `label`
  - `cwd`
  - `backend`

### 每個 agent 的 runtime 預設值

使用 `agents.list[].runtime` 為每個 agent 定義一次 ACP 預設值：

- `agents.list[].runtime.type="acp"`
- `agents.list[].runtime.acp.agent`（harness id，例如 `codex` 或 `claude`）
- `agents.list[].runtime.acp.backend`
- `agents.list[].runtime.acp.mode`
- `agents.list[].runtime.acp.cwd`

ACP 綁定 sessions 的覆寫優先順序：

1. `bindings[].acp.*`
2. `agents.list[].runtime.acp.*`
3. 全域 ACP 預設值（例如 `acp.backend`）

範例：

```json5
{
  agents: {
    list: [
      {
        id: "codex",
        runtime: {
          type: "acp",
          acp: {
            agent: "codex",
            backend: "acpx",
            mode: "persistent",
            cwd: "/workspace/openclaw",
          },
        },
      },
      {
        id: "claude",
        runtime: {
          type: "acp",
          acp: { agent: "claude", backend: "acpx", mode: "persistent" },
        },
      },
    ],
  },
  bindings: [
    {
      type: "acp",
      agentId: "codex",
      match: {
        channel: "discord",
        accountId: "default",
        peer: { kind: "channel", id: "222222222222222222" },
      },
      acp: { label: "codex-main" },
    },
    {
      type: "acp",
      agentId: "claude",
      match: {
        channel: "telegram",
        accountId: "default",
        peer: { kind: "group", id: "-1001234567890:topic:42" },
      },
      acp: { cwd: "/workspace/repo-b" },
    },
    {
      type: "route",
      agentId: "main",
      match: { channel: "discord", accountId: "default" },
    },
    {
      type: "route",
      agentId: "main",
      match: { channel: "telegram", accountId: "default" },
    },
  ],
  channels: {
    discord: {
      guilds: {
        "111111111111111111": {
          channels: {
            "222222222222222222": { requireMention: false },
          },
        },
      },
    },
    telegram: {
      groups: {
        "-1001234567890": {
          topics: { "42": { requireMention: false } },
        },
      },
    },
  },
}
```

行為：

- OpenClaw 確保在使用前已設定的 ACP session 存在。
- 該 channel 或 topic 中的訊息會路由至已設定的 ACP session。
- 在已綁定的對話中，`/new` 和 `/reset` 會就地重設同一個 ACP session key。
- 暫時性 runtime bindings（例如由 thread-focus 流程建立的）在存在時仍會套用。

## 啟動 ACP sessions（介面）

### 從 `sessions_spawn`

在 agent turn 或工具呼叫中使用 `runtime: "acp"` 啟動 ACP session。

```json
{
  "task": "Open the repo and summarize failing tests",
  "runtime": "acp",
  "agentId": "codex",
  "thread": true,
  "mode": "session"
}
```

注意：

- `runtime` 預設為 `subagent`，因此 ACP sessions 需明確設定 `runtime: "acp"`。
- 若省略 `agentId`，OpenClaw 會在已設定的情況下使用 `acp.defaultAgent`。
- `mode: "session"` 需要 `thread: true` 才能維持持久綁定對話。

介面詳情：

- `task`（必填）：傳送至 ACP session 的初始提示。
- `runtime`（ACP 必填）：必須為 `"acp"`。
- `agentId`（選填）：ACP 目標 harness id。若已設定，則回退至 `acp.defaultAgent`。
- `thread`（選填，預設 `false`）：在支援的情況下請求 thread binding 流程。
- `mode`（選填）：`run`（一次性）或 `session`（持久）。
  - 預設為 `run`
  - 若 `thread: true` 且省略 mode，OpenClaw 可能根據 runtime 路徑預設為持久行為
  - `mode: "session"` 需要 `thread: true`
- `cwd`（選填）：請求的 runtime 工作目錄（由 backend/runtime 政策驗證）。
- `label`（選填）：用於 session/banner 文字的操作者標籤。
- `streamTo`（選填）：`"parent"` 將初始 ACP run 進度摘要作為 system events 串流回請求者 session。
  - 若可用，接受的回應包含指向 session 範疇 JSONL 日誌（`<sessionId>.acp-stream.jsonl`）的 `streamLogPath`，可供追蹤完整 relay 歷史。

## Sandbox 相容性

ACP sessions 目前在 host runtime 執行，而非在 OpenClaw sandbox 內執行。

目前限制：

- 若請求者 session 已沙箱化，`sessions_spawn({ runtime: "acp" })` 和 `/acp spawn` 的 ACP spawns 均會被封鎖。
  - 錯誤：`Sandboxed sessions cannot spawn ACP sessions because runtime="acp" runs on the host. Use runtime="subagent" from sandboxed sessions.`
- `sessions_spawn` 加 `runtime: "acp"` 不支援 `sandbox: "require"`。
  - 錯誤：`sessions_spawn sandbox="require" is unsupported for runtime="acp" because ACP sessions run outside the sandbox. Use runtime="subagent" or sandbox="inherit".`

當需要強制 sandbox 執行時，使用 `runtime: "subagent"`。

### 從 `/acp` 命令

需要時，使用 `/acp spawn` 從聊天室進行明確的操作者控制。

```text
/acp spawn codex --mode persistent --thread auto
/acp spawn codex --mode oneshot --thread off
/acp spawn codex --thread here
```

主要旗標：

- `--mode persistent|oneshot`
- `--thread auto|here|off`
- `--cwd <absolute-path>`
- `--label <name>`

見 [Slash Commands](/zh-Hant/tools/slash-commands)。

## Session 目標解析

大多數 `/acp` 動作接受選用的 session 目標（`session-key`、`session-id` 或 `session-label`）。

解析順序：

1. 明確目標引數（或 `/acp steer` 的 `--session`）
   - 嘗試 key
   - 然後 UUID 形式的 session id
   - 然後 label
2. 當前 thread binding（若此對話/thread 已綁定至 ACP session）
3. 當前請求者 session 回退

若無法解析目標，OpenClaw 回傳明確錯誤（`Unable to resolve session target: ...`）。

## Spawn thread 模式

`/acp spawn` 支援 `--thread auto|here|off`。

| 模式   | 行為                                                                        |
| ------ | --------------------------------------------------------------------------- |
| `auto` | 在活躍 thread 中：綁定該 thread。在 thread 外：在支援時建立/綁定子 thread。 |
| `here` | 需要當前活躍 thread；若不在 thread 中則失敗。                               |
| `off`  | 不綁定。Session 以未綁定狀態啟動。                                          |

注意：

- 在非 thread binding 介面上，預設行為實際上為 `off`。
- Thread-bound spawn 需要 channel 政策支援：
  - Discord：`channels.discord.threadBindings.spawnAcpSessions=true`
  - Telegram：`channels.telegram.threadBindings.spawnAcpSessions=true`

## ACP 控制項

可用命令系列：

- `/acp spawn`
- `/acp cancel`
- `/acp steer`
- `/acp close`
- `/acp status`
- `/acp set-mode`
- `/acp set`
- `/acp cwd`
- `/acp permissions`
- `/acp timeout`
- `/acp model`
- `/acp reset-options`
- `/acp sessions`
- `/acp doctor`
- `/acp install`

`/acp status` 顯示有效的 runtime 選項，以及在可用時的 runtime 層級和 backend 層級 session 識別碼。

某些控制項依賴 backend 能力。若 backend 不支援某控制項，OpenClaw 回傳明確的不支援控制項錯誤。

## ACP 命令食譜

| 命令                 | 功能                                           | 範例                                                           |
| -------------------- | ---------------------------------------------- | -------------------------------------------------------------- |
| `/acp spawn`         | 建立 ACP session；選用 thread 綁定。           | `/acp spawn codex --mode persistent --thread auto --cwd /repo` |
| `/acp cancel`        | 取消目標 session 的進行中 turn。               | `/acp cancel agent:codex:acp:<uuid>`                           |
| `/acp steer`         | 向執行中 session 傳送引導指令。                | `/acp steer --session support inbox prioritize failing tests`  |
| `/acp close`         | 關閉 session 並解除 thread 目標綁定。          | `/acp close`                                                   |
| `/acp status`        | 顯示 backend、模式、狀態、runtime 選項、能力。 | `/acp status`                                                  |
| `/acp set-mode`      | 設定目標 session 的 runtime 模式。             | `/acp set-mode plan`                                           |
| `/acp set`           | 通用 runtime 設定選項寫入。                    | `/acp set model openai/gpt-5.2`                                |
| `/acp cwd`           | 設定 runtime 工作目錄覆寫。                    | `/acp cwd /Users/user/Projects/repo`                           |
| `/acp permissions`   | 設定審批政策 profile。                         | `/acp permissions strict`                                      |
| `/acp timeout`       | 設定 runtime 逾時（秒）。                      | `/acp timeout 120`                                             |
| `/acp model`         | 設定 runtime 模型覆寫。                        | `/acp model anthropic/claude-opus-4-5`                         |
| `/acp reset-options` | 移除 session runtime 選項覆寫。                | `/acp reset-options`                                           |
| `/acp sessions`      | 列出 store 中的近期 ACP sessions。             | `/acp sessions`                                                |
| `/acp doctor`        | Backend 健康狀況、能力、可行修復。             | `/acp doctor`                                                  |
| `/acp install`       | 列印確定性安裝和啟用步驟。                     | `/acp install`                                                 |

## Runtime 選項對映

`/acp` 有便捷命令和通用 setter。

等效操作：

- `/acp model <id>` 對映至 runtime config key `model`。
- `/acp permissions <profile>` 對映至 runtime config key `approval_policy`。
- `/acp timeout <seconds>` 對映至 runtime config key `timeout`。
- `/acp cwd <path>` 直接更新 runtime cwd 覆寫。
- `/acp set <key> <value>` 是通用路徑。
  - 特殊情況：`key=cwd` 使用 cwd 覆寫路徑。
- `/acp reset-options` 清除目標 session 的所有 runtime 覆寫。

## acpx harness 支援（目前）

目前 acpx 內建 harness 別名：

- `pi`
- `claude`
- `codex`
- `opencode`
- `gemini`
- `kimi`

當 OpenClaw 使用 acpx backend 時，優先使用這些值作為 `agentId`，除非你的 acpx 設定定義了自訂 agent 別名。

直接使用 acpx CLI 也可以透過 `--agent <command>` 指定任意 adapter，但這是 acpx CLI 的原始逃生艙功能（非正常 OpenClaw `agentId` 路徑）。

## 必要設定

核心 ACP 基準：

```json5
{
  acp: {
    enabled: true,
    // 選用。預設為 true；設為 false 可在保留 /acp 控制項的情況下暫停 ACP dispatch。
    dispatch: { enabled: true },
    backend: "acpx",
    defaultAgent: "codex",
    allowedAgents: ["pi", "claude", "codex", "opencode", "gemini", "kimi"],
    maxConcurrentSessions: 8,
    stream: {
      coalesceIdleMs: 300,
      maxChunkChars: 1200,
    },
    runtime: {
      ttlMinutes: 120,
    },
  },
}
```

Thread binding 設定因 channel-adapter 而異。以 Discord 為例：

```json5
{
  session: {
    threadBindings: {
      enabled: true,
      idleHours: 24,
      maxAgeHours: 0,
    },
  },
  channels: {
    discord: {
      threadBindings: {
        enabled: true,
        spawnAcpSessions: true,
      },
    },
  },
}
```

若 thread-bound ACP spawn 無法運作，請先驗證 adapter 功能旗標：

- Discord：`channels.discord.threadBindings.spawnAcpSessions=true`

見 [Configuration Reference](/zh-Hant/gateway/configuration-reference)。

## acpx backend 的 Plugin 設定

安裝並啟用 plugin：

```bash
openclaw plugins install acpx
openclaw config set plugins.entries.acpx.enabled true
```

開發期間本地工作區安裝：

```bash
openclaw plugins install ./extensions/acpx
```

然後驗證 backend 健康狀況：

```text
/acp doctor
```

### acpx 命令和版本設定

預設情況下，acpx plugin（以 `@openclaw/acpx` 發布）使用 plugin 本地固定的二進位檔：

1. 命令預設為 `extensions/acpx/node_modules/.bin/acpx`。
2. 預期版本預設為 extension pin。
3. 啟動時立即將 ACP backend 註冊為未就緒狀態。
4. 背景 ensure 工作驗證 `acpx --version`。
5. 若 plugin 本地二進位檔遺失或不符，執行：
   `npm install --omit=dev --no-save acpx@<pinned>` 並重新驗證。

你可以在 plugin 設定中覆寫命令/版本：

```json
{
  "plugins": {
    "entries": {
      "acpx": {
        "enabled": true,
        "config": {
          "command": "../acpx/dist/cli.js",
          "expectedVersion": "any"
        }
      }
    }
  }
}
```

注意：

- `command` 接受絕對路徑、相對路徑或命令名稱（`acpx`）。
- 相對路徑從 OpenClaw 工作區目錄解析。
- `expectedVersion: "any"` 停用嚴格版本比對。
- 當 `command` 指向自訂二進位/路徑時，plugin 本地自動安裝功能停用。
- OpenClaw 啟動在 backend 健康檢查執行時仍為非阻塞。

見 [Plugins](/zh-Hant/tools/plugin)。

## 權限設定

ACP sessions 以非互動方式執行——沒有 TTY 可用於批准或拒絕檔案寫入和 shell 執行權限提示。acpx plugin 提供兩個控制權限處理方式的設定 key：

### `permissionMode`

控制 harness agent 無需提示即可執行哪些操作。

| 值              | 行為                                 |
| --------------- | ------------------------------------ |
| `approve-all`   | 自動批准所有檔案寫入和 shell 命令。  |
| `approve-reads` | 僅自動批准讀取；寫入和執行需要提示。 |
| `deny-all`      | 拒絕所有權限提示。                   |

### `nonInteractivePermissions`

控制當需要顯示權限提示但沒有互動 TTY 時（ACP sessions 始終如此）會發生什麼。

| 值     | 行為                                            |
| ------ | ----------------------------------------------- |
| `fail` | 以 `AcpRuntimeError` 中止 session。**（預設）** |
| `deny` | 靜默拒絕權限並繼續（優雅降級）。                |

### 設定

透過 plugin 設定設定：

```bash
openclaw config set plugins.entries.acpx.config.permissionMode approve-all
openclaw config set plugins.entries.acpx.config.nonInteractivePermissions fail
```

更改這些值後重新啟動 Gateway。

> **重要：** OpenClaw 目前預設為 `permissionMode=approve-reads` 和 `nonInteractivePermissions=fail`。在非互動 ACP sessions 中，任何觸發權限提示的寫入或執行都可能以 `AcpRuntimeError: Permission prompt unavailable in non-interactive mode` 失敗。
>
> 若需要限制權限，將 `nonInteractivePermissions` 設為 `deny`，讓 sessions 優雅降級而非崩潰。

## 疑難排解

| 症狀                                                                     | 可能原因                                                       | 修復方法                                                                                                                         |
| ------------------------------------------------------------------------ | -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `ACP runtime backend is not configured`                                  | Backend plugin 遺失或停用。                                    | 安裝並啟用 backend plugin，然後執行 `/acp doctor`。                                                                              |
| `ACP is disabled by policy (acp.enabled=false)`                          | ACP 全域停用。                                                 | 設定 `acp.enabled=true`。                                                                                                        |
| `ACP dispatch is disabled by policy (acp.dispatch.enabled=false)`        | 來自正常 thread 訊息的 dispatch 已停用。                       | 設定 `acp.dispatch.enabled=true`。                                                                                               |
| `ACP agent "<id>" is not allowed by policy`                              | Agent 不在允許清單中。                                         | 使用允許的 `agentId` 或更新 `acp.allowedAgents`。                                                                                |
| `Unable to resolve session target: ...`                                  | 錯誤的 key/id/label token。                                    | 執行 `/acp sessions`，複製確切的 key/label，重試。                                                                               |
| `--thread here requires running /acp spawn inside an active ... thread`  | `--thread here` 在 thread context 外使用。                     | 移至目標 thread 或使用 `--thread auto`/`off`。                                                                                   |
| `Only <user-id> can rebind this thread.`                                 | 另一位使用者擁有 thread binding。                              | 以擁有者身分重新綁定或使用不同 thread。                                                                                          |
| `Thread bindings are unavailable for <channel>.`                         | Adapter 缺少 thread binding 能力。                             | 使用 `--thread off` 或移至支援的 adapter/channel。                                                                               |
| `Sandboxed sessions cannot spawn ACP sessions ...`                       | ACP runtime 在 host 端；請求者 session 已沙箱化。              | 從沙箱化 sessions 使用 `runtime="subagent"`，或從非沙箱化 session 執行 ACP spawn。                                               |
| `sessions_spawn sandbox="require" is unsupported for runtime="acp" ...`  | ACP runtime 請求 `sandbox="require"`。                         | 對強制沙箱化使用 `runtime="subagent"`，或以非沙箱化 session 使用 ACP 加 `sandbox="inherit"`。                                    |
| Missing ACP metadata for bound session                                   | 過時/已刪除的 ACP session 元資料。                             | 以 `/acp spawn` 重新建立，然後重新綁定/聚焦 thread。                                                                             |
| `AcpRuntimeError: Permission prompt unavailable in non-interactive mode` | `permissionMode` 在非互動 ACP session 中封鎖寫入/執行。        | 將 `plugins.entries.acpx.config.permissionMode` 設為 `approve-all` 並重新啟動 Gateway。見[權限設定](#permission-configuration)。 |
| ACP session 在輸出很少的情況下提早失敗                                   | 權限提示被 `permissionMode`/`nonInteractivePermissions` 封鎖。 | 檢查 Gateway 日誌中的 `AcpRuntimeError`。完整權限設 `permissionMode=approve-all`；優雅降級設 `nonInteractivePermissions=deny`。  |
| ACP session 完成工作後無限期停滯                                         | Harness 程序已完成但 ACP session 未回報完成。                  | 以 `ps aux \| grep acpx` 監控；手動終止殘留程序。                                                                                |
