---
summary: "Linux 支援 + 伴隨應用程式狀態"
read_when:
  - 尋找 Linux 伴隨應用程式狀態
  - 規劃平台覆蓋範圍或貢獻
title: "Linux App（Linux 應用程式）"
---

# Linux 應用程式

Gateway 在 Linux 上完全支援。**Node 是建議的執行環境**。
Bun 不建議用於 Gateway（存在 WhatsApp/Telegram 的 bug）。

原生 Linux 伴隨應用程式已在規劃中。如果你想協助開發，歡迎貢獻。

## 初學者快速路徑（VPS）

1. 安裝 Node 24（建議；Node 22 LTS，目前為 `22.16+`，仍可相容使用）
2. `npm i -g openclaw@latest`
3. `openclaw onboard --install-daemon`
4. 從你的筆記型電腦：`ssh -N -L 18789:127.0.0.1:18789 <user>@<host>`
5. 開啟 `http://127.0.0.1:18789/` 並貼上你的 token

逐步 VPS 指南：[exe.dev](/zh-Hant/install/exe-dev)

## 安裝

- [開始使用](/zh-Hant/start/getting-started)
- [安裝與更新](/zh-Hant/install/updating)
- 選用流程：[Bun（實驗性）](/zh-Hant/install/bun)、[Nix](/zh-Hant/install/nix)、[Docker](/zh-Hant/install/docker)

## Gateway

- [Gateway runbook](/zh-Hant/gateway)
- [設定](/zh-Hant/gateway/configuration)

## Gateway 服務安裝（CLI）

使用以下其中之一：

```
openclaw onboard --install-daemon
```

或：

```
openclaw gateway install
```

或：

```
openclaw configure
```

提示時選擇 **Gateway service**。

修復/遷移：

```
openclaw doctor
```

## 系統控制（systemd 使用者單元）

OpenClaw 預設安裝 systemd **使用者**服務。共用或始終開啟的伺服器請使用**系統**
服務。完整單元範例和說明位於 [Gateway runbook](/zh-Hant/gateway)。

最小設定：

建立 `~/.config/systemd/user/openclaw-gateway[-<profile>].service`：

```
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

```
systemctl --user enable --now openclaw-gateway[-<profile>].service
```
