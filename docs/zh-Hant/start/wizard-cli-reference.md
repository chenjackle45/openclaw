---
summary: "CLI 入門流程、認證/模型設定、輸出和內部機制的完整參考"
read_when:
  - 需要 openclaw onboard 詳細行為時
  - 正在偵錯入門結果或整合入門客戶端時
title: "CLI Onboarding Reference（CLI 入門參考）"
sidebarTitle: "CLI reference"
---

# CLI 入門參考

本頁是 `openclaw onboard` 的完整參考。
如需簡短指南，請參閱[入門精靈（CLI）](/zh-Hant/start/wizard)。

## 精靈的功能

本地模式（預設）會引導您完成：

- 模型和認證設定（OpenAI Code 訂閱 OAuth、Anthropic API key 或 setup token，以及 MiniMax、GLM、Moonshot 和 AI Gateway 選項）
- 工作區位置和引導檔案
- Gateway 設定（連接埠、綁定、認證、tailscale）
- 頻道和提供者（Telegram、WhatsApp、Discord、Google Chat、Mattermost 外掛、Signal）
- Daemon 安裝（LaunchAgent 或 systemd 使用者單元）
- 健康檢查
- 技能設定

遠端模式設定此機器連接到其他地方的 gateway。
它不會在遠端主機上安裝或修改任何東西。

## 本地流程詳情

