---
title: "Index(Web 介面)"
summary: "Gateway 網頁介面：控制介面、綁定模式與安全性"
read_when:
  - 您想要透過 Tailscale 存取 Gateway 時
  - 您想要使用瀏覽器控制介面與編輯配置時
---
# 使用者介面 (Web)

Gateway 透過與 WebSocket 相同的連接埠，提供了一個輕量級的**瀏覽器控制介面 (Control UI)**（基於 Vite + Lit）：

- 預設路徑：`http://<host>:18789/`
- 選用的前綴路徑：設定 `gateway.controlUi.basePath`（例如 `/openclaw`）

功能詳情請參閱 [控制介面 (Control UI)](/web/control-ui)。
本頁面重點介紹綁定模式、安全性以及面向網頁的介面。

## Webhooks

當 `hooks.enabled=true` 時，Gateway 也會在同一個 HTTP 伺服器上暴露一個 Webhook 端點。
關於認證與內容酬載，請參閱 [Gateway 配置](/gateway/configuration) → `hooks` 段落。

## 配置（預設開啟）

當 `dist/control-ui` 中存在資源檔案時，控制介面將**預設啟用**。
您可以透由配置進行控制：

```json5
{
  gateway: {
    controlUi: { enabled: true, basePath: "/openclaw" } // basePath 為選填
  }
}
```

## Tailscale 存取

### 整合式 Serve 模式（推薦做法）

將 Gateway 保持在 loopback（本地回環），並讓 Tailscale Serve 進行代理：

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "serve" }
  }
}
```

然後啟動 Gateway：

```bash
openclaw gateway
```

存取路徑：
- `https://<magicdns>/`（或您自訂的 `gateway.controlUi.basePath`）

### Tailnet 綁定 + Token 模式

```json5
{
  gateway: {
    bind: "tailnet",
    controlUi: { enabled: true },
    auth: { mode: "token", token: "your-token" }
  }
}
```

啟動 Gateway（非 loopback 綁定必須提供 Token）：

```bash
openclaw gateway
```

存取路徑：
- `http://<tailscale-ip>:18789/`（或您自訂的 `gateway.controlUi.basePath`）

### 公網存取 (Funnel)

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "funnel" },
    auth: { mode: "password" } // 或設定 OPENCLAW_GATEWAY_PASSWORD
  }
}
```

## 安全注意事項

- Gateway 預設需要認證（Token/密碼或 Tailscale 身份標頭）。
- 非 loopback 綁定**必須**對應一個共享的 Token 或密碼。
- 入門精靈預設會生成一個 Gateway Token。
- 控制介面會發送 `connect.params.auth.token` 或 `connect.params.auth.password` 進行驗證。
- 使用 Serve 模式時，若 `gateway.auth.allowTailscale` 為 `true`，則 Tailscale 身份標頭可滿足認證要求。詳見 [Tailscale](/gateway/tailscale) 與 [安全性](/gateway/security)。
- 模式 `gateway.tailscale.mode: "funnel"` 必須搭配 `gateway.auth.mode: "password"`。

## 建置介面資源

Gateway 透過 `dist/control-ui` 提供靜態檔案。您可以使用以下指令建置：

```bash
pnpm ui:build # 首次執行時會自動安裝 UI 依賴
```
