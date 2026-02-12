---
summary: "Linux 支援 + 伴隨應用程式狀態"
read_when:
  - 尋找 Linux 伴隨應用程式狀態
  - 規畫平台覆蓋範圍或貢獻
title: "Linux App（Linux 應用程式）"
---

# Linux 應用程式

Gateway 在 Linux 上完全支援。**Node 是推薦的執行時**。
Bun 不推薦用於 Gateway（WhatsApp/Telegram bugs）。

原生 Linux 伴隨應用程式已計畫。如果你想幫助構建一個，歡迎貢獻。

## 初學者快速路徑 (VPS)

1. 安裝 Node 22+
2. npm i -g openclaw@latest
3. openclaw onboard --install-daemon
4. 從你的筆記本電腦：`ssh -N -L 18789:127.0.0.1:18789 <user>@<host>`
5. 開啟 http://127.0.0.1:18789/ 並貼上你的權杖

逐步 VPS 指南：[exe.dev](/zh-Hant/install/exe-dev)

## 安裝

- [開始使用](/zh-Hant/start/getting-started)
- [安裝和更新](/zh-Hant/install/updating)
- 選用流程：[Bun（試驗性）](/zh-Hant/install/bun)、[Nix](/zh-Hant/install/nix)、[Docker](/zh-Hant/install/docker)

## Gateway

- [Gateway runbook](/zh-Hant/gateway)
- [配置](/zh-Hant/gateway/configuration)

## Gateway 服務安裝 (CLI)

使用以下其中之一：

openclaw onboard --install-daemon

或：

openclaw gateway install

或：

openclaw configure

提示時選擇 Gateway 服務。

修復/遷移：

openclaw doctor

## 系統控制（systemd 使用者單位）

OpenClaw 預設安裝 systemd **使用者**服務。為共用或始終開啟伺服器使用**系統**
服務。完整單位範例和指導
位於 [Gateway runbook](/zh-Hant/gateway)。

最小設定：

在 `~/.config/systemd/user/openclaw-gateway[-<profile>].service` 建立：

參考 Gateway runbook 以了解完整配置。

啟用它：

`systemctl --user enable --now openclaw-gateway[-<profile>].service`
