---
title: "更新"
summary: "安全更新 OpenClaw（全域安裝或源代碼），加上回滾策略"
read_when:
  - 更新 OpenClaw
  - 更新後出現問題
---

# 更新

OpenClaw 發展快速（1.0 前）。如基礎設施對待更新：更新 → 執行檢查 → 重啟（或使用 `openclaw update` 重啟） → 驗證。

## 建議：重新執行網站安裝程式（原地升級）

**首選**更新路徑是重新執行網站安裝程式。偵測現有安裝、原地升級並執行 `openclaw doctor` 需要。

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

備註：

- 加 `--no-onboard` 若不想引導精靈再執行。
- 對**源代碼安裝**，使用：
  ```bash
  curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git --no-onboard
  ```
  安裝程式僅當 repo 清潔時 `git pull --rebase`。
- 對**全域安裝**，指令碼在底層使用 `npm install -g openclaw@latest`。
- 舊版備註：`openclaw` 保持可用作相容性 shim。

## 更新前

- 知道如何安裝：**全域**（npm/pnpm）vs **源代碼**（git clone）。
- 知道 Gateway 如何執行：**前景終端**vs**受監督服務**（launchd/systemd）。
- 快照您的調整：
  - 配置：`~/.openclaw/openclaw.json`
  - 認證：`~/.openclaw/credentials/`
  - 工作區：`~/.openclaw/workspace`

## 更新（全域安裝）

全域安裝（挑一個）：

```bash
npm i -g openclaw@latest
```

```bash
pnpm add -g openclaw@latest
```

我們**不**建議 Bun 用於 Gateway 執行期（WhatsApp/Telegram bug）。

切換更新頻道（git + npm 安裝）：

```bash
openclaw update --channel beta
openclaw update --channel dev
openclaw update --channel stable
```

用 `--tag <dist-tag|version>` 一次性安裝標籤/版本。

詳見 [Development Channels](/install/development-channels) 取得頻道語義和發布說明。

備註：npm 安裝，Gateway 啟動時記錄更新提示（檢查當前頻道標籤）。透過 `update.checkOnStart: false` 停用。

接著：

```bash
openclaw doctor
openclaw gateway restart
openclaw health
```

備註：

- Gateway 作服務執行，`openclaw gateway restart` 優先於殺 PID。
- 版本固定，詳見下「回滾 / 固定」。

## 更新（`openclaw update`）

**源代碼安裝**（git checkout），傾向：

```bash
openclaw update
```

執行安全-ish 更新流程：

- 需乾淨工作樹。
- 切換至選定頻道（標籤或分支）。
- 取 + rebase 對配置上游（dev 頻道）。
- 安裝依賴、建置、建置 Control UI 並執行 `openclaw doctor`。
- 預設重啟 Gateway（使用 `--no-restart` 跳過）。

安裝**npm/pnpm**（無 git 中繼資料），`openclaw update` 試透過套件管理器更新。無法偵測安裝，使用「更新（全域安裝）」替代。

## 回滾 / 固定版本

### 使用 dev 頻道（git 源）進行快速回滾

若新版本破損，git install 最簡單回滾：

```bash
openclaw update --channel stable
```

或指定標籤：

```bash
openclaw update --tag v2025.2.1
```

### npm 安裝回滾

npm install，切換 dist-tag：

```bash
npm install -g openclaw@beta    # 或 @latest、@dev
openclaw doctor
openclaw gateway restart
```

或指定版本：

```bash
npm install -g openclaw@2025.2.1
openclaw doctor
openclaw gateway restart
```

查看版本：

```bash
npm view openclaw@latest version
```

### 固定特定版本

若需穩定版本，明確指定：

```bash
npm install -g openclaw@2025.1.15
```

（npm 不自動升級到更新版本除非您重新執行或設定更新檢查。）

## 常見問題

### 更新掛起或失敗

中止（Ctrl+C）並重試。若重複失敗，檢查網路和磁碟空間。

### Doctor 報告不匹配

若 `openclaw doctor` 在更新後報告問題，通常是無害的。按建議執行修復。

### 頻道切換後配置遺漏

確保您的配置檔案（`openclaw.json`）和工作區複製正確。詳見[遷移](/install/migrating)。

## 相關

- [Development Channels](/install/development-channels) — 頻道語義
- [Doctor](/gateway/doctor) — 配置檢查
- [Gateway 故障排除](/gateway/troubleshooting)
