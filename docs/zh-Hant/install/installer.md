---
title: "Installer(安裝腳本)"
summary: "安裝腳本（install.sh + install-cli.sh）的運作方式、旗標與自動化說明"
read_when:
  - 您想要瞭解 `openclaw.bot/install.sh` 的運作原理時
  - 您想要自動化安裝（CI / 無頭模式）時
  - 您想要從 GitHub 原始碼檢出版本進行安裝時
---

# 安裝腳本內核

OpenClaw 提供兩種主要的安裝腳本（由 `openclaw.ai` 提供服務）：

- `https://openclaw.bot/install.sh` —— **推薦**的安裝程式（預設執行 npm 全域安裝；亦可從 GitHub 原始碼檢出版本進行安裝）。
- `https://openclaw.bot/install-cli.sh` —— 對非 Root 使用者友好的 CLI 安裝程式（安裝到特定前綴目錄，並附帶專屬的 Node 執行期）。
- `https://openclaw.ai/install.ps1` —— Windows PowerShell 安裝程式（預設使用 npm；可選用 Git 安裝）。

若要查看目前的旗標與行為，請執行：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --help
```

Windows (PowerShell) 說明：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -?
```

如果安裝完成但在新終端機中找不到 `openclaw`，通常是 Node/npm 的 PATH 問題。請參閱：[安裝指南](/install#nodejs--npm-path-sanity)。

## install.sh (推薦)

高階運作邏輯：

- 偵測作業系統 (macOS / Linux / WSL)。
- 確保 Node.js 版本為 **22+** (macOS 透過 Homebrew；Linux 透過 NodeSource)。
- 選擇安裝方式：
  - `npm` (預設)：執行 `npm install -g openclaw@latest`。
  - `git`：複製/建置原始碼檢出版本並安裝包裝腳本 (Wrapper script)。
- 在 Linux 上：視需要將 npm 前綴切換至 `~/.npm-global` 以避免全域安裝權限錯誤。
- 如果是升級現有安裝：會執行 `openclaw doctor --non-interactive`（盡力而為）。
- 對於 Git 安裝：在安裝/更新後執行 `openclaw doctor --non-interactive`。

### 「Git 安裝」提示

如果您在 **OpenClaw 原始碼資料夾內**執行安裝程式（透過 `package.json` + `pnpm-workspace.yaml` 偵測），它會提示：
- 更新並使用此資料夾 (`git`)
- 或遷移至全域 npm 安裝 (`npm`)

在非互動式環境（無 TTY 或 `--no-prompt`）中，您必須傳遞 `--install-method git|npm`（或設定 `OPENCLAW_INSTALL_METHOD`），否則腳本將以狀態碼 `2` 結束。

### 為什麼需要 Git

在使用 `--install-method git` 路徑（複製 / 拉取）時必須具備 Git。

對於 `npm` 安裝，通常不需要 Git，但某些環境最終仍會用到它（例如當某個依賴項是經由 Git URL 獲取時）。安裝程式目前會確保 Git 存在，以避免在純淨的發行版上出現 `spawn git ENOENT` 意外。

## install-cli.sh (非 Root CLI 安裝程式)

此腳本將 `openclaw` 安裝至特定前綴目錄（預設為 `~/.openclaw`），並在該目錄下安裝專屬的 Node 執行期。這適用於您不想觸動系統全域 Node/npm 的環境。

使用說明：

```bash
curl -fsSL https://openclaw.bot/install-cli.sh | bash -s -- --help
```

## install.ps1 (Windows PowerShell)

高階運作邏輯：

- 確保 Node.js 為 **22+** (透過 winget/Chocolatey/Scoop 或手動安裝)。
- 選擇安裝方式：
  - `npm` (預設)：`npm install -g openclaw@latest`
  - `git`：複製/建置原始碼檢出版本並安裝包裝腳本
- 在升級或 Git 安裝時執行 `openclaw doctor --non-interactive`。

範例：

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

常見 Windows 問題：
- **"openclaw" 無法辨識**：您的 npm 全域 bin 資料夾不在 PATH 中。大多數系統使用 `%AppData%\\npm`。您可以執行 `npm config get prefix` 並將 `\\bin` 加入 PATH，然後重新開啟 PowerShell。
