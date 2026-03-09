---
summary: "OpenClaw CLI 的 `openclaw` 指令、子指令與選項參考"
read_when:
  - 新增或修改 CLI 指令或選項
  - 記錄新指令介面
title: "CLI Reference（CLI 參考手冊）"
---

# CLI 參考手冊

本頁說明目前的 CLI 行為。若指令有異動，請更新本文件。

## 指令頁面

- [`setup`](/zh-Hant/cli/setup)
- [`onboard`](/zh-Hant/cli/onboard)
- [`configure`](/zh-Hant/cli/configure)
- [`config`](/zh-Hant/cli/config)
- [`completion`](/zh-Hant/cli/completion)
- [`doctor`](/zh-Hant/cli/doctor)
- [`dashboard`](/zh-Hant/cli/dashboard)
- [`backup`](/zh-Hant/cli/backup)
- [`reset`](/zh-Hant/cli/reset)
- [`uninstall`](/zh-Hant/cli/uninstall)
- [`update`](/zh-Hant/cli/update)
- [`message`](/zh-Hant/cli/message)
- [`agent`](/zh-Hant/cli/agent)
- [`agents`](/zh-Hant/cli/agents)
- [`acp`](/zh-Hant/cli/acp)
- [`status`](/zh-Hant/cli/status)
- [`health`](/zh-Hant/cli/health)
- [`sessions`](/zh-Hant/cli/sessions)
- [`gateway`](/zh-Hant/cli/gateway)
- [`logs`](/zh-Hant/cli/logs)
- [`system`](/zh-Hant/cli/system)
- [`models`](/zh-Hant/cli/models)
- [`memory`](/zh-Hant/cli/memory)
- [`directory`](/zh-Hant/cli/directory)
- [`nodes`](/zh-Hant/cli/nodes)
- [`devices`](/zh-Hant/cli/devices)
- [`node`](/zh-Hant/cli/node)
- [`approvals`](/zh-Hant/cli/approvals)
- [`sandbox`](/zh-Hant/cli/sandbox)
- [`tui`](/zh-Hant/cli/tui)
- [`browser`](/zh-Hant/cli/browser)
- [`cron`](/zh-Hant/cli/cron)
- [`dns`](/zh-Hant/cli/dns)
- [`docs`](/zh-Hant/cli/docs)
- [`hooks`](/zh-Hant/cli/hooks)
- [`webhooks`](/zh-Hant/cli/webhooks)
- [`pairing`](/zh-Hant/cli/pairing)
- [`qr`](/zh-Hant/cli/qr)
- [`plugins`](/zh-Hant/cli/plugins)（外掛指令）
- [`channels`](/zh-Hant/cli/channels)
- [`security`](/zh-Hant/cli/security)
- [`secrets`](/zh-Hant/cli/secrets)
- [`skills`](/zh-Hant/cli/skills)
- [`daemon`](/zh-Hant/cli/daemon)（gateway 服務指令的舊別名）
- [`clawbot`](/zh-Hant/cli/clawbot)（舊別名命名空間）
- [`voicecall`](/zh-Hant/cli/voicecall)（外掛；若已安裝）

## 全域旗標

- `--dev`：將狀態隔離在 `~/.openclaw-dev` 並調整預設埠號。
- `--profile <name>`：將狀態隔離在 `~/.openclaw-<name>`。
- `--no-color`：停用 ANSI 顏色。
- `--update`：`openclaw update` 的快捷方式（僅限原始碼安裝）。
- `-V`、`--version`、`-v`：顯示版本並退出。

## 輸出樣式

- ANSI 顏色與進度指示器僅在 TTY 工作階段中渲染。
- OSC-8 超連結在支援的終端機中顯示為可點擊連結；否則退回純 URL。
- `--json`（以及部分支援的 `--plain`）停用樣式以取得乾淨輸出。
- `--no-color` 停用 ANSI 樣式；`NO_COLOR=1` 也同樣有效。
- 長時間執行的指令會顯示進度指示器（支援時使用 OSC 9;4）。

## 色彩調色盤

OpenClaw 在 CLI 輸出中使用龍蝦色調色盤。

- `accent`（#FF5A2D）：標題、標籤、主要重點。
- `accentBright`（#FF7A3D）：指令名稱、強調。
- `accentDim`（#D14A22）：次要重點文字。
- `info`（#FF8A5B）：資訊性數值。
- `success`（#2FBF71）：成功狀態。
- `warn`（#FFB020）：警告、退路、注意。
- `error`（#E23D2D）：錯誤、失敗。
- `muted`（#8B7F77）：去強調、metadata。

