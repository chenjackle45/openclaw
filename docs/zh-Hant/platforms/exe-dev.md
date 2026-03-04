---
summary: "在 exe.dev（VM + HTTPS 代理）上執行 OpenClaw Gateway 以進行遠端訪問"
read_when:
  - 你想要廉價的常駐 Linux 主機來執行 Gateway
  - 你想要遠端控制 UI 訪問而不執行自己的 VPS
title: "exe.dev（exe.dev）"
---

# exe.dev

目標：OpenClaw Gateway 執行在 exe.dev VM 上，可從你的筆記型電腦通過 `https://<vm-name>.exe.xyz` 訪問。

此頁面假設 exe.dev 的預設 **exeuntu** 映像。如果你選擇了不同的發行版，相應地映射套件。

## 初級快速路徑

1. [https://exe.new/openclaw](https://exe.new/openclaw)
2. 填入你的身分驗證金鑰/令牌（如需要）
3. 按一下你的 VM 旁的「Agent」，然後等待...
4. ???
5. 利潤

## 你需要什麼

- exe.dev 帳號
- 對 [exe.dev](https://exe.dev) 虛擬機的 `ssh exe.dev` 訪問（選用）

## 使用 Shelley 的自動安裝

Shelley 是 [exe.dev](https://exe.dev) 的 agent，可以使用我們的提示快速安裝 OpenClaw。

## 手動安裝

### 1) 建立 VM

從你的設備：

```bash
ssh exe.dev new
```

然後連線：

```bash
ssh <vm-name>.exe.xyz
```

提示：保持此 VM **有狀態**。OpenClaw 將狀態儲存在 `~/.openclaw/` 和 `~/.openclaw/workspace/`。

### 2) 安裝先決條件（在 VM 上）

```bash
sudo apt-get update
sudo apt-get install -y git curl jq ca-certificates openssl
```

### 3) 安裝 OpenClaw

執行 OpenClaw 安裝指令碼：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

### 4) 設定 nginx 以將 OpenClaw 代理到埠 8000

使用以下內容編輯 `/etc/nginx/sites-enabled/default`

```
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 8000;
    listen [::]:8000;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;

        # WebSocket 支援
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 標準代理標頭
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 長生命週期連線的逾時設定
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

### 5) 訪問 OpenClaw 並授予特權

訪問 `https://<vm-name>.exe.xyz/`（見上線精靈的控制 UI 輸出）。如果它提示身分驗證，從 VM 上的 `gateway.auth.token` 貼上令牌（使用 `openclaw config get gateway.auth.token` 檢索，或使用 `openclaw doctor --generate-gateway-token` 生成一個）。使用 `openclaw devices list` 和 `openclaw devices approve <requestId>` 批准設備。

## 遠端訪問

遠端訪問由 [exe.dev](https://exe.dev) 的身分驗證處理。預設情況下，埠 8000 的 HTTP 流量被轉發到 `https://<vm-name>.exe.xyz`，使用電子郵件身分驗證。

## 更新

```bash
npm i -g openclaw@latest
openclaw doctor
openclaw gateway restart
openclaw health
```

指南：[更新](/zh-Hant/install/updating)
