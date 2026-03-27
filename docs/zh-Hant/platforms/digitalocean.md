---
summary: "OpenClaw 部署在 DigitalOcean 上（簡單的付費 VPS 選項）"
read_when:
  - 在 DigitalOcean 上設定 OpenClaw
  - 尋找便宜的 VPS 主機來運行 OpenClaw
title: "DigitalOcean (Platform)"
---

# OpenClaw on DigitalOcean

## 目標

在 DigitalOcean 上運行持久的 OpenClaw Gateway，每月僅需 **$6**（預付定價可降至 $4/月）。

如果你想要 $0/月的選項且不介意 ARM 架構與特定供應商的設定，請參閱 [Oracle Cloud 指南](/zh-Hant/platforms/oracle)。

## 費用比較（2026）

| 供應商       | 方案            | 規格                  | 月費        | 備註                                |
| ------------ | --------------- | --------------------- | ----------- | ----------------------------------- |
| Oracle Cloud | Always Free ARM | 最多 4 OCPU、24GB RAM | $0          | ARM 架構，容量有限 / 註冊流程較繁瑣 |
| Hetzner      | CX22            | 2 vCPU、4GB RAM       | €3.79 (~$4) | 最便宜的付費選項                    |
| DigitalOcean | Basic           | 1 vCPU、1GB RAM       | $6          | 介面簡單，文件完整                  |
| Vultr        | Cloud Compute   | 1 vCPU、1GB RAM       | $6          | 機房位置多                          |
| Linode       | Nanode          | 1 vCPU、1GB RAM       | $5          | 現已歸屬 Akamai                     |

**選擇供應商：**

- DigitalOcean：介面最簡單，設定流程可預期（本指南）
- Hetzner：性價比高（參閱 [Hetzner 指南](/zh-Hant/install/hetzner)）
- Oracle Cloud：可達 $0/月，但設定較繁瑣且僅限 ARM（參閱 [Oracle 指南](/zh-Hant/platforms/oracle)）

---

## 前置需求

- DigitalOcean 帳號（[使用 $200 免費額度註冊](https://m.do.co/c/signup)）
- SSH 金鑰對（或接受使用密碼驗證）
- 約 20 分鐘

## 1) 建立 Droplet

<Warning>
使用乾淨的基礎映像（Ubuntu 24.04 LTS）。除非你已審閱其啟動腳本和防火牆預設值，否則請避免使用第三方 Marketplace 一鍵映像。
</Warning>

1. 登入 [DigitalOcean](https://cloud.digitalocean.com/)
2. 點選 **Create → Droplets**
3. 選擇：
   - **Region：** 離你（或使用者）最近的地區
   - **Image：** Ubuntu 24.04 LTS
   - **Size：** Basic → Regular → **$6/月**（1 vCPU、1GB RAM、25GB SSD）
   - **Authentication：** SSH 金鑰（建議）或密碼
4. 點選 **Create Droplet**
5. 記下 IP 位址

## 2) 透過 SSH 連線

```bash
ssh root@YOUR_DROPLET_IP
```

## 3) 安裝 OpenClaw

```bash
# 更新系統
apt update && apt upgrade -y

# 安裝 Node.js 24
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt install -y nodejs

# 安裝 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# 確認安裝
openclaw --version
```

## 4) 執行引導設定

```bash
openclaw onboard --install-daemon
```

精靈程式會引導你完成：

- 模型驗證（API 金鑰或 OAuth）
- 頻道設定（Telegram、WhatsApp、Discord 等）
- Gateway token（自動產生）
- Daemon 安裝（systemd）

## 5) 確認 Gateway 狀態

```bash
# 檢查狀態
openclaw status

# 檢查服務
systemctl --user status openclaw-gateway.service

# 查看日誌
journalctl --user -u openclaw-gateway.service -f
```

## 6) 存取控制台

Gateway 預設綁定在 loopback。若要存取控制介面：

**選項 A：SSH 通道（建議）**

```bash
# 在你的本機執行
ssh -L 18789:localhost:18789 root@YOUR_DROPLET_IP

# 然後開啟：http://localhost:18789
```

**選項 B：Tailscale Serve（HTTPS，僅限 loopback）**

```bash
# 在 Droplet 上執行
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# 設定 Gateway 使用 Tailscale Serve
openclaw config set gateway.tailscale.mode serve
openclaw gateway restart
```

開啟：`https://<magicdns>/`

備註：

- Serve 讓 Gateway 保持在 loopback，並透過 Tailscale 身份標頭驗證控制介面/WebSocket 流量（無 token 驗證假設為受信任的 gateway 主機；HTTP API 仍需要 token/密碼）。
- 若要改為需要 token/密碼，請設定 `gateway.auth.allowTailscale: false` 或使用 `gateway.auth.mode: "password"`。

**選項 C：Tailnet 綁定（不使用 Serve）**

```bash
openclaw config set gateway.bind tailnet
openclaw gateway restart
```

開啟：`http://<tailscale-ip>:18789`（需要 token）。

## 7) 連接你的頻道

### Telegram

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

### WhatsApp

```bash
openclaw channels login whatsapp
# 掃描 QR code
```

其他供應商請參閱 [頻道](/zh-Hant/channels)。

---

## 1GB RAM 最佳化

$6 的 Droplet 只有 1GB RAM。以下是讓運行更順暢的方式：

### 新增 swap（建議）

```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### 使用較輕量的模型

如果遇到記憶體不足（OOM），可以考慮：

- 使用 API 模型（Claude、GPT）而非本地模型
- 將 `agents.defaults.model.primary` 設定為較小的模型

### 監控記憶體

```bash
free -h
htop
```

---

## 持久性

所有狀態儲存於：

- `~/.openclaw/` — 設定、憑證、會話資料
- `~/.openclaw/workspace/` — 工作區（SOUL.md、記憶等）

這些資料在重啟後仍會保留。建議定期備份：

```bash
tar -czvf openclaw-backup.tar.gz ~/.openclaw ~/.openclaw/workspace
```

---

## Oracle Cloud 免費替代方案

Oracle Cloud 提供 **Always Free** ARM 實例，效能遠超過這裡任何付費選項——而且完全免費。

| 你得到的       | 規格           |
| -------------- | -------------- |
| **4 OCPUs**    | ARM Ampere A1  |
| **24GB RAM**   | 綽綽有餘       |
| **200GB 儲存** | Block volume   |
| **永久免費**   | 不收信用卡費用 |

**注意事項：**

- 註冊流程可能較繁瑣（失敗時請重試）
- ARM 架構——大多數東西可以運行，但部分二進位檔需要 ARM 版本

完整設定指南請參閱 [Oracle Cloud](/zh-Hant/platforms/oracle)。關於註冊技巧和入會流程疑難排解，請參閱此[社群指南](https://gist.github.com/rssnyder/51e3cfedd730e7dd5f4a816143b25dbd)。

---

## 疑難排解

### Gateway 無法啟動

```bash
openclaw gateway status
openclaw doctor --non-interactive
journalctl -u openclaw --no-pager -n 50
```

### 連接埠已被使用

```bash
lsof -i :18789
kill <PID>
```

### 記憶體不足

```bash
# 檢查記憶體
free -h

# 新增更多 swap
# 或升級到 $12/月 Droplet（2GB RAM）
```

---

## 參閱

- [Hetzner 指南](/zh-Hant/install/hetzner) — 更便宜、更強大
- [Docker 安裝](/zh-Hant/install/docker) — 容器化設定
- [Tailscale](/zh-Hant/gateway/tailscale) — 安全的遠端存取
- [設定](/zh-Hant/gateway/configuration) — 完整設定參考
