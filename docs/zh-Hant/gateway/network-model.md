---
title: "Network model（網路模型）"
summary: "Gateway、節點和 Canvas 主機如何連接"
read_when:
  - 您想要 Gateway 網路模型的簡潔檢視
---

大多數操作透過 Gateway（`openclaw gateway`）進行，這是單一長時間執行的程序，擁有頻道連接和 WebSocket 控制平面。

## 核心規則

- 建議每個主機一個 Gateway。它是唯一允許擁有 WhatsApp Web 會話的程序。針對救援機器人或嚴格隔離，使用隔離的設定檔和連接埠執行多個 Gateway。請參閱 [Multiple gateways](/zh-Hant/gateway/multiple-gateways)。
- 迴圈首先：Gateway WS 預設為 `ws://127.0.0.1:18789`。即使對於迴圈，精靈也預設生成 Gateway 權杖。針對 tailnet 存取，執行 `openclaw gateway --bind tailnet --token ...`，因為非迴圈綁定需要權杖。
- 節點透過 LAN、tailnet 或 SSH 根據需要連接到 Gateway WS。舊版 TCP 橋已棄用。
- Canvas 主機是 `canvasHost.port`（預設 `18793`）上的 HTTP 檔案伺服器，為節點 WebViews 提供 `/__openclaw__/canvas/`。請參閱 [Gateway configuration](/zh-Hant/gateway/configuration)（`canvasHost`）。
- 遠端使用通常是 SSH 通道或 tailnet VPN。請參閱 [Remote access](/zh-Hant/gateway/remote) 和 [Discovery](/zh-Hant/gateway/discovery)。