調色盤真實來源：`src/terminal/palette.ts`（亦稱「龍蝦接縫」）。

## 指令樹

```
openclaw [--dev] [--profile <name>] <command>
  setup
  onboard
  configure
  config
    get
    set
    unset
  completion
  doctor
  dashboard
  backup
    create
    verify
  security
    audit
  secrets
    reload
    migrate
  reset
  uninstall
  update
  channels
    list
    status
    logs
    add
    remove
    login
    logout
  directory
  skills
    list
    info
    check
  plugins
    list
    info
    install
    enable
    disable
    doctor
  memory
    status
    index
    search
  message
  agent
  agents
    list
    add
    delete
  acp
  status
  health
  sessions
  gateway
    call
    health
    status
    probe
    discover
    install
    uninstall
    start
    stop
    restart
    run
  daemon
    status
    install
    uninstall
    start
    stop
    restart
  logs
  system
    event
    heartbeat last|enable|disable
    presence
  models
    list
    status
    set
    set-image
    aliases list|add|remove
    fallbacks list|add|remove|clear
    image-fallbacks list|add|remove|clear
    scan
    auth add|setup-token|paste-token
    auth order get|set|clear
  sandbox
    list
    recreate
    explain
  cron
    status
    list
    add
    edit
    rm
    enable
    disable
    runs
    run
  nodes
  devices
  node
    run
    status
    install
    uninstall
    start
    stop
    restart
  approvals
    get
    set
    allowlist add|remove
  browser
    status
    start
    stop
    reset-profile
    tabs
    open
    focus
    close
    profiles
    create-profile
    delete-profile
    screenshot
    snapshot
    navigate
    resize
    click
    type
    press
    hover
    drag
    select
    upload
    fill
    dialog
    wait
    evaluate
    console
    pdf
  hooks
    list
    info
    check
    enable
    disable
    install
    update
  webhooks
    gmail setup|run
  pairing
    list
    approve
  qr
  clawbot
    qr
  docs
  dns
    setup
  tui
```

注意：外掛可新增額外的頂層指令（例如 `openclaw voicecall`）。

## 安全性

- `openclaw security audit` — 審核組態與本地狀態中的常見安全陷阱。
- `openclaw security audit --deep` — 盡力執行即時 Gateway 探測。
- `openclaw security audit --fix` — 收緊安全預設值並調整狀態/組態的檔案權限。

## Secrets

- `openclaw secrets reload` — 重新解析參照並以原子方式替換執行期快照。
- `openclaw secrets audit` — 掃描明文殘留、未解析參照及優先順序漂移。
- `openclaw secrets configure` — 供應商設定、SecretRef 對映及預檢/套用的互動式協助工具。
- `openclaw secrets apply --from <plan.json>` — 套用先前產生的計畫（支援 `--dry-run`）。

## Plugins（外掛）

管理擴充功能及其組態：

- `openclaw plugins list` — 探索外掛（使用 `--json` 取得機器可讀輸出）。
- `openclaw plugins info <id>` — 顯示外掛詳細資訊。
- `openclaw plugins install <path|.tgz|npm-spec>` — 安裝外掛（或將外掛路徑加入 `plugins.load.paths`）。
- `openclaw plugins enable <id>` / `disable <id>` — 切換 `plugins.entries.<id>.enabled`。
- `openclaw plugins doctor` — 回報外掛載入錯誤。

大多數外掛變更需要重新啟動 gateway。參見 [/plugin](/zh-Hant/tools/plugin)。

## Memory（記憶體）

對 `MEMORY.md` 與 `memory/*.md` 進行向量搜尋：

- `openclaw memory status` — 顯示索引統計。
- `openclaw memory index` — 重新索引記憶體檔案。
- `openclaw memory search "<query>"`（或 `--query "<query>"`）— 對記憶體進行語意搜尋。

## 聊天斜線指令

聊天訊息支援 `/...` 指令（文字與原生）。參見 [/tools/slash-commands](/zh-Hant/tools/slash-commands)。

重點：

- `/status` 快速診斷。
- `/config` 持久化組態變更。
- `/debug` 僅限執行期組態覆蓋（記憶體，不寫磁碟；需要 `commands.debug: true`）。

## 設定 + 上手引導

