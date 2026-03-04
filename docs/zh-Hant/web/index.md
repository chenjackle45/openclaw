---
summary: "閘道網路介面：Control UI、綁定模式和安全"
read_when:
  - 您想透過 Tailscale 存取閘道
  - 您想要瀏覽器 Control UI 和設定編輯
title: "Web（網路介面）"
---

# 網路（閘道）

閘道從與閘道 WebSocket 相同的埠提供小型**瀏覽器 Control UI**（Vite + Lit）：

- 預設：`http://<host>:18789/`
- 選用前綴：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

功能位於 [Control UI](/zh-Hant/web/control-ui)。
此頁面重點介紹綁定模式、安全和面向網路的介面。

## Webhooks

當 `hooks.enabled=true` 時，閘道也會在相同的 HTTP 伺服器上公開小型 webhook 端點。
請參閱 [閘道設定](/zh-Hant/gateway/configuration) → `hooks` 以取得驗證 + 裝載。

## 設定（預設啟用）

當資產存在時（`dist/control-ui`），Control UI 預設**啟用**。
您可以透過設定控制它：

```json5
{
  gateway: {
    controlUi: { enabled: true, basePath: "/openclaw" }, // basePath 選用
  },
}
```

## Tailscale 存取

### 整合 Serve（建議）

將閘道保持在環迴上，讓 Tailscale Serve 代理它：

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "serve" },
  },
}
```

然後啟動閘道：

```bash
openclaw gateway
```

開啟：

- `https://<magicdns>/`（或您配置的 `gateway.controlUi.basePath`）

### Tailnet 綁定 + 令牌

```json5
{
  gateway: {
    bind: "tailnet",
    controlUi: { enabled: true },
    auth: { mode: "token", token: "your-token" },
  },
}
```

然後啟動閘道（非環迴綁定需要令牌）：

```bash
openclaw gateway
```

開啟：

- `http://<tailscale-ip>:18789/`（或您配置的 `gateway.controlUi.basePath`）

### 公開網際網路（Funnel）

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "funnel" },
    auth: { mode: "password" }, // 或 OPENCLAW_GATEWAY_PASSWORD
  },
}
```

## 安全備註

- 預設需要閘道驗證（令牌/密碼或 Tailscale 身分標頭）。
- 非環迴綁定仍**需要**共用令牌/密碼（`gateway.auth` 或環境）。
- 精靈預設產生閘道令牌（即使在環迴上）。
- UI 傳送 `connect.params.auth.token` 或 `connect.params.auth.password`。
- 針對非環迴 Control UI 部署，明確設定 `gateway.controlUi.allowedOrigins`（完整來源）。沒有它，閘道啟動預設會被拒絕。
- `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback=true` 啟用主機標頭來源回退模式，但是是危險的安全降級。
- 使用 Serve，Tailscale 身分標頭可以在 `gateway.auth.allowTailscale` 為 `true` 時滿足 Control UI/WebSocket 驗證（不需要令牌/密碼）。HTTP API 端點仍需要令牌/密碼。設定 `gateway.auth.allowTailscale: false` 以需要明確認證。請參閱 [Tailscale](/zh-Hant/gateway/tailscale) 和 [安全](/zh-Hant/gateway/security)。此無令牌流程假設閘道主機是可信的。
- `gateway.tailscale.mode: "funnel"` 需要 `gateway.auth.mode: "password"`（共用密碼）。

## 構建 UI

閘道從 `dist/control-ui` 提供靜態檔案。使用以下方式構建它們：

```bash
pnpm ui:build # 首次執行時自動安裝 UI 依賴項
```
