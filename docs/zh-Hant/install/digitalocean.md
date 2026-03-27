---
summary: "在 DigitalOcean Droplet 上託管 OpenClaw"
read_when:
  - 在 DigitalOcean 上設定 OpenClaw
  - 尋找用於 OpenClaw 的簡單付費 VPS
title: "DigitalOcean"
---

# DigitalOcean

在 DigitalOcean Droplet 上執行持久的 OpenClaw Gateway。

## 必要條件

- DigitalOcean 帳戶（[註冊](https://cloud.digitalocean.com/registrations/new)）
- SSH 金鑰組（或願意使用密碼認證）
- 約 20 分鐘

## 設定

<Steps>
  <Step title="建立 Droplet">
    <Warning>
    使用乾淨的基礎映像（Ubuntu 24.04 LTS）。避免第三方 Marketplace 1-click 映像，除非你已審查其啟動腳本和防火牆預設值。
    </Warning>

    1. 登入 [DigitalOcean](https://cloud.digitalocean.com/)。
    2. 點擊 **Create > Droplets**。
    3. 選擇：
       - **區域：** 距離你最近的
       - **映像：** Ubuntu 24.04 LTS
       - **大小：** Basic、Regular、1 vCPU / 1 GB RAM / 25 GB SSD
       - **驗證：** SSH 金鑰（推薦）或密碼
    4. 點擊 **Create Droplet** 並記下 IP 位址。

  </Step>

  <Step title="連線和安裝">
    ```bash
    ssh root@YOUR_DROPLET_IP

    apt update && apt upgrade -y

    # 安裝 Node.js 24
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt install -y nodejs

    # 安裝 OpenClaw
    curl -fsSL https://openclaw.ai/install.sh | bash
    openclaw --version
    ```

  </Step>

  <Step title="執行上線">
    ```bash
    openclaw onboard --install-daemon
    ```

    嚮導會引導你完成模型認證、頻道設定、gateway 令牌生成和守護程式安裝 (systemd)。

  </Step>

  <Step title="新增 swap（推薦用於 1 GB Droplet）">
    ```bash
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    ```
  </Step>

  <Step title="驗證 gateway">
    ```bash
    openclaw status
    systemctl --user status openclaw-gateway.service
    journalctl --user -u openclaw-gateway.service -f
    ```
  </Step>

  <Step title="存取控制 UI">
    gateway 預設繫結到 loopback。選擇下列其中一個選項。

    **選項 A：SSH 通道（最簡單）**

    ```bash
    # 從你的本機
    ssh -L 18789:localhost:18789 root@YOUR_DROPLET_IP
    ```

    然後開啟 `http://localhost:18789`。

    **選項 B：Tailscale Serve**

    ```bash
    curl -fsSL https://tailscale.com/install.sh | sh
    tailscale up
    openclaw config set gateway.tailscale.mode serve
    openclaw gateway restart
    ```

    然後從 tailnet 上的任何裝置開啟 `https://<magicdns>/`。

    **選項 C：Tailnet 繫結（無 Serve）**

    ```bash
    openclaw config set gateway.bind tailnet
    openclaw gateway restart
    ```

    然後開啟 `http://<tailscale-ip>:18789`（需要令牌）。

  </Step>
</Steps>

## 故障排除

**Gateway 無法啟動** -- 執行 `openclaw doctor --non-interactive` 並使用 `journalctl --user -u openclaw-gateway.service -n 50` 檢查日誌。

**埠已在使用中** -- 執行 `lsof -i :18789` 尋找流程，然後停止它。

**記憶體不足** -- 使用 `free -h` 驗證 swap 是否啟用。如果仍然遇到 OOM，請使用基於 API 的模型（Claude、GPT），而不是本機模型，或升級到 2 GB Droplet。

## 後續步驟

- [頻道](/zh-Hant/channels) -- 連接 Telegram、WhatsApp、Discord 等
- [Gateway 配置](/zh-Hant/gateway/configuration) -- 所有配置選項
- [更新](/zh-Hant/install/updating) -- 保持 OpenClaw 最新
