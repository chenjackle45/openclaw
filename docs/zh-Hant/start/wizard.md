---
title: "Wizard(引導精靈)"
summary: "CLI 引導精靈：Gateway、工作區、頻道和技能的引導式設定"
read_when:
  - 運行或設定引導精靈
  - 設定新機器
---

# Wizard（引導精靈）

引導精靈是在 macOS、Linux 或 Windows（透過 WSL2；強烈建議）上設定 OpenClaw 的**建議**方式。
它在一個引導式流程中設定本地 Gateway 或遠端 Gateway 連線，加上頻道、技能和工作區預設值。

主要入口點：

```bash
openclaw onboard
```

最快的首次聊天：開啟控制 UI（無需設定頻道）。執行 `openclaw dashboard` 並在瀏覽器中聊天。文件：[儀表板](/web/dashboard)。

後續重新設定：

```bash
openclaw configure
```

建議：設定 Brave Search API 金鑰，讓代理可以使用 `web_search`（`web_fetch` 無需金鑰即可運作）。最簡單的方式：`openclaw configure --section web`，它會儲存 `tools.web.search.apiKey`。文件：[Web 工具](/tools/web)。

## 快速開始 vs 進階

精靈從**快速開始**（預設）vs **進階**（完全控制）開始。

**快速開始**保持預設值：
- 本地 Gateway（迴環）
- 工作區預設（或現有工作區）
- Gateway 連接埠 **18789**
- Gateway 認證 **Token**（自動生成，即使在迴環上）
- Tailscale 公開 **關閉**
- Telegram + WhatsApp 私訊預設為**允許清單**（會提示您輸入電話號碼）

**進階**公開每個步驟（模式、工作區、Gateway、頻道、daemon、技能）。

## 精靈的功能

**本地模式（預設）**會引導您完成：
  - 模型/認證（OpenAI Code (Codex) 訂閱 OAuth、Anthropic API 金鑰（建議）或 setup-token（貼上），加上 MiniMax/GLM/Moonshot/AI Gateway 選項）
- 工作區位置 + 啟動檔案
- Gateway 設定（連接埠/綁定/認證/tailscale）
- 供應商（Telegram、WhatsApp、Discord、Google Chat、Mattermost（插件）、Signal）
- Daemon 安裝（LaunchAgent / systemd 使用者單元）
- 健康檢查
- 技能（建議）

**遠端模式**僅設定本地客戶端以連接到其他地方的 Gateway。
它**不會**在遠端主機上安裝或更改任何內容。

若要新增更多隔離的代理（獨立的工作區 + 會話 + 認證），請使用：

```bash
openclaw agents add <name>
```

提示：`--json` **不**意味著非互動模式。腳本請使用 `--non-interactive`（和 `--workspace`）。

## 流程詳情（本地）

1) **現有設定偵測**
   - 如果 `~/.openclaw/openclaw.json` 存在，選擇 **保留 / 修改 / 重置**。
   - 重新運行精靈**不會**清除任何內容，除非您明確選擇**重置**（或傳遞 `--reset`）。
   - 如果設定無效或包含舊版金鑰，精靈會停止並要求您在繼續之前運行 `openclaw doctor`。
   - 重置使用 `trash`（永遠不用 `rm`）並提供範圍：
     - 僅設定
     - 設定 + 憑證 + 會話
     - 完全重置（也移除工作區）

