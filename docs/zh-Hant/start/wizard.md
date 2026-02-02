---
summary: "CLI 入門精靈：Gateway、工作區、頻道和技能的引導式設定"
read_when:
  - 執行或設定入門精靈時
  - 設定新機器時
title: "入門精靈"
---

# 入門精靈（CLI）

入門精靈是在 macOS、
Linux 或 Windows（透過 WSL2；強烈推薦）上設定 OpenClaw 的**推薦**方式。
它在一個引導流程中設定本地或遠端 Gateway，加上頻道、技能、
和工作區預設值。

主要進入點：

```bash
openclaw onboard
```

最快首次聊天：開啟控制 UI（無需頻道設定）。執行
`openclaw dashboard` 並在瀏覽器中聊天。文件：[儀表板](/web/dashboard)。

後續重新配置：

```bash
openclaw configure
```

推薦：設定 Brave Search API 金鑰讓代理程式可以使用 `web_search`
（`web_fetch` 無需金鑰工作）。最簡單的路徑：`openclaw configure --section web`
儲存 `tools.web.search.apiKey`。文件：[網路工具](/tools/web)。

## 快速開始 vs 進階

精靈從**快速開始**（預設值）vs **進階**（完全控制）開始。

**快速開始**保持預設值：

- 本地 Gateway（環回）
- 工作區預設（或現有工作區）
- Gateway 連接埠 **18789**
- Gateway 認證**令牌**（自動產生，即使在環回）
- Tailscale 暴露**關閉**
- Telegram + WhatsApp DM 預設為**允許清單**（會提示您輸入電話號碼）

**進階**暴露每個步驟（模式、工作區、Gateway、頻道、daemon、技能）。

## 精靈的功能

**本地模式（預設）**會引導您完成：

- 模型/認證（OpenAI Code（Codex）訂閱 OAuth、Anthropic API 金鑰（推薦）或 setup-token（貼上），加上 MiniMax/GLM/Moonshot/AI Gateway 選項）
- 工作區位置 + 引導檔案
- Gateway 設定（連接埠/綁定/認證/tailscale）
- 提供商（Telegram、WhatsApp、Discord、Google Chat、Mattermost（外掛）、Signal）
- Daemon 安裝（LaunchAgent / systemd 使用者單位）
- 健康檢查
- 技能（推薦）

**遠端模式**僅設定本地用戶端連接到其他地方的 Gateway。
它**不會**在遠端主機上安裝或變更任何內容。

若要新增更多隔離的代理程式（個別工作區 + 會話 + 認證），使用：

```bash
openclaw agents add <name>
```

提示：`--json` **不**意味著非互動模式。使用 `--non-interactive`（和 `--workspace`）適用於腳本。

## 流程詳情（本地）

1. **現有配置偵測**
   - 若 `~/.openclaw/openclaw.json` 存在，選擇**保留 / 修改 / 重設**。
   - 重新執行精靈**不會**清除任何內容除非您明確選擇**重設**
     （或傳遞 `--reset`）。
   - 若配置無效或包含舊版金鑰，精靈停止並要求
     您在繼續前執行 `openclaw doctor`。
   - 重設使用 `trash`（永遠不是 `rm`）並提供範圍：
     - 僅配置
     - 配置 + 認證 + 會話
     - 完全重設（也移除工作區）

