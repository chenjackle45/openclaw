---
title: "Vps(VPS 主機)"
summary: "OpenClaw 的 VPS 主機中心 (Oracle/Fly/Hetzner/GCP/exe.dev)"
read_when:
  - 您想在雲端運行 Gateway
  - 您需要 VPS/主機指南的快速地圖
---
# VPS hosting(VPS 主機)

此中心連結到支援的 VPS/主機指南，並從高層次解釋雲端部署的運作方式。

## 選擇供應商

- **Railway**（一鍵式 + 瀏覽器設定）：[Railway](/railway)
- **Northflank**（一鍵式 + 瀏覽器設定）：[Northflank](/northflank)
- **Oracle Cloud (Always Free)**：[Oracle](/platforms/oracle) — 每月 $0（Always Free, ARM；容量/註冊可能有點挑剔）
- **Fly.io**：[Fly.io](/platforms/fly)
- **Hetzner (Docker)**：[Hetzner](/platforms/hetzner)
- **GCP (Compute Engine)**：[GCP](/platforms/gcp)
- **exe.dev** (VM + HTTPS proxy)：[exe.dev](/platforms/exe-dev)
- **AWS (EC2/Lightsail/free tier)**：也運作良好。影片指南：
  https://x.com/techfrenAJ/status/2014934471095812547

## 雲端設定如何運作

- **Gateway 在 VPS 上運行**並擁有狀態 + 工作區。
- 您從筆記型電腦/手機透過 **Control UI** 或 **Tailscale/SSH** 連線。
- 將 VPS 視為真實來源並**備份**狀態 + 工作區。
- 安全預設：將 Gateway 保持在 loopback 上，並透過 SSH tunnel 或 Tailscale Serve 存取它。
  如果您綁定到 `lan`/`tailnet`，需要 `gateway.auth.token` 或 `gateway.auth.password`。

遠端存取：[Gateway remote](/gateway/remote)  
平台中心：[Platforms](/platforms)

## 將節點與 VPS 一起使用

您可以將 Gateway 保留在雲端，並在本地裝置上配對**節點**
(Mac/iOS/Android/無頭模式)。節點提供本地螢幕/相機/畫布和 `system.run`
功能，而 Gateway 保留在雲端。

文件：[Nodes](/nodes)、[Nodes CLI](/cli/nodes)
