---
summary: "安全更新 OpenClaw（全域安裝或原始碼），加上回滾策略"
read_when:
  - 更新 OpenClaw
  - 更新後出現問題
title: "Updating（更新）"
---

# 更新

OpenClaw 發展快速（「1.0」前）。將更新視為基礎架構發佈：更新 → 執行檢查 → 重啟（或使用 `openclaw update`，會重啟）→ 驗證。

## 推薦：重新執行網站安裝程式（就地升級）

**首選**更新路徑是重新執行網站安裝程式。它
偵測現有安裝、就地升級，並在需要時執行 `openclaw doctor`。

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

注意：

- 如果你不想再次執行上線精靈，新增 `--no-onboard`。
- 對於**原始碼安裝**，使用：

  ```bash
  curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git --no-onboard
  ```

  安裝程式將 `git pull --rebase` **僅當** repo 乾淨時。

- 對於**全域安裝**，指令碼在引擎蓋下使用 `npm install -g openclaw@latest`。
- 舊版注意事項：`clawdbot` 仍可用作相容墊片。

## 更新前

- 知道你如何安裝：**全域**（npm/pnpm）對**從原始碼**（git clone）。
- 知道你的 Gateway 如何執行：**前景終端**對**受監管服務**（launchd/systemd）。
- 快照你的客製化：
  - 配置：`~/.openclaw/openclaw.json`
  - 認證：`~/.openclaw/credentials/`
  - 工作區：`~/.openclaw/workspace`

## 更新（全域安裝）

全域安裝（選一個）：

```bash
npm i -g openclaw@latest
```

```bash
pnpm add -g openclaw@latest
```

我們**不**推薦 Bun 用於 Gateway 執行時（WhatsApp/Telegram bugs）。

要切換更新頻道（git + npm 安裝）：

```bash
openclaw update --channel beta
openclaw update --channel dev
openclaw update --channel stable
```

使用 `--tag <dist-tag|version>` 進行一次性安裝標籤/版本。

詳見 [開發頻道](/zh-Hant/install/development-channels) 以了解頻道語意和發佈說明。

注意：在 npm 安裝上，gateway 在啟動時記錄更新提示（檢查目前頻道標籤）。透過 `update.checkOnStart: false` 禁用。

然後：

```bash
openclaw doctor
openclaw gateway restart
openclaw health
```

注意：

- 如果你的 Gateway 作為服務執行，`openclaw gateway restart` 比殺 PID 更好。
- 如果你固定到特定版本，詳見下面的「回滾 / 固定」。

## 更新（`openclaw update`）

對於**原始碼安裝**（git 簽出），偏好：

```bash
openclaw update
```

它執行安全的更新流程：

- 需要乾淨工作樹。
- 切換到所選頻道（標籤或分支）。
- 獲取 + 對配置的上游進行 rebase（dev 頻道）。
- 安裝 deps、構建、構建控制 UI，並執行 `openclaw doctor`。
- 預設重啟 gateway（使用 `--no-restart` 跳過）。

如果你透過 **npm/pnpm** 安裝（沒有 git 中繼資料），`openclaw update` 將嘗試透過你的套件管理程式更新。如果它無法偵測安裝，改用「更新（全域安裝）」。

## 更新（控制 UI / RPC）

控制 UI 有**更新和重啟** (RPC: `update.run`)。它：

1. 執行與 `openclaw update` 相同的原始碼更新流程（僅 git 簽出）。
2. 寫入具有結構化報告的重啟哨兵（stdout/stderr 尾部）。
3. 重啟 gateway 並透過報告 ping 最後一個活躍會話。

如果 rebase 失敗，gateway 中止並重啟而不應用更新。

## 更新（從原始碼）

從 repo 簽出：

推薦：

```bash
openclaw update
```

手動（大致相等）：

```bash
git pull
pnpm install
pnpm build
pnpm ui:build # 首次執行時自動安裝 UI deps
openclaw doctor
openclaw health
```

注意：

- `pnpm build` 在執行打包的 `openclaw` 二進位檔（[`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs)）或使用 Node 執行 `dist/` 時重要。
- 如果你從 repo 簽出執行而不全域安裝，將 CLI 指令使用 `pnpm openclaw ...`。
- 如果你直接從 TypeScript 執行（`pnpm openclaw ...`），重新構建通常不必要，但 **配置遷移仍適用** → 執行 doctor。
- 在全域和 git 安裝間切換很容易：安裝另一種風格，然後執行 `openclaw doctor` 讓 gateway 服務進入點重新寫入為目前安裝。

## 一律執行：`openclaw doctor`

Doctor 是「安全更新」指令。它刻意乏味：修復 + 遷移 + 警告。

注意：如果你在**原始碼安裝**（git 簽出）上，`openclaw doctor` 會提供先執行 `openclaw update` 的選項。

它執行的典型事物：

- 遷移已棄用的配置金鑰 / 舊版配置檔案位置。
- 審計 DM 政策並在危險「開放」設定上警告。
- 檢查 Gateway 健康狀況並可提供重啟。
- 偵測和遷移較舊的 gateway 服務（launchd/systemd；舊版 schtasks）到目前 OpenClaw 服務。
- 在 Linux 上，確保 systemd 使用者逗留（讓 Gateway 在登出後倖存）。

詳節：[Doctor](/zh-Hant/gateway/doctor)

## 啟動 / 停止 / 重啟 Gateway

CLI（無論操作系統如何工作）：

```bash
openclaw gateway status
openclaw gateway stop
openclaw gateway restart
openclaw gateway --port 18789
openclaw logs --follow
```

如果你受監管：

- macOS launchd（應用程式包含的 LaunchAgent）：`launchctl kickstart -k gui/$UID/bot.molt.gateway`（使用 `bot.molt.<profile>`；舊版 `com.openclaw.*` 仍可用）
- Linux systemd 使用者服務：`systemctl --user restart openclaw-gateway[-<profile>].service`
- Windows（WSL2）：`systemctl --user restart openclaw-gateway[-<profile>].service`
  - `launchctl`/`systemctl` 僅在安裝服務時工作；否則執行 `openclaw gateway install`。

Runbook + 確切服務標籤：[Gateway runbook](/zh-Hant/gateway)

## 回滾 / 固定（當出現問題時）

### 固定（全域安裝）

安裝已知良好版本（將 `<version>` 取代為最後一個有效的）：

```bash
npm i -g openclaw@<version>
```

```bash
pnpm add -g openclaw@<version>
```

提示：若要查看目前發佈的版本，執行 `npm view openclaw version`。

然後重啟 + 重新執行 doctor：

```bash
openclaw doctor
openclaw gateway restart
```

### 固定（原始碼）按日期

從日期選擇提交（例：「2026-01-01 的 main 狀態」）：

```bash
git fetch origin
git checkout "$(git rev-list -n 1 --before=\"2026-01-01\" origin/main)"
```

然後重新安裝 deps + 重啟：

```bash
pnpm install
pnpm build
openclaw gateway restart
```

如果你稍後想回到最新：

```bash
git checkout main
git pull
```

## 如果你卡住了

- 再次執行 `openclaw doctor` 並仔細閱讀輸出（它通常會告訴你修復）。
- 檢查：[故障排查](/zh-Hant/gateway/troubleshooting)
- 在 Discord 提問：[https://discord.gg/clawd](https://discord.gg/clawd)
