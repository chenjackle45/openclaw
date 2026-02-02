---
title: "Nix"
summary: "使用 Nix 宣告式安裝 OpenClaw"
read_when:
  - 您想可重現、可回滾的安裝
  - 您已使用 Nix/NixOS/Home Manager
  - 您想一切宣告式管理且版本固定
---

# Nix 安裝

在 Nix 推薦執行 OpenClaw 的方式是透過 **[nix-openclaw](https://github.com/openclaw/nix-openclaw)** — 一個功能完整的 Home Manager 模組。

## 快速開始

貼此文到您的 AI 代理（Claude、Cursor 等）：

```text
我想在我的 Mac 上設定 nix-openclaw。
儲存庫：github:openclaw/nix-openclaw

您需要做的：
1. 檢查 Determinate Nix 是否已安裝（若無請安裝）
2. 使用 templates/agent-first/flake.nix 在 ~/code/openclaw-local 建立本地 flake
3. 幫我透過 @BotFather 建立 Telegram bot 並取得我的 chat ID（@userinfobot）
4. 設定秘密（bot token、Anthropic key）— ~/.secrets/ 純文字檔案可以
5. 填入模板佔位符並執行 home-manager switch
6. 驗證：launchd 執行中、bot 回應訊息

參考 nix-openclaw README 瞭解模組選項。
```

> **📦 完整指南：[github.com/openclaw/nix-openclaw](https://github.com/openclaw/nix-openclaw)**
>
> nix-openclaw 儲存庫是 Nix 安裝的真實來源。本頁只是快速概覽。

## 您將獲得

- Gateway + macOS app + 工具（whisper、spotify、cameras）— 全部版本固定
- Launchd 服務在重啟後存活
- 宣告式配置的插件系統
- 即時回滾：`home-manager switch --rollback`

---

## Nix 模式執行期行為

設定 `OPENCLAW_NIX_MODE=1` 時（nix-openclaw 自動設定）：

OpenClaw 支援 **Nix 模式**，使配置確定性且停用自動安裝流程。
透過匯出啟用：

```bash
OPENCLAW_NIX_MODE=1
```

在 macOS 上，GUI app 不自動繼承 shell 環境變數。也可透過 defaults 啟用：

```bash
defaults write bot.molt.mac openclaw.nixMode -bool true
```

### 配置 + 狀態路徑

OpenClaw 從 `OPENCLAW_CONFIG_PATH` 讀 JSON5 配置，儲存可變資料在 `OPENCLAW_STATE_DIR`。

- `OPENCLAW_STATE_DIR`（預設：`~/.openclaw`）
- `OPENCLAW_CONFIG_PATH`（預設：`$OPENCLAW_STATE_DIR/openclaw.json`）

Nix 下執行時，明確設為 Nix 管理的位置，讓執行期狀態和配置保持在不可變儲存之外。

### Nix 模式下的執行期行為

- 自動安裝和自我變更流程停用
- 遺漏依賴浮出 Nix 特定修復訊息
- UI 出現唯讀 Nix 模式橫幅

## 封裝備註（macOS）

macOS 封裝流程在以下位置需要穩定的 Info.plist 樣板：

```
apps/macos/Sources/OpenClaw/Resources/Info.plist
```

[`scripts/package-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/package-mac-app.sh) 複製此樣板到 app 套件並修補動態欄位（bundle ID、版本/建置、Git SHA、Sparkle 金鑰）。保持 plist 確定性用於 SwiftPM 封裝和 Nix 建置（不依賴完整 Xcode 工具鏈）。

## 相關

- [nix-openclaw](https://github.com/openclaw/nix-openclaw) — 完整設定指南
- [嚮導](/start/wizard) — 非 Nix CLI 設定
- [Docker](/install/docker) — 容器化設定
