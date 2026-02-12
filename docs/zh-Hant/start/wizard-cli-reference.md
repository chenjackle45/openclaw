---
summary: "CLI 入門流程、驗證/模型設定、輸出和內部詳細的完整參考"
read_when:
  - 需要 openclaw onboard 的詳細行為
  - 正在調試入門結果或整合入門客戶端
title: "CLI Onboarding Reference（CLI 入門參考）"
sidebarTitle: "CLI reference"
---

# CLI 入門參考

本頁是 `openclaw onboard` 的完整參考。
關於簡短指南，請參見 [入門精靈（CLI）](/zh-Hant/start/wizard)。

## 精靈做了什麼

本地模式（預設）將指導你完成：

- 模型和驗證設定（OpenAI Code 訂閱 OAuth、Anthropic API 金鑰或設定權杖，加上 MiniMax、GLM、Moonshot 和 AI Gateway 選項）
- 工作區位置和啟動檔案
- Gateway 設定（埠、繫結、驗證、tailscale）
- 頻道和提供者（Telegram、WhatsApp、Discord、Google Chat、Mattermost 外掛、Signal）
- 守護程序安裝（LaunchAgent 或 systemd 使用者單位）
- 健康狀態檢查
- 技能設定

遠端模式設定此機器以連接到其他位置的 Gateway。
它不會安裝或修改遠端主機上的任何內容。

## 本地流程詳細資訊

