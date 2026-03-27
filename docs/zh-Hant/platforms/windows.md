---
summary: "Windows（WSL2）支援 + 伴隨應用程式狀態"
read_when:
  - 在 Windows 上安裝 OpenClaw
  - 尋找 Windows 伴隨應用程式狀態
title: "Windows（Windows WSL2 支援）"
---

# Windows（WSL2）

Windows 上的 OpenClaw 建議**透過 WSL2**（推薦 Ubuntu）。
CLI + Gateway 在 Linux 內執行，保持執行環境一致，並讓工具更加相容（Node/Bun/pnpm、Linux 二進位檔、skills）。原生 Windows 可能較為複雜。WSL2 提供完整的 Linux 體驗——只需一行指令安裝：`wsl --install`。

原生 Windows 伴隨應用程式已在規劃中。

## 安裝（WSL2）

- [開始使用](/zh-Hant/start/getting-started)（在 WSL 內使用）
- [安裝與更新](/zh-Hant/install/updating)
- 官方 WSL2 指南（Microsoft）：[https://learn.microsoft.com/windows/wsl/install](https://learn.microsoft.com/windows/wsl/install)

## 原生 Windows 狀態

原生 Windows CLI 流程持續改善中，但 WSL2 仍是建議的方式。

目前在原生 Windows 上運作良好的功能：

- 透過 `install.ps1` 的網站安裝程式
- 本地 CLI 使用，例如 `openclaw --version`、`openclaw doctor` 和 `openclaw plugins list --json`
- 嵌入式本地 agent/provider smoke，例如：

```powershell
openclaw agent --local --agent main --thinking low -m "Reply with exactly WINDOWS-HATCH-OK."
```

目前注意事項：

- `openclaw onboard --non-interactive` 在未傳入 `--skip-health` 的情況下仍預期有可連線的本地 gateway
- `openclaw onboard --non-interactive --install-daemon` 和 `openclaw gateway install` 會先嘗試 Windows Scheduled Tasks
- 若 Scheduled Task 建立被拒，OpenClaw 會退回使用使用者層級的 Startup 資料夾登入項目並立即啟動 gateway
- Scheduled Tasks 仍是首選，因為它們提供更好的監控狀態

若你只想要原生 CLI，不需安裝 gateway 服務，請使用以下其中之一：

```powershell
openclaw onboard --non-interactive --skip-health
openclaw gateway run
```

若你確實想在原生 Windows 上管理啟動：

```powershell
openclaw gateway install
openclaw gateway status --json
```

若 Scheduled Task 建立被封鎖，備援服務模式仍會在登入後透過目前使用者的 Startup 資料夾自動啟動。

## Gateway

- [Gateway runbook](/zh-Hant/gateway)
- [設定](/zh-Hant/gateway/configuration)

## Gateway 服務安裝（CLI）

在 WSL2 內：

```
openclaw onboard --install-daemon
```

或：

```
openclaw gateway install
```

或：

```
openclaw configure
```

提示時選擇 **Gateway service**。

修復/遷移：

```
openclaw doctor
```

## Windows 登入前 Gateway 自動啟動

針對無頭設定，確保即使沒有人登入 Windows 也能執行完整的開機流程。

### 1) 在未登入時保持使用者服務運行

在 WSL 內：

```bash
sudo loginctl enable-linger "$(whoami)"
```

### 2) 安裝 OpenClaw gateway 使用者服務

在 WSL 內：

```bash
openclaw gateway install
```

### 3) 在 Windows 開機時自動啟動 WSL

以管理員身份在 PowerShell 中執行：

```powershell
schtasks /create /tn "WSL Boot" /tr "wsl.exe -d Ubuntu --exec /bin/true" /sc onstart /ru SYSTEM
```

將 `Ubuntu` 替換為以下指令中的你的 distro 名稱：

```powershell
wsl --list --verbose
```

### 驗證啟動流程

重啟後（Windows 登入前），從 WSL 確認：

```bash
systemctl --user is-enabled openclaw-gateway
systemctl --user status openclaw-gateway --no-pager
```

## 進階：透過 LAN 暴露 WSL 服務（portproxy）

WSL 有自己的虛擬網路。若另一台機器需要連接**在 WSL 內**執行的服務（SSH、本地 TTS 伺服器或 Gateway），你必須將 Windows 連接埠轉送至目前的 WSL IP。WSL IP 在重啟後會變更，因此你可能需要重新整理轉送規則。

範例（PowerShell **以管理員身份**）：

```powershell
$Distro = "Ubuntu-24.04"
$ListenPort = 2222
$TargetPort = 22

$WslIp = (wsl -d $Distro -- hostname -I).Trim().Split(" ")[0]
if (-not $WslIp) { throw "WSL IP not found." }

netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$ListenPort `
  connectaddress=$WslIp connectport=$TargetPort
```

允許連接埠通過 Windows 防火牆（一次性）：

```powershell
New-NetFirewallRule -DisplayName "WSL SSH $ListenPort" -Direction Inbound `
  -Protocol TCP -LocalPort $ListenPort -Action Allow
```

WSL 重啟後重新整理 portproxy：

```powershell
netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 | Out-Null
netsh interface portproxy add v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 `
  connectaddress=$WslIp connectport=$TargetPort | Out-Null
```

備註：

- 從另一台機器 SSH 連至 **Windows 主機 IP**（例如：`ssh user@windows-host -p 2222`）。
- 遠端節點必須指向**可連線的** Gateway URL（非 `127.0.0.1`）；使用 `openclaw status --all` 確認。
- 使用 `listenaddress=0.0.0.0` 允許 LAN 存取；`127.0.0.1` 則僅限本地。
- 若想自動化此流程，可建立 Scheduled Task 在登入時執行重新整理步驟。

## 逐步 WSL2 安裝

### 1) 安裝 WSL2 + Ubuntu

開啟 PowerShell（管理員）：

```powershell
wsl --install
# 或明確選擇 distro：
wsl --list --online
wsl --install -d Ubuntu-24.04
```

如果 Windows 要求，請重新開機。

### 2) 啟用 systemd（gateway 安裝必需）

在你的 WSL 終端機中：

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

然後從 PowerShell：

```powershell
wsl --shutdown
```

重新開啟 Ubuntu，然後確認：

```bash
systemctl --user status
```

### 3) 安裝 OpenClaw（在 WSL 內）

在 WSL 內按照 Linux 開始使用流程：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 第一次執行時自動安裝 UI 相依套件
pnpm build
openclaw onboard
```

完整指南：[開始使用](/zh-Hant/start/getting-started)

## Windows 伴隨應用程式

我們目前還沒有 Windows 伴隨應用程式。如果你想協助實現它，歡迎貢獻。
