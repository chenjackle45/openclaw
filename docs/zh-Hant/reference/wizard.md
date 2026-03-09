---
summary: "CLI 入門精靈的完整參考：每個步驟、旗標與設定欄位"
read_when:
  - 查詢特定精靈步驟或旗標
  - 使用非互動模式自動化入門流程
  - 除錯精靈行為
title: "Onboarding Wizard Reference（入門精靈參考）"
sidebarTitle: "Wizard Reference"
---

# 入門精靈參考

這是 `openclaw onboard` CLI 精靈的完整參考。
高階概覽請見 [入門精靈](/zh-Hant/start/wizard)。

## 流程細節（本地模式）

<Steps>
  <Step title="偵測現有設定">
    - 若 `~/.openclaw/openclaw.json` 存在，選擇 **保留 / 修改 / 重置**。
    - 重新執行精靈**不會**清除任何內容，除非明確選擇 **重置**（或傳入 `--reset`）。
    - CLI 的 `--reset` 預設為 `config+creds+sessions`；使用 `--reset-scope full` 也可移除 workspace。
    - 若設定無效或包含舊版金鑰，精靈會停止並要求先執行 `openclaw doctor`。
    - 重置使用 `trash`（從不使用 `rm`），並提供以下範圍：
      - 僅設定
      - 設定 + 憑證 + sessions
      - 完整重置（也移除 workspace）
  </Step>
  <Step title="模型／驗證">
    - **Anthropic API key**：若存在 `ANTHROPIC_API_KEY` 則使用，否則提示輸入金鑰並儲存供 daemon 使用。
    - **Anthropic OAuth（Claude Code CLI）**：在 macOS 上精靈會檢查 Keychain 項目「Claude Code-credentials」（選擇「永遠允許」以避免 launchd 啟動被阻擋）；在 Linux/Windows 上若存在 `~/.claude/.credentials.json` 則重複使用。
    - **Anthropic token（貼上 setup-token）**：在任何機器上執行 `claude setup-token`，然後貼上 token（可命名；留空 = 預設）。
    - **OpenAI Code（Codex）訂閱（Codex CLI）**：若 `~/.codex/auth.json` 存在，精靈可重複使用。
    - **OpenAI Code（Codex）訂閱（OAuth）**：瀏覽器流程；貼上 `code#state`。
      - 在模型未設定或為 `openai/*` 時，將 `agents.defaults.model` 設為 `openai-codex/gpt-5.2`。
    - **OpenAI API key**：若存在 `OPENAI_API_KEY` 則使用，否則提示輸入並儲存至 auth profiles。
    - **xAI（Grok）API key**：提示輸入 `XAI_API_KEY` 並將 xAI 設定為模型提供商。
    - **OpenCode Zen（多模型代理）**：提示輸入 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`，在 https://opencode.ai/auth 取得）。
    - **API key**：替你儲存金鑰。
    - **Vercel AI Gateway（多模型代理）**：提示輸入 `AI_GATEWAY_API_KEY`。
    - 詳細說明：[Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
    - **Cloudflare AI Gateway**：提示輸入 Account ID、Gateway ID 與 `CLOUDFLARE_AI_GATEWAY_API_KEY`。
    - 詳細說明：[Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)
    - **MiniMax M2.5**：設定自動寫入。
    - 詳細說明：[MiniMax](/zh-Hant/providers/minimax)
    - **Synthetic（Anthropic 相容）**：提示輸入 `SYNTHETIC_API_KEY`。
    - 詳細說明：[Synthetic](/zh-Hant/providers/synthetic)
    - **Moonshot（Kimi K2）**：設定自動寫入。
    - **Kimi Coding**：設定自動寫入。
    - 詳細說明：[Moonshot AI（Kimi + Kimi Coding）](/zh-Hant/providers/moonshot)
    - **跳過**：尚未設定驗證。
    - 從偵測到的選項中選擇預設模型（或手動輸入提供商/模型）。為了最佳品質與較低的提示注入風險，請選擇提供商堆疊中最強的最新世代模型。
    - 精靈執行模型檢查，若設定的模型未知或缺少驗證則發出警告。
    - API key 儲存模式預設為明文 auth profile 值。使用 `--secret-input-mode ref` 改為儲存環境變數支援的 ref（例如 `keyRef: { source: "env", provider: "default", id: "OPENAI_API_KEY" }`）。
    - OAuth 憑證存於 `~/.openclaw/credentials/oauth.json`；auth profiles 存於 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`（API 金鑰 + OAuth）。
    - 詳細說明：[/concepts/oauth](/zh-Hant/concepts/oauth)
    <Note>
    無頭／伺服器提示：在有瀏覽器的機器上完成 OAuth，然後將
    `~/.openclaw/credentials/oauth.json`（或 `$OPENCLAW_STATE_DIR/credentials/oauth.json`）複製到
    gateway 主機。
    </Note>
  </Step>
  <Step title="Workspace">
    - 預設 `~/.openclaw/workspace`（可設定）。
    - 建立 agent 啟動流程所需的 workspace 檔案。
    - 完整 workspace 結構 + 備份指南：[Agent workspace](/zh-Hant/concepts/agent-workspace)
  </Step>
  <Step title="Gateway">
    - 連接埠、綁定、驗證模式、tailscale 暴露。
    - 驗證建議：即使是 loopback 也保持 **Token**，使本地 WS 客戶端必須驗證。
    - 在 token 模式下，互動式入門提供：
      - **產生／儲存明文 token**（預設）
      - **使用 SecretRef**（選擇性啟用）
      - Quickstart 可跨 `env`、`file` 和 `exec` 提供商重複使用現有的 `gateway.auth.token` SecretRef 進行入門探測／儀表板啟動。
      - 若 SecretRef 已設定但無法解析，入門流程會提早失敗並給出明確的修復訊息，而不是靜默降級執行階段驗證。
    - 在密碼模式下，互動式入門也支援明文或 SecretRef 儲存。
    - 非互動 token SecretRef 路徑：`--gateway-token-ref-env <ENV_VAR>`。
      - 需要入門流程環境中的非空環境變數。
      - 不能與 `--gateway-token` 同時使用。
    - 僅在完全信任每個本地程序時才停用驗證。
    - 非 loopback 綁定仍需驗證。
  </Step>
  <Step title="頻道">
    - [WhatsApp](/zh-Hant/channels/whatsapp)：可選的 QR 碼登入。
    - [Telegram](/zh-Hant/channels/telegram)：bot token。
    - [Discord](/zh-Hant/channels/discord)：bot token。
    - [Google Chat](/zh-Hant/channels/googlechat)：service account JSON + webhook audience。
    - [Mattermost](/zh-Hant/channels/mattermost)（plugin）：bot token + base URL。
    - [Signal](/zh-Hant/channels/signal)：可選的 `signal-cli` 安裝 + 帳號設定。
    - [BlueBubbles](/zh-Hant/channels/bluebubbles)：**iMessage 推薦方案**；伺服器 URL + 密碼 + webhook。
    - [iMessage](/zh-Hant/channels/imessage)：舊版 `imsg` CLI 路徑 + DB 存取。
    - DM 安全性：預設為配對。第一則 DM 發送驗證碼；透過 `openclaw pairing approve <channel> <code>` 核准，或使用允許清單。
  </Step>
  <Step title="網路搜尋">
    - 選擇提供商：Perplexity、Brave、Gemini、Grok 或 Kimi（或跳過）。
    - 貼上 API 金鑰（QuickStart 可從環境變數或現有設定自動偵測金鑰）。
    - 使用 `--skip-search` 跳過。
    - 稍後設定：`openclaw configure --section web`。
  </Step>
  <Step title="Daemon 安裝">
    - macOS：LaunchAgent
      - 需要已登入的使用者 session；無頭環境請使用自訂 LaunchDaemon（未隨附）。
    - Linux（以及透過 WSL2 的 Windows）：systemd user unit
      - 精靈嘗試透過 `loginctl enable-linger <user>` 啟用持久化，使 Gateway 在登出後保持運作。
      - 可能提示 sudo（寫入 `/var/lib/systemd/linger`）；首先嘗試不使用 sudo。
    - **執行階段選擇：** Node（建議；WhatsApp/Telegram 必須）。Bun **不建議**。
    - 若 token 驗證需要 token 且 `gateway.auth.token` 由 SecretRef 管理，daemon 安裝會驗證但不會將已解析的明文 token 值持久化至 supervisor 服務環境中繼資料。
    - 若 token 驗證需要 token 且已設定的 token SecretRef 無法解析，daemon 安裝會被阻擋並提供可操作的指引。
    - 若同時設定了 `gateway.auth.token` 和 `gateway.auth.password` 且 `gateway.auth.mode` 未設定，daemon 安裝會被阻擋直到明確設定模式。
  </Step>
  <Step title="健康檢查">
    - 啟動 Gateway（若需要）並執行 `openclaw health`。
    - 提示：`openclaw status --deep` 將 gateway 健康探測加入 status 輸出（需要可達的 gateway）。
  </Step>
  <Step title="Skills（建議）">
    - 讀取可用的 skills 並檢查需求。
    - 讓你選擇 node 管理器：**npm / pnpm**（bun 不建議）。
    - 安裝可選的依賴項（部分在 macOS 上使用 Homebrew）。
  </Step>
  <Step title="完成">
    - 摘要 + 後續步驟，包含 iOS/Android/macOS 應用程式以獲得額外功能。
  </Step>
