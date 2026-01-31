---
title: "Index(Tools 總覽)"
summary: "OpenClaw 的 Agent Tool 表面（browser、canvas、nodes、message、cron）取代舊版 `openclaw-*` Skills"
read_when:
  - 新增或修改 Agent Tools
  - 淘汰或變更 `openclaw-*` Skills
---

# Tools (OpenClaw)

OpenClaw 為 Browser、Canvas、Nodes 和 Cron 提供**第一級 Agent Tools**。這些取代舊版的 `openclaw-*` Skills：這些 Tools 是 Typed 的、無需 Shelling，Agent 應直接依賴它們。

## 停用 Tools

您可以透過 `openclaw.json` 中的 `tools.allow` / `tools.deny` 全域允許/拒絕 Tools（deny 優先）。這可防止不允許的 Tools 傳送至 Model Providers。

```json5
{
  tools: { deny: ["browser"] }
}
```

注意事項：
- 比對不區分大小寫。
- 支援 `*` 萬用字元（`"*"` 表示所有 Tools）。
- 如果 `tools.allow` 僅參考未知或未載入的 Plugin Tool 名稱，OpenClaw 會記錄警告並忽略 Allowlist，讓 Core Tools 保持可用。

## Tool Profiles（基礎 Allowlist）

`tools.profile` 在 `tools.allow`/`tools.deny` 之前設定**基礎 Tool Allowlist**。Per-agent 覆寫：`agents.list[].tools.profile`。

Profiles：
- `minimal`：僅 `session_status`
- `coding`：`group:fs`、`group:runtime`、`group:sessions`、`group:memory`、`image`
- `messaging`：`group:messaging`、`sessions_list`、`sessions_history`、`sessions_send`、`session_status`
- `full`：無限制（與未設定相同）

範例（預設僅 Messaging，也允許 Slack + Discord Tools）：
```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"]
  }
}
```

範例（Coding Profile，但在任何地方都拒絕 exec/process）：
```json5
{
  tools: {
    profile: "coding",
    deny: ["group:runtime"]
  }
}
```

範例（全域 Coding Profile，僅 Messaging 的 Support Agent）：
```json5
{
  tools: { profile: "coding" },
  agents: {
    list: [
      {
        id: "support",
        tools: { profile: "messaging", allow: ["slack"] }
      }
    ]
  }
}
```

## Provider-specific Tool Policy

使用 `tools.byProvider` 為特定 Providers（或單一 `provider/model`）**進一步限制** Tools，而不變更您的全域預設值。Per-agent 覆寫：`agents.list[].tools.byProvider`。

這會在基礎 Tool Profile **之後**、Allow/Deny 清單**之前**套用，因此只能縮小 Tool 集合。Provider Keys 接受 `provider`（例如 `google-antigravity`）或 `provider/model`（例如 `openai/gpt-5.2`）。

範例（保持全域 Coding Profile，但 Google Antigravity 使用 Minimal Tools）：
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

範例（不穩定端點的 Provider/Model-specific Allowlist）：
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

範例（單一 Provider 的 Agent-specific 覆寫）：
```json5
{
  agents: {
    list: [
      {
        id: "support",
        tools: {
          byProvider: {
            "google-antigravity": { allow: ["message", "sessions_list"] }
          }
        }
      }
    ]
  }
}
```

## Tool Groups（速寫）

Tool Policies（Global、Agent、Sandbox）支援會展開為多個 Tools 的 `group:*` 項目。在 `tools.allow` / `tools.deny` 中使用這些。

