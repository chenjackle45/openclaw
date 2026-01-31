---
title: "linux(Linux App)"
summary: "Linux 支援 + 配套應用程式狀態"
read_when:
  - 尋找 Linux 配套應用程式狀態時
  - 規劃平台覆蓋範圍或貢獻時
---

# Linux 應用程式

Gateway 在 Linux 上受到完整支援。**推薦使用 Node 作為運行時**。
不建議使用 Bun 運行 Gateway (因 WhatsApp/Telegram 錯誤)。

原生 Linux 配套應用程式已在計畫中。若您想協助開發，歡迎貢獻。

## 新手快速路徑 (VPS)

1) 安裝 Node 22+  
2) `npm i -g openclaw@latest`  
3) `openclaw onboard --install-daemon`  
4) 從您的筆電: `ssh -N -L 18789:127.0.0.1:18789 <user>@<host>`  
5) 開啟 `http://127.0.0.1:18789/` 並貼上您的 Token

逐步 VPS 指南: [exe.dev](/platforms/exe-dev)

## 安裝
- [Getting Started](/start/getting-started)
- [Install & updates](/install/updating)
- 選用流程: [Bun (實驗性)](/install/bun), [Nix](/install/nix), [Docker](/install/docker)

## Gateway
- [Gateway runbook](/gateway)
- [Configuration](/gateway/configuration)

## Gateway 服務安裝 (CLI)

使用下列其中之一：

```bash
openclaw onboard --install-daemon
```

或：

```bash
openclaw gateway install
```

或：

```bash
openclaw configure
```

在提示時選擇 **Gateway service**。

修復/遷移：

```bash
openclaw doctor
```

## 系統控制 (systemd user unit)
OpenClaw 預設安裝 systemd **user** 服務。對於共用或全天候運行的伺服器，請使用 **system** 服務。完整的單元範例與指南位於 [Gateway runbook](/gateway)。

最小設定：

建立 `~/.config/systemd/user/openclaw-gateway[-<profile>].service`:

```ini
[Unit]
Description=OpenClaw Gateway (profile: <profile>, v<version>)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/openclaw gateway --port 18789
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

啟用它：

```bash
systemctl --user enable --now openclaw-gateway[-<profile>].service
```