2. **模型/認證**
   - **Anthropic API 金鑰（推薦）**：若存在則使用 `ANTHROPIC_API_KEY` 或提示金鑰，然後儲存供 daemon 使用。
   - **Anthropic OAuth（Claude Code CLI）**：macOS 上精靈檢查 Keychain 項目「Claude Code-credentials」（選擇「Always Allow」所以 launchd 啟動不阻塞）；Linux/Windows 上若存在則重用 `~/.claude/.credentials.json`。
   - **Anthropic 令牌（貼上 setup-token）**：在任何機器上執行 `claude setup-token`，然後貼上令牌（您可命名它；空白 = 預設）。
   - **OpenAI Code（Codex）訂閱（Codex CLI）**：若 `~/.codex/auth.json` 存在，精靈可重用它。
   - **OpenAI Code（Codex）訂閱（OAuth）**：瀏覽器流程；貼上 `code#state`。
     - 當模型未設定或 `openai/*` 時，設定 `agents.defaults.model` 為 `openai-codex/gpt-5.2`。
   - **OpenAI API 金鑰**：若存在則使用 `OPENAI_API_KEY` 或提示金鑰，然後儲存到 `~/.openclaw/.env` 所以 launchd 可讀取。
   - **OpenCode Zen（多模型代理）**：提示 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`，在 https://opencode.ai/auth 取得）。
   - **API 金鑰**：儲存金鑰。
   - **Vercel AI Gateway（多模型代理）**：提示 `AI_GATEWAY_API_KEY`。
     詳細資訊：[Vercel AI Gateway](/providers/vercel-ai-gateway)
   - **MiniMax M2.1**：配置自動寫入。
     詳細資訊：[MiniMax](/providers/minimax)
   - **Synthetic（Anthropic 相容）**：提示 `SYNTHETIC_API_KEY`。
     詳細資訊：[Synthetic](/providers/synthetic)
   - **Moonshot（Kimi K2）**：配置自動寫入。
   - **Kimi 編碼**：配置自動寫入。
     詳細資訊：[Moonshot AI（Kimi + Kimi 編碼）](/providers/moonshot)
   - **跳過**：尚無認證設定。
   - 從偵測到的選項選擇預設模型（或手動輸入提供商/模型）。
   - 精靈執行模型檢查並警告若設定的模型未知或缺失認證。

- OAuth 認證位於 `~/.openclaw/credentials/oauth.json`；認證設定檔位於 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`（API 金鑰 + OAuth）。
- 詳細資訊：[/concepts/oauth](/concepts/oauth)

3. **工作區**
   - 預設 `~/.openclaw/workspace`（可配置）。
   - 植入代理程式引導儀式所需的工作區檔案。
   - 完整工作區佈局 + 備份指南：[Agent 工作區](/concepts/agent-workspace)

4. **Gateway**
   - 連接埠、綁定、認證模式、tailscale 暴露。
   - 認證推薦：即使環回也保持**令牌**所以本地 WS 客戶端必須認證。
   - 僅當您完全信任每個本地程序時停用認證。
   - 非環回綁定仍需要認證。

5. **頻道**
   - [WhatsApp](/channels/whatsapp)：選用 QR 登入。
   - [Telegram](/channels/telegram)：bot 令牌。
   - [Discord](/channels/discord)：bot 令牌。
   - [Google Chat](/channels/googlechat)：服務帳戶 JSON + webhook 對象。
   - [Mattermost](/channels/mattermost)（外掛）：bot 令牌 + 基本 URL。
   - [Signal](/channels/signal)：選用 `signal-cli` 安裝 + 帳戶配置。
   - [iMessage](/channels/imessage)：本地 `imsg` CLI 路徑 + DB 存取。
   - DM 安全性：預設是配對。首個 DM 傳送碼；透過 `openclaw pairing approve <channel> <code>` 核准或使用允許清單。

6. **Daemon 安裝**
   - macOS：LaunchAgent
     - 需要登入使用者工作階段；無頭時，使用自訂 LaunchDaemon（未出貨）。
   - Linux（及 Windows 透過 WSL2）：systemd 使用者單位
     - 精靈嘗試透過 `loginctl enable-linger <user>` 啟用徘徊所以 Gateway 登出後保持執行。
     - 可能提示 sudo（寫入 `/var/lib/systemd/linger`）；首先嘗試無 sudo。
   - **執行環境選擇：** Node（推薦；WhatsApp/Telegram 必需）。Bun **不推薦**。

7. **健康檢查**
   - 啟動 Gateway（若需要）並執行 `openclaw health`。
   - 提示：`openclaw status --deep` 在狀態輸出中新增 Gateway 健康檢查（需要可達 Gateway）。

8. **技能（推薦）**
   - 讀取可用技能並檢查需求。
   - 讓您選擇節點管理員：**npm / pnpm**（bun 不推薦）。
   - 安裝選用依賴（某些在 macOS 上使用 Homebrew）。

9. **完成**
   - 摘要 + 後續步驟，包括 iOS/Android/macOS 應用程式的額外功能。

- 若未偵測到 GUI，精靈列印 SSH 連接埠轉發指令適用於控制 UI 而非開啟瀏覽器。
- 若控制 UI 資產缺失，精靈嘗試建置它們；後備是 `pnpm ui:build`（自動安裝 UI 依賴）。

