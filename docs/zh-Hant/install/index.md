---
title: "Index(安裝指南)"
summary: "安裝 OpenClaw（推薦安裝程式、全域安裝或從原始碼建置）"
read_when:
  - 正在安裝 OpenClaw 時
  - 您想要從 GitHub 原始碼安裝時
---

# 安裝指南

除非您有特殊需求，否則建議使用安裝腳本。它會自動設定 CLI 並執行入門引導流程。

## 快速安裝（推薦方式）

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

Windows (PowerShell 執行方式)：

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

接下來的步驟（如果您跳過了入門引導）：

```bash
openclaw onboard --install-daemon
```

## 系統需求

- **Node >= 22**
- macOS、Linux 或 Windows (透過 WSL2)
- 只有從原始碼建置才需要 `pnpm`

## 選擇您的安裝路徑

### 1) 安裝腳本（推薦）

透過 npm 全域安裝 `openclaw` 並執行入門引導。

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

安裝程式旗標說明：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --help
```

詳細原理請見：[安裝腳本內核](/install/installer)。

### 2) 全域安裝（手動）

如果您已安裝 Node：

```bash
npm install -g openclaw@latest
```

如果您在安裝 `sharp` 時遇到問題（常見於已透過 Homebrew 安裝 libvips 的 macOS 系統），請強制使用預建置的二進位檔案：

```bash
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
```

或是使用 pnpm：

```bash
pnpm add -g openclaw@latest
```

接著執行：

```bash
openclaw onboard --install-daemon
```

### 3) 從原始碼建置（貢獻者/開發者）

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 首次執行會自動安裝 UI 依賴
pnpm build
openclaw onboard --install-daemon
```

提示：如果您尚未進行全域安裝，請使用 `pnpm openclaw ...` 執行目錄下的指令。

### 4) 其他安裝選項

- [Docker](/install/docker)
- [Nix](/install/nix)
- [Ansible](/install/ansible)
- [Bun (僅限 CLI)](/install/bun)

## 安裝後動作

- 執行入門引導：`openclaw onboard --install-daemon`
- 快速檢查：`openclaw doctor`
- 檢查 Gateway 健康狀況：`openclaw status` + `openclaw health`
- 開啟儀表板：`openclaw dashboard`

## 疑難排解：找不到 `openclaw` (PATH 問題)

快速診斷：

```bash
node -v
npm -v
npm prefix -g
echo "$PATH"
```

如果 `$(npm prefix -g)/bin` (macOS/Linux) 或 `$(npm prefix -g)` (Windows) **沒有**出現在 `echo "$PATH"` 中，代表您的 Shell 找不到全域 npm 執行檔。

**修復方式**：將其加入您的 Shell 啟動設定檔中 (zsh: `~/.zshrc`, bash: `~/.bashrc`):

```bash
# macOS / Linux
export PATH="$(npm prefix -g)/bin:$PATH"
```

接著重新開啟終端機即可。

## 更新 / 移除安裝

- [更新指南](/install/updating)
- [遷移至新機器](/install/migrating)
- [移除安裝指南](/install/uninstall)
