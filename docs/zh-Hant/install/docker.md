---
summary: "選用 Docker 設定與 OpenClaw 引導設定"
read_when:
  - 您想使用容器化 gateway 而非本機安裝時
  - 您正在驗證 Docker 工作流程時
title: "Docker（選用）"
---

# Docker（選用）

Docker 是**選用**的。只有在您想要容器化 gateway 或驗證 Docker 工作流程時才使用它。

## Docker 適合我嗎？

- **適合**：您想要隔離、可拋棄的 gateway 環境，或在沒有本機安裝的主機上執行 OpenClaw。
- **不適合**：您在自己的機器上執行，只想要最快的開發循環。改用一般安裝流程。
- **沙箱注意事項**：Agent 沙箱也使用 Docker，但**不**要求完整的 gateway 在 Docker 中執行。見 [沙箱](/zh-Hant/gateway/sandboxing)。

本指南涵蓋：

- 容器化 Gateway（Docker 中的完整 OpenClaw）
- 每會話 Agent 沙箱（主機 gateway + Docker 隔離的 agent 工具）

沙箱詳細資訊：[沙箱](/zh-Hant/gateway/sandboxing)

## 需求

- Docker Desktop（或 Docker Engine）+ Docker Compose v2
- 至少 2 GB RAM 用於映像建置（`pnpm install` 在 1 GB 主機上可能因 exit 137 被 OOM 殺死）
- 足夠的磁碟空間用於映像 + 日誌
- 若在 VPS/公共主機上執行，請查閱
  [網路曝露的安全強化](/zh-Hant/gateway/security#04-network-exposure-bind--port--firewall)，
  尤其是 Docker `DOCKER-USER` 防火牆策略。

## 容器化 Gateway（Docker Compose）

### 快速開始（建議）

<Note>
此處的 Docker 預設假設使用綁定模式（`lan`/`loopback`），而非主機別名。在 `gateway.bind` 中使用綁定模式值（例如 `lan` 或 `loopback`），而非主機別名如
`0.0.0.0` 或 `localhost`。
</Note>

從倉庫根目錄執行：

```bash
./docker-setup.sh
```

此腳本：

- 在本機建置 gateway 映像（若設定了 `OPENCLAW_IMAGE` 則拉取遠端映像）
- 執行引導精靈
- 列印選填的提供者設定提示
- 透過 Docker Compose 啟動 gateway
- 生成 gateway token 並寫入 `.env`

選填環境變數：

- `OPENCLAW_IMAGE` — 使用遠端映像而非本機建置（例如 `ghcr.io/openclaw/openclaw:latest`）
- `OPENCLAW_DOCKER_APT_PACKAGES` — 建置期間安裝額外的 apt 套件
- `OPENCLAW_EXTENSIONS` — 建置時預先安裝擴充套件依賴項（以空格分隔的擴充套件名稱，例如 `diagnostics-otel matrix`）
- `OPENCLAW_EXTRA_MOUNTS` — 新增額外的主機綁定掛載
- `OPENCLAW_HOME_VOLUME` — 以具名 volume 持久化 `/home/node`
- `OPENCLAW_SANDBOX` — 選擇加入 Docker gateway 沙箱 bootstrap。只有明確的真值才會啟用：`1`、`true`、`yes`、`on`
- `OPENCLAW_INSTALL_DOCKER_CLI` — 本機映像建置的建置參數傳遞（`1` 在映像中安裝 Docker CLI）。當 `OPENCLAW_SANDBOX=1` 用於本機建置時，`docker-setup.sh` 自動設定此項。
- `OPENCLAW_DOCKER_SOCKET` — 覆寫 Docker socket 路徑（預設：`DOCKER_HOST=unix://...` 路徑，否則為 `/var/run/docker.sock`）
- `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1` — 緊急出口：允許受信任的私有網路 `ws://` 目標用於 CLI/引導客戶端路徑（預設僅限 loopback）
- `OPENCLAW_BROWSER_DISABLE_GRAPHICS_FLAGS=0` — 停用容器瀏覽器強化旗標
  `--disable-3d-apis`、`--disable-software-rasterizer`、`--disable-gpu`，當您需要
  WebGL/3D 相容性時使用。
- `OPENCLAW_BROWSER_DISABLE_EXTENSIONS=0` — 當瀏覽器流程需要擴充套件時保持擴充套件啟用（預設在沙箱瀏覽器中停用擴充套件）。
- `OPENCLAW_BROWSER_RENDERER_PROCESS_LIMIT=<N>` — 設定 Chromium 渲染器程序
  限制；設為 `0` 跳過此旗標並使用 Chromium 預設行為。

完成後：

- 在瀏覽器中開啟 `http://127.0.0.1:18789/`。
- 將 token 貼入 Control UI（設定 → token）。
- 再次需要 URL？執行 `docker compose run --rm openclaw-cli dashboard --no-open`。

### 為 Docker gateway 啟用 Agent 沙箱（選擇加入）

`docker-setup.sh` 也可以為 Docker 部署 bootstrap `agents.defaults.sandbox.*`。

啟用方式：

```bash
export OPENCLAW_SANDBOX=1
./docker-setup.sh
```

自訂 socket 路徑（例如 rootless Docker）：

```bash
export OPENCLAW_SANDBOX=1
export OPENCLAW_DOCKER_SOCKET=/run/user/1000/docker.sock
./docker-setup.sh
```

注意：

- 腳本只有在沙箱前置條件通過後才掛載 `docker.sock`。
- 若沙箱設定無法完成，腳本會重置
  `agents.defaults.sandbox.mode` 為 `off`，以避免重新執行時留下過時/損壞的沙箱設定。
- 若 `Dockerfile.sandbox` 不存在，腳本會列印警告並繼續；
  必要時使用 `scripts/sandbox-setup.sh` 建置 `openclaw-sandbox:bookworm-slim`。
- 對於非本機的 `OPENCLAW_IMAGE` 值，映像必須已包含 Docker
  CLI 支援以執行沙箱。

### 自動化/CI（非互動式，無 TTY 輸出）

對於腳本和 CI，使用 `-T` 停用 Compose 偽 TTY 分配：

```bash
docker compose run -T --rm openclaw-cli gateway probe
docker compose run -T --rm openclaw-cli devices list --json
```

若您的自動化未匯出 Claude 會話變數，在 `docker-compose.yml` 中保持它們未設定現在預設解析為空值，以避免重複的「variable is not set」警告。

### 共享網路安全注意事項（CLI + gateway）

`openclaw-cli` 使用 `network_mode: "service:openclaw-gateway"`，讓 CLI 指令可以
在 Docker 中透過 `127.0.0.1` 可靠地連接 gateway。

將此視為共享信任邊界：loopback 綁定在這兩個容器之間不是隔離。
若您需要更強的隔離，從獨立的容器/主機網路路徑執行指令，而非使用捆綁的 `openclaw-cli` 服務。

為降低 CLI 程序遭到入侵時的影響，compose 設定在 `openclaw-cli` 上
放棄 `NET_RAW`/`NET_ADMIN` 並啟用 `no-new-privileges`。

它在主機上寫入設定/工作區：

- `~/.openclaw/`
- `~/.openclaw/workspace`

在 VPS 上執行？見 [Hetzner（Docker VPS）](/zh-Hant/install/hetzner)。

### 使用遠端映像（跳過本機建置）

官方預建映像發布於：

- [GitHub Container Registry 套件](https://github.com/openclaw/openclaw/pkgs/container/openclaw)

使用映像名稱 `ghcr.io/openclaw/openclaw`（不是 Docker Hub 上名稱相似的映像）。

常用 tag：

- `main` — `main` 分支的最新建置
- `<version>` — 發布 tag 建置（例如 `2026.2.26`）
- `latest` — 最新穩定發布 tag

### 基礎映像元資料

主要 Docker 映像目前使用：

- `node:22-bookworm`

Docker 映像現在發布 OCI 基礎映像標注（sha256 為範例，
指向該 tag 的固定多架構 manifest list）：

- `org.opencontainers.image.base.name=docker.io/library/node:22-bookworm`
- `org.opencontainers.image.base.digest=sha256:b501c082306a4f528bc4038cbf2fbb58095d583d0419a259b2114b5ac53d12e9`
- `org.opencontainers.image.source=https://github.com/openclaw/openclaw`
- `org.opencontainers.image.url=https://openclaw.ai`
- `org.opencontainers.image.documentation=https://docs.openclaw.ai/install/docker`
- `org.opencontainers.image.licenses=MIT`
- `org.opencontainers.image.title=OpenClaw`
- `org.opencontainers.image.description=OpenClaw gateway and CLI runtime container image`
- `org.opencontainers.image.revision=<git-sha>`
- `org.opencontainers.image.version=<tag-or-main>`
- `org.opencontainers.image.created=<rfc3339 timestamp>`

參考：[OCI 映像標注](https://github.com/opencontainers/image-spec/blob/main/annotations.md)

發布上下文：此倉庫的 tag 歷史已在
`v2026.2.22` 及更早的 2026 tag（例如 `v2026.2.21`、`v2026.2.9`）中使用 Bookworm。

預設情況下，設定腳本從原始碼建置映像。若要拉取預建映像，在執行腳本前設定 `OPENCLAW_IMAGE`：

```bash
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
./docker-setup.sh
```

腳本偵測到 `OPENCLAW_IMAGE` 不是預設的 `openclaw:local` 並
執行 `docker pull` 而非 `docker build`。其他所有內容（引導、
gateway 啟動、token 生成）以相同方式運作。

`docker-setup.sh` 仍從倉庫根目錄執行，因為它使用本機的
`docker-compose.yml` 和輔助檔案。`OPENCLAW_IMAGE` 跳過本機映像建置
時間；它不替換 compose/設定工作流程。

### Shell 輔助工具（選用）

為便於日常 Docker 管理，安裝 `ClawDock`：

```bash
mkdir -p ~/.clawdock && curl -sL https://raw.githubusercontent.com/openclaw/openclaw/main/scripts/shell-helpers/clawdock-helpers.sh -o ~/.clawdock/clawdock-helpers.sh
```

**新增到您的 shell 設定（zsh）：**

```bash
echo 'source ~/.clawdock/clawdock-helpers.sh' >> ~/.zshrc && source ~/.zshrc
```

然後使用 `clawdock-start`、`clawdock-stop`、`clawdock-dashboard` 等。執行 `clawdock-help` 查看所有指令。

見 [`ClawDock` 輔助工具 README](https://github.com/openclaw/openclaw/blob/main/scripts/shell-helpers/README.md) 取得詳情。

### 手動流程（compose）

```bash
docker build -t openclaw:local -f Dockerfile .
docker compose run --rm openclaw-cli onboard
docker compose up -d openclaw-gateway
```

注意：從倉庫根目錄執行 `docker compose ...`。若您啟用了
`OPENCLAW_EXTRA_MOUNTS` 或 `OPENCLAW_HOME_VOLUME`，設定腳本會寫入
`docker-compose.extra.yml`；在其他地方執行 Compose 時請包含它：

```bash
docker compose -f docker-compose.yml -f docker-compose.extra.yml <command>
```

### Control UI token + 配對（Docker）

若您看到「unauthorized」或「disconnected (1008): pairing required」，取得
新的儀表板連結並核准瀏覽器裝置：

```bash
docker compose run --rm openclaw-cli dashboard --no-open
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve <requestId>
```

詳情：[儀表板](/zh-Hant/web/dashboard)、[裝置](/zh-Hant/cli/devices)。

### 額外掛載（選用）

若您想將額外的主機目錄掛載到容器中，在執行 `docker-setup.sh` 前設定
`OPENCLAW_EXTRA_MOUNTS`。這接受逗號分隔的 Docker 綁定掛載清單，並透過生成 `docker-compose.extra.yml` 將它們套用到
`openclaw-gateway` 和 `openclaw-cli`。

範例：

```bash
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

注意：

- 路徑必須在 macOS/Windows 上與 Docker Desktop 共享。
- 每個項目必須為 `source:target[:options]`，不含空格、Tab 或換行。
- 若您編輯 `OPENCLAW_EXTRA_MOUNTS`，重新執行 `docker-setup.sh` 以重新生成額外的 compose 檔案。
- `docker-compose.extra.yml` 是生成的，請勿手動編輯。

### 持久化整個容器主目錄（選用）

若您想讓 `/home/node` 在容器重建後持續存在，透過 `OPENCLAW_HOME_VOLUME` 設定具名
volume。這會建立一個 Docker volume 並將其掛載到 `/home/node`，同時保留標準的設定/工作區綁定掛載。在此使用具名 volume（而非綁定路徑）；對於綁定掛載，使用
`OPENCLAW_EXTRA_MOUNTS`。

範例：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

您可以結合額外掛載使用：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

注意：

- 具名 volume 必須符合 `^[A-Za-z0-9][A-Za-z0-9_.-]*$`。
- 若您更改 `OPENCLAW_HOME_VOLUME`，重新執行 `docker-setup.sh` 以重新生成額外的 compose 檔案。
- 具名 volume 持久化直到使用 `docker volume rm <name>` 移除。

### 安裝額外的 apt 套件（選用）

若您需要映像內的系統套件（例如建置工具或媒體程式庫），在執行 `docker-setup.sh` 前設定 `OPENCLAW_DOCKER_APT_PACKAGES`。
這會在映像建置期間安裝套件，因此即使容器刪除後也會持續存在。

範例：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg build-essential"
./docker-setup.sh
```

注意：

- 這接受以空格分隔的 apt 套件名稱清單。
- 若您更改 `OPENCLAW_DOCKER_APT_PACKAGES`，重新執行 `docker-setup.sh` 以重新建置映像。

### 預先安裝擴充套件依賴項（選用）

有自己 `package.json` 的擴充套件（例如 `diagnostics-otel`、`matrix`、
`msteams`）在首次載入時安裝其 npm 依賴項。若要改為將這些
依賴項烘焙到映像中，在執行 `docker-setup.sh` 前設定 `OPENCLAW_EXTENSIONS`：

```bash
export OPENCLAW_EXTENSIONS="diagnostics-otel matrix"
./docker-setup.sh
```

或直接建置時：

```bash
docker build --build-arg OPENCLAW_EXTENSIONS="diagnostics-otel matrix" .
```

注意：

- 這接受以空格分隔的擴充套件目錄名稱清單（在 `extensions/` 下）。
- 只有有 `package.json` 的擴充套件會受影響；沒有 `package.json` 的輕量插件會被忽略。
- 若您更改 `OPENCLAW_EXTENSIONS`，重新執行 `docker-setup.sh` 以重新建置映像。

### 進階使用者 / 功能完整容器（選擇加入）

預設 Docker 映像以**安全性優先**設計，以非 root 的 `node`
使用者執行。這使攻擊面小，但意味著：

- 執行時無法安裝系統套件
- 預設無 Homebrew
- 無捆綁的 Chromium/Playwright 瀏覽器

若您想要功能更完整的容器，使用這些選擇加入的設定：

1. **持久化 `/home/node`** 讓瀏覽器下載和工具快取得以保存：

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

2. **將系統依賴項烘焙到映像中**（可重複 + 持久）：

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="git curl jq"
./docker-setup.sh
```

3. **不使用 `npx` 安裝 Playwright 瀏覽器**（避免 npm 覆寫衝突）：

```bash
docker compose run --rm openclaw-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

若您需要 Playwright 安裝系統依賴項，使用
`OPENCLAW_DOCKER_APT_PACKAGES` 重新建置映像，而非在執行時使用 `--with-deps`。

4. **持久化 Playwright 瀏覽器下載**：

- 在 `docker-compose.yml` 中設定 `PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright`。
- 透過 `OPENCLAW_HOME_VOLUME` 確保 `/home/node` 持久化，或
  透過 `OPENCLAW_EXTRA_MOUNTS` 掛載 `/home/node/.cache/ms-playwright`。

### 權限 + EACCES

映像以 `node`（uid 1000）執行。若您在
`/home/node/.openclaw` 上看到權限錯誤，確認您的主機綁定掛載由 uid 1000 擁有。

範例（Linux 主機）：

```bash
sudo chown -R 1000:1000 /path/to/openclaw-config /path/to/openclaw-workspace
```

若您為了方便以 root 執行，您接受了安全性取捨。

### 更快的重新建置（建議）

為加速重新建置，將 Dockerfile 中的依賴層排在前面進行快取。
除非 lockfile 變更，否則避免重新執行 `pnpm install`：

```dockerfile
FROM node:22-bookworm

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# Cache dependencies unless package metadata changes
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

### 頻道設定（選用）

使用 CLI 容器設定頻道，必要時重啟 gateway。

WhatsApp（QR）：

```bash
docker compose run --rm openclaw-cli channels login
```

Telegram（bot token）：

```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "<token>"
```

Discord（bot token）：

```bash
docker compose run --rm openclaw-cli channels add --channel discord --token "<token>"
```

文件：[WhatsApp](/zh-Hant/channels/whatsapp)、[Telegram](/zh-Hant/channels/telegram)、[Discord](/zh-Hant/channels/discord)

### OpenAI Codex OAuth（無頭 Docker）

若您在精靈中選擇 OpenAI Codex OAuth，它會開啟瀏覽器 URL 並嘗試
在 `http://127.0.0.1:1455/auth/callback` 捕獲回呼。在 Docker 或
無頭設定中，該回呼可能顯示瀏覽器錯誤。複製您到達的完整重定向
URL 並貼回精靈以完成驗證。

### 健康檢查

容器探針端點（不需要驗證）：

```bash
curl -fsS http://127.0.0.1:18789/healthz
curl -fsS http://127.0.0.1:18789/readyz
```

別名：`/health` 和 `/ready`。

`/healthz` 是「gateway 程序已啟動」的淺層存活探針。
`/readyz` 在啟動寬限期間保持就緒，然後只有在寬限後或之後所需
的受管理頻道仍斷線時才變為 `503`。

Docker 映像包含一個內建的 `HEALTHCHECK`，在背景 ping `/healthz`。
簡單說：Docker 持續檢查 OpenClaw 是否仍有回應。若持續失敗，Docker 將容器標記為 `unhealthy`，
協調系統（Docker Compose 重啟策略、Swarm、Kubernetes 等）可自動重啟或替換它。

已驗證的深度健康快照（gateway + 頻道）：

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

### LAN vs loopback（Docker Compose）

`docker-setup.sh` 預設 `OPENCLAW_GATEWAY_BIND=lan`，以便主機存取
`http://127.0.0.1:18789` 能與 Docker 連接埠發布一起運作。

- `lan`（預設）：主機瀏覽器 + 主機 CLI 可以連接到已發布的 gateway 連接埠。
- `loopback`：只有容器網路命名空間內的程序才能直接連接
  gateway；主機發布的連接埠存取可能失敗。

設定腳本也在引導後固定 `gateway.mode=local`，以便 Docker CLI
指令預設使用本機 loopback 目標。

舊版設定注意事項：在 `gateway.bind` 中使用綁定模式值（`lan` / `loopback` /
`custom` / `tailnet` / `auto`），而非主機別名（`0.0.0.0`、`127.0.0.1`、
`localhost`、`::`、`::1`）。

若您看到 `Gateway target: ws://172.x.x.x:18789` 或來自 Docker CLI 指令的重複 `pairing required`
錯誤，執行：

```bash
docker compose run --rm openclaw-cli config set gateway.mode local
docker compose run --rm openclaw-cli config set gateway.bind lan
docker compose run --rm openclaw-cli devices list --url ws://127.0.0.1:18789
```

### 注意事項

- Gateway 綁定預設為 `lan` 以供容器使用（`OPENCLAW_GATEWAY_BIND`）。
- Dockerfile CMD 使用 `--allow-unconfigured`；設定了 `gateway.mode` 但不是 `local` 的掛載設定仍會啟動。覆寫 CMD 以強制套用防護。
- Gateway 容器是會話的真相來源（`~/.openclaw/agents/<agentId>/sessions/`）。

### 儲存模型

- **持久化主機資料：** Docker Compose 將 `OPENCLAW_CONFIG_DIR` 綁定掛載到 `/home/node/.openclaw`，將 `OPENCLAW_WORKSPACE_DIR` 綁定掛載到 `/home/node/.openclaw/workspace`，因此這些路徑在容器替換後仍能存活。
- **臨時沙箱 tmpfs：** 當 `agents.defaults.sandbox` 啟用時，沙箱容器對 `/tmp`、`/var/tmp` 和 `/run` 使用 `tmpfs`。這些掛載與頂層 Compose 堆疊分開，沙箱容器消失時也會消失。
- **磁碟增長熱點：** 監控 `media/`、`agents/<agentId>/sessions/sessions.json`、逐字稿 JSONL 檔案、`cron/runs/*.jsonl`，以及 `/tmp/openclaw/`（或您設定的 `logging.file`）下的滾動檔案日誌。若您也在 Docker 外執行 macOS app，其服務日誌是獨立的：`~/.openclaw/logs/gateway.log`、`~/.openclaw/logs/gateway.err.log` 和 `/tmp/openclaw/openclaw-gateway.log`。

## Agent 沙箱（主機 gateway + Docker 工具）

深入說明：[沙箱](/zh-Hant/gateway/sandboxing)

### 功能說明

當 `agents.defaults.sandbox` 啟用時，**非主會話**在 Docker
容器內執行工具。Gateway 保留在您的主機上，但工具執行是隔離的：

- 範圍：預設 `"agent"`（每個 agent 一個容器 + 工作區）
- 範圍：`"session"` 用於每會話隔離
- 每範圍工作區資料夾掛載到 `/workspace`
- 選填的 agent 工作區存取（`agents.defaults.sandbox.workspaceAccess`）
- 允許/拒絕工具策略（拒絕優先）
- 入站媒體複製到活躍的沙箱工作區（`media/inbound/*`），讓工具可以讀取（使用 `workspaceAccess: "rw"` 時，這會落在 agent 工作區）

警告：`scope: "shared"` 停用跨會話隔離。所有會話共享
一個容器和一個工作區。

### 每 Agent 沙箱設定檔（多 Agent）

若您使用多 Agent 路由，每個 agent 可以覆寫沙箱 + 工具設定：
`agents.list[].sandbox` 和 `agents.list[].tools`（加上 `agents.list[].tools.sandbox.tools`）。這讓您可以在一個 gateway 中執行
混合存取層級：

- 完整存取（個人 agent）
- 唯讀工具 + 唯讀工作區（家庭/工作 agent）
- 無檔案系統/Shell 工具（公開 agent）

見 [多 Agent 沙箱與工具](/zh-Hant/tools/multi-agent-sandbox-tools) 取得範例、
優先順序和疑難排解。

### 預設行為

- 映像：`openclaw-sandbox:bookworm-slim`
- 每個 agent 一個容器
- Agent 工作區存取：`workspaceAccess: "none"`（預設）使用 `~/.openclaw/sandboxes`
  - `"ro"` 保持沙箱工作區在 `/workspace`，並以唯讀方式掛載 agent 工作區到 `/agent`（停用 `write`/`edit`/`apply_patch`）
  - `"rw"` 以讀寫方式掛載 agent 工作區到 `/workspace`
- 自動修剪：閒置 > 24h 或年齡 > 7d
- 網路：預設 `none`（若需要出站連線請明確選擇加入）
  - `host` 被阻擋。
  - `container:<id>` 預設被阻擋（命名空間加入風險）。
- 預設允許：`exec`、`process`、`read`、`write`、`edit`、`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- 預設拒絕：`browser`、`canvas`、`nodes`、`cron`、`discord`、`gateway`

### 啟用沙箱

若您計劃在 `setupCommand` 中安裝套件，請注意：

- 預設 `docker.network` 為 `"none"`（無出站連線）。
- `docker.network: "host"` 被阻擋。
- `docker.network: "container:<id>"` 預設被阻擋。
- 緊急出口覆寫：`agents.defaults.sandbox.docker.dangerouslyAllowContainerNamespaceJoin: true`。
- `readOnlyRoot: true` 阻擋套件安裝。
- `user` 必須為 root 才能執行 `apt-get`（省略 `user` 或設定 `user: "0:0"`）。
  OpenClaw 在 `setupCommand`（或 docker 設定）變更時自動重建容器，
  除非容器是**最近使用**的（約 5 分鐘內）。熱容器會記錄警告並附上精確的 `openclaw sandbox recreate ...` 指令。

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // off | non-main | all
        scope: "agent", // session | agent | shared（agent 為預設）
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

強化設定位於 `agents.defaults.sandbox.docker` 下：
`network`、`user`、`pidsLimit`、`memory`、`memorySwap`、`cpus`、`ulimits`、
`seccompProfile`、`apparmorProfile`、`dns`、`extraHosts`、
`dangerouslyAllowContainerNamespaceJoin`（僅限緊急出口）。

多 Agent：透過 `agents.list[].sandbox.{docker,browser,prune}.*` 覆寫每個 agent 的 `agents.defaults.sandbox.{docker,browser,prune}.*`
（當 `agents.defaults.sandbox.scope` / `agents.list[].sandbox.scope` 為 `"shared"` 時忽略）。

### 建置預設沙箱映像

```bash
scripts/sandbox-setup.sh
```

這使用 `Dockerfile.sandbox` 建置 `openclaw-sandbox:bookworm-slim`。

### 沙箱通用映像（選用）

若您想要含常見建置工具（Node、Go、Rust 等）的沙箱映像，建置通用映像：

```bash
scripts/sandbox-common-setup.sh
```

這建置 `openclaw-sandbox-common:bookworm-slim`。若要使用它：

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

若要在沙箱內執行瀏覽器工具，建置瀏覽器映像：

```bash
scripts/sandbox-browser-setup.sh
```

這使用 `Dockerfile.sandbox-browser` 建置 `openclaw-sandbox-browser:bookworm-slim`。容器以啟用 CDP 的 Chromium 執行，並帶有
選填的 noVNC 觀察器（透過 Xvfb 的有頭模式）。

注意：

- 有頭模式（Xvfb）比無頭模式減少機器人攔截。
- 透過設定 `agents.defaults.sandbox.browser.headless=true` 仍可使用無頭模式。
- 不需要完整的桌面環境（GNOME）；Xvfb 提供顯示。
- 瀏覽器容器預設使用專用的 Docker 網路（`openclaw-sandbox-browser`）而非全局 `bridge`。
- 選填的 `agents.defaults.sandbox.browser.cdpSourceRange` 透過 CIDR 限制容器邊緣的 CDP 入站（例如 `172.21.0.1/32`）。
- noVNC 觀察器存取預設受密碼保護；OpenClaw 提供短期觀察器 Token URL，提供本機 bootstrap 頁面並在 URL 片段中保存密碼（而非 URL 查詢）。
- 瀏覽器容器啟動預設對共享/容器工作負載採取保守設定，包含：
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
  - 若設定了 `agents.defaults.sandbox.browser.noSandbox`，也會附加 `--no-sandbox` 和 `--disable-setuid-sandbox`。
  - 上述三個圖形強化旗標是選填的。若您的工作負載需要 WebGL/3D，設定 `OPENCLAW_BROWSER_DISABLE_GRAPHICS_FLAGS=0` 以不使用 `--disable-3d-apis`、`--disable-software-rasterizer` 和 `--disable-gpu` 執行。
  - 擴充套件行為由 `--disable-extensions` 控制，可透過 `OPENCLAW_BROWSER_DISABLE_EXTENSIONS=0` 停用（啟用擴充套件），適用於依賴擴充套件的頁面或擴充套件密集的工作流程。
  - `--renderer-process-limit=2` 也可透過 `OPENCLAW_BROWSER_RENDERER_PROCESS_LIMIT` 設定；設為 `0` 讓 Chromium 在需要調整瀏覽器並發時選擇其預設程序限制。

預設設定在捆綁的映像中預設套用。若您需要不同的 Chromium 旗標，使用自訂瀏覽器映像並提供自己的進入點。

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

啟用後，agent 會收到：

- 沙箱瀏覽器控制 URL（供 `browser` 工具使用）
- noVNC URL（若已啟用且 headless=false）

記住：若您使用工具的允許清單，新增 `browser`（並從
拒絕中移除），否則工具仍會被阻擋。
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
- 若 `allow` 為空：所有工具（除拒絕外）均可使用。
- 若 `allow` 非空：只有 `allow` 中的工具可使用（減去拒絕）。

### 修剪策略

兩個設定：

- `prune.idleHours`：移除 X 小時內未使用的容器（0 = 停用）
- `prune.maxAgeDays`：移除超過 X 天的容器（0 = 停用）

範例：

- 保留繁忙的會話但限制生命週期：
  `idleHours: 24`、`maxAgeDays: 7`
- 永不修剪：
  `idleHours: 0`、`maxAgeDays: 0`

### 安全注意事項

- 硬性隔離只適用於**工具**（exec/read/write/edit/apply_patch）。
- 主機專用工具如 browser/camera/canvas 預設被阻擋。
- 在沙箱中允許 `browser` **破壞隔離**（瀏覽器在主機上執行）。

## 疑難排解

- 映像缺失：使用 [`scripts/sandbox-setup.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/sandbox-setup.sh) 建置，或設定 `agents.defaults.sandbox.docker.image`。
- 容器未執行：將按需每會話自動建立。
- 沙箱中的權限錯誤：將 `docker.user` 設定為符合您掛載工作區擁有權的 UID:GID（或 chown 工作區資料夾）。
- 找不到自訂工具：OpenClaw 使用 `sh -lc`（登入 shell）執行指令，這會來源 `/etc/profile` 並可能重置 PATH。設定 `docker.env.PATH` 以前置您的自訂工具路徑（例如 `/custom/bin:/usr/local/share/npm-global/bin`），或在您的 Dockerfile 中在 `/etc/profile.d/` 下新增腳本。
