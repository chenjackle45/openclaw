---
title: "Docker(Docker 可選)"
summary: "OpenClaw 的可選 Docker 設定和引導設定"
read_when:
  - 您想要容器化 Gateway 而不是本機安裝
  - 您正在驗證 Docker 流程
---

# Docker（可選）

Docker 是**可選的**。僅在您想要容器化 Gateway 或驗證 Docker 流程時使用。

## Docker 適合我嗎？

- **是**：您想要一個隔離的、可丟棄的 Gateway 環境或在沒有本機安裝的主機上運行 OpenClaw。
- **否**：您在自己的機器上運行，只想要最快的開發循環。請改用正常安裝流程。
- **沙盒備註**：代理沙盒也使用 Docker，但它**不**需要完整的 Gateway 在 Docker 中運行。請參閱 [沙盒](/gateway/sandboxing)。

本指南涵蓋：
- 容器化 Gateway（完整 OpenClaw 在 Docker 中）
- 每會話代理沙盒（主機 Gateway + Docker 隔離的代理工具）

沙盒詳情：[沙盒](/gateway/sandboxing)

## 需求

- Docker Desktop（或 Docker Engine）+ Docker Compose v2
- 足夠的磁碟空間用於映像 + 日誌

## 容器化 Gateway（Docker Compose）

### 快速開始（建議）

從儲存庫根目錄：

```bash
./docker-setup.sh
```

此腳本：
- 建置 Gateway 映像
- 運行引導精靈
- 列印可選的供應商設定提示
- 透過 Docker Compose 啟動 Gateway
- 生成 Gateway 令牌並寫入 `.env`

可選環境變數：
- `OPENCLAW_DOCKER_APT_PACKAGES` — 在建置期間安裝額外的 apt 套件
- `OPENCLAW_EXTRA_MOUNTS` — 新增額外的主機綁定掛載
- `OPENCLAW_HOME_VOLUME` — 在命名 volume 中持久化 `/home/node`

完成後：
- 在瀏覽器中開啟 `http://127.0.0.1:18789/`。
- 將令牌貼到 Control UI（設定 → 令牌）。

它在主機上寫入設定/工作區：
- `~/.openclaw/`
- `~/.openclaw/workspace`

在 VPS 上運行？請參閱 [Hetzner (Docker VPS)](/platforms/hetzner)。

### 手動流程（compose）

```bash
docker build -t openclaw:local -f Dockerfile .
docker compose run --rm openclaw-cli onboard
docker compose up -d openclaw-gateway
```

### 額外掛載（可選）

如果您想將額外的主機目錄掛載到容器中，請在運行 `docker-setup.sh` 之前設定 `OPENCLAW_EXTRA_MOUNTS`。這接受逗號分隔的 Docker 綁定掛載列表，並透過生成 `docker-compose.extra.yml` 將它們套用於 `openclaw-gateway` 和 `openclaw-cli`。

範例：

```bash
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

備註：
- 路徑必須與 macOS/Windows 上的 Docker Desktop 共享。
- 如果您編輯 `OPENCLAW_EXTRA_MOUNTS`，請重新運行 `docker-setup.sh` 以重新生成額外的 compose 檔案。
- `docker-compose.extra.yml` 是生成的。不要手動編輯它。

### 持久化整個容器主目錄（可選）

如果您想讓 `/home/node` 在容器重建之間持久化，請透過 `OPENCLAW_HOME_VOLUME` 設定命名 volume。這會建立一個 Docker volume 並將其掛載到 `/home/node`，同時保持標準的設定/工作區綁定掛載。這裡使用命名 volume（不是綁定路徑）；對於綁定掛載，使用 `OPENCLAW_EXTRA_MOUNTS`。

範例：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

您可以將其與額外掛載結合：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

備註：
- 如果您更改 `OPENCLAW_HOME_VOLUME`，請重新運行 `docker-setup.sh` 以重新生成額外的 compose 檔案。
- 命名 volume 會持久化直到使用 `docker volume rm <name>` 移除。

### 安裝額外的 apt 套件（可選）

如果您需要映像內的系統套件（例如建置工具或媒體庫），請在運行 `docker-setup.sh` 之前設定 `OPENCLAW_DOCKER_APT_PACKAGES`。這會在映像建置期間安裝套件，因此即使容器被刪除它們也會持久化。

範例：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg build-essential"
./docker-setup.sh
```

