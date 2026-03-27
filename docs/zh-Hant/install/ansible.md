---
summary: "使用 Ansible、Tailscale VPN 和防火牆隔離進行自動化、強化的 OpenClaw 安裝"
read_when:
  - 你需要自動化的伺服器部署並加強安全性
  - 你需要防火牆隔離設定與 VPN 存取
  - 你部署到遠端 Debian/Ubuntu 伺服器
title: "Ansible"
---

# Ansible 安裝

使用 **[openclaw-ansible](https://github.com/openclaw/openclaw-ansible)** 將 OpenClaw 部署到生產伺服器──這是一個具有安全優先架構的自動化安裝程式。

<Info>
[openclaw-ansible](https://github.com/openclaw/openclaw-ansible) 倉庫是 Ansible 部署的真實來源。本頁面只是快速概述。
</Info>

## 必要條件

| 需求         | 詳細資訊                        |
| ------------ | ------------------------------- |
| **作業系統** | Debian 11+ 或 Ubuntu 20.04+     |
| **存取權限** | Root 或 sudo 權限               |
| **網路**     | 用於套件安裝的網際網路連線      |
| **Ansible**  | 2.14+（快速啟動腳本會自動安裝） |

## 你將獲得

- **防火牆優先安全性**──UFW + Docker 隔離（只有 SSH + Tailscale 可存取）
- **Tailscale VPN**──安全的遠端存取，無需公開暴露服務
- **Docker**──隔離的沙箱容器，localhost 專用繫結
- **深度防禦**──4 層安全架構
- **Systemd 整合**──開機自動啟動並加強安全性
- **一鍵設定**──完整部署只需幾分鐘

## 快速開始

一鍵安裝：

```bash
curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw-ansible/main/install.sh | bash
```

## 將安裝的內容

Ansible 劇本會安裝和配置：

1. **Tailscale**──用於安全遠端存取的網格 VPN
2. **UFW 防火牆**──只開放 SSH + Tailscale 埠
3. **Docker CE + Compose V2**──用於代理沙箱
4. **Node.js 24 + pnpm**──執行時期相依性（Node 22 LTS，目前 `22.16+`，仍然支援）
5. **OpenClaw**──基於主機，非容器化
6. **Systemd 服務**──開機自動啟動並加強安全性

<Note>
Gateway 直接在主機上執行（不在 Docker 中），但代理沙箱使用 Docker 進行隔離。詳見 [沙箱](/zh-Hant/gateway/sandboxing)。
</Note>

## 安裝後設定

<Steps>
  <Step title="切換到 openclaw 使用者">
    ```bash
    sudo -i -u openclaw
    ```
  </Step>
  <Step title="執行上線嚮導">
    安裝後腳本會指導你配置 OpenClaw 設定。
  </Step>
  <Step title="連線訊息傳遞提供者">
    登入 WhatsApp、Telegram、Discord 或 Signal：
    ```bash
    openclaw channels login
    ```
  </Step>
  <Step title="驗證安裝">
    ```bash
    sudo systemctl status openclaw
    sudo journalctl -u openclaw -f
    ```
  </Step>
  <Step title="連線到 Tailscale">
    加入你的 VPN 網格以進行安全遠端存取。
  </Step>
</Steps>

### 快速命令

```bash
# 檢查服務狀態
sudo systemctl status openclaw

# 查看即時日誌
sudo journalctl -u openclaw -f

# 重啟 gateway
sudo systemctl restart openclaw

# 提供者登入（以 openclaw 使用者執行）
sudo -i -u openclaw
openclaw channels login
```

## 安全架構

部署使用 4 層防禦模型：

1. **防火牆 (UFW)**──只有 SSH (22) + Tailscale (41641/udp) 公開暴露
2. **VPN (Tailscale)**──gateway 只能通過 VPN 網格存取
3. **Docker 隔離**──DOCKER-USER iptables 鏈防止外部埠暴露
4. **Systemd 強化**──NoNewPrivileges、PrivateTmp、無權限使用者

驗證你的外部攻擊面：

```bash
nmap -p- YOUR_SERVER_IP
```

只有埠 22 (SSH) 應該開放。所有其他服務（gateway、Docker）都被鎖定。

Docker 為代理沙箱安裝（隔離的工具執行），不是用來執行 gateway 本身。詳見 [多代理沙箱和工具](/zh-Hant/tools/multi-agent-sandbox-tools)。

## 手動安裝

如果你喜歡手動控制自動化：

<Steps>
  <Step title="安裝必要條件">
    ```bash
    sudo apt update && sudo apt install -y ansible git
    ```
  </Step>
  <Step title="複製倉庫">
    ```bash
    git clone https://github.com/openclaw/openclaw-ansible.git
    cd openclaw-ansible
    ```
  </Step>
  <Step title="安裝 Ansible 集合">
    ```bash
    ansible-galaxy collection install -r requirements.yml
    ```
  </Step>
  <Step title="執行劇本">
    ```bash
    ./run-playbook.sh
    ```

    或者，直接執行，然後在之後手動執行設定腳本：
    ```bash
    ansible-playbook playbook.yml --ask-become-pass
    # 然後執行: /tmp/openclaw-setup.sh
    ```

  </Step>
</Steps>

## 更新

Ansible 安裝程式會設定 OpenClaw 進行手動更新。詳見 [更新](/zh-Hant/install/updating)。

重新執行 Ansible 劇本（例如，進行配置變更）：

```bash
cd openclaw-ansible
./run-playbook.sh
```

這是冪等的，可以安全地執行多次。

## 故障排除

<AccordionGroup>
  <Accordion title="防火牆阻止了我的連線">
    - 首先確保你能通過 Tailscale VPN 存取
    - SSH 存取（埠 22）始終允許
    - Gateway 由設計只能通過 Tailscale 存取
  </Accordion>
  <Accordion title="服務無法啟動">
    ```bash
    # 檢查日誌
    sudo journalctl -u openclaw -n 100

    # 驗證權限
    sudo ls -la /opt/openclaw

    # 測試手動啟動
    sudo -i -u openclaw
    cd ~/openclaw
    openclaw gateway run
    ```

  </Accordion>
  <Accordion title="Docker 沙箱問題">
    ```bash
    # 驗證 Docker 正在執行
    sudo systemctl status docker

    # 檢查沙箱映像
    sudo docker images | grep openclaw-sandbox

    # 如果遺失，建立沙箱映像
    cd /opt/openclaw/openclaw
    sudo -u openclaw ./scripts/sandbox-setup.sh
    ```

  </Accordion>
  <Accordion title="提供者登入失敗">
    確保你以 `openclaw` 使用者執行：
    ```bash
    sudo -i -u openclaw
    openclaw channels login
    ```
  </Accordion>
</AccordionGroup>

## 進階配置

如需詳細安全架構與故障排查：

- [安全架構](https://github.com/openclaw/openclaw-ansible/blob/main/docs/security.md)
- [技術細節](https://github.com/openclaw/openclaw-ansible/blob/main/docs/architecture.md)
- [故障排查指南](https://github.com/openclaw/openclaw-ansible/blob/main/docs/troubleshooting.md)

## 相關

- [openclaw-ansible](https://github.com/openclaw/openclaw-ansible)──完整部署指南
- [Docker](/zh-Hant/install/docker)──容器化 gateway 設定
- [沙箱](/zh-Hant/gateway/sandboxing)──代理沙箱配置
- [多代理沙箱和工具](/zh-Hant/tools/multi-agent-sandbox-tools)──個別代理隔離
