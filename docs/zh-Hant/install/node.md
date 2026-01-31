---
title: "Node(Node.js 安裝)"
summary: "Node.js + npm 安裝檢查：版本要求、PATH 環境變數與全域安裝問題"
read_when:
  - "已安裝 OpenClaw 但執行時出現 `openclaw: command not found`"
  - "在新機器上設定 Node.js/npm 環境時"
  - "執行 `npm install -g` 失敗且出現權限或 PATH 問題時"
---

# Node.js + npm (PATH 設定檢查)

OpenClaw 的執行基準環境為 **Node 22+**。

如果您執行了 `npm install -g openclaw@latest` 但隨後看到 `openclaw: command not found`，這通常是 **PATH** 問題：npm 用於存放全域執行檔的目錄尚未加入到您的 Shell PATH 中。

## 快速診斷

執行以下指令：

```bash
node -v
npm -v
npm prefix -g
echo "$PATH"
```

如果 `$(npm prefix -g)/bin` (macOS/Linux) 或 `$(npm prefix -g)` (Windows) **沒有**出現在 `echo "$PATH"` 的輸出中，您的 Shell 就無法找到全域的 npm 執行檔（包括 `openclaw`）。

## 修復：將 npm 全域 bin 目錄加入 PATH

1) 找出您的全域 npm 前綴 (prefix)：

```bash
npm prefix -g
```

2) 將全域 npm bin 目錄加入您的 Shell 啟動設定檔中：

- zsh: `~/.zshrc`
- bash: `~/.bashrc`

範例（請將路徑替換為您 `npm prefix -g` 的輸出結果）：

```bash
# macOS / Linux
export PATH="/您的/npm/prefix/路徑/bin:$PATH"
```

接著開啟**新終端機**（或執行 `rehash` (zsh) / `hash -r` (bash)）。

在 Windows 上，請將 `npm prefix -g` 的輸出內容加入系統的「環境變數 (PATH)」中。

## 修復：避免 Linux 上的 `sudo npm install -g` / 權限錯誤

如果 `npm install -g ...` 失敗並出現 `EACCES` 錯誤，請將 npm 的全域前綴切換到使用者可寫入的目錄：

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
```

並記得將 `export PATH=...` 這行永久寫入您的 Shell 啟動設定檔中。

## 推薦的 Node 安裝選項

為了減少維護上的意外，建議以下列方式安裝 Node/npm：

- 保持 Node 為最新版本 (22+)
- 讓全域 npm bin 目錄穩定且已加入新 Shell 的 PATH 中

常見選擇：

- macOS: Homebrew (`brew install node`) 或版本管理工具 (Version Manager)
- Linux: 您偏好的版本管理工具，或提供 Node 22+ 的發行版安裝方式
- Windows: 官方 Node 安裝程式、`winget` 或 Windows 專用的 Node 版本管理工具

如果您使用版本管理工具（如 nvm/fnm/asdf 等），請確保它在您日常使用的 Shell (zsh 或 bash) 中已正確初始化，以便在執行安裝時 PATH 設定能正確生效。
