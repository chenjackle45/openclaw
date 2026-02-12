---
summary: "OpenClaw 的代理工具介面（瀏覽器、畫布、節點、訊息、cron）取代舊版 `openclaw-*` 技能"
read_when:
  - Adding or modifying agent tools
  - Retiring or changing `openclaw-*` skills
title: "Tools（工具）"
---

# Tools（工具）

OpenClaw 為瀏覽器、畫布、節點及 cron 公開**第一級代理工具**。
這些取代舊的 `openclaw-*` 技能：工具具有型別、無 shell，
代理應直接依賴它們。

## 停用工具

可以透過 `openclaw.json` 中的 `tools.allow` / `tools.deny` 全域允許/拒絕工具
（拒絕獲勝）。這防止不允許的工具被發送到模型提供者。

```json5
{
  tools: { deny: ["browser"] },
}
```

注意：

- 符合不區分大小寫。
- 支援 `*` 通配符（`"*"` 表示所有工具）。
- 如果 `tools.allow` 僅引用未知或未載入的外掛工具名稱，OpenClaw 會記錄警告並忽略 allowlist，以保持核心工具可用。

## 工具設定檔（基本 allowlist）

`tools.profile` 設定一個**基本工具 allowlist**，在 `tools.allow`/`tools.deny` 之前。
每個代理覆蓋：`agents.list[].tools.profile`。

設定檔：

- `minimal`：僅 `session_status`
- `coding`：`group:fs`、`group:runtime`、`group:sessions`、`group:memory`、`image`
- `messaging`：`group:messaging`、`sessions_list`、`sessions_history`、`sessions_send`、`session_status`
- `full`：無限制（與未設定相同）

範例（預設傳訊，也允許 Slack ＋ Discord 工具）：

```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"],
  },
}
```

範例（編碼設定檔，但到處拒絕 exec/process）：

```json5
{
  tools: {
    profile: "coding",
    deny: ["group:runtime"],
  },
}
```

範例（全域編碼設定檔，傳訊支援代理）：

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

## 提供者特定工具政策

使用 `tools.byProvider` 為特定提供者
（或單個 `provider/model`）進一步限制工具，無需改變全域預設值。
每個代理覆蓋：`agents.list[].tools.byProvider`。

這在基本工具設定檔**之後**及 allow/deny 列表**之前**套用，
因此只能縮小工具集。
提供者鑰接受 `provider`（例如 `google-antigravity`）或
`provider/model`（例如 `openai/gpt-5.2`）。

範例（保持全域編碼設定檔，但 Google Antigravity 的最少工具）：

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

範例（不穩定端點的提供者/模型特定 allowlist）：

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

範例（單個提供者的代理特定覆蓋）：

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

工具政策（全域、代理、沙箱）支援在 `tools.allow` / `tools.deny` 中的 `group:*` 項目。

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
- `group:openclaw`：所有內建 OpenClaw 工具（排除提供者外掛）

範例（僅允許檔案工具＋瀏覽器）：

```json5
{
  tools: {
    allow: ["group:fs", "browser"],
  },
}
```

## 外掛＋工具

外掛可以在核心集之外註冊**額外工具**（及 CLI 命令）。
見 [Plugins](/zh-Hant/tools/plugin) 以取得安裝＋設定，及 [Skills](/zh-Hant/tools/skills) 以瞭解工具使用指導如何注入到提示中。某些外掛隨工具一起提供其自己的技能
（例如 voice-call 外掛）。

可選外掛工具：

- [Lobster](/zh-Hant/tools/lobster)：具有可恢復許可的型別工作流執行時（在 gateway host 上需要 Lobster CLI）。
- [LLM Task](/zh-Hant/tools/llm-task)：工作流的 JSON-only LLM 步驟（可選架構驗證）。

## 工具庫存

### `apply_patch`

在一個或多個檔案上套用結構化補丁。用於多 hunk 編輯。
實驗性：透過 `tools.exec.applyPatch.enabled` 啟用（OpenAI 模型僅）。

### `exec`

在工作區中執行 shell 命令。

核心參數：

