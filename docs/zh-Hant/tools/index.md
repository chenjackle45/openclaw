---
summary: "OpenClaw 的 agent 工具介面（browser、canvas、nodes、message、cron），取代舊版 `openclaw-*` skills"
read_when:
  - 新增或修改 agent 工具
  - 退役或更改 `openclaw-*` skills
title: "Tools（工具）"
---

# Tools (OpenClaw)

OpenClaw 為 browser、canvas、nodes 和 cron 公開**第一等的 agent 工具**。這些取代了舊的 `openclaw-*` skills：工具有型別定義、不使用 shell，agent 應直接依賴它們。

## 停用工具

你可以透過 `openclaw.json` 中的 `tools.allow` / `tools.deny` 全域允許/拒絕工具（拒絕優先）。這防止不允許的工具被傳送至模型提供商。

```json5
{
  tools: { deny: ["browser"] },
}
```

注意：

- 比對不區分大小寫。
- 支援 `*` 通配符（`"*"` 表示所有工具）。
- 若 `tools.allow` 僅引用未知或未載入的 plugin 工具名稱，OpenClaw 記錄警告並忽略 allowlist，讓核心工具保持可用。

## 工具 profiles（基礎 allowlist）

`tools.profile` 在 `tools.allow`/`tools.deny` 之前設定一個**基礎工具 allowlist**。每個 agent 的覆寫：`agents.list[].tools.profile`。

Profiles：

- `minimal`：僅 `session_status`
- `coding`：`group:fs`、`group:runtime`、`group:sessions`、`group:memory`、`image`
- `messaging`：`group:messaging`、`sessions_list`、`sessions_history`、`sessions_send`、`session_status`
- `full`：無限制（與未設定相同）

範例（預設僅訊息，也允許 Slack + Discord 工具）：

```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"],
  },
}
```

範例（coding profile，但到處拒絕 exec/process）：

```json5
{
  tools: {
    profile: "coding",
    deny: ["group:runtime"],
  },
}
```

範例（全域 coding profile，僅訊息的支援 agent）：

```json5
{
  tools: { profile: "coding" },
  agents: {
    list: [
      {
        id: "support",
        tools: { profile: "messaging", allow: ["slack"] },
      },
    ],
  },
}
```

## 提供商特定的工具政策

使用 `tools.byProvider` **進一步限制**特定提供商（或單一 `provider/model`）的工具，而不更改你的全域預設值。每個 agent 的覆寫：`agents.list[].tools.byProvider`。

這在基礎工具 profile **之後**和 allow/deny 清單**之前**套用，因此只能縮小工具集。提供商 key 接受 `provider`（例如 `google-antigravity`）或 `provider/model`（例如 `openai/gpt-5.2`）。

範例（保留全域 coding profile，但 Google Antigravity 使用最小工具）：

```json5
{
  tools: {
    profile: "coding",
    byProvider: {
      "google-antigravity": { profile: "minimal" },
    },
  },
}
```

範例（不穩定端點的 provider/model 特定 allowlist）：

```json5
{
  tools: {
    allow: ["group:fs", "group:runtime", "sessions_list"],
    byProvider: {
      "openai/gpt-5.2": { allow: ["group:fs", "sessions_list"] },
    },
  },
}
```

範例（單一提供商的 agent 特定覆寫）：

```json5
{
  agents: {
    list: [
      {
        id: "support",
        tools: {
          byProvider: {
            "google-antigravity": { allow: ["message", "sessions_list"] },
          },
        },
      },
    ],
  },
}
```

## 工具群組（速記）

工具政策（全域、agent、sandbox）支援展開為多個工具的 `group:*` 項目。在 `tools.allow` / `tools.deny` 中使用這些。

可用群組：

