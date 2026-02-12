---
title: "Node.js（Node.js 需求）"
summary: "為 OpenClaw 安裝和配置 Node.js — 版本需求、安裝選項和 PATH 故障排查"
read_when:
  - "你需要在安裝 OpenClaw 前安裝 Node.js"
  - "你已安裝 OpenClaw 但 `openclaw` 指令找不到"
  - "npm install -g 因權限或 PATH 問題失敗"
---

# Node.js

OpenClaw 需要 **Node 22 或更新版本**。[安裝程式指令碼](/zh-Hant/install#install-methods)會自動偵測和安裝 Node — 此頁面適用於你想要自己設定 Node 並確保所有內容正確連接（版本、PATH、全域安裝）的情況。

## 檢查你的版本

```bash
node -v
```

如果這列印 `v22.x.x` 或更高，你沒問題。如果 Node 未安裝或版本過舊，請選擇下面的安裝方法。

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
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    ```

    **Fedora / RHEL：**

    ```bash
    sudo dnf install nodejs
    ```

    或使用版本管理程式（見下文）。

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

<Accordion title="使用版本管理程式（nvm、fnm、mise、asdf）">
  版本管理程式讓你輕鬆在 Node 版本間切換。熱門選項：

- [**fnm**](https://github.com/Schniz/fnm) — 快速、跨平台
- [**nvm**](https://github.com/nvm-sh/nvm) — 在 macOS/Linux 上廣泛使用
- [**mise**](https://mise.jdx.dev/) — 多語言（Node、Python、Ruby 等）

使用 fnm 的範例：

```bash
fnm install 22
fnm use 22
```

  <Warning>
  確保你的版本管理程式已在你的 shell 啟動檔（`~/.zshrc` 或 `~/.bashrc`）中初始化。如果沒有，`openclaw` 可能在新終端會話中找不到，因為 PATH 不會包含 Node 的 bin 目錄。
  </Warning>
</Accordion>

## 故障排查

### `openclaw: command not found`

這幾乎總是意味著 npm 的全域 bin 目錄不在你的 PATH 上。

<Steps>
  <Step title="找到你的全域 npm 前綴">
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
