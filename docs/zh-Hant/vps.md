---
summary: "VPS 託管中樞（Oracle/Fly/Hetzner/GCP/exe.dev）"
read_when:
  - 你想在雲中執行 Gateway
  - 你需要 VPS/託管指南的快速地圖
title: "VPS Hosting（VPS 託管）"
---

# VPS 託管

此中樞連結支援的 VPS/託管指南，並在高級別解釋雲端部署的運作方式。

## 選擇提供者

- **Railway**（單鍵 + 瀏覽器設定）：[Railway](/zh-Hant/install/railway)
- **Northflank**（單鍵 + 瀏覽器設定）：[Northflank](/zh-Hant/install/northflank)
- **Oracle Cloud（永遠免費）**：[Oracle](/zh-Hant/platforms/oracle) — $0/月（永遠免費、ARM；容量/註冊可能很挑剔）
- **Fly.io**：[Fly.io](/zh-Hant/install/fly)
- **Hetzner（Docker）**：[Hetzner](/zh-Hant/install/hetzner)
- **GCP（Compute Engine）**：[GCP](/zh-Hant/install/gcp)
- **exe.dev**（VM + HTTPS 代理）：[exe.dev](/zh-Hant/install/exe-dev)
- **AWS（EC2/Lightsail/免費層）**：也能很好地運作。視頻指南：
  [https://x.com/techfrenAJ/status/2014934471095812547](https://x.com/techfrenAJ/status/2014934471095812547)

## 雲端設定的運作方式

- **Gateway 在 VPS 上執行**並擁有狀態 + 工作區。
- 你從筆記型電腦/手機透過 **Control UI** 或 **Tailscale/SSH** 連接。
- 將 VPS 視為事實的來源並**備份**狀態 + 工作區。
- 安全預設：將 Gateway 保持在迴圈上，並透過 SSH 隧道或 Tailscale Serve 存取。
  如果你繫結到 `lan`/`tailnet`，需要 `gateway.auth.token` 或 `gateway.auth.password`。

遠端存取：[Gateway 遠端](/zh-Hant/gateway/remote)  
平臺中樞：[平臺](/zh-Hant/platforms)

## 搭配 VPS 使用節點

你可以將 Gateway 保留在雲中，並在本機裝置（Mac/iOS/Android/無頭）上配對**節點**。節點提供本機螢幕/攝影機/Canvas 和 `system.run` 功能，同時 Gateway 保留在雲中。

文件：[節點](/zh-Hant/nodes)、[節點 CLI](/zh-Hant/cli/nodes)
