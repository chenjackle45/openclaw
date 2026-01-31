---
title: "fly(Fly.io)"
summary: "在 Fly.io 上部署 OpenClaw"
read_when:
  - 在 Fly.io 上部署 OpenClaw
---

# Fly.io 部署

**目標:** 在 [Fly.io](https://fly.io) 機器上執行 OpenClaw Gateway，具備持久化儲存、自動 HTTPS 以及 Discord/Channel 存取權限。

## 您需要準備

- 安裝 [flyctl CLI](https://fly.io/docs/hands-on/install-flyctl/)
- Fly.io 帳號 (免費層級可用)
- 模型認證: Anthropic API Key (或其他供應商金鑰)
- Channel 憑證: Discord bot token, Telegram token 等

## 新手快速路徑

1. Clone repo → 自訂 `fly.toml`
2. 建立 app + volume → 設定 secrets
3. 使用 `fly deploy` 部署
4. SSH 進入以建立設定檔或使用 Control UI

## 1) 建立 Fly App

```bash
# Clone the repo
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 建立新的 Fly app (選擇您自己的名稱)
fly apps create my-openclaw

# 建立持久化 Volume (1GB 通常足夠)
fly volumes create openclaw_data --size 1 --region iad
```

**提示:** 選擇離您較近的區域。常見選項: `lhr` (倫敦), `iad` (維吉尼亞), `sjc` (聖荷西)。

## 2) 設定 fly.toml

編輯 `fly.toml` 以符合您的 App 名稱與需求。

**安全性注意事項:** 預設設定會暴露公開 URL。若需要無公開 IP 的強化部署，請參閱 [私有部署 (Hardened)](#私有部署-hardened) 或使用 `fly.private.toml`。

```toml
app = "my-openclaw"  # 您的 App 名稱
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  NODE_ENV = "production"
  OPENCLAW_PREFER_PNPM = "1"
  OPENCLAW_STATE_DIR = "/data"
  NODE_OPTIONS = "--max-old-space-size=1536"

[processes]
  app = "node dist/index.js gateway --allow-unconfigured --port 3000 --bind lan"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1
  processes = ["app"]

[[vm]]
  size = "shared-cpu-2x"
  memory = "2048mb"

[mounts]
  source = "openclaw_data"
  destination = "/data"
```

**關鍵設定:**

| 設定 | 原因 |
|---------|-----|
| `--bind lan` | 綁定至 `0.0.0.0` 以便 Fly 的代理能連線至 Gateway |
| `--allow-unconfigured` | 在無設定檔的情況下啟動 (您稍後會建立) |
| `internal_port = 3000` | 必須符合 `--port 3000` (或 `OPENCLAW_GATEWAY_PORT`) 以供 Fly 健康檢查 |
| `memory = "2048mb"` | 512MB 太小；推薦 2GB |
| `OPENCLAW_STATE_DIR = "/data"` | 將狀態持久化在 Volume 上 |

## 3) 設定 Secrets

```bash
# 必填: Gateway Token (用於非 loopback 綁定)
fly secrets set OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

# 模型供應商 API Keys
fly secrets set ANTHROPIC_API_KEY=sk-ant-...

# 選用: 其他供應商
fly secrets set OPENAI_API_KEY=sk-...
fly secrets set GOOGLE_API_KEY=...

# Channel Tokens
fly secrets set DISCORD_BOT_TOKEN=MTQ...
```

**注意:**
- 非 loopback 綁定 (`--bind lan`) 需要 `OPENCLAW_GATEWAY_TOKEN` 以策安全。
- 請像對待密碼一樣對待這些 Token。
- **所有 API Keys 與 Token 偏好使用環境變數勝過設定檔**。這能避免 Secrets 出現在 `openclaw.json` 中被意外暴露或記錄。

## 4) 部署

```bash
fly deploy
```

首次部署會建置 Docker 映像檔 (~2-3 分鐘)。後續部署會較快。

部署後驗證：
```bash
fly status
fly logs
```

您應看到：
```
[gateway] listening on ws://0.0.0.0:3000 (PID xxx)
[discord] logged in to discord as xxx
```

## 5) 建立設定檔

SSH 進入機器以建立適當的設定：

```bash
fly ssh console
```

建立設定目錄與檔案：
```bash
mkdir -p /data
cat > /data/openclaw.json << 'EOF'
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-5",
        "fallbacks": ["anthropic/claude-sonnet-4-5", "openai/gpt-4o"]
      },
      "maxConcurrent": 4
    },
    "list": [
      {
        "id": "main",
        "default": true
      }
    ]
  },
  "auth": {
    "profiles": {
      "anthropic:default": { "mode": "token", "provider": "anthropic" },
      "openai:default": { "mode": "token", "provider": "openai" }
    }
  },
  "bindings": [
    {
      "agentId": "main",
      "match": { "channel": "discord" }
    }
  ],
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "allowlist",
      "guilds": {
        "YOUR_GUILD_ID": {
          "channels": { "general": { "allow": true } },
          "requireMention": false
        }
      }
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "auto"
  },
  "meta": {
    "lastTouchedVersion": "2026.1.29"
  }
}
EOF
```

**注意:** 設定 `OPENCLAW_STATE_DIR=/data` 後，設定檔路徑為 `/data/openclaw.json`。

**注意:** Discord Token 可來自：
- 環境變數: `DISCORD_BOT_TOKEN` (推薦用於 Secrets)
- 設定檔: `channels.discord.token`

若使用環境變數，無需將 Token 加入設定檔。Gateway 會自動讀取 `DISCORD_BOT_TOKEN`。

重啟以套用：
```bash
exit
fly machine restart <machine-id>
```

## 6) 存取 Gateway

### Control UI

在瀏覽器開啟：
```bash
fly open
```

或造訪 `https://my-openclaw.fly.dev/`

貼上您的 Gateway Token (來自 `OPENCLAW_GATEWAY_TOKEN`) 以進行驗證。

### Logs

```bash
fly logs              # 即時日誌
fly logs --no-tail    # 近期日誌
```

### SSH Console

```bash
fly ssh console
```

## 故障排除

### "App is not listening on expected address"

Gateway 綁定在 `127.0.0.1` 而非 `0.0.0.0`。

**修復:** 在 `fly.toml` 的 process command 中加入 `--bind lan`。

### Health checks failing / connection refused

Fly 無法在配置的通訊埠連絡 Gateway。

**修復:** 確保 `internal_port` 與 Gateway 通訊埠相符 (設定 `--port 3000` 或 `OPENCLAW_GATEWAY_PORT=3000`)。

### OOM / Memory Issues

Container 不斷重啟或被殺死。徵兆: `SIGABRT`, `v8::internal::Runtime_AllocateInYoungGeneration`, 或無聲重啟。

**修復:** 在 `fly.toml` 增加記憶體：
```toml
[[vm]]
  memory = "2048mb"
```

或更新現有機器：
```bash
fly machine update <machine-id> --vm-memory 2048 -y
```

**注意:** 512MB 太小。1GB 可能可行但在負載或詳細日誌下可能 OOM。**推薦 2GB。**

### Gateway Lock Issues

Gateway 拒絕啟動並顯示 "already running" 錯誤。

這發生在 Container 重啟但 PID lock 檔案保留在 Volume 上時。

**修復:** 刪除 lock 檔案：
```bash
fly ssh console --command "rm -f /data/gateway.*.lock"
fly machine restart <machine-id>
```

Lock 檔案位於 `/data/gateway.*.lock` (不在子目錄中)。

### Config Not Being Read

若使用 `--allow-unconfigured`，Gateway 會建立最小設定。您在 `/data/openclaw.json` 的自訂設定應在重啟時被讀取。

驗證設定是否存在：
```bash
fly ssh console --command "cat /data/openclaw.json"
```

### 透過 SSH 寫入 Config

`fly ssh console -C` 指令不支援 Shell 重導向。要寫入設定檔：

```bash
# 使用 echo + tee (從本地 pipe 到遠端)
echo '{"your":"config"}' | fly ssh console -C "tee /data/openclaw.json"

# 或使用 sftp
fly sftp shell
> put /local/path/config.json /data/openclaw.json
```

**注意:** 若檔案已存在 `fly sftp` 可能失敗。先刪除：
```bash
fly ssh console --command "rm /data/openclaw.json"
```

### State Not Persisting

若重啟後遺失憑證或工作階段，表示狀態目錄寫入至 Container 檔案系統。

**修復:** 確保 `fly.toml` 中設定了 `OPENCLAW_STATE_DIR=/data` 並重新部署。

## Updates (更新)

```bash
# Pull 最新變更
git pull

# 重新部署
fly deploy

# 檢查健康
fly status
fly logs
```

### 更新機器指令

若需更改啟動指令而不想完全重新部署：

```bash
# 取得機器 ID
fly machines list

# 更新指令
fly machine update <machine-id> --command "node dist/index.js gateway --port 3000 --bind lan" -y

# 或連同增加記憶體
fly machine update <machine-id> --vm-memory 2048 --command "node dist/index.js gateway --port 3000 --bind lan" -y
```

**注意:** `fly deploy` 後，機器指令可能會重置為 `fly.toml` 中的內容。若您手動更改過，請在部署後重新套用。

## 私有部署 (Hardened)

預設情況下，Fly 分配公開 IP，使您的 Gateway 可透過 `https://your-app.fly.dev` 存取。這很方便，但也意味著您的部署會被網路掃描器 (Shodan, Censys 等) 發現。

針對 **無公開暴露** 的強化部署，請使用 Private Template。

### 何時使用私有部署

- 您僅進行 **外撥 (outbound)** 呼叫/訊息 (無 inbound webhooks)
- 您使用 **ngrok 或 Tailscale** 通道進行任何 webhook 回呼
- 您透過 **SSH, proxy, 或 WireGuard** 存取 Gateway 而非瀏覽器
- 您希望部署 **對網路掃描器隱藏**

### 設定

使用 `fly.private.toml` 代替標準設定：

```bash
# 使用私有設定部署
fly deploy -c fly.private.toml
```

或轉換現有部署：

```bash
# 列出目前 IP
fly ips list -a my-openclaw

# 釋放公開 IP
fly ips release <public-ipv4> -a my-openclaw
fly ips release <public-ipv6> -a my-openclaw

# 切換至私有設定，以免未來部署重新分配公開 IP
# (移除 [http_service] 或使用私有模板部署)
fly deploy -c fly.private.toml

# 分配僅限私有的 IPv6
fly ips allocate-v6 --private -a my-openclaw
```

此後，`fly ips list` 應僅顯示 `private` 類型的 IP：
```
VERSION  IP                   TYPE             REGION
v6       fdaa:x:x:x:x::x      private          global
```

### 存取私有部署

由於無公開 URL，請使用下列方法之一：

**選項 1: 本地 Proxy (最簡單)**
```bash
# 轉發本地通訊埠 3000 至 App
fly proxy 3000:3000 -a my-openclaw

# 然後在瀏覽器開啟 http://localhost:3000
```

**選項 2: WireGuard VPN**
```bash
# 建立 WireGuard 設定 (一次性)
fly wireguard create

# 匯入至 WireGuard 用戶端，然後透過內部 IPv6 存取
# 範例: http://[fdaa:x:x:x:x::x]:3000
```

**選項 3: 僅限 SSH**
```bash
fly ssh console -a my-openclaw
```

### 私有部署的 Webhooks

若您需要 Webhook 回呼 (Twilio, Telnyx 等) 但不公開暴露：

1. **ngrok tunnel** - 在 Container 內或作為 Sidecar 運行 ngrok
2. **Tailscale Funnel** - 透過 Tailscale 暴露特定路徑
3. **Outbound-only** - 部分供應商 (Twilio) 支援外撥呼叫無需 Webhook

使用 ngrok 的語音通話設定範例：
```json
{
  "plugins": {
    "entries": {
      "voice-call": {
        "enabled": true,
        "config": {
          "provider": "twilio",
          "tunnel": { "provider": "ngrok" }
        }
      }
    }
  }
}
```

ngrok 通道在 Container 內運行，提供公開 Webhook URL 而不暴露 Fly App 本身。

### 安全性優勢

| 面向 | Public | Private |
|--------|--------|---------|
| 網路掃描器 | 可被發現 | 隱藏 |
| 直接攻擊 | 可能 | 阻擋 |
| Control UI 存取 | 瀏覽器 | Proxy/VPN |
| Webhook 傳遞 | 直接 | 透過 Tunnel |

## 備註

- Fly.io 使用 **x86 架構** (非 ARM)
- Dockerfile 與兩種架構皆相容
- 進行 WhatsApp/Telegram onboarding 時，使用 `fly ssh console`
- 持久化資料位於 Volume 的 `/data` 上
- Signal 需要 Java + signal-cli；使用自訂 Image 並保持記憶體在 2GB+。

## 成本

使用推薦設定 (`shared-cpu-2x`, 2GB RAM):
- 約 ~$10-15/月，取決於使用量
- 免費層級包含部分額度

詳情請參閱 [Fly.io pricing](https://fly.io/docs/about/pricing/)。
