---
title: "digitalocean(DigitalOcean)"
summary: "在 DigitalOcean 上執行 OpenClaw (簡易付費 VPS 選項)"
read_when:
  - 在 DigitalOcean 上設定 OpenClaw 時
  - 尋找便宜的 OpenClaw VPS 託管時
---

# OpenClaw on DigitalOcean

## 目標

以 **$6/月** (或 $4/月保留價格) 在 DigitalOcean 上執行持久的 OpenClaw Gateway。

若您想要 $0/月的選項且不介意 ARM + 特定供應商設定，請參閱 [Oracle Cloud guide](/platforms/oracle)。

## 成本比較 (2026)

| 供應商 | 方案 | 規格 | 價格/月 | 備註 |
|----------|------|-------|----------|-------|
| Oracle Cloud | Always Free ARM | 高達 4 OCPU, 24GB RAM | $0 | ARM, 容量有限 / 註冊怪僻 |
| Hetzner | CX22 | 2 vCPU, 4GB RAM | €3.79 (~$4) | 最便宜的付費選項 |
| DigitalOcean | Basic | 1 vCPU, 1GB RAM | $6 | 介面簡易, 文件良好 |
| Vultr | Cloud Compute | 1 vCPU, 1GB RAM | $6 | 許多地點 |
| Linode | Nanode | 1 vCPU, 1GB RAM | $5 | 現屬於 Akamai |

**選擇供應商:**
- DigitalOcean: 最簡單的 UX + 可預測的設定 (本指南)
- Hetzner: 性價比高 (參閱 [Hetzner guide](/platforms/hetzner))
- Oracle Cloud: 可達 $0/月，但較挑剔且僅限 ARM (參閱 [Oracle guide](/platforms/oracle))

---

## 先決條件

- DigitalOcean 帳號 ([註冊獲得 $200 免費額度](https://m.do.co/c/signup))
- SSH 金鑰對 (或願意使用密碼認證)
- 約 20 分鐘時間

## 1) 建立 Droplet

1. 登入 [DigitalOcean](https://cloud.digitalocean.com/)
2. 點擊 **Create → Droplets**
3. 選擇：
   - **Region (區域):** 離您 (或您的使用者) 最近的區域
   - **Image (映像檔):** Ubuntu 24.04 LTS
   - **Size (規格):** Basic → Regular → **$6/mo** (1 vCPU, 1GB RAM, 25GB SSD)
   - **Authentication (認證):** SSH key (推薦) 或密碼
4. 點擊 **Create Droplet**
5. 記下 IP 位址

## 2) 透過 SSH 連線

```bash
ssh root@YOUR_DROPLET_IP
```

## 3) 安裝 OpenClaw

```bash
# 更新系統
apt update && apt upgrade -y

# 安裝 Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# 安裝 OpenClaw
curl -fsSL https://openclaw.bot/install.sh | bash

# 驗證
openclaw --version
```

## 4) 執行 Onboarding

```bash
openclaw onboard --install-daemon
```

精靈會引導您完成：
- 模型認證 (API Keys 或 OAuth)
- Channel 設定 (Telegram, WhatsApp, Discord 等)
- Gateway Token (自動產生)
- Daemon 安裝 (systemd)

## 5) 驗證 Gateway

```bash
# 檢查狀態
openclaw status

# 檢查服務
systemctl --user status openclaw-gateway.service

# 查看日誌
journalctl --user -u openclaw-gateway.service -f
```

## 6) 存取儀表板

Gateway 預設綁定至 loopback。要存取 Control UI：

**選項 A: SSH Tunnel (推薦)**
```bash
# 從您的本地機器
ssh -L 18789:localhost:18789 root@YOUR_DROPLET_IP

# 然後開啟: http://localhost:18789
```

**選項 B: Tailscale Serve (HTTPS, 僅限 loopback)**
```bash
# 在 Droplet 上
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# 設定 Gateway 使用 Tailscale Serve
openclaw config set gateway.tailscale.mode serve
openclaw gateway restart
```

開啟: `https://<magicdns>/`

注意：
- Serve 保持 Gateway 僅限 loopback 並透過 Tailscale 身分標頭驗證。
- 若要要求 token/密碼，請設定 `gateway.auth.allowTailscale: false` 或使用 `gateway.auth.mode: "password"`。

**選項 C: Tailnet bind (無 Serve)**
```bash
openclaw config set gateway.bind tailnet
openclaw gateway restart
```

開啟: `http://<tailscale-ip>:18789` (Token 必需)。

## 7) 連接您的 Channels

### Telegram
```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

### WhatsApp
```bash
openclaw channels login whatsapp
# 掃描 QR Code
```

其他供應商請參閱 [Channels](/channels)。

---

## 1GB RAM 優化

$6 的 droplet 僅有 1GB RAM。為了保持運作順暢：

### 新增 swap (推薦)
```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### 使用較輕量的模型
若您遇到 OOM，考慮：
- 使用基於 API 的模型 (Claude, GPT) 而非本地模型
- 將 `agents.defaults.model.primary` 設定為較小的模型

### 監控記憶體
```bash
free -h
htop
```

---

## 持久性

所有狀態存在於：
- `~/.openclaw/` — 設定, 憑證, 工作階段資料
- `~/.openclaw/workspace/` — 工作區 (SOUL.md, memory 等)

這些在重開機後仍會保留。定期備份它們：
```bash
tar -czvf openclaw-backup.tar.gz ~/.openclaw ~/.openclaw/workspace
```

---

## Oracle Cloud 免費替代方案

Oracle Cloud 提供 **終身免費 (Always Free)** 的 ARM 實例，比這裡任何付費選項都強大得多 — 且 $0/月。

| 您獲得什麼 | 規格 |
|--------------|-------|
| **4 OCPUs** | ARM Ampere A1 |
| **24GB RAM** | 綽綽有餘 |
| **200GB storage** | 區塊儲存 |
| **Forever free** | 無信用卡扣款 |

**隱憂:**
- 註冊可能較挑剔 (若失敗請重試)
- ARM 架構 — 大多數東西可運作，但部分二進位檔需 ARM 建置

完整設定指南請參閱 [Oracle Cloud](/platforms/oracle)。關於註冊技巧與流程障礙排除，請參閱此 [社群指南](https://gist.github.com/rssnyder/51e3cfedd730e7dd5f4a816143b25dbd)。

---

## 故障排除

### Gateway 無法啟動
```bash
openclaw gateway status
openclaw doctor --non-interactive
journalctl -u openclaw --no-pager -n 50
```

### 通訊埠已被使用
```bash
lsof -i :18789
kill <PID>
```

### 記憶體不足
```bash
# 檢查記憶體
free -h

# 增加更多 Swap
# 或升級至 $12/mo droplet (2GB RAM)
```

---

## 參閱

- [Hetzner guide](/platforms/hetzner) — 更便宜, 更強大
- [Docker install](/install/docker) — 容器化設定
- [Tailscale](/gateway/tailscale) — 安全遠端存取
- [Configuration](/gateway/configuration) — 完整設定參考
