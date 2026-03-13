---
summary: "使用 ACP runtime sessions 來執行 Pi、Claude Code、Codex、OpenCode、Gemini CLI 和其他 harness agents"
read_when:
  - 透過 ACP 執行編碼 harnesses
  - 在支援 thread 的頻道上設定 thread 繫結的 ACP sessions
  - 將 Discord 頻道或 Telegram 論壇主題繫結到持久 ACP sessions
  - 對 ACP backend 和 plugin wiring 進行疑難排解
  - 從 chat 執行 /acp 命令
title: "ACP Agents（ACP 代理）"
---

# ACP agents

[Agent Client Protocol (ACP)](https://agentclientprotocol.com/) sessions 讓 OpenClaw 能透過 ACP backend plugin 執行外部編碼 harnesses（例如 Pi、Claude Code、Codex、OpenCode 和 Gemini CLI）。

如果你在 OpenClaw 中以自然語言要求「在 Codex 中執行這個」或「在 thread 中啟動 Claude Code」，OpenClaw 應該將該請求路由到 ACP runtime（而不是原生 sub-agent runtime）。

## 快速運營流程

當你想要實用的 `/acp` 運行手冊時，使用以下方式：

1. 產生 session：
   - `/acp spawn codex --mode persistent --thread auto`
2. 在繫結的 thread 中工作（或明確指定該 session key）。
3. 檢查 runtime 狀態：
   - `/acp status`
4. 視需要調整 runtime 選項：
   - `/acp model <provider/model>`
   - `/acp permissions <profile>`
   - `/acp timeout <seconds>`
5. 在不取代 context 的情況下調整活躍 session：
   - `/acp steer tighten logging and continue`
6. 停止工作：
   - `/acp cancel`（停止目前 turn），或
   - `/acp close`（關閉 session + 移除繫結）

## 給人類的快速開始

自然請求的範例：

- 「在 thread 中啟動持久 Codex session，並保持聚焦。」
- 「以單次 Claude Code ACP session 執行此操作，並總結結果。」
- 「在 thread 中使用 Gemini CLI 執行此任務，然後在同一 thread 中進行後續操作。」

OpenClaw 應該做的是：

1. 選擇 `runtime: "acp"`。
2. 解析請求的 harness 目標（`agentId`，例如 `codex`）。
3. 如果要求 thread 繫結且目前頻道支援它，將 ACP session 繫結到 thread。
4. 將後續 thread 訊息路由到同一個 ACP session，直到取消聚焦／關閉／過期。

## ACP 與 sub-agents

當你想要外部 harness runtime 時使用 ACP。當你想要 OpenClaw 原生委派執行時使用 sub-agents。

| 領域        | ACP session                           | Sub-agent 執行                    |
| ----------- | ------------------------------------- | --------------------------------- |
| Runtime     | ACP backend plugin（例如 acpx）       | OpenClaw 原生 sub-agent runtime   |
| Session key | `agent:<agentId>:acp:<uuid>`          | `agent:<agentId>:subagent:<uuid>` |
| 主要命令    | `/acp ...`                            | `/subagents ...`                  |
| Spawn 工具  | `sessions_spawn` with `runtime:"acp"` | `sessions_spawn`（預設 runtime）  |

另見 [Sub-agents](/zh-Hant/tools/subagents)。

## Thread 繫結的 sessions（通道無關）

當為頻道 adapter 啟用 thread 繫結時，ACP sessions 可以繫結到 threads：

- OpenClaw 將 thread 繫結到目標 ACP session。
- 該 thread 中的後續訊息路由到繫結的 ACP session。
- ACP 輸出傳回同一 thread。
- 取消聚焦／關閉／存檔／閒置逾時或最大年齡過期會移除繫結。

Thread 繫結支援是 adapter 特定的。如果活躍頻道 adapter 不支援 thread 繫結，OpenClaw 會傳回清晰的不支援／無法使用訊息。

Thread 繫結 ACP 的必需功能旗標：

- `acp.enabled=true`
- `acp.dispatch.enabled` 預設為開啟（設定 `false` 暫停 ACP dispatch）
- 頻道 adapter ACP thread 產生旗標已啟用（adapter 特定）
  - Discord: `channels.discord.threadBindings.spawnAcpSessions=true`
  - Telegram: `channels.telegram.threadBindings.spawnAcpSessions=true`

### 支援 thread 的頻道

- 任何公開 session／thread 繫結能力的頻道 adapter。
- 目前的內建支援：
  - Discord threads／channels
  - Telegram topics（群組／超級群組和 DM topics 中的論壇主題）
- Plugin 頻道可以透過相同繫結介面新增支援。

## 通道特定設定

對於非暫時性工作流程，在頂層 `bindings[]` 項目中設定持久 ACP 繫結。

### 繫結模型

- `bindings[].type="acp"` 標記持久 ACP conversation 繫結。
- `bindings[].match` 識別目標 conversation：
  - Discord channel 或 thread: `match.channel="discord"` + `match.peer.id="<channelOrThreadId>"`
  - Telegram 論壇主題: `match.channel="telegram"` + `match.peer.id="<chatId>:topic:<topicId>"`
- `bindings[].agentId` 是擁有的 OpenClaw agent id。
- 選擇性 ACP 覆蓋位於 `bindings[].acp` 下：
  - `mode`（`persistent` 或 `oneshot`）
  - `label`
  - `cwd`
  - `backend`

### 每個 agent 的 runtime 預設值

使用 `agents.list[].runtime` 為每個 agent 定義 ACP 預設值一次：

- `agents.list[].runtime.type="acp"`
- `agents.list[].runtime.acp.agent`（harness id，例如 `codex` 或 `claude`）
- `agents.list[].runtime.acp.backend`
- `agents.list[].runtime.acp.mode`
- `agents.list[].runtime.acp.cwd`

ACP 繫結 sessions 的覆蓋優先級：

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

- OpenClaw 確保在使用前設定的 ACP session 存在。
- 該頻道或主題中的訊息路由到設定的 ACP session。
- 在繫結的 conversations 中，`/new` 和 `/reset` 在原地重設相同的 ACP session key。
- 臨時 runtime 繫結（例如由 thread 聚焦流程建立的）在存在時仍然適用。

## 啟動 ACP sessions（介面）

### 從 `sessions_spawn`

使用 `runtime: "acp"` 從 agent turn 或工具呼叫啟動 ACP session。

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

- `runtime` 預設為 `subagent`，因此明確為 ACP sessions 設定 `runtime: "acp"`。
- 如果省略 `agentId`，OpenClaw 會在設定時使用 `acp.defaultAgent`。
- `mode: "session"` 需要 `thread: true` 來保持持久繫結 conversation。

介面詳細資訊：

- `task`（必需）：傳送給 ACP session 的初始提示。
- `runtime`（ACP 必需）：必須是 `"acp"`。
- `agentId`（選擇性）：ACP 目標 harness id。如果設定，回退到 `acp.defaultAgent`。
- `thread`（選擇性，預設 `false`）：在支援的位置要求 thread 繫結流程。
- `mode`（選擇性）：`run`（單次）或 `session`（持久）。
  - 預設是 `run`
  - 如果 `thread: true` 且 mode 省略，OpenClaw 可能根據 runtime 路徑預設為持久行為
  - `mode: "session"` 需要 `thread: true`
- `cwd`（選擇性）：請求的 runtime 工作目錄（由 backend／runtime 原則驗證）。
- `label`（選擇性）：操作人員面向的標籤，用於 session／banner 文字。
- `resumeSessionId`（選擇性）：恢復現有 ACP session，而不是建立新的。該 agent 透過 `session/load` 重放其對話歷史。需要 `runtime: "acp"`。
- `streamTo`（選擇性）：`"parent"` 將初始 ACP 執行進度摘要串流回請求者 session 作為系統事件。
  - 在可用時，接受的回應包括 `streamLogPath`，指向 session 範圍的 JSONL 日誌（`<sessionId>.acp-stream.jsonl`），你可以跟蹤完整中繼歷史。

### 恢復現有 session

使用 `resumeSessionId` 繼續先前的 ACP session，而不是重新開始。該 agent 透過 `session/load` 重放其對話歷史，因此它會以之前內容的完整 context 繼續。

```json
{
  "task": "Continue where we left off — fix the remaining test failures",
  "runtime": "acp",
  "agentId": "codex",
  "resumeSessionId": "<previous-session-id>"
}
```

常見用途：

- 將 Codex session 從你的筆記本電腦遞交到手機 — 告訴你的 agent 從之前的位置繼續
- 繼續你在 CLI 中互動式啟動的編碼 session，現在透過你的 agent 無頭執行
- 拿起被 gateway 重啟或閒置逾時中斷的工作

注意：

- `resumeSessionId` 需要 `runtime: "acp"` — 如果與 sub-agent runtime 搭配使用會傳回錯誤。
- `resumeSessionId` 恢復上游 ACP conversation 歷史；`thread` 和 `mode` 仍然正常適用於你正在建立的新 OpenClaw session，所以 `mode: "session"` 仍然需要 `thread: true`。
- 目標 agent 必須支援 `session/load`（Codex 和 Claude Code 都支援）。
- 如果找不到 session ID，spawn 會失敗並顯示清晰的錯誤 — 不會默默回退到新 session。

### 運營煙霧測試

在 gateway 部署後，當你想要快速現場檢查 ACP spawn 確實在運作端到端（而不僅僅通過單元測試）時，使用這個。

推薦閘門：

1. 驗證目標主機上的已部署 gateway 版本／commit。
2. 確認已部署的源程式碼包括 ACP 血統接受在 `src/gateway/sessions-patch.ts`（`subagent:*` 或 `acp:*` sessions）。
3. 開啟臨時 ACPX 橋接 session 到即時 agent（例如 `jpclawhq` 上的 `razor(main)`）。
4. 要求該 agent 使用以下方式呼叫 `sessions_spawn`：
   - `runtime: "acp"`
   - `agentId: "codex"`
   - `mode: "run"`
   - task: `Reply with exactly LIVE-ACP-SPAWN-OK`
5. 驗證 agent 報告：
   - `accepted=yes`
   - 一個真實的 `childSessionKey`
   - 無驗證器錯誤
6. 清理臨時 ACPX 橋接 session。

範例提示給即時 agent：

```text
Use the sessions_spawn tool now with runtime: "acp", agentId: "codex", and mode: "run".
Set the task to: "Reply with exactly LIVE-ACP-SPAWN-OK".
Then report only: accepted=<yes/no>; childSessionKey=<value or none>; error=<exact text or none>.
```

注意：

- 除非你有意測試 thread 繫結持久 ACP sessions，否則在 `mode: "run"` 上保持此煙霧測試。
- 不要為基本閘門要求 `streamTo: "parent"`。該路徑取決於請求者／session 能力，是一個單獨的整合檢查。
- 將 thread 繫結 `mode: "session"` 測試作為第二個、更豐富的整合通過，來自真實 Discord thread 或 Telegram topic。

## Sandbox 相容性

ACP sessions 目前在主機 runtime 上執行，而不是在 OpenClaw sandbox 內。

目前的限制：

- 如果請求者 session 已沙箱化，ACP spawns 會被阻止，無論是針對 `sessions_spawn({ runtime: "acp" })` 還是 `/acp spawn`。
  - 錯誤：`Sandboxed sessions cannot spawn ACP sessions because runtime="acp" runs on the host. Use runtime="subagent" from sandboxed sessions.`
- 具有 `runtime: "acp"` 的 `sessions_spawn` 不支援 `sandbox: "require"`。
  - 錯誤：`sessions_spawn sandbox="require" is unsupported for runtime="acp" because ACP sessions run outside the sandbox. Use runtime="subagent" or sandbox="inherit".`

當你需要 sandbox 強制執行時使用 `runtime: "subagent"`。

### 從 `/acp` 命令

當需要時，使用 `/acp spawn` 來從 chat 進行明確的運營人員控制。

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

大多數 `/acp` 動作接受選擇性 session 目標（`session-key`、`session-id` 或 `session-label`）。

解析順序：

1. 明確目標引數（或 `/acp steer` 的 `--session`）
   - 嘗試 key
   - 然後是 UUID 形狀的 session id
   - 然後是 label
2. 目前的 thread 繫結（如果此 conversation／thread 繫結到 ACP session）
3. 目前的請求者 session 回退

如果沒有目標解析，OpenClaw 傳回清晰的錯誤（`Unable to resolve session target: ...`）。

## Spawn thread 模式

`/acp spawn` 支援 `--thread auto|here|off`。

| 模式   | 行為                                                                         |
| ------ | ---------------------------------------------------------------------------- |
| `auto` | 在活躍 thread 中：繫結該 thread。在 thread 外：在支援時建立／繫結子 thread。 |
| `here` | 需要目前活躍 thread；如果不在一個中會失敗。                                  |
| `off`  | 無繫結。Session 啟動時不繫結。                                               |

注意：

- 在非 thread 繫結表面上，預設行為有效地是 `off`。
- Thread 繫結 spawn 需要頻道原則支援：
  - Discord: `channels.discord.threadBindings.spawnAcpSessions=true`
  - Telegram: `channels.telegram.threadBindings.spawnAcpSessions=true`

## ACP 控制

可用命令家族：

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

`/acp status` 顯示有效的 runtime 選項，以及在可用時，runtime 級和 backend 級的 session 識別碼。

某些控制取決於 backend 能力。如果 backend 不支援控制，OpenClaw 傳回清晰的不支援控制錯誤。

## ACP 命令手冊

| 命令                 | 它做什麼                                        | 範例                                                           |
| -------------------- | ----------------------------------------------- | -------------------------------------------------------------- |
| `/acp spawn`         | 建立 ACP session；選擇性 thread 繫結。          | `/acp spawn codex --mode persistent --thread auto --cwd /repo` |
| `/acp cancel`        | 為目標 session 取消進行中的 turn。              | `/acp cancel agent:codex:acp:<uuid>`                           |
| `/acp steer`         | 傳送方向指示到執行中的 session。                | `/acp steer --session support inbox prioritize failing tests`  |
| `/acp close`         | 關閉 session 並取消繫結 thread 目標。           | `/acp close`                                                   |
| `/acp status`        | 顯示 backend、mode、state、runtime 選項、能力。 | `/acp status`                                                  |
| `/acp set-mode`      | 為目標 session 設定 runtime mode。              | `/acp set-mode plan`                                           |
| `/acp set`           | 通用 runtime config 選項寫入。                  | `/acp set model openai/gpt-5.2`                                |
| `/acp cwd`           | 設定 runtime 工作目錄覆蓋。                     | `/acp cwd /Users/user/Projects/repo`                           |
| `/acp permissions`   | 設定核准原則設定檔。                            | `/acp permissions strict`                                      |
| `/acp timeout`       | 設定 runtime 逾時（秒）。                       | `/acp timeout 120`                                             |
| `/acp model`         | 設定 runtime 模型覆蓋。                         | `/acp model anthropic/claude-opus-4-5`                         |
| `/acp reset-options` | 移除 session runtime 選項覆蓋。                 | `/acp reset-options`                                           |
| `/acp sessions`      | 從儲存列出最近的 ACP sessions。                 | `/acp sessions`                                                |
| `/acp doctor`        | Backend 健康、能力、可行的修復。                | `/acp doctor`                                                  |
| `/acp install`       | 列印確定性安裝和啟用步驟。                      | `/acp install`                                                 |

`/acp sessions` 讀取目前繫結或請求者 session 的儲存。接受 `session-key`、`session-id` 或 `session-label` tokens 的命令透過 gateway session 發現解析目標，包括自訂每 agent `session.store` 根目錄。

## Runtime 選項對映

`/acp` 有便利命令和通用 setter。

對等操作：

- `/acp model <id>` 對映到 runtime config key `model`。
- `/acp permissions <profile>` 對映到 runtime config key `approval_policy`。
- `/acp timeout <seconds>` 對映到 runtime config key `timeout`。
- `/acp cwd <path>` 直接更新 runtime cwd 覆蓋。
- `/acp set <key> <value>` 是通用路徑。
  - 特殊情況：`key=cwd` 使用 cwd 覆蓋路徑。
- `/acp reset-options` 清除目標 session 的所有 runtime 覆蓋。

## acpx harness 支援（目前）

目前 acpx 內建 harness 別名：

- `pi`
- `claude`
- `codex`
- `opencode`
- `gemini`
- `kimi`

當 OpenClaw 使用 acpx backend 時，除非你的 acpx config 定義自訂 agent 別名，否則為 `agentId` 偏好這些值。

直接 acpx CLI 使用也可以透過 `--agent <command>` 針對任意 adapters，但該原始逃逸舱口是 acpx CLI 功能（不是正常的 OpenClaw `agentId` 路徑）。

## 必需配置

核心 ACP 基線：

```json5
{
  acp: {
    enabled: true,
    // 選擇性。預設為 true；設定 false 暫停 ACP dispatch 同時保持 /acp 控制。
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

Thread 繫結配置是頻道 adapter 特定的。Discord 範例：

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

如果 thread 繫結 ACP spawn 無法運作，請先驗證 adapter 功能旗標：

- Discord: `channels.discord.threadBindings.spawnAcpSessions=true`

見 [Configuration Reference](/zh-Hant/gateway/configuration-reference)。

## acpx backend 的 Plugin 設定

安裝並啟用 plugin：

```bash
openclaw plugins install acpx
openclaw config set plugins.entries.acpx.enabled true
```

開發期間的本機工作區安裝：

```bash
openclaw plugins install ./extensions/acpx
```

然後驗證 backend 健康：

```text
/acp doctor
```

### acpx 命令和版本配置

預設情況下，acpx plugin（發佈為 `@openclaw/acpx`）使用 plugin 本機固定的二進位檔：

1. 命令預設為 `extensions/acpx/node_modules/.bin/acpx`。
2. 預期版本預設為擴充功能 pin。
3. 啟動將 ACP backend 立即註冊為尚未就緒。
4. 背景確保任務驗證 `acpx --version`。
5. 如果 plugin 本機二進位遺漏或不匹配，它會執行：
   `npm install --omit=dev --no-save acpx@<pinned>` 並重新驗證。

你可以在 plugin 配置中覆蓋命令／版本：

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
- `expectedVersion: "any"` 禁用嚴格版本比對。
- 當 `command` 指向自訂二進位／路徑時，plugin 本機自動安裝會被禁用。
- OpenClaw 啟動在 backend 健康檢查執行期間保持非阻止。

見 [Plugins](/zh-Hant/tools/plugin)。

## 許可權配置

ACP sessions 以非互動方式執行 — 沒有 TTY 來核准或拒絕檔案寫入和 shell exec 許可權提示。acpx plugin 提供兩個控制許可權如何處理的配置鍵：

### `permissionMode`

控制 harness agent 可以在不提示情況下執行的操作。

| 值              | 行為                                   |
| --------------- | -------------------------------------- |
| `approve-all`   | 自動核准所有檔案寫入和 shell 命令。    |
| `approve-reads` | 僅自動核准讀取；寫入和 exec 需要提示。 |
| `deny-all`      | 拒絕所有許可權提示。                   |

### `nonInteractivePermissions`

控制當許可權提示將被顯示但沒有互動 TTY 可用時會發生什麼（ACP sessions 總是如此）。

| 值     | 行為                                            |
| ------ | ----------------------------------------------- |
| `fail` | 中止 session with `AcpRuntimeError`。**(預設)** |
| `deny` | 默默拒絕許可權並繼續（優雅降級）。              |

### 配置

透過 plugin 配置設定：

```bash
openclaw config set plugins.entries.acpx.config.permissionMode approve-all
openclaw config set plugins.entries.acpx.config.nonInteractivePermissions fail
```

變更這些值後重啟 gateway。

> **重要：** OpenClaw 目前預設為 `permissionMode=approve-reads` 和 `nonInteractivePermissions=fail`。在非互動 ACP sessions 中，任何觸發許可權提示的寫入或 exec 都可能失敗，並出現 `AcpRuntimeError: Permission prompt unavailable in non-interactive mode`。
>
> 如果需要限制許可權，設定 `nonInteractivePermissions` 為 `deny`，以便 sessions 優雅地降級，而不是崩潰。

## 疑難排解

| 症狀                                                                     | 可能原因                                                          | 修復                                                                                                                                              |
| ------------------------------------------------------------------------ | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ACP runtime backend is not configured`                                  | Backend plugin 遺漏或已停用。                                     | 安裝並啟用 backend plugin，然後執行 `/acp doctor`。                                                                                               |
| `ACP is disabled by policy (acp.enabled=false)`                          | ACP 全域停用。                                                    | 設定 `acp.enabled=true`。                                                                                                                         |
| `ACP dispatch is disabled by policy (acp.dispatch.enabled=false)`        | 從正常 thread 訊息的 dispatch 已停用。                            | 設定 `acp.dispatch.enabled=true`。                                                                                                                |
| `ACP agent "<id>" is not allowed by policy`                              | Agent 不在允許列表中。                                            | 使用允許的 `agentId` 或更新 `acp.allowedAgents`。                                                                                                 |
| `Unable to resolve session target: ...`                                  | 差的 key／id／label token。                                       | 執行 `/acp sessions`，複製確切的 key／label，重試。                                                                                               |
| `--thread here requires running /acp spawn inside an active ... thread`  | 在 thread 上下文外使用 `--thread here`。                          | 移到目標 thread 或使用 `--thread auto`／`off`。                                                                                                   |
| `Only <user-id> can rebind this thread.`                                 | 另一個使用者擁有 thread 繫結。                                    | 作為擁有者重新繫結或使用不同的 thread。                                                                                                           |
| `Thread bindings are unavailable for <channel>.`                         | Adapter 缺乏 thread 繫結能力。                                    | 使用 `--thread off` 或移到支援的 adapter／channel。                                                                                               |
| `Sandboxed sessions cannot spawn ACP sessions ...`                       | ACP runtime 是主機側；請求者 session 已沙箱化。                   | 從沙箱化 sessions 使用 `runtime="subagent"`，或從非沙箱化 session 執行 ACP spawn。                                                                |
| `sessions_spawn sandbox="require" is unsupported for runtime="acp" ...`  | 為 ACP runtime 請求 `sandbox="require"`。                         | 對於必需的沙箱化使用 `runtime="subagent"`，或使用 ACP with `sandbox="inherit"`（來自非沙箱化 session）。                                          |
| 繫結 session 遺漏 ACP 元資料                                             | 舊的／已刪除的 ACP session 元資料。                               | 使用 `/acp spawn` 重新建立，然後重新繫結／聚焦 thread。                                                                                           |
| `AcpRuntimeError: Permission prompt unavailable in non-interactive mode` | `permissionMode` 在非互動 ACP session 中阻止寫入／exec。          | 設定 `plugins.entries.acpx.config.permissionMode` 為 `approve-all` 並重啟 gateway。見 [Permission configuration](#permission-configuration)。     |
| ACP session 早期失敗，輸出很少                                           | 許可權提示被 `permissionMode`／`nonInteractivePermissions` 阻止。 | 檢查 gateway 日誌中的 `AcpRuntimeError`。如需完整許可權，設定 `permissionMode=approve-all`；如需優雅降級，設定 `nonInteractivePermissions=deny`。 |
| ACP session 在完成工作後無限期停滯                                       | Harness 進程已完成，但 ACP session 未報告完成。                   | 使用 `ps aux \| grep acpx` 監視；手動殺死舊進程。                                                                                                 |