## 遠端模式

遠端模式設定本地用戶端連接到其他地方的 Gateway。

您將設定的內容：

- 遠端 Gateway URL（`ws://...`）
- 令牌若遠端 Gateway 需要認證（推薦）

備註：

- 不執行遠端安裝或 daemon 變更。
- 若 Gateway 僅環回，使用 SSH 通道或 tailnet。
- 發現提示：
  - macOS：Bonjour（`dns-sd`）
  - Linux：Avahi（`avahi-browse`）

## 新增另一個代理程式

使用 `openclaw agents add <name>` 建立獨立代理程式自己的工作區、
會話和認證設定檔。不帶 `--workspace` 執行啟動精靈。

它設定的內容：

- `agents.list[].name`
- `agents.list[].workspace`
- `agents.list[].agentDir`

備註：

- 預設工作區遵循 `~/.openclaw/workspace-<agentId>`。
- 新增 `bindings` 路由入站訊息（精靈可以執行此操作）。
- 非互動旗標：`--model`、`--agent-dir`、`--bind`、`--non-interactive`。

## 非互動模式

使用 `--non-interactive` 自動化或腳本入門：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice apiKey \
  --anthropic-api-key "$ANTHROPIC_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback \
  --install-daemon \
  --daemon-runtime node \
  --skip-skills
```

新增 `--json` 適用於機器可讀摘要。

Gemini 範例：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice gemini-api-key \
  --gemini-api-key "$GEMINI_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Z.AI 範例：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice zai-api-key \
  --zai-api-key "$ZAI_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Vercel AI Gateway 範例：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice ai-gateway-api-key \
  --ai-gateway-api-key "$AI_GATEWAY_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Moonshot 範例：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice moonshot-api-key \
  --moonshot-api-key "$MOONSHOT_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Synthetic 範例：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice synthetic-api-key \
  --synthetic-api-key "$SYNTHETIC_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

OpenCode Zen 範例：

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice opencode-zen \
  --opencode-zen-api-key "$OPENCODE_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

新增代理程式（非互動）範例：

```bash
openclaw agents add work \
  --workspace ~/.openclaw/workspace-work \
  --model openai/gpt-5.2 \
  --bind whatsapp:biz \
  --non-interactive \
  --json
```

## Gateway 精靈 RPC

Gateway 透過 RPC 暴露精靈流程（`wizard.start`、`wizard.next`、`wizard.cancel`、`wizard.status`）。
客戶端（macOS 應用程式、控制 UI）可以呈現步驟而不重新實作入門邏輯。

## Signal 設定（signal-cli）

精靈可以從 GitHub 發布安裝 `signal-cli`：

- 下載適當的發布資產。
- 儲存在 `~/.openclaw/tools/signal-cli/<version>/`。
- 寫入 `channels.signal.cliPath` 到您的配置。

備註：

- JVM 構建需要 **Java 21**。
- 本機構建在可用時使用。
- Windows 使用 WSL2；signal-cli 安裝在 WSL 內遵循 Linux 流程。

## 精靈寫入的內容

`~/.openclaw/openclaw.json` 中的典型欄位：

- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（若選擇 Minimax）
- `gateway.*`（模式、綁定、認證、tailscale）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 頻道允許清單（Slack/Discord/Matrix/Microsoft Teams）當您在提示期間選擇加入時（名稱在可能時解析為 ID）。
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw agents add` 寫入 `agents.list[]` 和選用 `bindings`。

WhatsApp 認證位於 `~/.openclaw/credentials/whatsapp/<accountId>/`。
會話儲存在 `~/.openclaw/agents/<agentId>/sessions/`。

某些頻道作為外掛交付。當您在入門期間選擇一個時，精靈
會提示安裝它（npm 或本地路徑）才能設定。

## 相關文件

- macOS 應用程式入門：[入門](/start/onboarding)
- 配置參考：[Gateway 配置](/gateway/configuration)
- 提供商：[WhatsApp](/channels/whatsapp)、[Telegram](/channels/telegram)、[Discord](/channels/discord)、[Google Chat](/channels/googlechat)、[Signal](/channels/signal)、[iMessage](/channels/imessage)
- 技能：[技能](/tools/skills)、[技能配置](/tools/skills-config)
