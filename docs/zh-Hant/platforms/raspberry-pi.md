---
title: "raspberry-pi(Raspberry Pi)"
summary: "在 Raspberry Pi 上執行 OpenClaw (經濟實惠的自託管方案)"
read_when:
  - 在 Raspberry Pi 上設定 OpenClaw 時
  - 在 ARM 裝置上執行 OpenClaw 時
  - 打造廉價的全天候個人 AI 時
---

# OpenClaw on Raspberry Pi

## 目標

以 **~$35-80 美金** 的一次性成本（無月費），在 Raspberry Pi 上執行持久、全天候運行的 OpenClaw Gateway。

適合：
- 24/7 個人 AI 助理
- 家庭自動化中心
- 低功耗、永遠在線的 Telegram/WhatsApp 機器人

## 硬體需求

| Pi 型號 | RAM | 可行性 | 備註 |
|----------|-----|--------|-------|
| **Pi 5** | 4GB/8GB | ✅ 最佳 | 速度最快，推薦 |
| **Pi 4** | 4GB | ✅ 良好 | 大多數使用者的甜蜜點 |
| **Pi 4** | 2GB | ✅ OK | 可行，需增加 Swap |
| **Pi 4** | 1GB | ⚠️ 緊繃 | 配合 Swap 可行，需最小化設定 |
| **Pi 3B+** | 1GB | ⚠️ 緩慢 | 可運作但反應遲鈍 |
| **Pi Zero 2 W** | 512MB | ❌ | 不推薦 |

**最低規格:** 1GB RAM, 1 核心, 500MB 磁碟  
**推薦規格:** 2GB+ RAM, 64-bit OS, 16GB+ SD 卡 (或 USB SSD)

## 您需要準備

- Raspberry Pi 4 或 5 (推薦 2GB+)
- MicroSD 卡 (16GB+) 或 USB SSD (效能較佳)
- 電源供應器 (推薦官方 Pi PSU)
- 網路連線 (Ethernet 或 WiFi)
- 約 30 分鐘時間

## 1) 燒錄 OS

使用 **Raspberry Pi OS Lite (64-bit)** — 無頭伺服器不需要桌面環境。