### `setup`

初始化組態與工作區。

選項：

- `--workspace <dir>`：Agent 工作區路徑（預設 `~/.openclaw/workspace`）。
- `--wizard`：執行上手引導精靈。
- `--non-interactive`：無提示執行精靈。
- `--mode <local|remote>`：精靈模式。
- `--remote-url <url>`：遠端 Gateway URL。
- `--remote-token <token>`：遠端 Gateway token。

當任何精靈旗標存在時（`--non-interactive`、`--mode`、`--remote-url`、`--remote-token`），精靈會自動執行。

### `onboard`

互動式精靈，設定 gateway、工作區和 skills。

選項：

- `--workspace <dir>`
- `--reset`（在精靈前重置組態 + 憑證 + 工作階段）
- `--reset-scope <config|config+creds+sessions|full>`（預設 `config+creds+sessions`；使用 `full` 可同時移除工作區）
- `--non-interactive`
- `--mode <local|remote>`
- `--flow <quickstart|advanced|manual>`（manual 是 advanced 的別名）
- `--auth-choice <setup-token|token|chutes|openai-codex|openai-api-key|openrouter-api-key|ai-gateway-api-key|moonshot-api-key|moonshot-api-key-cn|kimi-code-api-key|synthetic-api-key|venice-api-key|gemini-api-key|zai-api-key|mistral-api-key|apiKey|minimax-api|minimax-api-lightning|opencode-zen|custom-api-key|skip>`
- `--token-provider <id>`（非互動式；與 `--auth-choice token` 搭配使用）
- `--token <token>`（非互動式；與 `--auth-choice token` 搭配使用）
- `--token-profile-id <id>`（非互動式；預設：`<provider>:manual`）
- `--token-expires-in <duration>`（非互動式；例如 `365d`、`12h`）
- `--secret-input-mode <plaintext|ref>`（預設 `plaintext`；使用 `ref` 儲存供應商預設環境參照而非明文金鑰）
- `--anthropic-api-key <key>`
- `--openai-api-key <key>`
- `--mistral-api-key <key>`
- `--openrouter-api-key <key>`
- `--ai-gateway-api-key <key>`
- `--moonshot-api-key <key>`
- `--kimi-code-api-key <key>`
- `--gemini-api-key <key>`
- `--zai-api-key <key>`
- `--minimax-api-key <key>`
- `--opencode-zen-api-key <key>`
- `--custom-base-url <url>`（非互動式；與 `--auth-choice custom-api-key` 搭配使用）
- `--custom-model-id <id>`（非互動式；與 `--auth-choice custom-api-key` 搭配使用）
- `--custom-api-key <key>`（非互動式；選用；與 `--auth-choice custom-api-key` 搭配使用；省略時退回 `CUSTOM_API_KEY`）
- `--custom-provider-id <id>`（非互動式；選用自訂供應商 ID）
- `--custom-compatibility <openai|anthropic>`（非互動式；選用；預設 `openai`）
- `--gateway-port <port>`
- `--gateway-bind <loopback|lan|tailnet|auto|custom>`
- `--gateway-auth <token|password>`
- `--gateway-token <token>`
- `--gateway-token-ref-env <name>`（非互動式；將 `gateway.auth.token` 儲存為環境 SecretRef；需要已設定該環境變數；不可與 `--gateway-token` 合併使用）
- `--gateway-password <password>`
- `--remote-url <url>`
- `--remote-token <token>`
- `--tailscale <off|serve|funnel>`
- `--tailscale-reset-on-exit`
- `--install-daemon`
- `--no-install-daemon`（別名：`--skip-daemon`）
- `--daemon-runtime <node|bun>`
- `--skip-channels`
- `--skip-skills`
- `--skip-health`
- `--skip-ui`
- `--node-manager <npm|pnpm|bun>`（建議 pnpm；不建議 bun 作為 Gateway 執行期）
- `--json`

### `configure`

互動式組態精靈（模型、頻道、skills、gateway）。

### `config`

非互動式組態輔助工具（get/set/unset/file/validate）。執行 `openclaw config` 而不加子指令時會啟動精靈。

子指令：

- `config get <path>`：顯示組態值（點/括號路徑）。
- `config set <path> <value>`：設定值（JSON5 或原始字串）。
- `config unset <path>`：移除值。
- `config file`：顯示目前有效組態檔路徑。
- `config validate`：在不啟動 gateway 的情況下，根據 schema 驗證目前組態。
- `config validate --json`：輸出機器可讀的 JSON。

