---
summary: "Gateway 儀表板（Control UI）存取與驗證"
read_when:
  - 變更儀表板驗證或暴露模式
title: "Dashboard（儀表板）"
---

# 儀表板（Control UI）

Gateway 儀表板是預設在 `/` 提供的瀏覽器 Control UI（使用 `gateway.controlUi.basePath` 覆蓋）。

快速開啟（本地 Gateway）：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

重要參考：

- [Control UI](/zh-Hant/web/control-ui) 用於使用方式與 UI 功能。
- [Tailscale](/zh-Hant/gateway/tailscale) 用於 Serve/Funnel 自動化。
- [Web 介面](/zh-Hant/web) 用於綁定模式與安全注意事項。

驗證透過 `connect.params.auth`（token 或密碼）在 WebSocket 握手時強制執行。請見 [Gateway 設定](/zh-Hant/gateway/configuration) 中的 `gateway.auth`。

安全注意事項：Control UI 是**管理員介面**（聊天、設定、exec 核准）。請勿公開暴露。UI 會將儀表板 URL token 保留在目前分頁的記憶體中，並在載入後從 URL 中剝除。
建議使用 localhost、Tailscale Serve 或 SSH 隧道。

## 快速路徑（建議）

- 入門後，CLI 會自動開啟儀表板並列印乾淨（非 tokenized）的連結。
- 隨時重新開啟：`openclaw dashboard`（複製連結、盡可能開啟瀏覽器、無頭時顯示 SSH 提示）。
- 若 UI 提示驗證，將 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）中的 token 貼入 Control UI 設定。

## Token 基本說明（本地 vs 遠端）

- **Localhost**：開啟 `http://127.0.0.1:18789/`。
- **Token 來源**：`gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）；`openclaw dashboard` 可透過 URL fragment 一次性傳遞 token 進行啟動，但 Control UI 不會將 gateway token 持久化至 localStorage。
- 若 `gateway.auth.token` 由 SecretRef 管理，`openclaw dashboard` 依設計會列印/複製/開啟非 tokenized 的 URL。這避免在 shell 記錄、剪貼簿歷程或瀏覽器啟動參數中暴露外部管理的 token。
- 若 `gateway.auth.token` 設定為 SecretRef 且在目前 shell 中無法解析，`openclaw dashboard` 仍會列印非 tokenized 的 URL，並提供可操作的驗證設定指引。
- **非 localhost**：使用 Tailscale Serve（當 `gateway.auth.allowTailscale: true` 時，Control UI/WebSocket 不需 token，假設 gateway 主機受信任；HTTP API 仍需 token/密碼）、帶 token 的 tailnet 綁定，或 SSH 隧道。請見 [Web 介面](/zh-Hant/web)。

## 若你看到「unauthorized」/ 1008

- 確認 gateway 可達（本地：`openclaw status`；遠端：SSH 隧道 `ssh -N -L 18789:127.0.0.1:18789 user@gateway-host` 然後開啟 `http://127.0.0.1:18789/`）。
- 從 gateway 主機取得或提供 token：
  - 明文設定：`openclaw config get gateway.auth.token`
  - SecretRef 管理的設定：解析外部 secret 提供商，或在此 shell 中匯出 `OPENCLAW_GATEWAY_TOKEN`，然後重新執行 `openclaw dashboard`
  - 未設定 token：`openclaw doctor --generate-gateway-token`
- 在儀表板設定中，將 token 貼入驗證欄位，然後連線。
