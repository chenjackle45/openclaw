---
title: Fly.io
description: 在 Fly.io 上部署 OpenClaw
summary: "逐步為 OpenClaw 進行 Fly.io 部署，具有持久化存儲和 HTTPS"
read_when:
  - 在 Fly.io 上部署 OpenClaw
  - 設定 Fly 卷、秘密和首次執行配置
---

# Fly.io 部署

**目標：** OpenClaw Gateway 執行在 [Fly.io](https://fly.io) 機器上，具有持久化存儲、自動 HTTPS 和 Discord/頻道訪問。

## 你需要什麼

- [flyctl CLI](https://fly.io/docs/hands-on/install-flyctl/) 已安裝
- Fly.io 帳號（免費級別可行）
- 模型認證：你選擇的模型提供者的 API 金鑰
- 頻道認證：Discord 機器人令牌、Telegram 令牌等

## 初級快速路徑

1. 克隆倉庫 → 自訂 `fly.toml`
2. 建立應用 + 卷 → 設定秘密
3. 使用 `fly deploy` 部署
4. SSH 進入以建立配置或使用控制 UI

## 1) 建立 Fly 應用

```bash
# 克隆倉庫
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# 建立新 Fly 應用（選擇你自己的名稱）
fly apps create my-openclaw

# 建立持久化卷（1GB 通常足夠）
fly volumes create openclaw_data --size 1 --region iad
```

**提示：** 選擇靠近你的區域。常見選項：`lhr`（倫敦）、`iad`（維吉尼亞）、`sjc`（聖何塞）。

## 2) 配置 fly.toml

編輯 `fly.toml` 以匹配你的應用名稱和需求。

**安全注意：** 預設配置公開一個公開 URL。如果要硬化部署且無公開 IP，見 [私人部署（硬化）](#private-deployment-hardened) 或使用 `fly.private.toml`。

```toml
app = "my-openclaw"  # 你的應用名稱
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

## 更新

使用推薦配置（`shared-cpu-2x`、2GB RAM）：

- 約 $10-15/月，取決於使用情況
- 免費級別包含一些額度

詳見 [Fly.io 定價](https://fly.io/docs/about/pricing/)。
