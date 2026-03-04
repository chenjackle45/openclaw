---
title: Hetzner
description: 在 Hetzner Cloud 上執行 OpenClaw
summary: "在 Hetzner Cloud VPS 上部署 OpenClaw Gateway（Docker）"
read_when:
  - 你想要在 Hetzner 上執行 OpenClaw
  - 你想要廉價、可靠的 VPS 託管
title: "Hetzner（Hetzner）"
---

# Hetzner Cloud 上的 OpenClaw（Docker VPS）

## 目標

在 Hetzner Cloud VPS 上使用 Docker 執行 OpenClaw Gateway，具有持久化狀態和簡單的設定管理。

## 需求

- Hetzner Cloud 帳號
- 基本的 SSH 和 Linux 命令行技能
- hcloud CLI（可選，或使用網路主控台）

## 快速路徑

1. 建立 Hetzner Cloud 專案
2. 建立 Debian 或 Ubuntu VM（cx11 或更大）
3. SSH 進入 VM
4. 執行 Docker 安裝
5. 克隆 OpenClaw 倉庫
6. 執行 docker-compose up

## 定價

- cx11 VPS：約 €4.90/月
- cx21 VPS：約 €9.90/月

詳見 [Hetzner Cloud 定價](https://www.hetzner.com/cloud/pricing/)。

## 注意

- 持久化資料應儲存在 Hetzner 卷上
- 使用 SSH 金鑰進行身分驗證
- 定期備份配置和工作區

詳見通用 Docker 工作流程 [Docker](/zh-Hant/install/docker)。
