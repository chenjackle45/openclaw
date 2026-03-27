---
summary: "使用 Nix 宣告式地安裝 OpenClaw"
read_when:
  - 你想要可重現、可回滾的安裝
  - 你已在使用 Nix/NixOS/Home Manager
  - 你想要所有內容都被固定並以宣告方式管理
title: "Nix"
---

# Nix 安裝

使用 Nix 執行 OpenClaw 的推薦方法是透過 **[nix-openclaw](https://github.com/openclaw/nix-openclaw)** — 一個包含所有內容的 Home Manager 模組。

## 快速開始

貼到你的 AI 代理（Claude、Cursor 等）：

```text
I want to set up nix-openclaw on my Mac.
Repository: github:openclaw/nix-openclaw

What I need you to do:
1. Check if Determinate Nix is installed (if not, install it)
2. Create a local flake at ~/code/openclaw-local using templates/agent-first/flake.nix
3. Help me create a Telegram bot (@BotFather) and get my chat ID (@userinfobot)
4. Set up secrets (bot token, Anthropic key) - plain files at ~/.secrets/ is fine
5. Fill in the template placeholders and run home-manager switch
6. Verify: launchd running, bot responds to messages

Reference the nix-openclaw README for module options.
```

> **📦 完整指南：[github.com/openclaw/nix-openclaw](https://github.com/openclaw/nix-openclaw)**
>
> nix-openclaw repo 是 Nix 安裝的唯一權威來源。本頁面只是快速概覽。

## 你獲得什麼

- Gateway + macOS 應用程式 + 工具（whisper、spotify、cameras）— 全部固定
- 在重新啟動後倖存的 launchd 服務
- 具有宣告式配置的外掛系統
- 立即回滾：`home-manager switch --rollback`

---

## Nix Mode 執行時行為

當設定 `OPENCLAW_NIX_MODE=1` 時（使用 nix-openclaw 自動設定）：

OpenClaw 支援 **Nix mode**，使配置確定性且禁用自動安裝流程。
透過匯出啟用它：

```bash
OPENCLAW_NIX_MODE=1
```

在 macOS，GUI 應用程式不會自動繼承 shell 環境變數。你也可以
透過預設值啟用 Nix mode：

```bash
defaults write bot.molt.mac openclaw.nixMode -bool true
```

### 配置 + 狀態路徑

OpenClaw 從 `OPENCLAW_CONFIG_PATH` 讀取 JSON5 配置並將可變資料儲存在 `OPENCLAW_STATE_DIR`。
在需要時，你也可以設定 `OPENCLAW_HOME` 以控制用於內部路徑解析的基本主目錄。

- `OPENCLAW_HOME`（預設優先順序：`HOME` / `USERPROFILE` / `os.homedir()`）
- `OPENCLAW_STATE_DIR`（預設：`~/.openclaw`）
- `OPENCLAW_CONFIG_PATH`（預設：`$OPENCLAW_STATE_DIR/openclaw.json`）

在 Nix 下執行時，明確將這些設定為 Nix 管理的位置，以便執行時狀態和配置
保留在不可變存放區外。

### Nix mode 中的執行時行為

- 自動安裝和自我變異流程已禁用
- 遺失的依賴項會呈現 Nix 特定的修復訊息
- UI 在存在時呈現唯讀 Nix mode 橫幅

## 打包注意事項（macOS）

macOS 打包流程預期在以下位置有穩定的 Info.plist 範本：

```
apps/macos/Sources/OpenClaw/Resources/Info.plist
```

[`scripts/package-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/package-mac-app.sh) 將此範本複製到應用程式套件中並修補動態欄位
（套件 ID、版本/構建、Git SHA、Sparkle 金鑰）。這對 SwiftPM
打包和 Nix 構建保持 plist 確定性（不依賴完整 Xcode 工具鏈）。

## 相關資源

- [nix-openclaw](https://github.com/openclaw/nix-openclaw) — 完整設定指南
- [精靈](/zh-Hant/start/wizard) — 非 Nix CLI 設定
- [Docker](/zh-Hant/install/docker) — 容器化設定