</Steps>

<Note>
若未偵測到 GUI，精靈會列印 Control UI 的 SSH 連接埠轉發說明，而不是開啟瀏覽器。
若 Control UI 資源缺失，精靈會嘗試建置；退備方案為 `pnpm ui:build`（自動安裝 UI 依賴項）。
</Note>

## 非互動模式

使用 `--non-interactive` 自動化或腳本化入門流程：

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

加上 `--json` 可獲得機器可讀的摘要。

Gateway token SecretRef 非互動模式：

```bash
export OPENCLAW_GATEWAY_TOKEN="your-token"
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice skip \
  --gateway-auth token \
  --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN
```

`--gateway-token` 和 `--gateway-token-ref-env` 互斥。

<Note>
`--json` **不**隱含非互動模式。腳本請使用 `--non-interactive`（以及 `--workspace`）。
</Note>

<AccordionGroup>
  <Accordion title="Gemini 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice gemini-api-key \
      --gemini-api-key "$GEMINI_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
  <Accordion title="Z.AI 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice zai-api-key \
      --zai-api-key "$ZAI_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
  <Accordion title="Vercel AI Gateway 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice ai-gateway-api-key \
      --ai-gateway-api-key "$AI_GATEWAY_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
  <Accordion title="Cloudflare AI Gateway 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice cloudflare-ai-gateway-api-key \
      --cloudflare-ai-gateway-account-id "your-account-id" \
      --cloudflare-ai-gateway-gateway-id "your-gateway-id" \
      --cloudflare-ai-gateway-api-key "$CLOUDFLARE_AI_GATEWAY_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
  <Accordion title="Moonshot 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice moonshot-api-key \
      --moonshot-api-key "$MOONSHOT_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
  <Accordion title="Synthetic 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice synthetic-api-key \
      --synthetic-api-key "$SYNTHETIC_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
  <Accordion title="OpenCode Zen 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice opencode-zen \
      --opencode-zen-api-key "$OPENCODE_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
  </Accordion>
