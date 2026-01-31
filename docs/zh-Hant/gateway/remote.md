---
title: "remote(Remote access (SSH, tunnels, and tailnets))"
summary: "使用 SSH Tunnels (Gateway WS) 與 Tailnets 進行遠端存取"
read_when:
  - 運行或疑難排解遠端 Gateway 設定時
---

# 遠端存取 (Remote access (SSH, tunnels, and tailnets))

本 repo 支援“SSH 遠端”，方式是讓單一 Gateway (The Master) 運行在專用主機 (Desktop/Server) 上，並讓 Clients 連線至它。

- 對 **Operators (您 / macOS App)**: SSH Tunneling 是通用的 Fallback。
- 對 **Nodes (iOS/Android 與未來的裝置)**: 連線至 Gateway **WebSocket** (依需求使用 LAN/tailnet 或 SSH tunnel)。

## 核心概念

- Gateway WebSocket 綁定至您設定 Port (預設 18789) 的 **Loopback**。
- 若要遠端使用，您透過 SSH 將該 Loopback Port 轉發出來 (或使用 Tailnet/VPN 以減少 Tunneling)。

## 常見 VPN/Tailnet 設定 (Agent 在哪裡)

將 **Gateway Host** 視為“Agent 居住的地方”。它擁有 Sessions, Auth Profiles, Channels 與 State。
您的 Laptop/Desktop (與 Nodes) 連線至該主機。

### 1) Tailnet 中永遠開啟的 Gateway (VPS 或家用 Server)

在持久的主機上運行 Gateway 並透過 **Tailscale** 或 SSH 連線。

- **最佳 UX:** 保持 `gateway.bind: "loopback"` 並使用 **Tailscale Serve** 作為 Control UI。
- **Fallback:** 保持 Loopback + SSH Tunnel，從任何需要存取的機器連線。
- **範例:** [exe.dev](/platforms/exe-dev) (簡單 VM) 或 [Hetzner](/platforms/hetzner) (Production VPS)。

當您的 Laptop 經常休眠但您希望 Agent 永遠開啟時，這是理想選擇。

### 2) 家用 Desktop 運行 Gateway，Laptop 進行遠端控制

Laptop **不** 運行 Agent。它遠端連線：

- 使用 macOS App 的 **Remote over SSH** 模式 (Settings → General → “OpenClaw runs”)。
- App 會開啟並管理 Tunnel，因此 WebChat + Health Checks “直接可用 (Just work)”。

Runbook: [macOS remote access](/platforms/mac/remote)。

### 3) Laptop 運行 Gateway，從其他機器遠端存取

保持 Gateway 本地運行但安全地暴露它：

- 從其他機器 SSH Tunnel 至 Laptop，或
- Tailscale Serve 該 Control UI 並保持 Gateway 僅限 Loopback。

指南: [Tailscale](/gateway/tailscale) 與 [Web overview](/web)。

## 指令流向 (什麼在哪運行)

一個 Gateway Service 擁有 State + Channels。Nodes 是周邊設備。

流程範例 (Telegram → Node):
- Telegram 訊息抵達 **Gateway**。
- Gateway 運行 **Agent** 並決定是否呼叫 Node Tool。
- Gateway 透過 Gateway WebSocket (`node.*` RPC) 呼叫 **Node**。
- Node 回傳結果；Gateway 回覆給 Telegram。

註記:
- **Nodes 不運行 Gateway Service。** 除非您刻意運行隔離的 Profiles，否則每台主機應僅運行一個 Gateway (參閱 [Multiple gateways](/gateway/multiple-gateways))。
- macOS App “Node Mode” 僅是 Gateway WebSocket 上的一個 Node Client。

## SSH Tunnel (CLI + Tools)

建立至 Remote Gateway WS 的本地 Tunnel：

```bash
ssh -N -L 18789:127.0.0.1:18789 user@host
```

當 Tunnel 建立後：
- `openclaw health` 與 `openclaw status --deep` 現在透過 `ws://127.0.0.1:18789` 到達 Remote Gateway。
- `openclaw gateway {status,health,send,agent,call}` 在需要時亦可透過 `--url` 目標至轉發的 URL。

註記: 將 `18789` 替換為您設定的 `gateway.port` (或 `--port`/`OPENCLAW_GATEWAY_PORT`)。

## CLI Remote Defaults

您可以持久化 Remote Target 以便 CLI 指令預設使用它：

```json5
{
  gateway: {
    mode: "remote",
    remote: {
      url: "ws://127.0.0.1:18789",
      token: "your-token"
    }
  }
}
```

當 Gateway 僅限 Loopback 時，保持 URL 為 `ws://127.0.0.1:18789` 並先開啟 SSH Tunnel。

## 透過 SSH 的 Chat UI

WebChat 不再使用分開的 HTTP Port。SwiftUI Chat UI 直接連線至 Gateway WebSocket。

- 透過 SSH 轉發 `18789` (見上文)，然後將 Clients 連線至 `ws://127.0.0.1:18789`。
- 在 macOS 上，優先使用 App 的 “Remote over SSH” 模式，它會自動管理 Tunnel。

## macOS App “Remote over SSH”

macOS Menu Bar App 可以端對端驅動相同的設定 (Remote Status Checks, WebChat, 與 Voice Wake Forwarding)。

Runbook: [macOS remote access](/platforms/mac/remote)。

## 安全性規則 (Remote/VPN)

簡短版本: **保持 Gateway 僅限 Loopback** 除非您確定需要 Bind。

- **Loopback + SSH/Tailscale Serve** 是最安全的預設值 (無 Public Exposure)。
- **Non-loopback binds** (`lan`/`tailnet`/`custom`, 或當 Loopback 不可用時的 `auto`) 必須使用 Auth Tokens/Passwords。
- `gateway.remote.token` **僅** 用於 Remote CLI Calls — 它 **不** 啟用 Local Auth。
- `gateway.remote.tlsFingerprint` 在使用 `wss://` 時釘選 (Pin) Remote TLS Cert。
- **Tailscale Serve** 當 `gateway.auth.allowTailscale: true` 時可透過 Identity Headers 進行認證。
  若您想要 Tokens/Passwords 則將其設為 `false`。
- 將 Browser Control 視為 Operator Access: 僅限 Tailnet + 審慎的 Node 配對。

深入探討: [Security](/gateway/security)。
