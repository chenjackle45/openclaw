---
summary: "CLI 入門精靈：Gateway、工作區、頻道和技能的引導式設定"
read_when:
  - 執行或設定入門精靈時
  - 設定新機器時
title: "Onboarding Wizard (CLI)（CLI 入門精靈）"
sidebarTitle: "Onboarding: CLI"
---

# 入門精靈（CLI）

入門精靈是在 macOS、Linux 或 Windows（透過 WSL2；強烈推薦）上設定 OpenClaw 的**推薦**方式。
它在一個引導流程中設定本地 Gateway 或遠端 Gateway 連線，加上頻道、技能和工作區預設值。

```bash
openclaw onboard
```

<Info>
最快的第一次聊天：開啟控制 UI（無需設定頻道）。執行
`openclaw dashboard` 並在瀏覽器中聊天。文件：[Dashboard](/zh-Hant/web/dashboard)。
</Info>

之後重新設定：

```bash
openclaw configure
openclaw agents add <name>
```

<Note>
`--json` 不代表非互動式模式。對於腳本，請使用 `--non-interactive`。
</Note>

<Tip>
入門精靈包含一個網路搜尋步驟，您可以選擇提供者
（Perplexity、Brave、Gemini、Grok 或 Kimi）並貼上您的 API key，讓代理程式
可以使用 `web_search`。您也可以稍後透過
`openclaw configure --section web` 設定。文件：[Web 工具](/zh-Hant/tools/web)。
</Tip>

## QuickStart vs Advanced（進階）

精靈以 **QuickStart**（預設值）vs **Advanced（進階）**（完整控制）開始。

<Tabs>
  <Tab title="QuickStart（預設值）">
    - 本地 gateway（環回）
    - 工作區預設（或現有工作區）
    - Gateway 連接埠 **18789**
    - Gateway 認證 **Token**（自動產生，即使在環回上）
    - 新本地設定的工具政策預設：`tools.profile: "coding"`（現有明確設定檔予以保留）
    - DM 隔離預設：本地入門在未設定時寫入 `session.dmScope: "per-channel-peer"`。詳情：[CLI 入門參考](/zh-Hant/start/wizard-cli-reference#outputs-and-internals)
    - Tailscale 曝露 **關閉**
    - Telegram + WhatsApp DM 預設為**允許清單**（系統會提示您輸入電話號碼）
  </Tab>
  <Tab title="Advanced（進階，完整控制）">
    - 顯示每個步驟（模式、工作區、gateway、頻道、daemon、技能）。
  </Tab>
</Tabs>

## 精靈設定的內容

**本地模式（預設）**引導您完成這些步驟：

1. **模型/認證** — 選擇任何支援的提供者/認證流程（API key、OAuth 或 setup-token），包括自訂提供者
   （OpenAI 相容、Anthropic 相容或未知自動偵測）。選擇預設模型。
   安全說明：如果此代理程式將執行工具或處理 webhook/hooks 內容，請優先使用最強的最新一代模型並保持嚴格的工具政策。較弱/較舊的層更容易受到提示注入攻擊。
   對於非互動式執行，`--secret-input-mode ref` 將 env 支援的 refs 儲存在認證設定檔中，而非明文 API key 值。
   在非互動式 `ref` 模式中，必須設定提供者環境變數；未設定該環境變數而傳入內聯 key 標誌會快速失敗。
   在互動式執行中，選擇 secret reference 模式讓您指向環境變數或已設定的提供者 ref（`file` 或 `exec`），在儲存前進行快速預檢驗證。
2. **工作區** — 代理程式檔案的位置（預設 `~/.openclaw/workspace`）。植入引導檔案。
3. **Gateway** — 連接埠、綁定位址、認證模式、Tailscale 曝露。
   在互動式 token 模式中，選擇預設明文 token 儲存或選用 SecretRef。
   非互動式 token SecretRef 路徑：`--gateway-token-ref-env <ENV_VAR>`。
4. **頻道** — WhatsApp、Telegram、Discord、Google Chat、Mattermost、Signal、BlueBubbles 或 iMessage。
5. **Daemon** — 安裝 LaunchAgent（macOS）或 systemd 使用者單元（Linux/WSL2）。
   如果 token 認證需要 token 且 `gateway.auth.token` 由 SecretRef 管理，daemon 安裝會驗證它，但不會將解析後的 token 持久化到監督服務環境中繼資料中。
   如果 token 認證需要 token 且已設定的 token SecretRef 未解析，daemon 安裝會被封鎖並提供可操作的指引。
   如果同時設定了 `gateway.auth.token` 和 `gateway.auth.password` 且 `gateway.auth.mode` 未設定，daemon 安裝會被封鎖直到明確設定模式。
6. **健康檢查** — 啟動 Gateway 並驗證它正在執行。
7. **技能** — 安裝推薦的技能和選用相依套件。

<Note>
重新執行精靈**不會**清除任何內容，除非您明確選擇**重設**（或傳入 `--reset`）。
CLI `--reset` 預設為設定、憑證和會話；使用 `--reset-scope full` 包含工作區。
如果設定無效或包含舊版金鑰，精靈會要求您先執行 `openclaw doctor`。
</Note>

**遠端模式**僅設定本地客戶端連接到其他地方的 Gateway。
它**不會**在遠端主機上安裝或變更任何東西。

## 新增另一個代理程式

使用 `openclaw agents add <name>` 建立具有自己工作區、
會話和認證設定檔的獨立代理程式。不使用 `--workspace` 執行會啟動精靈。

設定的內容：

- `agents.list[].name`
- `agents.list[].workspace`
- `agents.list[].agentDir`

說明：

- 預設工作區遵循 `~/.openclaw/workspace-<agentId>`。
- 新增 `bindings` 路由入站訊息（精靈可執行此操作）。
- 非互動式標誌：`--model`、`--agent-dir`、`--bind`、`--non-interactive`。

## 完整參考

如需詳細的逐步說明、非互動式腳本、Signal 設定、
RPC API 和精靈寫入的完整設定欄位清單，請參閱
[精靈參考](/zh-Hant/reference/wizard)。

## 相關文件

- CLI 命令參考：[`openclaw onboard`](/zh-Hant/cli/onboard)
- 入門概覽：[入門概覽](/zh-Hant/start/onboarding-overview)
- macOS 應用程式入門：[入門流程](/zh-Hant/start/onboarding)
- 代理程式首次執行儀式：[代理程式引導](/zh-Hant/start/bootstrapping)
