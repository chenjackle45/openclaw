---
title: "gcp(GCP Compute Engine)"
summary: "在 GCP Compute Engine VM (Docker) 上全天候運行 OpenClaw Gateway 並具備持久狀態"
read_when:
  - 想要在 GCP 上全天候運行 OpenClaw
  - 想要在自己的 VM 上運行生產級、永遠在線的 Gateway
  - 想要完全控制持久性、二進位檔與重啟行為
---

# OpenClaw on GCP Compute Engine (Docker, Production VPS Guide)

## 目標

使用 Docker 在 GCP Compute Engine VM 上運行持久的 OpenClaw Gateway，具備持久狀態、內建二進位檔與安全的重啟行為。

若您想要 "OpenClaw 24/7 for ~$5-12/mo"，這是 Google Cloud 上可靠的設定。
價格因機器類型與區域而異；選擇適合您工作負載的最小 VM，若遇到 OOM 則擴展。

## 我們要做什麼 (簡單來說)?

- 建立 GCP 專案並啟用計費
- 建立 Compute Engine VM
- 安裝 Docker (隔離的應用程式執行環境)
- 在 Docker 中啟動 OpenClaw Gateway
- 將 `~/.openclaw` + `~/.openclaw/workspace` 持久化在 host 上 (重啟/重建後仍存在)
- 透過 SSH tunnel 從您的筆電存取 Control UI

Gateway 可透過以下方式存取：
- 從您的筆電進行 SSH 通訊埠轉發
- 若您自行管理防火牆與 Token，可直接暴露通訊埠

本指南在 GCP Compute Engine 上使用 Debian。
Ubuntu 也可運作；請相應地映射套件。
關於通用的 Docker 流程，請參閱 [Docker](/install/docker)。

---

## 快速路徑 (經驗豐富的操作者)

1) 建立 GCP 專案 + 啟用 Compute Engine API
2) 建立 Compute Engine VM (e2-small, Debian 12, 20GB)
3) SSH 進入 VM
4) 安裝 Docker
5) Clone OpenClaw repository
6) 建立持久化 host 目錄
7) 設定 `.env` 與 `docker-compose.yml`
8) 烘焙 (Bake) 必要的二進位檔、建置並啟動

---

## 您需要準備

- GCP 帳號 (e2-micro 適用免費層級)
- 安裝 gcloud CLI (或使用 Cloud Console)
- 從您的筆電進行 SSH 存取
- 基本的 SSH + 複製/貼上 能力
- ~20-30 分鐘
- Docker 與 Docker Compose
- 模型認證憑證
- 選用的供應商憑證
  - WhatsApp QR
  - Telegram bot token
  - Gmail OAuth

---

## 1) 安裝 gcloud CLI (或使用 Console)

**選項 A: gcloud CLI** (推薦用於自動化)

安裝來源: https://cloud.google.com/sdk/docs/install

初始化並驗證：

```bash
gcloud init
gcloud auth login
```

**選項 B: Cloud Console**

所有步驟皆可透過 Web UI 完成: https://console.cloud.google.com

---

## 2) 建立 GCP 專案

**CLI:**

```bash
gcloud projects create my-openclaw-project --name="OpenClaw Gateway"
gcloud config set project my-openclaw-project
```

在 https://console.cloud.google.com/billing 啟用計費 (Compute Engine 必需)。

啟用 Compute Engine API:

```bash
gcloud services enable compute.googleapis.com
```

**Console:**

1. 前往 IAM & Admin > Create Project
2. 命名並建立
3. 為專案啟用計費
4. 前往 APIs & Services > Enable APIs > 搜尋 "Compute Engine API" > Enable

---

## 3) 建立 VM

**機器類型:**

| 類型 | 規格 | 成本 | 備註 |
|------|-------|------|-------|
| e2-small | 2 vCPU, 2GB RAM | ~$12/mo | 推薦 |
| e2-micro | 2 vCPU (共享), 1GB RAM | 符合免費層級 | 負載下可能 OOM |

**CLI:**

```bash
gcloud compute instances create openclaw-gateway \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --boot-disk-size=20GB \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

**Console:**

1. 前往 Compute Engine > VM instances > Create instance
2. 名稱: `openclaw-gateway`
3. 區域: `us-central1`, 區域: `us-central1-a`
4. 機器類型: `e2-small`
5. 開機磁碟: Debian 12, 20GB
6. 建立

---

## 4) SSH 進入 VM

**CLI:**

```bash
gcloud compute ssh openclaw-gateway --zone=us-central1-a
```

**Console:**

點擊 Compute Engine 儀表板中 VM 旁的 "SSH" 按鈕。

注意: SSH 金鑰傳播在 VM 建立後可能需要 1-2 分鐘。若連線被拒絕，請稍候再試。

---

## 5) 安裝 Docker (在 VM 上)

```bash
sudo apt-get update
sudo apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

