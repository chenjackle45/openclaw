---
title: "protocol(Gateway protocol (WebSocket))"
summary: "Gateway WebSocket 協定: Handshake, Frames, Versioning"
read_when:
  - 實作或更新 Gateway WS Clients 時
  - 除錯 Protocol Mismatches 或 Connect Failures 時
  - 重新產生 Protocol Schema/Models 時
---

# Gateway Protocol (WebSocket)

Gateway WS Protocol 是 OpenClaw 的 **單一控制平面 + Node 傳輸**。所有 Clients (CLI, Web UI, macOS App, iOS/Android Nodes, Headless Nodes) 透過 WebSocket 連線並在 Handshake 時宣告其 **Role** + **Scope**。

## 傳輸 (Transport)

- WebSocket, 帶有 JSON Payloads 的 Text Frames。
- 第一個 Frame **必須** 是 `connect` 請求。

## 握手 (Handshake)

Gateway → Client (Pre-connect Challenge):

```json
{
  "type": "event",
  "event": "connect.challenge",
  "payload": { "nonce": "…", "ts": 1737264000000 }
}
```

Client → Gateway:

```json
{
  "type": "req",
  "id": "…",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "cli",
      "version": "1.2.3",
      "platform": "macos",
      "mode": "operator"
    },
    "role": "operator",
    "scopes": ["operator.read", "operator.write"],
    "caps": [],
    "commands": [],
    "permissions": {},
    "auth": { "token": "…" },
    "locale": "en-US",
    "userAgent": "openclaw-cli/1.2.3",
    "device": {
      "id": "device_fingerprint",
      "publicKey": "…",
      "signature": "…",
      "signedAt": 1737264000000,
      "nonce": "…"
    }
  }
}
```

Gateway → Client:

```json
{
  "type": "res",
  "id": "…",
  "ok": true,
  "payload": { "type": "hello-ok", "protocol": 3, "policy": { "tickIntervalMs": 15000 } }
}
```

當 Device Token 被發行時，`hello-ok` 亦包含：

```json
{
  "auth": {
    "deviceToken": "…",
    "role": "operator",
    "scopes": ["operator.read", "operator.write"]
  }
}
```

### Node 範例

```json
{
  "type": "req",
  "id": "…",
  "method": "connect",
  "params": {
    "minProtocol": 3,
    "maxProtocol": 3,
    "client": {
      "id": "ios-node",
      "version": "1.2.3",
      "platform": "ios",
      "mode": "node"
    },
    "role": "node",
    "scopes": [],
    "caps": ["camera", "canvas", "screen", "location", "voice"],
    "commands": ["camera.snap", "canvas.navigate", "screen.record", "location.get"],
    "permissions": { "camera.capture": true, "screen.record": false },
    "auth": { "token": "…" },
    "locale": "en-US",
    "userAgent": "openclaw-ios/1.2.3",
    "device": {
      "id": "device_fingerprint",
      "publicKey": "…",
      "signature": "…",
      "signedAt": 1737264000000,
      "nonce": "…"
    }
  }
}
```

## Framing

- **Request**: `{type:"req", id, method, params}`
- **Response**: `{type:"res", id, ok, payload|error}`
- **Event**: `{type:"event", event, payload, seq?, stateVersion?}`

有副作用的方法 (Side-effecting methods) 需要 **Idempotency Keys** (參閱 Schema)。

## Roles + Scopes

### Roles
- `operator` = Control Plane Client (CLI/UI/Automation)。
- `node` = Capability Host (Camera/Screen/Canvas/System.run)。

### Scopes (Operator)
常見 Scopes:
- `operator.read`
- `operator.write`
- `operator.admin`
- `operator.approvals`
- `operator.pairing`

### Caps/Commands/Permissions (Node)
Nodes 在 Connect 時宣告 Capability Claims：
- `caps`: 高階 Capability 類別。
- `commands`: Invoke 的指令 Allowlist。
- `permissions`: 細粒度開關 (例如 `screen.record`, `camera.capture`)。

Gateway 將這些視為 **Claims** 並強制執行伺服器端的 Allowlists。

## 存在 (Presence)

- `system-presence` 回傳以 Device Identity 為 Key 的項目。
- Presence Entries 包含 `deviceId`, `roles`, 與 `scopes`，以便 UIs 即使在 Device 同時作為 **Operator** 與 **Node** 連線時也能顯示單一列。

### Node Helper Methods

- Nodes 可呼叫 `skills.bins` 以取得目前的 Skill Executables 清單，用於 Auto-allow 檢查。

## Exec Approvals

- 當 Exec Request 需要核准時，Gateway 廣播 `exec.approval.requested`。
- Operator Clients 透過呼叫 `exec.approval.resolve` 來解決 (需要 `operator.approvals` Scope)。

## 版本控制 (Versioning)

- `PROTOCOL_VERSION` 位於 `src/gateway/protocol/schema.ts`。
- Clients 傳送 `minProtocol` + `maxProtocol`；伺服器拒絕不符者。
- Schema + Models 從 TypeBox Definitions 產生：
  - `pnpm protocol:gen`
  - `pnpm protocol:gen:swift`
  - `pnpm protocol:check`

## Auth (認證)

- 若設定了 `OPENCLAW_GATEWAY_TOKEN` (或 `--token`)，`connect.params.auth.token` 必須相符，否則 Socket 會被關閉。
- 配對後，Gateway 發行界定於 Connection Role + Scopes 的 **Device Token**。它在 `hello-ok.auth.deviceToken` 中回傳，Client 應持久化它以供未來連線使用。
- Device Tokens 可透過 `device.token.rotate` 與 `device.token.revoke` 進行輪替/撤銷 (需要 `operator.pairing` Scope)。

## Device Identity + Pairing

- Nodes 應包含從 Keypair Fingerprint 推導出的穩定 Device Identity (`device.id`)。
- Gateways 發行 Per Device + Role 的 Tokens。
- 除非啟用本地 Auto-approval，否則新的 Device IDs 需要配對核准。
- **Local** Connects 包含 Loopback 與 Gateway Host 自己的 Tailnet Address (因此 Same-host Tailnet Binds 仍可 Auto-approve)。
- 所有 WS Clients 在 `connect` 期間必須包含 `device` Identity (Operator + Node)。
- Control UI 僅當 `gateway.controlUi.allowInsecureAuth` 啟用時 (或 `gateway.controlUi.dangerouslyDisableDeviceAuth` 用於緊急修復時) 才可省略它。
- Non-local Connections 必須簽署 Server 提供的 `connect.challenge` Nonce。

## TLS + Pinning

- WS 連線支援 TLS。
- Clients 可選擇性地釘選 (Pin) Gateway Cert Fingerprint (參閱 `gateway.tls` Config 加上 `gateway.remote.tlsFingerprint` 或 CLI `--tls-fingerprint`)。

## Scope

此協定暴露 **完整的 Gateway API** (Status, Channels, Models, Chat, Agent, Sessions, Nodes, Approvals, etc.)。確切的 Surface 定義於 `src/gateway/protocol/schema.ts` 中的 TypeBox Schemas。
