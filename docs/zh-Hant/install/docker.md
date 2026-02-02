---
title: "Docker"
summary: "OpenClaw 的可選 Docker 設定與引導"
read_when:
  - 您想要容器化 Gateway 而非本機安裝
  - 您正驗證 Docker 工作流程
---

# Docker（可選）

Docker 是**可選的**。只在您想要容器化 Gateway 或驗證 Docker 工作流程時使用。

## Docker 適合我嗎？

- **是**：您想要隔離的、可丟棄的 Gateway 環境或在無本機安裝的主機上執行 OpenClaw。
- **否**：您在自己的機器上執行，只想要最快的開發迴圈。改用正常安裝流程。
- **沙盒備註**：Agent 沙盒也使用 Docker，但**不**需要完整 Gateway 在 Docker 中執行。詳見 [沙盒隔離](/gateway/sandboxing)。

本指南涵蓋：

- 容器化 Gateway（完整 OpenClaw 在 Docker 中）
- 每會話 Agent 沙盒（主機 Gateway + Docker 隔離的 Agent 工具）

沙盒詳情：[沙盒隔離](/gateway/sandboxing)

## 需求

- Docker Desktop（或 Docker Engine）+ Docker Compose v2
- 足夠磁碟用於映像 + 日誌

## 容器化 Gateway（Docker Compose）

### 快速開始（建議）

從儲存庫根目錄：

```bash
./docker-setup.sh
```

此指令碼：

- 建置 Gateway 映像
- 執行引導精靈
- 列印可選的供應商設定提示
- 透過 Docker Compose 啟動 Gateway
- 生成 Gateway 令牌並寫入 `.env`

可選環境變數：

- `OPENCLAW_DOCKER_APT_PACKAGES` — 建置期間安裝額外 apt 套件
- `OPENCLAW_EXTRA_MOUNTS` — 新增額外主機綁定掛載
- `OPENCLAW_HOME_VOLUME` — 在命名 volume 中持久化 `/home/node`

完成後：

- 在瀏覽器開啟 `http://127.0.0.1:18789/`。
- 將令牌貼入 Control UI（設定 → 令牌）。

它在主機上寫入設定/工作區：

- `~/.openclaw/`
- `~/.openclaw/workspace`

在 VPS 上執行？詳見 [Hetzner（Docker VPS）](/platforms/hetzner)。

### 手動流程（Compose）

```bash
docker build -t openclaw:local -f Dockerfile .
docker compose run --rm openclaw-cli onboard
docker compose up -d openclaw-gateway
```

### 額外掛載（可選）

若要將額外主機目錄掛載至容器，執行 `docker-setup.sh` 前設定
`OPENCLAW_EXTRA_MOUNTS`。接受逗號分隔的 Docker 綁定掛載清單，透過生成 `docker-compose.extra.yml` 套用至 `openclaw-gateway` 和 `openclaw-cli`。

範例：

```bash
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

備註：

- 路徑必須與 macOS/Windows 上的 Docker Desktop 共享。
- 若編輯 `OPENCLAW_EXTRA_MOUNTS`，重新執行 `docker-setup.sh` 以重新生成額外 Compose 檔案。
- `docker-compose.extra.yml` 已生成。勿手動編輯。

### 持久化整個容器主目錄（可選）

若要讓 `/home/node` 在容器重建間持久化，透過 `OPENCLAW_HOME_VOLUME` 設定命名 volume。建立 Docker volume 並掛載至 `/home/node`，同時保持標準設定/工作區綁定掛載。此處使用命名 volume（非綁定路徑）；綁定掛載請使用 `OPENCLAW_EXTRA_MOUNTS`。

範例：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

可結合額外掛載：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

備註：

- 若變更 `OPENCLAW_HOME_VOLUME`，重新執行 `docker-setup.sh` 以重新生成額外 Compose 檔案。
- 命名 volume 持續存在直到用 `docker volume rm <name>` 移除。

### 安裝額外 apt 套件（可選）

若需映像內的系統套件（例如建置工具或媒體庫），執行 `docker-setup.sh` 前設定 `OPENCLAW_DOCKER_APT_PACKAGES`。在映像建置期間安裝套件，即使容器被刪除仍保持。

範例：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg build-essential"
./docker-setup.sh
```

