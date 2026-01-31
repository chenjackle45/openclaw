---
title: "hetzner(Hetzner)"
summary: "在便宜的 Hetzner VPS (Docker) 上全天候運行 OpenClaw Gateway，具備持久狀態與內建二進位檔"
read_when:
  - 想要在雲端 VPS (非筆電) 上全天候運行 OpenClaw
  - 想要在自己的 VPS 上運行生產級、永遠在線的 Gateway
  - 想要完全控制持久性、二進位檔與重啟行為
  - 您正在 Hetzner 或類似供應商的 Docker 上運行 OpenClaw
---

# OpenClaw on Hetzner (Docker, Production VPS Guide)

## 目標
使用 Docker 在 Hetzner VPS 上運行持久的 OpenClaw Gateway，具備持久狀態、內建二進位檔與安全的重啟行為。

若您想要 “OpenClaw 24/7 for ~$5”，這是最簡單可靠的設定。
Hetzner 價格會變動；選擇最小的 Debian/Ubuntu VPS，若遇到 OOM 則擴展。

## 我們要做什麼 (簡單來說)?

- 租用一台小型 Linux 伺服器 (Hetzner VPS)
- 安裝 Docker (隔離的應用程式執行環境)
- 在 Docker 中啟動 OpenClaw Gateway
- 將 `~/.openclaw` + `~/.openclaw/workspace` 持久化在 host 上 (重啟/重建後仍存在)
- 透過 SSH tunnel 從您的筆電存取 Control UI

Gateway 可透過以下方式存取：
- 從您的筆電進行 SSH 通訊埠轉發
- 若您自行管理防火牆與 Token，可直接暴露通訊埠

本指南假設在 Hetzner 上使用 Ubuntu 或 Debian。
若您使用其他 Linux VPS，請相應地映射套件。
關於通用的 Docker 流程，請參閱 [Docker](/install/docker)。

---

## 快速路徑 (經驗豐富的操作者)

1) 供應 Hetzner VPS
2) 安裝 Docker
3) Clone OpenClaw repository
4) 建立持久化 host 目錄
5) 設定 `.env` 與 `docker-compose.yml`
6) 將必要的二進位檔烘焙至映像檔中
7) `docker compose up -d`
8) 驗證持久性與 Gateway 存取

---

## 您需要準備

- 具有 root 權限的 Hetzner VPS
- 從您的筆電進行 SSH 存取
- 基本的 SSH + 複製/貼上 能力
- ~20 分鐘
- Docker 與 Docker Compose
- 模型認證憑證
- 選用的供應商憑證
  - WhatsApp QR
  - Telegram bot token
  - Gmail OAuth

---

## 1) 供應 VPS

在 Hetzner 中建立 Ubuntu 或 Debian VPS。

以 root 連線：

```bash
ssh root@YOUR_VPS_IP
```

本指南假設 VPS 是有狀態的 (stateful)。
請勿將其視為拋棄式基礎設施。

---

## 2) 安裝 Docker (在 VPS 上)

```bash
apt-get update
apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sh
```

驗證：

```bash
docker --version
docker compose version
```

---

## 3) Clone OpenClaw repository

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

本指南假設您將建置自訂映像檔以保證二進位檔持久性。

---

## 4) 建立持久化 host 目錄

Docker 容器是短暫的。
所有長壽狀態必須存在於 host 上。

```bash
mkdir -p /root/.openclaw
mkdir -p /root/.openclaw/workspace

# 將擁有權設定為 container user (uid 1000):
chown -R 1000:1000 /root/.openclaw
chown -R 1000:1000 /root/.openclaw/workspace
```

---

## 5) 設定環境變數

在 repository 根目錄建立 `.env`。

```bash
OPENCLAW_IMAGE=openclaw:latest
OPENCLAW_GATEWAY_TOKEN=change-me-now
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789

OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace

GOG_KEYRING_PASSWORD=change-me-now
XDG_CONFIG_HOME=/home/node/.openclaw
```

產生強密碼：

```bash
openssl rand -hex 32
```

**請勿提交此檔案。**

---

## 6) Docker Compose 設定

建立或更新 `docker-compose.yml`。

