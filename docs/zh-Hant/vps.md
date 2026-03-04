---
summary: "VPS hosting hub for OpenClaw (Oracle/Fly/Hetzner/GCP/exe.dev)"
read_when:
  - You want to run the Gateway in the cloud
  - You need a quick map of VPS/hosting guides
title: "VPS Hosting（VPS 託管）"
---

# VPS 託管

此中樞連結至支援的 VPS/託管指南，並從高層次解釋雲端部署的運作方式。

## 選擇供應商

- **Railway**（一鍵 + 瀏覽器設定）：[Railway](/zh-Hant/install/railway)
- **Northflank**（一鍵 + 瀏覽器設定）：[Northflank](/zh-Hant/install/northflank)
- **Oracle Cloud（永遠免費）**：[Oracle](/zh-Hant/platforms/oracle) — $0/月（永遠免費、ARM；容量/註冊可能有問題）
- **Fly.io**：[Fly.io](/zh-Hant/install/fly)
- **Hetzner（Docker）**：[Hetzner](/zh-Hant/install/hetzner)
- **GCP（Compute Engine）**：[GCP](/zh-Hant/install/gcp)
- **exe.dev**（VM + HTTPS 代理）：[exe.dev](/zh-Hant/install/exe-dev)
- **AWS（EC2/Lightsail/免費層）**：也可以很好地運作。影片指南：
  [https://x.com/techfrenAJ/status/2014934471095812547](https://x.com/techfrenAJ/status/2014934471095812547)

## 雲端設定的運作方式

- **閘道在 VPS 上執行**並擁有狀態 + 工作區。
- 您可以透過 **Control UI** 或 **Tailscale/SSH** 從筆電/手機連線。
- 將 VPS 視為真實來源，並**備份**狀態 + 工作區。
- 安全預設值：將閘道保持在環迴上，並透過 SSH 通道或 Tailscale Serve 存取。
  如果您綁定至 `lan`/`tailnet`，需要 `gateway.auth.token` 或 `gateway.auth.password`。

遠端存取：[閘道遠端](/zh-Hant/gateway/remote)
平台中樞：[平台](/zh-Hant/platforms)

## VPS 上的共用公司代理

當使用者在一個信任邊界內（例如一個公司團隊）且代理僅供業務使用時，這是有效的設定。

- 將其保留在專用運行時（VPS/VM/容器 + 專用 OS 使用者/帳戶）。
- 不要將該運行時簽署到個人 Apple/Google 帳戶或個人瀏覽器/密碼管理員設定檔。
- 如果使用者之間存在對立關係，請按閘道/主機/OS 使用者分割。

安全模型詳細資訊：[安全](/zh-Hant/gateway/security)

## 使用 VPS 上的節點

您可以將閘道保留在雲端中，並在本機裝置（Mac/iOS/Android/無頭）上配對**節點**。節點提供本機螢幕/相機/畫布和 `system.run` 功能，而閘道保留在雲端中。

文件：[節點](/zh-Hant/nodes)、[節點 CLI](/zh-Hant/cli/nodes)

## 小型 VM 和 ARM 主機的啟動調整

如果 CLI 命令在低功率 VM（或 ARM 主機）上感覺緩慢，請啟用 Node 的模組編譯快取：

```bash
grep -q 'NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
EOF
source ~/.bashrc
```

- `NODE_COMPILE_CACHE` 改進重複命令啟動時間。
- `OPENCLAW_NO_RESPAWN=1` 避免自我重新產生路徑的額外啟動開銷。
- 第一個命令執行會預熱快取；後續執行更快。
- 若要取得 Raspberry Pi 特定內容，請參閱 [Raspberry Pi](/zh-Hant/platforms/raspberry-pi)。

### systemd 調整檢查清單（選用）

針對使用 `systemd` 的 VM 主機，請考慮：

- 為穩定啟動路徑新增服務環境：
  - `OPENCLAW_NO_RESPAWN=1`
  - `NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache`
- 保持重新啟動行為明確：
  - `Restart=always`
  - `RestartSec=2`
  - `TimeoutStartSec=90`
- 偏好使用 SSD 支援的磁碟作為狀態/快取路徑，以減少隨機 I/O 冷啟動懲罰。

範例：

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

`Restart=` 原則如何幫助自動恢復：
[systemd 可以自動化服務恢復](https://www.redhat.com/en/blog/systemd-automate-recovery)。
