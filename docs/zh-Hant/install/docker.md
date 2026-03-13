---
summary: "選用的 Docker 式設定與 OpenClaw 引導設定"
read_when:
  - 您想要容器化的 Gateway 而非本機安裝
  - 您正在驗證 Docker 流程
title: "Docker"
---

# Docker（選用）

Docker 是**選用的**。只有在您想要容器化的 Gateway 或要驗證 Docker 流程時才使用它。

## Docker 適合我嗎？

- **是**：您想要一個隔離的、可拋棄的 Gateway 環境，或在沒有本機安裝的主機上執行 OpenClaw。
- **否**：您在自己的機器上執行，只是想要最快的開發迴圈。請改用正常的安裝流程。
- **沙箱注意事項**：Agent 沙箱也使用 Docker，但它**不**要求完整的 Gateway 在 Docker 中執行。請參閱[沙箱](/zh-Hant/gateway/sandboxing)。

本指南涵蓋：

- 容器化 Gateway（完整的 OpenClaw 在 Docker 中）
- 每對話 Agent 沙箱（主機 Gateway + Docker 隔離的 Agent 工具）

沙箱詳情：[沙箱](/zh-Hant/gateway/sandboxing)

## 需求

- Docker Desktop（或 Docker Engine）+ Docker Compose v2
- 映像建置至少需要 2 GB RAM（`pnpm install` 可能在 1 GB 主機上因退出碼 137 而被 OOM 終止）
- 足夠的磁碟空間用於映像 + 日誌
- 如果在 VPS/公共主機上執行，請檢閱[網路暴露的安全強化](/zh-Hant/gateway/security#04-network-exposure-bind--port--firewall)，特別是 Docker `DOCKER-USER` 防火牆策略。

## 容器化 Gateway（Docker Compose）

### 快速開始（建議）

<Note>
Docker 此處的預設值假設繫結模式（`lan`/`loopback`），而非主機別名。在 `gateway.bind` 中使用繫結模式值（例如 `lan` 或 `loopback`），而非主機別名，如 `0.0.0.0` 或 `localhost`。
</Note>

從儲存庫根目錄：

```bash
./docker-setup.sh
```

此腳本：

- 在本機建置 Gateway 映像（或者如果設定了 `OPENCLAW_IMAGE` 則拉取遠端映像）
- 執行引導精靈
- 列印選用的 Provider 設定提示
- 透過 Docker Compose 啟動 Gateway
- 產生 Gateway Token 並將其寫入 `.env`

選用的環境變數：

- `OPENCLAW_IMAGE` — 使用遠端映像而非在本機建置（例如 `ghcr.io/openclaw/openclaw:latest`）
- `OPENCLAW_DOCKER_APT_PACKAGES` — 在建置期間安裝額外的 apt 套件
- `OPENCLAW_EXTENSIONS` — 在建置時預先安裝擴充功能相依項（以空格分隔的擴充功能名稱，例如 `diagnostics-otel matrix`）
- `OPENCLAW_EXTRA_MOUNTS` — 新增額外的主機繫結掛載
- `OPENCLAW_HOME_VOLUME` — 將 `/home/node` 持久化在具名磁碟區中
- `OPENCLAW_SANDBOX` — 選擇加入 Docker Gateway 沙箱啟動。只有明確的真值才能啟用：`1`、`true`、`yes`、`on`
- `OPENCLAW_INSTALL_DOCKER_CLI` — 本機映像建置的建置參數傳遞（`1` 在映像中安裝 Docker CLI）。`docker-setup.sh` 在本機建置的 `OPENCLAW_SANDBOX=1` 時會自動設定此項。
- `OPENCLAW_DOCKER_SOCKET` — 覆寫 Docker socket 路徑（預設：`DOCKER_HOST=unix://...` 路徑，否則為 `/var/run/docker.sock`）
- `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1` — 緊急措施：允許受信任私人網路的 `ws://` 目標用於 CLI/引導用戶端路徑（預設僅限回環）
- `OPENCLAW_BROWSER_DISABLE_GRAPHICS_FLAGS=0` — 在您需要 WebGL/3D 相容性時停用容器瀏覽器強化旗標 `--disable-3d-apis`、`--disable-software-rasterizer`、`--disable-gpu`
- `OPENCLAW_BROWSER_DISABLE_EXTENSIONS=0` — 在瀏覽器流程需要時保持擴充功能啟用（預設在沙箱瀏覽器中停用擴充功能）
- `OPENCLAW_BROWSER_RENDERER_PROCESS_LIMIT=<N>` — 設定 Chromium 渲染器行程限制；設定為 `0` 以跳過旗標並使用 Chromium 預設行為

完成後：

- 在瀏覽器中開啟 `http://127.0.0.1:18789/`。
- 將 Token 貼入控制 UI（設定 → token）。
- 需要再次查看 URL？執行 `docker compose run --rm openclaw-cli dashboard --no-open`。

### 為 Docker Gateway 啟用 Agent 沙箱（選擇加入）

`docker-setup.sh` 也可以為 Docker 部署啟動 `agents.defaults.sandbox.*`。

使用以下方式啟用：

```bash
export OPENCLAW_SANDBOX=1
./docker-setup.sh
```

自訂 socket 路徑（例如無根 Docker）：

```bash
export OPENCLAW_SANDBOX=1
export OPENCLAW_DOCKER_SOCKET=/run/user/1000/docker.sock
./docker-setup.sh
```

注意：

- 只有在沙箱前提條件通過後，腳本才會掛載 `docker.sock`。
- 如果沙箱設定無法完成，腳本會重設 `agents.defaults.sandbox.mode` 為 `off`，以避免重新執行時出現過時/損壞的沙箱設定。
- 如果 `Dockerfile.sandbox` 遺失，腳本會列印警告並繼續；如需要，使用 `scripts/sandbox-setup.sh` 建置 `openclaw-sandbox:bookworm-slim`。
- 對於非本機的 `OPENCLAW_IMAGE` 值，映像必須已包含 Docker CLI 支援以執行沙箱。

### 自動化/CI（非互動式，無 TTY 雜訊）

對於腳本和 CI，使用 `-T` 停用 Compose 偽 TTY 配置：

```bash
docker compose run -T --rm openclaw-cli gateway probe
docker compose run -T --rm openclaw-cli devices list --json
```

如果您的自動化不匯出任何 Claude 對話變數，將它們保持未設定狀態現在在 `docker-compose.yml` 中預設解析為空值，以避免重複的「variable is not set」警告。

### 共享網路安全注意事項（CLI + Gateway）

`openclaw-cli` 使用 `network_mode: "service:openclaw-gateway"`，以便 CLI 指令可以在 Docker 中透過 `127.0.0.1` 可靠地連線到 Gateway。

將此視為共享信任邊界：回環繫結在這兩個容器之間不是隔離。如果您需要更強的分離，請從獨立的容器/主機網路路徑執行指令，而非使用捆綁的 `openclaw-cli` 服務。

為了減少 CLI 行程被攻擊時的影響，compose 設定在 `openclaw-cli` 上放棄 `NET_RAW`/`NET_ADMIN` 並啟用 `no-new-privileges`。

它在主機上寫入設定/工作區：

- `~/.openclaw/`
- `~/.openclaw/workspace`

在 VPS 上執行？請參閱 [Hetzner（Docker VPS）](/zh-Hant/install/hetzner)。

### 使用遠端映像（跳過本機建置）

官方預建映像發佈於：

- [GitHub Container Registry 套件](https://github.com/openclaw/openclaw/pkgs/container/openclaw)

使用映像名稱 `ghcr.io/openclaw/openclaw`（不是類似名稱的 Docker Hub 映像）。

常見標籤：

- `main` — 來自 `main` 的最新建置
- `<version>` — 版本標籤建置（例如 `2026.2.26`）
- `latest` — 最新的穩定版本標籤

### 基礎映像元資料

主要 Docker 映像目前使用：

- `node:24-bookworm`

Docker 映像現在發佈 OCI 基礎映像標註（sha256 是範例，指向該標籤的已固定多架構清單）：

- `org.opencontainers.image.base.name=docker.io/library/node:24-bookworm`
- `org.opencontainers.image.base.digest=sha256:3a09aa6354567619221ef6c45a5051b671f953f0a1924d1f819ffb236e520e6b`
- `org.opencontainers.image.source=https://github.com/openclaw/openclaw`
- `org.opencontainers.image.url=https://openclaw.ai`
- `org.opencontainers.image.documentation=https://docs.openclaw.ai/install/docker`
- `org.opencontainers.image.licenses=MIT`
- `org.opencontainers.image.title=OpenClaw`
- `org.opencontainers.image.description=OpenClaw gateway and CLI runtime container image`
- `org.opencontainers.image.revision=<git-sha>`
- `org.opencontainers.image.version=<tag-or-main>`
- `org.opencontainers.image.created=<rfc3339 timestamp>`

參考：[OCI 映像標註](https://github.com/opencontainers/image-spec/blob/main/annotations.md)

版本背景：此儲存庫的帶標籤歷史記錄已在 `v2026.2.22` 和更早的 2026 標籤（例如 `v2026.2.21`、`v2026.2.9`）中使用 Bookworm。

預設情況下，設定腳本會從來源建置映像。要改為拉取預建映像，請在執行腳本前設定 `OPENCLAW_IMAGE`：

```bash
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
./docker-setup.sh
```

腳本偵測到 `OPENCLAW_IMAGE` 不是預設的 `openclaw:local` 並執行 `docker pull` 而非 `docker build`。其他一切（引導、Gateway 啟動、Token 產生）的運作方式相同。

`docker-setup.sh` 仍然從儲存庫根目錄執行，因為它使用本機的 `docker-compose.yml` 和輔助檔案。`OPENCLAW_IMAGE` 跳過本機映像建置時間；它不取代 compose/設定工作流程。

### Shell 輔助程式（選用）

為了更輕鬆的日常 Docker 管理，請安裝 `ClawDock`：

```bash
mkdir -p ~/.clawdock && curl -sL https://raw.githubusercontent.com/openclaw/openclaw/main/scripts/shell-helpers/clawdock-helpers.sh -o ~/.clawdock/clawdock-helpers.sh
```

**新增到您的 shell 設定（zsh）：**

```bash
echo 'source ~/.clawdock/clawdock-helpers.sh' >> ~/.zshrc && source ~/.zshrc
```

然後使用 `clawdock-start`、`clawdock-stop`、`clawdock-dashboard` 等。執行 `clawdock-help` 查看所有指令。

請參閱 [`ClawDock` 輔助程式 README](https://github.com/openclaw/openclaw/blob/main/scripts/shell-helpers/README.md) 了解詳情。

### 手動流程（compose）

```bash
docker build -t openclaw:local -f Dockerfile .
docker compose run --rm openclaw-cli onboard
docker compose up -d openclaw-gateway
```

注意：從儲存庫根目錄執行 `docker compose ...`。如果您啟用了 `OPENCLAW_EXTRA_MOUNTS` 或 `OPENCLAW_HOME_VOLUME`，設定腳本會寫入 `docker-compose.extra.yml`；在其他地方執行 Compose 時包含它：

```bash
docker compose -f docker-compose.yml -f docker-compose.extra.yml <command>
```

### 控制 UI Token + 配對（Docker）

如果您看到「unauthorized」或「disconnected (1008): pairing required」，請取得新的儀表板連結並核准瀏覽器裝置：

```bash
docker compose run --rm openclaw-cli dashboard --no-open
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve <requestId>
```

更多詳情：[儀表板](/zh-Hant/web/dashboard)、[裝置](/zh-Hant/cli/devices)。

### 額外掛載（選用）

如果您想將額外的主機目錄掛載到容器中，請在執行 `docker-setup.sh` 前設定 `OPENCLAW_EXTRA_MOUNTS`。這接受以逗號分隔的 Docker 繫結掛載列表，並透過產生 `docker-compose.extra.yml` 將它們應用於 `openclaw-gateway` 和 `openclaw-cli`。

範例：

```bash
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

注意：

- 路徑必須在 macOS/Windows 上與 Docker Desktop 共享。
- 每個條目必須是 `source:target[:options]`，沒有空格、Tab 或換行。
- 如果您編輯 `OPENCLAW_EXTRA_MOUNTS`，請重新執行 `docker-setup.sh` 以重新產生額外的 compose 檔案。
- `docker-compose.extra.yml` 是產生的。不要手動編輯它。

### 持久化整個容器主目錄（選用）

如果您想讓 `/home/node` 在容器重建後持久化，請透過 `OPENCLAW_HOME_VOLUME` 設定具名磁碟區。這建立一個 Docker 磁碟區並將其掛載在 `/home/node`，同時保留標準設定/工作區繫結掛載。此處使用具名磁碟區（不是繫結路徑）；對於繫結掛載，請使用 `OPENCLAW_EXTRA_MOUNTS`。

範例：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

您可以將此與額外掛載結合：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

注意：

- 具名磁碟區必須符合 `^[A-Za-z0-9][A-Za-z0-9_.-]*$`。
- 如果您變更 `OPENCLAW_HOME_VOLUME`，請重新執行 `docker-setup.sh` 以重新產生額外的 compose 檔案。
- 具名磁碟區在使用 `docker volume rm <name>` 移除之前持續存在。

### 安裝額外的 apt 套件（選用）

如果您在映像中需要系統套件（例如建置工具或媒體函式庫），請在執行 `docker-setup.sh` 前設定 `OPENCLAW_DOCKER_APT_PACKAGES`。這在映像建置期間安裝套件，因此即使容器被刪除也會持續存在。

範例：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg build-essential"
./docker-setup.sh
```

注意：

- 這接受以空格分隔的 apt 套件名稱列表。
- 如果您變更 `OPENCLAW_DOCKER_APT_PACKAGES`，請重新執行 `docker-setup.sh` 以重建映像。

### 預先安裝擴充功能相依項（選用）

具有自己 `package.json` 的擴充功能（例如 `diagnostics-otel`、`matrix`、`msteams`）在首次載入時安裝其 npm 相依項。要將這些相依項烘焙到映像中，請在執行 `docker-setup.sh` 前設定 `OPENCLAW_EXTENSIONS`：

```bash
export OPENCLAW_EXTENSIONS="diagnostics-otel matrix"
./docker-setup.sh
```

或在直接建置時：

```bash
docker build --build-arg OPENCLAW_EXTENSIONS="diagnostics-otel matrix" .
```

注意：

- 這接受以空格分隔的擴充功能目錄名稱列表（在 `extensions/` 下）。
- 只有具有 `package.json` 的擴充功能受到影響；沒有 package.json 的輕量外掛程式被忽略。
- 如果您變更 `OPENCLAW_EXTENSIONS`，請重新執行 `docker-setup.sh` 以重建映像。

### 進階使用者 / 全功能容器（選擇加入）

預設 Docker 映像是**安全優先的**，以非根使用者 `node` 執行。這使攻擊面小，但這意味著：

- 執行時無法安裝系統套件
- 預設不含 Homebrew
- 不含捆綁的 Chromium/Playwright 瀏覽器

如果您想要更全功能的容器，請使用這些選擇加入的調整：

1. **持久化 `/home/node`**，使瀏覽器下載和工具快取能夠存活：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

2. **將系統相依項烘焙到映像中**（可重複 + 持久化）：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="git curl jq"
./docker-setup.sh
```

3. **不使用 `npx` 安裝 Playwright 瀏覽器**（避免 npm 覆寫衝突）：

```bash
docker compose run --rm openclaw-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

如果您需要 Playwright 安裝系統相依項，請改用 `OPENCLAW_DOCKER_APT_PACKAGES` 重建映像，而非在執行時使用 `--with-deps`。

4. **持久化 Playwright 瀏覽器下載**：

- 在 `docker-compose.yml` 中設定 `PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright`。
- 確保 `/home/node` 透過 `OPENCLAW_HOME_VOLUME` 持久化，或透過 `OPENCLAW_EXTRA_MOUNTS` 掛載 `/home/node/.cache/ms-playwright`。

### 權限 + EACCES

映像以 `node`（uid 1000）執行。如果您在 `/home/node/.openclaw` 上看到權限錯誤，請確保您的主機繫結掛載由 uid 1000 擁有。

範例（Linux 主機）：

```bash
sudo chown -R 1000:1000 /path/to/openclaw-config /path/to/openclaw-workspace
```

如果您選擇以根使用者執行，您接受安全性的取捨。

### 更快的重建（建議）

為了加速重建，請將您的 Dockerfile 排序使相依層被快取。
這避免在鎖定檔案沒有變更的情況下重新執行 `pnpm install`：

```dockerfile
FROM node:24-bookworm

# 安裝 Bun（建置腳本需要）
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# 除非套件元資料變更，否則快取相依項
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

### Channel 設定（選用）

使用 CLI 容器設定 Channel，然後在需要時重新啟動 Gateway。

WhatsApp（QR）：

```bash
docker compose run --rm openclaw-cli channels login
```

Telegram（機器人 Token）：

```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "<token>"
```

Discord（機器人 Token）：

```bash
docker compose run --rm openclaw-cli channels add --channel discord --token "<token>"
```

文件：[WhatsApp](/zh-Hant/channels/whatsapp)、[Telegram](/zh-Hant/channels/telegram)、[Discord](/zh-Hant/channels/discord)

### OpenAI Codex OAuth（無頭 Docker）

如果您在精靈中選擇 OpenAI Codex OAuth，它會開啟一個瀏覽器 URL 並嘗試在 `http://127.0.0.1:1455/auth/callback` 上捕獲回調。在 Docker 或無頭設定中，該回調可能顯示瀏覽器錯誤。複製您登陸的完整重定向 URL 並貼回精靈以完成驗證。

### 健康狀態檢查

容器探針端點（不需要驗證）：

```bash
curl -fsS http://127.0.0.1:18789/healthz
curl -fsS http://127.0.0.1:18789/readyz
```

別名：`/health` 和 `/ready`。

`/healthz` 是「Gateway 行程正在執行」的淺層存活性探針。
`/readyz` 在啟動寬限期間保持就緒，然後只有在必需的受管 Channel 在寬限後仍然斷連或稍後斷連時才變為 `503`。

Docker 映像包含內建的 `HEALTHCHECK`，在後台 ping `/healthz`。簡單來說：Docker 持續檢查 OpenClaw 是否仍在回應。如果檢查持續失敗，Docker 將容器標記為 `unhealthy`，編排系統（Docker Compose 重啟策略、Swarm、Kubernetes 等）可以自動重啟或替換它。

已驗證的深度健康狀態快照（Gateway + Channel）：

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

### LAN 與回環（Docker Compose）

`docker-setup.sh` 預設 `OPENCLAW_GATEWAY_BIND=lan`，使主機存取 `http://127.0.0.1:18789` 可以與 Docker 連接埠發佈一起使用。

- `lan`（預設）：主機瀏覽器 + 主機 CLI 可以連線到已發佈的 Gateway 連接埠。
- `loopback`：只有容器網路命名空間內的行程才能直接連線到 Gateway；主機已發佈連接埠存取可能失敗。

設定腳本也在引導後固定 `gateway.mode=local`，使 Docker CLI 指令預設以本地回環為目標。

舊版設定注意事項：在 `gateway.bind` 中使用繫結模式值（`lan` / `loopback` / `custom` / `tailnet` / `auto`），而非主機別名（`0.0.0.0`、`127.0.0.1`、`localhost`、`::`、`::1`）。

如果您看到來自 Docker CLI 指令的 `Gateway target: ws://172.x.x.x:18789` 或重複的 `pairing required` 錯誤，請執行：

```bash
docker compose run --rm openclaw-cli config set gateway.mode local
docker compose run --rm openclaw-cli config set gateway.bind lan
docker compose run --rm openclaw-cli devices list --url ws://127.0.0.1:18789
```

### 注意事項

- Gateway 繫結預設為 `lan` 用於容器使用（`OPENCLAW_GATEWAY_BIND`）。
- Dockerfile CMD 使用 `--allow-unconfigured`；具有非 `local` 的 `gateway.mode` 的掛載設定仍然會啟動。覆寫 CMD 以強制執行護欄。
- Gateway 容器是對話的真實來源（`~/.openclaw/agents/<agentId>/sessions/`）。

### 儲存模型

- **持久化主機資料：** Docker Compose 將 `OPENCLAW_CONFIG_DIR` 繫結掛載到 `/home/node/.openclaw`，將 `OPENCLAW_WORKSPACE_DIR` 繫結掛載到 `/home/node/.openclaw/workspace`，因此這些路徑在容器替換後仍然存在。
- **短暫的沙箱 tmpfs：** 當啟用 `agents.defaults.sandbox` 時，沙箱容器對 `/tmp`、`/var/tmp` 和 `/run` 使用 `tmpfs`。這些掛載與頂層 Compose 堆疊分開，並隨沙箱容器消失。
- **磁碟增長熱點：** 注意 `media/`、`agents/<agentId>/sessions/sessions.json`、逐字稿 JSONL 檔案、`cron/runs/*.jsonl` 以及 `/tmp/openclaw/`（或您設定的 `logging.file`）下的滾動檔案日誌。如果您也在 Docker 之外執行 macOS 應用程式，其服務日誌是獨立的：`~/.openclaw/logs/gateway.log`、`~/.openclaw/logs/gateway.err.log` 和 `/tmp/openclaw/openclaw-gateway.log`。

## Agent 沙箱（主機 Gateway + Docker 工具）

深入探討：[沙箱](/zh-Hant/gateway/sandboxing)

### 功能說明

當啟用 `agents.defaults.sandbox` 時，**非主要對話**在 Docker 容器內執行工具。Gateway 保持在您的主機上，但工具執行是隔離的：

- 範圍：預設 `"agent"`（每個 Agent 一個容器 + 工作區）
- 範圍：`"session"` 用於每對話隔離
- 每個範圍的工作區資料夾掛載在 `/workspace`
- 選用的 Agent 工作區存取（`agents.defaults.sandbox.workspaceAccess`）
- 允許/拒絕工具策略（拒絕優先）
- 入站媒體被複製到活躍沙箱工作區（`media/inbound/*`），使工具可以讀取它（使用 `workspaceAccess: "rw"` 時，這會放置在 Agent 工作區中）

警告：`scope: "shared"` 停用跨對話隔離。所有對話共享一個容器和一個工作區。

### 每個 Agent 的沙箱設定檔（多 Agent）

如果您使用多 Agent 路由，每個 Agent 可以覆寫沙箱 + 工具設定：
`agents.list[].sandbox` 和 `agents.list[].tools`（加上 `agents.list[].tools.sandbox.tools`）。這讓您可以在一個 Gateway 中執行混合存取層級：

- 完全存取（個人 Agent）
- 唯讀工具 + 唯讀工作區（家庭/工作 Agent）
- 沒有檔案系統/shell 工具（公開 Agent）

請參閱[多 Agent 沙箱與工具](/zh-Hant/tools/multi-agent-sandbox-tools)以取得範例、優先順序和疑難排解。

### 預設行為

- 映像：`openclaw-sandbox:bookworm-slim`
- 每個 Agent 一個容器
- Agent 工作區存取：`workspaceAccess: "none"`（預設）使用 `~/.openclaw/sandboxes`
  - `"ro"` 將沙箱工作區保持在 `/workspace` 並以唯讀方式在 `/agent` 掛載 Agent 工作區（停用 `write`/`edit`/`apply_patch`）
  - `"rw"` 以讀/寫方式在 `/workspace` 掛載 Agent 工作區
- 自動修剪：閒置 > 24 小時或年齡 > 7 天
- 網路：預設 `none`（如果您需要對外流量，請明確選擇加入）
  - `host` 被封鎖。
  - `container:<id>` 預設被封鎖（命名空間加入風險）。
- 預設允許：`exec`、`process`、`read`、`write`、`edit`、`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- 預設拒絕：`browser`、`canvas`、`nodes`、`cron`、`discord`、`gateway`

### 啟用沙箱

如果您計劃在 `setupCommand` 中安裝套件，請注意：

- 預設 `docker.network` 是 `"none"`（無對外流量）。
- `docker.network: "host"` 被封鎖。
- `docker.network: "container:<id>"` 預設被封鎖。
- 緊急措施覆寫：`agents.defaults.sandbox.docker.dangerouslyAllowContainerNamespaceJoin: true`。
- `readOnlyRoot: true` 封鎖套件安裝。
- `user` 必須是根使用者才能使用 `apt-get`（省略 `user` 或設定 `user: "0:0"`）。
  OpenClaw 在 `setupCommand`（或 docker 設定）變更時自動重建容器，除非容器是**最近使用的**（在約 5 分鐘內）。熱容器會以確切的 `openclaw sandbox recreate ...` 指令記錄警告。

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // off | non-main | all
        scope: "agent", // session | agent | shared（agent 是預設值）
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
          idleHours: 24, // 0 停用閒置修剪
          maxAgeDays: 7, // 0 停用最大年齡修剪
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

強化調整位於 `agents.defaults.sandbox.docker` 下：
`network`、`user`、`pidsLimit`、`memory`、`memorySwap`、`cpus`、`ulimits`、
`seccompProfile`、`apparmorProfile`、`dns`、`extraHosts`、
`dangerouslyAllowContainerNamespaceJoin`（僅緊急措施）。

多 Agent：透過 `agents.list[].sandbox.{docker,browser,prune}.*` 為每個 Agent 覆寫 `agents.defaults.sandbox.{docker,browser,prune}.*`
（當 `agents.defaults.sandbox.scope` / `agents.list[].sandbox.scope` 是 `"shared"` 時忽略）。

### 建置預設沙箱映像

```bash
scripts/sandbox-setup.sh
```

這使用 `Dockerfile.sandbox` 建置 `openclaw-sandbox:bookworm-slim`。

### 沙箱通用映像（選用）

如果您想要一個帶有常用建置工具（Node、Go、Rust 等）的沙箱映像，請建置通用映像：

```bash
scripts/sandbox-common-setup.sh
```

這建置 `openclaw-sandbox-common:bookworm-slim`。要使用它：

```json5
{
  agents: {
    defaults: {
      sandbox: { docker: { image: "openclaw-sandbox-common:bookworm-slim" } },
    },
  },
}
```

### 沙箱瀏覽器映像

要在沙箱內執行瀏覽器工具，請建置瀏覽器映像：

```bash
scripts/sandbox-browser-setup.sh
```

這使用 `Dockerfile.sandbox-browser` 建置 `openclaw-sandbox-browser:bookworm-slim`。容器以啟用 CDP 和選用的 noVNC 觀察器（透過 Xvfb 的有頭模式）執行 Chromium。

注意：

- 有頭模式（Xvfb）比無頭模式更能減少機器人封鎖。
- 透過設定 `agents.defaults.sandbox.browser.headless=true` 仍然可以使用無頭模式。
- 不需要完整的桌面環境（GNOME）；Xvfb 提供顯示器。
- 瀏覽器容器預設使用專用的 Docker 網路（`openclaw-sandbox-browser`）而非全域的 `bridge`。
- 選用的 `agents.defaults.sandbox.browser.cdpSourceRange` 按 CIDR 限制容器邊緣 CDP 入口（例如 `172.21.0.1/32`）。
- noVNC 觀察器存取預設受密碼保護；OpenClaw 提供一個短期的觀察器 Token URL，該 URL 提供本地啟動頁面並將密碼保存在 URL 片段中（而非 URL 查詢）。
- 瀏覽器容器啟動預設對共享/容器工作負載是保守的，包括：
  - `--remote-debugging-address=127.0.0.1`
  - `--remote-debugging-port=<derived from OPENCLAW_BROWSER_CDP_PORT>`
  - `--user-data-dir=${HOME}/.chrome`
  - `--no-first-run`
  - `--no-default-browser-check`
  - `--disable-3d-apis`
  - `--disable-software-rasterizer`
  - `--disable-gpu`
  - `--disable-dev-shm-usage`
  - `--disable-background-networking`
  - `--disable-features=TranslateUI`
  - `--disable-breakpad`
  - `--disable-crash-reporter`
  - `--metrics-recording-only`
  - `--renderer-process-limit=2`
  - `--no-zygote`
  - `--disable-extensions`
  - 如果設定了 `agents.defaults.sandbox.browser.noSandbox`，也會附加 `--no-sandbox` 和 `--disable-setuid-sandbox`。
  - 上面三個圖形強化旗標是選用的。如果您的工作負載需要 WebGL/3D，請設定 `OPENCLAW_BROWSER_DISABLE_GRAPHICS_FLAGS=0` 以在沒有 `--disable-3d-apis`、`--disable-software-rasterizer` 和 `--disable-gpu` 的情況下執行。
  - 擴充功能行為由 `--disable-extensions` 控制，可以透過 `OPENCLAW_BROWSER_DISABLE_EXTENSIONS=0` 停用（啟用擴充功能）以用於依賴擴充功能的頁面或重度使用擴充功能的工作流程。
  - `--renderer-process-limit=2` 也可以透過 `OPENCLAW_BROWSER_RENDERER_PROCESS_LIMIT` 設定；設定 `0` 讓 Chromium 在瀏覽器並發需要調整時選擇其預設行程限制。

預設值在捆綁的映像中預設應用。如果您需要不同的 Chromium 旗標，請使用自訂瀏覽器映像並提供您自己的進入點。

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

啟用後，Agent 收到：

- 沙箱瀏覽器控制 URL（用於 `browser` 工具）
- noVNC URL（如果啟用且 headless=false）

記住：如果您對工具使用白名單，請新增 `browser`（並從拒絕中移除），否則工具仍然被封鎖。
修剪規則（`agents.defaults.sandbox.prune`）也適用於瀏覽器容器。

### 自訂沙箱映像

建置您自己的映像並將設定指向它：

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

### 工具策略（允許/拒絕）

- `deny` 優先於 `allow`。
- 如果 `allow` 為空：所有工具（除拒絕外）均可用。
- 如果 `allow` 非空：只有 `allow` 中的工具可用（減去拒絕）。

### 修剪策略

兩個調整：

- `prune.idleHours`：移除 X 小時內未使用的容器（0 = 停用）
- `prune.maxAgeDays`：移除超過 X 天的容器（0 = 停用）

範例：

- 保留繁忙的對話但限制生命週期：
  `idleHours: 24`、`maxAgeDays: 7`
- 永不修剪：
  `idleHours: 0`、`maxAgeDays: 0`

### 安全注意事項

- 硬性限制只適用於**工具**（exec/read/write/edit/apply_patch）。
- 瀏覽器/相機/畫布等主機專用工具預設被封鎖。
- 在沙箱中允許 `browser` **會破壞隔離**（瀏覽器在主機上執行）。

## 疑難排解

- 映像遺失：使用 [`scripts/sandbox-setup.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/sandbox-setup.sh) 建置，或設定 `agents.defaults.sandbox.docker.image`。
- 容器未執行：它將按需每個對話自動建立。
- 沙箱中的權限錯誤：將 `docker.user` 設定為與您的掛載工作區擁有權相符的 UID:GID（或 chown 工作區資料夾）。
- 找不到自訂工具：OpenClaw 使用 `sh -lc`（登入 shell）執行指令，它會載入 `/etc/profile` 並可能重設 PATH。設定 `docker.env.PATH` 以前置您的自訂工具路徑（例如 `/custom/bin:/usr/local/share/npm-global/bin`），或在您的 Dockerfile 中的 `/etc/profile.d/` 下新增腳本。