- `group:runtime`：`exec`、`bash`、`process`
- `group:fs`：`read`、`write`、`edit`、`apply_patch`
- `group:sessions`：`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- `group:memory`：`memory_search`、`memory_get`
- `group:web`：`web_search`、`web_fetch`
- `group:ui`：`browser`、`canvas`
- `group:automation`：`cron`、`gateway`
- `group:messaging`：`message`
- `group:nodes`：`nodes`
- `group:openclaw`：所有內建 OpenClaw 工具（排除提供商 plugins）

範例（僅允許檔案工具 + browser）：

```json5
{
  tools: {
    allow: ["group:fs", "browser"],
  },
}
```

## Plugins + 工具

Plugins 可以在核心集之外註冊**額外工具**（和 CLI 命令）。見 [Plugins](/zh-Hant/tools/plugin) 瞭解安裝 + 設定，見 [Skills](/zh-Hant/tools/skills) 瞭解工具使用指引如何注入提示。某些 plugins 會隨工具一起附帶自己的 skills（例如 voice-call plugin）。

選用的 plugin 工具：

- [Lobster](/zh-Hant/tools/lobster)：帶有可恢復 approvals 的類型化工作流程 runtime（需要 gateway 主機上的 Lobster CLI）。
- [LLM Task](/zh-Hant/tools/llm-task)：用於結構化工作流程輸出的僅 JSON LLM 步驟（選用 schema 驗證）。
- [Diffs](/zh-Hant/tools/diffs)：前後文字或統一 patch 的唯讀 diff 檢視器和 PNG 或 PDF 檔案渲染器。

## 工具清單

### `apply_patch`

跨一個或多個檔案套用結構化 patch。用於多 hunk 編輯。實驗性：透過 `tools.exec.applyPatch.enabled` 啟用（僅限 OpenAI 模型）。`tools.exec.applyPatch.workspaceOnly` 預設為 `true`（工作區內含）。僅在你刻意想讓 `apply_patch` 在工作區目錄外寫入/刪除時設為 `false`。

### `exec`

在工作區中執行 shell 命令。

核心參數：

- `command`（必填）
- `yieldMs`（超時後自動背景執行，預設 10000）
- `background`（立即背景執行）
- `timeout`（秒；若超過則終止程序，預設 1800）
- `elevated`（bool；若提升模式已啟用/允許則在 host 執行；僅在 agent 已沙箱化時改變行為）
- `host`（`sandbox | gateway | node`）
- `security`（`deny | allowlist | full`）
- `ask`（`off | on-miss | always`）
- `node`（`host=node` 的節點 id/名稱）
- 需要真實 TTY？設定 `pty: true`。

注意：

- 背景執行時回傳 `status: "running"` 加 `sessionId`。
- 使用 `process` 輪詢/記錄/寫入/終止/清除背景 sessions。
- 若 `process` 不被允許，`exec` 同步執行並忽略 `yieldMs`/`background`。
- `elevated` 受 `tools.elevated` 加任何 `agents.list[].tools.elevated` 覆寫閘控（兩者都必須允許），是 `host=gateway` + `security=full` 的別名。
- `elevated` 僅在 agent 已沙箱化時改變行為（否則是無操作）。
- `host=node` 可以指定 macOS companion app 或 headless 節點主機（`openclaw node run`）。
- gateway/節點 approvals 和 allowlists：[Exec approvals](/zh-Hant/tools/exec-approvals)。

### `process`

管理背景 exec sessions。

核心動作：

- `list`、`poll`、`log`、`write`、`kill`、`clear`、`remove`

注意：

- `poll` 在完成時回傳新輸出和退出狀態。
- `log` 支援基於行的 `offset`/`limit`（省略 `offset` 以取得最後 N 行）。
- `process` 按 agent 範疇；其他 agent 的 sessions 不可見。

### `loop-detection`（工具呼叫循環護欄）

OpenClaw 追蹤近期的工具呼叫歷史，並在偵測到重複的無進展循環時封鎖或警告。以 `tools.loopDetection.enabled: true` 啟用（預設為 `false`）。

```json5
{
  tools: {
    loopDetection: {
      enabled: true,
      warningThreshold: 10,
      criticalThreshold: 20,
      globalCircuitBreakerThreshold: 30,
      historySize: 30,
      detectors: {
        genericRepeat: true,
        knownPollNoProgress: true,
        pingPong: true,
      },
    },
  },
}
```

- `genericRepeat`：重複的相同工具 + 相同參數呼叫模式。
- `knownPollNoProgress`：重複的類輪詢工具，輸出相同。
- `pingPong`：交替的 `A/B/A/B` 無進展模式。
- 每個 agent 的覆寫：`agents.list[].tools.loopDetection`。

### `web_search`

使用 Perplexity、Brave、Gemini、Grok 或 Kimi 搜尋網路。

核心參數：

- `query`（必填）
- `count`（1–10；預設來自 `tools.web.search.maxResults`）

注意：

- 需要所選提供商的 API key（推薦：`openclaw configure --section web`）。
- 透過 `tools.web.search.enabled` 啟用。
- 回應已快取（預設 15 分鐘）。
- 見 [Web tools](/zh-Hant/tools/web) 瞭解設定。

### `web_fetch`

從 URL 獲取並提取可讀內容（HTML → markdown/text）。

核心參數：

- `url`（必填）
- `extractMode`（`markdown` | `text`）
- `maxChars`（截斷長頁面）

注意：

- 透過 `tools.web.fetch.enabled` 啟用。
- `maxChars` 受 `tools.web.fetch.maxCharsCap` 限制（預設 50000）。
- 回應已快取（預設 15 分鐘）。
- 對 JS 密集網站，優先使用 browser 工具。
- 見 [Web tools](/zh-Hant/tools/web) 瞭解設定。
- 見 [Firecrawl](/zh-Hant/tools/firecrawl) 瞭解選用的防機器人備用。

### `browser`

控制專屬的 OpenClaw 管理瀏覽器。

核心動作：

- `status`、`start`、`stop`、`tabs`、`open`、`focus`、`close`
- `snapshot`（aria/ai）
- `screenshot`（回傳圖片區塊 + `MEDIA:<path>`）
- `act`（UI 動作：click/type/press/hover/drag/select/fill/resize/wait/evaluate）
- `navigate`、`console`、`pdf`、`upload`、`dialog`

Profile 管理：

- `profiles` — 列出所有瀏覽器 profiles 及狀態
- `create-profile` — 建立自動分配埠（或 `cdpUrl`）的新 profile
- `delete-profile` — 停止瀏覽器、刪除使用者資料、從設定移除（僅限本地）
- `reset-profile` — 終止 profile 埠上的孤立程序（僅限本地）

常用參數：

- `profile`（選用；預設為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（選用；指定特定節點 id/名稱）
  注意：
- 需要 `browser.enabled=true`（預設為 `true`；設為 `false` 可停用）。
- 所有動作接受選用的 `profile` 參數用於多實例支援。
- 省略 `profile` 時，使用 `browser.defaultProfile`（預設為 "chrome"）。
- Profile 名稱：僅小寫英數字和連字符（最多 64 字元）。
- 埠範圍：18800-18899（約 100 個 profiles）。
- 遠端 profiles 僅限附加（無法 start/stop/reset）。
- 若已連接具備瀏覽器能力的節點，工具可能自動路由至它（除非你固定 `target`）。
- `snapshot` 在安裝 Playwright 時預設為 `ai`；使用 `aria` 取得無障礙樹。
- `snapshot` 也支援 role-snapshot 選項（`interactive`、`compact`、`depth`、`selector`），回傳如 `e12` 的 refs。
- `act` 需要來自 `snapshot` 的 `ref`（AI 快照的數字 `12`，或 role 快照的 `e12`）；對少見的 CSS 選擇器需求使用 `evaluate`。
- 預設避免 `act` → `wait`；僅在例外情況下使用（無可靠的 UI 狀態可等待）。
- `upload` 可選擇傳遞 `ref` 以在預備後自動點擊。
- `upload` 也支援 `inputRef`（aria ref）或 `element`（CSS 選擇器）直接設定 `<input type="file">`。

### `canvas`

驅動節點 Canvas（present、eval、snapshot、A2UI）。

核心動作：

- `present`、`hide`、`navigate`、`eval`
- `snapshot`（回傳圖片區塊 + `MEDIA:<path>`）
- `a2ui_push`、`a2ui_reset`

注意：

- 底層使用 gateway `node.invoke`。
- 若未提供 `node`，工具選擇預設（單一已連接節點或本地 mac 節點）。
- A2UI 僅限 v0.8（無 `createSurface`）；CLI 拒絕帶有行錯誤的 v0.9 JSONL。
- 快速冒煙測試：`openclaw nodes canvas a2ui push --node <id> --text "Hello from A2UI"`。

### `nodes`

探索和指定已配對節點；傳送通知；擷取相機/螢幕。

核心動作：

- `status`、`describe`
- `pending`、`approve`、`reject`（配對）
- `notify`（macOS `system.notify`）
- `run`（macOS `system.run`）
- `camera_list`、`camera_snap`、`camera_clip`、`screen_record`
- `location_get`、`notifications_list`、`notifications_action`
- `device_status`、`device_info`、`device_permissions`、`device_health`

注意：

- 相機/螢幕命令需要節點 app 在前景執行。
- 圖片回傳圖片區塊 + `MEDIA:<path>`。
- 影片回傳 `FILE:<path>`（mp4）。
- 位置回傳 JSON payload（lat/lon/accuracy/timestamp）。
- `run` 參數：`command` argv 陣列；選用 `cwd`、`env`（`KEY=VAL`）、`commandTimeoutMs`、`invokeTimeoutMs`、`needsScreenRecording`。

範例（`run`）：

```json
{
  "action": "run",
  "node": "office-mac",
  "command": ["echo", "Hello"],
  "env": ["FOO=bar"],
  "commandTimeoutMs": 12000,
  "invokeTimeoutMs": 45000,
  "needsScreenRecording": false
}
```

### `image`

以已設定的圖片模型分析圖片。

核心參數：

- `image`（必填路徑或 URL）
- `prompt`（選用；預設為「Describe the image.」）
- `model`（選用覆寫）
- `maxBytesMb`（選用大小上限）

注意：

- 僅在 `agents.defaults.imageModel` 已設定（主要或備用）時可用，或當可以從你的預設模型 + 已設定的驗證推斷隱含的圖片模型時（盡力配對）。
- 直接使用圖片模型（獨立於主要聊天模型）。

### `pdf`

分析一個或多個 PDF 文件。

完整行為、限制、設定和範例見 [PDF tool](/zh-Hant/tools/pdf)。

### `message`

跨 Discord/Google Chat/Slack/Telegram/WhatsApp/Signal/iMessage/MS Teams 傳送訊息和頻道動作。

核心動作：

- `send`（文字 + 選用媒體；MS Teams 也支援 `card` 用於 Adaptive Cards）
- `poll`（WhatsApp/Discord/MS Teams 投票）
- `react` / `reactions` / `read` / `edit` / `delete`
- `pin` / `unpin` / `list-pins`
- `permissions`
- `thread-create` / `thread-list` / `thread-reply`
- `search`
- `sticker`
- `member-info` / `role-info`
- `emoji-list` / `emoji-upload` / `sticker-upload`
- `role-add` / `role-remove`
- `channel-info` / `channel-list`
- `voice-status`
- `event-list` / `event-create`
- `timeout` / `kick` / `ban`

注意：

- `send` 透過 Gateway 路由 WhatsApp；其他頻道直接傳送。
- `poll` 對 WhatsApp 和 MS Teams 使用 Gateway；Discord 投票直接傳送。
- 當訊息工具呼叫綁定至活躍的聊天 session 時，傳送受限於該 session 的目標，以避免跨 context 洩漏。

### `cron`

管理 Gateway cron 工作和喚醒。

核心動作：

- `status`、`list`
- `add`、`update`、`remove`、`run`、`runs`
- `wake`（排入系統事件 + 選用立即心跳）

注意：

- `add` 期望完整的 cron 工作物件（與 `cron.add` RPC 相同的 schema）。
- `update` 使用 `{ jobId, patch }`（接受 `id` 以保持相容性）。

### `gateway`

重新啟動或對執行中的 Gateway 程序套用更新（就地）。

核心動作：

- `restart`（授權 + 傳送 `SIGUSR1` 進行程序內重新啟動；`openclaw gateway` 就地重新啟動）
- `config.schema.lookup`（一次檢查一個設定路徑，不將完整 schema 載入提示 context）
- `config.get`
- `config.apply`（驗證 + 寫入設定 + 重新啟動 + 喚醒）
- `config.patch`（合併部分更新 + 重新啟動 + 喚醒）
- `update.run`（執行更新 + 重新啟動 + 喚醒）

注意：

- `config.schema.lookup` 期望目標設定路徑，如 `gateway.auth` 或 `agents.list.*.heartbeat`。
- 在指定 `plugins.entries.<id>` 時，路徑可以包含斜線分隔的 plugin id，例如 `plugins.entries.pack/one.config`。
- 使用 `delayMs`（預設 2000）以避免中斷正在進行的回覆。
- `config.schema` 仍可供內部 Control UI 流程使用，且不透過 agent `gateway` 工具公開。
- `restart` 預設啟用；設定 `commands.restart: false` 可停用。

### `sessions_list` / `sessions_history` / `sessions_send` / `sessions_spawn` / `session_status`

列出 sessions、檢查對話記錄，或傳送至另一個 session。

核心參數：

- `sessions_list`：`kinds?`、`limit?`、`activeMinutes?`、`messageLimit?`（0 = 無）
- `sessions_history`：`sessionKey`（或 `sessionId`）、`limit?`、`includeTools?`
- `sessions_send`：`sessionKey`（或 `sessionId`）、`message`、`timeoutSeconds?`（0 = 發送後不等待）
- `sessions_spawn`：`task`、`label?`、`runtime?`、`agentId?`、`model?`、`thinking?`、`cwd?`、`runTimeoutSeconds?`、`thread?`、`mode?`、`cleanup?`、`sandbox?`、`streamTo?`、`attachments?`、`attachAs?`
- `session_status`：`sessionKey?`（預設當前；接受 `sessionId`）、`model?`（`default` 清除覆寫）

注意：

- `main` 是正規的直接聊天 key；global/unknown 已隱藏。
- `messageLimit > 0` 每個 session 獲取最後 N 則訊息（已過濾工具訊息）。
- Session 指定由 `tools.sessions.visibility` 控制（預設 `tree`：當前 session + 已生成的 subagent sessions）。若你為多個使用者執行共享 agent，考慮設定 `tools.sessions.visibility: "self"` 以防止跨 session 瀏覽。
- `sessions_send` 在 `timeoutSeconds > 0` 時等待最終完成。
- 傳遞/通知在完成後發生，是盡力而為；`status: "ok"` 確認 agent run 完成，而非通知已傳遞。
- `sessions_spawn` 支援 `runtime: "subagent" | "acp"`（預設 `subagent`）。ACP runtime 行為見 [ACP Agents](/zh-Hant/tools/acp-agents)。
- 對於 ACP runtime，`streamTo: "parent"` 將初始 run 進度摘要作為 system events 路由回請求者 session，而非直接子傳遞。
- `sessions_spawn` 啟動 sub-agent run 並向請求者聊天頻道回發通知回覆。
  - 支援一次性模式（`mode: "run"`）和持久 thread 綁定模式（`mode: "session"` 加 `thread: true`）。
  - 若 `thread: true` 且省略 `mode`，mode 預設為 `session`。
  - `mode: "session"` 需要 `thread: true`。
  - 若省略 `runTimeoutSeconds`，當已設定時，OpenClaw 使用 `agents.defaults.subagents.runTimeoutSeconds`；否則逾時預設為 `0`（無逾時）。
  - Discord thread 綁定流程依賴 `session.threadBindings.*` 和 `channels.discord.threadBindings.*`。
  - 回覆格式包含 `Status`、`Result` 和精簡統計資訊。
  - `Result` 是 assistant 完成文字；若遺失，使用最新的 `toolResult` 作為備用。
- 手動完成模式 spawns 先直接傳送，在佇列備用和短暫失敗時重試（`status: "ok"` 表示 run 完成，不表示通知已傳遞）。
- `sessions_spawn` 支援內嵌檔案附件，僅限 subagent runtime（ACP 拒絕它們）。每個附件有 `name`、`content` 和選用的 `encoding`（`utf8` 或 `base64`）以及 `mimeType`。檔案在子工作區的 `.openclaw/attachments/<uuid>/` 中實體化，並帶有 `.manifest.json` 元資料檔案。工具回傳帶有 `count`、`totalBytes`、每個檔案 `sha256` 和 `relDir` 的收據。附件內容從對話記錄持久化中自動編輯。
  - 透過 `tools.sessions_spawn.attachments`（`enabled`、`maxTotalBytes`、`maxFiles`、`maxFileBytes`、`retainOnSessionKeep`）設定限制。
  - `attachAs.mountPath` 是為未來掛載實作保留的提示。
- `sessions_spawn` 是非阻塞的，立即回傳 `status: "accepted"`。
- ACP `streamTo: "parent"` 回應可能包含 `streamLogPath`（session 範疇的 `*.acp-stream.jsonl`）用於追蹤進度歷史。
- `sessions_send` 執行回覆乒乓（回覆 `REPLY_SKIP` 停止；透過 `session.agentToAgent.maxPingPongTurns` 設定最大回合，0–5）。
- 乒乓後，目標 agent 執行**通知步驟**；回覆 `ANNOUNCE_SKIP` 以抑制通知。
- 沙箱限制：當當前 session 已沙箱化且 `agents.defaults.sandbox.sessionToolsVisibility: "spawned"` 時，OpenClaw 將 `tools.sessions.visibility` 限制為 `tree`。

### `agents_list`

列出當前 session 可以以 `sessions_spawn` 指定的 agent id。

注意：

- 結果受每個 agent 的 allowlists（`agents.list[].subagents.allowAgents`）限制。
- 設定 `["*"]` 時，工具包含所有已設定的 agents 並標記 `allowAny: true`。

## 參數（通用）

Gateway 支援的工具（`canvas`、`nodes`、`cron`）：

- `gatewayUrl`（預設 `ws://127.0.0.1:18789`）
- `gatewayToken`（若已啟用驗證）
- `timeoutMs`

