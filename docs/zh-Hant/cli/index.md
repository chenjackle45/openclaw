---
title: "index(指令總覽)"
summary: "OpenClaw CLI 參考手冊，包含 `openclaw` 指令、子指令及選項說明"
read_when:
  - 新增或修改 CLI 指令或選項時
  - 記錄新的指令介面時
---

# 指令參考 (CLI reference)

本頁面說明目前的 CLI 行為。若指令有所變更，請務必更新此文件。

## 指令頁面

- [`setup`](/cli/setup) (環境初始化)
- [`onboard`](/cli/onboard) (新手引導)
- [`configure`](/cli/configure) (互動式配置)
- [`config`](/cli/config) (配置管理)
- [`doctor`](/cli/doctor) (健康檢查與修復)
- [`dashboard`](/cli/dashboard) (控制中心)
- [`reset`](/cli/reset) (重設狀態)
- [`uninstall`](/cli/uninstall) (解除安裝)
- [`update`](/cli/update) (系統更新)
- [`message`](/cli/message) (訊息操作)
- [`agent`](/cli/agent) (直連 Agent)
- [`agents`](/cli/agents) (Agent 管理)
- [`acp`](/cli/acp) (ACP 橋接)
- [`status`](/cli/status) (狀態盤查)
- [`health`](/cli/health) (健康度)
- [`sessions`](/cli/sessions) (會話管理)
- [`gateway`](/cli/gateway) (Gateway 服務)
- [`logs`](/cli/logs) (日誌查看)
- [`system`](/cli/system) (系統事件)
- [`models`](/cli/models) (模型配置)
- [`memory`](/cli/memory) (記憶體搜尋)
- [`nodes`](/cli/nodes) (節點列表)
- [`devices`](/cli/devices) (裝置列表)
- [`node`](/cli/node) (節點操作)
- [`approvals`](/cli/approvals) (核准管理)
- [`sandbox`](/cli/sandbox) (沙盒管理)
- [`tui`](/cli/tui) (終端機介面)
- [`browser`](/cli/browser) (瀏覽器控制)
- [`cron`](/cli/cron) (排程管理)
- [`dns`](/cli/dns) (DNS 配置)
- [`docs`](/cli/docs) (文件閱讀)
- [`hooks`](/cli/hooks) (鉤子管理)
- [`webhooks`](/cli/webhooks) (Webhooks 管理)
- [`pairing`](/cli/pairing) (裝置配對)
- [`plugins`](/cli/plugins) (外掛管理)
- [`channels`](/cli/channels) (聊天頻道)
- [`security`](/cli/security) (安全性審查)
- [`skills`](/cli/skills) (技能管理)
- [`voicecall`](/cli/voicecall) (語音通話外掛)

## 全域旗標 (Global flags)

- `--dev`：將狀態隔離於 `~/.openclaw-dev` 下，並切換至開發預設埠位。
- `--profile <名稱>`：將狀態隔離於 `~/.openclaw-<名稱>` 下。
- `--no-color`：停用 ANSI 色彩。
- `--update`：`openclaw update` 的簡寫（僅限源碼安裝版）。
- `-V`, `--version`, `-v`：列印版本資訊並退出。

## 輸出樣式 (Output styling)

- ANSI 色彩與進度指示僅在 TTY 會話中呈現。
- 在支援的終端機中，OSC-8 超連結將以「可點擊連結」呈現；否則會退回純文字 URL。
- 使用 `--json`（或部分支援出的 `--plain`）可停用樣式以獲得乾淨的輸出內容。
- `--no-color` 或設定環境變數 `NO_COLOR=1` 可停用色彩。
- 耗時較長的指令會顯示進度指示器。

## 色彩調色盤 (Color palette)

OpenClaw 採用「龍蝦調色盤 (Lobster palette)」進行 CLI 輸出。

