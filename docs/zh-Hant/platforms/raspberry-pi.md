---
summary: "Raspberry Pi 上的 OpenClaw（低預算自行託管設定）"
read_when:
  - 在 Raspberry Pi 上設定 OpenClaw
  - 在 ARM 裝置上執行 OpenClaw
  - 建立低成本的全天候個人 AI
title: "Raspberry Pi (Platform)"
---

# OpenClaw on Raspberry Pi

## 目標

在 Raspberry Pi 上運行持久、全天候的 OpenClaw Gateway，一次性費用約 **$35-80**（無月費）。

適合：

- 24/7 個人 AI 助理
- 家庭自動化中樞
- 低功耗、全天候可用的 Telegram/WhatsApp 機器人

## 硬體需求

| Pi 型號         | RAM     | 是否適用？ | 備註                     |
| --------------- | ------- | ---------- | ------------------------ |
| **Pi 5**        | 4GB/8GB | ✅ 最佳    | 最快，建議首選           |
| **Pi 4**        | 4GB     | ✅ 良好    | 大多數使用者的最佳選擇   |
| **Pi 4**        | 2GB     | ✅ 可用    | 可用，需加 swap          |
| **Pi 4**        | 1GB     | ⚠️ 較緊張  | 有 swap 可用，需最小設定 |
| **Pi 3B+**      | 1GB     | ⚠️ 較慢    | 可用但遲緩               |
| **Pi Zero 2 W** | 512MB   | ❌         | 不建議                   |

**最低規格：** 1GB RAM、1 核心、500MB 磁碟
**建議：** 2GB+ RAM、64 位元 OS、16GB+ SD 卡（或 USB SSD）

## 所需設備

- Raspberry Pi 4 或 5（建議 2GB+）
- MicroSD 卡（16GB+）或 USB SSD（效能更佳）
- 電源供應器（建議使用官方 Pi PSU）
- 網路連線（乙太網路或 WiFi）
- 約 30 分鐘

## 1) 燒錄 OS

使用 **Raspberry Pi OS Lite（64 位元）**——無頭伺服器不需要桌面環境。

1. 下載 [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. 選擇 OS：**Raspberry Pi OS Lite（64 位元）**
3. 點選齒輪圖示（⚙️）進行預設定：
   - 設定主機名稱：`gateway-host`
   - 啟用 SSH
   - 設定使用者名稱/密碼
   - 設定 WiFi（若不使用乙太網路）
4. 燒錄至 SD 卡／USB 磁碟
5. 插入並啟動 Pi

## 2) 透過 SSH 連線

```bash
ssh user@gateway-host
# 或使用 IP 位址
ssh user@192.168.x.x
```

## 3) 系統設定

```bash
# 更新系統
sudo apt update && sudo apt upgrade -y

# 安裝必要套件
sudo apt install -y git curl build-essential

# 設定時區（對 cron/提醒很重要）
sudo timedatectl set-timezone America/Chicago  # 換成你的時區
```

## 4) 安裝 Node.js 24（ARM64）

```bash
# 透過 NodeSource 安裝 Node.js
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

# 確認
node --version  # 應顯示 v24.x.x
npm --version
```

## 5) 新增 Swap（2GB 或以下必做）

Swap 可防止記憶體不足崩潰：

```bash
# 建立 2GB swap 檔案
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 使其永久生效
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 針對低 RAM 最佳化（降低 swappiness）
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## 6) 安裝 OpenClaw

### 選項 A：標準安裝（建議）

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

### 選項 B：可自訂安裝（供實驗用）

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install
npm run build
npm link
```

可自訂安裝提供對日誌和程式碼的直接存取，適合除錯 ARM 特定問題。

## 7) 執行引導設定

```bash
openclaw onboard --install-daemon
```

按照精靈操作：

1. **Gateway 模式：** Local
2. **驗證：** 建議 API 金鑰（OAuth 在無頭 Pi 上可能不穩定）
3. **頻道：** Telegram 最容易開始
4. **Daemon：** 是（systemd）

## 8) 確認安裝

```bash
# 確認狀態
openclaw status

# 確認服務
sudo systemctl status openclaw

# 查看日誌
journalctl -u openclaw -f
```

## 9) 存取 OpenClaw 控制台

將 `user@gateway-host` 替換成你的 Pi 使用者名稱與主機名稱或 IP 位址。

在你的電腦上，請 Pi 列印一個全新的控制台 URL：

```bash
ssh user@gateway-host 'openclaw dashboard --no-open'
```

指令會列印 `Dashboard URL:`。根據 `gateway.auth.token` 的設定方式，URL 可能是純粹的 `http://127.0.0.1:18789/` 連結，或包含 `#token=...` 的連結。

在你電腦的另一個終端機中，建立 SSH 通道：

```bash
ssh -N -L 18789:127.0.0.1:18789 user@gateway-host
```

然後在本機瀏覽器中開啟列印的控制台 URL。

若介面要求驗證，請將 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）中的 token 貼入 Control UI 設定。

如需全天候遠端存取，請參閱 [Tailscale](/zh-Hant/gateway/tailscale)。

---

## 效能最佳化

### 使用 USB SSD（大幅提升）

SD 卡速度慢且容易磨損。USB SSD 可大幅改善效能：

```bash
# 確認是否從 USB 啟動
lsblk
```

設定方式請見 [Pi USB 開機指南](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#usb-mass-storage-boot)。

### 加速 CLI 啟動（模組編譯快取）

在低功耗 Pi 主機上，啟用 Node 的模組編譯快取，讓重複的 CLI 執行更快：

```bash
grep -q 'NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache' ~/.bashrc || cat >> ~/.bashrc <<'EOF' # pragma: allowlist secret
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
EOF
source ~/.bashrc
```

備註：

- `NODE_COMPILE_CACHE` 加快後續執行（`status`、`health`、`--help`）。
- `/var/tmp` 比 `/tmp` 更能在重啟後存活。
- `OPENCLAW_NO_RESPAWN=1` 避免 CLI 自我重啟的額外啟動成本。
- 第一次執行暖機快取；之後的執行最能受益。

### systemd 啟動調校（選用）

若此 Pi 主要執行 OpenClaw，加入服務 drop-in 以減少重啟抖動並保持啟動環境穩定：

```bash
sudo systemctl edit openclaw
```

```ini
[Service]
Environment=OPENCLAW_NO_RESPAWN=1
Environment=NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
Restart=always
RestartSec=2
TimeoutStartSec=90
```

然後套用：

```bash
sudo systemctl daemon-reload
sudo systemctl restart openclaw
```

若可能，將 OpenClaw 狀態/快取保存在 SSD 支援的儲存空間，以避免冷啟動時的 SD 卡隨機 I/O 瓶頸。

`Restart=` 策略如何協助自動恢復：
[systemd 可以自動化服務恢復](https://www.redhat.com/en/blog/systemd-automate-recovery)。

### 減少記憶體使用

```bash
# 停用 GPU 記憶體配置（無頭）
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt

# 若不需要則停用藍牙
sudo systemctl disable bluetooth
```

### 監控資源

```bash
# 確認記憶體
free -h

# 確認 CPU 溫度
vcgencmd measure_temp

# 即時監控
htop
```

---

## ARM 特定注意事項

### 二進位相容性

大多數 OpenClaw 功能在 ARM64 上可用，但部分外部二進位檔可能需要 ARM 版本：

| 工具                | ARM64 狀態 | 備註                                |
| ------------------- | ---------- | ----------------------------------- |
| Node.js             | ✅         | 運作良好                            |
| WhatsApp（Baileys） | ✅         | 純 JS，無問題                       |
| Telegram            | ✅         | 純 JS，無問題                       |
| gog（Gmail CLI）    | ⚠️         | 請確認是否有 ARM 版本               |
| Chromium（瀏覽器）  | ✅         | `sudo apt install chromium-browser` |

若某個 skill 失敗，請確認其二進位檔是否有 ARM 版本。許多 Go/Rust 工具有；部分沒有。

### 32 位元 vs 64 位元

**務必使用 64 位元 OS。** Node.js 和許多現代工具都需要它。確認方式：

```bash
uname -m
# 應顯示：aarch64（64 位元）而非 armv7l（32 位元）
```

---

## 建議的模型設定

由於 Pi 只是 Gateway（模型在雲端執行），請使用 API 模型：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-20250514",
        "fallbacks": ["openai/gpt-4o-mini"]
      }
    }
  }
}
```

**不要嘗試在 Pi 上執行本地 LLM**——即使是小型模型也太慢。讓 Claude/GPT 負責繁重的工作。

---

## 開機時自動啟動

引導設定精靈會設定此項，但若要驗證：

```bash
# 確認服務是否已啟用
sudo systemctl is-enabled openclaw