### `doctor`

健康檢查 + 快速修復（組態 + gateway + 舊服務）。

選項：

- `--no-workspace-suggestions`：停用工作區記憶體提示。
- `--yes`：無提示接受預設（無頭模式）。
- `--non-interactive`：跳過提示；僅套用安全遷移。
- `--deep`：掃描系統服務以找出額外的 gateway 安裝。

## 頻道輔助工具

### `channels`

管理聊天頻道帳號（WhatsApp/Telegram/Discord/Google Chat/Slack/Mattermost（外掛）/Signal/iMessage/MS Teams）。

子指令：

- `channels list`：顯示已設定的頻道與認證 profile。
- `channels status`：檢查 gateway 可達性與頻道健康狀態（`--probe` 執行額外檢查；使用 `openclaw health` 或 `openclaw status --deep` 進行 gateway 健康探測）。
- 提示：`channels status` 在偵測到常見設定錯誤時，會列印帶有建議修復方案的警告（然後指向 `openclaw doctor`）。
- `channels logs`：從 gateway 日誌檔顯示近期頻道日誌。
- `channels add`：未傳入旗標時為精靈式設定；旗標會切換至非互動式模式。
  - 將非預設帳號新增至仍使用單帳號頂層組態的頻道時，OpenClaw 會在寫入新帳號前，將帳號範圍的值移至 `channels.<channel>.accounts.default`。
  - 非互動式的 `channels add` 不會自動建立/升級繫結；頻道專屬繫結會繼續與預設帳號對應。
- `channels remove`：預設停用；傳入 `--delete` 可不顯示提示地移除組態條目。
- `channels login`：互動式頻道登入（僅限 WhatsApp Web）。
- `channels logout`：登出頻道工作階段（若支援）。

常用選項：

- `--channel <name>`：`whatsapp|telegram|discord|googlechat|slack|mattermost|signal|imessage|msteams`
- `--account <id>`：頻道帳號 ID（預設 `default`）
- `--name <label>`：帳號的顯示名稱

`channels login` 選項：

- `--channel <channel>`（預設 `whatsapp`；支援 `whatsapp`/`web`）
- `--account <id>`
- `--verbose`

`channels logout` 選項：

- `--channel <channel>`（預設 `whatsapp`）
- `--account <id>`

`channels list` 選項：

- `--no-usage`：跳過模型供應商使用量/配額快照（僅限 OAuth/API 支援）。
- `--json`：輸出 JSON（除非設定 `--no-usage`，否則包含使用量）。

`channels logs` 選項：

- `--channel <name|all>`（預設 `all`）
- `--lines <n>`（預設 `200`）
- `--json`

更多詳情：[/concepts/oauth](/zh-Hant/concepts/oauth)

範例：

```bash
openclaw channels add --channel telegram --account alerts --name "Alerts Bot" --token $TELEGRAM_BOT_TOKEN
openclaw channels add --channel discord --account work --name "Work Bot" --token $DISCORD_BOT_TOKEN
openclaw channels remove --channel discord --account work --delete
openclaw channels status --probe
openclaw status --deep
```

### `skills`

列出並查看可用的 skills 及其就緒資訊。

子指令：

- `skills list`：列出 skills（未指定子指令時的預設行為）。
- `skills info <name>`：顯示單一 skill 的詳細資訊。
- `skills check`：顯示已就緒與缺少需求的摘要。

選項：

- `--eligible`：僅顯示已就緒的 skills。
- `--json`：輸出 JSON（無樣式）。
- `-v`、`--verbose`：包含缺少需求的詳細資訊。

提示：使用 `npx clawhub` 搜尋、安裝和同步 skills。

### `pairing`

跨頻道核准 DM 配對請求。

子指令：

- `pairing list [channel] [--channel <channel>] [--account <id>] [--json]`
- `pairing approve <channel> <code> [--account <id>] [--notify]`
- `pairing approve --channel <channel> [--account <id>] <code> [--notify]`

### `devices`

管理 gateway 裝置配對條目與每個角色的裝置 token。

子指令：

- `devices list [--json]`
- `devices approve [requestId] [--latest]`
- `devices reject <requestId>`
- `devices remove <deviceId>`
- `devices clear --yes [--pending]`
- `devices rotate --device <id> --role <role> [--scope <scope...>]`
- `devices revoke --device <id> --role <role>`

