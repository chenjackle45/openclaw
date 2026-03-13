---
title: "Onboarding Wizard Reference（登機精靈參考）"
summary: "完整的 CLI 登機精靈參考：每個步驟、標誌和設定欄位"
read_when:
  - 查詢特定精靈步驟或標誌
  - 使用非互動模式自動化登機
  - 除錯精靈行為
sidebarTitle: "精靈參考"
---

# 登機精靈參考

這是 `openclaw onboard` CLI 精靈的完整參考。
如需高層級概覽，請參閱 [登機精靈](/zh-Hant/start/wizard)。

## 流程詳細資料（本地模式）

<Steps>
  <Step title="現有設定偵測">
    - 如果存在 `~/.openclaw/openclaw.json`，請選擇 **保持／修改／重設**。
    - 重新執行精靈 **不會**擦除任何內容，除非您明確選擇 **重設**（或傳遞 `--reset`）。
    - CLI `--reset` 預設為 `config+creds+sessions`；使用 `--reset-scope full` 也移除工作區。
    - 如果設定無效或包含舊版金鑰，精靈會停止並要求您在繼續前執行 `openclaw doctor`。
    - 重設使用 `trash`（從不 `rm`）並提供範圍：
      - 僅設定
      - 設定 + 認證 + 工作階段
      - 完整重設（也移除工作區）
  </Step>
  <Step title="模型／驗證">
    - **Anthropic API 金鑰**：使用 `ANTHROPIC_API_KEY`（如果存在）或提示輸入金鑰，然後為精靈用途儲存。
    - **Anthropic OAuth（Claude Code CLI）**：在 macOS 上，精靈檢查鑰匙圈項目「Claude Code-credentials」（選擇「始終允許」以便 launchd 啟動不會阻止）；在 Linux／Windows 上，如果存在則重新使用 `~/.claude/.credentials.json`。
    - **Anthropic 令牌（貼上設定令牌）**：在任何機器上執行 `claude setup-token`，然後貼上令牌（您可以將其命名；空白 = 預設值）。
    - **OpenAI Code（Codex）訂閱（Codex CLI）**：如果存在 `~/.codex/auth.json`，精靈可以重新使用它。
    - **OpenAI Code（Codex）訂閱（OAuth）**：瀏覽器流程；貼上 `code#state`。
      - 當模型未設定或 `openai/*` 時，將 `agents.defaults.model` 設定為 `openai-codex/gpt-5.2`。
    - **OpenAI API 金鑰**：使用 `OPENAI_API_KEY`（如果存在）或提示輸入金鑰，然後儲存在驗證設定檔中。
    - **xAI（Grok）API 金鑰**：提示輸入 `XAI_API_KEY` 並將 xAI 設定為模型提供者。
    - **OpenCode**：提示輸入 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`，在 https://opencode.ai/auth 取得）並讓您挑選 Zen 或 Go 目錄。
    - **Ollama**：提示輸入 Ollama 基礎 URL、提供 **雲端 + 本地**或 **本地**模式、發現可用模型，以及在需要時自動拉取所選本地模型。
    - 更多詳細資訊：[Ollama](/zh-Hant/providers/ollama)
    - **API 金鑰**：為您儲存金鑰。
    - **Vercel AI Gateway（多模型代理）**：提示輸入 `AI_GATEWAY_API_KEY`。
    - 更多詳細資訊：[Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
    - **Cloudflare AI Gateway**：提示輸入帳戶 ID、Gateway ID 和 `CLOUDFLARE_AI_GATEWAY_API_KEY`。
    - 更多詳細資訊：[Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)
    - **MiniMax M2.5**：設定自動寫入。
    - 更多詳細資訊：[MiniMax](/zh-Hant/providers/minimax)
    - **Synthetic（Anthropic 相容）**：提示輸入 `SYNTHETIC_API_KEY`。
    - 更多詳細資訊：[Synthetic](/zh-Hant/providers/synthetic)
    - **Moonshot（Kimi K2）**：設定自動寫入。
    - **Kimi Coding**：設定自動寫入。
    - 更多詳細資訊：[Moonshot AI（Kimi + Kimi Coding）](/zh-Hant/providers/moonshot)
    - **略過**：尚未設定驗證。
    - 從偵測的選項中挑選預設模型（或手動輸入提供者／模型）。為獲得最佳品質和較低的提示注入風險，請選擇提供者堆疊中可用的最強最新產生模型。
    - 精靈執行模型檢查並警告已設定的模型是否不明或遺留驗證。
    - API 金鑰儲存模式預設為純文字驗證設定檔值。使用 `--secret-input-mode ref` 改為儲存環境支援的重新（例如 `keyRef: { source: "env", provider: "default", id: "OPENAI_API_KEY" }`）。
    - OAuth 認證存儲在 `~/.openclaw/credentials/oauth.json`；驗證設定檔存儲在 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`（API 金鑰 + OAuth）。
    - 更多詳細資訊：[/concepts/oauth](/zh-Hant/concepts/oauth)
    <Note>
    無頭／伺服器提示：在具有瀏覽器的機器上完成 OAuth，然後複製 `~/.openclaw/credentials/oauth.json`（或 `$OPENCLAW_STATE_DIR/credentials/oauth.json`）到閘道主機。
    </Note>
  </Step>
  <Step title="工作區">
    - 預設 `~/.openclaw/workspace`（可設定）。
    - 針對代理啟動儀式播種必要的工作區檔案。
    - 完整工作區配置 + 備份指南：[代理工作區](/zh-Hant/concepts/agent-workspace)
  </Step>
  <Step title="閘道">
    - 連接埠、繫結、驗證模式、tailscale 暴露。
    - 驗證建議：即使針對迴圈保持 **令牌**，以便本地 WS 用戶端必須驗證。
    - 在令牌模式中，互動式登機提供：
      - **產生／儲存純文字令牌**（預設）
      - **使用 SecretRef**（選擇加入）
      - Quickstart 針對登機探測／儀表板啟動在 `env`、`file` 和 `exec` 提供者間重新使用現有 `gateway.auth.token` SecretRef。
      - 如果該 SecretRef 已設定但無法解析，登機早期失敗，並清除修復訊息，而不是無聲降級執行時間驗證。
    - 在密碼模式中，互動式登機也支援純文字或 SecretRef 儲存。
    - 非互動令牌 SecretRef 路徑：`--gateway-token-ref-env <ENV_VAR>`。
      - 需要登機程序環境中的非空環境變數。
      - 無法與 `--gateway-token` 結合。
    - 僅在您完全信任每個本地程序時停用驗證。
    - 非迴圈繫結仍需要驗證。
  </Step>
  <Step title="頻道">
    - [WhatsApp](/zh-Hant/channels/whatsapp)：選擇性 QR 登入。
    - [Telegram](/zh-Hant/channels/telegram)：機器人令牌。
    - [Discord](/zh-Hant/channels/discord)：機器人令牌。
    - [Google Chat](/zh-Hant/channels/googlechat)：服務帳戶 JSON + webhook 對象。
    - [Mattermost](/zh-Hant/channels/mattermost)（外掛）：機器人令牌 + 基礎 URL。
    - [Signal](/zh-Hant/channels/signal)：選擇性 `signal-cli` 安裝 + 帳戶設定。
    - [BlueBubbles](/zh-Hant/channels/bluebubbles)：**建議用於 iMessage**；伺服器 URL + 密碼 + webhook。
    - [iMessage](/zh-Hant/channels/imessage)：舊版 `imsg` CLI 路徑 + 資料庫存取。
    - DM 安全性：預設為配對。第一次 DM 傳送代碼；透過 `openclaw pairing approve <channel> <code>` 批准或使用允許清單。
  </Step>
  <Step title="Web 搜尋">
    - 挑選提供者：Perplexity、Brave、Gemini、Grok 或 Kimi（或略過）。
    - 貼上您的 API 金鑰（QuickStart 自動偵測來自環境變數或現有設定的金鑰）。
    - 使用 `--skip-search` 略過。
    - 稍後設定：`openclaw configure --section web`。
  </Step>
  <Step title="精靈安裝">
    - macOS：LaunchAgent
      - 需要已登入的使用者工作階段；用於無頭，使用自訂 LaunchDaemon（未發佈）。
    - Linux（和透過 WSL2 的 Windows）：systemd 使用者單位
      - 精靈嘗試透過 `loginctl enable-linger <user>` 啟用逗留，以便 Gateway 在登出後保持執行。
      - 可能提示 sudo（寫入 `/var/lib/systemd/linger`）；它先嘗試無 sudo。
    - **執行時間選擇**：Node（建議；WhatsApp／Telegram 必需）。Bun **不建議**。
    - 如果令牌驗證需要令牌且 `gateway.auth.token` 為 SecretRef 管理，精靈安裝驗證它但不將已解析的純文字令牌值保持到監督服務環境中繼資料。
    - 如果令牌驗證需要令牌且已設定的令牌 SecretRef 未解析，精靈安裝被阻止並具有可操作指導。
    - 如果同時設定 `gateway.auth.token` 和 `gateway.auth.password` 且 `gateway.auth.mode` 未設定，精靈安裝被阻止直到明確設定模式。
  </Step>
  <Step title="健康檢查">
    - 啟動 Gateway（如果需要）並執行 `openclaw health`。
    - 提示：`openclaw status --deep` 將閘道健康探測新增到狀態輸出（需要可到達的閘道）。
  </Step>
  <Step title="技能（建議）">
    - 讀取可用的技能並檢查需求。
    - 讓您選擇節點管理員：**npm / pnpm**（不建議 bun）。
    - 安裝選擇性依賴項（某些在 macOS 上使用 Homebrew）。
  </Step>
  <Step title="完成">
    - 摘要 + 後續步驟，包括 iOS／Android／macOS app 以取得額外功能。
  </Step>