2) **模型/認證**
   - **Anthropic API 金鑰（建議）**：如果存在則使用 `ANTHROPIC_API_KEY`，否則提示輸入金鑰，然後儲存以供 daemon 使用。
   - **Anthropic OAuth（Claude Code CLI）**：在 macOS 上，精靈會檢查 Keychain 項目「Claude Code-credentials」（選擇「始終允許」以便 launchd 啟動不會阻塞）；在 Linux/Windows 上，如果存在則重用 `~/.claude/.credentials.json`。
   - **Anthropic token（貼上 setup-token）**：在任何機器上運行 `claude setup-token`，然後貼上 token（您可以命名它；空白 = 預設）。
   - **OpenAI Code (Codex) 訂閱（Codex CLI）**：如果 `~/.codex/auth.json` 存在，精靈可以重用它。
   - **OpenAI Code (Codex) 訂閱（OAuth）**：瀏覽器流程；貼上 `code#state`。
     - 當模型未設定或為 `openai/*` 時，設定 `agents.defaults.model` 為 `openai-codex/gpt-5.2`。
   - **OpenAI API 金鑰**：如果存在則使用 `OPENAI_API_KEY`，否則提示輸入金鑰，然後儲存到 `~/.openclaw/.env` 以便 launchd 可以讀取。
   - **OpenCode Zen（多模型代理）**：提示輸入 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`，在 https://opencode.ai/auth 取得）。
   - **API 金鑰**：為您儲存金鑰。
   - **Vercel AI Gateway（多模型代理）**：提示輸入 `AI_GATEWAY_API_KEY`。
   - 更多詳情：[Vercel AI Gateway](/providers/vercel-ai-gateway)
   - **MiniMax M2.1**：設定會自動寫入。
   - 更多詳情：[MiniMax](/providers/minimax)
   - **Synthetic（Anthropic 相容）**：提示輸入 `SYNTHETIC_API_KEY`。
   - 更多詳情：[Synthetic](/providers/synthetic)
   - **Moonshot（Kimi K2）**：設定會自動寫入。
   - **Kimi Code**：設定會自動寫入。
   - 更多詳情：[Moonshot AI（Kimi + Kimi Code）](/providers/moonshot)
   - **跳過**：尚未設定認證。
   - 從偵測到的選項中選擇預設模型（或手動輸入 provider/model）。
   - 精靈會運行模型檢查，如果設定的模型未知或缺少認證則發出警告。
  - OAuth 憑證位於 `~/.openclaw/credentials/oauth.json`；認證設定檔位於 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`（API 金鑰 + OAuth）。
   - 更多詳情：[/concepts/oauth](/concepts/oauth)

3) **工作區**
   - 預設 `~/.openclaw/workspace`（可設定）。
   - 種植代理啟動儀式所需的工作區檔案。
   - 完整工作區佈局 + 備份指南：[代理工作區](/concepts/agent-workspace)

4) **Gateway**
   - 連接埠、綁定、認證模式、tailscale 公開。
   - 認證建議：即使在迴環上也保持 **Token**，以便本地 WS 客戶端必須認證。
   - 只有在您完全信任每個本地程序時才停用認證。
   - 非迴環綁定仍然需要認證。

5) **頻道**
  - WhatsApp：可選的 QR 登入。
  - Telegram：機器人 token。
  - Discord：機器人 token。
  - Google Chat：服務帳戶 JSON + webhook 受眾。
  - Mattermost（插件）：機器人 token + 基礎 URL。
   - Signal：可選的 `signal-cli` 安裝 + 帳戶設定。
   - iMessage：本地 `imsg` CLI 路徑 + 資料庫存取。
  - 私訊安全：預設為配對。第一則私訊發送代碼；透過 `openclaw pairing approve <channel> <code>` 批准或使用允許清單。

6) **Daemon 安裝**
   - macOS：LaunchAgent
     - 需要已登入的使用者會話；對於無頭使用，請使用自訂 LaunchDaemon（未隨附）。
   - Linux（和透過 WSL2 的 Windows）：systemd 使用者單元
     - 精靈嘗試透過 `loginctl enable-linger <user>` 啟用 lingering，以便 Gateway 在登出後保持運行。
     - 可能提示 sudo（寫入 `/var/lib/systemd/linger`）；它會先嘗試不使用 sudo。
   - **運行時選擇：** Node（建議；WhatsApp/Telegram 必需）。**不建議**使用 Bun。

7) **健康檢查**
   - 啟動 Gateway（如果需要）並運行 `openclaw health`。
   - 提示：`openclaw status --deep` 將 Gateway 健康探測新增到狀態輸出（需要可達的 Gateway）。

