---
summary: "DigitalOcean 上的 OpenClaw（簡單的付費 VPS 選項）"
read_when:
  - 在 DigitalOcean 上設定 OpenClaw
  - 尋找 OpenClaw 的便宜 VPS 主機代管
title: "DigitalOcean（DigitalOcean）"
---

# DigitalOcean 上的 OpenClaw

## 目標

在 DigitalOcean 上執行持續 OpenClaw Gateway，費用為 **$6/月**（或以保留定價為 $4/月）。

如果你想要 $0/月選項且不介意 ARM + 提供者特定設定，詳見 [Oracle Cloud 指南](/zh-Hant/platforms/oracle)。

## 成本比較 (2026)

| 提供者       | 計畫            | 規格                  | 價格/月     | 注意                     |
| ------------ | --------------- | --------------------- | ----------- | ------------------------ |
| Oracle Cloud | Always Free ARM | 最多 4 OCPU、24GB RAM | $0          | ARM、有限容量 / 註冊怪癖 |
| Hetzner      | CX22            | 2 vCPU、4GB RAM       | €3.79 (~$4) | 最便宜的付費選項         |
| DigitalOcean | 基本            | 1 vCPU、1GB RAM       | $6          | 簡單 UI、良好文件        |
| Vultr        | 雲計算          | 1 vCPU、1GB RAM       | $6          | 許多位置                 |
| Linode       | Nanode          | 1 vCPU、1GB RAM       | $5          | 現在是 Akamai 的一部分   |

**選擇提供者：**

- DigitalOcean：最簡單的 UX + 可預測設定（本指南）
- Hetzner：良好的價格/效能（詳見 [Hetzner 指南](/zh-Hant/install/hetzner)）
- Oracle Cloud：可以 $0/月，但更棘手且僅 ARM（詳見 [Oracle 指南](/zh-Hant/platforms/oracle)）

---

## 先決條件

- DigitalOcean 帳戶（[以 $200 免費點數註冊](https://m.do.co/c/signup)）
- SSH 金鑰對（或使用密碼驗證的意願）
- ~20 分鐘

## 1) 建立 Droplet

1. 登入 [DigitalOcean](https://cloud.digitalocean.com/)
2. 點擊 **建立 → Droplets**
3. 選擇：
   - **區域：** 最接近你的（或你的使用者）
   - **映像：** Ubuntu 24.04 LTS
   - **大小：** 基本 → 一般 → **$6/月**（1 vCPU、1GB RAM、25GB SSD）
   - **驗證：** SSH 金鑰（推薦）或密碼
4. 點擊 **建立 Droplet**
5. 記下 IP 位址

## 2) 透過 SSH 連接

ssh root@YOUR_DROPLET_IP

## 3) 安裝 OpenClaw

apt update && apt upgrade -y

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

curl -fsSL https://openclaw.ai/install.sh | bash

openclaw --version

## 4) 執行上線

openclaw onboard --install-daemon

精靈會引導你完成：

- 模型驗證（API 金鑰或 OAuth）
- 頻道設定（Telegram、WhatsApp、Discord 等）
- Gateway 權杖（自動產生）
- 守護程式安裝（systemd）

## 5) 驗證 Gateway

openclaw status

systemctl --user status openclaw-gateway.service

journalctl --user -u openclaw-gateway.service -f

## 6) 存取儀表板

Gateway 預設綁定到環回。若要存取控制 UI：

**選項 A：SSH 隧道（推薦）**

從你的本機機器：

ssh -L 18789:localhost:18789 root@YOUR_DROPLET_IP

然後開啟：http://localhost:18789

**選項 B：Tailscale Serve（HTTPS、僅環回）**

在 droplet 上：

curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

openclaw config set gateway.tailscale.mode serve
openclaw gateway restart

開啟：`https://<magicdns>/`

---

## 1GB RAM 優化

$6 droplet 僅有 1GB RAM。保持一切執行順利：

### 新增交換（推薦）

fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

### 使用較淡模型

如果你遇到 OOM，考慮：

- 使用基於 API 的模型（Claude、GPT）而不是本機模型
- 將 agents.defaults.model.primary 設定為較小的模型

### 監視記憶體

free -h
htop

---

## 持久性

所有狀態位於：

~/.openclaw/ — 配置、認證、會話資料
~/.openclaw/workspace/ — 工作區（SOUL.md、記憶體等）

這些在重新開機後倖存。定期備份：

tar -czvf openclaw-backup.tar.gz ~/.openclaw ~/.openclaw/workspace

---

## Oracle Cloud 免費替代品

Oracle Cloud 提供 **Always Free** ARM 實例，比此處任何付費選項都強大得多 — 免費 $0/月。

詳見 [Oracle Cloud](/zh-Hant/platforms/oracle)。

---

## 故障排查

### Gateway 不會啟動

openclaw gateway status
openclaw doctor --non-interactive
journalctl -u openclaw --no-pager -n 50

### 連接埠已在使用中

`lsof -i :18789`
`kill <PID>`

### 記憶體不足

free -h

新增更多交換或升級到 $12/月 droplet（2GB RAM）

---

## 另請參閱

- [Hetzner 指南](/zh-Hant/install/hetzner) — 更便宜、更強大
- [Docker 安裝](/zh-Hant/install/docker) — 容器化設定
- [Tailscale](/zh-Hant/gateway/tailscale) — 安全遠端存取
- [配置](/zh-Hant/gateway/configuration) — 完整配置參考