<Steps>
  <Step title="偵測現有設定">
    - 如果 `~/.openclaw/openclaw.json` 存在，選擇保留、修改或重設。
    - 重新執行精靈不會清除任何內容，除非您明確選擇重設（或傳入 `--reset`）。
    - CLI `--reset` 預設為 `config+creds+sessions`；使用 `--reset-scope full` 也可移除工作區。
    - 如果設定無效或包含舊版金鑰，精靈會停止並要求您在繼續之前執行 `openclaw doctor`。
    - 重設使用 `trash` 並提供範圍選項：
      - 僅設定
      - 設定 + 憑證 + 會話
      - 完整重設（也移除工作區）
  </Step>
  <Step title="模型和認證">
    - 完整的選項矩陣請見[認證和模型選項](#auth-and-model-options)。
  </Step>
  <Step title="工作區">
    - 預設 `~/.openclaw/workspace`（可設定）。
    - 植入首次執行引導儀式所需的工作區檔案。
    - 工作區佈局：[代理程式工作區](/zh-Hant/concepts/agent-workspace)。
  </Step>
  <Step title="Gateway">
    - 提示輸入連接埠、綁定、認證模式和 tailscale 曝露。
    - 建議：即使對環回也保持 token 認證啟用，這樣本地 WS 客戶端必須認證。
    - 在 token 模式中，互動式入門提供：
      - **產生/儲存明文 token**（預設）
      - **使用 SecretRef**（選用啟用）
    - 在密碼模式中，互動式入門也支援明文或 SecretRef 儲存。
    - 非互動式 token SecretRef 路徑：`--gateway-token-ref-env <ENV_VAR>`。
      - 在入門程序環境中需要非空的環境變數。
      - 不能與 `--gateway-token` 組合使用。
    - 只有在完全信任每個本地程序時才停用認證。
    - 非環回綁定仍然需要認證。
  </Step>
  <Step title="頻道">
    - [WhatsApp](/zh-Hant/channels/whatsapp)：選用 QR 登入
    - [Telegram](/zh-Hant/channels/telegram)：機器人 token
    - [Discord](/zh-Hant/channels/discord)：機器人 token
    - [Google Chat](/zh-Hant/channels/googlechat)：服務帳號 JSON + webhook audience
    - [Mattermost](/zh-Hant/channels/mattermost) 外掛：機器人 token + 基本 URL
    - [Signal](/zh-Hant/channels/signal)：選用 `signal-cli` 安裝 + 帳號設定
    - [BlueBubbles](/zh-Hant/channels/bluebubbles)：建議用於 iMessage；伺服器 URL + 密碼 + webhook
    - [iMessage](/zh-Hant/channels/imessage)：舊版 `imsg` CLI 路徑 + 資料庫存取
    - DM 安全性：預設為配對。第一個 DM 發送驗證碼；透過 `openclaw pairing approve <channel> <code>` 核准或使用允許清單。
  </Step>
  <Step title="Daemon 安裝">
    - macOS：LaunchAgent
      - 需要已登入的使用者會話；對於無頭設定，請使用自訂 LaunchDaemon（未隨附）。
    - Linux 和 Windows（透過 WSL2）：systemd 使用者單元
      - 精靈嘗試執行 `loginctl enable-linger <user>` 使 gateway 在登出後仍然執行。
      - 可能提示 sudo（寫入 `/var/lib/systemd/linger`）；先嘗試不使用 sudo。
    - 執行階段選擇：Node（建議；WhatsApp 和 Telegram 需要）。不建議使用 Bun。
  </Step>
  <Step title="健康檢查">
    - 啟動 gateway（如需要）並執行 `openclaw health`。
    - `openclaw status --deep` 將 gateway 健康探測加入狀態輸出。
  </Step>
  <Step title="技能">
    - 讀取可用技能並檢查需求。
    - 讓您選擇節點管理器：npm 或 pnpm（不建議使用 bun）。
    - 安裝選用相依套件（某些在 macOS 上使用 Homebrew）。
  </Step>
  <Step title="完成">
    - 摘要和後續步驟，包括 iOS、Android 和 macOS 應用程式選項。
  </Step>
</Steps>

<Note>
如果未偵測到 GUI，精靈會印出 SSH 連接埠轉發指示以使用控制 UI，而非開啟瀏覽器。
如果控制 UI 資產遺失，精靈嘗試建置它們；後備方案是 `pnpm ui:build`（自動安裝 UI 相依套件）。
</Note>

## 遠端模式詳情

遠端模式設定此機器連接到其他地方的 gateway。

<Info>
遠端模式不會在遠端主機上安裝或修改任何東西。
</Info>

您設定的內容：

- 遠端 gateway URL（`ws://...`）
- 如果遠端 gateway 需要認證，則提供 token（建議）

<Note>
- 如果 gateway 僅限環回，請使用 SSH 隧道或 tailnet。
- 探索提示：
  - macOS：Bonjour（`dns-sd`）
  - Linux：Avahi（`avahi-browse`）
</Note>

## 認證和模型選項

<AccordionGroup>
  <Accordion title="Anthropic API key">
    使用 `ANTHROPIC_API_KEY`（如果存在）或提示輸入金鑰，然後儲存供 daemon 使用。
  </Accordion>
  <Accordion title="Anthropic OAuth（Claude Code CLI）">
    - macOS：檢查 Keychain 項目「Claude Code-credentials」
    - Linux 和 Windows：若存在則重用 `~/.claude/.credentials.json`

    在 macOS 上，選擇「Always Allow」以防止 launchd 啟動時被封鎖。

  </Accordion>
  <Accordion title="Anthropic token（setup-token 貼上）">
    在任何機器上執行 `claude setup-token`，然後貼上 token。
    可命名；空白則使用預設。
  </Accordion>
  <Accordion title="OpenAI Code 訂閱（Codex CLI 重用）">
    如果 `~/.codex/auth.json` 存在，精靈可重用它。
  </Accordion>
  <Accordion title="OpenAI Code 訂閱（OAuth）">
    瀏覽器流程；貼上 `code#state`。

    當模型未設定或為 `openai/*` 時，將 `agents.defaults.model` 設為 `openai-codex/gpt-5.4`。

  </Accordion>
  <Accordion title="OpenAI API key">
    使用 `OPENAI_API_KEY`（如果存在）或提示輸入金鑰，然後將憑證儲存在認證設定檔中。

    當模型未設定、為 `openai/*` 或 `openai-codex/*` 時，將 `agents.defaults.model` 設為 `openai/gpt-5.1-codex`。

  </Accordion>
  <Accordion title="xAI（Grok）API key">
    提示輸入 `XAI_API_KEY` 並將 xAI 設定為模型提供者。
  </Accordion>
  <Accordion title="OpenCode Zen">
    提示輸入 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`）。
    設定 URL：[opencode.ai/auth](https://opencode.ai/auth)。
  </Accordion>
  <Accordion title="API key（通用）">
    為您儲存金鑰。
  </Accordion>
  <Accordion title="Vercel AI Gateway">
    提示輸入 `AI_GATEWAY_API_KEY`。
    更多詳情：[Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)。
  </Accordion>
  <Accordion title="Cloudflare AI Gateway">
    提示輸入帳號 ID、gateway ID 和 `CLOUDFLARE_AI_GATEWAY_API_KEY`。
    更多詳情：[Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)。
  </Accordion>
  <Accordion title="MiniMax M2.5">
    設定自動寫入。
    更多詳情：[MiniMax](/zh-Hant/providers/minimax)。
  </Accordion>
  <Accordion title="Synthetic（Anthropic 相容）">
    提示輸入 `SYNTHETIC_API_KEY`。
    更多詳情：[Synthetic](/zh-Hant/providers/synthetic)。
  </Accordion>
  <Accordion title="Moonshot 和 Kimi Coding">
    Moonshot（Kimi K2）和 Kimi Coding 設定自動寫入。
    更多詳情：[Moonshot AI（Kimi + Kimi Coding）](/zh-Hant/providers/moonshot)。
  </Accordion>
  <Accordion title="自訂提供者">
    適用於 OpenAI 相容和 Anthropic 相容端點。

    互動式入門支援與其他提供者 API key 流程相同的 API key 儲存選項：
    - **立即貼上 API key**（明文）
    - **使用 secret reference**（env ref 或已設定的提供者 ref，含預檢驗證）

    非互動式標誌：
    - `--auth-choice custom-api-key`
    - `--custom-base-url`
    - `--custom-model-id`
    - `--custom-api-key`（選用；後備為 `CUSTOM_API_KEY`）
    - `--custom-provider-id`（選用）
    - `--custom-compatibility <openai|anthropic>`（選用；預設 `openai`）

  </Accordion>
  <Accordion title="跳過">
    保持認證未設定。
  </Accordion>
</AccordionGroup>

模型行為：

- 從偵測到的選項中選擇預設模型，或手動輸入提供者和模型。
- 精靈執行模型檢查，如果設定的模型未知或缺少認證則發出警告。

憑證和設定檔路徑：

- OAuth 憑證：`~/.openclaw/credentials/oauth.json`
- 認證設定檔（API keys + OAuth）：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`

憑證儲存模式：

- 預設入門行為將 API key 以明文值持久化在認證設定檔中。
- `--secret-input-mode ref` 啟用參考模式而非明文 key 儲存。
  在互動式入門中，您可以選擇：
  - 環境變數 ref（例如 `keyRef: { source: "env", provider: "default", id: "OPENAI_API_KEY" }`）
  - 已設定的提供者 ref（`file` 或 `exec`）含提供者別名 + id
- 互動式參考模式在儲存前執行快速預檢驗證。
  - Env refs：驗證變數名稱 + 目前入門環境中的非空值。
  - 提供者 refs：驗證提供者設定並解析請求的 id。
  - 如果預檢失敗，入門顯示錯誤並讓您重試。
- 在非互動式模式中，`--secret-input-mode ref` 僅支援 env 支援的模式。
  - 在入門程序環境中設定提供者環境變數。
  - 內聯 key 標誌（例如 `--openai-api-key`）需要設定該環境變數；否則入門快速失敗。
  - 對於自訂提供者，非互動式 `ref` 模式將 `models.providers.<id>.apiKey` 儲存為 `{ source: "env", provider: "default", id: "CUSTOM_API_KEY" }`。
  - 在該自訂提供者情況下，`--custom-api-key` 需要設定 `CUSTOM_API_KEY`；否則入門快速失敗。
- Gateway 認證憑證在互動式入門中支援明文和 SecretRef 選項：
  - Token 模式：**產生/儲存明文 token**（預設）或**使用 SecretRef**。
  - 密碼模式：明文或 SecretRef。
- 非互動式 token SecretRef 路徑：`--gateway-token-ref-env <ENV_VAR>`。
- 現有的明文設定繼續不變地運作。

<Note>
無頭和伺服器提示：在有瀏覽器的機器上完成 OAuth，然後將
`~/.openclaw/credentials/oauth.json`（或 `$OPENCLAW_STATE_DIR/credentials/oauth.json`）
複製到 gateway 主機。
</Note>

## 輸出和內部機制

`~/.openclaw/openclaw.json` 中的典型欄位：

- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（如果選擇 Minimax）
- `tools.profile`（本地入門預設為 `"coding"`（未設定時）；現有明確值予以保留）
- `gateway.*`（模式、綁定、認證、tailscale）
- `session.dmScope`（本地入門預設為 `per-channel-peer`（未設定時）；現有明確值予以保留）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 頻道允許清單（Slack、Discord、Matrix、Microsoft Teams），當您在提示中選擇時（名稱盡可能解析為 ID）
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw agents add` 寫入 `agents.list[]` 和選用的 `bindings`。

WhatsApp 憑證存放在 `~/.openclaw/credentials/whatsapp/<accountId>/` 下。
會話存放在 `~/.openclaw/agents/<agentId>/sessions/` 下。

<Note>
某些頻道以外掛形式提供。在入門過程中選擇時，精靈
在頻道設定之前提示安裝外掛（npm 或本地路徑）。
</Note>

Gateway 精靈 RPC：

- `wizard.start`
- `wizard.next`
- `wizard.cancel`
- `wizard.status`

客戶端（macOS 應用程式和控制 UI）可以渲染步驟而無需重新實作入門邏輯。

Signal 設定行為：

- 下載適當的發布資產
- 儲存在 `~/.openclaw/tools/signal-cli/<version>/` 下
- 在設定中寫入 `channels.signal.cliPath`
- JVM 版本需要 Java 21
- 可用時使用原生版本
- Windows 使用 WSL2 並在 WSL 內遵循 Linux signal-cli 流程

## 相關文件

- 入門中心：[入門精靈（CLI）](/zh-Hant/start/wizard)
- 自動化和腳本：[CLI 自動化](/zh-Hant/start/wizard-cli-automation)
- 命令參考：[`openclaw onboard`](/zh-Hant/cli/onboard)
