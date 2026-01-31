---
title: "oracle(Oracle Cloud)"
summary: "在 Oracle Cloud (Always Free ARM) 上運行 OpenClaw"
read_when:
  - 在 Oracle Cloud 上設定 OpenClaw 時
  - 尋找 OpenClaw 的低成本 VPS 託管時
  - 想要在小型伺服器上全天候運行 OpenClaw 時
---

# OpenClaw on Oracle Cloud (OCI)

## 目標

在 Oracle Cloud 的 **Always Free (終身免費)** ARM 層級上執行持久的 OpenClaw Gateway。

Oracle 的免費層級非常適合 OpenClaw（特別是若您已有 OCI 帳號），但有一些權衡：

- ARM 架構 (大多數東西可運作，但部分二進位檔可能僅限 x86)
- 容量與註冊可能較挑剔

## 成本比較 (2026)

| 供應商 | 方案 | 規格 | 價格/月 | 備註 |
|----------|------|-------|----------|-------|
| Oracle Cloud | Always Free ARM | 高達 4 OCPU, 24GB RAM | $0 | ARM, 容量有限 |
| Hetzner | CX22 | 2 vCPU, 4GB RAM | ~ $4 | 最便宜的付費選項 |
| DigitalOcean | Basic | 1 vCPU, 1GB RAM | $6 | 介面簡易, 文件良好 |
| Vultr | Cloud Compute | 1 vCPU, 1GB RAM | $6 | 許多地點 |
| Linode | Nanode | 1 vCPU, 1GB RAM | $5 | 現屬於 Akamai |

---

## 先決條件

