---
title: "FAQ(常見問題)"
summary: "OpenClaw 設定、配置和使用的常見問題"
---
# FAQ(常見問題)

快速解答以及針對實際設定（本機開發、VPS、多 Agent、OAuth/API 金鑰、模型故障轉移）的深入疑難排解。運行時診斷請參閱 [疑難排解](/zh-Hant/gateway/troubleshooting)。完整設定參考請參閱 [配置](/zh-Hant/gateway/configuration)。

## 目錄

- [快速開始與首次執行設定](#快速開始與首次執行設定)
  - [我卡住了，最快的解決方法是什麼？](#我卡住了最快的解決方法是什麼)
  - [安裝和設定 OpenClaw 的建議方式是什麼？](#安裝和設定-openclaw-的建議方式是什麼)
  - [引導完成後如何開啟儀表板？](#引導完成後如何開啟儀表板)
  - [如何在 localhost 與遠端驗證儀表板 token？](#如何在-localhost-與遠端驗證儀表板-token)
  - [我需要什麼運行環境？](#我需要什麼運行環境)
  - [可以在 Raspberry Pi 上執行嗎？](#可以在-raspberry-pi-上執行嗎)
  - [Raspberry Pi 安裝有什麼建議？](#raspberry-pi-安裝有什麼建議)
  - [卡在「wake up my friend」/ 引導無法完成，怎麼辦？](#卡在-wake-up-my-friend-引導無法完成怎麼辦)
  - [可以將設定遷移到新機器（Mac mini）而不重做引導嗎？](#可以將設定遷移到新機器mac-mini而不重做引導嗎)
  - [在哪裡查看最新版本的更新內容？](#在哪裡查看最新版本的更新內容)
  - [無法存取 docs.openclaw.ai（SSL 錯誤），怎麼辦？](#無法存取-docsopenclawaissl-錯誤怎麼辦)
  - [stable 和 beta 有什麼區別？](#stable-和-beta-有什麼區別)
- [如何安裝 beta 版本，beta 和 dev 有什麼區別？](#如何安裝-beta-版本beta-和-dev-有什麼區別)
  - [如何嘗試最新的程式碼？](#如何嘗試最新的程式碼)
  - [安裝和引導通常需要多長時間？](#安裝和引導通常需要多長時間)
  - [安裝程式卡住了？如何獲得更多回饋？](#安裝程式卡住了如何獲得更多回饋)
  - [Windows 安裝顯示 git 找不到或 openclaw 無法識別](#windows-安裝顯示-git-找不到或-openclaw-無法識別)
  - [文件沒有回答我的問題 - 如何獲得更好的答案？](#文件沒有回答我的問題---如何獲得更好的答案)
  - [如何在 Linux 上安裝 OpenClaw？](#如何在-linux-上安裝-openclaw)
  - [如何在 VPS 上安裝 OpenClaw？](#如何在-vps-上安裝-openclaw)
  - [雲端/VPS 安裝指南在哪裡？](#雲端vps-安裝指南在哪裡)
  - [可以讓 OpenClaw 自己更新嗎？](#可以讓-openclaw-自己更新嗎)
  - [引導精靈實際做了什麼？](#引導精靈實際做了什麼)
  - [需要 Claude 或 OpenAI 訂閱才能執行嗎？](#需要-claude-或-openai-訂閱才能執行嗎)
  - [可以不用 API 金鑰使用 Claude Max 訂閱嗎？](#可以不用-api-金鑰使用-claude-max-訂閱嗎)
  - [Anthropic setup-token 驗證如何運作？](#anthropic-setup-token-驗證如何運作)
  - [在哪裡找到 Anthropic setup-token？](#在哪裡找到-anthropic-setup-token)
  - [支援 Claude 訂閱驗證（Claude Code OAuth）嗎？](#支援-claude-訂閱驗證claude-code-oauth嗎)
  - [為什麼看到 HTTP 429: rate_limit_error？](#為什麼看到-http-429-rate_limit_error)
  - [支援 AWS Bedrock 嗎？](#支援-aws-bedrock-嗎)
  - [Codex 驗證如何運作？](#codex-驗證如何運作)
  - [支援 OpenAI 訂閱驗證（Codex OAuth）嗎？](#支援-openai-訂閱驗證codex-oauth嗎)
  - [如何設定 Gemini CLI OAuth？](#如何設定-gemini-cli-oauth)
  - [本地模型適合日常聊天嗎？](#本地模型適合日常聊天嗎)
  - [如何將託管模型流量保持在特定區域？](#如何將託管模型流量保持在特定區域)
  - [必須購買 Mac Mini 才能安裝嗎？](#必須購買-mac-mini-才能安裝嗎)
  - [iMessage 支援需要 Mac mini 嗎？](#imessage-支援需要-mac-mini-嗎)
  - [如果購買 Mac mini 執行 OpenClaw，可以連接到 MacBook Pro 嗎？](#如果購買-mac-mini-執行-openclaw可以連接到-macbook-pro-嗎)
  - [可以使用 Bun 嗎？](#可以使用-bun-嗎)
  - [Telegram: allowFrom 要填什麼？](#telegram-allowfrom-要填什麼)
  - [多人可以使用同一個 WhatsApp 號碼搭配不同的 OpenClaw 實例嗎？](#多人可以使用同一個-whatsapp-號碼搭配不同的-openclaw-實例嗎)
  - [可以同時執行「快速聊天」agent 和「Opus 寫程式」agent 嗎？](#可以同時執行快速聊天-agent-和opus-寫程式-agent-嗎)
  - [Homebrew 在 Linux 上可用嗎？](#homebrew-在-linux-上可用嗎)
  - [hackable (git) 安裝和 npm 安裝有什麼區別？](#hackable-git-安裝和-npm-安裝有什麼區別)
  - [之後可以在 npm 和 git 安裝之間切換嗎？](#之後可以在-npm-和-git-安裝之間切換嗎)
  - [應該在筆電還是 VPS 上執行 Gateway？](#應該在筆電還是-vps-上執行-gateway)
  - [在專用機器上執行 OpenClaw 有多重要？](#在專用機器上執行-openclaw-有多重要)
  - [VPS 最低需求和建議作業系統是什麼？](#vps-最低需求和建議作業系統是什麼)
  - [可以在 VM 中執行 OpenClaw 嗎？需求是什麼？](#可以在-vm-中執行-openclaw-嗎需求是什麼)
- [什麼是 OpenClaw？](#什麼是-openclaw)
  - [用一段話說明 OpenClaw 是什麼？](#用一段話說明-openclaw-是什麼)
  - [價值主張是什麼？](#價值主張是什麼)
  - [剛設定好，應該先做什麼？](#剛設定好應該先做什麼)
  - [OpenClaw 的前五大日常使用案例是什麼？](#openclaw-的前五大日常使用案例是什麼)
  - [OpenClaw 可以幫助 SaaS 的潛在客戶開發、外展廣告和部落格嗎？](#openclaw-可以幫助-saas-的潛在客戶開發外展廣告和部落格嗎)
  - [與 Claude Code 相比在網頁開發方面有什麼優勢？](#與-claude-code-相比在網頁開發方面有什麼優勢)
- [Skills 和自動化](#skills-和自動化)
- [沙箱和記憶](#沙箱和記憶)
- [檔案儲存位置](#檔案儲存位置)
- [設定基礎](#設定基礎)
- [遠端 Gateway + Nodes](#遠端-gateway--nodes)
- [環境變數和 .env 載入](#環境變數和-env-載入)
- [Sessions 與多重聊天](#sessions-與多重聊天)
- [模型：預設、選擇、別名、切換](#模型預設選擇別名切換)
- [模型故障轉移和「所有模型都失敗了」](#模型故障轉移和所有模型都失敗了)
- [驗證設定檔：它們是什麼以及如何管理](#驗證設定檔它們是什麼以及如何管理)
- [Gateway：連接埠、「已在執行」和遠端模式](#gateway連接埠已在執行和遠端模式)
- [日誌和除錯](#日誌和除錯)
- [媒體與附件](#媒體與附件)
- [安全性和存取控制](#安全性和存取控制)
- [聊天指令、中止任務和「它不會停止」](#聊天指令中止任務和它不會停止)

## 出問題時的前 60 秒

1) **快速狀態（第一步檢查）**
   ```bash
   openclaw status
   ```
   快速本地摘要：作業系統 + 更新、gateway/服務可達性、agents/sessions、供應商設定 + 執行時問題（當 gateway 可達時）。

2) **可貼上報告（可安全分享）**
   ```bash
   openclaw status --all
   ```
   唯讀診斷與日誌尾端（token 已遮蔽）。

3) **Daemon + 連接埠狀態**
   ```bash
   openclaw gateway status
   ```
   顯示 supervisor 執行狀態 vs RPC 可達性、探測目標 URL，以及服務可能使用的設定。

4) **深度探測**
   ```bash
   openclaw status --deep
   ```
   執行 gateway 健康檢查 + 供應商探測（需要可達的 gateway）。參閱 [Health](/zh-Hant/gateway/health)。

5) **追蹤最新日誌**
   ```bash
   openclaw logs --follow
   ```
   如果 RPC 無法使用，改用：
   ```bash
   tail -f "$(ls -t /tmp/openclaw/openclaw-*.log | head -1)"
   ```
   檔案日誌與服務日誌是分開的；參閱 [Logging](/zh-Hant/logging) 和 [疑難排解](/zh-Hant/gateway/troubleshooting)。

6) **執行 doctor（修復）**
   ```bash
   openclaw doctor
   ```
   修復/遷移設定/狀態 + 執行健康檢查。參閱 [Doctor](/zh-Hant/gateway/doctor)。

7) **Gateway 快照**
   ```bash
   openclaw health --json
   openclaw health --verbose   # 錯誤時顯示目標 URL + 設定路徑
   ```
   向執行中的 gateway 請求完整快照（僅限 WS）。參閱 [Health](/zh-Hant/gateway/health)。

## 快速開始與首次執行設定

### 我卡住了最快的解決方法是什麼

使用可以**看到你的機器**的本地 AI agent。這比在 Discord 問問題有效得多，因為大多數「我卡住了」的情況是**本地設定或環境問題**，遠端幫手無法檢查。

- **Claude Code**: https://www.anthropic.com/claude-code/
- **OpenAI Codex**: https://openai.com/codex/

這些工具可以讀取 repo、執行指令、檢查日誌，並幫助修復機器層級的設定（PATH、服務、權限、驗證檔案）。透過 hackable (git) 安裝給它們**完整的原始碼 checkout**：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --install-method git
```

這會從 **git checkout** 安裝 OpenClaw，讓 agent 可以讀取程式碼 + 文件，並針對你執行的確切版本進行推理。之後可以不加 `--install-method git` 重新執行安裝程式切換回 stable。

提示：請 agent **規劃並監督**修復（逐步），然後只執行必要的指令。這樣變更較小且更容易審查。

如果發現真正的 bug 或修復，請提交 GitHub issue 或送出 PR：
https://github.com/openclaw/openclaw/issues
https://github.com/openclaw/openclaw/pulls

從這些指令開始（求助時分享輸出）：

```bash
openclaw status
openclaw models status
openclaw doctor
```

它們做什麼：
- `openclaw status`：gateway/agent 健康狀態 + 基本設定的快速快照。
- `openclaw models status`：檢查供應商驗證 + 模型可用性。
- `openclaw doctor`：驗證並修復常見設定/狀態問題。

其他有用的 CLI 檢查：`openclaw status --all`、`openclaw logs --follow`、`openclaw gateway status`、`openclaw health --verbose`。

快速除錯循環：[出問題時的前 60 秒](#出問題時的前-60-秒)。
安裝文件：[安裝](/zh-Hant/install)、[安裝程式旗標](/zh-Hant/install/installer)、[更新](/zh-Hant/install/updating)。

### 安裝和設定-openclaw-的建議方式是什麼

Repo 建議從原始碼執行並使用引導精靈：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
openclaw onboard --install-daemon
```

精靈也可以自動建置 UI assets。引導完成後，通常在連接埠 **18789** 執行 Gateway。

從原始碼（貢獻者/開發）：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm build
pnpm ui:build # 首次執行時自動安裝 UI 依賴
openclaw onboard
```

如果還沒有全域安裝，透過 `pnpm openclaw onboard` 執行。

### 引導完成後如何開啟儀表板

精靈現在會在引導完成後立即用帶 token 的儀表板 URL 開啟瀏覽器，並在摘要中印出完整連結（帶 token）。保持該分頁開啟；如果沒有啟動，在同一台機器上複製/貼上印出的 URL。Token 保留在本地主機——瀏覽器不會從外部獲取任何東西。

### 如何在-localhost-與遠端驗證儀表板-token

**Localhost（同一台機器）：**
- 開啟 `http://127.0.0.1:18789/`。
- 如果要求驗證，執行 `openclaw dashboard` 並使用帶 token 的連結（`?token=...`）。
- Token 值與 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）相同，UI 在首次載入後會儲存它。

**非 localhost：**
- **Tailscale Serve**（建議）：保持 bind loopback，執行 `openclaw gateway --tailscale serve`，開啟 `https://<magicdns>/`。如果 `gateway.auth.allowTailscale` 為 `true`，身份標頭滿足驗證（不需要 token）。
- **Tailnet bind**：執行 `openclaw gateway --bind tailnet --token "<token>"`，開啟 `http://<tailscale-ip>:18789/`，在儀表板設定中貼上 token。
- **SSH tunnel**：`ssh -N -L 18789:127.0.0.1:18789 user@host` 然後從 `openclaw dashboard` 開啟 `http://127.0.0.1:18789/?token=...`。

參閱 [Dashboard](/zh-Hant/web/dashboard) 和 [Web 介面](/zh-Hant/web) 了解 bind 模式和驗證詳情。

### 我需要什麼運行環境

Node **>= 22** 是必需的。建議使用 `pnpm`。**不建議**用 Bun 執行 Gateway。

### 可以在-raspberry-pi-上執行嗎

可以。Gateway 很輕量——文件列出 **512MB-1GB RAM**、**1 核心**和約 **500MB** 磁碟空間足以供個人使用，並指出 **Raspberry Pi 4 可以執行它**。

如果需要額外空間（日誌、媒體、其他服務），**建議 2GB**，但這不是硬性最低要求。

提示：小型 Pi/VPS 可以託管 Gateway，你可以在筆電/手機上配對 **nodes** 以獲得本地螢幕/相機/canvas 或指令執行。參閱 [Nodes](/zh-Hant/nodes)。

### raspberry-pi-安裝有什麼建議

簡短版：可以用，但預期會有些粗糙的邊緣。

- 使用 **64 位元** 作業系統並保持 Node >= 22。
- 優先使用 **hackable (git) 安裝**，這樣可以看到日誌並快速更新。
- 開始時不要啟用 channels/skills，然後逐一添加。
- 如果遇到奇怪的二進制問題，通常是 **ARM 相容性**問題。

文件：[Linux](/zh-Hant/platforms/linux)、[安裝](/zh-Hant/install)。

### 卡在-wake-up-my-friend-引導無法完成怎麼辦

該畫面依賴 Gateway 可達且已驗證。TUI 也會在首次孵化時自動發送「Wake up, my friend!」。如果你看到該行**沒有回覆**且 token 保持為 0，表示 agent 從未執行。

1) 重啟 Gateway：
```bash
openclaw gateway restart
```
2) 檢查狀態 + 驗證：
```bash
openclaw status
openclaw models status
openclaw logs --follow
```
3) 如果仍然卡住，執行：
```bash
openclaw doctor
```

如果 Gateway 是遠端的，確保 tunnel/Tailscale 連線正常，且 UI 指向正確的 Gateway。參閱 [遠端存取](/zh-Hant/gateway/remote)。

### 可以將設定遷移到新機器mac-mini而不重做引導嗎

可以。複製**狀態目錄**和**工作區**，然後執行一次 Doctor。只要複製**兩個**位置，這會讓你的 bot「完全一樣」（記憶、session 歷史、驗證和 channel 狀態）：

1) 在新機器上安裝 OpenClaw。
2) 從舊機器複製 `$OPENCLAW_STATE_DIR`（預設：`~/.openclaw`）。
3) 複製你的工作區（預設：`~/.openclaw/workspace`）。
4) 執行 `openclaw doctor` 並重啟 Gateway 服務。

這會保留設定、驗證設定檔、WhatsApp 憑證、sessions 和記憶。如果你在遠端模式，記住 gateway 主機擁有 session 儲存和工作區。

**重要：** 如果你只將工作區 commit/push 到 GitHub，你備份的是**記憶 + bootstrap 檔案**，但**不是** session 歷史或驗證。那些位於 `~/.openclaw/` 下（例如 `~/.openclaw/agents/<agentId>/sessions/`）。

相關：[遷移](/zh-Hant/install/migrating)、[檔案儲存位置](/zh-Hant/help/faq#openclaw-的資料儲存在哪裡)、[Agent 工作區](/zh-Hant/concepts/agent-workspace)、[Doctor](/zh-Hant/gateway/doctor)、[遠端模式](/zh-Hant/gateway/remote)。

### 在哪裡查看最新版本的更新內容

查看 GitHub changelog：
https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md

最新條目在頂部。如果頂部區段標記為 **Unreleased**，下一個帶日期的區段就是最新發布版本。條目按 **Highlights**、**Changes** 和 **Fixes** 分組（需要時還有 docs/其他區段）。

### 無法存取-docsopenclawaissl-錯誤怎麼辦

某些 Comcast/Xfinity 連線透過 Xfinity Advanced Security 錯誤地封鎖 `docs.openclaw.ai`。停用它或將 `docs.openclaw.ai` 加入允許清單，然後重試。更多詳情：[疑難排解](/zh-Hant/help/troubleshooting#docsopenclawai-shows-an-ssl-error-comcastxfinity)。
請幫助我們解除封鎖：https://spa.xfinity.com/check_url_status。

如果仍然無法存取網站，文件在 GitHub 上有鏡像：
https://github.com/openclaw/openclaw/tree/main/docs

### stable-和-beta-有什麼區別

**Stable** 和 **beta** 是 **npm dist‑tags**，不是獨立的程式碼線：
- `latest` = stable
- `beta` = 用於測試的早期建置

我們將建置發送到 **beta**，測試它們，一旦建置穩定就**將該版本提升到 `latest`**。這就是為什麼 beta 和 stable 可以指向**相同版本**。

查看變更內容：
https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md

### 如何安裝-beta-版本beta-和-dev-有什麼區別

**Beta** 是 npm dist‑tag `beta`（可能與 `latest` 相同）。
**Dev** 是 `main` 的移動頭（git）；發布時使用 npm dist‑tag `dev`。

單行指令（macOS/Linux）：

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.bot/install.sh | bash -s -- --beta
```

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.bot/install.sh | bash -s -- --install-method git
```

Windows 安裝程式（PowerShell）：
https://openclaw.ai/install.ps1

更多詳情：[開發頻道](/zh-Hant/install/development-channels) 和 [安裝程式旗標](/zh-Hant/install/installer)。

### 如何嘗試最新的程式碼

兩個選項：

1) **Dev 頻道（git checkout）：**
```bash
openclaw update --channel dev
```
這會切換到 `main` 分支並從原始碼更新。

2) **Hackable 安裝（從安裝程式網站）：**
```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --install-method git
```
這會給你一個可以編輯的本地 repo，然後透過 git 更新。

如果你偏好手動乾淨 clone：
```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm build
```

文件：[Update](/zh-Hant/cli/update)、[開發頻道](/zh-Hant/install/development-channels)、[安裝](/zh-Hant/install)。

### 安裝和引導通常需要多長時間

大致指南：
- **安裝：** 2-5 分鐘
- **引導：** 5-15 分鐘，取決於你設定多少 channels/models

如果卡住，使用 [安裝程式卡住](#安裝程式卡住了如何獲得更多回饋) 和 [我卡住了](#我卡住了最快的解決方法是什麼) 中的快速除錯循環。

### 安裝程式卡住了如何獲得更多回饋

重新執行安裝程式並加上 **verbose 輸出**：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --verbose
```

Beta 安裝加 verbose：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --beta --verbose
```

Hackable (git) 安裝：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --install-method git --verbose
```

更多選項：[安裝程式旗標](/zh-Hant/install/installer)。

### windows-安裝顯示-git-找不到或-openclaw-無法識別

兩個常見的 Windows 問題：

**1) npm error spawn git / git not found**
- 安裝 **Git for Windows** 並確保 `git` 在你的 PATH 中。
- 關閉並重新開啟 PowerShell，然後重新執行安裝程式。

**2) openclaw is not recognized after install**
- 你的 npm 全域 bin 資料夾不在 PATH 中。
- 檢查路徑：
  ```powershell
  npm config get prefix
  ```
- 確保 `<prefix>\\bin` 在 PATH 中（大多數系統是 `%AppData%\\npm`）。
- 更新 PATH 後關閉並重新開啟 PowerShell。

如果想要最順暢的 Windows 設定，使用 **WSL2** 而非原生 Windows。
文件：[Windows](/zh-Hant/platforms/windows)。

### 文件沒有回答我的問題---如何獲得更好的答案

使用 **hackable (git) 安裝**，這樣你本地有完整的原始碼和文件，然後*從該資料夾*詢問你的 bot（或 Claude/Codex），讓它可以讀取 repo 並精確回答。

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --install-method git
```

更多詳情：[安裝](/zh-Hant/install) 和 [安裝程式旗標](/zh-Hant/install/installer)。

### 如何在-linux-上安裝-openclaw

簡短回答：遵循 Linux 指南，然後執行引導精靈。

- Linux 快速路徑 + 服務安裝：[Linux](/zh-Hant/platforms/linux)。
- 完整說明：[開始使用](/zh-Hant/start/getting-started)。
- 安裝程式 + 更新：[安裝與更新](/zh-Hant/install/updating)。

### 如何在-vps-上安裝-openclaw

任何 Linux VPS 都可以。在伺服器上安裝，然後使用 SSH/Tailscale 連接 Gateway。

指南：[exe.dev](/zh-Hant/platforms/exe-dev)、[Hetzner](/zh-Hant/platforms/hetzner)、[Fly.io](/zh-Hant/platforms/fly)。
遠端存取：[Gateway 遠端](/zh-Hant/gateway/remote)。

### 雲端vps-安裝指南在哪裡

我們有一個**託管中心**列出常見供應商。選擇一個並遵循指南：

- [VPS 託管](/zh-Hant/vps)（所有供應商集中在一處）
- [Fly.io](/zh-Hant/platforms/fly)
- [Hetzner](/zh-Hant/platforms/hetzner)
- [exe.dev](/zh-Hant/platforms/exe-dev)

雲端運作方式：**Gateway 在伺服器上執行**，你從筆電/手機透過 Control UI（或 Tailscale/SSH）存取它。你的狀態 + 工作區存在伺服器上，所以將主機視為真相來源並備份它。

你可以將 **nodes**（Mac/iOS/Android/headless）配對到該雲端 Gateway，以存取筆電上的本地螢幕/相機/canvas 或執行指令，同時保持 Gateway 在雲端。

中心：[平台](/zh-Hant/platforms)。遠端存取：[Gateway 遠端](/zh-Hant/gateway/remote)。
Nodes：[Nodes](/zh-Hant/nodes)、[Nodes CLI](/zh-Hant/cli/nodes)。

### 可以讓-openclaw-自己更新嗎

簡短回答：**可能，但不建議**。更新流程可能重啟 Gateway（這會中斷活動 session），可能需要乾淨的 git checkout，並可能提示確認。更安全：以操作者身份從 shell 執行更新。

使用 CLI：

```bash
openclaw update
openclaw update status
openclaw update --channel stable|beta|dev
openclaw update --tag <dist-tag|version>
openclaw update --no-restart
```

如果必須從 agent 自動化：

```bash
openclaw update --yes --no-restart
openclaw gateway restart
```

文件：[Update](/zh-Hant/cli/update)、[更新](/zh-Hant/install/updating)。

### 引導精靈實際做了什麼

`openclaw onboard` 是建議的設定路徑。在**本地模式**中它會引導你完成：

- **模型/驗證設定**（Anthropic **setup-token** 建議用於 Claude 訂閱，支援 OpenAI Codex OAuth，API 金鑰可選，支援 LM Studio 本地模型）
- **工作區**位置 + bootstrap 檔案
- **Gateway 設定**（bind/port/auth/tailscale）
- **供應商**（WhatsApp、Telegram、Discord、Mattermost（plugin）、Signal、iMessage）
- **Daemon 安裝**（macOS 上的 LaunchAgent；Linux/WSL2 上的 systemd user unit）
- **健康檢查**和 **skills** 選擇

如果你設定的模型未知或缺少驗證，它也會警告。

### 需要-claude-或-openai-訂閱才能執行嗎

不需要。你可以用 **API 金鑰**（Anthropic/OpenAI/其他）或**純本地模型**執行 OpenClaw，這樣你的資料會留在你的裝置上。訂閱（Claude Pro/Max 或 OpenAI Codex）是驗證這些供應商的可選方式。

文件：[Anthropic](/zh-Hant/providers/anthropic)、[OpenAI](/zh-Hant/providers/openai)、[本地模型](/zh-Hant/gateway/local-models)、[模型](/zh-Hant/concepts/models)。

### 可以不用-api-金鑰使用-claude-max-訂閱嗎

可以。你可以用 **setup-token** 而非 API 金鑰進行驗證。這是訂閱路徑。

Claude Pro/Max 訂閱**不包含 API 金鑰**，所以這是訂閱帳戶的正確方法。重要：你必須向 Anthropic 確認這種用法在他們的訂閱政策和條款下是允許的。如果你想要最明確、受支援的路徑，使用 Anthropic API 金鑰。

### anthropic-setup-token-驗證如何運作

`claude setup-token` 透過 Claude Code CLI 產生一個 **token 字串**（在網頁控制台不可用）。你可以在**任何機器**上執行它。在精靈中選擇 **Anthropic token (paste setup-token)** 或用 `openclaw models auth paste-token --provider anthropic` 貼上。Token 作為 **anthropic** 供應商的驗證設定檔儲存，像 API 金鑰一樣使用（不自動更新）。更多詳情：[OAuth](/zh-Hant/concepts/oauth)。

### 在哪裡找到-anthropic-setup-token

它**不在** Anthropic Console 中。setup-token 由 **Claude Code CLI** 在**任何機器**上產生：

```bash
claude setup-token
```

複製它印出的 token，然後在精靈中選擇 **Anthropic token (paste setup-token)**。如果你想在 gateway 主機上執行，使用 `openclaw models auth setup-token --provider anthropic`。如果你在其他地方執行了 `claude setup-token`，在 gateway 主機上用 `openclaw models auth paste-token --provider anthropic` 貼上。參閱 [Anthropic](/zh-Hant/providers/anthropic)。

### 支援-claude-訂閱驗證claude-code-oauth嗎

支援——透過 **setup-token**。OpenClaw 不再重用 Claude Code CLI OAuth token；使用 setup-token 或 Anthropic API 金鑰。在任何地方產生 token 並在 gateway 主機上貼上。參閱 [Anthropic](/zh-Hant/providers/anthropic) 和 [OAuth](/zh-Hant/concepts/oauth)。

注意：Claude 訂閱存取受 Anthropic 條款約束。對於生產或多用戶工作負載，API 金鑰通常是更安全的選擇。

### 為什麼看到-http-429-rate_limit_error

這表示你的 **Anthropic 配額/速率限制**在當前窗口內已用完。如果你使用 **Claude 訂閱**（setup‑token 或 Claude Code OAuth），等待窗口重置或升級你的方案。如果你使用 **Anthropic API 金鑰**，在 Anthropic Console 檢查使用量/帳單並根據需要提高限制。

提示：設定**備用模型**，這樣 OpenClaw 可以在供應商受速率限制時繼續回覆。
參閱 [Models](/zh-Hant/cli/models) 和 [OAuth](/zh-Hant/concepts/oauth)。

### 支援-aws-bedrock-嗎

支援——透過 pi‑ai 的 **Amazon Bedrock (Converse)** 供應商加上**手動設定**。你必須在 gateway 主機上提供 AWS 憑證/區域，並在你的 models 設定中添加 Bedrock 供應商條目。參閱 [Amazon Bedrock](/zh-Hant/bedrock) 和 [模型供應商](/zh-Hant/providers/models)。如果你偏好託管金鑰流程，在 Bedrock 前面放一個 OpenAI 相容的 proxy 仍然是有效選項。

### codex-驗證如何運作

OpenClaw 透過 OAuth（ChatGPT 登入）支援 **OpenAI Code (Codex)**。精靈可以執行 OAuth 流程，並在適當時將預設模型設為 `openai-codex/gpt-5.2`。參閱 [模型供應商](/zh-Hant/concepts/model-providers) 和 [精靈](/zh-Hant/start/wizard)。

### 支援-openai-訂閱驗證codex-oauth嗎

支援。OpenClaw 完全支援 **OpenAI Code (Codex) 訂閱 OAuth**。引導精靈可以為你執行 OAuth 流程。

參閱 [OAuth](/zh-Hant/concepts/oauth)、[模型供應商](/zh-Hant/concepts/model-providers) 和 [精靈](/zh-Hant/start/wizard)。

### 如何設定-gemini-cli-oauth

Gemini CLI 使用**插件驗證流程**，不是 `openclaw.json` 中的 client id 或 secret。

步驟：
1) 啟用插件：`openclaw plugins enable google-gemini-cli-auth`
2) 登入：`openclaw models auth login --provider google-gemini-cli --set-default`

這會在 gateway 主機的驗證設定檔中儲存 OAuth token。詳情：[模型供應商](/zh-Hant/concepts/model-providers)。

### 本地模型適合日常聊天嗎

通常不適合。OpenClaw 需要大型 context + 強大的安全性；小型卡片會截斷並洩漏。如果必須使用，在本地執行你能執行的**最大** MiniMax M2.1 建置（LM Studio）並參閱 [/gateway/local-models](/zh-Hant/gateway/local-models)。較小/量化的模型會增加 prompt-injection 風險——參閱 [安全性](/zh-Hant/gateway/security)。

### 如何將託管模型流量保持在特定區域

選擇區域固定的端點。OpenRouter 為 MiniMax、Kimi 和 GLM 提供美國託管選項；選擇美國託管的變體以保持資料在區域內。你仍然可以透過使用 `models.mode: "merge"` 將 Anthropic/OpenAI 列在這些旁邊，這樣備用仍然可用，同時尊重你選擇的區域供應商。

### 必須購買-mac-mini-才能安裝嗎

不需要。OpenClaw 在 macOS 或 Linux（Windows 透過 WSL2）上執行。Mac mini 是可選的——有些人買一台作為始終開機的主機，但小型 VPS、家用伺服器或 Raspberry Pi 級別的機器也可以。

你只需要 Mac **用於 macOS 專用工具**。對於 iMessage，你可以將 Gateway 保持在 Linux 上，並透過將 `channels.imessage.cliPath` 指向 SSH wrapper 在任何 Mac 上透過 SSH 執行 `imsg`。如果你想要其他 macOS 專用工具，在 Mac 上執行 Gateway 或配對 macOS node。

文件：[iMessage](/zh-Hant/channels/imessage)、[Nodes](/zh-Hant/nodes)、[Mac 遠端模式](/zh-Hant/platforms/mac/remote)。

### imessage-支援需要-mac-mini-嗎

你需要**某個 macOS 裝置**登入 Messages。它**不必**是 Mac mini——任何 Mac 都可以。OpenClaw 的 iMessage 整合在 macOS 上執行（BlueBubbles 或 `imsg`），而 Gateway 可以在其他地方執行。

常見設定：
- 在 Linux/VPS 上執行 Gateway，並將 `channels.imessage.cliPath` 指向在 Mac 上執行 `imsg` 的 SSH wrapper。
- 如果你想要最簡單的單機設定，在 Mac 上執行所有東西。

文件：[iMessage](/zh-Hant/channels/imessage)、[BlueBubbles](/zh-Hant/channels/bluebubbles)、[Mac 遠端模式](/zh-Hant/platforms/mac/remote)。

### 如果購買-mac-mini-執行-openclaw可以連接到-macbook-pro-嗎

可以。**Mac mini 可以執行 Gateway**，你的 MacBook Pro 可以作為 **node**（配套裝置）連接。Nodes 不執行 Gateway——它們提供額外功能，如該裝置上的螢幕/相機/canvas 和 `system.run`。

常見模式：
- Gateway 在 Mac mini 上（始終開機）。
- MacBook Pro 執行 macOS app 或 node host 並配對到 Gateway。
- 使用 `openclaw nodes status` / `openclaw nodes list` 查看它。

文件：[Nodes](/zh-Hant/nodes)、[Nodes CLI](/zh-Hant/cli/nodes)。

### 可以使用-bun-嗎

**不建議**使用 Bun。我們看到執行時 bug，特別是 WhatsApp 和 Telegram。使用 **Node** 以獲得穩定的 gateway。

如果你仍想試驗 Bun，在沒有 WhatsApp/Telegram 的非生產 gateway 上進行。

### telegram-allowfrom-要填什麼

`channels.telegram.allowFrom` 是**發送者的 Telegram 用戶 ID**（數字，建議）或 `@username`。它不是 bot username。

更安全（不需要第三方 bot）：
- 私訊你的 bot，然後執行 `openclaw logs --follow` 並讀取 `from.id`。

官方 Bot API：
- 私訊你的 bot，然後呼叫 `https://api.telegram.org/bot<bot_token>/getUpdates` 並讀取 `message.from.id`。

第三方（較不私密）：
- 私訊 `@userinfobot` 或 `@getidsbot`。

參閱 [/channels/telegram](/zh-Hant/channels/telegram#access-control-dms--groups)。

### 多人可以使用同一個-whatsapp-號碼搭配不同的-openclaw-實例嗎

可以，透過**多 agent 路由**。將每個發送者的 WhatsApp **DM**（peer `kind: "dm"`，發送者 E.164 如 `+15551234567`）綁定到不同的 `agentId`，這樣每個人都有自己的工作區和 session 儲存。回覆仍然來自**同一個 WhatsApp 帳戶**，DM 存取控制（`channels.whatsapp.dmPolicy` / `channels.whatsapp.allowFrom`）對每個 WhatsApp 帳戶是全域的。參閱 [多 Agent 路由](/zh-Hant/concepts/multi-agent) 和 [WhatsApp](/zh-Hant/channels/whatsapp)。

### 可以同時執行快速聊天-agent-和opus-寫程式-agent-嗎

可以。使用多 agent 路由：給每個 agent 自己的預設模型，然後將入站路由（供應商帳戶或特定 peer）綁定到每個 agent。範例設定在 [多 Agent 路由](/zh-Hant/concepts/multi-agent)。另參閱 [模型](/zh-Hant/concepts/models) 和 [配置](/zh-Hant/gateway/configuration)。

### homebrew-在-linux-上可用嗎

可以。Homebrew 支援 Linux（Linuxbrew）。快速設定：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install <formula>
```

如果你透過 systemd 執行 OpenClaw，確保服務 PATH 包含 `/home/linuxbrew/.linuxbrew/bin`（或你的 brew prefix），這樣 `brew` 安裝的工具在非登入 shell 中可以解析。
最近的建置也會在 Linux systemd 服務上預置常見的用戶 bin 目錄（例如 `~/.local/bin`、`~/.npm-global/bin`、`~/.local/share/pnpm`、`~/.bun/bin`）並在設定時遵守 `PNPM_HOME`、`NPM_CONFIG_PREFIX`、`BUN_INSTALL`、`VOLTA_HOME`、`ASDF_DATA_DIR`、`NVM_DIR` 和 `FNM_DIR`。

### hackable-git-安裝和-npm-安裝有什麼區別

- **Hackable (git) 安裝：** 完整原始碼 checkout，可編輯，最適合貢獻者。你在本地執行建置，可以修補程式碼/文件。
- **npm 安裝：** 全域 CLI 安裝，沒有 repo，最適合「直接執行」。更新來自 npm dist‑tags。

文件：[開始使用](/zh-Hant/start/getting-started)、[更新](/zh-Hant/install/updating)。

### 之後可以在-npm-和-git-安裝之間切換嗎

可以。安裝另一種方式，然後執行 Doctor 讓 gateway 服務指向新的入口點。這**不會刪除你的資料**——它只改變 OpenClaw 程式碼安裝。你的狀態（`~/.openclaw`）和工作區（`~/.openclaw/workspace`）不受影響。

從 npm → git：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm build
openclaw doctor
openclaw gateway restart
```

從 git → npm：

```bash
npm install -g openclaw@latest
openclaw doctor
openclaw gateway restart
```

Doctor 檢測到 gateway 服務入口點不匹配時會提議重寫服務設定以匹配當前安裝（自動化時使用 `--repair`）。

備份提示：參閱 [備份策略](#建議的備份策略是什麼)。

### 應該在筆電還是-vps-上執行-gateway

簡短回答：**如果你想要 24/7 可靠性，使用 VPS**。如果你想要最低摩擦且可以接受睡眠/重啟，在本地執行。

**筆電（本地 Gateway）**
- **優點：** 無伺服器成本，直接存取本地檔案，可見瀏覽器視窗。
- **缺點：** 睡眠/網路中斷 = 斷線，OS 更新/重啟會中斷，必須保持喚醒。

**VPS / 雲端**
- **優點：** 始終開機，穩定網路，無筆電睡眠問題，更容易保持運行。
- **缺點：** 通常無頭運行（使用螢幕截圖），僅遠端檔案存取，更新需要 SSH。

**OpenClaw 特定說明：** WhatsApp/Telegram/Slack/Mattermost（plugin）/Discord 都可以從 VPS 正常運作。唯一真正的權衡是**無頭瀏覽器** vs 可見視窗。參閱 [瀏覽器](/zh-Hant/tools/browser)。

**建議預設：** 如果你之前有 gateway 斷線，使用 VPS。當你積極使用 Mac 並想要本地檔案存取或帶可見瀏覽器的 UI 自動化時，本地很好。

### 在專用機器上執行-openclaw-有多重要

不是必需的，但**建議用於可靠性和隔離**。

- **專用主機（VPS/Mac mini/Pi）：** 始終開機，較少睡眠/重啟中斷，更乾淨的權限，更容易保持運行。
- **共用筆電/桌機：** 測試和積極使用完全可以，但預期機器睡眠或更新時會暫停。

如果你想要兩全其美，將 Gateway 保持在專用主機上，並將筆電作為 **node** 配對以獲得本地螢幕/相機/exec 工具。參閱 [Nodes](/zh-Hant/nodes)。
安全指南請閱讀 [安全性](/zh-Hant/gateway/security)。

### vps-最低需求和建議作業系統是什麼

OpenClaw 很輕量。對於基本 Gateway + 一個聊天頻道：

- **絕對最低：** 1 vCPU、1GB RAM、~500MB 磁碟。
- **建議：** 1-2 vCPU、2GB RAM 或更多以獲得餘裕（日誌、媒體、多個頻道）。Node 工具和瀏覽器自動化可能資源密集。

作業系統：使用 **Ubuntu LTS**（或任何現代 Debian/Ubuntu）。Linux 安裝路徑在那裡測試最多。

文件：[Linux](/zh-Hant/platforms/linux)、[VPS 託管](/zh-Hant/vps)。

### 可以在-vm-中執行-openclaw-嗎需求是什麼

可以。將 VM 視為與 VPS 相同：它需要始終開機、可達，並有足夠的 RAM 用於 Gateway 和你啟用的任何頻道。

基準指南：
- **絕對最低：** 1 vCPU、1GB RAM。
- **建議：** 2GB RAM 或更多，如果你執行多個頻道、瀏覽器自動化或媒體工具。
- **作業系統：** Ubuntu LTS 或其他現代 Debian/Ubuntu。

如果你在 Windows 上，**WSL2 是最簡單的 VM 式設定**，工具相容性最好。參閱 [Windows](/zh-Hant/platforms/windows)、[VPS 託管](/zh-Hant/vps)。
如果你在 VM 中執行 macOS，參閱 [macOS VM](/zh-Hant/platforms/macos-vm)。

## 什麼是 OpenClaw

### 用一段話說明-openclaw-是什麼

OpenClaw 是一個你在自己裝置上執行的個人 AI 助理。它在你已經使用的訊息平台上回覆（WhatsApp、Telegram、Slack、Mattermost（plugin）、Discord、Google Chat、Signal、iMessage、WebChat），也可以在支援的平台上進行語音 + 即時 Canvas。**Gateway** 是始終開機的控制平面；助理是產品。

### 價值主張是什麼

OpenClaw 不只是「Claude wrapper」。它是一個**本地優先的控制平面**，讓你在**自己的硬體**上執行一個能幹的助理，可從你已經使用的聊天 app 存取，具有狀態 sessions、記憶和工具——無需將工作流程的控制權交給託管 SaaS。

亮點：
- **你的裝置，你的資料：** 在任何你想要的地方執行 Gateway（Mac、Linux、VPS）並保持工作區 + session 歷史在本地。
- **真正的頻道，不是網頁沙箱：** WhatsApp/Telegram/Slack/Discord/Signal/iMessage/等，加上支援平台上的行動語音和 Canvas。
- **模型不可知：** 使用 Anthropic、OpenAI、MiniMax、OpenRouter 等，支援每 agent 路由和故障轉移。
- **純本地選項：** 執行本地模型，**所有資料都可以留在你的裝置上**（如果你想要）。
- **多 agent 路由：** 每個頻道、帳戶或任務分開的 agents，各有自己的工作區和預設值。
- **開源且可修改：** 檢查、擴展和自託管，無供應商鎖定。

文件：[Gateway](/zh-Hant/gateway)、[頻道](/zh-Hant/channels)、[多 Agent](/zh-Hant/concepts/multi-agent)、[記憶](/zh-Hant/concepts/memory)。

### 剛設定好應該先做什麼

好的第一個專案：
- 建立網站（WordPress、Shopify 或簡單的靜態網站）。
- 製作行動 app 原型（大綱、畫面、API 計劃）。
- 整理檔案和資料夾（清理、命名、標記）。
- 連接 Gmail 並自動化摘要或跟進。

它可以處理大型任務，但當你將它們分成階段並使用子 agents 進行並行工作時效果最好。

### openclaw-的前五大日常使用案例是什麼

日常收益通常看起來像：
- **個人簡報：** 收件匣、行事曆和你關心的新聞的摘要。
- **研究和草稿：** 快速研究、摘要和電子郵件或文件的初稿。
- **提醒和跟進：** cron 或 heartbeat 驅動的提醒和清單。
- **瀏覽器自動化：** 填寫表單、收集資料和重複網頁任務。
- **跨裝置協調：** 從手機發送任務，讓 Gateway 在伺服器上執行它，並在聊天中取回結果。

### openclaw-可以幫助-saas-的潛在客戶開發外展廣告和部落格嗎

可以用於**研究、資格審查和草稿**。它可以掃描網站、建立候選名單、總結潛在客戶，並撰寫外展或廣告文案草稿。

對於**外展或廣告投放**，保持人工在迴圈中。避免垃圾郵件，遵守當地法律和平台政策，並在發送前審查任何內容。最安全的模式是讓 OpenClaw 草擬，你批准。

文件：[安全性](/zh-Hant/gateway/security)。

### 與-claude-code-相比在網頁開發方面有什麼優勢

OpenClaw 是**個人助理**和協調層，不是 IDE 替代品。使用 Claude Code 或 Codex 在 repo 內進行最快的直接編碼循環。當你想要持久記憶、跨裝置存取和工具編排時使用 OpenClaw。

優勢：
- **跨 sessions 的持久記憶 + 工作區**
- **多平台存取**（WhatsApp、Telegram、TUI、WebChat）
- **工具編排**（瀏覽器、檔案、排程、hooks）
- **始終開機的 Gateway**（在 VPS 上執行，從任何地方互動）
- **Nodes** 用於本地瀏覽器/螢幕/相機/exec

展示：https://openclaw.ai/showcase

## Skills 和自動化

### 如何在不弄髒 repo 的情況下自訂 skills

使用受管覆蓋而非編輯 repo 副本。將你的變更放在 `~/.openclaw/skills/<name>/SKILL.md`（或透過 `~/.openclaw/openclaw.json` 中的 `skills.load.extraDirs` 添加資料夾）。優先順序是 `<workspace>/skills` > `~/.openclaw/skills` > bundled，所以受管覆蓋會勝出而不觸碰 git。只有值得上游的編輯應該放在 repo 中並作為 PR 提交。

### 可以從自訂資料夾載入 skills 嗎

可以。透過 `~/.openclaw/openclaw.json` 中的 `skills.load.extraDirs` 添加額外目錄（最低優先順序）。預設優先順序保持：`<workspace>/skills` → `~/.openclaw/skills` → bundled → `skills.load.extraDirs`。`clawdhub` 預設安裝到 `./skills`，OpenClaw 將其視為 `<workspace>/skills`。

### 如何針對不同任務使用不同模型

目前支援的模式是：
- **Cron jobs**：隔離的 jobs 可以針對每個 job 設定 `model` 覆蓋。
- **Sub-agents**：將任務路由到具有不同預設模型的獨立 agents。
- **按需切換**：使用 `/model` 隨時切換當前 session 模型。

參閱 [Cron jobs](/zh-Hant/automation/cron-jobs)、[多 Agent 路由](/zh-Hant/concepts/multi-agent) 和 [斜線指令](/zh-Hant/tools/slash-commands)。

### bot 在進行繁重工作時凍結如何卸載

使用 **sub-agents** 進行長時間或並行任務。Sub-agents 在自己的 session 中執行，返回摘要，並保持你的主聊天響應。

請你的 bot「為這個任務產生一個 sub-agent」或使用 `/subagents`。
在聊天中使用 `/status` 查看 Gateway 現在在做什麼（以及它是否忙碌）。

Token 提示：長任務和 sub-agents 都消耗 token。如果成本是考量，透過 `agents.defaults.subagents.model` 為 sub-agents 設定更便宜的模型。

文件：[Sub-agents](/zh-Hant/tools/subagents)。

### cron-或提醒沒有觸發應該檢查什麼

Cron 在 Gateway 程序內執行。如果 Gateway 沒有持續運行，排程的 jobs 不會執行。

檢查清單：
- 確認 cron 已啟用（`cron.enabled`）且 `OPENCLAW_SKIP_CRON` 未設定。
- 檢查 Gateway 是否 24/7 運行（無睡眠/重啟）。
- 驗證 job 的時區設定（`--tz` vs 主機時區）。

除錯：
```bash
openclaw cron run <jobId> --force
openclaw cron runs --id <jobId> --limit 50
```

文件：[Cron jobs](/zh-Hant/automation/cron-jobs)、[Cron vs Heartbeat](/zh-Hant/automation/cron-vs-heartbeat)。

### 如何在-linux-上安裝-skills

使用 **ClawdHub**（CLI）或將 skills 放入你的工作區。macOS Skills UI 在 Linux 上不可用。
在 https://clawdhub.com 瀏覽 skills。

安裝 ClawdHub CLI（選擇一個套件管理器）：

```bash
npm i -g clawdhub
```

```bash
pnpm add -g clawdhub
```

### openclaw-可以按排程或在背景持續執行任務嗎

可以。使用 Gateway 排程器：

- **Cron jobs** 用於排程或重複任務（跨重啟持久化）。
- **Heartbeat** 用於「主 session」定期檢查。
- **隔離 jobs** 用於發布摘要或傳遞到聊天的自主 agents。

文件：[Cron jobs](/zh-Hant/automation/cron-jobs)、[Cron vs Heartbeat](/zh-Hant/automation/cron-vs-heartbeat)、[Heartbeat](/zh-Hant/gateway/heartbeat)。

## 沙箱和記憶

### 有專門的沙箱文件嗎

有。參閱 [沙箱](/zh-Hant/gateway/sandboxing)。Docker 特定設定（完整 gateway 在 Docker 中或沙箱映像）請參閱 [Docker](/zh-Hant/install/docker)。

### 如何將主機資料夾綁定到沙箱中

設定 `agents.defaults.sandbox.docker.binds` 為 `["host:path:mode"]`（例如 `"/home/user/src:/src:ro"`）。全域 + 每 agent 綁定會合併；當 `scope: "shared"` 時會忽略每 agent 綁定。對任何敏感內容使用 `:ro`，記住綁定會繞過沙箱檔案系統牆。參閱 [沙箱](/zh-Hant/gateway/sandboxing#custom-bind-mounts) 和 [Sandbox vs Tool Policy vs Elevated](/zh-Hant/gateway/sandbox-vs-tool-policy-vs-elevated#bind-mounts-security-quick-check) 獲取範例和安全說明。

### 記憶如何運作

OpenClaw 記憶只是 agent 工作區中的 Markdown 檔案：
- 每日筆記在 `memory/YYYY-MM-DD.md`
- 策展的長期筆記在 `MEMORY.md`（僅限主/私人 sessions）

OpenClaw 也執行**靜默預壓縮記憶刷新**，在自動壓縮前提醒模型寫入持久筆記。這只在工作區可寫時執行（唯讀沙箱會跳過）。參閱 [記憶](/zh-Hant/concepts/memory)。

### 記憶一直忘記東西如何讓它記住

請 bot **將事實寫入記憶**。長期筆記屬於 `MEMORY.md`，短期上下文放入 `memory/YYYY-MM-DD.md`。

這仍然是我們正在改進的領域。提醒模型儲存記憶會有幫助；它知道該怎麼做。如果它一直忘記，驗證 Gateway 每次運行都使用相同的工作區。

文件：[記憶](/zh-Hant/concepts/memory)、[Agent 工作區](/zh-Hant/concepts/agent-workspace)。

### 語義記憶搜尋需要-openai-api-金鑰嗎

只有當你使用 **OpenAI embeddings** 時。Codex OAuth 涵蓋 chat/completions 但**不**授予 embeddings 存取，所以**用 Codex 登入（OAuth 或 Codex CLI 登入）**對語義記憶搜尋沒有幫助。OpenAI embeddings 仍然需要真正的 API 金鑰（`OPENAI_API_KEY` 或 `models.providers.openai.apiKey`）。

如果你不明確設定供應商，OpenClaw 會在可以解析 API 金鑰（驗證設定檔、`models.providers.*.apiKey` 或環境變數）時自動選擇供應商。如果 OpenAI 金鑰可解析則優先 OpenAI，否則如果 Gemini 金鑰可解析則優先 Gemini。如果兩個金鑰都不可用，記憶搜尋會保持停用直到你設定它。如果你設定了本地模型路徑且存在，OpenClaw 優先 `local`。

如果你寧願保持本地，設定 `memorySearch.provider = "local"`（可選 `memorySearch.fallback = "none"`）。如果你想要 Gemini embeddings，設定 `memorySearch.provider = "gemini"` 並提供 `GEMINI_API_KEY`（或 `memorySearch.remote.apiKey`）。我們支援 **OpenAI、Gemini 或本地** embedding 模型——參閱 [記憶](/zh-Hant/concepts/memory) 獲取設定詳情。

### 記憶會永久保存嗎有什麼限制

記憶檔案存在磁碟上，直到你刪除它們才會消失。限制是你的儲存空間，不是模型。**Session context** 仍然受模型 context window 限制，所以長對話可能會壓縮或截斷。這就是為什麼記憶搜尋存在——它只將相關部分拉回 context。

文件：[記憶](/zh-Hant/concepts/memory)、[Context](/zh-Hant/concepts/context)。

## 檔案儲存位置

### 與-openclaw-使用的所有資料都儲存在本地嗎

不是——**OpenClaw 的狀態是本地的**，但**外部服務仍然看到你發送給它們的內容**。

- **預設本地：** sessions、記憶檔案、設定和工作區存在 Gateway 主機上（`~/.openclaw` + 你的工作區目錄）。
- **必然遠端：** 你發送給模型供應商（Anthropic/OpenAI/等）的訊息會到它們的 API，聊天平台（WhatsApp/Telegram/Slack/等）在它們的伺服器上儲存訊息資料。
- **你控制範圍：** 使用本地模型會將 prompts 保留在你的機器上，但頻道流量仍然通過頻道的伺服器。

相關：[Agent 工作區](/zh-Hant/concepts/agent-workspace)、[記憶](/zh-Hant/concepts/memory)。

### openclaw-的資料儲存在哪裡

所有東西都在 `$OPENCLAW_STATE_DIR`（預設：`~/.openclaw`）下：

| 路徑 | 用途 |
|------|------|
| `$OPENCLAW_STATE_DIR/openclaw.json` | 主設定（JSON5） |
| `$OPENCLAW_STATE_DIR/credentials/oauth.json` | 舊版 OAuth 匯入（首次使用時複製到驗證設定檔） |
| `$OPENCLAW_STATE_DIR/agents/<agentId>/agent/auth-profiles.json` | 驗證設定檔（OAuth + API 金鑰） |
| `$OPENCLAW_STATE_DIR/agents/<agentId>/agent/auth.json` | 執行時驗證快取（自動管理） |
| `$OPENCLAW_STATE_DIR/credentials/` | 供應商狀態（例如 `whatsapp/<accountId>/creds.json`） |
| `$OPENCLAW_STATE_DIR/agents/` | 每 agent 狀態（agentDir + sessions） |
| `$OPENCLAW_STATE_DIR/agents/<agentId>/sessions/` | 對話歷史 & 狀態（每 agent） |
| `$OPENCLAW_STATE_DIR/agents/<agentId>/sessions/sessions.json` | Session 中繼資料（每 agent） |

舊版單 agent 路徑：`~/.openclaw/agent/*`（由 `openclaw doctor` 遷移）。

你的**工作區**（AGENTS.md、記憶檔案、skills 等）是獨立的，透過 `agents.defaults.workspace` 設定（預設：`~/.openclaw/workspace`）。

### agentsmd-soulmd-usermd-memorymd-應該放在哪裡

這些檔案存在**agent 工作區**中，不是 `~/.openclaw`。

- **工作區（每 agent）**：`AGENTS.md`、`SOUL.md`、`IDENTITY.md`、`USER.md`、`MEMORY.md`（或 `memory.md`）、`memory/YYYY-MM-DD.md`、可選 `HEARTBEAT.md`。
- **狀態目錄（`~/.openclaw`）**：設定、憑證、驗證設定檔、sessions、日誌和共用 skills（`~/.openclaw/skills`）。

預設工作區是 `~/.openclaw/workspace`，可透過以下設定：

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } }
}
```

如果 bot 重啟後「忘記」，確認 Gateway 每次啟動都使用相同的工作區（記住：遠端模式使用 **gateway 主機的**工作區，不是你本地筆電的）。

提示：如果你想要持久的行為或偏好，請 bot **將它寫入 AGENTS.md 或 MEMORY.md** 而非依賴聊天歷史。

參閱 [Agent 工作區](/zh-Hant/concepts/agent-workspace) 和 [記憶](/zh-Hant/concepts/memory)。

### 建議的備份策略是什麼

將你的 **agent 工作區**放入**私人** git repo 並備份到某個私人地方（例如 GitHub private）。這會捕捉記憶 + AGENTS/SOUL/USER 檔案，讓你之後可以恢復助理的「心智」。

**不要** commit `~/.openclaw` 下的任何東西（憑證、sessions、tokens）。如果你需要完整恢復，分別備份工作區和狀態目錄（參閱上面的遷移問題）。

文件：[Agent 工作區](/zh-Hant/concepts/agent-workspace)。

### 如何完全解除安裝-openclaw

參閱專門指南：[解除安裝](/zh-Hant/install/uninstall)。

### agents-可以在工作區外工作嗎

可以。工作區是**預設 cwd** 和記憶錨點，不是硬沙箱。相對路徑在工作區內解析，但絕對路徑可以存取其他主機位置，除非啟用沙箱。如果你需要隔離，使用 [`agents.defaults.sandbox`](/zh-Hant/gateway/sandboxing) 或每 agent 沙箱設定。如果你想讓 repo 成為預設工作目錄，將該 agent 的 `workspace` 指向 repo 根目錄。OpenClaw repo 只是原始碼；除非你刻意想讓 agent 在裡面工作，否則保持工作區分離。

範例（repo 作為預設 cwd）：

```json5
{
  agents: {
    defaults: {
      workspace: "~/Projects/my-repo"
    }
  }
}
```

### 我在遠端模式session-儲存在哪裡

Session 狀態由 **gateway 主機**擁有。如果你在遠端模式，你關心的 session 儲存在遠端機器上，不是你本地筆電。參閱 [Session 管理](/zh-Hant/concepts/session)。

## 設定基礎

### 設定是什麼格式在哪裡

OpenClaw 從 `$OPENCLAW_CONFIG_PATH`（預設：`~/.openclaw/openclaw.json`）讀取可選的 **JSON5** 設定：

```
$OPENCLAW_CONFIG_PATH
```

如果檔案不存在，它使用安全的預設值（包括預設工作區 `~/.openclaw/workspace`）。

### 我設定了-gatewaybind-lan-或-tailnet-現在什麼都不監聽ui-說未授權

非 loopback 綁定**需要驗證**。設定 `gateway.auth.mode` + `gateway.auth.token`（或使用 `OPENCLAW_GATEWAY_TOKEN`）。

```json5
{
  gateway: {
    bind: "lan",
    auth: {
      mode: "token",
      token: "replace-me"
    }
  }
}
```

注意：
- `gateway.remote.token` 僅用於**遠端 CLI 呼叫**；它不啟用本地 gateway 驗證。
- Control UI 透過 `connect.params.auth.token`（儲存在 app/UI 設定中）驗證。避免在 URL 中放入 token。

### 為什麼現在在-localhost-需要-token

精靈預設產生 gateway token（即使在 loopback 上），所以**本地 WS 客戶端必須驗證**。這會阻止其他本地程序呼叫 Gateway。在 Control UI 設定（或你的客戶端設定）中貼上 token 以連接。

如果你**真的**想要開放 loopback，從設定中移除 `gateway.auth`。Doctor 可以隨時為你產生 token：`openclaw doctor --generate-gateway-token`。

### 變更設定後需要重啟嗎

Gateway 監視設定並支援熱重載：

- `gateway.reload.mode: "hybrid"`（預設）：熱套用安全變更，關鍵變更則重啟
- 也支援 `hot`、`restart`、`off`

### 如何啟用網頁搜尋和網頁擷取

`web_fetch` 不需要 API 金鑰即可運作。`web_search` 需要 Brave Search API 金鑰。**建議：** 執行 `openclaw configure --section web` 將它儲存在 `tools.web.search.apiKey`。環境替代方案：為 Gateway 程序設定 `BRAVE_API_KEY`。

```json5
{
  tools: {
    web: {
      search: {
        enabled: true,
        apiKey: "BRAVE_API_KEY_HERE",
        maxResults: 5
      },
      fetch: {
        enabled: true
      }
    }
  }
}
```

注意：
- 如果你使用允許清單，添加 `web_search`/`web_fetch` 或 `group:web`。
- `web_fetch` 預設啟用（除非明確停用）。
- Daemon 從 `~/.openclaw/.env`（或服務環境）讀取環境變數。

文件：[Web 工具](/zh-Hant/tools/web)。

## 遠端 Gateway + Nodes

### 指令如何在-telegram-gateway-和-nodes-之間傳播

Telegram 訊息由 **gateway** 處理。Gateway 執行 agent，只有在需要 node 工具時才透過 **Gateway WebSocket** 呼叫 nodes：

Telegram → Gateway → Agent → `node.*` → Node → Gateway → Telegram

Nodes 看不到入站供應商流量；它們只接收 node RPC 呼叫。

### 如果-gateway-託管在遠端我的-agent-如何存取我的電腦

簡短回答：**將你的電腦配對為 node**。Gateway 在其他地方執行，但它可以透過 Gateway WebSocket 在你的本地機器上呼叫 `node.*` 工具（螢幕、相機、系統）。

典型設定：
1) 在始終開機的主機（VPS/家用伺服器）上執行 Gateway。
2) 將 Gateway 主機 + 你的電腦放在同一個 tailnet 上。
3) 確保 Gateway WS 可達（tailnet bind 或 SSH tunnel）。
4) 在本地開啟 macOS app 並以 **Remote over SSH** 模式（或直接 tailnet）連接，這樣它可以註冊為 node。
5) 在 Gateway 上批准 node：
   ```bash
   openclaw nodes pending
   openclaw nodes approve <requestId>
   ```

不需要單獨的 TCP bridge；nodes 透過 Gateway WebSocket 連接。

安全提醒：配對 macOS node 允許在該機器上使用 `system.run`。只配對你信任的裝置，並審查 [安全性](/zh-Hant/gateway/security)。

文件：[Nodes](/zh-Hant/nodes)、[Gateway 協議](/zh-Hant/gateway/protocol)、[macOS 遠端模式](/zh-Hant/platforms/mac/remote)、[安全性](/zh-Hant/gateway/security)。

### tailscale-已連接但沒有回覆怎麼辦

檢查基本事項：
- Gateway 正在執行：`openclaw gateway status`
- Gateway 健康：`openclaw status`
- 頻道健康：`openclaw channels status`

然後驗證驗證和路由：
- 如果你使用 Tailscale Serve，確保 `gateway.auth.allowTailscale` 設定正確。
- 如果你透過 SSH tunnel 連接，確認本地 tunnel 正常且指向正確的連接埠。
- 確認你的允許清單（DM 或群組）包含你的帳戶。

文件：[Tailscale](/zh-Hant/gateway/tailscale)、[遠端存取](/zh-Hant/gateway/remote)、[頻道](/zh-Hant/channels)。

### 兩個-openclaw-實例可以互相通訊嗎本地-vps

可以。沒有內建的「bot 對 bot」橋接，但你可以用幾種可靠的方式連接：

**最簡單：** 使用兩個 bot 都可以存取的正常聊天頻道（Telegram/Slack/WhatsApp）。讓 Bot A 發送訊息給 Bot B，然後讓 Bot B 正常回覆。

**CLI 橋接（通用）：** 執行一個用 `openclaw agent --message ... --deliver` 呼叫另一個 Gateway 的腳本，目標是另一個 bot 監聽的聊天。如果一個 bot 在遠端 VPS 上，透過 SSH/Tailscale 將你的 CLI 指向該遠端 Gateway（參閱 [遠端存取](/zh-Hant/gateway/remote)）。

範例模式（從可以連接目標 Gateway 的機器執行）：
```bash
openclaw agent --message "Hello from local bot" --deliver --channel telegram --reply-to <chat-id>
```

提示：添加防護機制使兩個 bot 不會無限循環（僅提及、頻道允許清單或「不回覆 bot 訊息」規則）。

文件：[遠端存取](/zh-Hant/gateway/remote)、[Agent CLI](/zh-Hant/cli/agent)、[Agent send](/zh-Hant/tools/agent-send)。

### 多個-agents-需要獨立的-vps-嗎

不需要。一個 Gateway 可以託管多個 agents，每個都有自己的工作區、模型預設值和路由。這是正常設定，比每個 agent 執行一個 VPS 便宜且簡單得多。

只有當你需要硬隔離（安全邊界）或非常不同的設定而不想共享時才使用獨立 VPS。否則，保持一個 Gateway 並使用多個 agents 或 sub-agents。

### 在個人筆電上使用-node-比從-vps-ssh-有什麼好處

有——nodes 是從遠端 Gateway 連接你的筆電的首選方式，它們解鎖的不只是 shell 存取。Gateway 在 macOS/Linux（Windows 透過 WSL2）上執行且很輕量（小型 VPS 或 Raspberry Pi 級別的機器就夠了；4 GB RAM 很充足），所以常見的設定是一個始終開機的主機加上你的筆電作為 node。

- **不需要入站 SSH。** Nodes 向 Gateway WebSocket 發起連接並使用裝置配對。
- **更安全的執行控制。** `system.run` 由該筆電上的 node 允許清單/批准控制。
- **更多裝置工具。** 除了 `system.run`，nodes 還暴露 `canvas`、`camera` 和 `screen`。
- **本地瀏覽器自動化。** 保持 Gateway 在 VPS 上，但在本地執行 Chrome 並用 Chrome 擴展 + 筆電上的 node host 中繼控制。

SSH 適合臨時 shell 存取，但 nodes 對於持續的 agent 工作流程和裝置自動化更簡單。

文件：[Nodes](/zh-Hant/nodes)、[Nodes CLI](/zh-Hant/cli/nodes)、[Chrome 擴展](/zh-Hant/tools/chrome-extension)。

### 應該在第二台筆電上安裝還是只添加-node

如果你只需要第二台筆電上的**本地工具**（螢幕/相機/exec），添加它作為 **node**。這保持單一 Gateway 並避免重複設定。本地 node 工具目前僅限 macOS，但我們計劃擴展到其他作業系統。

只有當你需要**硬隔離**或兩個完全獨立的 bot 時才安裝第二個 Gateway。

文件：[Nodes](/zh-Hant/nodes)、[Nodes CLI](/zh-Hant/cli/nodes)、[多 Gateway](/zh-Hant/gateway/multiple-gateways)。

### nodes-會執行-gateway-服務嗎

不會。除非你刻意執行隔離的 profiles，否則每個主機只應該執行**一個 gateway**（參閱 [多 Gateway](/zh-Hant/gateway/multiple-gateways)）。Nodes 是連接到 gateway 的周邊設備（iOS/Android nodes 或選單列 app 中的 macOS「node 模式」）。headless node hosts 和 CLI 控制請參閱 [Node host CLI](/zh-Hant/cli/node)。

`gateway`、`discovery` 和 `canvasHost` 變更需要完全重啟。

## 環境變數和 .env 載入

### openclaw-如何載入環境變數

OpenClaw 從父程序（shell、launchd/systemd、CI 等）讀取環境變數，另外載入：

- 當前工作目錄的 `.env`
- `~/.openclaw/.env`（又稱 `$OPENCLAW_STATE_DIR/.env`）的全域備用

兩個 `.env` 檔案都不會覆蓋現有環境變數。

你也可以在設定中定義內聯環境變數（僅在程序環境中缺失時套用）：

```json5
{
  env: {
    OPENROUTER_API_KEY: "sk-or-...",
    vars: { GROQ_API_KEY: "gsk-..." }
  }
}
```

完整優先順序和來源請參閱 [/environment](/zh-Hant/environment)。

### 我透過服務啟動-gateway我的環境變數消失了怎麼辦

兩個常見修復：

1) 將缺少的金鑰放在 `~/.openclaw/.env` 中，這樣即使服務沒有繼承你的 shell 環境也會被載入。
2) 啟用 shell 匯入（選擇性便利）：

```json5
{
  env: {
    shellEnv: {
      enabled: true,
      timeoutMs: 15000
    }
  }
}
```

這會執行你的登入 shell 並只匯入缺少的預期金鑰（永不覆蓋）。環境變數等效項：
`OPENCLAW_LOAD_SHELL_ENV=1`、`OPENCLAW_SHELL_ENV_TIMEOUT_MS=15000`。

### 我設定了-copilotgithubtoken-但-models-status-顯示-shell-env-off為什麼

`openclaw models status` 報告 **shell 環境匯入**是否啟用。「Shell env: off」**不**表示你的環境變數缺失——它只表示 OpenClaw 不會自動載入你的登入 shell。

如果 Gateway 作為服務執行（launchd/systemd），它不會繼承你的 shell 環境。修復方法之一：

1) 將 token 放在 `~/.openclaw/.env`：
   ```
   COPILOT_GITHUB_TOKEN=...
   ```
2) 或啟用 shell 匯入（`env.shellEnv.enabled: true`）。
3) 或將它添加到你的設定 `env` 區塊（僅在缺失時套用）。

然後重啟 gateway 並重新檢查：
```bash
openclaw models status
```

Copilot token 從 `COPILOT_GITHUB_TOKEN`（也 `GH_TOKEN` / `GITHUB_TOKEN`）讀取。
參閱 [/concepts/model-providers](/zh-Hant/concepts/model-providers) 和 [/environment](/zh-Hant/environment)。

## Sessions 與多重聊天

### 如何開始新對話

發送 `/new` 或 `/reset` 作為獨立訊息。參閱 [Session 管理](/zh-Hant/concepts/session)。

### 如果我從不發送-new-sessions-會自動重置嗎

會。Sessions 在 `session.idleMinutes`（預設 **60**）後過期。該聊天金鑰的**下一條**訊息會開始新的 session id。這不會刪除對話記錄——它只是開始新的 session。

```json5
{
  session: {
    idleMinutes: 240
  }
}
```

### 有辦法建立-openclaw-實例團隊一個-ceo-和多個-agents-嗎

有，透過**多 agent 路由**和 **sub-agents**。你可以建立一個協調者 agent 和幾個工作者 agents，各有自己的工作區和模型。

話雖如此，這最好被視為**有趣的實驗**。它消耗大量 token，通常比使用一個 bot 搭配獨立 sessions 效率低。我們設想的典型模型是你對話的一個 bot，用不同的 sessions 進行並行工作。該 bot 也可以在需要時產生 sub-agents。

文件：[多 agent 路由](/zh-Hant/concepts/multi-agent)、[Sub-agents](/zh-Hant/tools/subagents)、[Agents CLI](/zh-Hant/cli/agents)。

### 為什麼-context-在任務中間被截斷如何防止

Session context 受模型視窗限制。長對話、大型工具輸出或許多檔案可能觸發壓縮或截斷。

有幫助的方法：
- 請 bot 總結當前狀態並寫入檔案。
- 在長任務前使用 `/compact`，切換主題時使用 `/new`。
- 將重要 context 保留在工作區中並請 bot 讀回來。
- 使用 sub-agents 進行長時間或並行工作，這樣主聊天保持較小。
- 如果這種情況經常發生，選擇 context 視窗更大的模型。

### 如何完全重置-openclaw-但保持安裝

使用 reset 指令：

```bash
openclaw reset
```

非互動式完整重置：

```bash
openclaw reset --scope full --yes --non-interactive
```

然後重新執行引導：

```bash
openclaw onboard --install-daemon
```

注意：
- 引導精靈如果看到現有設定也會提供 **Reset**。參閱 [精靈](/zh-Hant/start/wizard)。
- 如果你使用 profiles（`--profile` / `OPENCLAW_PROFILE`），重置每個狀態目錄（預設是 `~/.openclaw-<profile>`）。
- 開發重置：`openclaw gateway --dev --reset`（僅限開發；清除開發設定 + 憑證 + sessions + 工作區）。

### 我收到-context-too-large-錯誤如何重置或壓縮

使用其中之一：

- **壓縮**（保留對話但總結較舊的輪次）：
  ```
  /compact
  ```
  或 `/compact <instructions>` 來指導總結。

- **重置**（同一聊天金鑰的新 session ID）：
  ```
  /new
  /reset
  ```

如果持續發生：
- 啟用或調整 **session 修剪**（`agents.defaults.contextPruning`）以修剪舊工具輸出。
- 使用 context 視窗更大的模型。

文件：[壓縮](/zh-Hant/concepts/compaction)、[Session 修剪](/zh-Hant/concepts/session-pruning)、[Session 管理](/zh-Hant/concepts/session)。

### 為什麼我收到-heartbeat-訊息每-30-分鐘

Heartbeats 預設每 **30m** 執行一次。調整或停用它們：

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "2h"   // 或 "0m" 停用
      }
    }
  }
}
```

如果 `HEARTBEAT.md` 存在但實際上是空的（只有空白行和 markdown 標題如 `# Heading`），OpenClaw 會跳過 heartbeat 執行以節省 API 呼叫。如果檔案不存在，heartbeat 仍然執行，模型決定做什麼。

每 agent 覆蓋使用 `agents.list[].heartbeat`。文件：[Heartbeat](/zh-Hant/gateway/heartbeat)。

### 我需要將-bot-帳戶添加到-whatsapp-群組嗎

不需要。OpenClaw 在**你自己的帳戶**上執行，所以如果你在群組中，OpenClaw 可以看到它。預設情況下，群組回覆被阻止直到你允許發送者（`groupPolicy: "allowlist"`）。

如果你只想讓**你**能夠觸發群組回覆：

```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"]
    }
  }
}
```

### 如何取得-whatsapp-群組的-jid

選項 1（最快）：追蹤日誌並在群組中發送測試訊息：

```bash
openclaw logs --follow --json
```

尋找以 `@g.us` 結尾的 `chatId`（或 `from`），如：
`1234567890-1234567890@g.us`。

選項 2（如果已設定/允許清單）：從設定列出群組：

```bash
openclaw directory groups list --channel whatsapp
```

文件：[WhatsApp](/zh-Hant/channels/whatsapp)、[Directory](/zh-Hant/cli/directory)、[Logs](/zh-Hant/cli/logs)。

### 為什麼-openclaw-不在群組中回覆

兩個常見原因：
- 提及控制已開啟（預設）。你必須 @提及 bot（或匹配 `mentionPatterns`）。
- 你設定了 `channels.whatsapp.groups` 但沒有 `"*"` 且該群組不在允許清單中。

參閱 [群組](/zh-Hant/concepts/groups) 和 [群組訊息](/zh-Hant/concepts/group-messages)。

### 群組threads-與-dms-共享-context-嗎

直接聊天預設折疊到主 session。群組/頻道有自己的 session 金鑰，Telegram topics / Discord threads 是獨立的 sessions。參閱 [群組](/zh-Hant/concepts/groups) 和 [群組訊息](/zh-Hant/concepts/group-messages)。

### 我可以建立多少工作區和-agents

沒有硬性限制。幾十個（甚至上百個）都可以，但注意：

- **磁碟成長：** sessions + 對話記錄存在 `~/.openclaw/agents/<agentId>/sessions/` 下。
- **Token 成本：** 更多 agents 意味著更多並行模型使用。
- **營運開銷：** 每 agent 驗證設定檔、工作區和頻道路由。

提示：
- 每個 agent 保持一個**活躍**工作區（`agents.defaults.workspace`）。
- 如果磁碟成長，修剪舊 sessions（刪除 JSONL 或儲存條目）。
- 使用 `openclaw doctor` 發現迷途工作區和 profile 不匹配。

## 模型預設選擇別名切換

### 什麼是預設模型

OpenClaw 的預設模型是你設定為：

```
agents.defaults.model.primary
```

模型引用為 `provider/model`（例如：`anthropic/claude-opus-4-5`）。如果你省略供應商，OpenClaw 目前假設 `anthropic` 作為臨時棄用備用——但你仍應**明確**設定 `provider/model`。

### 你推薦什麼模型

**建議預設：** `anthropic/claude-opus-4-5`。
**好的替代：** `anthropic/claude-sonnet-4-5`。
**可靠（較少個性）：** `openai/gpt-5.2` - 幾乎和 Opus 一樣好，只是個性較少。
**預算：** `zai/glm-4.7`。

MiniMax M2.1 有自己的文件：[MiniMax](/zh-Hant/providers/minimax) 和 [本地模型](/zh-Hant/gateway/local-models)。

經驗法則：對高風險工作使用**你能負擔的最佳模型**，對例行聊天或摘要使用更便宜的模型。你可以按 agent 路由模型並使用 sub-agents 並行化長任務（每個 sub-agent 消耗 token）。參閱 [模型](/zh-Hant/concepts/models) 和 [Sub-agents](/zh-Hant/tools/subagents)。

強烈警告：較弱/過度量化的模型更容易受到 prompt injection 和不安全行為的影響。參閱 [安全性](/zh-Hant/gateway/security)。

更多 context：[模型](/zh-Hant/concepts/models)。

### 如何在不清除設定的情況下切換模型

使用**模型指令**或只編輯**模型**欄位。避免完整設定替換。

安全選項：
- `/model` 在聊天中（快速，每 session）
- `openclaw models set ...`（只更新模型設定）
- `openclaw configure --section models`（互動式）
- 編輯 `~/.openclaw/openclaw.json` 中的 `agents.defaults.model`

除非你打算替換整個設定，否則避免用部分物件使用 `config.apply`。如果你確實覆蓋了設定，從備份恢復或重新執行 `openclaw doctor` 修復。

文件：[模型](/zh-Hant/concepts/models)、[Configure](/zh-Hant/cli/configure)、[Config](/zh-Hant/cli/config)、[Doctor](/zh-Hant/gateway/doctor)。

### 如何即時切換模型不重啟

使用 `/model` 指令作為獨立訊息：

```
/model sonnet
/model haiku
/model opus
/model gpt
/model gpt-mini
/model gemini
/model gemini-flash
```

你可以用 `/model`、`/model list` 或 `/model status` 列出可用模型。

`/model`（和 `/model list`）顯示一個緊湊的編號選擇器。按編號選擇：

```
/model 3
```

你也可以強制使用特定驗證設定檔（每 session）：

```
/model opus@anthropic:default
/model opus@anthropic:work
```

提示：`/model status` 顯示哪個 agent 活躍、使用哪個 `auth-profiles.json` 檔案，以及下一個會嘗試哪個驗證設定檔。它還顯示設定的供應商端點（`baseUrl`）和 API 模式（`api`）（如果可用）。

### 如何取消我用-profile-設定的固定

重新執行 `/model` **不帶** `@profile` 後綴：

```
/model anthropic/claude-opus-4-5
```

如果你想返回預設，從 `/model` 選擇它（或發送 `/model <default provider/model>`）。
使用 `/model status` 確認哪個驗證設定檔活躍。

## 模型故障轉移和所有模型都失敗了

### 故障轉移如何運作

故障轉移分兩個階段：

1) 同一供應商內的**驗證設定檔輪換**。
2) **模型備用**到 `agents.defaults.model.fallbacks` 中的下一個模型。

冷卻適用於失敗的設定檔（指數退避），所以 OpenClaw 可以在供應商受速率限制或暫時失敗時繼續回應。

### 這個錯誤是什麼意思

```
No credentials found for profile "anthropic:default"
```

這表示系統嘗試使用驗證設定檔 ID `anthropic:default`，但在預期的驗證儲存中找不到憑證。

### 修復-no-credentials-found-for-profile-anthropicdefault-的檢查清單

- **確認驗證設定檔的位置**（新 vs 舊版路徑）
  - 當前：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
  - 舊版：`~/.openclaw/agent/*`（由 `openclaw doctor` 遷移）
- **確認你的環境變數被 Gateway 載入**
  - 如果你在 shell 中設定 `ANTHROPIC_API_KEY` 但透過 systemd/launchd 執行 Gateway，它可能沒有繼承。將它放在 `~/.openclaw/.env` 或啟用 `env.shellEnv`。
- **確保你編輯的是正確的 agent**
  - 多 agent 設定意味著可能有多個 `auth-profiles.json` 檔案。
- **健全性檢查模型/驗證狀態**
  - 使用 `openclaw models status` 查看設定的模型和供應商是否已驗證。

### 為什麼它也嘗試-google-gemini-並失敗

如果你的模型設定包含 Google Gemini 作為備用（或你切換到 Gemini 快捷方式），OpenClaw 會在模型備用期間嘗試它。如果你沒有設定 Google 憑證，你會看到 `No API key found for provider "google"`。

修復：提供 Google 驗證，或在 `agents.defaults.model.fallbacks` / 別名中移除/避免 Google 模型，這樣備用不會路由到那裡。

## 驗證設定檔它們是什麼以及如何管理

相關：[/concepts/oauth](/zh-Hant/concepts/oauth)（OAuth 流程、token 儲存、多帳戶模式）

### 什麼是驗證設定檔

驗證設定檔是綁定到供應商的具名憑證記錄（OAuth 或 API 金鑰）。設定檔存在：

```
~/.openclaw/agents/<agentId>/agent/auth-profiles.json
```

### 典型的設定檔-id-是什麼

OpenClaw 使用供應商前綴的 ID，如：

- `anthropic:default`（當沒有電子郵件身份時常見）
- `anthropic:<email>` 用於 OAuth 身份
- 你選擇的自訂 ID（例如 `anthropic:work`）

### 我可以控制先嘗試哪個驗證設定檔嗎

可以。設定支援設定檔的可選中繼資料和每供應商的排序（`auth.order.<provider>`）。這**不**儲存秘密；它將 ID 映射到供應商/模式並設定輪換順序。

如果設定檔處於短期**冷卻**（速率限制/超時/驗證失敗）或較長的**停用**狀態（帳單/額度不足），OpenClaw 可能會暫時跳過它。要檢查這個，執行 `openclaw models status --json` 並檢查 `auth.unusableProfiles`。調整：`auth.cooldowns.billingBackoffHours*`。

你也可以透過 CLI 設定**每 agent** 順序覆蓋（儲存在該 agent 的 `auth-profiles.json` 中）：

```bash
# 預設使用設定的預設 agent（省略 --agent）
openclaw models auth order get --provider anthropic

# 鎖定輪換到單一設定檔（只嘗試這個）
openclaw models auth order set --provider anthropic anthropic:default

# 或設定明確順序（供應商內備用）
openclaw models auth order set --provider anthropic anthropic:work anthropic:default

# 清除覆蓋（退回到設定 auth.order / 輪詢）
openclaw models auth order clear --provider anthropic
```

要針對特定 agent：

```bash
openclaw models auth order set --provider anthropic --agent main anthropic:default
```

### oauth-vs-api-金鑰有什麼區別

OpenClaw 兩者都支援：

- **OAuth** 通常利用訂閱存取（如適用）。
- **API 金鑰**使用按 token 計費。

精靈明確支援 Anthropic setup-token 和 OpenAI Codex OAuth，也可以為你儲存 API 金鑰。

## Gateway連接埠已在執行和遠端模式

### gateway-使用什麼連接埠

`gateway.port` 控制 WebSocket + HTTP（Control UI、hooks 等）的單一多工連接埠。

優先順序：

```
--port > OPENCLAW_GATEWAY_PORT > gateway.port > 預設 18789
```

### 為什麼-openclaw-gateway-status-說-runtime-running-但-rpc-probe-failed

因為「running」是 **supervisor** 的視角（launchd/systemd/schtasks）。RPC 探測是 CLI 實際連接到 gateway WebSocket 並呼叫 `status`。

使用 `openclaw gateway status` 並信任這些行：
- `Probe target:`（探測實際使用的 URL）
- `Listening:`（連接埠上實際綁定的內容）
- `Last gateway error:`（程序存活但連接埠沒有監聽時的常見根本原因）

### 為什麼-openclaw-gateway-status-顯示-config-cli-和-config-service-不同

你在編輯一個設定檔而服務在執行另一個（通常是 `--profile` / `OPENCLAW_STATE_DIR` 不匹配）。

修復：
```bash
openclaw gateway install --force
```
從你想讓服務使用的同一 `--profile` / 環境執行。

### 另一個-gateway-實例已在監聽是什麼意思

OpenClaw 透過在啟動時立即綁定 WebSocket 監聽器（預設 `ws://127.0.0.1:18789`）來強制執行運行時鎖定。如果綁定因 `EADDRINUSE` 失敗，它會拋出 `GatewayLockError` 表示另一個實例已在監聽。

修復：停止另一個實例、釋放連接埠，或用 `openclaw gateway --port <port>` 執行。

### 如何在遠端模式執行-openclaw客戶端連接到其他地方的-gateway

設定 `gateway.mode: "remote"` 並指向遠端 WebSocket URL，可選帶 token/密碼：

```json5
{
  gateway: {
    mode: "remote",
    remote: {
      url: "ws://gateway.tailnet:18789",
      token: "your-token",
      password: "your-password"
    }
  }
}
```

注意：
- `openclaw gateway` 只在 `gateway.mode` 為 `local` 時啟動（或你傳遞覆蓋旗標）。
- macOS app 監視設定檔並在這些值變更時即時切換模式。

### control-ui-說未授權或持續重新連接怎麼辦

你的 gateway 啟用了驗證（`gateway.auth.*`），但 UI 沒有發送匹配的 token/密碼。

事實（來自程式碼）：
- Control UI 將 token 儲存在瀏覽器 localStorage 金鑰 `openclaw.control.settings.v1`。
- UI 可以匯入 `?token=...`（和/或 `?password=...`）一次，然後從 URL 中移除。

修復：
- 最快：`openclaw dashboard`（印出 + 複製帶 token 的連結，嘗試開啟；如果是 headless 顯示 SSH 提示）。
- 如果你還沒有 token：`openclaw doctor --generate-gateway-token`。
- 如果是遠端，先建立 tunnel：`ssh -N -L 18789:127.0.0.1:18789 user@host` 然後開啟 `http://127.0.0.1:18789/?token=...`。
- 在 gateway 主機上設定 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）。
- 在 Control UI 設定中貼上相同的 token（或用一次性 `?token=...` 連結重新整理）。
- 仍然卡住？執行 `openclaw status --all` 並遵循 [疑難排解](/zh-Hant/gateway/troubleshooting)。參閱 [Dashboard](/zh-Hant/web/dashboard) 獲取驗證詳情。

### 我設定了-gatewaybind-tailnet-但它無法綁定什麼都不監聽

`tailnet` bind 從你的網路介面選擇 Tailscale IP（100.64.0.0/10）。如果機器不在 Tailscale 上（或介面關閉），沒有東西可綁定。

修復：
- 在該主機上啟動 Tailscale（使它有 100.x 地址），或
- 切換到 `gateway.bind: "loopback"` / `"lan"`。

注意：`tailnet` 是明確的。`auto` 優先 loopback；當你想要僅 tailnet 綁定時使用 `gateway.bind: "tailnet"`。

### 我可以在同一主機上執行多個-gateway-嗎

通常不需要——一個 Gateway 可以執行多個訊息頻道和 agents。只有當你需要冗餘（例如：救援 bot）或硬隔離時才使用多個 Gateway。

可以，但你必須隔離：

- `OPENCLAW_CONFIG_PATH`（每實例設定）
- `OPENCLAW_STATE_DIR`（每實例狀態）
- `agents.defaults.workspace`（工作區隔離）
- `gateway.port`（唯一連接埠）

快速設定（建議）：
- 每個實例使用 `openclaw --profile <name> …`（自動建立 `~/.openclaw-<name>`）。
- 在每個 profile 設定中設定唯一的 `gateway.port`（或手動執行時傳遞 `--port`）。
- 安裝每 profile 服務：`openclaw --profile <name> gateway install`。

Profiles 也會後綴服務名稱（`bot.molt.<profile>`；舊版 `com.openclaw.*`、`openclaw-gateway-<profile>.service`、`OpenClaw Gateway (<profile>)`）。
完整指南：[多 Gateway](/zh-Hant/gateway/multiple-gateways)。

## 日誌和除錯

### 日誌在哪裡

檔案日誌（結構化）：

```
/tmp/openclaw/openclaw-YYYY-MM-DD.log
```

你可以透過 `logging.file` 設定穩定路徑。檔案日誌等級由 `logging.level` 控制。控制台詳細程度由 `--verbose` 和 `logging.consoleLevel` 控制。

最快的日誌追蹤：

```bash
openclaw logs --follow
```

服務/supervisor 日誌（當 gateway 透過 launchd/systemd 執行時）：
- macOS：`$OPENCLAW_STATE_DIR/logs/gateway.log` 和 `gateway.err.log`（預設：`~/.openclaw/logs/...`；profiles 使用 `~/.openclaw-<profile>/logs/...`）
- Linux：`journalctl --user -u openclaw-gateway[-<profile>].service -n 200 --no-pager`
- Windows：`schtasks /Query /TN "OpenClaw Gateway (<profile>)" /V /FO LIST`

更多請參閱 [疑難排解](/zh-Hant/gateway/troubleshooting#log-locations)。

### 如何啟動停止重啟-gateway-服務

使用 gateway 輔助指令：

```bash
openclaw gateway status
openclaw gateway restart
```

如果你手動執行 gateway，`openclaw gateway --force` 可以回收連接埠。參閱 [Gateway](/zh-Hant/gateway)。

### 我在-windows-上關閉了終端機如何重啟-openclaw

有**兩種 Windows 安裝模式**：

**1) WSL2（建議）：** Gateway 在 Linux 內執行。

開啟 PowerShell，進入 WSL，然後重啟：

```powershell
wsl
openclaw gateway status
openclaw gateway restart
```

如果你從未安裝服務，在前台啟動：

```bash
openclaw gateway run
```

**2) 原生 Windows（不建議）：** Gateway 直接在 Windows 中執行。

開啟 PowerShell 並執行：

```powershell
openclaw gateway status
openclaw gateway restart
```

如果你手動執行（無服務），使用：

```powershell
openclaw gateway run
```

文件：[Windows (WSL2)](/zh-Hant/platforms/windows)、[Gateway 服務指南](/zh-Hant/gateway)。

### gateway-正在執行但回覆從未到達應該檢查什麼

從快速健康掃描開始：

```bash
openclaw status
openclaw models status
openclaw channels status
openclaw logs --follow
```

常見原因：
- 模型驗證未在 **gateway 主機**上載入（檢查 `models status`）。
- 頻道配對/允許清單阻止回覆（檢查頻道設定 + 日誌）。
- WebChat/Dashboard 開啟但沒有正確的 token。

如果你是遠端，確認 tunnel/Tailscale 連線正常且 Gateway WebSocket 可達。

文件：[頻道](/zh-Hant/channels)、[疑難排解](/zh-Hant/gateway/troubleshooting)、[遠端存取](/zh-Hant/gateway/remote)。

### disconnected-from-gateway-no-reason-怎麼辦

這通常表示 UI 失去了 WebSocket 連線。檢查：

1) Gateway 正在執行嗎？`openclaw gateway status`
2) Gateway 健康嗎？`openclaw status`
3) UI 有正確的 token 嗎？`openclaw dashboard`
4) 如果是遠端，tunnel/Tailscale 連結正常嗎？

然後追蹤日誌：

```bash
openclaw logs --follow
```

文件：[Dashboard](/zh-Hant/web/dashboard)、[遠端存取](/zh-Hant/gateway/remote)、[疑難排解](/zh-Hant/gateway/troubleshooting)。

## 媒體與附件

### 我的-skill-產生了圖片pdf但沒有發送

來自 agent 的出站附件必須包含 `MEDIA:<path-or-url>` 行（獨立一行）。參閱 [OpenClaw 助理設定](/zh-Hant/start/openclaw) 和 [Agent send](/zh-Hant/tools/agent-send)。

CLI 發送：

```bash
openclaw message send --target +15555550123 --message "Here you go" --media /path/to/file.png
```

也檢查：
- 目標頻道支援出站媒體且未被允許清單阻止。
- 檔案在供應商的大小限制內（圖片調整大小至最大 2048px）。

參閱 [圖片](/zh-Hant/nodes/images)。

## 安全性和存取控制

### 將-openclaw-暴露給入站-dm-安全嗎

將入站 DM 視為不受信任的輸入。預設設計用於降低風險：

- DM 功能頻道的預設行為是**配對**：
  - 未知發送者收到配對碼；bot 不處理他們的訊息。
  - 用以下方式批准：`openclaw pairing approve <channel> <code>`
  - 待處理請求每頻道上限 **3 個**；如果碼沒有到達，檢查 `openclaw pairing list <channel>`。
- 公開開放 DM 需要明確選擇加入（`dmPolicy: "open"` 和允許清單 `"*"`）。

執行 `openclaw doctor` 以發現有風險的 DM 政策。

### prompt-injection-只是公開-bot-的問題嗎

不是。Prompt injection 是關於**不受信任的內容**，不只是誰可以私訊 bot。如果你的助理讀取外部內容（網頁搜尋/擷取、瀏覽器頁面、電子郵件、文件、附件、貼上的日誌），該內容可以包含試圖劫持模型的指令。即使**你是唯一發送者**這也可能發生。

最大風險是啟用工具時：模型可能被欺騙代你洩漏 context 或呼叫工具。透過以下方式減少影響範圍：
- 使用唯讀或停用工具的「讀取器」agent 來總結不受信任的內容
- 對啟用工具的 agents 關閉 `web_search` / `web_fetch` / `browser`
- 沙箱和嚴格工具允許清單

詳情：[安全性](/zh-Hant/gateway/security)。

### 我的-bot-應該有自己的電子郵件-github-帳戶或電話號碼嗎

是的，對於大多數設定。用獨立帳戶和電話號碼隔離 bot 可以在出問題時減少影響範圍。這也讓輪換憑證或撤銷存取更容易，而不影響你的個人帳戶。

從小處開始。只給你實際需要的工具和帳戶存取權，之後如有需要再擴展。

文件：[安全性](/zh-Hant/gateway/security)、[配對](/zh-Hant/start/pairing)。

### 我可以給它對我的簡訊的自主權這樣安全嗎

我們**不建議**對你的個人訊息完全自主。最安全的模式是：
- 保持 DM 在**配對模式**或嚴格允許清單。
- 如果你想讓它代你發訊息，使用**獨立號碼或帳戶**。
- 讓它草擬，然後**在發送前批准**。

如果你想實驗，在專用帳戶上進行並保持隔離。參閱 [安全性](/zh-Hant/gateway/security)。

### 我可以使用更便宜的模型處理個人助理任務嗎

可以，**如果** agent 僅限聊天且輸入是受信任的。較小層級更容易受到指令劫持，所以對啟用工具的 agents 或讀取不受信任內容時避免使用。如果必須使用較小模型，鎖定工具並在沙箱內執行。參閱 [安全性](/zh-Hant/gateway/security)。

### 我在-telegram-執行-start-但沒有收到配對碼

配對碼只在未知發送者發訊息給 bot 且 `dmPolicy: "pairing"` 啟用時發送。`/start` 本身不產生碼。

檢查待處理請求：
```bash
openclaw pairing list telegram
```

如果你想立即存取，將你的發送者 id 加入允許清單或為該帳戶設定 `dmPolicy: "open"`。

### whatsapp-會訊息我的聯絡人嗎配對如何運作

不會。預設 WhatsApp DM 政策是**配對**。未知發送者只收到配對碼，他們的訊息**不被處理**。OpenClaw 只回覆它收到的聊天或你觸發的明確發送。

用以下方式批准配對：

```bash
openclaw pairing approve whatsapp <code>
```

列出待處理請求：

```bash
openclaw pairing list whatsapp
```

精靈電話號碼提示：用於設定你的**允許清單/擁有者**，這樣你自己的 DM 被允許。它不用於自動發送。如果你在個人 WhatsApp 號碼上執行，使用該號碼並啟用 `channels.whatsapp.selfChatMode`。

## 聊天指令中止任務和它不會停止

### 如何停止內部系統訊息在聊天中顯示

大多數內部或工具訊息只在該 session 啟用 **verbose** 或 **reasoning** 時出現。

在你看到它的聊天中修復：
```
/verbose off
/reasoning off
```

如果仍然嘈雜，在 Control UI 中檢查 session 設定並將 verbose 設為 **inherit**。也確認你沒有使用在設定中將 `verboseDefault` 設為 `on` 的 bot profile。

文件：[思考和 verbose](/zh-Hant/tools/thinking)、[安全性](/zh-Hant/gateway/security#reasoning--verbose-output-in-groups)。

### 如何停止取消正在執行的任務

發送以下任一項作為**獨立訊息**（不帶斜線）：

```
stop
abort
esc
wait
exit
interrupt
```

這些是中止觸發器（不是斜線指令）。

對於背景程序（來自 exec 工具），你可以請 agent 執行：

```
process action:kill sessionId:XXX
```

斜線指令總覽：參閱 [斜線指令](/zh-Hant/tools/slash-commands)。

大多數指令必須作為以 `/` 開頭的**獨立**訊息發送，但一些快捷方式（如 `/status`）對允許清單發送者也可以內聯使用。

### 如何從-telegram-發送-discord-訊息跨-context-訊息被拒絕

OpenClaw 預設阻止**跨供應商**訊息。如果工具呼叫綁定到 Telegram，除非你明確允許，否則它不會發送到 Discord。

為 agent 啟用跨供應商訊息：

```json5
{
  agents: {
    defaults: {
      tools: {
        message: {
          crossContext: {
            allowAcrossProviders: true,
            marker: { enabled: true, prefix: "[from {channel}] " }
          }
        }
      }
    }
  }
}
```

編輯設定後重啟 gateway。如果你只想對單一 agent 這樣做，在 `agents.list[].tools.message` 下設定。

### 為什麼感覺-bot-忽略快速連發的訊息

佇列模式控制新訊息如何與進行中的執行互動。使用 `/queue` 變更模式：

- `steer` - 新訊息重新導向當前任務
- `followup` - 一次執行一條訊息
- `collect` - 批次訊息並回覆一次（預設）
- `steer-backlog` - 現在導向，然後處理積壓
- `interrupt` - 中止當前執行並重新開始

你可以為 followup 模式添加選項如 `debounce:2s cap:25 drop:summarize`。

---

仍然卡住？在 [Discord](https://discord.com/invite/clawd) 詢問或開啟 [GitHub discussion](https://github.com/openclaw/openclaw/discussions)。
