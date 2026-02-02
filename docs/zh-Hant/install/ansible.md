---
title: "Ansible"
summary: "透過 Ansible、Tailscale VPN 與防火牆隔離進行自動化且加固的 OpenClaw 安裝"
read_when:
  - 您想要進行具備安全加固的自動化伺服器部署時
  - 您需要透過 VPN 存取的防火牆隔離環境時
  - 您正在將 OpenClaw 部署至遠端 Debian/Ubuntu 伺服器時
---

# Ansible 安裝

將 OpenClaw 部署至生產伺服器的推薦方式是透過 **[openclaw-ansible](https://github.com/openclaw/openclaw-ansible)** —— 一個具備安全優先架構的自動化安裝工具。

## 快速開始

一鍵安裝指令：

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw-ansible/main/install.sh | bash
```

> **📦 完整指南：[github.com/openclaw/openclaw-ansible](https://github.com/openclaw/openclaw-ansible)**
>
> openclaw-ansible 儲存庫是 Ansible 部署的最終權威來源。本頁僅提供快速概覽。

## 您將獲得

- 🔒 **防火牆優先的安全性**：UFW + Docker 隔離（僅開放 SSH + Tailscale）
- 🔐 **Tailscale VPN**：無需暴露公共服務即可安全遠端存取
- 🐳 **Docker**：隔離沙盒容器，僅綁定 localhost
- 🛡️ **深度防禦**：4 層安全架構
- 🚀 **一鍵設定**：數分鐘完成完整部署
- 🔧 **Systemd 整合**：開機自動啟動且已加固

## 需求

- **作業系統**：Debian 11+ 或 Ubuntu 20.04+
- **存取權限**：Root 或 sudo 權限
- **網路**：套件安裝所需之網際網路連線
- **Ansible**：2.14+（快速開始腳本會自動安裝）

## 安裝內容

Ansible Playbook 會安裝並設定：

1. **Tailscale**（網狀 VPN 用於安全遠端存取）
2. **UFW 防火牆**（SSH + Tailscale 連接埠僅限）
3. **Docker CE + Compose V2**（用於 Agent 沙盒）
4. **Node.js 22.x + pnpm**（執行期依賴）
5. **OpenClaw**（主機端執行，非容器化）
6. **Systemd 服務**（開機自動啟動且已加固）

注意：Gateway **直接執行於主機上**（非 Docker 內），但 Agent 沙盒使用 Docker 隔離。詳見 [沙盒隔離](/gateway/sandboxing)。

## 安裝後設定

安裝完成後，切換至 openclaw 使用者：

```bash
sudo -i -u openclaw
```

安裝後腳本將引導您完成：

1. **入門精靈**：配置 OpenClaw 設定
2. **供應商登入**：連接 WhatsApp/Telegram/Discord/Signal
3. **Gateway 測試**：驗證安裝
4. **Tailscale 設定**：連接至 VPN 網路

### 快速指令

```bash
# 檢查服務狀態
sudo systemctl status openclaw

# 查看即時日誌
sudo journalctl -u openclaw -f

# 重啟 Gateway
sudo systemctl restart openclaw

# 供應商登入（以 openclaw 使用者執行）
sudo -i -u openclaw
openclaw channels login
```

## 安全架構

### 4 層防禦

1. **防火牆 (UFW)**：僅對外暴露 SSH (22) + Tailscale (41641/udp)
2. **VPN (Tailscale)**：Gateway 僅可透過 VPN 網路存取
3. **Docker 隔離**：DOCKER-USER iptables 鏈防止外部連接埠暴露
4. **Systemd 加固**：NoNewPrivileges、PrivateTmp、無特權使用者

### 驗證

測試外部攻擊面：

```bash
nmap -p- YOUR_SERVER_IP
```

應僅顯示 **22 號連接埠**（SSH）開啟。所有其他服務（Gateway、Docker）皆已鎖定。

### Docker 可用性

Docker 安裝用於 **Agent 沙盒**（隔離工具執行），不用於執行 Gateway 本身。Gateway 僅綁定 localhost 並可透過 Tailscale VPN 存取。

詳見 [多代理沙盒與工具](/multi-agent-sandbox-tools) 瞭解沙盒設定。

## 手動安裝

如果您偏好手動控制自動化流程：

```bash
# 1. 安裝前置條件
sudo apt update && sudo apt install -y ansible git

# 2. 複製儲存庫
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible

# 3. 安裝 Ansible collections
ansible-galaxy collection install -r requirements.yml

# 4. 執行 Playbook
./run-playbook.sh

# 或直接執行（然後手動執行 /tmp/openclaw-setup.sh）
# ansible-playbook playbook.yml --ask-become-pass
```

## 更新 OpenClaw

Ansible 安裝工具設定 OpenClaw 供手動更新。詳見 [更新](/install/updating) 瞭解標準更新流程。

重新執行 Ansible Playbook（例如設定變更）：

```bash
cd openclaw-ansible
./run-playbook.sh
```

注意：此操作具冪等性且可安全地執行多次。

## 故障排除

### 防火牆阻止連接

如果您被鎖定：

- 先確保可透過 Tailscale VPN 存取
- SSH 存取（22 號連接埠）始終允許
- Gateway **僅**可透過 Tailscale 存取（設計如此）

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

### Docker 沙盒問題

```bash
# 驗證 Docker 執行中
sudo systemctl status docker

# 檢查沙盒映像
sudo docker images | grep openclaw-sandbox

# 如遺漏沙盒映像，請重建
cd /opt/openclaw/openclaw
sudo -u openclaw ./scripts/sandbox-setup.sh
```

### 供應商登入失敗

確保您以 `openclaw` 使用者執行：

```bash
sudo -i -u openclaw
openclaw channels login
```

## 進階設定

詳細的安全架構與故障排除：

- [Security Architecture](https://github.com/openclaw/openclaw-ansible/blob/main/docs/security.md)
- [Technical Details](https://github.com/openclaw/openclaw-ansible/blob/main/docs/architecture.md)
- [Troubleshooting Guide](https://github.com/openclaw/openclaw-ansible/blob/main/docs/troubleshooting.md)

## 相關

- [openclaw-ansible](https://github.com/openclaw/openclaw-ansible) — 完整部署指南
- [Docker](/install/docker) — 容器化 Gateway 設定
- [沙盒隔離](/gateway/sandboxing) — Agent 沙盒設定
- [多代理沙盒與工具](/multi-agent-sandbox-tools) — 每個代理隔離
