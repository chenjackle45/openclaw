---
summary: "用於長期 OpenClaw Gateway 主機的共享 Docker VM 執行時步驟"
read_when:
  - 你在具有 Docker 的雲端 VM 上部署 OpenClaw
  - 你需要共享二進位烘焙、持久性和更新流程
title: "Docker VM Runtime（Docker VM 執行時）"
---

# Docker VM Runtime

共享執行時步驟，用於基於 VM 的 Docker 安裝，例如 GCP、Hetzner 和類似的 VPS 提供者。

## 將所需的二進位檔案烘焙到映像中

在執行中的容器內安裝二進位檔案是一個陷阱。任何在執行時期安裝的內容都會在重新啟動時遺失。

所有由技能所需的外部二進位檔案都必須在映像建置時安裝。

下列範例僅顯示三個常見二進位檔案：

- `gog` 用於 Gmail 存取
- `goplaces` 用於 Google Places
- `wacli` 用於 WhatsApp

這些是範例，而非完整清單。你可以使用相同的模式安裝任意數量的二進位檔案。

如果你稍後新增依賴於其他二進位檔案的新技能，你必須：

1. 更新 Dockerfile
2. 重新建置映像
3. 重新啟動容器

**範例 Dockerfile**

```dockerfile
FROM node:24-bookworm

RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

# 範例二進位 1：Gmail CLI
RUN curl -L https://github.com/steipete/gog/releases/latest/download/gog_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/gog

# 範例二進位 2：Google Places CLI
RUN curl -L https://github.com/steipete/goplaces/releases/latest/download/goplaces_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/goplaces

# 範例二進位 3：WhatsApp CLI
RUN curl -L https://github.com/steipete/wacli/releases/latest/download/wacli_Linux_x86_64.tar.gz \
  | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/wacli

# 在下方使用相同的模式新增更多二進位檔案

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

<Note>
上述下載 URL 用於 x86_64 (amd64)。對於基於 ARM 的 VM（例如 Hetzner ARM、GCP Tau T2A），請用每個工具發行頁面上的適當 ARM64 變體取代下載 URL。
</Note>

## 建置和啟動

```bash
docker compose build
docker compose up -d openclaw-gateway
```

如果在 `pnpm install --frozen-lockfile` 期間建置失敗並出現 `Killed` 或 `exit code 137`，VM 記憶體不足。在重試前使用更大的機器類別。

驗證二進位檔案：

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

驗證 Gateway：

```bash
docker compose logs -f openclaw-gateway
```

預期輸出：

```
[gateway] listening on ws://0.0.0.0:18789
```

## 什麼在哪裡持久

OpenClaw 在 Docker 中執行，但 Docker 不是事實的來源。所有長期狀態必須在重新啟動、重新建置和重新啟動時存活。

| 元件              | 位置                              | 持久機制      | 備註                        |
| ----------------- | --------------------------------- | ------------- | --------------------------- |
| Gateway 配置      | `/home/node/.openclaw/`           | 主機卷掛載    | 包括 `openclaw.json`、令牌  |
| 模型認證設定檔    | `/home/node/.openclaw/`           | 主機卷掛載    | OAuth 令牌、API 金鑰        |
| 技能配置          | `/home/node/.openclaw/skills/`    | 主機卷掛載    | 技能級狀態                  |
| 代理工作區        | `/home/node/.openclaw/workspace/` | 主機卷掛載    | 程式碼和代理成品            |
| WhatsApp 工作階段 | `/home/node/.openclaw/`           | 主機卷掛載    | 保留 QR 登入                |
| Gmail 鑰匙圈      | `/home/node/.openclaw/`           | 主機卷 + 密碼 | 需要 `GOG_KEYRING_PASSWORD` |
| 外部二進位檔案    | `/usr/local/bin/`                 | Docker 映像   | 必須在建置時烘焙            |
| Node 執行時期     | 容器檔案系統                      | Docker 映像   | 每次映像建置時重新建置      |
| OS 套件           | 容器檔案系統                      | Docker 映像   | 不要在執行時期安裝          |
| Docker 容器       | 暫時的                            | 可重新啟動    | 安全刪除                    |

## 更新

在 VM 上更新 OpenClaw：

```bash
git pull
docker compose build
docker compose up -d
```
