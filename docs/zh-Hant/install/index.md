---
title: "安裝"
summary: "安裝 OpenClaw（建議安裝程式、全域安裝或從原始碼）"
read_when:
  - 安裝 OpenClaw
  - 您想從 GitHub 安裝
---

# 安裝

除非有特別理由，否則使用安裝程式。它設定 CLI 並執行引導。

## 快速安裝（建議）

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

Windows（PowerShell）：

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
```

下一步（若跳過引導）：

```bash
openclaw onboard --install-daemon
```

## 系統需求

- **Node >=22**
- macOS、Linux 或 Windows via WSL2
- 從原始碼建置時才需 `pnpm`

## 選擇安裝路徑

### 1) 安裝程式腳本（建議）

透過 npm 全域安裝 `openclaw` 並執行引導。

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

安裝程式旗標：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --help
```

詳情：[安裝程式內部](/install/installer)。

非互動式（跳過引導）：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
```

### 2) 全域安裝（手動）

若已安裝 Node：

```bash
npm install -g openclaw@latest
```

若已全域安裝 libvips（macOS via Homebrew 常見）且 `sharp` 安裝失敗，強制預建二進制：

```bash
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
```

若見 `sharp: Please add node-gyp to your dependencies`，安裝建置工具（macOS：Xcode CLT + `npm install -g node-gyp`）或使用上面的 `SHARP_IGNORE_GLOBAL_LIBVIPS=1` 解決方案跳過原生建置。

或用 pnpm：

```bash
pnpm add -g openclaw@latest
pnpm approve-builds -g                # 核准 openclaw、node-llama-cpp、sharp 等
pnpm add -g openclaw@latest           # 重新執行以執行 postinstall 腳本
```

pnpm 需要明確核准有建置腳本的套件。第一次安裝顯示「忽略的建置腳本」警告後，執行 `pnpm approve-builds -g` 並選擇列出的套件，再重新執行安裝讓 postinstall 腳本執行。

接著：

```bash
openclaw onboard --install-daemon
```

### 3) 從原始碼（貢獻者/開發）

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 首次執行自動安裝 UI 依賴
pnpm build
openclaw onboard --install-daemon
```

提示：若未全域安裝，執行儲存庫指令用 `pnpm openclaw …`。

### 4) 其他安裝選項

- Docker：[Docker](/install/docker)
- Nix：[Nix](/install/nix)
- Ansible：[Ansible](/install/ansible)
- Bun（CLI 僅限）：[Bun](/install/bun)

## 安裝後

- 執行引導：`openclaw onboard --install-daemon`
- 快速檢查：`openclaw doctor`
- 檢查 Gateway 健康：`openclaw status` + `openclaw health`
- 開啟儀表板：`openclaw dashboard`

## 安裝方法：npm vs git（安裝程式）

安裝程式支援兩種方法：

- `npm`（預設）：`npm install -g openclaw@latest`
- `git`：從 GitHub 複製/建置並執行源代碼檢出

### CLI 旗標

```bash
# 明確 npm
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method npm

# 從 GitHub 安裝（源代碼檢出）
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git
```

通用旗標：

- `--install-method npm|git`
- `--git-dir <path>`（預設：`~/openclaw`）
- `--no-git-update`（使用現有檢出時跳過 `git pull`）
- `--no-prompt`（停用提示；CI/automation 需要）
- `--dry-run`（列印將發生的情況；無變更）
- `--no-onboard`（跳過引導）

### 環境變數

等效環境變數（自動化時實用）：

- `OPENCLAW_INSTALL_METHOD=git|npm`
- `OPENCLAW_GIT_DIR=...`
- `OPENCLAW_GIT_UPDATE=0|1`
- `OPENCLAW_NO_PROMPT=1`
- `OPENCLAW_DRY_RUN=1`
- `OPENCLAW_NO_ONBOARD=1`
- `SHARP_IGNORE_GLOBAL_LIBVIPS=0|1`（預設：`1`；避免 `sharp` 對系統 libvips 建置）

## 故障排除：`openclaw` 未找到（PATH）

快速診斷：

```bash
node -v
npm -v
npm prefix -g
echo "$PATH"
```

若 `$(npm prefix -g)/bin`（macOS/Linux）或 `$(npm prefix -g)`（Windows）**未**出現在 `echo "$PATH"` 中，shell 找不到全域 npm 二進制（包括 `openclaw`）。

修復：加至 shell 啟動檔案（zsh：`~/.zshrc`、bash：`~/.bashrc`）：

```bash
# macOS / Linux
export PATH="$(npm prefix -g)/bin:$PATH"
```

在 Windows 上，將 `npm prefix -g` 的輸出加至 PATH。

然後開啟新終端（或 zsh 中 `rehash` / bash 中 `hash -r`）。

## 更新 / 卸載

- 更新：[更新](/install/updating)
- 遷移至新機器：[遷移](/install/migrating)
- 卸載：[卸載](/install/uninstall)
