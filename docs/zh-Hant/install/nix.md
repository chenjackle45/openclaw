---
title: "Nix(Nix 安裝指南)"
summary: "使用 Nix 進行宣告式安裝 OpenClaw"
read_when:
  - 您想要可重現、可回滾的安裝方式時
  - 您已經在使用 Nix/NixOS/Home Manager 時
  - 您希望所有內容都由宣告式管理並固定版本時
---

# Nix 安裝指南

在 Nix 環境中執行 OpenClaw 的推薦方式是透過 **[nix-openclaw](https://github.com/openclaw/nix-openclaw)** —— 這是一個功能齊全的 Home Manager 模組。

## 快速開始

將以下內容貼給您的 AI 助手（Claude, Cursor 等）：

```text
我想在我的 Mac 上設定 nix-openclaw。
儲存庫：github:openclaw/nix-openclaw

我需要你做的事：
1. 檢查是否已安裝 Determinate Nix（若無則安裝）。
2. 使用 templates/agent-first/flake.nix 在 ~/code/openclaw-local 建立一個本地 Flake。
3. 協助我透過 @BotFather 建立一個 Telegram 機器人，並獲取我的 Chat ID (@userinfobot)。
4. 設定秘密資訊（Bot Token、Anthropic Key）—— 存放在 ~/.secrets/ 的純文字檔即可。
5. 填寫模板佔位符並執行 home-manager switch。
6. 驗證：launchd 正在執行，且機器人能回覆訊息。

參考 nix-openclaw 的 README 以獲取模組選項細節。
```

> **📦 完整指南：[github.com/openclaw/nix-openclaw](https://github.com/openclaw/nix-openclaw)**
>
> `nix-openclaw` 儲存庫是 Nix 安裝的最終權威來源。本頁僅提供簡要總覽。

## 使用 Nix 的優勢

- Gateway + macOS App + 工具（Whisper, Spotify, 相機）—— 全部固定版本。
- 自動重啟後仍能存活的 Launchd 服務。
- 具備宣告式配置的插件系統。
- 即時回滾：`home-manager switch --rollback`。

---

## Nix 模式下的執行期行為

當設定 `OPENCLAW_NIX_MODE=1` 時（nix-openclaw 會自動設定）：

OpenClaw 支援 **Nix 模式**，這會使配置具有確定性，並停用自動安裝流程。

在 macOS 上，GUI 應用程式不會自動繼承 Shell 環境變數。您也可以透過 defaults 啟用：

```bash
defaults write bot.molt.mac openclaw.nixMode -bool true
```

### 配置與狀態路徑

OpenClaw 從 `OPENCLAW_CONFIG_PATH` 讀取 JSON5 配置，並在 `OPENCLAW_STATE_DIR` 中存儲可變數據。

- `OPENCLAW_STATE_DIR` (預設：`~/.openclaw`)
- `OPENCLAW_CONFIG_PATH` (預設：`$OPENCLAW_STATE_DIR/openclaw.json`)

在 Nix 下執行時，請明確將這些路徑設定為由 Nix 管理的位置。

### Nix 模式下的執行行為
- 停用自動安裝與自我變更流程。
- 若缺漏依賴項，會顯示 Nix 專屬的修補建議訊息。
- UI 會在適當位置顯示唯讀的「Nix 模式」橫幅。
