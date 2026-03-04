---
summary: "安全更新 OpenClaw（全域安裝或源程式碼），加上回退策略"
read_when:
  - Updating OpenClaw
  - Something breaks after an update
title: "Updating（更新）"
---

# 更新

OpenClaw 發展快速（正式版前）。視更新如同基礎設施運維：更新 → 執行檢查 → 重啟（或使用 `openclaw update`，會自動重啟）→ 驗證。

## 推薦：重新執行網站安裝程式（就地升級）

**首選**更新路徑是重新執行網站中的安裝程式。它偵測現有安裝，就地升級，並在需要時執行 `openclaw doctor`。

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

注意：

- 如果不想再次執行入門精靈，加上 `--no-onboard`。
- 對於**源程式碼安裝**，使用：

  ```bash
  curl -fsSL https://openclaw.ai/install.sh | bash -s -- --install-method git --no-onboard
  ```

  如果 repo 乾淨，安裝程式將 `git pull --rebase` **只執行一次**。

- 對於**全域安裝**，腳本在底層使用 `npm install -g openclaw@latest`。
- 舊版註記：`clawdbot` 仍作為相容性 shim 提供。

## 更新前

- 知道你的安裝方式：**全域**（npm/pnpm）vs **源程式碼**（git clone）。
- 知道你的 Gateway 執行方式：**前景終端**vs **受監督服務**（launchd/systemd）。
- 快照你的客製化：
  - 設定：`~/.openclaw/openclaw.json`
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

我們**不推薦** Bun 作為 Gateway 執行時（WhatsApp/Telegram 有 bug）。

要切換更新頻道（git + npm 安裝）：

```bash
openclaw update --channel beta
openclaw update --channel dev
openclaw update --channel stable
```

使用 `--tag <dist-tag|version>` 進行一次性安裝標籤/版本。

見[開發頻道](/zh-Hant/install/development-channels)了解頻道語義和發行說明。

注意：在 npm 安裝上，Gateway 在啟動時記錄更新提示（檢查當前頻道標籤）。通過 `update.checkOnStart: false` 禁用。

### 核心自動更新程式（選用）

自動更新程式**預設關閉**，是一個核心 Gateway 特性（不是外掛程式）。

```json
{
  "update": {
    "channel": "stable",
    "auto": {
      "enabled": true,
      "stableDelayHours": 6,
      "stableJitterHours": 12,
      "betaCheckIntervalHours": 1
    }
  }
}
```

行為：

- `stable`：看到新版本時，OpenClaw 等待 `stableDelayHours`，然後在 `stableJitterHours` 內應用確定的每安裝抖動（分散推出）。
- `beta`：以 `betaCheckIntervalHours` 節奏檢查（預設：每小時），在更新可用時應用。
- `dev`：無自動應用；使用手動 `openclaw update`。

使用 `openclaw update --dry-run` 在啟用自動化前預覽更新操作。

然後：

```bash
openclaw doctor
openclaw gateway restart
openclaw health
```

注意：

- 如果你的 Gateway 作為服務執行，`openclaw gateway restart` 比殺死 PID 更好。
- 如果你釘選至特定版本，見下面的「回退 / 釘選」。

## 更新（`openclaw update`）

對於**源程式碼安裝**（git checkout），優先使用：

```bash
openclaw update
```

它執行相對安全的更新流：

- 需要乾淨的工作樹。
- 切換至選定的頻道（標籤或分支）。
- 抓取 + rebase 至設定的上游（開發版頻道）。
- 安裝依賴、構建、構建 Control UI，並執行 `openclaw doctor`。
- 預設重啟 Gateway（使用 `--no-restart` 跳過）。

如果你通過 **npm/pnpm** 安裝（無 git 元資料），`openclaw update` 會嘗試通過你的套件管理器更新。如果偵測不到安裝，使用「更新（全域安裝）」。

## 更新（Control UI / RPC）

Control UI 有**更新 & 重啟**（RPC：`update.run`）。它：