可用 Groups：
- `group:runtime`：`exec`、`bash`、`process`
- `group:fs`：`read`、`write`、`edit`、`apply_patch`
- `group:sessions`：`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- `group:memory`：`memory_search`、`memory_get`
- `group:web`：`web_search`、`web_fetch`
- `group:ui`：`browser`、`canvas`
- `group:automation`：`cron`、`gateway`
- `group:messaging`：`message`
- `group:nodes`：`nodes`
- `group:openclaw`：所有內建 OpenClaw Tools（排除 Provider Plugins）

範例（僅允許 File Tools + Browser）：
```json5
{
  tools: {
    allow: ["group:fs", "browser"]
  }
}
```

## Plugins + Tools

Plugins 可以在 Core 集合之外註冊**額外的 Tools**（和 CLI 指令）。請見 [Plugins](/plugin) 了解安裝 + Config，以及 [Skills](/tools/skills) 了解 Tool 使用指引如何注入到 Prompts 中。部分 Plugins 會隨 Tools 一起提供自己的 Skills（例如 Voice-call Plugin）。

選用 Plugin Tools：
- [Lobster](/tools/lobster)：Typed 工作流程 Runtime，具有可恢復的 Approvals（需要 Gateway Host 上有 Lobster CLI）。
- [LLM Task](/tools/llm-task)：純 JSON LLM 步驟，用於結構化工作流程輸出（選用 Schema 驗證）。

## Tool 清單

### `apply_patch`
在一個或多個檔案中套用結構化 Patches。用於 Multi-hunk 編輯。
實驗性：透過 `tools.exec.applyPatch.enabled` 啟用（僅限 OpenAI 模型）。

### `exec`
在 Workspace 中執行 Shell 指令。

核心參數：
- `command`（必填）
- `yieldMs`（Timeout 後自動背景，預設 10000）
- `background`（立即背景）
- `timeout`（秒；超過時終止 Process，預設 1800）
- `elevated`（bool；如果啟用/允許 Elevated Mode 則在 Host 上執行；僅在 Agent 被 Sandboxed 時改變行為）
- `host`（`sandbox | gateway | node`）
- `security`（`deny | allowlist | full`）
- `ask`（`off | on-miss | always`）
- `node`（`host=node` 的 Node ID/Name）
- 需要真正的 TTY？設定 `pty: true`。

注意事項：
- 背景化時回傳 `status: "running"` 和 `sessionId`。
- 使用 `process` 來 Poll/Log/Write/Kill/Clear 背景 Sessions。
- 如果 `process` 被禁止，`exec` 會同步執行並忽略 `yieldMs`/`background`。
- `elevated` 受 `tools.elevated` 加上任何 `agents.list[].tools.elevated` 覆寫的限制（兩者都必須允許），是 `host=gateway` + `security=full` 的別名。
- `elevated` 僅在 Agent 被 Sandboxed 時改變行為（否則是 No-op）。
- `host=node` 可以指定 macOS Companion App 或 Headless Node Host（`openclaw node run`）。
- Gateway/Node Approvals 和 Allowlists：[Exec approvals](/tools/exec-approvals)。

### `process`
管理背景 Exec Sessions。

核心動作：
- `list`、`poll`、`log`、`write`、`kill`、`clear`、`remove`

注意事項：
- `poll` 在完成時回傳新輸出和 Exit Status。
- `log` 支援基於行的 `offset`/`limit`（省略 `offset` 可取得最後 N 行）。
- `process` 依 Agent 劃分範圍；其他 Agents 的 Sessions 不可見。

### `web_search`
使用 Brave Search API 搜尋網路。

核心參數：
- `query`（必填）
- `count`（1–10；預設來自 `tools.web.search.maxResults`）

注意事項：
- 需要 Brave API Key（建議：`openclaw configure --section web`，或設定 `BRAVE_API_KEY`）。
- 透過 `tools.web.search.enabled` 啟用。
- 回應會被快取（預設 15 分鐘）。
- 請見 [Web tools](/tools/web) 了解設定。

### `web_fetch`
從 URL 取得並擷取可讀內容（HTML → Markdown/Text）。

核心參數：
- `url`（必填）
- `extractMode`（`markdown` | `text`）
- `maxChars`（截斷長頁面）

注意事項：
- 透過 `tools.web.fetch.enabled` 啟用。
- 回應會被快取（預設 15 分鐘）。
- 對於 JS-heavy 網站，建議使用 Browser Tool。
- 請見 [Web tools](/tools/web) 了解設定。
- 請見 [Firecrawl](/tools/firecrawl) 了解選用的 Anti-bot Fallback。

### `browser`
控制專用的 OpenClaw-managed Browser。

核心動作：
- `status`、`start`、`stop`、`tabs`、`open`、`focus`、`close`
- `snapshot`（aria/ai）
- `screenshot`（回傳 Image Block + `MEDIA:<path>`）
- `act`（UI 動作：click/type/press/hover/drag/select/fill/resize/wait/evaluate）
- `navigate`、`console`、`pdf`、`upload`、`dialog`

Profile 管理：
- `profiles` — 列出所有 Browser Profiles 及狀態
- `create-profile` — 使用自動配置的 Port（或 `cdpUrl`）建立新 Profile
- `delete-profile` — 停止 Browser、刪除 User Data、從 Config 移除（僅限 Local）
- `reset-profile` — 終止 Profile Port 上的孤兒 Process（僅限 Local）

常見參數：
- `profile`（選用；預設為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（選用；指定特定 Node ID/Name）

注意事項：
- 需要 `browser.enabled=true`（預設為 `true`；設定 `false` 停用）。
- 所有動作接受選用的 `profile` 參數以支援多實例。
- 省略 `profile` 時使用 `browser.defaultProfile`（預設為 "chrome"）。
- Profile 名稱：僅限小寫英數字元 + 連字號（最多 64 字元）。
- Port 範圍：18800-18899（最多約 100 個 Profiles）。
- Remote Profiles 僅支援 Attach（無 Start/Stop/Reset）。
- 如果連接了具備 Browser 能力的 Node，Tool 可能會自動路由到它（除非您指定 `target`）。
- `snapshot` 在安裝 Playwright 時預設為 `ai`；使用 `aria` 取得 Accessibility Tree。
- `snapshot` 也支援 Role-snapshot 選項（`interactive`、`compact`、`depth`、`selector`），回傳如 `e12` 的 Refs。
- `act` 需要來自 `snapshot` 的 `ref`（AI Snapshots 的數字 `12`，或 Role Snapshots 的 `e12`）；如需 CSS Selector，使用 `evaluate`。
- 避免預設 `act` → `wait`；僅在特殊情況下使用（無可靠的 UI 狀態可等待）。
- `upload` 可選擇傳入 `ref` 以在 Arming 後自動點擊。
- `upload` 也支援 `inputRef`（Aria Ref）或 `element`（CSS Selector）以直接設定 `<input type="file">`。

### `canvas`
驅動 Node Canvas（Present、Eval、Snapshot、A2UI）。

核心動作：
- `present`、`hide`、`navigate`、`eval`
- `snapshot`（回傳 Image Block + `MEDIA:<path>`）
- `a2ui_push`、`a2ui_reset`

注意事項：
- 底層使用 Gateway `node.invoke`。
- 如果未提供 `node`，Tool 會選擇預設（單一連接的 Node 或 Local Mac Node）。
- A2UI 僅限 v0.8（無 `createSurface`）；CLI 會拒絕 v0.9 JSONL 並顯示行錯誤。
- 快速測試：`openclaw nodes canvas a2ui push --node <id> --text "Hello from A2UI"`。

### `nodes`
探索和指定已配對的 Nodes；傳送通知；擷取 Camera/Screen。

核心動作：
- `status`、`describe`
- `pending`、`approve`、`reject`（配對）
- `notify`（macOS `system.notify`）
- `run`（macOS `system.run`）
- `camera_snap`、`camera_clip`、`screen_record`
- `location_get`

注意事項：
- Camera/Screen 指令需要 Node App 在前景。
- Images 回傳 Image Blocks + `MEDIA:<path>`。
- Videos 回傳 `FILE:<path>`（mp4）。
- Location 回傳 JSON Payload（lat/lon/accuracy/timestamp）。
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
使用設定的 Image Model 分析圖片。

核心參數：
- `image`（必填路徑或 URL）
- `prompt`（選用；預設為 "Describe the image."）
- `model`（選用覆寫）
- `maxBytesMb`（選用大小上限）

注意事項：
- 僅在設定 `agents.defaults.imageModel`（Primary 或 Fallbacks）時可用，或當可從您的預設 Model + 設定的 Auth 推斷出 Implicit Image Model 時（盡力配對）。
- 直接使用 Image Model（與主要 Chat Model 無關）。

### `message`
在 Discord/Google Chat/Slack/Telegram/WhatsApp/Signal/iMessage/MS Teams 間傳送訊息和 Channel 動作。

核心動作：
- `send`（Text + 選用 Media；MS Teams 也支援 `card` 用於 Adaptive Cards）
- `poll`（WhatsApp/Discord/MS Teams Polls）
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

注意事項：
- `send` 透過 Gateway 路由 WhatsApp；其他 Channels 直接傳送。
- `poll` 對 WhatsApp 和 MS Teams 使用 Gateway；Discord Polls 直接傳送。
- 當 Message Tool Call 綁定到活躍 Chat Session 時，傳送會限制在該 Session 的目標，以避免跨 Context 洩漏。

### `cron`
管理 Gateway Cron Jobs 和 Wakeups。

核心動作：
- `status`、`list`
- `add`、`update`、`remove`、`run`、`runs`
- `wake`（排入 System Event + 選用立即 Heartbeat）

注意事項：
- `add` 期望完整的 Cron Job 物件（與 `cron.add` RPC 相同的 Schema）。
- `update` 使用 `{ id, patch }`。

### `gateway`
重新啟動或套用更新至執行中的 Gateway Process（In-place）。

核心動作：
- `restart`（授權 + 傳送 `SIGUSR1` 進行 In-process 重新啟動；`openclaw gateway` In-place 重新啟動）
- `config.get` / `config.schema`
- `config.apply`（驗證 + 寫入 Config + 重新啟動 + Wake）
- `config.patch`（合併部分更新 + 重新啟動 + Wake）
- `update.run`（執行更新 + 重新啟動 + Wake）

注意事項：
- 使用 `delayMs`（預設 2000）以避免中斷進行中的回覆。
- `restart` 預設停用；使用 `commands.restart: true` 啟用。

### `sessions_list` / `sessions_history` / `sessions_send` / `sessions_spawn` / `session_status`
列出 Sessions、檢視 Transcript 歷史，或傳送到另一個 Session。

核心參數：
- `sessions_list`：`kinds?`、`limit?`、`activeMinutes?`、`messageLimit?`（0 = 無）
- `sessions_history`：`sessionKey`（或 `sessionId`）、`limit?`、`includeTools?`
- `sessions_send`：`sessionKey`（或 `sessionId`）、`message`、`timeoutSeconds?`（0 = Fire-and-forget）
- `sessions_spawn`：`task`、`label?`、`agentId?`、`model?`、`runTimeoutSeconds?`、`cleanup?`
- `session_status`：`sessionKey?`（預設目前；接受 `sessionId`）、`model?`（`default` 清除覆寫）

注意事項：
- `main` 是標準 Direct-chat Key；Global/Unknown 會隱藏。
- `messageLimit > 0` 取得每個 Session 的最後 N 則訊息（過濾 Tool 訊息）。
- `sessions_send` 在 `timeoutSeconds > 0` 時等待最終完成。
- Delivery/Announce 在完成後發生且為盡力而為；`status: "ok"` 確認 Agent Run 完成，而非 Announce 已傳遞。
- `sessions_spawn` 啟動 Sub-agent Run 並將公告回覆張貼回請求者 Chat。
- `sessions_spawn` 是非阻塞的，立即回傳 `status: "accepted"`。
- `sessions_send` 執行 Reply-back Ping-pong（回覆 `REPLY_SKIP` 停止；最大 Turns 透過 `session.agentToAgent.maxPingPongTurns`，0–5）。
- Ping-pong 後，目標 Agent 執行 **Announce 步驟**；回覆 `ANNOUNCE_SKIP` 可抑制公告。

### `agents_list`
列出目前 Session 可透過 `sessions_spawn` 指定的 Agent IDs。

注意事項：
- 結果受 Per-agent Allowlists（`agents.list[].subagents.allowAgents`）限制。
- 設定 `["*"]` 時，Tool 會包含所有設定的 Agents 並標記 `allowAny: true`。

## 參數（通用）

Gateway-backed Tools（`canvas`、`nodes`、`cron`）：
- `gatewayUrl`（預設 `ws://127.0.0.1:18789`）
- `gatewayToken`（如果啟用 Auth）
- `timeoutMs`

Browser Tool：
- `profile`（選用；預設為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（選用；指定特定 Node ID/Name）

## 建議的 Agent 流程

Browser 自動化：
1) `browser` → `status` / `start`
2) `snapshot`（ai 或 aria）
3) `act`（click/type/press）
4) `screenshot` 如果需要視覺確認

Canvas Render：
1) `canvas` → `present`
2) `a2ui_push`（選用）
3) `snapshot`

Node Targeting：
1) `nodes` → `status`
2) 對所選 Node 執行 `describe`
3) `notify` / `run` / `camera_snap` / `screen_record`

## 安全

- 避免直接 `system.run`；僅在明確使用者同意下使用 `nodes` → `run`。
- 尊重使用者對 Camera/Screen 擷取的同意。
- 在呼叫 Media 指令前使用 `status/describe` 確保權限。

## 如何向 Agent 呈現 Tools

Tools 透過兩個平行管道公開：

1) **System Prompt Text**：可讀的清單 + 指引。
2) **Tool Schema**：傳送至 Model API 的結構化 Function 定義。

這表示 Agent 同時看到「有哪些 Tools」和「如何呼叫它們」。如果 Tool 未出現在 System Prompt 或 Schema 中，Model 無法呼叫它。