</Steps>

<Note>
如果未偵測到 GUI，精靈列印 SSH 連接埠轉發指示用於控制 UI，而不是開啟瀏覽器。
如果遺留控制 UI 資產，精靈嘗試建置它們；回退為 `pnpm ui:build`（自動安裝 UI 依賴項）。
</Note>

## 非互動模式

使用 `--non-interactive` 自動化或指令碼登機：

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

新增 `--json` 以取得機器可讀摘要。

非互動模式中的 Gateway 令牌 SecretRef：

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
`--json` **不**隱含非互動模式。使用 `--non-interactive`（和 `--workspace`）以用於指令碼。
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
  <Accordion title="OpenCode 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice opencode-zen \
      --opencode-zen-api-key "$OPENCODE_API_KEY" \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
    切換到 `--auth-choice opencode-go --opencode-go-api-key "$OPENCODE_API_KEY"` 以取得 Go 目錄。
  </Accordion>
  <Accordion title="Ollama 範例">
    ```bash
    openclaw onboard --non-interactive \
      --mode local \
      --auth-choice ollama \
      --custom-model-id "qwen3.5:27b" \
      --accept-risk \
      --gateway-port 18789 \
      --gateway-bind loopback
    ```
    新增 `--custom-base-url "http://ollama-host:11434"` 以將目標指向遠端 Ollama 實例。
  </Accordion>
