---
summary: "使用 SSH tunnels（Gateway WS）與 tailnets 進行遠端存取"
read_when:
  - 運行或疑難排解遠端 Gateway 設定時
title: "Remote Access（遠端存取）"
---

# 遠端存取（SSH、tunnels 與 tailnets）

此 repo 支援「SSH 遠端」，方式是讓單一 Gateway（主機）在專用主機（桌機/伺服器）上運行，並讓 client 連線至它。

- 對於 **operator（您 / macOS app）**：SSH tunneling 是通用的 fallback。
- 對於 **節點（iOS/Android 及未來設備）**：直接連線至 Gateway **WebSocket**（LAN/tailnet 或視需要使用 SSH tunnel）。

## 核心概念

- Gateway WebSocket 綁定至您設定埠的 **loopback**（預設 18789）。
- 對於遠端使用，您透過 SSH 轉送該 loopback 埠（或使用 tailnet/VPN 減少 tunnel 需求）。

## 常見 VPN/tailnet 設定（Agent 所在位置）

將 **Gateway 主機**視為「Agent 所在位置」。它擁有 sessions、auth profiles、頻道和狀態。
您的筆電/桌機（以及節點）連線至該主機。

### 1) 在您的 tailnet 中的長期運行 Gateway（VPS 或家用伺服器）

在持久性主機上運行 Gateway，並透過 **Tailscale** 或 SSH 存取。

- **最佳體驗：** 保持 `gateway.bind: "loopback"` 並使用 **Tailscale Serve** 供 Control UI 使用。
- **Fallback：** 保持 loopback + 從任何需要存取的機器建立 SSH tunnel。
- **範例：** [exe.dev](/zh-Hant/install/exe-dev)（簡易 VM）或 [Hetzner](/zh-Hant/install/hetzner)（生產 VPS）。

當您的筆電經常休眠但希望 agent 持續運作時，這是理想選擇。

### 2) 家用桌機運行 Gateway，筆電作為遠端控制

筆電**不**執行 agent，而是遠端連線：

- 使用 macOS app 的 **Remote over SSH** 模式（Settings → General → "OpenClaw runs"）。
- App 會開啟並管理 tunnel，讓 WebChat + 健康檢查「自動運作」。

操作手冊：[macOS remote access](/zh-Hant/platforms/mac/remote)。

### 3) 筆電運行 Gateway，從其他機器遠端存取

保持 Gateway 在本地，但安全地暴露它：

- 從其他機器 SSH tunnel 到筆電，或
- 使用 Tailscale Serve 提供 Control UI 並保持 Gateway 僅限 loopback。

指南：[Tailscale](/zh-Hant/gateway/tailscale) 和 [Web overview](/zh-Hant/web)。

## 指令流程（各自運行的位置）

一個 gateway 服務擁有狀態 + 頻道。節點是週邊設備。

流程範例（Telegram → 節點）：

- Telegram 訊息抵達 **Gateway**。
- Gateway 執行 **agent** 並決定是否呼叫節點工具。
- Gateway 透過 Gateway WebSocket 呼叫 **節點**（`node.*` RPC）。
- 節點返回結果；Gateway 回覆給 Telegram。

注意事項：

- **節點不執行 gateway 服務。** 每個主機只應執行一個 gateway，除非您刻意執行隔離的 profiles（參見 [Multiple gateways](/zh-Hant/gateway/multiple-gateways)）。
- macOS app 的「節點模式」只是透過 Gateway WebSocket 的節點 client。

## SSH tunnel（CLI + 工具）

建立到遠端 Gateway WS 的本地 tunnel：

```bash
ssh -N -L 18789:127.0.0.1:18789 user@host
```

建立 tunnel 後：

- `openclaw health` 和 `openclaw status --deep` 現在可以透過 `ws://127.0.0.1:18789` 連到遠端 gateway。
- `openclaw gateway {status,health,send,agent,call}` 也可以在需要時透過 `--url` 指定轉送的 URL。

