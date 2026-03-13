---
title: "Dashboard（儀表板）"
summary: "Gateway 儀表板（控制 UI）存取和驗證"
read_when:
  - 變更儀表板驗證或暴露模式
---

# 儀表板（控制 UI）

Gateway 儀表板是由預設在 `/` 提供的瀏覽器控制 UI（使用 `gateway.controlUi.basePath` 覆寫）。

快速開啟（本地 Gateway）：

- [http://127.0.0.1:18789/](http://127.0.0.1:18789/)（或 [http://localhost:18789/](http://localhost:18789/)）

主要參考：

- [控制 UI](/zh-Hant/web/control-ui) 以取得使用和 UI 功能。
- [Tailscale](/zh-Hant/gateway/tailscale) 以取得 Serve／Funnel 自動化。
- [Web 表面](/zh-Hant/web) 以取得繫結模式和安全備註。

驗證在 WebSocket 握手時透過 `connect.params.auth`（令牌或密碼）強制執行。參閱 [Gateway 設定](/zh-Hant/gateway/configuration) 中的 `gateway.auth`。

安全備註：控制 UI 是 **管理表面**（聊天、設定、執行批准）。不要公開暴露它。UI 為目前瀏覽器標籤工作階段和所選 gateway URL 在 sessionStorage 中保持儀表板 URL 令牌，並在載入後從 URL 移除它們。
優先使用 localhost、Tailscale Serve 或 SSH 通道。

## 快速路徑（建議）

- 登機後，CLI 自動開啟儀表板並列印乾淨（非令牌化）連結。
- 隨時重新開啟：`openclaw dashboard`（複製連結、盡可能開啟瀏覽器、如果無頭則顯示 SSH 提示）。
- 如果 UI 提示驗證，從 `gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）貼到控制 UI 設定中。

## 令牌基礎（本地 vs 遠端）

- **Localhost**：開啟 `http://127.0.0.1:18789/`。
- **令牌來源**：`gateway.auth.token`（或 `OPENCLAW_GATEWAY_TOKEN`）；`openclaw dashboard` 可透過 URL 片段為一次性啟動並傳遞它，控制 UI 為目前瀏覽器標籤工作階段和所選 gateway URL 在 sessionStorage 中保持它，而不是 localStorage。
- 如果 `gateway.auth.token` 為 SecretRef 管理，`openclaw dashboard` 依設計列印／複製／開啟非令牌化 URL。這避免在 shell 記錄、剪貼簿歷史記錄或瀏覽器啟動引數中暴露外部管理令牌。
- 如果 `gateway.auth.token` 設定為 SecretRef 且在您目前的 shell 中未解析，`openclaw dashboard` 仍列印非令牌化 URL 加上可操作的驗證設定指導。
- **不是 localhost**：使用 Tailscale Serve（如果 `gateway.auth.allowTailscale: true`，假設受信 gateway 主機，無令牌的控制 UI／WebSocket；HTTP API 仍需要令牌／密碼）、tailnet 繫結加令牌或 SSH 通道。參閱 [Web 表面](/zh-Hant/web)。

## 如果您看到「unauthorized」/ 1008

- 確保 gateway 可到達（本地：`openclaw status`；遠端：SSH 通道 `ssh -N -L 18789:127.0.0.1:18789 user@host` 然後開啟 `http://127.0.0.1:18789/`）。
- 針對 `AUTH_TOKEN_MISMATCH`，當 gateway 傳回重試提示時，用戶端可能執行一次受信重試並使用快取設備令牌。如果驗證在該重試後仍失敗，手動解析令牌漂移。
- 針對令牌漂移修復步驟，遵循 [令牌漂移恢復檢查清單](/zh-Hant/cli/devices#token-drift-recovery-checklist)。
- 從 gateway 主機取得或提供令牌：
  - 純文字設定：`openclaw config get gateway.auth.token`
  - SecretRef 管理設定：解析外部機密提供者或在此 shell 中匯出 `OPENCLAW_GATEWAY_TOKEN`，然後重新執行 `openclaw dashboard`
  - 沒有設定令牌：`openclaw doctor --generate-gateway-token`
- 在儀表板設定中，將令牌貼到驗證欄位中，然後連接。