- `accent` (#FF5A2D)：標題、標籤、主要強調內容。
- `accentBright` (#FF7A3D)：指令名稱、重點。
- `accentDim` (#D14A22)：次要強調內容。
- `info` (#FF8A5B)：資訊類數值。
- `success` (#2FBF71)：成功狀態。
- `warn` (#FFB020)：警告、退回機制、提醒。
- `error` (#E23D2D)：錯誤、失敗。
- `muted` (#8B7F77)：取消強調、元資料。

## 指令樹 (Command tree)

```
openclaw [--dev] [--profile <名稱>] <指令>
  setup (初始化)
  onboard (新手引導)
  configure (配置嚮導)
  config (配置管理)
    get / set / unset
  doctor (疑難排解)
  security (安全審查)
    audit
  reset (重設)
  uninstall (解除安裝)
  update (更新)
  channels (頻道管理)
    list / status / logs / add / remove / login / logout
  skills (技能管理)
    list / info / check
  plugins (外掛管理)
    list / info / install / enable / disable / doctor
  memory (記憶體)
    status / index / search
  message (訊息)
  agent (執行 Agent)
  agents (Agent 管理)
    list / add / delete
  acp (ACP 橋接)
  status (狀態)
  health (健康)
  sessions (會話列表)
  gateway (Gateway 管理)
    call / health / status / probe / discover / install / uninstall / start / stop / restart / run
  logs (查看日誌)
  system (系統操作)
    event / heartbeat / presence
  models (模型配置)
    list / status / set / set-image / aliases / fallbacks / image-fallbacks / scan / auth
  sandbox (沙盒管理)
    list / recreate / explain
  cron (排程)
    status / list / add / edit / rm / enable / disable / runs / run
  nodes (節點發現)
  devices (裝置發現)
  node (節點控制)
    run / status / install / uninstall / start / stop / restart
  approvals (執行核准)
    get / set / allowlist
  browser (瀏覽器自動化)
    status / start / stop / reset-profile / tabs / open / focus / close / profiles / create-profile / delete-profile / screenshot / snapshot / navigate / resize / click / type / press / hover / drag / select / upload / fill / dialog / wait / evaluate / console / pdf
  hooks (鉤子)
    list / info / check / enable / disable / install / update
  webhooks (網路鉤子)
    gmail
  pairing (配對)
    list / approve
  docs (文件)
  dns (廣域發現)
    setup
  tui (TUI 介面)
```

注意：外掛可以新增額外的頂層指令（例如 `openclaw voicecall`）。

## 安全性 (Security)

- `openclaw security audit` —— 審查配置與本地狀態中常見的安全漏洞。
- `openclaw security audit --deep` —— 執行即時 Gateway 探針檢測。
- `openclaw security audit --fix` —— 強化安全預設設定並修改狀態/配置權限。

## 外掛 (Plugins)

管理擴展功能及其配置：

- `openclaw plugins list` —— 發現可用外掛（使用 `--json` 獲得機器格式輸出）。
- `openclaw plugins info <id>` —— 顯示外掛詳細資訊。
- `openclaw plugins install <path|.tgz|npm-spec>` —— 安裝外掛（或將外掛路徑新增至 `plugins.load.paths`）。
- `openclaw plugins enable <id>` / `disable <id>` —— 切換 `plugins.entries.<id>.enabled`。
- `openclaw plugins doctor` —— 回報外掛載入錯誤。

大多數外掛變更後需要重啟 Gateway。詳見 [/plugin](/plugin)。

## 記憶體 (Memory)

對 `MEMORY.md` + `memory/*.md` 進行向量搜尋：

- `openclaw memory status` —— 顯示索引統計資訊。
- `openclaw memory index` —— 重新索引記憶體檔案。
- `openclaw memory search "<查詢>"` —— 對記憶體進行語義搜尋。

## 聊天斜線指令

聊天訊息支援 `/...` 指令形式（文字及原生形式）。詳見 [/tools/slash-commands](/tools/slash-commands)。

重點包括：

- `/status` —— 快速診斷。
- `/config` —— 持久化配置變更。
- `/debug` —— 執行時限定的配置覆寫（記憶體而非硬碟；需要 `commands.debug: true`）。

## 初始化與新手引導

### `setup`

初始化配置與工作區。

選項：

- `--workspace <dir>`：Agent 工作區路徑（預設 `~/.openclaw/workspace`）。
- `--wizard`：執行新手引導嚮導。
- `--non-interactive`：執行嚮導而不提示。
- `--mode <local|remote>`：嚮導模式。
- `--remote-url <url>`：遠端 Gateway URL。
- `--remote-token <token>`：遠端 Gateway 權杖。

當指定任何嚮導旗標（`--non-interactive`、`--mode`、`--remote-url`、`--remote-token`）時，嚮導會自動執行。

### `onboard`

互動式嚮導以設定 Gateway、工作區及技能。

選項：

- `--workspace <dir>`
- `--reset` (重設嚮導前的配置、憑證、會話與工作區)
- `--non-interactive`
- `--mode <local|remote>`
- `--flow <quickstart|advanced|manual>` (manual 為 advanced 的別名)
- `--auth-choice <setup-token|token|chutes|openai-codex|openai-api-key|openrouter-api-key|ai-gateway-api-key|moonshot-api-key|kimi-code-api-key|synthetic-api-key|venice-api-key|gemini-api-key|zai-api-key|apiKey|minimax-api|minimax-api-lightning|opencode-zen|skip>`
- `--token-provider <id>` (非互動模式；搭配 `--auth-choice token` 使用)
- `--token <token>` (非互動模式；搭配 `--auth-choice token` 使用)
- `--token-profile-id <id>` (非互動模式；預設：`<provider>:manual`)
- `--token-expires-in <duration>` (非互動模式；例如 `365d`、`12h`)
- `--anthropic-api-key <key>`
- `--openai-api-key <key>`
- `--openrouter-api-key <key>`
- `--ai-gateway-api-key <key>`
- `--moonshot-api-key <key>`
- `--kimi-code-api-key <key>`
- `--gemini-api-key <key>`
- `--zai-api-key <key>`
- `--minimax-api-key <key>`
- `--opencode-zen-api-key <key>`
- `--gateway-port <port>`
- `--gateway-bind <loopback|lan|tailnet|auto|custom>`
- `--gateway-auth <token|password>`
- `--gateway-token <token>`
- `--gateway-password <password>`
- `--remote-url <url>`
- `--remote-token <token>`
- `--tailscale <off|serve|funnel>`
- `--tailscale-reset-on-exit`
- `--install-daemon`
- `--no-install-daemon` (別名：`--skip-daemon`)
- `--daemon-runtime <node|bun>`
- `--skip-channels`
- `--skip-skills`
- `--skip-health`
- `--skip-ui`
- `--node-manager <npm|pnpm|bun>` (推薦 pnpm；不推薦 bun 作為 Gateway 執行環境)
- `--json`

### `configure`

互動式配置嚮導（模型、頻道、技能、Gateway）。

### `config`

非互動配置助手（get/set/unset）。執行 `openclaw config` 而不加子指令時會啟動嚮導。

子指令：

- `config get <path>`：列印配置值（點號/括號路徑）。
- `config set <path> <value>`：設定值（JSON5 或原始字串）。
- `config unset <path>`：移除值。

### `doctor`

健康檢查與快速修復（配置 + Gateway + 舊版服務）。

選項：

- `--no-workspace-suggestions`：停用工作區記憶體提示。
- `--yes`：接受預設值而不提示（無頭模式）。
- `--non-interactive`：略過提示；僅套用安全遷移。
- `--deep`：掃描系統服務中的額外 Gateway 安裝。

## 頻道助手

### `channels`

管理聊天頻道帳戶（WhatsApp/Telegram/Discord/Google Chat/Slack/Mattermost (外掛)/Signal/iMessage/MS Teams）。

子指令：

- `channels list`：顯示已配置的頻道與認證設定檔。
- `channels status`：檢查 Gateway 可達性與頻道健康狀態（`--probe` 執行額外檢查；使用 `openclaw health` 或 `openclaw status --deep` 進行 Gateway 健康探針）。
- 提示：`channels status` 在偵測到常見設定錯誤時會列印警告及建議修復方案（並指向 `openclaw doctor`）。
- `channels logs`：顯示 Gateway 日誌檔案中最近的頻道日誌。
- `channels add`：未傳遞旗標時採用嚮導模式；傳遞旗標時切換至非互動模式。
- `channels remove`：預設停用；傳遞 `--delete` 以無提示移除配置項目。
- `channels login`：互動式頻道登入（僅 WhatsApp Web）。
- `channels logout`：從頻道會話登出（如支援）。

常見選項：

- `--channel <name>`：`whatsapp|telegram|discord|googlechat|slack|mattermost|signal|imessage|msteams`
- `--account <id>`：頻道帳戶 id（預設 `default`）
- `--name <label>`：帳戶顯示名稱

`channels login` 選項：

- `--channel <channel>` (預設 `whatsapp`；支援 `whatsapp`/`web`)
- `--account <id>`
- `--verbose`

`channels logout` 選項：

- `--channel <channel>` (預設 `whatsapp`)
- `--account <id>`

`channels list` 選項：

- `--no-usage`：略過模型供應商用量/配額快照（僅 OAuth/API 支援）。
- `--json`：輸出 JSON（除非設定 `--no-usage`，否則包括用量）。

`channels logs` 選項：

- `--channel <name|all>` (預設 `all`)
- `--lines <n>` (預設 `200`)
- `--json`

詳見 [/concepts/oauth](/concepts/oauth)

範例：

```bash
openclaw channels add --channel telegram --account alerts --name "Alerts Bot" --token $TELEGRAM_BOT_TOKEN
openclaw channels add --channel discord --account work --name "Work Bot" --token $DISCORD_BOT_TOKEN
openclaw channels remove --channel discord --account work --delete
openclaw channels status --probe
openclaw status --deep
```

### `skills`

列出及檢視可用技能與就緒狀態資訊。

子指令：

- `skills list`：列出技能（未指定子指令時的預設）。
- `skills info <name>`：顯示單個技能的詳細資訊。
- `skills check`：就緒與缺失需求的摘要。

選項：

- `--eligible`：僅顯示就緒的技能。
- `--json`：輸出 JSON（無樣式）。
- `-v`, `--verbose`：包括缺失需求詳情。

提示：使用 `npx clawhub` 搜尋、安裝及同步技能。

### `pairing`

跨頻道核准 DM 配對請求。

子指令：

- `pairing list <channel> [--json]`
- `pairing approve <channel> <code> [--notify]`

### `webhooks gmail`

Gmail Pub/Sub 鉤子設定與執行器。詳見 [/automation/gmail-pubsub](/automation/gmail-pubsub)。

子指令：

- `webhooks gmail setup` (必須 `--account <email>`；支援 `--project`、`--topic`、`--subscription`、`--label`、`--hook-url`、`--hook-token`、`--push-token`、`--bind`、`--port`、`--path`、`--include-body`、`--max-bytes`、`--renew-minutes`、`--tailscale`、`--tailscale-path`、`--tailscale-target`、`--push-endpoint`、`--json`)
- `webhooks gmail run` (相同旗標的執行時覆寫)

### `dns setup`

廣域發現 DNS 助手（CoreDNS + Tailscale）。詳見 [/gateway/discovery](/gateway/discovery)。

選項：

- `--apply`：安裝/更新 CoreDNS 配置（需要 sudo；僅 macOS）。

## 訊息與 Agent

### `message`

統一的出站訊息 + 頻道操作。

詳見：[/cli/message](/cli/message)

子指令：

- `message send|poll|react|reactions|read|edit|delete|pin|unpin|pins|permissions|search|timeout|kick|ban`
- `message thread <create|list|reply>`
- `message emoji <list|upload>`
- `message sticker <send|upload>`
- `message role <info|add|remove>`
- `message channel <info|list>`
- `message member info`
- `message voice status`
- `message event <list|create>`

範例：

- `openclaw message send --target +15555550123 --message "Hi"`
- `openclaw message poll --channel discord --target channel:123 --poll-question "Snack?" --poll-option Pizza --poll-option Sushi`

### `agent`

透過 Gateway 執行單次 Agent 運行（或使用 `--local` 嵌入式）。

必須：

- `--message <text>`

選項：

- `--to <dest>` (用於會話金鑰與選用遞送)
- `--session-id <id>`
- `--thinking <off|minimal|low|medium|high|xhigh>` (僅 GPT-5.2 + Codex 模型)
- `--verbose <on|full|off>`
- `--channel <whatsapp|telegram|discord|slack|mattermost|signal|imessage|msteams>`
- `--local`
- `--deliver`
- `--json`
- `--timeout <seconds>`

### `agents`

管理隔離的 Agent（工作區 + 認證 + 路由）。

#### `agents list`

列出已配置的 Agent。

選項：

- `--json`
- `--bindings`

#### `agents add [name]`

新增隔離的 Agent。除非傳遞旗標（或 `--non-interactive`），否則執行引導嚮導；非互動模式下 `--workspace` 為必須。

選項：

- `--workspace <dir>`
- `--model <id>`
- `--agent-dir <dir>`
- `--bind <channel[:accountId]>` (可重複)
- `--non-interactive`
- `--json`

綁定規格使用 `channel[:accountId]`。為 WhatsApp 省略 `accountId` 時，將使用預設帳戶 id。

#### `agents delete <id>`

刪除 Agent 及清除其工作區 + 狀態。

選項：

- `--force`
- `--json`

### `acp`

執行將 IDE 連接至 Gateway 的 ACP 橋接器。

詳見 [`acp`](/cli/acp) 的完整選項與範例。

### `status`

顯示已連結會話的健康狀況與最近收件人。

選項：

- `--json`
- `--all` (完整診斷；唯讀、可貼上)
- `--deep` (探針頻道)
- `--usage` (顯示模型供應商用量/配額)
- `--timeout <ms>`
- `--verbose`
- `--debug` (別名 `--verbose`)

注意：

- 概覽在可用時包括 Gateway + 節點主機服務狀態。

### 用量追蹤

當 OAuth/API 認證可用時，OpenClaw 可顯示供應商用量/配額。

呈現表面：

- `/status` (可用時新增簡短供應商用量行)
- `openclaw status --usage` (列印完整供應商分解)
- macOS 選單欄 (Context 下的用量區段)

注意：

- 資料直接來自供應商用量端點（無估計）。
- 供應商：Anthropic、GitHub Copilot、OpenAI Codex OAuth，加上啟用相關供應商外掛時的 Gemini CLI/Antigravity。
- 若無匹配認證，用量將隱藏。
- 詳見 [用量追蹤](/concepts/usage-tracking)。

### `health`

從運行中的 Gateway 獲取健康狀態。

選項：

- `--json`
- `--timeout <ms>`
- `--verbose`

### `sessions`

列出已儲存的對話會話。

選項：

- `--json`
- `--verbose`
- `--store <path>`
- `--active <minutes>`

## 重設 / 解除安裝

### `reset`

重設本地配置/狀態（保留已安裝的 CLI）。

選項：

- `--scope <config|config+creds+sessions|full>`
- `--yes`
- `--non-interactive`
- `--dry-run`

注意：

- `--non-interactive` 需要 `--scope` 與 `--yes`。

### `uninstall`

解除安裝 Gateway 服務 + 本地資料（CLI 保留）。

選項：

- `--service`
- `--state`
- `--workspace`
- `--app`
- `--all`
- `--yes`
- `--non-interactive`
- `--dry-run`

注意：

- `--non-interactive` 需要 `--yes` 與明確的範圍（或 `--all`）。

## Gateway

### `gateway`

執行 WebSocket Gateway。

選項：

- `--port <port>`：WebSocket 埠位。
- `--bind <loopback|tailnet|lan|auto|custom>`：監聽綁定模式。
- `--token <token>`：權杖。
- `--auth <token|password>`：認證模式。
- `--password <password>`：密碼。
- `--tailscale <off|serve|funnel>`：透過 Tailscale 暴露。
- `--tailscale-reset-on-exit`：關閉時重設 Tailscale serve/funnel。
- `--allow-unconfigured`：允許未配置時啟動。
- `--dev`：建立開發配置與認證。
- `--reset` (重設開發配置 + 憑證 + 會話 + 工作區)
- `--force` (強制殺死既有監聽程式)
- `--verbose`
- `--claude-cli-logs`
- `--ws-log <auto|full|compact>`
- `--compact` (別名 `--ws-log compact`)
- `--raw-stream`
- `--raw-stream-path <path>`

### `gateway service`

管理 Gateway 服務（launchd/systemd/schtasks）。

子指令：

- `gateway status` (預設探針 Gateway RPC)
- `gateway install` (服務安裝)
- `gateway uninstall`
- `gateway start`
- `gateway stop`
- `gateway restart`

注意：

- `gateway status` 預設使用服務解析的埠位/配置探針 Gateway RPC（使用 `--url/--token/--password` 覆寫）。
- `gateway status` 支援 `--no-probe`、`--deep` 及 `--json` 以用於指令化。
- `gateway status` 也會顯示舊版或額外 Gateway 服務（`--deep` 新增系統層級掃描）。設定檔名稱的 OpenClaw 服務被視為一級且不被標記為「額外」。
- `gateway status` 列印 CLI 使用的配置路徑對上服務可能使用的配置（服務環境），加上解析的探針目標 URL。
- `gateway install|uninstall|start|stop|restart` 支援 `--json` 用於指令化（預設輸出保持人類友善）。
- `gateway install` 預設為 Node 執行環境；bun **不建議**（WhatsApp/Telegram 漏洞）。
- `gateway install` 選項：`--port`、`--runtime`、`--token`、`--force`、`--json`。

### `logs`

透過 RPC 追蹤 Gateway 檔案日誌。

注意：

- TTY 會話呈現色彩化、結構化檢視；非 TTY 退回至純文字。
- `--json` 發送行分隔的 JSON（每行一個日誌事件）。

範例：

```bash
openclaw logs --follow
openclaw logs --limit 200
openclaw logs --plain
openclaw logs --json
openclaw logs --no-color
```

### `gateway <subcommand>`

Gateway CLI 助手（RPC 子指令使用 `--url`、`--token`、`--password`、`--timeout`、`--expect-final`）。

子指令：

- `gateway call <method> [--params <json>]`
- `gateway health`
- `gateway status`
- `gateway probe`
- `gateway discover`
- `gateway install|uninstall|start|stop|restart`
- `gateway run`

常見 RPC：

- `config.apply` (驗證 + 寫入配置 + 重啟 + 喚醒)
- `config.patch` (合併部分更新 + 重啟 + 喚醒)
- `update.run` (執行更新 + 重啟 + 喚醒)

提示：直接呼叫 `config.set`/`config.apply`/`config.patch` 時，若配置已存在，請從 `config.get` 傳遞 `baseHash`。

## 模型

詳見 [/concepts/models](/concepts/models) 關於退回行為與掃描策略。

偏好的 Anthropic 認證（setup-token）：

```bash
claude setup-token
openclaw models auth setup-token --provider anthropic
openclaw models status
```

### `models` (根)

`openclaw models` 為 `models status` 的別名。

根選項：

- `--status-json` (別名 `models status --json`)
- `--status-plain` (別名 `models status --plain`)

### `models list`

選項：

- `--all`
- `--local`
- `--provider <name>`
- `--json`
- `--plain`

### `models status`

選項：

- `--json`
- `--plain`
- `--check` (exit 1=已過期/缺失，2=即將過期)
- `--probe` (已配置認證設定檔的即時探針)
- `--probe-provider <name>`
- `--probe-profile <id>` (重複或逗號分隔)
- `--probe-timeout <ms>`
- `--probe-concurrency <n>`
- `--probe-max-tokens <n>`

始終包括認證概覽與認證儲存區中設定檔的 OAuth 過期狀態。
`--probe` 執行即時請求（可能消耗權杖並觸發速率限制）。

### `models set <model>`

設定 `agents.defaults.model.primary`。

### `models set-image <model>`

設定 `agents.defaults.imageModel.primary`。

### `models aliases list|add|remove`

選項：

- `list`：`--json`、`--plain`
- `add <alias> <model>`
- `remove <alias>`

### `models fallbacks list|add|remove|clear`

選項：

- `list`：`--json`、`--plain`
- `add <model>`
- `remove <model>`
- `clear`

### `models image-fallbacks list|add|remove|clear`

選項：

- `list`：`--json`、`--plain`
- `add <model>`
- `remove <model>`
- `clear`

### `models scan`

選項：

- `--min-params <b>`
- `--max-age-days <days>`
- `--provider <name>`
- `--max-candidates <n>`
- `--timeout <ms>`
- `--concurrency <n>`
- `--no-probe`
- `--yes`
- `--no-input`
- `--set-default`
- `--set-image`
- `--json`

### `models auth add|setup-token|paste-token`

選項：

- `add`：互動式認證助手
- `setup-token`：`--provider <name>` (預設 `anthropic`)、`--yes`
- `paste-token`：`--provider <name>`、`--profile-id <id>`、`--expires-in <duration>`

### `models auth order get|set|clear`

選項：

- `get`：`--provider <name>`、`--agent <id>`、`--json`
- `set`：`--provider <name>`、`--agent <id>`、`<profileIds...>`
- `clear`：`--provider <name>`、`--agent <id>`

## 系統

### `system event`

排隊系統事件並可選觸發心跳（Gateway RPC）。

必須：

- `--text <text>`

選項：

- `--mode <now|next-heartbeat>`
- `--json`
- `--url`、`--token`、`--timeout`、`--expect-final`

### `system heartbeat last|enable|disable`

心跳控制（Gateway RPC）。

選項：

- `--json`
- `--url`、`--token`、`--timeout`、`--expect-final`

### `system presence`

列出系統在場項目（Gateway RPC）。

選項：

- `--json`
- `--url`、`--token`、`--timeout`、`--expect-final`

## 排程 (Cron)

管理排程工作（Gateway RPC）。詳見 [/automation/cron-jobs](/automation/cron-jobs)。

子指令：

- `cron status [--json]`
- `cron list [--all] [--json]` (預設表格輸出；使用 `--json` 獲得原始資料)
- `cron add` (別名：`create`；需要 `--name` 與恰好其中一個 `--at` | `--every` | `--cron`，與恰好其中一個有效負載 `--system-event` | `--message`)
- `cron edit <id>` (修補欄位)
- `cron rm <id>` (別名：`remove`、`delete`)
- `cron enable <id>`
- `cron disable <id>`
- `cron runs --id <id> [--limit <n>]`
- `cron run <id> [--force]`

所有 `cron` 指令接受 `--url`、`--token`、`--timeout`、`--expect-final`。

## 節點主機

`node` 執行**無頭節點主機**或將其作為背景服務管理。詳見 [`openclaw node`](/cli/node)。

子指令：

- `node run --host <gateway-host> --port 18789`
- `node status`
- `node install [--host <gateway-host>] [--port <port>] [--tls] [--tls-fingerprint <sha256>] [--node-id <id>] [--display-name <name>] [--runtime <node|bun>] [--force]`
- `node uninstall`
- `node stop`
- `node restart`

## 節點

`nodes` 與 Gateway 通訊並針對配對節點。詳見 [/nodes](/nodes)。

常見選項：

- `--url`、`--token`、`--timeout`、`--json`

子指令：

- `nodes status [--connected] [--last-connected <duration>]`
- `nodes describe --node <id|name|ip>`
- `nodes list [--connected] [--last-connected <duration>]`
- `nodes pending`
- `nodes approve <requestId>`
- `nodes reject <requestId>`
- `nodes rename --node <id|name|ip> --name <displayName>`
- `nodes invoke --node <id|name|ip> --command <command> [--params <json>] [--invoke-timeout <ms>] [--idempotency-key <key>]`
- `nodes run --node <id|name|ip> [--cwd <path>] [--env KEY=VAL] [--command-timeout <ms>] [--needs-screen-recording] [--invoke-timeout <ms>] <command...>` (Mac 節點或無頭節點主機)
- `nodes notify --node <id|name|ip> [--title <text>] [--body <text>] [--sound <name>] [--priority <passive|active|timeSensitive>] [--delivery <system|overlay|auto>] [--invoke-timeout <ms>]` (僅 Mac)

相機：

- `nodes camera list --node <id|name|ip>`
- `nodes camera snap --node <id|name|ip> [--facing front|back|both] [--device-id <id>] [--max-width <px>] [--quality <0-1>] [--delay-ms <ms>] [--invoke-timeout <ms>]`
- `nodes camera clip --node <id|name|ip> [--facing front|back] [--device-id <id>] [--duration <ms|10s|1m>] [--no-audio] [--invoke-timeout <ms>]`

Canvas + 螢幕：

- `nodes canvas snapshot --node <id|name|ip> [--format png|jpg|jpeg] [--max-width <px>] [--quality <0-1>] [--invoke-timeout <ms>]`
- `nodes canvas present --node <id|name|ip> [--target <urlOrPath>] [--x <px>] [--y <px>] [--width <px>] [--height <px>] [--invoke-timeout <ms>]`
- `nodes canvas hide --node <id|name|ip> [--invoke-timeout <ms>]`
- `nodes canvas navigate <url> --node <id|name|ip> [--invoke-timeout <ms>]`
- `nodes canvas eval [<js>] --node <id|name|ip> [--js <code>] [--invoke-timeout <ms>]`
- `nodes canvas a2ui push --node <id|name|ip> (--jsonl <path> | --text <text>) [--invoke-timeout <ms>]`
- `nodes canvas a2ui reset --node <id|name|ip> [--invoke-timeout <ms>]`
- `nodes screen record --node <id|name|ip> [--screen <index>] [--duration <ms|10s>] [--fps <n>] [--no-audio] [--out <path>] [--invoke-timeout <ms>]`

位置：

- `nodes location get --node <id|name|ip> [--max-age <ms>] [--accuracy <coarse|balanced|precise>] [--location-timeout <ms>] [--invoke-timeout <ms>]`

## 瀏覽器

瀏覽器控制 CLI（專用 Chrome/Brave/Edge/Chromium）。詳見 [`openclaw browser`](/cli/browser) 與 [瀏覽器工具](/tools/browser)。

常見選項：

- `--url`、`--token`、`--timeout`、`--json`
- `--browser-profile <name>`

管理：

- `browser status`
- `browser start`
- `browser stop`
- `browser reset-profile`
- `browser tabs`
- `browser open <url>`
- `browser focus <targetId>`
- `browser close [targetId]`
- `browser profiles`
- `browser create-profile --name <name> [--color <hex>] [--cdp-url <url>]`
- `browser delete-profile --name <name>`

檢視：

- `browser screenshot [targetId] [--full-page] [--ref <ref>] [--element <selector>] [--type png|jpeg]`
- `browser snapshot [--format aria|ai] [--target-id <id>] [--limit <n>] [--interactive] [--compact] [--depth <n>] [--selector <sel>] [--out <path>]`

操作：

- `browser navigate <url> [--target-id <id>]`
- `browser resize <width> <height> [--target-id <id>]`
- `browser click <ref> [--double] [--button <left|right|middle>] [--modifiers <csv>] [--target-id <id>]`
- `browser type <ref> <text> [--submit] [--slowly] [--target-id <id>]`
- `browser press <key> [--target-id <id>]`
- `browser hover <ref> [--target-id <id>]`
- `browser drag <startRef> <endRef> [--target-id <id>]`
- `browser select <ref> <values...> [--target-id <id>]`
- `browser upload <paths...> [--ref <ref>] [--input-ref <ref>] [--element <selector>] [--target-id <id>] [--timeout-ms <ms>]`
- `browser fill [--fields <json>] [--fields-file <path>] [--target-id <id>]`
- `browser dialog --accept|--dismiss [--prompt <text>] [--target-id <id>] [--timeout-ms <ms>]`
- `browser wait [--time <ms>] [--text <value>] [--text-gone <value>] [--target-id <id>]`
- `browser evaluate --fn <code> [--ref <ref>] [--target-id <id>]`
- `browser console [--level <error|warn|info>] [--target-id <id>]`
- `browser pdf [--target-id <id>]`

## 文件搜尋

### `docs [query...]`

搜尋即時文件索引。

## TUI

### `tui`

開啟連接至 Gateway 的終端機使用者介面。

選項：

- `--url <url>`
- `--token <token>`
- `--password <password>`
- `--session <key>`
- `--deliver`
- `--thinking <level>`
- `--message <text>`
- `--timeout-ms <ms>` (預設 `agents.defaults.timeoutSeconds`)
- `--history-limit <n>`
