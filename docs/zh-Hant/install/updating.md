---
title: "Updating(更新)"
summary: "安全更新 OpenClaw（全域安裝或原始碼），加上回滾策略"
read_when:
  - 更新 OpenClaw
  - 更新後有東西壞掉
---

# Updating（更新）

OpenClaw 進展很快（「1.0」之前）。像對待基礎設施部署一樣對待更新：更新 → 運行檢查 → 重啟（或使用 `openclaw update`，它會重啟）→ 驗證。

## 建議：重新運行網站安裝程式（原地升級）

**推薦的**更新路徑是重新運行網站的安裝程式。它會檢測現有安裝、原地升級，並在需要時運行 `openclaw doctor`。

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

備註：
- 如果您不想再次運行引導精靈，請新增 `--no-onboard`。
- 對於**原始碼安裝**，使用：
  ```bash
  curl -fsSL https://openclaw.bot/install.sh | bash -s -- --install-method git --no-onboard
  ```
  安裝程式**僅**當儲存庫乾淨時才會 `git pull --rebase`。
- 對於**全域安裝**，腳本在底層使用 `npm install -g openclaw@latest`。
- 舊版備註：`openclaw` 仍作為相容性 shim 可用。

## 更新前

- 知道您如何安裝：**全域**（npm/pnpm）vs **從原始碼**（git clone）。
- 知道您的 Gateway 如何運行：**前台終端機** vs **受監督服務**（launchd/systemd）。
- 快照您的客製化：
  - 設定：`~/.openclaw/openclaw.json`
  - 憑證：`~/.openclaw/credentials/`
  - 工作區：`~/.openclaw/workspace`

## 更新（全域安裝）

全域安裝（選擇一個）：

```bash
npm i -g openclaw@latest
```

```bash
pnpm add -g openclaw@latest
```
我們**不**建議使用 Bun 作為 Gateway 執行時（WhatsApp/Telegram 有 bug）。

切換更新頻道（git + npm 安裝）：

```bash
openclaw update --channel beta
openclaw update --channel dev
openclaw update --channel stable
```

使用 `--tag <dist-tag|version>` 進行一次性安裝標籤/版本。

請參閱 [開發頻道](/install/development-channels) 了解頻道語義和發行說明。

備註：在 npm 安裝上，Gateway 會在啟動時記錄更新提示（檢查當前頻道標籤）。透過 `update.checkOnStart: false` 停用。

然後：

```bash
openclaw doctor
openclaw gateway restart
openclaw health
```

備註：
- 如果您的 Gateway 作為服務運行，`openclaw gateway restart` 優於終止 PID。
- 如果您固定到特定版本，請參閱下面的「回滾 / 固定」。

## 更新（`openclaw update`）

對於**原始碼安裝**（git 簽出），推薦：

```bash
openclaw update
```

它運行一個安全的更新流程：
- 需要乾淨的工作樹。
- 切換到選定的頻道（標籤或分支）。
- 對設定的上游（dev 頻道）進行 fetch + rebase。
- 安裝依賴、建置、建置 Control UI，並運行 `openclaw doctor`。
- 預設重啟 Gateway（使用 `--no-restart` 跳過）。

如果您透過 **npm/pnpm** 安裝（無 git 元資料），`openclaw update` 會嘗試透過您的套件管理器更新。如果它無法檢測安裝，請改用「更新（全域安裝）」。

## 更新（Control UI / RPC）

Control UI 有 **Update & Restart**（RPC：`update.run`）。它：
1) 運行與 `openclaw update` 相同的原始碼更新流程（僅 git 簽出）。
2) 寫入帶有結構化報告（stdout/stderr 尾部）的重啟哨兵。
3) 重啟 Gateway 並向最後活動會話 ping 報告。

如果 rebase 失敗，Gateway 會中止並在不套用更新的情況下重啟。

## 更新（從原始碼）

從儲存庫簽出：

推薦：

```bash
openclaw update
```

手動（等效）：

```bash
git pull
pnpm install
pnpm build
pnpm ui:build # 首次運行時自動安裝 UI 依賴
openclaw doctor
openclaw health
```

備註：
- 當您運行打包的 `openclaw` 二進位檔（[`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs)）或使用 Node 運行 `dist/` 時，`pnpm build` 很重要。
- 如果您從儲存庫簽出運行而沒有全域安裝，請使用 `pnpm openclaw ...` 進行 CLI 命令。
- 如果您直接從 TypeScript 運行（`pnpm openclaw ...`），通常不需要重建，但**設定遷移仍然適用** → 運行 doctor。
- 在全域和 git 安裝之間切換很容易：安裝另一個版本，然後運行 `openclaw doctor` 以便 Gateway 服務入口點被重寫為當前安裝。

## 始終運行：`openclaw doctor`

Doctor 是「安全更新」命令。它故意很無聊：修復 + 遷移 + 警告。

備註：如果您在**原始碼安裝**（git 簽出）上，`openclaw doctor` 會提議先運行 `openclaw update`。

它通常做的事情：
- 遷移已棄用的設定鍵 / 舊設定檔案位置。
- 審計私訊策略並警告有風險的「open」設定。
- 檢查 Gateway 健康狀態並可以提議重啟。
- 檢測並將較舊的 Gateway 服務（launchd/systemd；舊版 schtasks）遷移到當前 OpenClaw 服務。
- 在 Linux 上，確保 systemd 用戶 lingering（使 Gateway 在登出後存活）。

詳情：[Doctor](/gateway/doctor)

## 啟動 / 停止 / 重啟 Gateway

CLI（不管作業系統都有效）：

```bash
openclaw gateway status
openclaw gateway stop
openclaw gateway restart
openclaw gateway --port 18789
openclaw logs --follow
```

如果您是受監督的：
- macOS launchd（應用程式綁定的 LaunchAgent）：`launchctl kickstart -k gui/$UID/bot.molt.gateway`（使用 `bot.molt.<profile>`；舊版 `com.openclaw.*` 仍有效）
- Linux systemd 用戶服務：`systemctl --user restart openclaw-gateway[-<profile>].service`
- Windows（WSL2）：`systemctl --user restart openclaw-gateway[-<profile>].service`
  - `launchctl`/`systemctl` 僅在服務已安裝時有效；否則運行 `openclaw gateway install`。

運行手冊 + 確切服務標籤：[Gateway 運行手冊](/gateway)

## 回滾 / 固定（當有東西壞掉時）

### 固定（全域安裝）

安裝已知良好的版本（將 `<version>` 替換為最後運作的版本）：

```bash
npm i -g openclaw@<version>
```

```bash
pnpm add -g openclaw@<version>
```

提示：要查看當前發布的版本，運行 `npm view openclaw version`。

然後重啟 + 重新運行 doctor：

```bash
openclaw doctor
openclaw gateway restart
```

### 按日期固定（原始碼）

選擇一個日期的 commit（範例：「2026-01-01 時 main 的狀態」）：

```bash
git fetch origin
git checkout "$(git rev-list -n 1 --before=\"2026-01-01\" origin/main)"
```

然後重新安裝依賴 + 重啟：

```bash
pnpm install
pnpm build
openclaw gateway restart
```

如果您想稍後回到最新：

```bash
git checkout main
git pull
```

## 如果您卡住了

- 再次運行 `openclaw doctor` 並仔細閱讀輸出（它通常會告訴您修復方法）。
- 查看：[疑難排解](/gateway/troubleshooting)
- 在 Discord 上詢問：https://channels.discord.gg/clawd
