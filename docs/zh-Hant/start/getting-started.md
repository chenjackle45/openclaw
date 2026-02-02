---
summary: "初學者指南：從零開始到發送第一則訊息（精靈導引、認證、頻道與配對）"
read_when:
  - 第一次從零開始設定時
  - 您想要從安裝到傳送第一則訊息的最快路徑時
title: "開始使用"
---

# 開始使用

目標：以最快速度實現 **從零** 到 **第一則成功對話**（並套用合理的預設設定）。

最速體驗：開啟控制介面 (Control UI)，無需設定通訊頻道。執行 `openclaw dashboard` 即可在瀏覽器中對話，或在 Gateway 主機開啟 `http://127.0.0.1:18789/`。
文件：[儀表板](/web/dashboard) 與 [控制介面](/web/control-ui)。

推薦路徑：使用 **CLI 入門精靈** (`openclaw onboard`)。它會協助您設定：

- 模型與認證（推薦 OAuth）
- Gateway 設定
- 通訊頻道（WhatsApp/Telegram/Discord/Mattermost（外掛）/...）
- 配對預設值（安全的私訊）
- 工作區引導與技能
- 選用的背景服務

如果您想查看更深層的參考頁面，請跳至：[精靈](/start/wizard)、[設定](/start/setup)、[配對](/start/pairing)、[安全性](/gateway/security)。

沙箱備註：`agents.defaults.sandbox.mode: "non-main"` 使用 `session.mainKey`（預設為 `"main"`），
所以群組/頻道會話會被沙箱化。如果您想讓主代理始終在主機上執行，請設置明確的每代理覆蓋：

```json
{
  "routing": {
    "agents": {
      "main": {
        "workspace": "~/.openclaw/workspace",
        "sandbox": { "mode": "off" }
      }
    }
  }
}
```

## 0) 前置需求

- Node `>=22`
- `pnpm`（選用；若您從原始碼建置則強力推薦）
- **推薦**：準備 Brave Search API 金鑰以供網路搜尋。最簡單的方法：
  `openclaw configure --section web`（儲存至 `tools.web.search.apiKey`）。
  詳見 [網路工具](/tools/web)。

macOS：如果您計畫建置應用程式，請安裝 Xcode / CLT。若僅需 CLI 與 Gateway，則 Node 已足夠。
Windows：使用 **WSL2**（推薦 Ubuntu）。WSL2 強烈推薦；原生 Windows 未經測試、問題更多且工具相容性較差。請先安裝 WSL2，接著在 WSL 內執行 Linux 的步驟。詳見 [Windows (WSL2)](/platforms/windows)。

## 1) 安裝 CLI（推薦）

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

安裝選項（安裝方法、非互動、從 GitHub）：[安裝](/install)。

Windows（PowerShell）：

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

替代方案（全域安裝）：

```bash
npm install -g openclaw@latest
```

```bash
pnpm add -g openclaw@latest
```

## 2) 執行入門精靈（並安裝服務）

```bash
openclaw onboard --install-daemon
```

您將選擇：

- **本地 vs 遠端** Gateway
- **認證**：OpenAI Code（Codex）訂閱（OAuth）或 API 金鑰。若為 Anthropic，推薦使用 API 金鑰；也支援 `claude setup-token`。
- **提供商**：WhatsApp QR 登入、Telegram/Discord bot 令牌、Mattermost 外掛令牌等。
- **守護程序**：背景安裝（launchd/systemd；WSL2 使用 systemd）
  - **執行環境**：Node（推薦；WhatsApp/Telegram 必需）。Bun **不推薦**。
- **Gateway 令牌**：精靈預設會生成一個（即使在本地環回）並儲存在 `gateway.auth.token`。

精靈文件：[精靈](/start/wizard)

### 認證：位置在哪裡（重要）

- **推薦的 Anthropic 路徑：**設置 API 金鑰（精靈可為服務使用而儲存）。若您想重用 Claude Code 認證，也支援 `claude setup-token`。

- OAuth 認證（舊版匯入）：`~/.openclaw/credentials/oauth.json`
- 認證設定檔（OAuth + API 金鑰）：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`

無頭/伺服器提示：先在一般機器上進行 OAuth，然後複製 `oauth.json` 到 Gateway 主機。

## 3) 啟動 Gateway

如果您在入門精靈中安裝了服務，Gateway 應該已在執行中：

```bash
openclaw gateway status
```

手動執行（前台）：

```bash
openclaw gateway --port 18789 --verbose
```

儀表板（本地環回）：`http://127.0.0.1:18789/`
若配置了令牌，請將其貼到控制介面設定中（儲存為 `connect.params.auth.token`）。

⚠️ **Bun 警告（WhatsApp + Telegram）：**Bun 在這些
頻道上有已知問題。如果您使用 WhatsApp 或 Telegram，請以 **Node** 執行 Gateway。

## 3.5) 快速驗證（2 分鐘）

```bash
openclaw status
openclaw health
openclaw security audit --deep
```

## 4) 配對 + 連接您的首個聊天介面

### WhatsApp（QR 登入）

```bash
openclaw channels login
```

透過 WhatsApp → 設定 → 已連結裝置掃描。

WhatsApp 文件：[WhatsApp](/channels/whatsapp)

### Telegram / Discord / 其他

精靈可為您寫入令牌/設定。若您偏好手動設定，請從以下開始：

- Telegram：[Telegram](/channels/telegram)
- Discord：[Discord](/channels/discord)
- Mattermost（外掛）：[Mattermost](/channels/mattermost)

**Telegram DM 提示：**您的首個 DM 會傳回配對碼。核准它（見下一步）或機器人不會回應。

## 5) DM 安全性（配對核准）

預設立場：未知 DM 會取得短碼，訊息在核准前不會被處理。
如果您的首個 DM 沒有收到回覆，請核准配對：

```bash
openclaw pairing list whatsapp
openclaw pairing approve whatsapp <code>
```

配對文件：[配對](/start/pairing)

## 從原始碼（開發）

若您在調整 OpenClaw 本身，請從原始碼執行：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 首次執行時自動安裝 UI 依賴
pnpm build
openclaw onboard --install-daemon
```

若您還沒有全域安裝，請從此儲存庫透過 `pnpm openclaw ...` 執行入門步驟。
`pnpm build` 也會打包 A2UI 資產；若您只需執行該步驟，請使用 `pnpm canvas:a2ui:bundle`。

Gateway（從此儲存庫）：

```bash
node openclaw.mjs gateway --port 18789 --verbose
```

## 7) 驗證端到端

在新終端機中發送測試訊息：

```bash
openclaw message send --target +15555550123 --message "Hello from OpenClaw"
```

若 `openclaw health` 顯示「無認證設定」，請返回精靈設置 OAuth/金鑰認證 — 代理無此無法回應。

提示：`openclaw status --all` 是最佳可貼上的唯讀除錯報告。
健康檢查：`openclaw health`（或 `openclaw status --deep`）向執行中的 Gateway 查詢健康快照。

## 後續步驟（選用但很棒）

- macOS 菜單列應用 + 語音喚醒：[macOS 應用](/platforms/macos)
- iOS/Android 節點（Canvas/相機/語音）：[節點](/nodes)
- 遠端存取（SSH 通道 / Tailscale Serve）：[遠端存取](/gateway/remote) 與 [Tailscale](/gateway/tailscale)
- 持續執行 / VPN 設定：[遠端存取](/gateway/remote)、[exe.dev](/platforms/exe-dev)、[Hetzner](/platforms/hetzner)、[macOS 遠端](/platforms/mac/remote)
