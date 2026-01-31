---
title: "windows(Windows (WSL2))"
summary: "Windows (WSL2) 支援 + 配套應用程式狀態"
read_when:
  - 在 Windows 上安裝 OpenClaw 時
  - 尋找 Windows 配套應用程式狀態時
---

# Windows (WSL2)

OpenClaw 在 Windows 上推薦 **透過 WSL2** (建議使用 Ubuntu)。
CLI 與 Gateway 在 Linux 內運行，這能保持執行環境一致，並使工具相容性更高 (Node/Bun/pnpm, Linux binaries, skills)。原生 Windows 安裝未經測試且問題較多。

原生 Windows 配套應用程式已在計畫中。

## 安裝 (WSL2)
- [Getting Started](/start/getting-started) (在 WSL 內使用)
- [Install & updates](/install/updating)
- 官方 WSL2 指南 (Microsoft): https://learn.microsoft.com/windows/wsl/install

## Gateway
- [Gateway runbook](/gateway)
- [Configuration](/gateway/configuration)

## Gateway 服務安裝 (CLI)

在 WSL2 內：

```bash
openclaw onboard --install-daemon
```

或：

```bash
openclaw gateway install
```

或：

```bash
openclaw configure
```

在提示時選擇 **Gateway service**。

修復/遷移：

```bash
openclaw doctor
```

## 進階：透過 LAN 暴露 WSL 服務 (portproxy)

WSL 擁有自己的虛擬網路。若另一台機器需要存取 **WSL 內** 運行的服務 (SSH, 本地 TTS 伺服器, 或 Gateway)，您必須將 Windows 通訊埠轉發至目前的 WSL IP。WSL IP 在重啟後會改變，因此您可能需要更新轉發規則。

範例 (PowerShell **以最高權限執行**):

```powershell
$Distro = "Ubuntu-24.04"
$ListenPort = 2222
$TargetPort = 22

$WslIp = (wsl -d $Distro -- hostname -I).Trim().Split(" ")[0]
if (-not $WslIp) { throw "WSL IP not found." }

netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$ListenPort `
  connectaddress=$WslIp connectport=$TargetPort
```

允許通訊埠通過 Windows 防火牆 (一次性):

```powershell
New-NetFirewallRule -DisplayName "WSL SSH $ListenPort" -Direction Inbound `
  -Protocol TCP -LocalPort $ListenPort -Action Allow
```

在 WSL 重啟後更新 portproxy：

```powershell
netsh interface portproxy delete v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 | Out-Null
netsh interface portproxy add v4tov4 listenport=$ListenPort listenaddress=0.0.0.0 `
  connectaddress=$WslIp connectport=$TargetPort | Out-Null
```

注意：
- 從另一台機器 SSH 的目標是 **Windows 主機 IP** (範例: `ssh user@windows-host -p 2222`)。
- 遠端節點必須指向 **可達的** Gateway URL (非 `127.0.0.1`)；使用 `openclaw status --all` 確認。
- 使用 `listenaddress=0.0.0.0` 以供 LAN 存取；`127.0.0.1` 僅限本地存取。
- 若希望自動化此步驟，請註冊工作排程器 (Scheduled Task) 在登入時執行更新步驟。

## 逐步 WSL2 安裝

### 1) 安裝 WSL2 + Ubuntu

開啟 PowerShell (Admin):

```powershell
wsl --install
# 或明確選擇 distro:
wsl --list --online
wsl --install -d Ubuntu-24.04
```

若 Windows 要求，請重新開機。

### 2) 啟用 systemd (Gateway 安裝所需)

在您的 WSL 終端機中：

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

接著從 PowerShell：

```powershell
wsl --shutdown
```

重新開啟 Ubuntu，然後驗證：

```bash
systemctl --user status
```

### 3) 安裝 OpenClaw (在 WSL 內)

在 WSL 內遵循 Linux Getting Started 流程：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 首次執行時自動安裝 UI 相依套件
pnpm build
openclaw onboard
```

完整指南: [Getting Started](/start/getting-started)

## Windows 配套應用程式

我們尚未有 Windows 配套應用程式。若您想協助開發，歡迎貢獻。