備註：

- 接受空白分隔的 apt 套件名稱清單。
- 若變更 `OPENCLAW_DOCKER_APT_PACKAGES`，重新執行 `docker-setup.sh` 以重建映像。

### 進階使用者 / 功能完整容器（選用）

預設 Docker 映像是**安全優先**，執行為非 root `node` 使用者。降低攻擊面，但表示：

- 執行期無系統套件安裝
- 預設無 Homebrew
- 無內建 Chromium/Playwright 瀏覽器

若想更功能完整的容器，使用這些選用旋鈕：

1. **持久化 `/home/node`** 讓瀏覽器下載和工具快取存活：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

2. **將系統依賴烤入映像**（可重複 + 持久）：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="git curl jq"
./docker-setup.sh
```

3. **不使用 `npx` 安裝 Playwright 瀏覽器**（避免 npm override 衝突）：

```bash
docker compose run --rm openclaw-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

若 Playwright 需安裝系統依賴，改用 `OPENCLAW_DOCKER_APT_PACKAGES` 重建映像而非執行期 `--with-deps`。

4. **持久化 Playwright 瀏覽器下載**：

- 在 `docker-compose.yml` 中設定 `PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright`。
- 確保 `/home/node` 透過 `OPENCLAW_HOME_VOLUME` 持久化，或掛載 `/home/node/.cache/ms-playwright` 透過 `OPENCLAW_EXTRA_MOUNTS`。

### 權限 + EACCES

映像執行為 `node`（uid 1000）。若在 `/home/node/.openclaw` 看到權限錯誤，確保主機綁定掛載由 uid 1000 擁有。

範例（Linux 主機）：

```bash
sudo chown -R 1000:1000 /path/to/openclaw-config /path/to/openclaw-workspace
```

若選擇以 root 執行以方便，接受安全權衡。

### 加快重建（建議）

加快重建速度，排列 Dockerfile 讓依賴層被快取。避免重複執行 `pnpm install` 除非鎖定檔變更：

```dockerfile
FROM node:22-bookworm

# 安裝 Bun（建置指令碼所需）
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# 快取依賴除非套件中繼資料變更
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production

CMD ["node","dist/index.js"]
```

### 頻道設定（可選）

使用 CLI 容器設定頻道，必要時重啟 Gateway。

WhatsApp（QR）：

```bash
docker compose run --rm openclaw-cli channels login
```

Telegram（bot 令牌）：

```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "<token>"
```

Discord（bot 令牌）：

```bash
docker compose run --rm openclaw-cli channels add --channel discord --token "<token>"
```

文件：[WhatsApp](/channels/whatsapp)、[Telegram](/channels/telegram)、[Discord](/channels/discord)

### 健康檢查