- `command`（必需）
- `yieldMs`（逾時後自動背景化，預設 10000）
- `background`（立即背景化）
- `timeout`（秒；超過時殺死程序，預設 1800）
- `elevated`（bool；如果啟用/允許提升模式時在主機上執行；僅當代理沙箱化時改變行為）
- `host`（`sandbox | gateway | node`）
- `security`（`deny | allowlist | full`）
- `ask`（`off | on-miss | always`）
- `node`（用於 `host=node` 的節點 id/name）
- 需要真實 TTY？設定 `pty: true`。

注意：

- 背景化時返回 `status: "running"` 及 `sessionId`。
- 使用 `process` 輪詢/記錄/寫入/殺死/清除背景工作階段。
- 如果 `process` 被拒絕，`exec` 同步執行並忽略 `yieldMs`/`background`。
- `elevated` 由 `tools.elevated` 加上任何 `agents.list[].tools.elevated` 覆蓋閘控（兩者都必須允許），是 `host=gateway` ＋ `security=full` 的別名。
- `elevated` 僅當代理沙箱化時改變行為（否則是無作用）。
- `host=node` 可以以 macOS 配套應用或無頭 node host（`openclaw node run`）為目標。
- gateway/node approvals 及 allowlist：[Exec approvals](/zh-Hant/tools/exec-approvals)。

### `process`

管理背景 exec 工作階段。

核心動作：

- `list`、`poll`、`log`、`write`、`kill`、`clear`、`remove`

注意：

- `poll` 返回新輸出及完成時的結束狀態。
- `log` 支援以行為基礎的 `offset`/`limit`（省略 `offset` 來抓取最後 N 行）。
- `process` 範圍為每個代理；來自其他代理的工作階段不可見。

### `web_search`

使用 Brave Search API 搜尋網路。

核心參數：

- `query`（必需）
- `count`（1–10；從 `tools.web.search.maxResults` 預設）

注意：

- 需要 Brave API 鑰（推薦：`openclaw configure --section web`，或設定 `BRAVE_API_KEY`）。
- 透過 `tools.web.search.enabled` 啟用。
- 回應被快取（預設 15 分鐘）。
- 見 [Web tools](/zh-Hant/tools/web) 以進行設定。

### `web_fetch`

從 URL 取得及擷取可讀內容（HTML → markdown/text）。

核心參數：

- `url`（必需）
- `extractMode`（`markdown` | `text`）
- `maxChars`（截斷長頁面）

注意：

- 透過 `tools.web.fetch.enabled` 啟用。
- `maxChars` 由 `tools.web.fetch.maxCharsCap`（預設 50000）固定。
- 回應被快取（預設 15 分鐘）。
- 對於 JS 繁重的網站，優先使用瀏覽器工具。
- 見 [Web tools](/zh-Hant/tools/web) 以進行設定。
- 見 [Firecrawl](/zh-Hant/tools/firecrawl) 用於可選的反機器人 fallback。

### `browser`

控制專用 OpenClaw 管理的瀏覽器。

核心動作：

- `status`、`start`、`stop`、`tabs`、`open`、`focus`、`close`
- `snapshot`（aria/ai）
- `screenshot`（返回影像區塊＋ `MEDIA:<path>`）
- `act`（UI 動作：click/type/press/hover/drag/select/fill/resize/wait/evaluate）
- `navigate`、`console`、`pdf`、`upload`、`dialog`

設定檔管理：

- `profiles` — 列出所有瀏覽器設定檔及狀態
- `create-profile` — 以自動分配的 port 建立新設定檔（或 `cdpUrl`）
- `delete-profile` — 停止瀏覽器、刪除使用者資料、從設定檔移除（僅本地）
- `reset-profile` — 殺死設定檔 port 上的孤立程序（僅本地）

常見參數：

- `profile`（可選；預設為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（可選；選擇特定節點 id/name）
  注意：
