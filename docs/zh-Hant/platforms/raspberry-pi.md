---
summary: "Raspberry Pi 上的 OpenClaw（低預算自託管設定）"
read_when:
  - 在 Raspberry Pi 上設定 OpenClaw
  - 在 ARM 設備上執行 OpenClaw
  - 構建便宜的始終開啟的個人 AI
title: "Raspberry Pi（Raspberry Pi）"
---

# Raspberry Pi 上的 OpenClaw

## 目標

在 Raspberry Pi 上執行持續、始終開啟的 OpenClaw Gateway，費用為 **~$35-80** 一次性（無月費）。

完美適用於：

- 24/7 個人 AI 助手
- 家庭自動化中樞
- 低功耗、始終可用的 Telegram/WhatsApp 機器人

## 硬體需求

| Pi 型號         | RAM     | 有效嗎？ | 注意                   |
| --------------- | ------- | -------- | ---------------------- |
| **Pi 5**        | 4GB/8GB | ✅ 最佳  | 最快，推薦             |
| **Pi 4**        | 4GB     | ✅ 良好  | 大多數使用者的最佳點   |
| **Pi 4**        | 2GB     | ✅ 可以  | 有效，新增交換         |
| **Pi 4**        | 1GB     | ⚠️ 緊張  | 可能帶有交換，最小配置 |
| **Pi 3B+**      | 1GB     | ⚠️ 緩慢  | 有效但遲緩             |
| **Pi Zero 2 W** | 512MB   | ❌       | 不推薦                 |

**最低規格：** 1GB RAM、1 核、500MB 磁碟
**推薦：** 2GB+ RAM、64 位作業系統、16GB+ SD 卡（或 USB SSD）

## 你需要什麼

- Raspberry Pi 4 或 5（推薦 2GB+）
- MicroSD 卡（16GB+）或 USB SSD（更好的性能）
- 電源供應（推薦官方 Pi PSU）
- 網路連線（乙太網或 WiFi）
- ~30 分鐘

## 1) 刷新操作系統

使用 **Raspberry Pi OS Lite（64 位）** — 無需桌面進行無頭伺服器。

1. 下載 [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. 選擇操作系統：**Raspberry Pi OS Lite（64 位）**
3. 點擊齒輪圖示（⚙️）進行預配置：
   - 設定主機名稱：gateway-host
   - 啟用 SSH
   - 設定使用者名稱/密碼
   - 配置 WiFi（如果未使用乙太網）
4. 刷新到你的 SD 卡 / USB 磁碟
5. 插入並啟動 Pi

## 2) 透過 SSH 連接

ssh user@gateway-host
或使用 IP 位址
ssh user@192.168.x.x

## 3) 系統設定

更新系統並安裝 Node.js 等基本套件。詳見原始英文文件。

## 4) 安裝 OpenClaw

### 選項 A：標準安裝（推薦）

curl -fsSL https://openclaw.ai/install.sh | bash

### 選項 B：可駭客安裝（用於調整）

git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install
npm run build
npm link

可駭客安裝提供對日誌和程式碼的直接存取 — 用於偵錯 ARM 特定問題。

## 5) 執行上線

openclaw onboard --install-daemon

按照精靈進行：

1. **Gateway 模式：** 本機
2. **驗證：** 推薦 API 金鑰（OAuth 在無頭 Pi 上可能很棘手）
3. **頻道：** Telegram 最容易開始
4. **守護程式：** 是（systemd）

## 6) 驗證安裝

openclaw status
openclaw status --user
journalctl -u openclaw -f

## 7) 存取儀表板

由於 Pi 是無頭的，使用 SSH 隧道：

ssh -L 18789:localhost:18789 user@gateway-host

然後在瀏覽器中開啟
http://localhost:18789

或使用 Tailscale 進行始終開啟存取：

curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

更新配置
openclaw config set gateway.bind tailnet
sudo systemctl restart openclaw

---

## 性能優化

### 使用 USB SSD（巨大改進）

SD 卡速度慢且磨損。USB SSD 大幅改善性能。詳見 Pi USB 啟動指南。

### 減少記憶體使用

# 禁用 GPU 記憶體分配（無頭）

echo 'gpu_mem=16' | sudo tee -a /boot/config.txt

# 禁用藍牙（如果不需要）

sudo systemctl disable bluetooth

### 監視資源

free -h
vcgencmd measure_temp
htop

---

## ARM 特定注意事項

### 二進位相容性

大多數 OpenClaw 功能在 ARM64 上有效，但某些外部二進位檔可能需要 ARM 構建。詳見原始文件。

### 32 位對 64 位

**始終使用 64 位作業系統。** Node.js 和許多現代工具都需要它。檢查：

uname -m
應該顯示：aarch64（64 位）而不是 armv7l（32 位）

---

## 推薦模型設定

由於 Pi 只是 Gateway（模型在雲中執行），使用基於 API 的模型。詳見原始文件。

**不要嘗試在 Pi 上執行本機 LLM** — 即使小型模型也太慢。讓 Claude/GPT 執行繁重工作。

---

## 開機時自動啟動

上線精靈設定此，但驗證：

sudo systemctl is-enabled openclaw

如果沒有啟用：

sudo systemctl enable openclaw

---

## 故障排查

### 記憶體不足（OOM）

free -h

新增更多交換（見步驟 5）或減少 Pi 上執行的服務。

### 效能緩慢

- 使用 USB SSD 而不是 SD 卡
- 禁用未使用的服務
- 檢查 CPU 節流

### 服務不會啟動

journalctl -u openclaw --no-pager -n 100

常見修復：重新構建

### ARM 二進位檔問題

如果技能以「exec format error」失敗：

1. 檢查二進位檔是否有 ARM64 構建
2. 嘗試從原始碼構建
3. 或使用帶有 ARM 支援的 Docker 容器

---

## 成本比較

| 設定           | 一次性成本 | 月費 | 注意             |
| -------------- | ---------- | ---- | ---------------- |
| **Pi 4 (2GB)** | ~$45       | $0   | + 電源（~$5/年） |
| **Pi 4 (4GB)** | ~$55       | $0   | 推薦             |
| **Pi 5 (4GB)** | ~$60       | $0   | 最佳性能         |
| **Pi 5 (8GB)** | ~$80       | $0   | 過度但未來防災   |

**損益平衡：** Pi 與雲 VPS 相比在 ~6-12 個月內為自己付費。

---

## 另請參閱

- [Linux 指南](/zh-Hant/platforms/linux) — 一般 Linux 設定
- [DigitalOcean 指南](/zh-Hant/platforms/digitalocean) — 雲替代品
- [Hetzner 指南](/zh-Hant/install/hetzner) — Docker 設定
- [Tailscale](/zh-Hant/gateway/tailscale) — 遠端存取
- [節點](/zh-Hant/nodes) — 將你的筆記本電腦/電話與 Pi gateway 配對