### `webhooks gmail`

Gmail Pub/Sub hook 設定 + 執行器。參見 [/automation/gmail-pubsub](/zh-Hant/automation/gmail-pubsub)。

子指令：

- `webhooks gmail setup`（需要 `--account <email>`；支援 `--project`、`--topic`、`--subscription`、`--label`、`--hook-url`、`--hook-token`、`--push-token`、`--bind`、`--port`、`--path`、`--include-body`、`--max-bytes`、`--renew-minutes`、`--tailscale`、`--tailscale-path`、`--tailscale-target`、`--push-endpoint`、`--json`）
- `webhooks gmail run`（相同旗標的執行期覆蓋）

### `dns setup`

廣域探索 DNS 輔助工具（CoreDNS + Tailscale）。參見 [/gateway/discovery](/zh-Hant/gateway/discovery)。

選項：

- `--apply`：安裝/更新 CoreDNS 組態（需要 sudo；僅限 macOS）。

## 訊息傳遞 + Agent

### `message`

統一的對外訊息傳遞 + 頻道操作。

參見：[/cli/message](/zh-Hant/cli/message)

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

透過 Gateway（或 `--local` 嵌入式）執行一次 agent 回合。

必要參數：

- `--message <text>`

選項：

- `--to <dest>`（用於工作階段金鑰和選用的傳遞）
- `--session-id <id>`
- `--thinking <off|minimal|low|medium|high|xhigh>`（僅限 GPT-5.2 + Codex 模型）
- `--verbose <on|full|off>`
- `--channel <whatsapp|telegram|discord|slack|mattermost|signal|imessage|msteams>`
- `--local`
- `--deliver`
- `--json`
- `--timeout <seconds>`

### `agents`

管理隔離的 agents（工作區 + 認證 + 路由）。

#### `agents list`

列出已設定的 agents。

選項：

- `--json`
- `--bindings`

#### `agents add [name]`

新增一個隔離的 agent。除非傳入旗標（或 `--non-interactive`），否則執行引導精靈；非互動模式需要 `--workspace`。

選項：

- `--workspace <dir>`
- `--model <id>`
- `--agent-dir <dir>`
- `--bind <channel[:accountId]>`（可重複）
- `--non-interactive`
- `--json`

繫結規格使用 `channel[:accountId]`。省略 `accountId` 時，OpenClaw 可能透過頻道預設/外掛 hook 解析帳號範圍；否則為不含明確帳號範圍的頻道繫結。

#### `agents bindings`

列出路由繫結。

選項：

- `--agent <id>`
- `--json`

#### `agents bind`

為 agent 新增路由繫結。

選項：

- `--agent <id>`
- `--bind <channel[:accountId]>`（可重複）
- `--json`

#### `agents unbind`

移除 agent 的路由繫結。

選項：

- `--agent <id>`
- `--bind <channel[:accountId]>`（可重複）
- `--all`
- `--json`

#### `agents delete <id>`

刪除 agent 並清理其工作區 + 狀態。

選項：

- `--force`
- `--json`

### `acp`

執行連接 IDE 到 Gateway 的 ACP 橋接器。

完整選項和範例參見 [`acp`](/zh-Hant/cli/acp)。

### `status`

顯示連結工作階段的健康狀態和近期收件人。

選項：

- `--json`
- `--all`（完整診斷；唯讀，可貼上）
- `--deep`（探測頻道）
- `--usage`（顯示模型供應商使用量/配額）
- `--timeout <ms>`
- `--verbose`
- `--debug`（`--verbose` 的別名）

注意：

- 摘要在可取得時包含 Gateway + 節點主機服務狀態。

### 使用量追蹤

當 OAuth/API 憑證可用時，OpenClaw 可顯示供應商使用量/配額。

顯示位置：

- `/status`（可用時附上簡短供應商使用量行）
- `openclaw status --usage`（顯示完整供應商明細）
- macOS 選單列（Context 下的 Usage 區塊）

注意：

- 資料直接來自供應商使用量端點（無估算）。
- 供應商：Anthropic、GitHub Copilot、OpenAI Codex OAuth，以及啟用供應商外掛時的 Gemini CLI/Antigravity。
- 若無對應憑證，使用量不顯示。
- 詳情：參見 [使用量追蹤](/zh-Hant/concepts/usage-tracking)。

### `health`

從執行中的 Gateway 取得健康狀態。

選項：

