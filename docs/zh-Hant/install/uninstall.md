---
title: "卸載"
summary: "完全卸載 OpenClaw（CLI、服務、狀態、工作區）"
read_when:
  - 您想從機器移除 OpenClaw
  - Gateway 服務卸載後仍執行
---

# 卸載

兩條路徑：

- **簡單路徑**若 `openclaw` 仍安裝。
- **手動服務移除**若 CLI 已去但服務仍執行。

## 簡單路徑（CLI 仍安裝）

建議：使用內建卸載工具：

```bash
openclaw uninstall
```

非互動式（自動化 / npx）：

```bash
openclaw uninstall --all --yes --non-interactive
npx -y openclaw uninstall --all --yes --non-interactive
```

手動步驟（相同結果）：

1. 停止 Gateway 服務：

```bash
openclaw gateway stop
```

2. 卸載 Gateway 服務（launchd/systemd/schtasks）：

```bash
openclaw gateway uninstall
```

3. 刪除狀態 + 配置：

```bash
rm -rf "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
```

若在狀態目錄外設定 `OPENCLAW_CONFIG_PATH` 至自訂位置，也刪除該檔案。

4. 刪除工作區（可選，移除代理檔案）：

```bash
rm -rf ~/.openclaw/workspace
```

5. 移除 CLI 安裝（挑選您使用的）：

```bash
npm rm -g openclaw
pnpm remove -g openclaw
bun remove -g openclaw
```

6. 若安裝 macOS app：

```bash
rm -rf /Applications/OpenClaw.app
```

備註：

- 使用設定檔（`--profile` / `OPENCLAW_PROFILE`），重複步驟 3 各狀態目錄（預設 `~/.openclaw-<profile>`）。
- 遠端模式，狀態目錄位於**Gateway 主機**，也在那裡執行步驟 1-4。

## 手動服務移除（CLI 未安裝）

Gateway 服務保持執行但 `openclaw` 遺漏時使用。

### macOS（launchd）

預設標籤是 `bot.molt.gateway`（或 `bot.molt.<profile>`；舊版 `com.openclaw.*` 可能仍存在）：

```bash
launchctl bootout gui/$UID/bot.molt.gateway
rm -f ~/Library/LaunchAgents/bot.molt.gateway.plist
```

使用設定檔，以 `bot.molt.<profile>` 替換標籤和 plist 名。移除任何舊版 `com.openclaw.*` plist 若存在。

### Linux（systemd 使用者單位）

預設單位名是 `openclaw-gateway.service`（或 `openclaw-gateway-<profile>.service`）：

```bash
systemctl --user disable --now openclaw-gateway.service
rm -f ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
```

### Windows（排程任務）

預設任務名是 `OpenClaw Gateway`（或 `OpenClaw Gateway(<profile>)`）。
任務指令碼位於狀態目錄。

```powershell
schtasks /Delete /F /TN "OpenClaw Gateway"
Remove-Item -Force "$env:USERPROFILE\.openclaw\gateway.cmd"
```

使用設定檔，刪除相符任務名和 `~\.openclaw-<profile>\gateway.cmd`。

## 正常安裝 vs 源代碼檢出

### 正常安裝（install.sh / npm / pnpm / bun）

使用 `https://openclaw.ai/install.sh` 或 `install.ps1`，CLI 用 `npm install -g openclaw@latest` 安裝。
用 `npm rm -g openclaw` 移除（或 `pnpm remove -g` / `bun remove -g` 若那樣安裝）。

### 源代碼檢出（git clone）

從 repo 檢出執行（`git clone` + `openclaw …` / `bun run openclaw …`）：

1. 卸載 Gateway 服務**在**刪除 repo 前（使用簡單路徑或手動服務移除）。
2. 刪除 repo 目錄。
3. 移除狀態 + 工作區如上所示。