<Steps>
  <Step title="現有設定檢測">
    - 如果 `~/.openclaw/openclaw.json` 存在，選擇保留、修改或重設。
    - 重新執行精靈不會清除任何內容，除非你明確選擇重設（或傳遞 `--reset`）。
    - 如果設定無效或包含遺舊金鑰，精靈會停止並要求你在繼續前執行 `openclaw doctor`。
    - 重設使用 `trash` 並提供範圍：
      - 僅設定
      - 設定 + 認證 + 會話
      - 完全重設（也移除工作區）
  </Step>
  <Step title="模型和驗證">
    - 完整選項矩陣位於 [驗證和模型選項](#auth-and-model-options)。
  </Step>
  <Step title="工作區">
    - 預設 `~/.openclaw/workspace`（可設定）。
    - 播種首次執行啟動儀式所需的工作區檔案。
    - 工作區配置：[Agent 工作區](/zh-Hant/concepts/agent-workspace)。
  </Step>
  <Step title="Gateway">
    - 提示埠、繫結、驗證模式和 tailscale 曝露。
    - 推薦：即使對於 loopback 也保持啟用權杖驗證，以便本地 WS 客戶端必須驗證。
    - 僅在你完全信任每個本地程序時禁用驗證。
    - 非 loopback 繫結仍需要驗證。
  </Step>
  <Step title="頻道">
    - [WhatsApp](/zh-Hant/channels/whatsapp)：可選 QR 登入
    - [Telegram](/zh-Hant/channels/telegram)：機器人權杖
    - [Discord](/zh-Hant/channels/discord)：機器人權杖
    - [Google Chat](/zh-Hant/channels/googlechat)：服務帳戶 JSON + webhook 對象
    - [Mattermost](/zh-Hant/channels/mattermost) 外掛：機器人權杖 + 基礎 URL
    - [Signal](/zh-Hant/channels/signal)：可選 `signal-cli` 安裝 + 帳戶設定
    - [BlueBubbles](/zh-Hant/channels/bluebubbles)：建議用於 iMessage；伺服器 URL + 密碼 + webhook
    - [iMessage](/zh-Hant/channels/imessage)：遺舊 `imsg` CLI 路徑 + 資料庫存取
    - DM 安全：預設值是配對。首次 DM 傳送程式碼；透過 `openclaw pairing approve <channel> <code>` 核准或使用允許清單。
  </Step>
  <Step title="守護程序安裝">
    - macOS：LaunchAgent
      - 需要登入的使用者會話；對於無頭設定，請使用自訂 LaunchDaemon（未出貨）。
    - Linux 和 Windows（透過 WSL2）：systemd 使用者單位
      - 精靈嘗試透過 `loginctl enable-linger <user>` 啟用遷移，以便 Gateway 在登出後保持執行。
      - 可能提示 sudo（寫入 `/var/lib/systemd/linger`）；它首先嘗試不使用 sudo。
    - 執行時選擇：Node（建議；WhatsApp 和 Telegram 需要）。不建議 Bun。
  </Step>
  <Step title="健康狀態檢查">
    - 啟動 Gateway（如果需要）並執行 `openclaw health`。
    - `openclaw status --deep` 將 Gateway 健康狀態探測新增至狀態輸出。
  </Step>
  <Step title="技能">
    - 讀取可用技能並檢查需求。
    - 讓你選擇節點管理器：npm 或 pnpm（不建議 bun）。
    - 安裝可選相依性（某些在 macOS 上使用 Homebrew）。
  </Step>
  <Step title="完成">
    - 摘要和後續步驟，包括 iOS、Android 和 macOS 應用選項。
  </Step>
</Steps>

<Note>
如果未檢測到 GUI，精靈將列印 Control UI 的 SSH 埠轉發說明，而不是開啟瀏覽器。
如果 Control UI 資產遺失，精靈會嘗試構建它們；回退是 `pnpm ui:build`（自動安裝 UI 相依性）。
</Note>

## 遠端模式詳細資訊

遠端模式設定此機器以連接到其他位置的 Gateway。

<Info>
遠端模式不會安裝或修改遠端主機上的任何內容。
</Info>

你設定什麼：

- 遠端 Gateway URL（`ws://...`）
- 令牌（如果遠端 Gateway 驗證是必需的）（建議）

<Note>
- 如果 Gateway 僅限本地迴圈，請使用 SSH 隧道或 tailnet。
- 發現提示：
  - macOS：Bonjour（`dns-sd`）
  - Linux：Avahi（`avahi-browse`）
</Note>

## 驗證和模型選項

<AccordionGroup>
  <Accordion title="Anthropic API 金鑰（建議）">
    使用 `ANTHROPIC_API_KEY`（如果存在）或提示輸入金鑰，然後儲存以供守護程序使用。
  </Accordion>
  <Accordion title="Anthropic OAuth（Claude Code CLI）">
    - macOS：檢查 Keychain 項目「Claude Code-credentials」
    - Linux 和 Windows：如果 `~/.claude/.credentials.json` 存在則重複使用

    在 macOS 上，選擇「Always Allow」，以便 launchd 啟動不會阻止。

  </Accordion>
  <Accordion title="Anthropic 權杖（設定權杖貼上）">
    在任何機器上執行 `claude setup-token`，然後貼上權杖。
    你可以為它命名；空白使用預設值。
  </Accordion>
  <Accordion title="OpenAI Code 訂閱（Codex CLI 重複使用）">
    如果 `~/.codex/auth.json` 存在，精靈可以重複使用它。
  </Accordion>
  <Accordion title="OpenAI Code 訂閱（OAuth）">
    瀏覽器流程；貼上 `code#state`。

    當模型未設定或 `openai/*` 時，將 `agents.defaults.model` 設定為 `openai-codex/gpt-5.3-codex`。

  </Accordion>
  <Accordion title="OpenAI API 金鑰">
    使用 `OPENAI_API_KEY`（如果存在）或提示輸入金鑰，然後儲存至 `~/.openclaw/.env`，以便 launchd 可以讀取。

    當模型未設定、`openai/*` 或 `openai-codex/*` 時，將 `agents.defaults.model` 設定為 `openai/gpt-5.1-codex`。

  </Accordion>
  <Accordion title="xAI（Grok）API 金鑰">
    提示 `XAI_API_KEY` 並將 xAI 設定為模型提供者。
  </Accordion>
  <Accordion title="OpenCode Zen">
    提示 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`）。
    設定 URL：[opencode.ai/auth](https://opencode.ai/auth)。
  </Accordion>
  <Accordion title="API 金鑰（通用）">
    為你儲存金鑰。
  </Accordion>
  <Accordion title="Vercel AI Gateway">
    提示 `AI_GATEWAY_API_KEY`。
    詳細資訊：[Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)。
  </Accordion>
  <Accordion title="Cloudflare AI Gateway">
    提示帳戶 ID、Gateway ID 和 `CLOUDFLARE_AI_GATEWAY_API_KEY`。
    詳細資訊：[Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)。
  </Accordion>
  <Accordion title="MiniMax M2.1">
    設定是自動寫入的。
    詳細資訊：[MiniMax](/zh-Hant/providers/minimax)。
  </Accordion>
  <Accordion title="Synthetic（Anthropic 相容）">
    提示 `SYNTHETIC_API_KEY`。
    詳細資訊：[Synthetic](/zh-Hant/providers/synthetic)。
  </Accordion>
  <Accordion title="Moonshot 和 Kimi Coding">
    Moonshot（Kimi K2）和 Kimi Coding 設定是自動寫入的。
    詳細資訊：[Moonshot AI（Kimi + Kimi Coding）](/zh-Hant/providers/moonshot)。
  </Accordion>
  <Accordion title="跳過">
    讓驗證未設定。
  </Accordion>
</AccordionGroup>

模型行為：

- 從偵測到的選項中挑選預設模型，或手動輸入提供者和模型。
- 精靈執行模型檢查並警告已設定的模型是否未知或缺少驗證。

認證和設定檔路徑：

- OAuth 認證：`~/.openclaw/credentials/oauth.json`
- 驗證設定檔（API 金鑰 + OAuth）：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`

<Note>
無頭和伺服器提示：在具有瀏覽器的機器上完成 OAuth，然後將 `~/.openclaw/credentials/oauth.json`（或 `$OPENCLAW_STATE_DIR/credentials/oauth.json`）複製到 Gateway 主機。
</Note>

## 輸出和內部

`~/.openclaw/openclaw.json` 中的典型欄位：

- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（如果選擇了 Minimax）
- `gateway.*`（模式、繫結、驗證、tailscale）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 頻道允許清單（Slack、Discord、Matrix、Microsoft Teams）（當你在提示期間選擇時）（名稱在可能時解析為 ID）
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw agents add` 寫入 `agents.list[]` 和可選 `bindings`。

WhatsApp 認證位於 `~/.openclaw/credentials/whatsapp/<accountId>/`。
會話儲存在 `~/.openclaw/agents/<agentId>/sessions/`。

<Note>
某些頻道以外掛方式提供。選定期間選擇時，精靈會提示安裝外掛（npm 或本地路徑），才能進行頻道設定。
</Note>

Gateway 精靈 RPC：

- `wizard.start`
- `wizard.next`
- `wizard.cancel`
- `wizard.status`

客戶端（macOS 應用和 Control UI）可以無需重新實作入門邏輯即可呈現步驟。

Signal 設定行為：

- 下載適當的發佈資產
- 儲存在 `~/.openclaw/tools/signal-cli/<version>/` 下
- 在設定中寫入 `channels.signal.cliPath`
- JVM 組態需要 Java 21
- 在可用時使用原生組態
- Windows 使用 WSL2 並在 WSL 內遵循 Linux signal-cli 流程

## 相關文件

- 入門中樞：[入門精靈（CLI）](/zh-Hant/start/wizard)
- 自動化和指令碼：[CLI 自動化](/zh-Hant/start/wizard-cli-automation)
- 命令參考：[`openclaw onboard`](/zh-Hant/cli/onboard)
