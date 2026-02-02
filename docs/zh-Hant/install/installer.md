---
title: "安裝程式內部"
summary: "安裝程式指令碼如何工作（install.sh + install-cli.sh）、旗標與自動化"
read_when:
  - 您想理解 `openclaw.ai/install.sh`
  - 您想自動化安裝（CI / headless）
  - 您想從 GitHub 檢出安裝
---

# 安裝程式內部

OpenClaw 提供兩個安裝程式指令碼（從 `openclaw.ai` 提供）：

- `https://openclaw.ai/install.sh` — 「建議的」安裝程式（預設全域 npm 安裝；也可從 GitHub 檢出安裝）
- `https://openclaw.ai/install-cli.sh` — 非 root 友善 CLI 安裝程式（以自己的 Node 安裝至前綴）
- `https://openclaw.ai/install.ps1` — Windows PowerShell 安裝程式（npm 預設；可選 git 安裝）

查看當前旗標/行為，執行：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --help
```

Windows（PowerShell）幫助：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -?
```

若安裝程式完成但 `openclaw` 在新終端未找到，通常是 Node/npm PATH 問題。詳見：[安裝](/install#nodejs--npm-path-sanity)。

## install.sh（建議）

功能（高層次）：

- 偵測 OS（macOS / Linux / WSL）。
- 確保 Node.js **22+**（macOS via Homebrew；Linux via NodeSource）。
- 選擇安裝方法：
  - `npm`（預設）：`npm install -g openclaw@latest`
  - `git`：複製/建置源代碼檢出並安裝包裝腳本
- 在 Linux 上：必要時透過切換 npm 前綴至 `~/.npm-global` 避免全域 npm 權限錯誤。
- 若升級現有安裝：執行 `openclaw doctor --non-interactive`（盡力而為）。
- git 安裝：安裝/更新後執行 `openclaw doctor --non-interactive`（盡力而為）。
- 透過預設 `SHARP_IGNORE_GLOBAL_LIBVIPS=1` 緩和 `sharp` 原生安裝困境（避免對系統 libvips 建置）。

若您**想要** `sharp` 連結至全域安裝的 libvips（或除錯），設定：

```bash
SHARP_IGNORE_GLOBAL_LIBVIPS=0 curl -fsSL https://openclaw.ai/install.sh | bash
```

### 可發現性 / 「git 安裝」提示

若在**已位於 OpenClaw 源代碼檢出內**執行安裝程式（透過 `package.json` + `pnpm-workspace.yaml` 偵測），它提示：

- 更新並使用此檢出（`git`）
- 或遷移至全域 npm 安裝（`npm`）

在非互動式上下文（無 TTY / `--no-prompt`），必須傳遞 `--install-method git|npm`（或設定 `OPENCLAW_INSTALL_METHOD`），否則指令碼以代碼 `2` 退出。

### 為什麼需要 Git

Git 對於 `--install-method git` 路徑（複製 / 拉取）是必須的。

npm 安裝，Git **通常**不必須，但部分環境仍需要（例如套件或依賴透過 git URL 取得）。安裝程式目前確保 Git 存在以避免新發行版上 `spawn git ENOENT` 驚喜。

### 為什麼 npm 在新鮮 Linux 上遇到 `EACCES`

部分 Linux 設定（尤其透過系統套件管理器或 NodeSource 安裝 Node 後），npm 全域前綴指向 root 擁有的位置。然後 `npm install -g …` 失敗，出現 `EACCES` / `mkdir` 權限錯誤。

`install.sh` 透過切換前綴至：

- `~/.npm-global`（當 `~/.bashrc` / `~/.zshrc` 存在時加至 `PATH`）

## install-cli.sh（非 root CLI 安裝程式）

此指令碼安裝 `openclaw` 至前綴（預設：`~/.openclaw`）並也安裝專用 Node 執行期在該前綴下，讓它可在您不想接觸系統 Node/npm 的機器上運作。

幫助：

```bash
curl -fsSL https://openclaw.ai/install-cli.sh | bash -s -- --help
```

## install.ps1（Windows PowerShell）

功能（高層次）：

- 確保 Node.js **22+**（winget/Chocolatey/Scoop 或手動）。
- 選擇安裝方法：
  - `npm`（預設）：`npm install -g openclaw@latest`
  - `git`：複製/建置源代碼檢出並安裝包裝腳本
- 在升級和 git 安裝上執行 `openclaw doctor --non-interactive`（盡力而為）。

範例：

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex -InstallMethod git
```

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex -InstallMethod git -GitDir "C:\\openclaw"
```

環境變數：

- `OPENCLAW_INSTALL_METHOD=git|npm`
- `OPENCLAW_GIT_DIR=...`

Git 需求：

若選擇 `-InstallMethod git` 且 Git 遺漏，安裝程式將列印 Git for Windows 連結（`https://git-scm.com/download/win`）並退出。

常見 Windows 問題：

- **npm error spawn git / ENOENT**：安裝 Git for Windows 並重新開啟 PowerShell，再重新執行安裝程式。
- **「openclaw」未認可**：npm 全域 bin 資料夾不在 PATH 上。大多系統使用 `%AppData%\\npm`。您也可執行 `npm config get prefix` 並加 `\\bin` 至 PATH，再重新開啟 PowerShell。
