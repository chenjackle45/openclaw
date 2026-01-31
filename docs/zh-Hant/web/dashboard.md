---
title: "Dashboard(儀表板)"
summary: "Gateway 儀表板 (Control UI) 存取與認證"
read_when:
  - 變更儀表板認證或公開模式時
---
# 儀表板 (Dashboard)

Gateway 儀表板即為瀏覽器控制介面 (Control UI)，預設路徑為 `/`（可透過 `gateway.controlUi.basePath` 覆蓋）。

### 快速開啟（本地執行時）：
- http://127.0.0.1:18789/ (或 http://localhost:18789/)

相關參考：
- [控制介面 (Control UI)](/web/control-ui)：功能與介面操作。
- [Tailscale](/gateway/tailscale)：自動化的 Serve/Funnel 功能。
- [網頁介面總覽](/web)：綁定模式與安全性說明。

認證機制是在 WebSocket 交握階段透過 `connect.params.auth`（Token 或密碼）強制執行的。詳見 [Gateway 配置](/gateway/configuration) 中的 `gateway.auth` 段落。

> [!CAUTION]
> 控制介面是具備**管理權限的介面**（包含聊天、配置、指令執行核准）。請勿將其公開暴露。介面會在首次載入後將 Token 存放在 `localStorage` 中。推薦使用 localhost、Tailscale Serve 或 SSH 隧道進行存取。

## 推薦路徑 (Recommended)

- 完成入門引導後，CLI 會自動開啟帶有 Token 的儀表板連結，並在終端機印出該連結。
- 隨時重新開啟：執行 `openclaw dashboard`（會複製連結，並在可能的情況下開啟瀏覽器；若在無頭伺服器上則會顯示 SSH 提示）。
- Token 僅存在於本地（作為查詢參數）；介面在首次載入後會將其隱藏並儲存至 localStorage。

## Token 基礎（本地 vs 遠端）

- **Localhost (本地)**：開啟 `http://127.0.0.1:18789/`。若看到「unauthorized」，請執行 `openclaw dashboard` 並使用帶有 Token 的連結 (`?token=...`)。
- **Token 來源**：`gateway.auth.token` (或環境變數 `OPENCLAW_GATEWAY_TOKEN`)。
- **非 Localhost (遠端)**：建議使用 Tailscale Serve (若開啟 `gateway.auth.allowTailscale` 則無需 Token)、或是透過 Token 綁定至 tailnet、或使用 SSH 隧道。詳見 [網頁介面總覽](/web)。

## 若出現「unauthorized」或 1008 錯誤

- 執行 `openclaw dashboard` 獲取最新的 Token 連結。
- 確保 Gateway 可存取（本地：`openclaw status`；遠端：使用 SSH 隧道 `ssh -N -L 18789:127.0.0.1:18789 user@host` 後開啟 `http://127.0.0.1:18789/?token=...`）。
- 在儀表板設定中，貼上您在 `gateway.auth.token` (或 `OPENCLAW_GATEWAY_TOKEN`) 中配置的同一個 Token。