備註：
- 這接受空格分隔的 apt 套件名稱列表。
- 如果您更改 `OPENCLAW_DOCKER_APT_PACKAGES`，請重新運行 `docker-setup.sh` 以重建映像。

### 更快的重建（建議）

為加速重建，請排序您的 Dockerfile 以便依賴層被快取。這避免了除非 lockfile 更改否則重新運行 `pnpm install`：

```dockerfile
FROM node:22-bookworm

# 安裝 Bun（建置腳本所需）
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# 快取依賴除非套件元資料更改
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

使用 CLI 容器設定頻道，然後在需要時重啟 Gateway。

WhatsApp（QR）：
```bash
docker compose run --rm openclaw-cli channels login
```

Telegram（機器人令牌）：
```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "<token>"
```

Discord（機器人令牌）：
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

## 代理沙盒（主機 Gateway + Docker 工具）

深入了解：[沙盒](/gateway/sandboxing)

### 它做什麼

當 `agents.defaults.sandbox` 啟用時，**非主會話**會在 Docker 容器內運行工具。Gateway 保持在您的主機上，但工具執行是隔離的：
- 範圍：預設 `"agent"`（每個代理一個容器 + 工作區）
- 範圍：`"session"` 用於每會話隔離
- 每範圍工作區資料夾掛載於 `/workspace`
- 可選的代理工作區存取（`agents.defaults.sandbox.workspaceAccess`）
- 允許/拒絕工具策略（拒絕優先）
- 入站媒體會複製到活動沙盒工作區（`media/inbound/*`）以便工具可以讀取（使用 `workspaceAccess: "rw"` 時，這會落在代理工作區）

警告：`scope: "shared"` 停用跨會話隔離。所有會話共享一個容器和一個工作區。

### 每代理沙盒設定檔（多代理）

如果您使用多代理路由，每個代理可以覆寫沙盒 + 工具設定：`agents.list[].sandbox` 和 `agents.list[].tools`（加上 `agents.list[].tools.sandbox.tools`）。這讓您可以在一個 Gateway 中運行混合存取級別：
- 完全存取（個人代理）
- 唯讀工具 + 唯讀工作區（家庭/工作代理）
- 無檔案系統/shell 工具（公開代理）

請參閱 [多代理沙盒與工具](/multi-agent-sandbox-tools) 了解範例、優先順序和疑難排解。

### 預設行為

- 映像：`openclaw-sandbox:bookworm-slim`
- 每個代理一個容器
- 代理工作區存取：`workspaceAccess: "none"`（預設）使用 `~/.openclaw/sandboxes`
  - `"ro"` 將沙盒工作區保持在 `/workspace` 並將代理工作區唯讀掛載於 `/agent`（停用 `write`/`edit`/`apply_patch`）
  - `"rw"` 將代理工作區讀寫掛載於 `/workspace`
- 自動清理：閒置 > 24 小時或年齡 > 7 天
- 網路：預設 `none`（如有需要明確選擇加入出口）
- 預設允許：`exec`、`process`、`read`、`write`、`edit`、`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- 預設拒絕：`browser`、`canvas`、`nodes`、`cron`、`discord`、`gateway`

### 啟用沙盒

如果您計劃在 `setupCommand` 中安裝套件，請注意：
- 預設 `docker.network` 是 `"none"`（無出口）。
- `readOnlyRoot: true` 阻止套件安裝。
- `user` 必須是 root 才能使用 `apt-get`（省略 `user` 或設定 `user: "0:0"`）。
當 `setupCommand`（或 docker 設定）更改時，OpenClaw 會自動重建容器，除非容器**最近使用**（約 5 分鐘內）。熱容器會記錄帶有確切 `openclaw sandbox recreate ...` 命令的警告。

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // off | non-main | all
        scope: "agent", // session | agent | shared（agent 是預設）
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
            nproc: 256
          },
          seccompProfile: "/path/to/seccomp.json",
          apparmorProfile: "openclaw-sandbox",
          dns: ["1.1.1.1", "8.8.8.8"],
          extraHosts: ["internal.service:10.0.0.5"]
        },
        prune: {
          idleHours: 24, // 0 停用閒置清理
          maxAgeDays: 7  // 0 停用最大年齡清理
        }
      }
    }
  },
  tools: {
    sandbox: {
      tools: {
        allow: ["exec", "process", "read", "write", "edit", "sessions_list", "sessions_history", "sessions_send", "sessions_spawn", "session_status"],
        deny: ["browser", "canvas", "nodes", "cron", "discord", "gateway"]
      }
    }
  }
}
```

加固選項位於 `agents.defaults.sandbox.docker` 下：`network`、`user`、`pidsLimit`、`memory`、`memorySwap`、`cpus`、`ulimits`、`seccompProfile`、`apparmorProfile`、`dns`、`extraHosts`。

多代理：透過 `agents.list[].sandbox.{docker,browser,prune}.*` 按代理覆寫 `agents.defaults.sandbox.{docker,browser,prune}.*`（當 `agents.defaults.sandbox.scope` / `agents.list[].sandbox.scope` 是 `"shared"` 時忽略）。

### 建置預設沙盒映像

```bash
scripts/sandbox-setup.sh
```

這使用 `Dockerfile.sandbox` 建置 `openclaw-sandbox:bookworm-slim`。

### 沙盒通用映像（可選）
如果您想要帶有通用建置工具（Node、Go、Rust 等）的沙盒映像，建置通用映像：

```bash
scripts/sandbox-common-setup.sh
```

這建置 `openclaw-sandbox-common:bookworm-slim`。使用方式：

```json5
{
  agents: { defaults: { sandbox: { docker: { image: "openclaw-sandbox-common:bookworm-slim" } } } }
}
```

### 沙盒瀏覽器映像

要在沙盒內運行瀏覽器工具，建置瀏覽器映像：

```bash
scripts/sandbox-browser-setup.sh
```

這使用 `Dockerfile.sandbox-browser` 建置 `openclaw-sandbox-browser:bookworm-slim`。容器運行已啟用 CDP 的 Chromium 和可選的 noVNC 觀察器（透過 Xvfb 有頭）。

備註：
- 有頭（Xvfb）比無頭減少機器人阻擋。
- 無頭仍可透過設定 `agents.defaults.sandbox.browser.headless=true` 使用。
- 不需要完整桌面環境（GNOME）；Xvfb 提供顯示。

使用設定：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        browser: { enabled: true }
      }
    }
  }
}
```

自訂瀏覽器映像：

```json5
{
  agents: {
    defaults: {
      sandbox: { browser: { image: "my-openclaw-browser" } }
    }
  }
}
```

啟用時，代理收到：
- 沙盒瀏覽器控制 URL（用於 `browser` 工具）
- noVNC URL（如果啟用且 headless=false）

記住：如果您對工具使用允許清單，請新增 `browser`（並從拒絕中移除），否則工具仍被阻擋。
清理規則（`agents.defaults.sandbox.prune`）也適用於瀏覽器容器。

### 自訂沙盒映像

建置您自己的映像並將設定指向它：

```bash
docker build -t my-openclaw-sbx -f Dockerfile.sandbox .
```

```json5
{
  agents: {
    defaults: {
      sandbox: { docker: { image: "my-openclaw-sbx" } }
    }
  }
}
```

### 工具策略（允許/拒絕）

- `deny` 優先於 `allow`。
- 如果 `allow` 為空：所有工具（除了 deny）可用。
- 如果 `allow` 非空：只有 `allow` 中的工具可用（減去 deny）。

### 清理策略

兩個選項：
- `prune.idleHours`：移除 X 小時未使用的容器（0 = 停用）
- `prune.maxAgeDays`：移除 X 天以上的容器（0 = 停用）

範例：
- 保持繁忙會話但限制生命週期：
  `idleHours: 24`、`maxAgeDays: 7`
- 從不清理：
  `idleHours: 0`、`maxAgeDays: 0`

### 安全備註

- 硬牆僅適用於**工具**（exec/read/write/edit/apply_patch）。
- 主機專用工具如 browser/camera/canvas 預設被阻擋。
- 在沙盒中允許 `browser` **會破壞隔離**（瀏覽器在主機上運行）。

## 疑難排解

- 映像缺失：使用 [`scripts/sandbox-setup.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/sandbox-setup.sh) 建置或設定 `agents.defaults.sandbox.docker.image`。
- 容器未運行：它會按需每會話自動建立。
- 沙盒中的權限錯誤：將 `docker.user` 設為與掛載的工作區所有權匹配的 UID:GID（或 chown 工作區資料夾）。
- 找不到自訂工具：OpenClaw 使用 `sh -lc`（登入 shell）運行命令，這會載入 `/etc/profile` 並可能重設 PATH。設定 `docker.env.PATH` 以前置您的自訂工具路徑（例如 `/custom/bin:/usr/local/share/npm-global/bin`），或在您的 Dockerfile 中在 `/etc/profile.d/` 下新增腳本。