- 需要 `browser.enabled=true`（預設為 `true`；設定 `false` 停用）。
- 所有動作接受選擇性 `profile` 參數以支援多實例。
- 當省略 `profile` 時，使用 `browser.defaultProfile`（預設為 "chrome"）。
- 設定檔名稱：僅小寫英數及連字號（最多 64 字元）。
- Port 範圍：18800-18899（約 100 個設定檔上限）。
- 遠端設定檔是僅附加（無 start/stop/reset）。
- 如果連接了瀏覽器capable node，工具可能自動路由到它（除非你固定 `target`）。
- 安裝 Playwright 時 `snapshot` 預設為 `ai`；使用 `aria` 以取得無障礙樹。
- `snapshot` 也支援角色快照選項（`interactive`、`compact`、`depth`、`selector`），返回 refs 如 `e12`。
- `act` 需要來自 `snapshot` 的 `ref`（AI 快照的數字 `12`，或角色快照的 `e12`）；對罕見 CSS 選擇器需要使用 `evaluate`。
- 根據預設避免 `act` → `wait`；僅在例外情況下使用（無可靠的 UI 狀態等待）。
- `upload` 可以選擇性傳遞 `ref` 以自動點擊後武裝。
- `upload` 也支援 `inputRef`（aria ref）或 `element`（CSS 選擇器）以直接設定 `<input type="file">`。

### `canvas`

驅動節點 Canvas（出現、評估、快照、A2UI）。

核心動作：

- `present`、`hide`、`navigate`、`eval`
- `snapshot`（返回影像區塊＋ `MEDIA:<path>`）
- `a2ui_push`、`a2ui_reset`

注意：

- 在引擎下使用 gateway `node.invoke`。
- 如果沒有提供 `node`，工具選擇預設（單個連接節點或本地 mac 節點）。
- A2UI 是 v0.8 僅（無 `createSurface`）；CLI 以行錯誤拒絕 v0.9 JSONL。
- 快速煙霧測試：`openclaw nodes canvas a2ui push --node <id> --text "Hello from A2UI"`。

### `nodes`

探索及目標配對節點；發送通知；捕獲相機/螢幕。

核心動作：

- `status`、`describe`
- `pending`、`approve`、`reject`（配對）
- `notify`（macOS `system.notify`）
- `run`（macOS `system.run`）
- `camera_snap`、`camera_clip`、`screen_record`
- `location_get`

注意：

- 相機/螢幕命令需要 node 應用處於前景。
- 影像返回影像區塊＋ `MEDIA:<path>`。
- 影片返回 `FILE:<path>`（mp4）。
- 位置返回 JSON 有效負載（lat/lon/accuracy/timestamp）。
- `run` 參數：`command` argv 陣列；可選 `cwd`、`env`（`KEY=VAL`）、`commandTimeoutMs`、`invokeTimeoutMs`、`needsScreenRecording`。

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

用設定的影像模型分析影像。

核心參數：

- `image`（必需路徑或 URL）
- `prompt`（可選；預設為 "Describe the image."）
- `model`（可選覆蓋）
- `maxBytesMb`（可選大小上限）

注意：

- 僅當 `agents.defaults.imageModel` 被設定（主要或 fallback）時可用，或當可以從你的預設模型＋設定的認證推斷隱含影像模型時（最佳嘗試）。
- 直接使用影像模型（獨立於主聊天模型）。

### `message`

透過 Discord/Google Chat/Slack/Telegram/WhatsApp/Signal/iMessage/MS Teams 發送訊息及頻道動作。

核心動作：

- `send`（文字＋可選媒體；MS Teams 也支援 `card` 用於調適卡片）
- `poll`（WhatsApp/Discord/MS Teams 民調）
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

- `send` 透過 Gateway 路由 WhatsApp；其他頻道直接進行。
- `poll` 使用 WhatsApp 及 MS Teams 的 Gateway；Discord 民調直接進行。
- 當訊息工具呼叫綁定到活躍聊天工作階段時，發送被限制到該工作階段的目標，以避免跨context 洩露。

### `cron`

管理 Gateway cron 工作及喚醒。

核心動作：

- `status`、`list`
- `add`、`update`、`remove`、`run`、`runs`
- `wake`（排隊系統事件＋可選立即心跳）

注意：

- `add` 期望完整的 cron 工作物件（與 `cron.add` RPC 相同架構）。
- `update` 使用 `{ jobId, patch }`（為相容性接受 `id`）。

### `gateway`

重啟或套用更新到執行中 Gateway 程序（就地）。

核心動作：