</AccordionGroup>

### 新增 agent（非互動模式）

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
客戶端（macOS 應用程式、Control UI）可以渲染步驟而無需重新實作入門邏輯。

## Signal 設定（signal-cli）

精靈可從 GitHub releases 安裝 `signal-cli`：

- 下載適當的 release 資源。
- 儲存於 `~/.openclaw/tools/signal-cli/<version>/`。
- 將 `channels.signal.cliPath` 寫入設定。

注意事項：

- JVM 版本需要 **Java 21**。
- 有原生版本時優先使用。
- Windows 使用 WSL2；signal-cli 安裝遵循 WSL 內的 Linux 流程。

## 精靈寫入的內容

`~/.openclaw/openclaw.json` 中的典型欄位：

- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（若選擇 Minimax）
- `tools.profile`（本地入門在未設定時預設為 `"coding"`；現有明確值會保留）
- `gateway.*`（模式、綁定、驗證、tailscale）
- `session.dmScope`（行為細節：[CLI 入門參考](/zh-Hant/start/wizard-cli-reference#outputs-and-internals)）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 頻道允許清單（Slack/Discord/Matrix/Microsoft Teams），在提示時選擇啟用（名稱盡可能解析為 ID）。
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw agents add` 寫入 `agents.list[]` 與可選的 `bindings`。

WhatsApp 憑證存於 `~/.openclaw/credentials/whatsapp/<accountId>/`。
Sessions 存於 `~/.openclaw/agents/<agentId>/sessions/`。

部分頻道以 plugin 形式提供。在入門時選擇後，精靈會提示先安裝（npm 或本地路徑），才能進行設定。

## 相關文件

- 精靈概覽：[入門精靈](/zh-Hant/start/wizard)
- macOS 應用程式入門：[Onboarding](/zh-Hant/start/onboarding)
- 設定參考：[Gateway 設定](/zh-Hant/gateway/configuration)
- 提供商：[WhatsApp](/zh-Hant/channels/whatsapp)、[Telegram](/zh-Hant/channels/telegram)、[Discord](/zh-Hant/channels/discord)、[Google Chat](/zh-Hant/channels/googlechat)、[Signal](/zh-Hant/channels/signal)、[BlueBubbles](/zh-Hant/channels/bluebubbles)（iMessage）、[iMessage](/zh-Hant/channels/imessage)（舊版）
- Skills：[Skills](/zh-Hant/tools/skills)、[Skills 設定](/zh-Hant/tools/skills-config)