登出並重新登入以使群組變更生效：

```bash
exit
```

然後 SSH 回去：

```bash
gcloud compute ssh openclaw-gateway --zone=us-central1-a
```

驗證：

```bash
docker --version
docker compose version
```

---

## 6) Clone OpenClaw repository

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

本指南假設您將建置自訂映像檔以保證二進位檔持久性。

---

## 7) 建立持久化 host 目錄

Docker 容器是短暫的。
所有長壽狀態必須存在於 host 上。

```bash
mkdir -p ~/.openclaw
mkdir -p ~/.openclaw/workspace
```

---

## 8) 設定環境變數

在 repository 根目錄建立 `.env`。

```bash
OPENCLAW_IMAGE=openclaw:latest
OPENCLAW_GATEWAY_TOKEN=change-me-now
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789

OPENCLAW_CONFIG_DIR=/home/$USER/.openclaw
OPENCLAW_WORKSPACE_DIR=/home/$USER/.openclaw/workspace

GOG_KEYRING_PASSWORD=change-me-now
XDG_CONFIG_HOME=/home/node/.openclaw
```

產生強密碼：

```bash
openssl rand -hex 32
```

**請勿提交此檔案。**

---

## 9) Docker Compose 設定

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
      # 推薦: 保持 Gateway 僅限 loopback 在 VM 上；透過 SSH tunnel 存取。
      # 若要公開暴露，移除 `127.0.0.1:` 前綴並相應地設定防火牆。
      - "127.0.0.1:${OPENCLAW_GATEWAY_PORT}:18789"

      # 選用: 僅當您在 iOS/Android 節點上針對此 VM 運行且需要 Canvas host 時。
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

## 10) 將必要的二進位檔烘焙至映像檔中 (關鍵)

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

## 11) 建置並啟動

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

## 12) 驗證 Gateway

```bash
docker compose logs -f openclaw-gateway
```

成功：

```
[gateway] listening on ws://0.0.0.0:18789
```

---

## 13) 從您的筆電存取

建立 SSH Tunnel 轉發 Gateway 通訊埠：

```bash
gcloud compute ssh openclaw-gateway --zone=us-central1-a -- -L 18789:127.0.0.1:18789
```

在您的瀏覽器開啟：

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

---

## 更新

要在 VM 上更新 OpenClaw：

```bash
cd ~/openclaw
git pull
docker compose build
docker compose up -d
```

---

## 故障排除

**SSH 連線被拒絕 (Connection refused)**

SSH 金鑰傳播在 VM 建立後可能需要 1-2 分鐘。稍候再試。

**OS Login 問題**

檢查您的 OS Login 設定檔：

```bash
gcloud compute os-login describe-profile
```

確保您的帳號擁有必要的 IAM 權限 (Compute OS Login 或 Compute OS Admin Login)。

**記憶體不足 (OOM)**

若使用 e2-micro 並遇到 OOM，升級至 e2-small 或 e2-medium：

```bash
# 先停止 VM
gcloud compute instances stop openclaw-gateway --zone=us-central1-a

# 變更機器類型
gcloud compute instances set-machine-type openclaw-gateway \
  --zone=us-central1-a \
  --machine-type=e2-small

# 啟動 VM
gcloud compute instances start openclaw-gateway --zone=us-central1-a
```

---

## 服務帳戶 (安全性最佳實踐)

供個人使用時，您的預設使用者帳號即可。

對於自動化或 CI/CD 管道，建立具有最小權限的專用服務帳戶：

1. 建立服務帳戶：
   ```bash
   gcloud iam service-accounts create openclaw-deploy \
     --display-name="OpenClaw Deployment"
   ```

2. 授予 Compute Instance Admin 角色 (或更窄的自訂角色)：
   ```bash
   gcloud projects add-iam-policy-binding my-openclaw-project \
     --member="serviceAccount:openclaw-deploy@my-openclaw-project.iam.gserviceaccount.com" \
     --role="roles/compute.instanceAdmin.v1"
   ```

避免在自動化中使用 Owner 角色。採用最小權限原則。

詳情請參閱 [GCP IAM roles](https://cloud.google.com/iam/docs/understanding-roles)。

---

## 下一步

- 設定訊息頻道: [Channels](/channels)
- 配對本地裝置為節點: [Nodes](/nodes)
- 設定 Gateway: [Gateway configuration](/gateway/configuration)