- `restart`（授權＋發送 `SIGUSR1` 進行程序內重啟；`openclaw gateway` 就地重啟）
- `config.get` / `config.schema`
- `config.apply`（驗證＋寫入設定＋重啟＋喚醒）
- `config.patch`（合併部分更新＋重啟＋喚醒）
- `update.run`（執行更新＋重啟＋喚醒）

注意：

- 使用 `delayMs`（預設 2000）以避免中斷飛行中的回覆。
- `restart` 預設停用；使用 `commands.restart: true` 啟用。

### `sessions_list` / `sessions_history` / `sessions_send` / `sessions_spawn` / `session_status`

列出工作階段、檢查副本歷史或發送到另一工作階段。

核心參數：

- `sessions_list`：`kinds?`、`limit?`、`activeMinutes?`、`messageLimit?`（0 = 無）
- `sessions_history`：`sessionKey`（或 `sessionId`）、`limit?`、`includeTools?`
- `sessions_send`：`sessionKey`（或 `sessionId`）、`message`、`timeoutSeconds?`（0 = fire-and-forget）
- `sessions_spawn`：`task`、`label?`、`agentId?`、`model?`、`runTimeoutSeconds?`、`cleanup?`
- `session_status`：`sessionKey?`（預設現在；接受 `sessionId`）、`model?`（`default` 清除覆蓋）

注意：

- `main` 是正規直接聊天鑰；全域/未知被隱藏。
- `messageLimit > 0` 來 per session 取最後 N 訊息（工具訊息篩選）。
- `sessions_send` 在 `timeoutSeconds > 0` 時等待最終完成。
- 傳遞/宣佈在完成後發生，且是最佳嘗試；`status: "ok"` 確認代理執行完成，非宣佈被傳遞。
- `sessions_spawn` 啟動子代理執行並將公告回覆發佈到要求者聊天。
- `sessions_spawn` 非阻止且立即返回 `status: "accepted"`。
- `sessions_send` 執行回覆往返 ping-pong（回覆 `REPLY_SKIP` 停止；最大轉數透過 `session.agentToAgent.maxPingPongTurns`，0–5）。
- 在 ping-pong 之後，目標代理執行一個**公告步驟**；回覆 `ANNOUNCE_SKIP` 以抑制公告。

### `agents_list`

列出現在工作階段可能以 `sessions_spawn` 為目標的代理 id。

注意：

- 結果受限於每個代理 allowlist（`agents.list[].subagents.allowAgents`）。
- 當設定為 `["*"]` 時，工具包含所有設定的代理並標記 `allowAny: true`。

## 參數（常見）

Gateway 背靠的工具（`canvas`、`nodes`、`cron`）：

- `gatewayUrl`（預設 `ws://127.0.0.1:18789`）
- `gatewayToken`（如果啟用認證）
- `timeoutMs`

注意：當設定 `gatewayUrl` 時，明確包含 `gatewayToken`。工具不為覆蓋繼承設定
或環境認證，缺少明確認證是錯誤。

瀏覽器工具：

- `profile`（可選；預設為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（可選；固定特定節點 id/name）

## 推薦的代理流程

瀏覽器自動化：

1. `browser` → `status` / `start`
2. `snapshot`（ai 或 aria）
3. `act`（click/type/press）
4. `screenshot` 如果需要視覺確認

Canvas 渲染：

1. `canvas` → `present`
2. `a2ui_push`（可選）
3. `snapshot`

節點目標：

1. `nodes` → `status`
2. `describe` 在選擇的節點上
3. `notify` / `run` / `camera_snap` / `screen_record`

## 安全

- 避免直接 `system.run`；僅使用 `nodes` → `run` 及明確使用者同意。
- 尊重相機/螢幕捕獲的使用者同意。
- 使用 `status/describe` 以確保權限，然後再調用媒體命令。

## 工具如何呈現給代理

工具透過兩個平行管道公開：

1. **系統提示文字**：人類可讀列表＋指導。
2. **工具架構**：發送到模型 API 的結構化函式定義。

這表示代理看到"存在什麼工具"及"如何呼叫它們"。如果工具
不出現在系統提示或架構中，模型無法呼叫它。
