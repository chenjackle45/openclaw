---
title: "index(平台)"
summary: "平台支援總覽 (Gateway + 配套應用程式)"
read_when:
  - 尋找作業系統支援或安裝路徑時
  - 決定由何處運行 Gateway 時
---

# 平台

OpenClaw 核心以 TypeScript 撰寫。**推薦使用 Node 作為運行環境**。
不建議使用 Bun 運行 Gateway（已知有 WhatsApp/Telegram 相關錯誤）。

目前已有適用於 macOS（選單列應用程式）與行動節點（iOS/Android）的配套應用程式。Windows 與 Linux 的配套應用程式已在計劃中，但目前 Gateway 本身已獲完全支援。
Windows 原生配套應用程式也在計劃中；推薦透過 WSL2 使用 Gateway。

## 選擇您的作業系統

- macOS: [macOS](/platforms/macos)
- iOS: [iOS](/platforms/ios)
- Android: [Android](/platforms/android)
- Windows: [Windows](/platforms/windows)
- Linux: [Linux](/platforms/linux)

## VPS 與託管

- VPS 中心: [VPS hosting](/vps)
- Fly.io: [Fly.io](/platforms/fly)
- Hetzner (Docker): [Hetzner](/platforms/hetzner)
- GCP (Compute Engine): [GCP](/platforms/gcp)
- exe.dev (VM + HTTPS proxy): [exe.dev](/platforms/exe-dev)

## 常用連結

- 安裝指南: [Getting Started](/start/getting-started)
- Gateway 操作手冊: [Gateway](/gateway)
- Gateway 配置: [Configuration](/gateway/configuration)
- 服務狀態: `openclaw gateway status`

## Gateway 服務安裝 (CLI)

使用下列任一方式（皆支援）：

- 安裝精靈（推薦）: `openclaw onboard --install-daemon`
- 直接安裝: `openclaw gateway install`
- 配置流程: `openclaw configure` → 選擇 **Gateway service**
- 修復/遷移: `openclaw doctor`（提供安裝或是修復服務的選項）

服務目標取決於作業系統：
- macOS: LaunchAgent (`bot.molt.gateway` 或 `bot.molt.<profile>`；舊版為 `com.openclaw.*`)
- Linux/WSL2: systemd 使用者服務 (`openclaw-gateway[-<profile>].service`)