8) **技能（建議）**
   - 讀取可用技能並檢查需求。
   - 讓您選擇節點管理器：**npm / pnpm**（不建議 bun）。
   - 安裝可選依賴（某些在 macOS 上使用 Homebrew）。

9) **完成**
   - 摘要 + 下一步，包括 iOS/Android/macOS 應用程式以獲得額外功能。
  - 如果未偵測到 GUI，精靈會列印 SSH 連接埠轉發指令用於控制 UI，而不是開啟瀏覽器。
  - 如果控制 UI 資源遺失，精靈會嘗試建置它們；備用方案是 `pnpm ui:build`（自動安裝 UI 依賴）。

## 遠端模式

遠端模式設定本地客戶端以連接到其他地方的 Gateway。

您將設定的內容：
- 遠端 Gateway URL（`ws://...`）
- 如果遠端 Gateway 需要認證則輸入 Token（建議）

注意：
- 不會執行遠端安裝或 daemon 變更。
- 如果 Gateway 僅限迴環，請使用 SSH 隧道或 tailnet。
- 探索提示：
  - macOS：Bonjour（`dns-sd`）
  - Linux：Avahi（`avahi-browse`）

## 新增另一個代理

使用 `openclaw agents add <name>` 建立一個擁有自己工作區、會話和認證設定檔的獨立代理。不使用 `--workspace` 運行會啟動精靈。

它設定的內容：
- `agents.list[].name`
- `agents.list[].workspace`
- `agents.list[].agentDir`

注意：
- 預設工作區遵循 `~/.openclaw/workspace-<agentId>`。
- 新增 `bindings` 以路由入站訊息（精靈可以做到這一點）。
- 非互動標誌：`--model`、`--agent-dir`、`--bind`、`--non-interactive`。

## 非互動模式

使用 `--non-interactive` 來自動化或腳本化引導：

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

新增 `--json` 以獲得機器可讀的摘要。

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

新增代理（非互動）範例：

```bash
openclaw agents add work \
  --workspace ~/.openclaw/workspace-work \
  --model openai/gpt-5.2 \
  --bind whatsapp:biz \
  --non-interactive \
  --json
```

## Gateway 精靈 RPC

Gateway 透過 RPC 公開精靈流程（`wizard.start`、`wizard.next`、`wizard.cancel`、`wizard.status`）。
客戶端（macOS 應用程式、控制 UI）可以渲染步驟而無需重新實作引導邏輯。

## Signal 設定（signal-cli）

精靈可以從 GitHub releases 安裝 `signal-cli`：
- 下載適當的 release 資源。
- 儲存在 `~/.openclaw/tools/signal-cli/<version>/` 下。
- 將 `channels.signal.cliPath` 寫入您的設定。

注意：
- JVM 建置需要 **Java 21**。
- 可用時使用原生建置。
- Windows 使用 WSL2；signal-cli 安裝在 WSL 內遵循 Linux 流程。

## 精靈寫入的內容

`~/.openclaw/openclaw.json` 中的典型欄位：
- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（如果選擇 Minimax）
- `gateway.*`（模式、綁定、認證、tailscale）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 頻道允許清單（Slack/Discord/Matrix/Microsoft Teams），當您在提示期間選擇加入時（名稱會在可能時解析為 ID）。
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw agents add` 寫入 `agents.list[]` 和可選的 `bindings`。

WhatsApp 憑證存放在 `~/.openclaw/credentials/whatsapp/<accountId>/` 下。
會話儲存在 `~/.openclaw/agents/<agentId>/sessions/` 下。

某些頻道以插件形式提供。當您在引導期間選擇一個時，精靈會提示安裝它（npm 或本地路徑），然後才能設定。

## 相關文件

- macOS 應用程式引導：[引導](/start/onboarding)
- 設定參考：[Gateway 設定](/gateway/configuration)
- 供應商：[WhatsApp](/channels/whatsapp)、[Telegram](/channels/telegram)、[Discord](/channels/discord)、[Google Chat](/channels/googlechat)、[Signal](/channels/signal)、[iMessage](/channels/imessage)
- 技能：[技能](/tools/skills)、[技能設定](/tools/skills-config)
