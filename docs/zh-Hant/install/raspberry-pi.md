---
summary: "在 Raspberry Pi 上託管 OpenClaw 以實現始終開啟的自我託管"
read_when:
  - 在 Raspberry Pi 上設定 OpenClaw
  - 在 ARM 裝置上執行 OpenClaw
  - 建置廉價的始終開啟的個人 AI
title: "Raspberry Pi（Raspberry Pi）"
---

# Raspberry Pi

在 Raspberry Pi 上執行持久、始終開啟的 OpenClaw Gateway。由於 Pi 只是 gateway（模型通過 API 在雲端執行），即使是適度的 Pi 也可以處理工作負載。

## 必要條件

- Raspberry Pi 4 或 5，配有 2 GB+ RAM（推薦 4 GB）
- MicroSD 卡（16 GB+）或 USB SSD（更好的效能）
- 官方 Pi 電源供應
- 網路連線（乙太網路或 WiFi）
- 64 位 Raspberry Pi OS（必需 -- 不要使用 32 位）
- 約 30 分鐘

## 設定

<Steps>
  <Step title="刷新 OS">
    使用 **Raspberry Pi OS Lite (64-bit)** -- 頭部伺服器不需要桌面。

    1. 下載 [Raspberry Pi Imager](https://www.raspberrypi.com/software/)。
    2. 選擇 OS：**Raspberry Pi OS Lite (64-bit)**。
    3. 在設定對話方塊中，預先配置：
       - 主機名稱：`gateway-host`
       - 啟用 SSH
       - 設定使用者名稱和密碼
       - 配置 WiFi（若未使用乙太網路）
    4. 刷新到 SD 卡或 USB 磁碟機、插入它，並啟動 Pi。

  </Step>

  <Step title="通過 SSH 連線">
    ```bash
    ssh user@gateway-host
    ```
  </Step>

  <Step title="更新系統">
    ```bash
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git curl build-essential

    # 設定時區（對 cron 和提醒很重要）
    sudo timedatectl set-timezone America/Chicago
    ```

  </Step>

  <Step title="安裝 Node.js 24">
    ```bash
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt install -y nodejs
    node --version
    ```
  </Step>

  <Step title="新增 swap（2 GB 或更少時很重要）">
    ```bash
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    # 為低 RAM 裝置降低 swappiness
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    ```

  </Step>

  <Step title="安裝 OpenClaw">
    ```bash
    curl -fsSL https://openclaw.ai/install.sh | bash
    ```
  </Step>

  <Step title="執行上線">
    ```bash
    openclaw onboard --install-daemon
    ```

    遵循嚮導。API 金鑰對頭部裝置來說優於 OAuth。Telegram 是最簡單的頻道。

  </Step>

  <Step title="驗證">
    ```bash
    openclaw status
    sudo systemctl status openclaw
    journalctl -u openclaw -f
    ```
  </Step>

  <Step title="存取控制 UI">
    在你的電腦上，從 Pi 取得儀表板 URL：

    ```bash
    ssh user@gateway-host 'openclaw dashboard --no-open'
    ```

    然後在另一個終端機中建立 SSH 通道：

    ```bash
    ssh -N -L 18789:127.0.0.1:18789 user@gateway-host
    ```

    在本機瀏覽器中開啟列印的 URL。如需始終開啟的遠端存取，詳見 [Tailscale 整合](/zh-Hant/gateway/tailscale)。

  </Step>
</Steps>

## 效能提示

**使用 USB SSD** -- SD 卡很慢且容易磨損。USB SSD 可大幅改善效能。詳見 [Pi USB 啟動指南](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#usb-mass-storage-boot)。

**啟用模組編譯快取** -- 在低功率 Pi 主機上加速重複 CLI 呼叫：

```bash
grep -q 'NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache' ~/.bashrc || cat >> ~/.bashrc <<'EOF' # pragma: allowlist secret
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
EOF
source ~/.bashrc
```

**降低記憶體使用量** -- 對於頭部設定，釋放 GPU 記憶體並停用未使用的服務：

```bash
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt
sudo systemctl disable bluetooth
```

## 故障排除

**記憶體不足** -- 使用 `free -h` 驗證 swap 是否啟用。停用未使用的服務（`sudo systemctl disable cups bluetooth avahi-daemon`）。僅使用基於 API 的模型。

**效能緩慢** -- 使用 USB SSD 而不是 SD 卡。使用 `vcgencmd get_throttled` 檢查 CPU 節流（應傳回 `0x0`）。

**服務無法啟動** -- 使用 `journalctl -u openclaw --no-pager -n 100` 檢查日誌並執行 `openclaw doctor --non-interactive`。

**ARM 二進位問題** -- 如果技能失敗並出現「exec format error」，檢查二進位檔案是否有 ARM64 建置。使用 `uname -m` 驗證架構（應顯示 `aarch64`）。

**WiFi 掉線** -- 停用 WiFi 電源管理：`sudo iwconfig wlan0 power off`。

## 後續步驟

- [頻道](/zh-Hant/channels) -- 連接 Telegram、WhatsApp、Discord 等
- [Gateway 配置](/zh-Hant/gateway/configuration) -- 所有配置選項
- [更新](/zh-Hant/install/updating) -- 保持 OpenClaw 最新
