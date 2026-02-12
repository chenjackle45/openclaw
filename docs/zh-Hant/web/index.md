---
summary: "Gateway web 介面：Control UI、繫結模式和安全"
read_when:
  - 你想透過 Tailscale 存取 Gateway
  - 你想要瀏覽器 Control UI 和設定編輯
title: "Web（Web）"
---

# Web（Gateway）

Gateway 從與 Gateway WebSocket 相同的連接埠提供一個小的**瀏覽器 Control UI**（Vite + Lit）：

- 預設值：`http://<host>:18789/`
- 選擇性前綴：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

功能存在於[Control UI](/zh-Hant/web/control-ui)。
本頁面側重於繫結模式、安全和面向 Web 的介面。

## Webhook

當 `hooks.enabled=true` 時，Gateway 也在相同 HTTP 伺服器上公開一個小 Webhook 端點。
詳見[Gateway 設定](/zh-Hant/gateway/configuration) → `hooks` 了解驗證 + 負載。

## 設定（預設啟用）

當資產存在時（`dist/control-ui`），Control UI **預設啟用**。
你可以透過設定控制它：

```json5
{
  gateway: {
    controlUi: { enabled: true, basePath: "/openclaw" }, // basePath 選擇性
  },
}
```

## Tailscale 存取

### 整合 Serve（建議）

將 Gateway 保持在迴圈上，讓 Tailscale Serve 代理它：

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "serve" },
  },
}
```

然後啟動 Gateway：

```bash
openclaw gateway
```

開啟：

- `https://<magicdns>/`（或你設定的 `gateway.controlUi.basePath`）

### Tailnet 繫結 + 標記

```json5
{
  gateway: {
    bind: "tailnet",
    controlUi: { enabled: true },
    auth: { mode: "token", token: "your-token" },
  },
}
```

然後啟動 Gateway（非迴圈繫結需要標記）：

```bash
openclaw gateway
```

開啟：

- `http://<tailscale-ip>:18789/`（或你設定的 `gateway.controlUi.basePath`）

### 公網（Funnel）

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "funnel" },
    auth: { mode: "password" }, // 或 OPENCLAW_GATEWAY_PASSWORD
  },
}
```

## 安全筆記

- Gateway 驗證預設需要（標記/密碼或 Tailscale 身分標頭）。
- 非迴圈繫結仍然**需要**共享標記/密碼（`gateway.auth` 或環境）。
- 精靈預設產生 Gateway 標記（甚至在迴圈上）。
- Control UI 傳送 `connect.params.auth.token` 或 `connect.params.auth.password`。
- Control UI 傳送反點擊劫持標頭，並且僅接受相同來源瀏覽器 WebSocket 連接，除非設定了 `gateway.controlUi.allowedOrigins`。
- 使用 Serve，當 `gateway.auth.allowTailscale` 為 `true` 時，Tailscale 身分標頭可以滿足驗證（不需要標記/密碼）。設定 `gateway.auth.allowTailscale: false` 以需要明確認證。詳見[Tailscale](/zh-Hant/gateway/tailscale)和[安全](/zh-Hant/gateway/security)。
- `gateway.tailscale.mode: "funnel"` 需要 `gateway.auth.mode: "password"`（共享密碼）。

## 建置 UI

Gateway 從 `dist/control-ui` 提供靜態檔案。使用以下方式建置：

```bash
pnpm ui:build # 首次執行時自動安裝 UI 依賴項
```
