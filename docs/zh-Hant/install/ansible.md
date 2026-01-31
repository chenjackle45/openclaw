---
title: "Ansible(Ansible 安裝指南)"
summary: "透過 Ansible、Tailscale VPN 與防火牆隔離進行自動化且加固的 OpenClaw 安裝"
read_when:
  - 您想要進行具備安全加固的自動化伺服器部署時
  - 您需要透過 VPN 存取的防火牆隔離環境時
  - 您正在將 OpenClaw 部署至遠端 Debian/Ubuntu 伺服器時
---

# Ansible 安裝指南

將 OpenClaw 部署至生產伺服器的推薦方式是透過 **[openclaw-ansible](https://github.com/openclaw/openclaw-ansible)** —— 這是一個具備「安全優先」架構的自動化安裝工具。

## 快速開始

一鍵安裝指令：

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw-ansible/main/install.sh | bash
```

> **📦 完整指南：[github.com/openclaw/openclaw-ansible](https://github.com/openclaw/openclaw-ansible)**
>
> `openclaw-ansible` 儲存庫是 Ansible 部署的最終權威來源。本頁僅提供簡要總覽。

## 使用 Ansible 的優勢

- 🔒 **防火牆優先的安全機制**：UFW + Docker 隔離（僅開放 SSH 與 Tailscale 存取）。
- 🔐 **Tailscale VPN**：無需將服務暴露於公網即可進行安全遠端存取。
- 🐳 **Docker**：隔離的 Agent 沙盒容器，僅綁定於本地回環地址 (localhost)。
- 🛡️ **深度防禦**：具備 4 層安全架構。
- 🚀 **一鍵設定**：數分鐘內完成完整部署。
- 🔧 **Systemd 整合**：支援開機自動啟動並進行權限限制。

## 系統需求

- **作業系統**：Debian 11+ 或 Ubuntu 20.04+。
- **存取權限**：Root 或 sudo 權限。
- **網路**：需具備網路連線以安裝套件。
- **Ansible**：2.14+ (安裝腳本會自動協助安裝)。

## 安裝內容

Ansible Playbook 會安裝並設定以下組件：
1. **Tailscale**（網狀 VPN，用於安全遠端存取）。
2. **UFW 防火牆**（僅開放 SSH 與 Tailscale 連接埠）。
3. **Docker CE + Compose V2**（用於 Agent 沙盒隔離）。
4. **Node.js 22.x + pnpm**（執行期依賴）。
5. **OpenClaw**（執行於主機端，非容器化）。
6. **Systemd 服務**（自動啟動並具備安全加固）。

注意：Gateway **直接執行於主機上**（而非 Docker 內），但 Agent 的工具執行則是利用 Docker 達成隔離。詳見 [沙盒隔離](/gateway/sandboxing)。

## 安裝後設定

完成安裝後，請切換至 `openclaw` 使用者：

```bash
sudo -i -u openclaw
```

安裝後腳本將引導您完成：
1. **入門精靈**：配置 OpenClaw 設定。
2. **供應商登入**：連接 WhatsApp/Telegram/Discord/Signal 等。
3. **Gateway 測試**：驗證安裝結果。
4. **Tailscale 設定**：連接至您的 VPN 網路。

### 常用指令

```bash
# 檢查服務狀態
sudo systemctl status openclaw

# 查看即時日誌
sudo journalctl -u openclaw -f

# 重啟 Gateway
sudo systemctl restart openclaw

# 供應商登入 (需以 openclaw 使用者執行)
sudo -i -u openclaw
openclaw channels login
```

## 安全架構

### 4 層防禦
1. **防火牆 (UFW)**：僅對公網暴露 SSH (22) 與 Tailscale (41641/udp)。
2. **VPN (Tailscale)**：僅能透過 VPN 網路存取 Gateway。
3. **Docker 隔離**：透過 iptables 鏈防止外部存取 Docker 內部的連接埠。
4. **Systemd 加固**：使用 NoNewPrivileges、PrivateTmp 且以非特權使用者執行。

### 驗證安全
測試外部攻擊面：`nmap -p- 您的伺服器IP`
應僅顯示 **22 號連接埠** (SSH) 為開啟狀態。所有其他服務（Gateway, Docker）皆已被鎖定。