```bash
docker compose exec openclaw-gateway node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

### E2E 煙霧測試（Docker）

```bash
scripts/e2e/onboard-docker.sh
```

### QR 匯入煙霧測試（Docker）

```bash
pnpm test:docker:qr
```

### 備註

- Gateway 綁定預設為 `lan` 用於容器使用。
- Gateway 容器是會話的真實來源（`~/.openclaw/agents/<agentId>/sessions/`）。

## Agent 沙盒（主機 Gateway + Docker 工具）

深入探討：[沙盒隔離](/gateway/sandboxing)

### 功能說明

啟用 `agents.defaults.sandbox` 時，**非主要會話**在 Docker 容器內執行工具。Gateway 保持在主機，但工具執行隔離：

- 範圍：`"agent"`（預設；每個 Agent 一個容器 + 工作區）
- 範圍：`"session"`（每會話隔離）
- 每範圍工作區資料夾掛載於 `/workspace`
- 可選 Agent 工作區存取（`agents.defaults.sandbox.workspaceAccess`）
- 允許/拒絕工具原則（拒絕優先）
- 入站媒體複製到活躍沙盒工作區（`media/inbound/*`）讓工具可讀取（`workspaceAccess: "rw"` 時進入 Agent 工作區）

警告：`scope: "shared"` 停用跨會話隔離。所有會話共享一個容器和一個工作區。

### 每 Agent 沙盒設定檔（多代理）

使用多代理路由，各 Agent 可覆蓋沙盒 + 工具設定：
`agents.list[].sandbox` 和 `agents.list[].tools`（加上 `agents.list[].tools.sandbox.tools`）。讓您在一個 Gateway 執行混合存取層級：

- 完整存取（個人 Agent）
- 唯讀工具 + 唯讀工作區（家庭/工作 Agent）
- 無檔案系統/shell 工具（公開 Agent）

詳見 [多代理沙盒與工具](/multi-agent-sandbox-tools) 取得範例、優先級與故障排除。

### 預設行為

- 映像：`openclaw-sandbox:bookworm-slim`
- 每個 Agent 一個容器
- Agent 工作區存取：`workspaceAccess: "none"`（預設）使用 `~/.openclaw/sandboxes`
  - `"ro"` 保持沙盒工作區於 `/workspace`，掛載 Agent 工作區唯讀於 `/agent`（停用 `write`/`edit`/`apply_patch`）
  - `"rw"` 掛載 Agent 工作區讀/寫於 `/workspace`
- 自動清理：閒置 > 24h 或年齡 > 7d
- 網路：預設 `none`（明確選用若需出口）
- 預設允許：`exec`、`process`、`read`、`write`、`edit`、`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- 預設拒絕：`browser`、`canvas`、`nodes`、`cron`、`discord`、`gateway`

### 啟用沙盒隔離

若計畫在 `setupCommand` 安裝套件，注意：

- 預設 `docker.network` 是 `"none"`（無出口）。
- `readOnlyRoot: true` 阻止套件安裝。
- `user` 必須是 root 用於 `apt-get`（省略 `user` 或設定 `user: "0:0"`）。
  OpenClaw 在 `setupCommand`（或 Docker 設定）變更時自動重建容器，
  除非容器**最近被使用**（~5 分鐘內）。熱容器記錄警告含確切 `openclaw sandbox recreate ...` 指令。

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // off | non-main | all
        scope: "agent", // session | agent | shared (agent 預設)
        workspaceAccess: "none", // none | ro | rw
        workspaceRoot: "~/.openclaw/sandboxes",
        docker: {
          image: "openclaw-sandbox:bookworm-slim",
          workdir: "/workspace",
          readOnlyRoot: true,
          tmpfs: ["/tmp", "/var/tmp", "/run"],
          network: "none",
          user: "1000:1000",
          capDrop: ["ALL"],
          env: { LANG: "C.UTF-8" },
          setupCommand: "apt-get update && apt-get install -y git curl jq",
          pidsLimit: 256,
          memory: "1g",
          memorySwap: "2g",
          cpus: 1,
          ulimits: {
            nofile: { soft: 1024, hard: 2048 },
            nproc: 256,
          },
          seccompProfile: "/path/to/seccomp.json",
          apparmorProfile: "openclaw-sandbox",
          dns: ["1.1.1.1", "8.8.8.8"],
          extraHosts: ["internal.service:10.0.0.5"],
        },
        prune: {
          idleHours: 24, // 0 停用閒置清理
          maxAgeDays: 7, // 0 停用最大年齡清理
        },
      },
    },
  },
  tools: {
    sandbox: {
      tools: {
        allow: [
          "exec",
          "process",
          "read",
          "write",
          "edit",
          "sessions_list",
          "sessions_history",
          "sessions_send",
          "sessions_spawn",
          "session_status",
        ],
        deny: ["browser", "canvas", "nodes", "cron", "discord", "gateway"],
      },
    },
  },
}
```

加固旋鈕位於 `agents.defaults.sandbox.docker`：
`network`、`user`、`pidsLimit`、`memory`、`memorySwap`、`cpus`、`ulimits`、
`seccompProfile`、`apparmorProfile`、`dns`、`extraHosts`。

多代理：透過 `agents.list[].sandbox.{docker,browser,prune}.*` 覆蓋 `agents.defaults.sandbox.{docker,browser,prune}.*` 每 Agent
（`agents.defaults.sandbox.scope` / `agents.list[].sandbox.scope` 為 `"shared"` 時忽略）。

### 建置預設沙盒映像

```bash
scripts/sandbox-setup.sh
```

使用 `Dockerfile.sandbox` 建置 `openclaw-sandbox:bookworm-slim`。

### 沙盒通用映像（可選）

若想沙盒映像含通用建置工具（Node、Go、Rust 等），建置通用映像：

```bash
scripts/sandbox-common-setup.sh
```

建置 `openclaw-sandbox-common:bookworm-slim`。使用時：

```json5
{
  agents: {
    defaults: {
      sandbox: { docker: { image: "openclaw-sandbox-common:bookworm-slim" } },
    },
  },
}
```

### 沙盒瀏覽器映像

執行沙盒內瀏覽器工具，建置瀏覽器映像：

```bash
scripts/sandbox-browser-setup.sh
```

使用 `Dockerfile.sandbox-browser` 建置 `openclaw-sandbox-browser:bookworm-slim`。容器執行 Chromium 啟用 CDP 和可選 noVNC 觀察者（headful via Xvfb）。

備註：

- Headful（Xvfb）降低 bot 阻止相比 headless。
- Headless 仍可用設定 `agents.defaults.sandbox.browser.headless=true`。
- 無需完整桌面環境（GNOME）；Xvfb 提供顯示。

使用設定：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        browser: { enabled: true },
      },
    },
  },
}
```

自訂瀏覽器映像：

```json5
{
  agents: {
    defaults: {
      sandbox: { browser: { image: "my-openclaw-browser" } },
    },
  },
}
```

啟用時，Agent 接收：

- 沙盒瀏覽器控制 URL（用於 `browser` 工具）
- noVNC URL（若啟用且 headless=false）

記住：使用工具允許清單，新增 `browser`（並從拒絕移除）或工具保持被阻止。
清理規則（`agents.defaults.sandbox.prune`）也套用至瀏覽器容器。

### 自訂沙盒映像

建置自己的映像並指向設定：

```bash
docker build -t my-openclaw-sbx -f Dockerfile.sandbox .
```

```json5
{
  agents: {
    defaults: {
      sandbox: { docker: { image: "my-openclaw-sbx" } },
    },
  },
}
```

### 工具原則（允許/拒絕）

- `deny` 優先於 `allow`。
- 若 `allow` 為空：所有工具（除拒絕）可用。
- 若 `allow` 非空：僅 `allow` 中的工具可用（減去拒絕）。

### 清理策略

兩個旋鈕：

- `prune.idleHours`：移除未在 X 小時內使用的容器（0 = 停用）
- `prune.maxAgeDays`：移除超過 X 天的容器（0 = 停用）

範例：

- 保持忙碌會話但上限生命週期：
  `idleHours: 24`、`maxAgeDays: 7`
- 絕不清理：
  `idleHours: 0`、`maxAgeDays: 0`

### 安全備註

- 硬牆只套用至**工具**（exec/read/write/edit/apply_patch）。
- 僅主機工具如瀏覽器/相機/Canvas 預設被阻止。
- 允許沙盒內 `browser` **破壞隔離**（瀏覽器執行於主機）。

## 故障排除

- 映像遺漏：用 [`scripts/sandbox-setup.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/sandbox-setup.sh) 建置或設定 `agents.defaults.sandbox.docker.image`。
- 容器未執行：依需求自動建立每會話。
- 沙盒權限錯誤：設定 `docker.user` 為 UID:GID 符合掛載工作區所有權（或 chown 工作區資料夾）。
- 自訂工具未找到：OpenClaw 用 `sh -lc` 執行指令（登入 shell），源於 `/etc/profile` 且可能重設 PATH。設定 `docker.env.PATH` 預加自訂工具路徑（例如 `/custom/bin:/usr/local/share/npm-global/bin`），或在 Dockerfile 內 `/etc/profile.d/` 下新增指令碼。