- `--json`
- `--timeout <ms>`
- `--verbose`

### `sessions`

列出已儲存的對話工作階段。

選項：

- `--json`
- `--verbose`
- `--store <path>`
- `--active <minutes>`

## 重置 / 解除安裝

### `reset`

重置本地組態/狀態（CLI 保留安裝）。

選項：

- `--scope <config|config+creds+sessions|full>`
- `--yes`
- `--non-interactive`
- `--dry-run`

注意：

- `--non-interactive` 需要 `--scope` 和 `--yes`。

### `uninstall`

解除安裝 gateway 服務 + 本地資料（CLI 保留）。

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

- `--port <port>`
- `--bind <loopback|tailnet|lan|auto|custom>`
- `--token <token>`
- `--auth <token|password>`
- `--password <password>`
- `--password-file <path>`
- `--tailscale <off|serve|funnel>`
- `--tailscale-reset-on-exit`
- `--allow-unconfigured`
- `--dev`
- `--reset`（重置開發組態 + 憑證 + 工作階段 + 工作區）
- `--force`（強制終止埠號上的現有監聽器）
- `--verbose`
- `--claude-cli-logs`
- `--ws-log <auto|full|compact>`
- `--compact`（`--ws-log compact` 的別名）
- `--raw-stream`
- `--raw-stream-path <path>`

### `gateway service`

管理 Gateway 服務（launchd/systemd/schtasks）。

子指令：

- `gateway status`（預設探測 Gateway RPC）
- `gateway install`（服務安裝）
- `gateway uninstall`
- `gateway start`
- `gateway stop`
- `gateway restart`

注意：

- `gateway status` 預設使用服務已解析的埠號/組態探測 Gateway RPC（用 `--url/--token/--password` 覆蓋）。
- `gateway status` 支援 `--no-probe`、`--deep` 和 `--json` 供腳本使用。
- `gateway status` 也會在可偵測到舊版或額外 gateway 服務時列出（`--deep` 加入系統級掃描）。已命名 profile 的 OpenClaw 服務視為一等，不標記為「額外」。
- `gateway status` 顯示 CLI 使用的組態路徑與服務可能使用的組態（服務環境）的差異，以及已解析的探測目標 URL。
- 在 Linux systemd 安裝上，status token 漂移檢查同時涵蓋 `Environment=` 和 `EnvironmentFile=` unit 來源。
- `gateway install|uninstall|start|stop|restart` 支援 `--json` 供腳本使用（預設輸出保持人類友善格式）。
- `gateway install` 預設使用 Node 執行期；**不建議** bun（WhatsApp/Telegram 有問題）。
- `gateway install` 選項：`--port`、`--runtime`、`--token`、`--force`、`--json`。

### `logs`

透過 RPC 追蹤 Gateway 檔案日誌。

注意：

- TTY 工作階段渲染彩色結構化視圖；非 TTY 退回純文字。
- `--json` 輸出行分隔的 JSON（每行一個日誌事件）。

範例：

```bash
openclaw logs --follow
openclaw logs --limit 200
openclaw logs --plain
openclaw logs --json
openclaw logs --no-color
```

### `gateway <subcommand>`

Gateway CLI 輔助工具（RPC 子指令使用 `--url`、`--token`、`--password`、`--timeout`、`--expect-final`）。
傳入 `--url` 時，CLI 不會自動套用組態或環境憑證。
請明確包含 `--token` 或 `--password`。缺少明確憑證為錯誤。

子指令：

- `gateway call <method> [--params <json>]`
- `gateway health`
- `gateway status`
- `gateway probe`
- `gateway discover`
- `gateway install|uninstall|start|stop|restart`
- `gateway run`

常用 RPC：

- `config.apply`（驗證 + 寫入組態 + 重啟 + 喚醒）
- `config.patch`（合併部分更新 + 重啟 + 喚醒）
- `update.run`（執行更新 + 重啟 + 喚醒）

提示：直接呼叫 `config.set`/`config.apply`/`config.patch` 時，若組態已存在，請從 `config.get` 傳入 `baseHash`。

## 模型

參見 [/concepts/models](/zh-Hant/concepts/models) 了解退路行為和掃描策略。

Anthropic setup-token（已支援）：

```bash
claude setup-token
openclaw models auth setup-token --provider anthropic
openclaw models status
```

政策說明：此為技術相容性。Anthropic 過去曾封鎖某些在 Claude Code 之外的訂閱用量；在生產環境依賴 setup-token 前，請確認目前的 Anthropic 條款。

