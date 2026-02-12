---
summary: "Gateway 儀表板（Control UI）存取和驗證"
read_when:
  - 更改儀表板驗證或曝露模式
title: "Dashboard（儀表板）"
---

# 儀表板（Control UI）

Gateway 儀表板是由 `/` 預設提供的瀏覽器 Control UI
（使用 `gateway.controlUi.basePath` 覆蓋）。

快速開啟（本機 Gateway）：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

主要參考資料：

- [Control UI](/zh-Hant/web/control-ui) 用於使用和 UI 功能。
- [Tailscale](/zh-Hant/gateway/tailscale) 用於 Serve/Funnel 自動化。
- [Web 介面](/zh-Hant/web) 用於繫結模式和安全筆記。

驗證在 WebSocket 握手時透過 `connect.params.auth` 執行
（標記或密碼）。詳見[Gateway 設定](/zh-Hant/gateway/configuration)中的 `gateway.auth`。

安全筆記：Control UI 是一個**管理員介面**（聊天、設定、Exec 核准）。
不要公開曝露。UI 在首次載入後在 `localStorage` 中儲存標記。
偏好 localhost、Tailscale Serve 或 SSH 隧道。

## 快速路徑（建議）

- 上線後，CLI 自動開啟儀表板並列印乾淨的（非標記化的）連結。
- 隨時重新開啟：`openclaw dashboard`（複製連結、盡可能開啟瀏覽器、如果無頭顯示 SSH 提示）。
- 如果 UI 提示驗證，將 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）中的標記貼到 Control UI 設定。

## 標記基礎（本機與遠端）

- **本機主機**：開啟 `http://127.0.0.1:18789/`。
- **標記來源**：`gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）；UI 在連接後在 localStorage 中儲存副本。
- **不是本機主機**：使用 Tailscale Serve（如果 `gateway.auth.allowTailscale: true` 則無標記）、帶有標記的 tailnet 繫結或 SSH 隧道。詳見[Web 介面](/zh-Hant/web)。

## 如果你看到「unauthorized」/ 1008

- 確保 Gateway 可達（本機：`openclaw status`；遠端：SSH 隧道 `ssh -N -L 18789:127.0.0.1:18789 user@host` 然後開啟 `http://127.0.0.1:18789/`）。
- 從 Gateway 主機檢索標記：`openclaw config get gateway.auth.token`（或產生一個：`openclaw doctor --generate-gateway-token`）。
- 在儀表板設定中，將標記貼到驗證欄位，然後連接。