1. 下載 [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. 選擇 OS: **Raspberry Pi OS Lite (64-bit)**
3. 點擊齒輪圖示 (⚙️) 預先設定：
   - 設定主機名稱: `gateway-host`
   - 啟用 SSH
   - 設定使用者名稱/密碼
   - 設定 WiFi (若不使用 Ethernet)
4. 燒錄至您的 SD 卡 / USB 隨身碟
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

# 設定時區 (對 cron/提醒很重要)
sudo timedatectl set-timezone Asia/Taipei  # 請改為您的時區
```

## 4) 安裝 Node.js 22 (ARM64)

```bash
# 透過 NodeSource 安裝 Node.js
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# 驗證
node --version  # 應顯示 v22.x.x
npm --version
```

## 5) 新增 Swap (2GB 或更少記憶體者重要)

Swap 可防止記憶體不足 (OOM) 崩潰：

```bash
# 建立 2GB Swap 檔案
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 設定永久生效
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 優化低記憶體 (降低 swappiness)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## 6) 安裝 OpenClaw

### 選項 A: 標準安裝 (推薦)

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

### 選項 B: 可駭客安裝 (適合想自行修改者)

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install
npm run build
npm link
```

可駭客安裝讓您直接存取日誌與程式碼 — 對於除錯 ARM 特定問題很有用。

## 7) 執行 Onboarding

```bash
openclaw onboard --install-daemon
```

依照精靈操作：
1. **Gateway mode:** Local
2. **Auth:** 推薦使用 API Keys (OAuth 在無頭 Pi 上可能較麻煩)
3. **Channels:** Telegram 最容易上手
4. **Daemon:** Yes (systemd)

## 8) 驗證安裝

```bash
# 檢查狀態
openclaw status

# 檢查服務
sudo systemctl status openclaw

# 查看日誌
journalctl -u openclaw -f
```

## 9) 存取儀表板 (Dashboard)

由於 Pi 是無頭的 (headless)，使用 SSH 通道：

```bash
# 從您的筆電/桌機
ssh -L 18789:localhost:18789 user@gateway-host

# 然後在瀏覽器開啟
open http://localhost:18789
```

或使用 Tailscale 進行全天候存取：

```bash
# 在 Pi 上
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# 更新設定
openclaw config set gateway.bind tailnet
sudo systemctl restart openclaw
```

---

## 效能優化

### 使用 USB SSD (顯著提升)

SD 卡速度慢且容易損壞。USB SSD 可顯著提升效能：

```bash
# 檢查是否從 USB 啟動
lsblk
```

設定請參閱 [Pi USB boot guide](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#usb-mass-storage-boot)。

### 減少記憶體使用

```bash
# 停用 GPU 記憶體分配 (headless)
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt

# 若不需要則停用藍牙
sudo systemctl disable bluetooth
```

### 監控資源

```bash
# 檢查記憶體
free -h

# 檢查 CPU 溫度
vcgencmd measure_temp

# 即時監控
htop
```

---

## ARM 特定注意事項

### 二進位檔相容性

大多數 OpenClaw 功能在 ARM64 上運作良好，但部分外部二進位檔可能需要 ARM 版本：

| 工具 | ARM64 狀態 | 備註 |
|------|--------------|-------|
| Node.js | ✅ | 運作良好 |
| WhatsApp (Baileys) | ✅ | 純 JS，無問題 |
| Telegram | ✅ | 純 JS，無問題 |
| gog (Gmail CLI) | ⚠️ | 檢查是否有 ARM Release |
| Chromium (browser) | ✅ | `sudo apt install chromium-browser` |

若某個 Skill 失敗，檢查其二進位檔是否有 ARM 建置。許多 Go/Rust 工具都有；有些則無。

### 32-bit vs 64-bit

**務必使用 64-bit OS。** Node.js 與許多現代工具都需要它。檢查方式：

```bash
uname -m
# 應顯示: aarch64 (64-bit) 而非 armv7l (32-bit)
```

---

## 推薦模型設定

由於 Pi 只是 Gateway（模型在雲端運行），請使用基於 API 的模型：

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

**不要嘗試在 Pi 上運行本地 LLM** — 即使是小模型也太慢。讓 Claude/GPT 處理繁重工作。

---

## 開機自動啟動

Onboarding 精靈會設定此項，但可透過以下方式驗證：

```bash
# 檢查服務是否啟用
sudo systemctl is-enabled openclaw

# 若未啟用則啟用
sudo systemctl enable openclaw

# 啟動服務
sudo systemctl start openclaw
```

---

## 故障排除

### 記憶體不足 (OOM)

```bash
# 檢查記憶體
free -h

# 增加更多 Swap (見步驟 5)
# 或減少 Pi 上運行的服務
```

### 效能緩慢

- 使用 USB SSD 代替 SD 卡
- 停用未使用的服務：`sudo systemctl disable cups bluetooth avahi-daemon`
- 檢查 CPU 降頻：`vcgencmd get_throttled` (應回傳 `0x0`)

### 服務無法啟動

```bash
# 檢查日誌
journalctl -u openclaw --no-pager -n 100

# 常見修復：重新建置
cd ~/openclaw  # 若使用可駭客安裝
npm run build
sudo systemctl restart openclaw
```

### ARM 二進位檔問題

若 Skill 失敗並顯示 "exec format error"：
1. 檢查二進位檔是否有 ARM64 建置
2. 嘗試從原始碼建置
3. 或使用支援 ARM 的 Docker 容器

### WiFi 斷線

對於使用 WiFi 的無頭 Pi：

```bash
# 停用 WiFi 電源管理
sudo iwconfig wlan0 power off

# 設定永久生效
echo 'wireless-power off' | sudo tee -a /etc/network/interfaces
```

---

## 成本比較

| 設定 | 一次性成本 | 月費 | 備註 |
|-------|---------------|--------------|-------|
| **Pi 4 (2GB)** | ~$45 | $0 | + 電費 (~$5/年) |
| **Pi 4 (4GB)** | ~$55 | $0 | 推薦 |
| **Pi 5 (4GB)** | ~$60 | $0 | 效能最佳 |
| **Pi 5 (8GB)** | ~$80 | $0 | 效能過剩但經得起未來考驗 |
| DigitalOcean | $0 | $6/mo | $72/年 |
| Hetzner | $0 | €3.79/mo | ~$50/年 |

**損益平衡點:** 與雲端 VPS 相比，Pi 在約 6-12 個月內回本。

---

## 參閱

- [Linux guide](/platforms/linux) — 通用 Linux 設定
- [DigitalOcean guide](/platforms/digitalocean) — 雲端替代方案
- [Hetzner guide](/platforms/hetzner) — Docker 設定
- [Tailscale](/gateway/tailscale) — 遠端存取
- [Nodes](/nodes) — 將您的筆電/手機與 Pi Gateway 配對
