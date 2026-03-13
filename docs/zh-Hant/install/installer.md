---
summary: "安裝程式腳本（install.sh、install-cli.sh、install.ps1）的運作原理、旗標及自動化"
read_when:
  - 您想了解 `openclaw.ai/install.sh` 的運作方式
  - 您想自動化安裝（CI / 無頭模式）
  - 您想從 GitHub checkout 安裝
title: "Installer Internals（安裝程式內部機制）"
---

# 安裝程式內部機制

OpenClaw 提供三個安裝程式腳本，從 `openclaw.ai` 提供服務。

| 腳本                               | 平台                 | 功能                                                                       |
| ---------------------------------- | -------------------- | -------------------------------------------------------------------------- |
| [`install.sh`](#installsh)         | macOS / Linux / WSL  | 必要時安裝 Node，透過 npm（預設）或 git 安裝 OpenClaw，並可執行引導程序。  |
| [`install-cli.sh`](#install-clish) | macOS / Linux / WSL  | 將 Node + OpenClaw 安裝到本機前置路徑（`~/.openclaw`）。不需要 root 權限。 |
| [`install.ps1`](#installps1)       | Windows (PowerShell) | 必要時安裝 Node，透過 npm（預設）或 git 安裝 OpenClaw，並可執行引導程序。  |

## 快速指令

<Tabs>
  <Tab title="install.sh">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
    ```

    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --help
    ```

  </Tab>
  <Tab title="install-cli.sh">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash
    ```

    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --help
    ```

  </Tab>
  <Tab title="install.ps1">
    ```powershell
    iwr -useb https://openclaw.ai/install.ps1 | iex
    ```

    ```powershell
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -Tag beta -NoOnboard -DryRun
    ```

  </Tab>
</Tabs>

<Note>
如果安裝成功但在新終端機中找不到 `openclaw`，請參閱 [Node.js 疑難排解](/zh-Hant/install/node#troubleshooting)。
</Note>

---

## install.sh

<Tip>
適用於大多數在 macOS/Linux/WSL 上的互動式安裝的建議選項。
</Tip>

### 流程（install.sh）

<Steps>
  <Step title="偵測 OS">
    支援 macOS 和 Linux（包括 WSL）。如果偵測到 macOS，若缺少 Homebrew 則安裝。
  </Step>
  <Step title="預設確保 Node.js 24">
    檢查 Node 版本，若需要則安裝 Node 24（macOS 上使用 Homebrew，Linux 上使用 apt/dnf/yum 的 NodeSource 設定腳本）。OpenClaw 仍支援 Node 22 LTS，目前為 `22.16+`，以確保相容性。
  </Step>
  <Step title="確保 Git">
    若缺少 Git 則安裝。
  </Step>
  <Step title="安裝 OpenClaw">
    - `npm` 方法（預設）：全域 npm 安裝
    - `git` 方法：clone/更新儲存庫，使用 pnpm 安裝相依項，建置，然後在 `~/.local/bin/openclaw` 安裝包裝程式
  </Step>
  <Step title="安裝後任務">
    - 在升級和 git 安裝時執行 `openclaw doctor --non-interactive`（盡力而為）
    - 在適當時嘗試引導程序（TTY 可用、引導程序未停用，且啟動/設定檢查通過）
    - 預設 `SHARP_IGNORE_GLOBAL_LIBVIPS=1`
  </Step>
</Steps>

### 原始碼 checkout 偵測

如果在 OpenClaw checkout 內執行（`package.json` + `pnpm-workspace.yaml`），腳本提供：

- 使用 checkout（`git`），或
- 使用全域安裝（`npm`）

如果沒有 TTY 可用且未設定安裝方法，它預設為 `npm` 並發出警告。

對於無效的方法選擇或無效的 `--install-method` 值，腳本以退出碼 `2` 退出。

### 範例（install.sh）

<Tabs>
  <Tab title="預設">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
    ```
  </Tab>
  <Tab title="跳過引導程序">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard
    ```
  </Tab>
  <Tab title="Git 安裝">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --install-method git
    ```
  </Tab>
  <Tab title="乾跑（Dry run）">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --dry-run
    ```
  </Tab>
</Tabs>

<AccordionGroup>
  <Accordion title="旗標參考">

| 旗標                            | 說明                                               |
| ------------------------------- | -------------------------------------------------- |
| `--install-method npm\|git`     | 選擇安裝方法（預設：`npm`）。別名：`--method`      |
| `--npm`                         | npm 方法的捷徑                                     |
| `--git`                         | git 方法的捷徑。別名：`--github`                   |
| `--version <version\|dist-tag>` | npm 版本或 dist-tag（預設：`latest`）              |
| `--beta`                        | 若可用則使用 beta dist-tag，否則回退到 `latest`    |
| `--git-dir <path>`              | Checkout 目錄（預設：`~/openclaw`）。別名：`--dir` |
| `--no-git-update`               | 跳過現有 checkout 的 `git pull`                    |
| `--no-prompt`                   | 停用提示                                           |
| `--no-onboard`                  | 跳過引導程序                                       |
| `--onboard`                     | 啟用引導程序                                       |
| `--dry-run`                     | 列印動作而不套用變更                               |
| `--verbose`                     | 啟用除錯輸出（`set -x`、npm notice-level 日誌）    |
| `--help`                        | 顯示使用說明（`-h`）                               |

  </Accordion>

  <Accordion title="環境變數參考">

| 變數                                        | 說明                                 |
| ------------------------------------------- | ------------------------------------ |
| `OPENCLAW_INSTALL_METHOD=git\|npm`          | 安裝方法                             |
| `OPENCLAW_VERSION=latest\|next\|<semver>`   | npm 版本或 dist-tag                  |
| `OPENCLAW_BETA=0\|1`                        | 若可用則使用 beta                    |
| `OPENCLAW_GIT_DIR=<path>`                   | Checkout 目錄                        |
| `OPENCLAW_GIT_UPDATE=0\|1`                  | 切換 git 更新                        |
| `OPENCLAW_NO_PROMPT=1`                      | 停用提示                             |
| `OPENCLAW_NO_ONBOARD=1`                     | 跳過引導程序                         |
| `OPENCLAW_DRY_RUN=1`                        | 乾跑模式                             |
| `OPENCLAW_VERBOSE=1`                        | 除錯模式                             |
| `OPENCLAW_NPM_LOGLEVEL=error\|warn\|notice` | npm 日誌層級                         |
| `SHARP_IGNORE_GLOBAL_LIBVIPS=0\|1`          | 控制 sharp/libvips 行為（預設：`1`） |

  </Accordion>
</AccordionGroup>

---

## install-cli.sh

<Info>
專為您希望將所有內容放在本機前置路徑（預設 `~/.openclaw`）且沒有系統 Node 相依項的環境設計。
</Info>

### 流程（install-cli.sh）

<Steps>
  <Step title="安裝本機 Node 執行期">
    下載已固定的受支援 Node tarball（目前預設 `22.22.0`）到 `<prefix>/tools/node-v<version>` 並驗證 SHA-256。
  </Step>
  <Step title="確保 Git">
    若缺少 Git，嘗試在 Linux 上透過 apt/dnf/yum 或在 macOS 上透過 Homebrew 安裝。
  </Step>
  <Step title="在前置路徑下安裝 OpenClaw">
    使用 npm 以 `--prefix <prefix>` 安裝，然後將包裝程式寫入 `<prefix>/bin/openclaw`。
  </Step>
</Steps>

### 範例（install-cli.sh）

<Tabs>
  <Tab title="預設">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash
    ```
  </Tab>
  <Tab title="自訂前置路徑 + 版本">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --prefix /opt/openclaw --version latest
    ```
  </Tab>
  <Tab title="自動化 JSON 輸出">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --json --prefix /opt/openclaw
    ```
  </Tab>
  <Tab title="執行引導程序">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --onboard
    ```
  </Tab>
</Tabs>

<AccordionGroup>
  <Accordion title="旗標參考">

| 旗標                   | 說明                                                                           |
| ---------------------- | ------------------------------------------------------------------------------ |
| `--prefix <path>`      | 安裝前置路徑（預設：`~/.openclaw`）                                            |
| `--version <ver>`      | OpenClaw 版本或 dist-tag（預設：`latest`）                                     |
| `--node-version <ver>` | Node 版本（預設：`22.22.0`）                                                   |
| `--json`               | 發出 NDJSON 事件                                                               |
| `--onboard`            | 安裝後執行 `openclaw onboard`                                                  |
| `--no-onboard`         | 跳過引導程序（預設）                                                           |
| `--set-npm-prefix`     | 在 Linux 上，若目前前置路徑不可寫入，強制將 npm 前置路徑設定為 `~/.npm-global` |
| `--help`               | 顯示使用說明（`-h`）                                                           |

  </Accordion>

  <Accordion title="環境變數參考">

| 變數                                        | 說明                                                         |
| ------------------------------------------- | ------------------------------------------------------------ |
| `OPENCLAW_PREFIX=<path>`                    | 安裝前置路徑                                                 |
| `OPENCLAW_VERSION=<ver>`                    | OpenClaw 版本或 dist-tag                                     |
| `OPENCLAW_NODE_VERSION=<ver>`               | Node 版本                                                    |
| `OPENCLAW_NO_ONBOARD=1`                     | 跳過引導程序                                                 |
| `OPENCLAW_NPM_LOGLEVEL=error\|warn\|notice` | npm 日誌層級                                                 |
| `OPENCLAW_GIT_DIR=<path>`                   | 舊版清除查找路徑（移除舊 `Peekaboo` 子模組 checkout 時使用） |
| `SHARP_IGNORE_GLOBAL_LIBVIPS=0\|1`          | 控制 sharp/libvips 行為（預設：`1`）                         |

  </Accordion>
</AccordionGroup>

---

## install.ps1

### 流程（install.ps1）

<Steps>
  <Step title="確保 PowerShell + Windows 環境">
    需要 PowerShell 5+。
  </Step>
  <Step title="預設確保 Node.js 24">
    若缺少，嘗試透過 winget、然後 Chocolatey、然後 Scoop 安裝。Node 22 LTS，目前為 `22.16+`，仍支援以確保相容性。
  </Step>
  <Step title="安裝 OpenClaw">
    - `npm` 方法（預設）：使用選取的 `-Tag` 進行全域 npm 安裝
    - `git` 方法：clone/更新儲存庫，使用 pnpm 安裝/建置，並在 `%USERPROFILE%\.local\bin\openclaw.cmd` 安裝包裝程式
  </Step>
  <Step title="安裝後任務">
    在可能的情況下將所需的 bin 目錄新增到使用者 PATH，然後在升級和 git 安裝時執行 `openclaw doctor --non-interactive`（盡力而為）。
  </Step>
</Steps>

### 範例（install.ps1）

<Tabs>
  <Tab title="預設">
    ```powershell
    iwr -useb https://openclaw.ai/install.ps1 | iex
    ```
  </Tab>
  <Tab title="Git 安裝">
    ```powershell
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -InstallMethod git
    ```
  </Tab>
  <Tab title="自訂 git 目錄">
    ```powershell
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -InstallMethod git -GitDir "C:\openclaw"
    ```
  </Tab>
  <Tab title="乾跑（Dry run）">
    ```powershell
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -DryRun
    ```
  </Tab>
  <Tab title="除錯追蹤">
    ```powershell
    # install.ps1 目前沒有專用的 -Verbose 旗標。
    Set-PSDebug -Trace 1
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
    Set-PSDebug -Trace 0
    ```
  </Tab>
</Tabs>

<AccordionGroup>
  <Accordion title="旗標參考">

| 旗標                      | 說明                                            |
| ------------------------- | ----------------------------------------------- |
| `-InstallMethod npm\|git` | 安裝方法（預設：`npm`）                         |
| `-Tag <tag>`              | npm dist-tag（預設：`latest`）                  |
| `-GitDir <path>`          | Checkout 目錄（預設：`%USERPROFILE%\openclaw`） |
| `-NoOnboard`              | 跳過引導程序                                    |
| `-NoGitUpdate`            | 跳過 `git pull`                                 |
| `-DryRun`                 | 僅列印動作                                      |

  </Accordion>

  <Accordion title="環境變數參考">

| 變數                               | 說明          |
| ---------------------------------- | ------------- |
| `OPENCLAW_INSTALL_METHOD=git\|npm` | 安裝方法      |
| `OPENCLAW_GIT_DIR=<path>`          | Checkout 目錄 |
| `OPENCLAW_NO_ONBOARD=1`            | 跳過引導程序  |
| `OPENCLAW_GIT_UPDATE=0`            | 停用 git pull |
| `OPENCLAW_DRY_RUN=1`               | 乾跑模式      |

  </Accordion>
</AccordionGroup>

<Note>
如果使用 `-InstallMethod git` 且缺少 Git，腳本會退出並列印 Git for Windows 連結。
</Note>

---

## CI 和自動化

對於可預測的執行，使用非互動式旗標/環境變數。

<Tabs>
  <Tab title="install.sh（非互動式 npm）">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard
    ```
  </Tab>
  <Tab title="install.sh（非互動式 git）">
    ```bash
    OPENCLAW_INSTALL_METHOD=git OPENCLAW_NO_PROMPT=1 \
      curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
    ```
  </Tab>
  <Tab title="install-cli.sh（JSON）">
    ```bash
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --json --prefix /opt/openclaw
    ```
  </Tab>
  <Tab title="install.ps1（跳過引導程序）">
    ```powershell
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
    ```
  </Tab>
</Tabs>

---

## 疑難排解

<AccordionGroup>
  <Accordion title="為什麼需要 Git？">
    `git` 安裝方法需要 Git。對於 `npm` 安裝，仍然會檢查/安裝 Git，以避免相依項使用 git URL 時出現 `spawn git ENOENT` 失敗。
  </Accordion>

  <Accordion title="為什麼 npm 在 Linux 上出現 EACCES？">
    某些 Linux 設定將 npm 全域前置路徑指向 root 擁有的路徑。`install.sh` 可以將前置路徑切換到 `~/.npm-global` 並在 shell rc 檔案存在時附加 PATH 匯出（如果那些檔案存在）。
  </Accordion>

  <Accordion title="sharp/libvips 問題">
    腳本預設 `SHARP_IGNORE_GLOBAL_LIBVIPS=1` 以避免 sharp 針對系統 libvips 建置。若要覆寫：

    ```bash
    SHARP_IGNORE_GLOBAL_LIBVIPS=0 curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
    ```

  </Accordion>

  <Accordion title='Windows："npm error spawn git / ENOENT"'>
    安裝 Git for Windows，重新開啟 PowerShell，重新執行安裝程式。
  </Accordion>

  <Accordion title='Windows："openclaw is not recognized"'>
    執行 `npm config get prefix` 並將該目錄新增到您的使用者 PATH（Windows 上不需要 `\bin` 後綴），然後重新開啟 PowerShell。
  </Accordion>

  <Accordion title="Windows：如何取得詳細的安裝程式輸出">
    `install.ps1` 目前未公開 `-Verbose` 切換。
    使用 PowerShell 追蹤進行腳本層級診斷：

    ```powershell
    Set-PSDebug -Trace 1
    & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
    Set-PSDebug -Trace 0
    ```

  </Accordion>

  <Accordion title="安裝後找不到 openclaw">
    通常是 PATH 問題。請參閱 [Node.js 疑難排解](/zh-Hant/install/node#troubleshooting)。
  </Accordion>
</AccordionGroup>