# 若未啟用
sudo systemctl enable openclaw

# 開機時啟動
sudo systemctl start openclaw
```

---

## 疑難排解

### 記憶體不足（OOM）

```bash
# 確認記憶體
free -h

# 新增更多 swap（見步驟 5）
# 或減少 Pi 上執行的服務
```

### 效能緩慢

- 使用 USB SSD 取代 SD 卡
- 停用未使用的服務：`sudo systemctl disable cups bluetooth avahi-daemon`
- 確認 CPU 節流：`vcgencmd get_throttled`（應回傳 `0x0`）

### 服務無法啟動

```bash
# 查看日誌
journalctl -u openclaw --no-pager -n 100

# 常見修復：重新建置
cd ~/openclaw  # 若使用可自訂安裝
npm run build
sudo systemctl restart openclaw
```

### ARM 二進位檔問題

若某個 skill 以「exec format error」失敗：

1. 確認二進位檔是否有 ARM64 版本
2. 嘗試從原始碼建置
3. 或使用支援 ARM 的 Docker 容器

### WiFi 中斷

無頭 Pi 使用 WiFi 時：

```bash
# 停用 WiFi 電源管理
sudo iwconfig wlan0 power off

# 使其永久生效
echo 'wireless-power off' | sudo tee -a /etc/network/interfaces
```

---

## 成本比較

| 設定            | 一次性費用 | 月費     | 備註                 |
| --------------- | ---------- | -------- | -------------------- |
| **Pi 4（2GB）** | ~$45       | $0       | + 電費（~$5/年）     |
| **Pi 4（4GB）** | ~$55       | $0       | 建議                 |
| **Pi 5（4GB）** | ~$60       | $0       | 最佳效能             |
| **Pi 5（8GB）** | ~$80       | $0       | 過規格但具未來擴展性 |
| DigitalOcean    | $0         | $6/月    | $72/年               |
| Hetzner         | $0         | €3.79/月 | 約 $50/年            |

**損益平衡：** Pi 與雲端 VPS 相比約 6-12 個月回本。

---

## 參閱

- [Linux 指南](/zh-Hant/platforms/linux) — 一般 Linux 設定
- [DigitalOcean 指南](/zh-Hant/platforms/digitalocean) — 雲端替代方案
- [Hetzner 指南](/zh-Hant/install/hetzner) — Docker 設定
- [Tailscale](/zh-Hant/gateway/tailscale) — 遠端存取
- [Nodes](/zh-Hant/nodes) — 將你的筆記型電腦/手機與 Pi gateway 配對
