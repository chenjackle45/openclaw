---
summary: "Gateway dashboard (Control UI) access and auth"
read_when:
  - Changing dashboard authentication or exposure modes
title: "Dashboard（儀表板）"
---

# 儀表板（Control UI）

閘道儀表板是預設在 `/` 服務的瀏覽器 Control UI
（使用 `gateway.controlUi.basePath` 覆蓋）。

快速開啟（本機閘道）：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

關鍵參考：

- [Control UI](/zh-Hant/web/control-ui) 用於使用和 UI 功能。
- [Tailscale](/zh-Hant/gateway/tailscale) 用於 Serve/Funnel 自動化。
- [Web 介面](/zh-Hant/web) 用於綁定模式和安全備註。

驗證在 WebSocket 握手透過 `connect.params.auth` 強制執行
（令牌或密碼）。請參閱 [閘道設定](/zh-Hant/gateway/configuration) 中的 `gateway.auth`。

安全備註：Control UI 是**管理員介面**（聊天、設定、執行核准）。
不要公開公開。UI 在首次載入後在 `localStorage` 中儲存令牌。
偏好 localhost、Tailscale Serve 或 SSH 通道。

## 快速路徑（建議）

- 入職後，CLI 自動開啟儀表板並列印乾淨（非令牌化）連結。
- 隨時重新開啟：`openclaw dashboard`（複製連結、盡可能開啟瀏覽器、無頭時顯示 SSH 提示）。
- 如果 UI 提示驗證，將 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）中的令牌貼到 Control UI 設定中。

## 令牌基本知識（本機與遠端）

- **Localhost**：開啟 `http://127.0.0.1:18789/`。
- **令牌來源**：`gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）；UI 在連線後在 localStorage 中儲存副本。
- **不是 localhost**：使用 Tailscale Serve（當 `gateway.auth.allowTailscale: true` 時無令牌用於 Control UI/WebSocket，假設受信閘道主機；HTTP API 仍需要令牌/密碼）、帶令牌的 tailnet 綁定或 SSH 通道。請參閱 [Web 介面](/zh-Hant/web)。

## 如果你看到「未授權」/ 1008

- 確保閘道可以到達（本機：`openclaw status`；遠端：SSH 通道 `ssh -N -L 18789:127.0.0.1:18789 user@host` 然後開啟 `http://127.0.0.1:18789/`）。
- 從閘道主機擷取令牌：`openclaw config get gateway.auth.token`（或產生一個：`openclaw doctor --generate-gateway-token`）。
- 在儀表板設定中，將令牌貼到驗證欄位中，然後連線。