### `models`（根）

`openclaw models` 是 `models status` 的別名。

根選項：

- `--status-json`（`models status --json` 的別名）
- `--status-plain`（`models status --plain` 的別名）

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
- `--check`（退出碼：1=已過期/缺少，2=即將過期）
- `--probe`（對已設定的認證 profile 執行即時探測）
- `--probe-provider <name>`
- `--probe-profile <id>`（重複或以逗號分隔）
- `--probe-timeout <ms>`
- `--probe-concurrency <n>`
- `--probe-max-tokens <n>`

始終包含認證總覽與認證儲存中 profile 的 OAuth 到期狀態。
`--probe` 執行即時請求（可能消耗 token 並觸發速率限制）。

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

- `add`：互動式認證輔助工具
- `setup-token`：`--provider <name>`（預設 `anthropic`）、`--yes`
- `paste-token`：`--provider <name>`、`--profile-id <id>`、`--expires-in <duration>`

### `models auth order get|set|clear`

選項：

- `get`：`--provider <name>`、`--agent <id>`、`--json`
- `set`：`--provider <name>`、`--agent <id>`、`<profileIds...>`
- `clear`：`--provider <name>`、`--agent <id>`

## 系統

### `system event`

排入系統事件並選擇性觸發心跳（Gateway RPC）。

必要參數：

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

列出系統 presence 條目（Gateway RPC）。

選項：

- `--json`
- `--url`、`--token`、`--timeout`、`--expect-final`

## Cron

管理排程工作（Gateway RPC）。參見 [/automation/cron-jobs](/zh-Hant/automation/cron-jobs)。

子指令：

- `cron status [--json]`
- `cron list [--all] [--json]`（預設表格輸出；使用 `--json` 取得原始資料）
- `cron add`（別名：`create`；需要 `--name` 且恰好一個 `--at` | `--every` | `--cron`，以及恰好一個 `--system-event` | `--message` 負載）
- `cron edit <id>`（修補欄位）
- `cron rm <id>`（別名：`remove`、`delete`）
- `cron enable <id>`
- `cron disable <id>`
- `cron runs --id <id> [--limit <n>]`
- `cron run <id> [--force]`

所有 `cron` 指令接受 `--url`、`--token`、`--timeout`、`--expect-final`。

## 節點主機

`node` 執行**無頭節點主機**或將其作為背景服務管理。參見
[`openclaw node`](/zh-Hant/cli/node)。

子指令：

- `node run --host <gateway-host> --port 18789`
- `node status`
- `node install [--host <gateway-host>] [--port <port>] [--tls] [--tls-fingerprint <sha256>] [--node-id <id>] [--display-name <name>] [--runtime <node|bun>] [--force]`
- `node uninstall`
- `node stop`
- `node restart`

認證說明：

- `node` 從環境/組態解析 gateway 認證（無 `--token`/`--password` 旗標）：`OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`，然後是 `gateway.auth.*`，並支援透過 `gateway.remote.*` 的遠端模式。
- 舊版 `CLAWDBOT_GATEWAY_*` 環境變數在節點主機認證解析中被刻意忽略。

## Nodes

`nodes` 與 Gateway 通訊並以配對節點為目標。參見 [/nodes](/zh-Hant/nodes)。

常用選項：

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
- `nodes run --node <id|name|ip> [--cwd <path>] [--env KEY=VAL] [--command-timeout <ms>] [--needs-screen-recording] [--invoke-timeout <ms>] <command...>`（mac 節點或無頭節點主機）
- `nodes notify --node <id|name|ip> [--title <text>] [--body <text>] [--sound <name>] [--priority <passive|active|timeSensitive>] [--delivery <system|overlay|auto>] [--invoke-timeout <ms>]`（僅限 mac）

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

瀏覽器控制 CLI（專用 Chrome/Brave/Edge/Chromium）。參見 [`openclaw browser`](/zh-Hant/cli/browser) 和 [Browser 工具](/zh-Hant/tools/browser)。

常用選項：

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

開啟連接至 Gateway 的終端介面。

選項：

- `--url <url>`
- `--token <token>`
- `--password <password>`
- `--session <key>`
- `--deliver`
- `--thinking <level>`
- `--message <text>`
- `--timeout-ms <ms>`（預設為 `agents.defaults.timeoutSeconds`）
- `--history-limit <n>`