注意：設定 `gatewayUrl` 時，明確包含 `gatewayToken`。工具不繼承覆寫的設定或環境憑證，遺失明確憑證是錯誤。

Browser 工具：

- `profile`（選用；預設為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（選用；固定特定節點 id/名稱）
- 疑難排解指南：
  - Linux 啟動/CDP 問題：[Browser troubleshooting (Linux)](/zh-Hant/tools/browser-linux-troubleshooting)
  - WSL2 Gateway + Windows 遠端 Chrome CDP：[WSL2 + Windows + remote Chrome CDP troubleshooting](/zh-Hant/tools/browser-wsl2-windows-remote-cdp-troubleshooting)

## 推薦的 agent 流程

瀏覽器自動化：

1. `browser` → `status` / `start`
2. `snapshot`（ai 或 aria）
3. `act`（click/type/press）
4. 若需要視覺確認則 `screenshot`

Canvas 渲染：

1. `canvas` → `present`
2. `a2ui_push`（選用）
3. `snapshot`

節點指定：

1. `nodes` → `status`
2. 在所選節點上 `describe`
3. `notify` / `run` / `camera_snap` / `screen_record`

## 安全性

- 避免直接 `system.run`；僅在明確使用者同意下使用 `nodes` → `run`。
- 尊重相機/螢幕擷取的使用者同意。
- 在呼叫媒體命令前使用 `status/describe` 確認權限。

## 工具如何呈現給 agent

工具透過兩個並行頻道公開：

1. **System prompt 文字**：人類可讀的清單 + 指引。
2. **Tool schema**：傳送至模型 API 的結構化函式定義。

這意味著 agent 同時看到「有哪些工具」和「如何呼叫它們」。若工具未出現在 system prompt 或 schema 中，模型無法呼叫它。
