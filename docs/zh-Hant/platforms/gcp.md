---
title: GCP
description: 在 GCP 上執行 OpenClaw
summary: "在 GCP Compute Engine VM（Docker）上執行 OpenClaw Gateway 24/7，具有持久化狀態"
read_when:
  - 你想要 OpenClaw 在 GCP 上執行 24/7
  - 你想要在自己的 VM 上進行生產級、常駐的 Gateway
  - 你想要完全控制持久化、二進製檔案和重新啟動行為
title: "GCP（GCP）"
---

# GCP Compute Engine 上的 OpenClaw（Docker、生產 VPS 指南）

## 目標

在 GCP Compute Engine VM 上使用 Docker 執行持久的 OpenClaw Gateway，具有持久化狀態、內建二進製檔案和安全重新啟動行為。

如果你想要「OpenClaw 24/7，費用約 $5-12/月」，這是 Google Cloud 上的可靠設定。定價因機器類型和區域而異；選擇最小的 VM 以適應你的工作負載，如果遇到 OOM，則向上擴展。

## 我們在做什麼（簡單用語）？

- 建立 GCP 專案並啟用計費
- 建立 Compute Engine VM
- 安裝 Docker（隔離的應用執行時）
- 在 Docker 中啟動 OpenClaw Gateway
- 在主機上持久化 `~/.openclaw` + `~/.openclaw/workspace`（在重新啟動/重建後倖存）
- 通過 SSH 隧道從你的筆記型電腦訪問控制 UI

## 快速路徑（有經驗的運營者）

1. 建立 GCP 專案 + 啟用 Compute Engine API
2. 建立 Compute Engine VM（e2-small、Debian 12、20GB）
3. SSH 進入 VM
4. 安裝 Docker
5. 克隆 OpenClaw 倉庫
6. 建立持久化主機目錄
7. 配置 `.env` 和 `docker-compose.yml`
8. 烘焙必需的二進製檔案、建置並啟動

## 你需要什麼

- GCP 帳號（免費級別符合 e2-micro 資格）
- gcloud CLI 已安裝（或使用 Cloud Console）
- 從你的筆記型電腦進行 SSH 訪問
- 對 SSH + 複製/貼上 的基本掌握
- 約 20-30 分鐘
- Docker 和 Docker Compose
- 模型認證認證
- 選用提供者認證
  - WhatsApp QR
  - Telegram 機器人令牌
  - Gmail OAuth

## 更新

詳見通用 Docker 工作流程 [Docker](/zh-Hant/install/docker)。
