---
title: "Node.js"
summary: "安裝和配置 OpenClaw 的 Node.js — 版本需求、安裝選項和 PATH 故障排除"
read_when:
  - "您需要在安裝 OpenClaw 前安裝 Node.js"
  - "您安裝了 OpenClaw 但 `openclaw` 指令無法找到"
  - "npm install -g 因權限或 PATH 問題失敗"
---

# Node.js

OpenClaw 需要 **Node 22.16 或更新版本**。**Node 24 是預設且推薦的執行時**用於安裝、CI 和發佈工作流。Node 22 透過活躍 LTS 行保持支援。[安裝指令碼](/zh-Hant/install#install-methods)會自動檢測和安裝 Node — 此頁面供您想自己設定 Node 並確保一切正確連接時使用（版本、PATH、全域安裝）。

## 檢查您的版本

```bash
node -v
```

如果顯示 `v24.x.x` 或更高，您在推薦預設上。如果顯示 `v22.16.x` 或更高，您在支援的 Node 22 LTS 路徑上，但我們仍建議在方便時升級至 Node 24。如果 Node 未安裝或版本過舊，選擇下面的安裝方式。

## 安裝 Node

<Tabs>
  <Tab title="macOS">
    **Homebrew**（推薦）：

    ```bash
    brew install node
    ```

    或從 [nodejs.org](https://nodejs.org/) 下載 macOS 安裝程式。

  </Tab>
  <Tab title="Linux">
    **Ubuntu / Debian：**

    ```bash
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
    ```

    **Fedora / RHEL：**

    ```bash
    sudo dnf install nodejs
    ```

    或使用版本管理工具（見下文）。

  </Tab>
  <Tab title="Windows">
    **winget**（推薦）：

    ```powershell
    winget install OpenJS.NodeJS.LTS
    ```

    **Chocolatey：**

    ```powershell
    choco install nodejs-lts
    ```

    或從 [nodejs.org](https://nodejs.org/) 下載 Windows 安裝程式。

  </Tab>
</Tabs>

<Accordion title="使用版本管理工具（nvm、fnm、mise、asdf）">
  版本管理工具讓您輕鬆在 Node 版本間切換。流行選項：

- [**fnm**](https://github.com/Schniz/fnm) — 快速、跨平台
- [**nvm**](https://github.com/nvm-sh/nvm) — 在 macOS/Linux 上廣泛使用
- [**mise**](https://mise.jdx.dev/) — 多語言（Node、Python、Ruby 等）

fnm 範例：

```bash
fnm install 24
fnm use 24
```

  <Warning>
  確保您的版本管理工具在 shell 啟動檔案中初始化（`~/.zshrc` 或 `~/.bashrc`）。如果不是，`openclaw` 可能在新終端會話中找不到，因為 PATH 不包含 Node 的 bin 目錄。
  </Warning>
</Accordion>

## 故障排除

### `openclaw: command not found`

這幾乎總是意味著 npm 的全域 bin 目錄不在您的 PATH 上。

<Steps>
  <Step title="找到您的全域 npm 前綴">
    ```bash
    npm prefix -g
    ```
  </Step>
  <Step title="檢查它是否在你的 PATH 上">
    ```bash
    echo "$PATH"
    ```

    在輸出中查找 `<npm-prefix>/bin`（macOS/Linux）或 `<npm-prefix>`（Windows）。

  </Step>
  <Step title="將其新增到你的 shell 啟動檔">
    <Tabs>
      <Tab title="macOS / Linux">
        新增到 `~/.zshrc` 或 `~/.bashrc`：

        ```bash
        export PATH="$(npm prefix -g)/bin:$PATH"
        ```

        然後開啟新終端（或在 zsh 中執行 `rehash` / 在 bash 中執行 `hash -r`）。
      </Tab>
      <Tab title="Windows">
        透過「設定」→「系統」→「環境變數」將 `npm prefix -g` 的輸出新增到你的系統 PATH。
      </Tab>
    </Tabs>

  </Step>
</Steps>

### Linux 上 `npm install -g` 的權限錯誤

如果你看到 `EACCES` 錯誤，將 npm 的全域前綴切換到使用者可寫的目錄：

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
```

將 `export PATH=...` 行新增到你的 `~/.bashrc` 或 `~/.zshrc` 以使其永久生效。