</AccordionGroup>

### 新增代理（非互動）

```bash
openclaw agents add work \
  --workspace ~/.openclaw/workspace-work \
  --model openai/gpt-5.2 \
  --bind whatsapp:biz \
  --non-interactive \
  --json
```

## Gateway 精靈 RPC

Gateway 透過 RPC（`wizard.start`、`wizard.next`、`wizard.cancel`、`wizard.status`）公開精靈流程。
用戶端（macOS app、控制 UI）可以轉譯步驟而不需重新實現登機邏輯。

## Signal 設定（signal-cli）

精靈可以從 GitHub 發佈安裝 `signal-cli`：

- 下載適當的發佈資產。
- 儲存在 `~/.openclaw/tools/signal-cli/<version>/` 下。
- 寫入 `channels.signal.cliPath` 到您的設定。

備註：

- JVM 構建需要 **Java 21**。
- 可用時使用原生構建。
- Windows 使用 WSL2；signal-cli 安裝遵循 WSL 內的 Linux 流程。

## 精靈寫入的內容

`~/.openclaw/openclaw.json` 中的典型欄位：

- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（如果選擇 Minimax）
- `tools.profile`（本地登機預設為 `"coding"`（未設定時）；現有明確值已保留）
- `gateway.*`（模式、繫結、驗證、tailscale）
- `session.dmScope`（行為詳細資料：[CLI 登機參考](/zh-Hant/start/wizard-cli-reference#outputs-and-internals)）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 頻道允許清單（Slack／Discord／Matrix／Microsoft Teams）（當您在提示期間選擇加入時（名稱在可能時解析為 ID）。
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw agents add` 寫入 `agents.list[]` 和選擇性 `bindings`。

WhatsApp 認證位於 `~/.openclaw/credentials/whatsapp/<accountId>/`。
工作階段儲存在 `~/.openclaw/agents/<agentId>/sessions/`。

某些頻道作為外掛被發佈。當您在登機期間挑選一個時，精靈將提示安裝它（npm 或本地路徑），然後才能設定。

## 相關文件

- 精靈概覽：[登機精靈](/zh-Hant/start/wizard)
- macOS app 登機：[登機](/zh-Hant/start/onboarding)
- 設定參考：[Gateway 設定](/zh-Hant/gateway/configuration)
- 提供者：[WhatsApp](/zh-Hant/channels/whatsapp)、[Telegram](/zh-Hant/channels/telegram)、[Discord](/zh-Hant/channels/discord)、[Google Chat](/zh-Hant/channels/googlechat)、[Signal](/zh-Hant/channels/signal)、[BlueBubbles](/zh-Hant/channels/bluebubbles)（iMessage）、[iMessage](/zh-Hant/channels/imessage)（舊版）
- 技能：[技能](/zh-Hant/tools/skills)、[技能設定](/zh-Hant/tools/skills-config)
