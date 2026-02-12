---
summary: "平台支援概覽（Gateway + 伴隨應用程式）"
read_when:
  - 尋找操作系統支援或安裝路徑
  - 決定在何處執行 Gateway
title: "Platforms（平台）"
---

# 平台

OpenClaw 核心以 TypeScript 編寫。**Node 是推薦的執行時**。
Bun 不推薦用於 Gateway（WhatsApp/Telegram bugs）。

伴隨應用程式存在於 macOS（功能表欄應用程式）和行動節點（iOS/Android）。Windows 和
Linux 伴隨應用程式已計畫，但 Gateway 現已完全支援。
Windows 原生伴隨應用程式也已計畫；透過 WSL2 推薦 Gateway。

## 選擇你的操作系統

- macOS：[macOS](/zh-Hant/platforms/macos)
- iOS：[iOS](/zh-Hant/platforms/ios)
- Android：[Android](/zh-Hant/platforms/android)
- Windows：[Windows](/zh-Hant/platforms/windows)
- Linux：[Linux](/zh-Hant/platforms/linux)

## VPS 和主機代管

- VPS 中樞：[VPS 主機代管](/zh-Hant/vps)
- Fly.io：[Fly.io](/zh-Hant/install/fly)
- Hetzner（Docker）：[Hetzner](/zh-Hant/install/hetzner)
- GCP（Compute Engine）：[GCP](/zh-Hant/install/gcp)
- exe.dev（VM + HTTPS proxy）：[exe.dev](/zh-Hant/install/exe-dev)

## 常見連結

- 安裝指南：[開始使用](/zh-Hant/start/getting-started)
- Gateway Runbook：[Gateway](/zh-Hant/gateway)
- Gateway 配置：[配置](/zh-Hant/gateway/configuration)
- 服務狀態：`openclaw gateway status`

## Gateway 服務安裝 (CLI)

使用以下其中之一（全部支援）：

- 精靈（推薦）：`openclaw onboard --install-daemon`
- 直接：`openclaw gateway install`
- 配置流程：`openclaw configure` → 選擇 **Gateway 服務**
- 修復/遷移：`openclaw doctor`（提供安裝或修復服務的選項）

服務目標取決於操作系統：

- macOS：LaunchAgent（`bot.molt.gateway` 或 `bot.molt.<profile>`；舊版 `com.openclaw.*`）
- Linux/WSL2：systemd 使用者服務（`openclaw-gateway[-<profile>].service`）
