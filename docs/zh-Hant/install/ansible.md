---
summary: "使用 Ansible、Tailscale VPN 和防火牆隔離進行自動化、安全加固的 OpenClaw 安裝"
read_when:
  - 您想要自動化伺服器部署並進行安全加固
  - 您需要防火牆隔離設定與 VPN 存取
  - 您正在部署到遠端 Debian/Ubuntu 伺服器
title: "Ansible"
---

# Ansible 安裝

將 OpenClaw 部署到生產伺服器的推薦方式是通過 **[openclaw-ansible](https://github.com/openclaw/openclaw-ansible)** — 一個具有安全優先架構的自動化安裝程式。

## 快速開始

一行命令安裝：

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw-ansible/main/install.sh | bash
```

> **📦 完整指南：[github.com/openclaw/openclaw-ansible](https://github.com/openclaw/openclaw-ansible)**
>
> openclaw-ansible 儲存庫是 Ansible 部署的唯一來源。此頁面是一個快速概述。

## 您將獲得什麼

- 🔒 **防火牆優先安全**：UFW + Docker 隔離（僅 SSH + Tailscale 可存取）
- 🔐 **Tailscale VPN**：安全的遠端存取，無需公開暴露服務
- 🐳 **Docker**：隔離的沙箱容器，僅本地綁定
- 🛡️ **深度防禦**：4 層安全架構
- 🚀 **一鍵設定**：幾分鐘內完成部署
- 🔧 **Systemd 整合**：開機時自動啟動並進行強化

## 要求

- **作業系統**：Debian 11+ 或 Ubuntu 20.04+
- **存取**：根目錄或 sudo 權限
- **網路**：網際網路連接以安裝套件
- **Ansible**：2.14+ （快速開始指令會自動安裝）

## 安裝內容

Ansible playbook 會安裝並配置：

1. **Tailscale**（安全遠端存取的網狀 VPN）
2. **UFW 防火牆**（僅 SSH + Tailscale 連接埠）
3. **Docker CE + Compose V2**（代理沙箱）
4. **Node.js 24 + pnpm**（執行時依賴；Node 22 LTS 目前 `22.16+` 仍受支援以相容）
5. **OpenClaw**（主機型，不容器化）
6. **Systemd 服務**（開機自動啟動且加固）

注意：Gateway 直接在主機上執行（不在 Docker 中），但代理沙箱使用 Docker 進行隔離。詳見 [沙箱](/zh-Hant/gateway/sandboxing)。

## 安裝後設定

安裝完成後，切換至 openclaw 使用者：

```bash
sudo -i -u openclaw
```

安裝後指令會引導您完成：

1. **上線精靈**：配置 OpenClaw 設定
2. **提供者登入**：連接 WhatsApp/Telegram/Discord/Signal
3. **Gateway 測試**：驗證安裝
4. **Tailscale 設定**：連接到您的 VPN 網狀網路

### 快速指令

```bash
# 檢查服務狀態
sudo systemctl status openclaw

# 查看實時日誌
sudo journalctl -u openclaw -f

# 重啟 Gateway
sudo systemctl restart openclaw

# 提供者登入（以 openclaw 使用者執行）
sudo -i -u openclaw
openclaw channels login
```

## 安全架構

### 4 層防禦

1. **防火牆 (UFW)**：僅公開 SSH (22) + Tailscale (41641/udp)
2. **VPN (Tailscale)**：Gateway 只能通過 VPN 網狀網路存取
3. **Docker 隔離**：DOCKER-USER iptables 鏈防止外部埠暴露
4. **Systemd 加固**：NoNewPrivileges、PrivateTmp、非特權使用者

### 驗證

測試外部攻擊面：

```bash
nmap -p- YOUR_SERVER_IP
```

應該僅顯示 **連接埠 22**（SSH）開放。所有其他服務（gateway、Docker）都被鎖定。

### Docker 可用性

Docker 是為了 **代理沙箱**（隔離工具執行），而非執行 gateway 本身。Gateway 僅綁定本地且透過 Tailscale VPN 存取。

詳見 [多代理沙箱與工具](/zh-Hant/tools/multi-agent-sandbox-tools)。

## 手動安裝

如果你偏好對自動化有更多控制：

```bash
# 1. 安裝先決條件
sudo apt update && sudo apt install -y ansible git

# 2. 複製 repository
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible

# 3. 安裝 Ansible collections
ansible-galaxy collection install -r requirements.yml

# 4. 執行 playbook
./run-playbook.sh

# 或直接執行（之後手動執行 /tmp/openclaw-setup.sh）
# ansible-playbook playbook.yml --ask-become-pass
```

## 更新 OpenClaw

Ansible 安裝程式會設定 OpenClaw 進行手動更新。詳見 [更新](/zh-Hant/install/updating)。

重新執行 Ansible playbook（例如進行配置變更）：

```bash
cd openclaw-ansible
./run-playbook.sh
```

注意：此操作是冪等的，安全執行多次。

## 故障排查

### 防火牆阻擋連線

如果你被鎖定：

- 確保先能透過 Tailscale VPN 存取
- SSH 存取（連接埠 22）始終允許
- Gateway **僅**透過 Tailscale 存取（設計如此）

### 服務無法啟動

```bash
# 檢查日誌
sudo journalctl -u openclaw -n 100

# 驗證權限
sudo ls -la /opt/openclaw

# 測試手動啟動
sudo -i -u openclaw
cd ~/openclaw
pnpm start
```

### Docker 沙箱問題

```bash
# 驗證 Docker 執行中
sudo systemctl status docker

# 檢查沙箱映像
sudo docker images | grep openclaw-sandbox

# 如果遺失沙箱映像，建置之
cd /opt/openclaw/openclaw
sudo -u openclaw ./scripts/sandbox-setup.sh
```

### Provider 登入失敗

確保以 `openclaw` 使用者執行：

```bash
sudo -i -u openclaw
openclaw channels login
```

## 進階配置

如需詳細安全架構與故障排查：

- [安全架構](https://github.com/openclaw/openclaw-ansible/blob/main/docs/security.md)
- [技術細節](https://github.com/openclaw/openclaw-ansible/blob/main/docs/architecture.md)
- [故障排查指南](https://github.com/openclaw/openclaw-ansible/blob/main/docs/troubleshooting.md)

## 相關資源

- [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) — 完整部署指南
- [Docker](/zh-Hant/install/docker) — 容器化 gateway 設定
- [沙箱化](/zh-Hant/gateway/sandboxing) — 代理沙箱配置
- [多代理沙箱與工具](/zh-Hant/tools/multi-agent-sandbox-tools) — 各代理隔離
