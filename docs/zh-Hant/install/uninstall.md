---
title: "Uninstall(移除安裝)"
summary: "完全移除 OpenClaw（包含 CLI、服務、狀態目錄與工作區）"
read_when:
  - 您想要從機器上移除 OpenClaw 時
  - 移除後 Gateway 服務仍在執行的情況下
---

# 移除安裝 (Uninstall)

分為兩種路徑：
- **簡單路徑**：如果 `openclaw` 指令仍可使用。
- **手動移除服務**：如果 CLI 已被刪除，但 Gateway 服務仍在背景執行的情況。

## 簡單路徑 (CLI 仍可使用)

推薦做法：使用內建的解除安裝指令：

```bash
openclaw uninstall
```

非互動式執行（自動化 / npx）：

```bash
openclaw uninstall --all --yes --non-interactive
npx -y openclaw uninstall --all --yes --non-interactive
```

手動執行步驟（結果相同）：

1) **停止 Gateway 服務**：
```bash
openclaw gateway stop
```

2) **解除安裝服務** (launchd/systemd/schtasks)：
```bash
openclaw gateway uninstall
```

3) **刪除狀態與配置**：
```bash
rm -rf "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
```
如果您將 `OPENCLAW_CONFIG_PATH` 設定在狀態目錄之外的自訂位置，也請一併刪除該檔案。

4) **刪除工作區**（選用，這會移除 Agent 檔案）：
```bash
rm -rf ~/.openclaw/workspace
```

5) **移除 CLI 安裝**（根據您當初安裝的方式選擇）：
```bash
npm rm -g openclaw
pnpm remove -g openclaw
bun remove -g openclaw
```

6) **如果您安裝了 macOS App**：
```bash
rm -rf /Applications/OpenClaw.app
```

注意：
- 如果您使用了設定檔 (`--profile`），請針對每個狀態目錄重複執行步驟 3（預設通常為 `~/.openclaw-<profile>`）。
- 在遠端模式下，狀態目錄存放在 **Gateway 主機**上，請在該主機執行步驟 1-4。

## 手動移除服務 (CLI 已被刪除)

如果 `openclaw` 指令已遺失，但 Gateway 服務仍在背景執行，請依作業系統執行以下操作：

### macOS (launchd)

預設標籤為 `bot.molt.gateway`：

```bash
launchctl bootout gui/$UID/bot.molt.gateway
rm -f ~/Library/LaunchAgents/bot.molt.gateway.plist
```

### Linux (systemd 使用者單元)

預設單元名稱為 `openclaw-gateway.service`：

```bash
systemctl --user disable --now openclaw-gateway.service
rm -f ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
```

### Windows (工作排程器)

預設任務名稱為 `OpenClaw Gateway`。

```powershell
schtasks /Delete /F /TN "OpenClaw Gateway"
Remove-Item -Force "$env:USERPROFILE\.openclaw\gateway.cmd"
```

## 原始碼檢出版本的情況 (Git clone)

如果您是從倉庫檢出版本執行的：
1) **在刪除倉庫之前**，請先解除安裝 Gateway 服務（使用上述簡單路徑或手動移除方式）。
2) 刪除該倉庫目錄。
3) 按上方說明移除狀態與工作區。