注意：將 `18789` 替換為您設定的 `gateway.port`（或 `--port`/`OPENCLAW_GATEWAY_PORT`）。
注意：當您傳遞 `--url` 時，CLI 不會 fallback 到設定或環境憑證。
請明確包含 `--token` 或 `--password`。缺少明確憑證是錯誤。

## CLI 遠端預設值

您可以持久化遠端目標，讓 CLI 指令預設使用它：

```json5
{
  gateway: {
    mode: "remote",
    remote: {
      url: "ws://127.0.0.1:18789",
      token: "your-token",
    },
  },
}
```

當 gateway 僅限 loopback 時，保持 URL 為 `ws://127.0.0.1:18789` 並先開啟 SSH tunnel。

## 憑證優先順序

Gateway 憑證解析遵循跨 call/probe/status 路徑、Discord exec-approval 監控和節點主機連線的共享規約：

- 明確憑證（`--token`、`--password` 或工具 `gatewayToken`）在接受明確認證的 call 路徑上優先。
- URL 覆蓋安全性：
  - CLI URL 覆蓋（`--url`）永不重複使用隱式設定/環境憑證。
  - 環境 URL 覆蓋（`OPENCLAW_GATEWAY_URL`）只能使用環境憑證（`OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`）。
- 本地模式預設：
  - token：`OPENCLAW_GATEWAY_TOKEN` -> `gateway.auth.token` -> `gateway.remote.token`
  - password：`OPENCLAW_GATEWAY_PASSWORD` -> `gateway.auth.password` -> `gateway.remote.password`
- 遠端模式預設：
  - token：`gateway.remote.token` -> `OPENCLAW_GATEWAY_TOKEN` -> `gateway.auth.token`
  - password：`OPENCLAW_GATEWAY_PASSWORD` -> `gateway.remote.password` -> `gateway.auth.password`
- 遠端 probe/status token 檢查預設嚴格：針對遠端模式時只使用 `gateway.remote.token`（無本地 token fallback）。
- 舊版 `CLAWDBOT_GATEWAY_*` 環境變數只被相容性 call 路徑使用；probe/status/auth 解析只使用 `OPENCLAW_GATEWAY_*`。

## Chat UI over SSH

WebChat 不再使用獨立的 HTTP 埠。SwiftUI chat UI 直接連線到 Gateway WebSocket。

- 透過 SSH 轉送 `18789`（參見上方），然後讓 client 連線至 `ws://127.0.0.1:18789`。
- 在 macOS 上，優先使用 app 的「Remote over SSH」模式，它會自動管理 tunnel。

## macOS app「Remote over SSH」

macOS menu bar app 可以端到端驅動相同的設定（遠端狀態檢查、WebChat 和 Voice Wake 轉送）。

操作手冊：[macOS remote access](/zh-Hant/platforms/mac/remote)。

## 安全規則（遠端/VPN）

簡短版本：**保持 Gateway 僅限 loopback**，除非您確定需要綁定。

- **Loopback + SSH/Tailscale Serve** 是最安全的預設值（無公開暴露）。
- 明文 `ws://` 預設僅限 loopback。對於受信任的私有網路，在 client 程序上設定 `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1` 作為緊急情況。
- **非 loopback 綁定**（`lan`/`tailnet`/`custom` 或 loopback 不可用時的 `auto`）必須使用認證 token/password。
- `gateway.remote.token` / `.password` 是 client 憑證來源。它們**本身不**保護本地 WS 存取。
- 本地 call 路徑在 `gateway.auth.*` 未設定時可以使用 `gateway.remote.*` 作為 fallback。
- `gateway.remote.tlsFingerprint` 在使用 `wss://` 時固定遠端 TLS 憑證。
- **Tailscale Serve** 可以在 `gateway.auth.allowTailscale: true` 時透過身份 header 認證 Control UI/WebSocket 流量；HTTP API endpoint 仍需要 token/password 認證。此無 token 流程假設 gateway 主機受信任。若您希望所有地方都使用 token/password，設定為 `false`。
- 將瀏覽器控制視為 operator 存取：僅限 tailnet + 刻意的節點配對。

深入探討：[Security](/zh-Hant/gateway/security)。
