---
title: "tailscale(Tailscale (Gateway dashboard))"
summary: "為 Gateway Dashboard 整合 Tailscale Serve/Funnel"
read_when:
  - 在 Localhost 之外暴露 Gateway Control UI 時
  - 自動化 Tailnet 或 Public Dashboard 存取時
---

# Tailscale (Gateway dashboard)

OpenClaw 可以為 Gateway Dashboard 與 WebSocket Port 自動設定 Tailscale **Serve** (tailnet) 或 **Funnel** (public)。這讓 Gateway 保持綁定至 Loopback，同時由 Tailscale 提供 HTTPS, Routing, 與 Identity Headers (對於 Serve)。

## 模式 (Modes)

- `serve`: 透過 `tailscale serve` 進行 Tailnet-only Serve。Gateway 停留在 `127.0.0.1`。
- `funnel`: 透過 `tailscale funnel` 進行 Public HTTPS。OpenClaw 需要共用密碼。
- `off`: 預設值 (無 Tailscale 自動化)。

## 認證 (Auth)

設定 `gateway.auth.mode` 以控制 Handshake：

- `token` (當 `OPENCLAW_GATEWAY_TOKEN` 設定時的預設值)
- `password` (透過 `OPENCLAW_GATEWAY_PASSWORD` 或 Config 設定的共用密碼)

當 `tailscale.mode = "serve"` 且 `gateway.auth.allowTailscale` 為 `true` 時，有效的 Serve Proxy 請求可透過 Tailscale Identity Headers (`tailscale-user-login`) 進行認證，而無需提供 Token/Password。OpenClaw 透過 Local Tailscale Daemon (`tailscale whois`) 解析 `x-forwarded-for` 位址並與 Header 比對以驗證身份。OpenClaw 僅當請求來自 Loopback 且帶有 Tailscale 的 `x-forwarded-for`, `x-forwarded-proto`, 與 `x-forwarded-host` Headers 時才視為 Serve。

若要要求顯式憑證，設定 `gateway.auth.allowTailscale: false` 或強制 `gateway.auth.mode: "password"`。

## 設定範例

### Tailnet-only (Serve)

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "serve" }
  }
}
```

開啟: `https://<magicdns>/` (或您設定的 `gateway.controlUi.basePath`)

### Tailnet-only (Bind to Tailnet IP)

當您想要 Gateway 直接在 Tailnet IP 上監聽 (無 Serve/Funnel) 時使用此項。

```json5
{
  gateway: {
    bind: "tailnet",
    auth: { mode: "token", token: "your-token" }
  }
}
```

從另一台 Tailnet 裝置連線:
- Control UI: `http://<tailscale-ip>:18789/`
- WebSocket: `ws://<tailscale-ip>:18789`

註記: Loopback (`http://127.0.0.1:18789`) 在此模式下 **無法** 運作。

### Public Internet (Funnel + Shared Password)

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "funnel" },
    auth: { mode: "password", password: "replace-me" }
  }
}
```

優先使用 `OPENCLAW_GATEWAY_PASSWORD` 勝過將密碼提交至磁碟。

## CLI 範例

```bash
openclaw gateway --tailscale serve
openclaw gateway --tailscale funnel --auth password
```

## 註記

- Tailscale Serve/Funnel 需要已安裝 `tailscale` CLI 並登入。
- `tailscale.mode: "funnel"` 拒絕啟動除非 Auth Mode 為 `password`，以避免公開暴露。
- 設定 `gateway.tailscale.resetOnExit` 若您希望 OpenClaw 在關閉時復原 `tailscale serve` 或 `tailscale funnel` 設定。
- `gateway.bind: "tailnet"` 是直接 Tailnet Bind (無 HTTPS, 無 Serve/Funnel)。
- `gateway.bind: "auto"` 偏好 Loopback；若您想要 Tailnet-only 則使用 `tailnet`。
- Serve/Funnel 僅暴露 **Gateway Control UI + WS**。Nodes 透過相同的 Gateway WS Endpoint 連線，因此 Serve 可用於 Node 存取。

## 瀏覽器控制 (Remote Gateway + Local Browser)

若您在一台機器運行 Gateway 但想驅動另一台機器的瀏覽器，請在瀏覽器機器上運行 **Node Host** 並將兩者保持在相同 Tailnet 上。Gateway 會將瀏覽器動作 Proxy 至 Node；無需分開的 Control Server 或 Serve URL。

避免使用 Funnel 進行瀏覽器控制；像 Operator Access 一樣對待 Node 配對。

## Tailscale 先決條件與限制

- Serve 需要您的 Tailnet 啟用 HTTPS；若遺失 CLI 會提示。
- Serve 注入 Tailscale Identity Headers；Funnel 不會。
- Funnel 需要 Tailscale v1.38.3+, MagicDNS, 啟用 HTTPS, 以及 Funnel Node Attribute。
- Funnel 僅支援 Ports `443`, `8443`, 與 `10000` over TLS。
- macOS 上的 Funnel 需要 Open-source Tailscale App Variant。

## 了解更多

- Tailscale Serve Overview: https://tailscale.com/kb/1312/serve
- `tailscale serve` Command: https://tailscale.com/kb/1242/tailscale-serve
- Tailscale Funnel Overview: https://tailscale.com/kb/1223/tailscale-funnel
- `tailscale funnel` Command: https://tailscale.com/kb/1311/tailscale-funnel
