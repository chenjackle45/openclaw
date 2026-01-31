---
title: "discovery(Discovery & Transports)"
summary: "Node 發現與傳輸機制 (Bonjour, Tailscale, SSH) 以尋找 Gateway"
read_when:
  - 實作或變更 Bonjour 發現/廣播時
  - 調整遠端連線模式 (Direct vs SSH) 時
  - 設計遠端 Node 的發現 + 配對時
---

# 發現與傳輸 (Discovery & Transports)

OpenClaw 面臨兩個表面上看起來相似的不同問題：

1) **操作者遠端控制 (Operator remote control)**: macOS Menu Bar App 控制運行在別處的 Gateway。
2) **Node 配對 (Node pairing)**: iOS/Android (以及未來的 Nodes) 安全地尋找 Gateway 並進行配對。

設計目標是將所有網路發現/廣播保留在 **Node Gateway** (`openclaw gateway`) 中，並讓 Clients (mac app, iOS) 作為消費者。

## 術語

- **Gateway**: 單一長執行的 Gateway 程序，擁有狀態 (Sessions, Pairing, Node Registry) 並運行 Channels。多數設定每台主機使用一個；支援隔離的多 Gateway 設定。
- **Gateway WS (control plane)**: 預設位於 `127.0.0.1:18789` 的 WebSocket Endpoint；可透過 `gateway.bind` 綁定至 LAN/tailnet。
- **Direct WS transport**: 面向 LAN/tailnet 的 Gateway WS Endpoint (無 SSH)。
- **SSH transport (fallback)**: 透過 SSH 轉發 `127.0.0.1:18789` 進行遠端控制。
- **Legacy TCP bridge (deprecated/removed)**: 舊版 Node 傳輸 (參閱 [Bridge protocol](/gateway/bridge-protocol))；不再廣播以供發現。

協定細節:
- [Gateway protocol](/gateway/protocol)
- [Bridge protocol (legacy)](/gateway/bridge-protocol)

## 為何我們同時保留 "Direct" 與 SSH

- **Direct WS** 在同一個網路與 Tailnet 內提供最佳 UX：
  - 透過 Bonjour 在 LAN 上自動發現
  - 配對 Tokens + ACLs 由 Gateway 擁有
  - 無需 Shell 存取權限；協定表面可保持緊密且可稽核
- **SSH** 仍是通用的 Fallback：
  - 在任何您擁有 SSH 存取權限的地方皆可運作 (即使跨越不相關的網路)
  - 可在 Multicast/mDNS 問題下存活
  - 除了 SSH 外無需新的 Inbound Ports

## 發現輸入 (Clients 如何得知 Gateway 在哪)

### 1) Bonjour / mDNS (僅限 LAN)

Bonjour 是盡力而為的機制且不跨越網路。它僅用於“同一個 LAN”的便利性。

目標方向:
- **Gateway** 透過 Bonjour 廣播其 WS Endpoint。
- Clients 瀏覽並顯示“選擇 Gateway”清單，然後儲存選定的 Endpoint。

故障排除與 Beacon 細節: [Bonjour](/gateway/bonjour)。

#### Service Beacon 細節

- Service types:
  - `_openclaw-gw._tcp` (Gateway 傳輸信標)
- TXT Keys (非機密):
  - `role=gateway`
  - `lanHost=<hostname>.local`
  - `sshPort=22` (或任何廣播的 Port)
  - `gatewayPort=18789` (Gateway WS + HTTP)
  - `gatewayTls=1` (僅當 TLS 啟用時)
  - `gatewayTlsSha256=<sha256>` (僅當 TLS 啟用且 Fingerprint 可用時)
  - `canvasPort=18793` (預設 Canvas Host Port; 服務 `/__openclaw__/canvas/`)
  - `cliPath=<path>` (選用; 可運行的 `openclaw` Entrypoint 或 Binary 的絕對路徑)
  - `tailnetDns=<magicdns>` (選用提示; 當 Tailscale 可用時自動偵測)

停用/覆蓋:
- `OPENCLAW_DISABLE_BONJOUR=1` 停用廣播。
- `~/.openclaw/openclaw.json` 中的 `gateway.bind` 控制 Gateway Bind Mode。
- `OPENCLAW_SSH_PORT` 覆蓋 TXT 中廣播的 SSH Port (預設為 22)。
- `OPENCLAW_TAILNET_DNS` 發布 `tailnetDns` 提示 (MagicDNS)。
- `OPENCLAW_CLI_PATH` 覆蓋廣播的 CLI Path。

### 2) Tailnet (跨網路)

對於 London/Vienna 風格的設定，Bonjour 無法協助。推薦的“Direct”目標是：
- Tailscale MagicDNS 名稱 (首選) 或穩定的 Tailnet IP。

若 Gateway 能偵測到它在 Tailscale 下運行，它會發布 `tailnetDns` 作為給 Clients 的選用提示 (包含廣域 Beacons)。

### 3) Manual / SSH Target

當沒有直接路徑 (或 Direct 被停用) 時，Clients 總是能透過轉發 Loopback Gateway Port 的 SSH 連線。

參閱 [Remote access](/gateway/remote)。

## 傳輸選擇 (Client Policy)

推薦的 Client 行為:

1) 若已設定並可達該 Paired Direct Endpoint，使用它。
2) 否則，若 Bonjour 在 LAN 上找到 Gateway，提供一鍵“使用此 Gateway”選擇並將其儲存為 Direct Endpoint。
3) 否則，若已設定 Tailnet DNS/IP，嘗試 Direct。
4) 否則，Fallback 至 SSH。

## 配對 + Auth (Direct Transport)

Gateway 是 Node/Client 准入的 Source of Truth。

- 配對請求在 Gateway 中建立/核准/拒絕 (參閱 [Gateway pairing](/gateway/pairing))。
- Gateway 強制執行:
  - Auth (Token / Keypair)
  - Scopes/ACLs (Gateway 並非每個方法的 Raw Proxy)
  - Rate Limits

## 元件職責

- **Gateway**: 廣播 Discovery Beacons，擁有配對決策，並託管 WS Endpoint。
- **macOS app**: 協助您挑選 Gateway，顯示配對提示，並僅將 SSH 用作 Fallback。
- **iOS/Android nodes**: 為了便利瀏覽 Bonjour 並連線至已配對的 Gateway WS。