1. 執行與 `openclaw update` 相同的源程式碼更新流（git checkout 只有）。
2. 以結構化報告（stdout/stderr 尾部）寫入重啟哨兵。
3. 重啟 Gateway 並以報告 ping 最後一個活躍會話。

如果 rebase 失敗，Gateway 中止並重啟而不應用更新。

## 更新（從源程式碼）

從 repo checkout：

推薦的：

```bash
openclaw update
```

手動（大致等同）：

```bash
git pull
pnpm install
pnpm build
pnpm ui:build # 首次執行時自動安裝 UI 依賴
openclaw doctor
openclaw health
```

注意：

- 當你執行已套件化的 `openclaw` 二進制檔案（[`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs)）或用 Node 執行 `dist/` 時，`pnpm build` 重要。
- 如果你從 repo checkout 執行而未進行全域安裝，對 CLI 命令使用 `pnpm openclaw ...`。
- 如果你直接從 TypeScript 執行（`pnpm openclaw ...`），重建通常不必要，但**設定遷移仍適用** → 執行 doctor。
- 在全域安裝和 git 安裝間切換很容易：安裝另一個版本，然後執行 `openclaw doctor`，所以 Gateway 服務進入點被改寫至當前安裝。

## 始終執行：`openclaw doctor`

Doctor 是「安全更新」命令。刻意乏味：修復 + 遷移 + 警告。

注意：如果你在**源程式碼安裝**（git checkout），`openclaw doctor` 會建議先執行 `openclaw update`。

它通常執行：

- 遷移已棄用的設定鍵 / 舊版設定檔位置。
- 審計 DM 策略，並在危險的「開放」設定上警告。
- 檢查 Gateway 健康，可以建議重啟。
- 偵測並遷移舊版 Gateway 服務（launchd/systemd；舊版 schtasks）至當前 OpenClaw 服務。
- 在 Linux 上，確保 systemd 用戶徘徊（所以 Gateway 在登出後存活）。

詳細：[Doctor](/zh-Hant/gateway/doctor)

## 啟動 / 停止 / 重啟 Gateway

CLI（不論 OS 都有效）：

```bash
openclaw gateway status
openclaw gateway stop
openclaw gateway restart
openclaw gateway --port 18789
openclaw logs --follow
```

如果你被監督：

- macOS launchd（應用程式整合的 LaunchAgent）：`launchctl kickstart -k gui/$UID/ai.openclaw.gateway`（使用 `ai.openclaw.<profile>`；舊版 `com.openclaw.*` 仍有效）
- Linux systemd 用戶服務：`systemctl --user restart openclaw-gateway[-<profile>].service`
- Windows (WSL2)：`systemctl --user restart openclaw-gateway[-<profile>].service`
  - 只有在服務已安裝時 `launchctl`/`systemctl` 才有效；否則執行 `openclaw gateway install`。

執行手冊 + 確切的服務標籤：[Gateway 執行手冊](/zh-Hant/gateway)

## 回退 / 釘選（當某些事情破裂時）

### 釘選（全域安裝）

安裝已知良好的版本（用最後一個工作的版本替換 `<version>`）：

```bash
npm i -g openclaw@<version>
```

```bash
pnpm add -g openclaw@<version>
```

提示：要查看當前發佈的版本，執行 `npm view openclaw version`。

然後重啟 + 重新執行 doctor：

```bash
openclaw doctor
openclaw gateway restart
```

### 釘選（源程式碼）按日期

從日期選取提交（例如：「2026-01-01 時 main 的狀態」）：

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

如果之後想回到最新版本：

```bash
git checkout main
git pull
```

## 如果你被卡住

- 再次執行 `openclaw doctor` 並仔細閱讀輸出（它通常會告訴你修復方式）。
- 檢查：[疑難排解](/zh-Hant/gateway/troubleshooting)
- 在 Discord 上提問：[https://discord.gg/clawd](https://discord.gg/clawd)
