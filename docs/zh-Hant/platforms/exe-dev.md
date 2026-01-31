---
title: "exe-dev(exe.dev)"
summary: "在 exe.dev (VM + HTTPS proxy) 上運行 OpenClaw Gateway 以進行遠端存取"
read_when:
  - 想要便宜的永遠在線 Linux 主機運行 Gateway
  - 想要無需運行自己 VPS 的遠端 Control UI 存取
---

# exe.dev

目標: 在 exe.dev VM 上運行 OpenClaw Gateway，並可透過 `https://<vm-name>.exe.xyz` 從您的筆電存取。

此頁面假設使用 exe.dev 的預設 **exeuntu** 映像檔。若您選擇不同的發行版，請相應地映射套件。

## 新手快速路徑

1) [https://exe.new/openclaw](https://exe.new/openclaw)
2) 視需要填入您的 Auth Key/Token
3) 點擊 VM 旁的 "Agent"，然後等待...
4) ???
5) 獲利

## 您需要準備

- exe.dev 帳號
- 對 [exe.dev](https://exe.dev) 虛擬機器的 `ssh exe.dev` 存取權限 (選用)

## 使用 Shelley 自動安裝

Shelley ([exe.dev](https://exe.dev) 的 Agent) 可以透過我們的 Prompt 立即安裝 OpenClaw。使用的 Prompt 如下：

```
Set up OpenClaw (https://docs.openclaw.ai/install) on this VM. Use the non-interactive and accept-risk flags for openclaw onboarding. Add the supplied auth or token as needed. Configure nginx to forward from the default port 18789 to the root location on the default enabled site config, making sure to enable Websocket support. Pairing is done by "openclaw devices list" and "openclaw device approve <request id>". Make sure the dashboard shows that OpenClaw's health is OK. exe.dev handles forwarding from port 8000 to port 80/443 and HTTPS for us, so the final "reachable" should be <vm-name>.exe.xyz, without port specification.
```

## 手動安裝

## 1) 建立 VM

從您的裝置：

```bash
ssh exe.dev new 
```

然後連線：

```bash
ssh <vm-name>.exe.xyz
```

提示: 保持此 VM **stateful**。OpenClaw 將狀態儲存在 `~/.openclaw/` 與 `~/.openclaw/workspace/` 下。

## 2) 安裝先決條件 (在 VM 上)

```bash
sudo apt-get update
sudo apt-get install -y git curl jq ca-certificates openssl
```

## 3) 安裝 OpenClaw

執行 OpenClaw 安裝腳本：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

## 4) 設定 nginx 代理 OpenClaw 至通訊埠 8000

使用以下內容編輯 `/etc/nginx/sites-enabled/default`：

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 8000;
    listen [::]:8000;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Standard proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeout settings for long-lived connections
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

## 5) 存取 OpenClaw 並授予權限

存取 `https://<vm-name>.exe.xyz/?token=YOUR-TOKEN-FROM-TERMINAL`。
透過 `openclaw devices list` 與 `openclaw device approve` 核准裝置。
若有疑問，請從您的瀏覽器使用 Shelley！

## 遠端存取

遠端存取由 [exe.dev](https://exe.dev) 的認證處理。預設情況下，來自通訊埠 8000 的 HTTP 流量會被轉發至 `https://<vm-name>.exe.xyz` 並附帶 Email 認證。

## 更新

```bash
npm i -g openclaw@latest
openclaw doctor
openclaw gateway restart
openclaw health
```

指南: [Updating](/install/updating)
