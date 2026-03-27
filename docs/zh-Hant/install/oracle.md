---
summary: "在 Oracle Cloud 的免費 ARM 層上託管 OpenClaw"
read_when:
  - 在 Oracle Cloud 上設定 OpenClaw
  - 尋找免費的 VPS 託管用於 OpenClaw
  - 想要 24/7 OpenClaw 在小型伺服器上
title: "Oracle Cloud（Oracle Cloud）"
---

# Oracle Cloud

在 Oracle Cloud 的 **Always Free** ARM 層上執行持久的 OpenClaw Gateway（最多 4 OCPU、24 GB RAM、200 GB 儲存空間），完全免費。

## 必要條件

- Oracle Cloud 帳戶（[註冊](https://www.oracle.com/cloud/free/)）-- 若遇到問題，詳見[社群註冊指南](https://gist.github.com/rssnyder/51e3cfedd730e7dd5f4a816143b25dbd)
- Tailscale 帳戶（免費於 [tailscale.com](https://tailscale.com)）
- SSH 金鑰組
- 約 30 分鐘

## 設定

<Steps>
  <Step title="建立 OCI 執行個體">
    1. 登入 [Oracle Cloud Console](https://cloud.oracle.com/)。
    2. 導覽到 **Compute > Instances > Create Instance**。
    3. 配置：
       - **名稱：** `openclaw`
       - **映像：** Ubuntu 24.04 (aarch64)
       - **Shape：** `VM.Standard.A1.Flex` (Ampere ARM)
       - **OCPU：** 2（或最多 4 個）
       - **記憶體：** 12 GB（或最多 24 GB）
       - **啟動卷：** 50 GB（最多 200 GB 免費）
       - **SSH 金鑰：** 新增你的公開金鑰
    4. 點擊 **Create** 並記下公開 IP 位址。

    <Tip>
    如果執行個體建立失敗，出現「Out of capacity」，請嘗試不同的可用性網域或稍後重試。免費層容量受限。
    </Tip>

  </Step>

  <Step title="連線和更新系統">
    ```bash
    ssh ubuntu@YOUR_PUBLIC_IP

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y build-essential
    ```

    `build-essential` 是某些相依性的 ARM 編譯所必需的。

  </Step>

  <Step title="配置使用者和主機名稱">
    ```bash
    sudo hostnamectl set-hostname openclaw
    sudo passwd ubuntu
    sudo loginctl enable-linger ubuntu
    ```

    啟用 linger 會使使用者服務在登出後繼續執行。

  </Step>

  <Step title="安裝 Tailscale">
    ```bash
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up --ssh --hostname=openclaw
    ```

    從現在開始，通過 Tailscale 連線：`ssh ubuntu@openclaw`。

  </Step>

  <Step title="安裝 OpenClaw">
    ```bash
    curl -fsSL https://openclaw.ai/install.sh | bash
    source ~/.bashrc
    ```

    當提示「How do you want to hatch your bot?」時，選擇 **Do this later**。

  </Step>

  <Step title="配置 gateway">
    使用令牌認證搭配 Tailscale Serve 進行安全遠端存取。

    ```bash
    openclaw config set gateway.bind loopback
    openclaw config set gateway.auth.mode token
    openclaw doctor --generate-gateway-token
    openclaw config set gateway.tailscale.mode serve
    openclaw config set gateway.trustedProxies '["127.0.0.1"]'

    systemctl --user restart openclaw-gateway
    ```

  </Step>

  <Step title="鎖定 VCN 安全性">
    阻止除 Tailscale 外的所有流量在網路邊緣：

    1. 在 OCI Console 中進入 **Networking > Virtual Cloud Networks**。
    2. 點擊你的 VCN，然後 **Security Lists > Default Security List**。
    3. **移除** 除 `0.0.0.0/0 UDP 41641`（Tailscale）外的所有傳入規則。
    4. 保持預設傳出規則（允許所有傳出）。

    這會在網路邊緣阻止埠 22 上的 SSH、HTTP、HTTPS 和其他所有內容。從此時起，你只能通過 Tailscale 連線。

  </Step>

  <Step title="驗證">
    ```bash
    openclaw --version
    systemctl --user status openclaw-gateway
    tailscale serve status
    curl http://localhost:18789
    ```

    從 tailnet 上的任何裝置存取控制 UI：

    ```
    https://openclaw.<tailnet-name>.ts.net/
    ```

    用你的 tailnet 名稱取代 `<tailnet-name>`（在 `tailscale status` 中可見）。

  </Step>
</Steps>

## 備用方案：SSH 通道

如果 Tailscale Serve 無法運作，請從本機使用 SSH 通道：

```bash
ssh -L 18789:127.0.0.1:18789 ubuntu@openclaw
```

然後開啟 `http://localhost:18789`。

## 故障排除

**執行個體建立失敗（「Out of capacity」）** -- 免費層 ARM 執行個體很受歡迎。嘗試不同的可用性網域或在非尖峰時段重試。

**Tailscale 無法連線** -- 執行 `sudo tailscale up --ssh --hostname=openclaw --reset` 以重新認證。

**Gateway 無法啟動** -- 執行 `openclaw doctor --non-interactive` 並用 `journalctl --user -u openclaw-gateway -n 50` 檢查日誌。

**ARM 二進位問題** -- 大多數 npm 套件可在 ARM64 上運作。對於原生二進位檔案，尋找 `linux-arm64` 或 `aarch64` 版本。用 `uname -m` 驗證架構。

## 後續步驟

- [頻道](/zh-Hant/channels) -- 連接 Telegram、WhatsApp、Discord 等
- [Gateway 配置](/zh-Hant/gateway/configuration) -- 所有配置選項
- [更新](/zh-Hant/install/updating) -- 保持 OpenClaw 最新