```yaml
services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE}
    build: .
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - HOME=/home/node
      - NODE_ENV=production
      - TERM=xterm-256color
      - OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND}
      - OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT}
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
      - GOG_KEYRING_PASSWORD=${GOG_KEYRING_PASSWORD}
      - XDG_CONFIG_HOME=${XDG_CONFIG_HOME}
      - PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    ports:
      # 推薦: 保持 Gateway 僅限 loopback 在 VPS 上；透過 SSH tunnel 存取。
      # 若要公開暴露，移除 `127.0.0.1:` 前綴並相應地設定防火牆。
      - "127.0.0.1:${OPENCLAW_GATEWAY_PORT}:18789"

      # 選用: 僅當您在 iOS/Android 節點上針對此 VPS 運行且需要 Canvas host 時。
      # 若您公開暴露此项，請閱讀 /gateway/security 並相應地設定防火牆。
      # - "18793:18793"
    command:
      [
        "node",
        "dist/index.js",
        "gateway",
        "--bind",
        "${OPENCLAW_GATEWAY_BIND}",
        "--port",
        "${OPENCLAW_GATEWAY_PORT}"
      ]
```

---

## 7) 將必要的二進位檔烘焙至映像檔中 (關鍵)

在運行的容器中安裝二進位檔是一個陷阱。
任何在執行時安裝的東西都會在重啟時遺失。

所有 Skills 需要的外部二進位檔必須在映像檔建置時安裝。

以下範例僅顯示三個常見的二進位檔：
- `gog` 用於 Gmail 存取
- `goplaces` 用於 Google Places
- `wacli` 用於 WhatsApp

這些是範例，並非完整清單。
您可以使用相同模式安裝任意數量的二進位檔。

若您稍後新增依賴額外二進位檔的新 Skills，您必須：
1. 更新 Dockerfile
2. 重新建置映像檔
3. 重啟容器

**範例 Dockerfile**

```dockerfile
FROM node:22-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# 範例二進位檔 1: Gmail CLI
RUN curl -L https://github.com/steipete/gog/releases/latest/download/gog_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/gog

# 範例二進位檔 2: Google Places CLI
RUN curl -L https://github.com/steipete/goplaces/releases/latest/download/goplaces_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/goplaces

# 範例二進位檔 3: WhatsApp CLI
RUN curl -L https://github.com/steipete/wacli/releases/latest/download/wacli_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/wacli

# 使用相同模式在下方新增更多二進位檔

WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY scripts ./scripts

RUN corepack enable
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

CMD ["node","dist/index.js"]
```

---

## 8) 建置並啟動

```bash
docker compose build
docker compose up -d openclaw-gateway
```

驗證二進位檔：

```bash
docker compose exec openclaw-gateway which gog
docker compose exec openclaw-gateway which goplaces
docker compose exec openclaw-gateway which wacli
```

預期輸出：

```
/usr/local/bin/gog
/usr/local/bin/goplaces
/usr/local/bin/wacli
```

---

## 9) 驗證 Gateway

```bash
docker compose logs -f openclaw-gateway
```

成功：

```
[gateway] listening on ws://0.0.0.0:18789
```

從您的筆電：

```bash
ssh -N -L 18789:127.0.0.1:18789 root@YOUR_VPS_IP
```

開啟：

`http://127.0.0.1:18789/`

貼上您的 Gateway Token。

---

## 資料持久化位置 (Source of Truth)

OpenClaw 運行在 Docker 中，但 Docker 不是 Source of Truth。
所有長壽狀態必須在重啟、重建與重開機後存活。

| 元件 | 位置 | 持久化機制 | 備註 |
|---|---|---|---|
| Gateway config | `/home/node/.openclaw/` | Host volume mount | 包含 `openclaw.json`, tokens |
| Model auth profiles | `/home/node/.openclaw/` | Host volume mount | OAuth tokens, API keys |
| Skill configs | `/home/node/.openclaw/skills/` | Host volume mount | Skill-level state |
| Agent workspace | `/home/node/.openclaw/workspace/` | Host volume mount | 程式碼與 Agent artifacts |
| WhatsApp session | `/home/node/.openclaw/` | Host volume mount | 保留 QR 登入狀態 |
| Gmail keyring | `/home/node/.openclaw/` | Host volume + password | 需要 `GOG_KEYRING_PASSWORD` |
| 外部二進位檔 | `/usr/local/bin/` | Docker image | 必須在建置時烘焙 |
| Node runtime | Container filesystem | Docker image | 每次映像檔建置時重建 |
| OS packages | Container filesystem | Docker image | 請勿在執行時安裝 |
| Docker container | Ephemeral | Restartable | 可安全銷毀 |