- Oracle Cloud 帳號 ([註冊](https://www.oracle.com/cloud/free/)) — 若遇到問題請參閱 [社群註冊指南](https://gist.github.com/rssnyder/51e3cfedd730e7dd5f4a816143b25dbd)
- Tailscale 帳號 (在 [tailscale.com](https://tailscale.com) 免費註冊)
- ~30 分鐘

## 1) 建立 OCI 實例

1. 登入 [Oracle Cloud Console](https://cloud.oracle.com/)
2. 導航至 **Compute → Instances → Create Instance**
3. 設定：
   - **Name:** `openclaw`
   - **Image:** Ubuntu 24.04 (aarch64)
   - **Shape:** `VM.Standard.A1.Flex` (Ampere ARM)
   - **OCPUs:** 2 (或高達 4)
   - **Memory:** 12 GB (或高達 24 GB)
   - **Boot volume:** 50 GB (高達 200 GB 免費)
   - **SSH key:** 新增您的 Public Key
4. 點擊 **Create**
5. 記下 Public IP 位址

**提示:** 若實例建立失敗顯示 "Out of capacity"，嘗試不同的 Availability Domain 或稍後再試。免費層級容量有限。

## 2) 連線並更新

```bash
# 透過 Public IP 連線
ssh ubuntu@YOUR_PUBLIC_IP

# 更新系統
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential
```

**注意:** 部分依賴項的 ARM 編譯需要 `build-essential`。

## 3) 設定使用者與主機名稱

```bash
# 設定主機名稱
sudo hostnamectl set-hostname openclaw

# 設定 ubuntu 使用者密碼
sudo passwd ubuntu

# 啟用 lingering (讓使用者服務在登出後繼續運行)
sudo loginctl enable-linger ubuntu
```

## 4) 安裝 Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --hostname=openclaw
```

這啟用了 Tailscale SSH，讓您可以從 Tailnet 上任何裝置透過 `ssh openclaw` 連線 — 無需 Public IP。

驗證：
```bash
tailscale status
```

**從現在起，透過 Tailscale 連線:** `ssh ubuntu@openclaw` (或使用 Tailscale IP)。

## 5) 安裝 OpenClaw

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
source ~/.bashrc
```

當提示 "How do you want to hatch your bot?" 時，選擇 **"Do this later"**。

> 注意: 若遇到 ARM 原生建置問題，在尋求 Homebrew 之前先嘗試使用系統套件 (例如 `sudo apt install -y build-essential`)。

## 6) 設定 Gateway (loopback + token auth) 並啟用 Tailscale Serve

使用 token auth 作為預設值。這很可預測且避免需要任何「不安全認證」的 Control UI 旗標。

```bash
# 保持 Gateway 在 VM 上私有
openclaw config set gateway.bind loopback

# Gateway + Control UI 要求認證
openclaw config set gateway.auth.mode token
openclaw doctor --generate-gateway-token

# 透過 Tailscale Serve 暴露 (HTTPS + tailnet 存取)
openclaw config set gateway.tailscale.mode serve
openclaw config set gateway.trustedProxies '["127.0.0.1"]'

systemctl --user restart openclaw-gateway
```

## 7) 驗證

```bash
# 檢查版本
openclaw --version

# 檢查 Daemon 狀態
systemctl --user status openclaw-gateway

# 檢查 Tailscale Serve
tailscale serve status

# 測試本地回應
curl http://localhost:18789
```

## 8) 鎖定 VCN 安全性

現在一切運作正常，鎖定 VCN 以阻擋除 Tailscale 外的所有流量。OCI 的虛擬雲端網路 (Virtual Cloud Network) 在網路邊緣充當防火牆 — 流量在到達您的實例前就被阻擋。

1. 在 OCI Console 前往 **Networking → Virtual Cloud Networks**
2. 點擊您的 VCN → **Security Lists** → Default Security List
3. **移除** 所有 Ingress 規則，除了：
   - `0.0.0.0/0 UDP 41641` (Tailscale)
4. 保留預設 Egress 規則 (允許所有外流)

這會阻擋 Port 22 SSH, HTTP, HTTPS 以及網路邊緣的其他所有流量。從現在起，您只能透過 Tailscale 連線。

---

## 存取 Control UI

從您 Tailscale 網路上的任何裝置：

```
https://openclaw.<tailnet-name>.ts.net/
```

將 `<tailnet-name>` 替換為您的 Tailnet 名稱 (可透過 `tailscale status` 查看)。

無需 SSH Tunnel。Tailscale 提供：
- HTTPS 加密 (自動憑證)
- 透過 Tailscale 身分進行驗證
- 從 Tailnet 上任何裝置存取 (筆電, 手機等)

---

## 安全性: VCN + Tailscale (推薦基準)

鎖定 VCN (僅開放 UDP 41641) 並將 Gateway 綁定至 Loopback，您獲得了強大的防禦深度：公開流量在網路邊緣被阻擋，管理員存取透過您的 Tailnet 進行。

此設定通常消除了純粹為了防止 SSH 该力攻擊而設定額外 Host 防火牆規則的 *需求* — 但您仍應保持 OS 更新，執行 `openclaw security audit`，並確認沒有意外在公開介面上聆聽。

### 什麼已被保護

| 傳統步驟 | 需要? | 原因 |
|------------------|---------|-----|
| UFW 防火牆 | 否 | VCN 在流量到達實例前阻擋 |
| fail2ban | 否 | 若 Port 22 在 VCN 被阻擋則無暴力攻擊 |
| sshd 強化 | 否 | Tailscale SSH 不使用 sshd |
| 停用 root 登入 | 否 | Tailscale 使用 Tailscale 身分，非系統使用者 |
| 僅限 SSH Key 認證 | 否 | Tailscale 透過您的 Tailnet 驗證 |
| IPv6 強化 | 通常不 | 取決於您的 VCN/subnet 設定；驗證實際分配/暴露的內容 |

### 仍推薦

- **憑證權限:** `chmod 700 ~/.openclaw`
- **安全性稽核:** `openclaw security audit`
- **系統更新:** 定期執行 `sudo apt update && sudo apt upgrade`
- **監控 Tailscale:** 在 [Tailscale admin console](https://login.tailscale.com/admin) 審查裝置

### 驗證安全性狀態

```bash
# 確認無公開 Port 在聆聽
sudo ss -tlnp | grep -v '127.0.0.1\|::1'

# 驗證 Tailscale SSH 使用中
tailscale status | grep -q 'offers: ssh' && echo "Tailscale SSH active"

# 選用: 完全停用 sshd
sudo systemctl disable --now ssh
```

---

## 備援: SSH Tunnel

若 Tailscale Serve 無法運作，使用 SSH Tunnel：

```bash
# 從您的本地機器 (透過 Tailscale)
ssh -L 18789:127.0.0.1:18789 ubuntu@openclaw
```

然後開啟 `http://localhost:18789`。

---

## 故障排除

### 實例建立失敗 ("Out of capacity")
免費層級 ARM 實例很熱門。嘗試：
- 不同的 Availability Domain
- 在離峰時間重試 (清晨)
- 選擇 Shape 時使用 "Always Free" 篩選器

### Tailscale 無法連線
```bash
# 檢查狀態
sudo tailscale status

# 重新驗證
sudo tailscale up --ssh --hostname=openclaw --reset
```

### Gateway 無法啟動
```bash
openclaw gateway status
openclaw doctor --non-interactive
journalctl --user -u openclaw-gateway -n 50
```

### 無法存取 Control UI
```bash
# 驗證 Tailscale Serve 正在運行
tailscale serve status

# 檢查 Gateway 是否聆聽
curl http://localhost:18789

# 若需要則重啟
systemctl --user restart openclaw-gateway
```

### ARM 二進位檔問題
部分工具可能沒有 ARM 建置。檢查：
```bash
uname -m  # 應顯示 aarch64
```

大多數 npm 套件運作正常。對於二進位檔，尋找 `linux-arm64` 或 `aarch64` 版本。

---

## 持久性

所有狀態存在於：
- `~/.openclaw/` — 設定, 憑證, 工作階段資料
- `~/.openclaw/workspace/` — 工作區 (SOUL.md, memory, artifacts)

定期備份：
```bash
tar -czvf openclaw-backup.tar.gz ~/.openclaw ~/.openclaw/workspace
```

---

## 參閱

- [Gateway remote access](/gateway/remote) — 其他遠端存取模式
- [Tailscale integration](/gateway/tailscale) — 完整 Tailscale 文件
- [Gateway configuration](/gateway/configuration) — 所有設定選項
- [DigitalOcean guide](/platforms/digitalocean) — 若您想要付費 + 較簡單的註冊
- [Hetzner guide](/platforms/hetzner) — 基於 Docker 的替代方案
