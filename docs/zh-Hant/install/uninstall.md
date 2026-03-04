---
summary: "完全解除安裝 OpenClaw（CLI、服務、狀態、工作區）"
read_when:
  - You want to remove OpenClaw from a machine
  - The gateway service is still running after uninstall
title: "Uninstall（解除安裝）"
---

# 解除安裝

兩個路徑：

- **簡易路徑**如果 `openclaw` 仍已安裝。
- **手動服務移除**如果 CLI 已刪除但服務仍在執行。

## 簡易路徑（CLI 仍已安裝）

推薦：使用內置解除安裝程式：

```bash
openclaw uninstall
```

非互動（自動化 / npx）：

```bash
openclaw uninstall --all --yes --non-interactive
npx -y openclaw uninstall --all --yes --non-interactive
```

手動步驟（同樣結果）：

1. 停止 Gateway 服務：

```bash
openclaw gateway stop
```

2. 解除安裝 Gateway 服務（launchd/systemd/schtasks）：

```bash
openclaw gateway uninstall
```

3. 刪除狀態 + 設定：

```bash
rm -rf "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
```

如果設定了 `OPENCLAW_CONFIG_PATH` 至狀態目錄外的自訂位置，也刪除該檔案。

4. 刪除你的工作區（選用，移除代理檔案）：

```bash
rm -rf ~/.openclaw/workspace
```

5. 移除 CLI 安裝（選擇你使用的那個）：

```bash
npm rm -g openclaw
pnpm remove -g openclaw
bun remove -g openclaw
```

6. 如果已安裝 macOS 應用程式：

```bash
rm -rf /Applications/OpenClaw.app
```

注意：

- 如果使用了設定檔（`--profile` / `OPENCLAW_PROFILE`），針對每個狀態目錄重複步驟 3（預設為 `~/.openclaw-<profile>`）。
- 在遠端模式中，狀態目錄位於 **Gateway 主機**上，所以也要在那裡執行步驟 1-4。

## 手動服務移除（CLI 未安裝）

如果 Gateway 服務繼續執行但 `openclaw` 缺失，使用此方式。

### macOS (launchd)

預設標籤是 `ai.openclaw.gateway`（或 `ai.openclaw.<profile>`；舊版 `com.openclaw.*` 可能仍存在）：

```bash
launchctl bootout gui/$UID/ai.openclaw.gateway
rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

如果使用了設定檔，使用 `ai.openclaw.<profile>` 替換標籤和 plist 名稱。如果有舊版 `com.openclaw.*` plist，也移除。

### Linux (systemd user unit)

預設單位名稱是 `openclaw-gateway.service`（或 `openclaw-gateway-<profile>.service`）：

```bash
systemctl --user disable --now openclaw-gateway.service
rm -f ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
```

### Windows (Scheduled Task)

預設任務名稱是 `OpenClaw Gateway`（或 `OpenClaw Gateway (<profile>)`）。
任務腳本位在你的狀態目錄下。

```powershell
schtasks /Delete /F /TN "OpenClaw Gateway"
Remove-Item -Force "$env:USERPROFILE\.openclaw\gateway.cmd"
```

如果使用了設定檔，刪除相符的任務名稱和 `~\.openclaw-<profile>\gateway.cmd`。

## 標準安裝 vs 源程式碼 checkout

### 標準安裝（install.sh / npm / pnpm / bun）

如果使用 `https://openclaw.ai/install.sh` 或 `install.ps1`，CLI 用 `npm install -g openclaw@latest` 安裝。
使用 `npm rm -g openclaw`（或 `pnpm remove -g` / `bun remove -g`（如果你用那種方式安裝））移除。

### 源程式碼 checkout (git clone)

如果從 repo checkout 執行（`git clone` + `openclaw ...` / `bun run openclaw ...`）：

1. **在刪除 repo 之前**解除安裝 Gateway 服務（使用上面的簡易路徑或手動服務移除）。
2. 刪除 repo 目錄。
3. 按上面所示移除狀態 + 工作區。
