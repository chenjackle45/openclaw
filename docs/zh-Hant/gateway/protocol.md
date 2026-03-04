---
title: "Gateway Protocol（Gateway 協議）"
summary: "Gateway WebSocket 協議：握手、訊框、版本控制"
read_when:
  - 實作或更新 Gateway WS 用戶端時
  - 除錯協議不匹配或連線失敗時
  - 重新產生協議結構／模型時
---

# Gateway Protocol (WebSocket)

Gateway WS 協議是 OpenClaw 的**單一控制平面 + 節點傳輸**。所有用戶端（CLI、Web UI、macOS app、iOS／Android 節點、Headless 節點）透過 WebSocket 連線並在握手時宣告其**角色** + **範圍**。

## 傳輸

- WebSocket，帶有 JSON 承載的文字訊框。
- 第一個訊框**必須**是 `connect` 請求。

## 握手（連線）

Gateway → 用戶端（預連線挑戰）：

```json
{
  "type": "event",
  "event": "connect.challenge",
  "payload": { "nonce": "…", "ts": 1737264000000 }
}
```

用戶端 → Gateway：

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

Gateway → 用戶端：

```json
{
  "type": "res",
  "id": "…",
  "ok": true,
  "payload": { "type": "hello-ok", "protocol": 3, "policy": { "tickIntervalMs": 15000 } }
}
```

當發行設備令牌時，`hello-ok` 也包括：

```json
{
  "auth": {
    "deviceToken": "…",
    "role": "operator",
    "scopes": ["operator.read", "operator.write"]
  }
}
```

### 節點範例

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

## 訊框

- **請求**：`{type:"req", id, method, params}`
- **回應**：`{type:"res", id, ok, payload|error}`
- **事件**：`{type:"event", event, payload, seq?, stateVersion?}`

有副作用的方法需要**等冪鍵**（參閱結構）。

## 角色 + 範圍

### 角色

- `operator` = 控制平面用戶端（CLI／UI／自動化）。
- `node` = 能力主機（攝影機／畫面／畫布／system.run）。

### 範圍（操作員）

常見範圍：

- `operator.read`
- `operator.write`
- `operator.admin`
- `operator.approvals`
- `operator.pairing`

### Caps／Commands／Permissions（節點）

節點在連線時宣告能力聲明：

- `caps`：高階能力類別。
- `commands`：invoke 的命令允許清單。
- `permissions`：細粒度切換（例如 `screen.record`、`camera.capture`）。

Gateway 將這些視為**聲明**並強制伺服器端允許清單。

## 狀態

- `system-presence` 傳回以設備身分為鍵的項目。
- 狀態項目包括 `deviceId`、`roles` 和 `scopes`，以便 UI 即使在設備同時作為**操作員**和**節點**連線時也能顯示單一列。

### 節點協助方法

- 節點可呼叫 `skills.bins` 以取得目前的技能可執行檔清單以進行自動允許檢查。

### 操作員協助方法

- 操作員可呼叫 `tools.catalog`（`operator.read`）以取得 Agent 的執行階段工具目錄。回應包括分組工具和出處元資料：
  - `source`：`core` 或 `plugin`
  - `pluginId`：當 `source="plugin"` 時的外掛所有者
  - `optional`：外掛工具是否選用

## Exec 核准

- 當 exec 請求需要核准時，Gateway 廣播 `exec.approval.requested`。
- 操作員用戶端透過呼叫 `exec.approval.resolve` 來解決（需要 `operator.approvals` 範圍）。
- 對於 `host=node`，`exec.approval.request` 必須包括 `systemRunPlan`（標準 `argv`／`cwd`／`rawCommand`／工作階段元資料）。遺漏 `systemRunPlan` 的請求會被拒絕。

## 版本控制

- `PROTOCOL_VERSION` 位於 `src/gateway/protocol/schema.ts`。
- 用戶端傳送 `minProtocol` + `maxProtocol`；伺服器拒絕不符者。
- 結構和模型從 TypeBox 定義產生：
  - `pnpm protocol:gen`
  - `pnpm protocol:gen:swift`
  - `pnpm protocol:check`

## 認證

- 若設定了 `OPENCLAW_GATEWAY_TOKEN`（或 `--token`），`connect.params.auth.token` 必須相符，否則通訊端會關閉。
- 配對後，Gateway 發行範圍為連線角色 + 範圍的**設備令牌**。它在 `hello-ok.auth.deviceToken` 中傳回，用戶端應持久化它以供未來連線。
- 設備令牌可透過 `device.token.rotate` 和 `device.token.revoke` 輪替／撤銷（需要 `operator.pairing` 範圍）。

## 設備身分 + 配對

- 節點應包括從金鑰對指紋衍生的穩定設備身分（`device.id`）。
- Gateway 發行每個設備 + 角色的令牌。
- 除非啟用本地自動核准，否則新的設備 ID 需要配對核准。
- **本地**連線包括迴路和 Gateway 主機自己的 tailnet 位址（因此相同主機的 tailnet 綁定仍可自動核准）。
- 所有 WS 用戶端在 `connect` 時必須包括 `device` 身分（操作員 + 節點）。
- 控制 UI 只有在啟用 `gateway.controlUi.dangerouslyDisableDeviceAuth` 以進行緊急情況時才能省略它。
- 所有連線必須簽署伺服器提供的 `connect.challenge` nonce。

### 設備認證遷移診斷

對於仍使用預挑戰簽署行為的舊版用戶端，`connect` 現在會在 `error.details.code` 下傳回 `DEVICE_AUTH_*` 詳細代碼，並在 `error.details.reason` 中傳回穩定的原因。

常見遷移失敗：

| 訊息                        | details.code                     | details.reason           | 含義                                        |
| --------------------------- | -------------------------------- | ------------------------ | ------------------------------------------- |
| `device nonce required`     | `DEVICE_AUTH_NONCE_REQUIRED`     | `device-nonce-missing`   | 用戶端省略了 `device.nonce`（或傳送空白）。 |
| `device nonce mismatch`     | `DEVICE_AUTH_NONCE_MISMATCH`     | `device-nonce-mismatch`  | 用戶端使用過時／錯誤的 nonce 簽署。         |
| `device signature invalid`  | `DEVICE_AUTH_SIGNATURE_INVALID`  | `device-signature`       | 簽署承載與 v2 承載不符。                    |
| `device signature expired`  | `DEVICE_AUTH_SIGNATURE_EXPIRED`  | `device-signature-stale` | 已簽署的時間戳超出允許的誤差。              |
| `device identity mismatch`  | `DEVICE_AUTH_DEVICE_ID_MISMATCH` | `device-id-mismatch`     | `device.id` 與公開金鑰指紋不符。            |
| `device public key invalid` | `DEVICE_AUTH_PUBLIC_KEY_INVALID` | `device-public-key`      | 公開金鑰格式／規範化失敗。                  |

遷移目標：

- 始終等待 `connect.challenge`。
- 簽署包括伺服器 nonce 的 v2 承載。
- 在 `connect.params.device.nonce` 中傳送相同的 nonce。
- 偏好的簽署承載是 `v3`，它除了 device／client／role／scopes／token／nonce 欄位外，還繫結 `platform` 和 `deviceFamily`。
- 為了相容性，仍接受舊版 `v2` 簽署，但配對設備元資料釘選仍會控制重新連線時的命令原則。

## TLS + 釘選

- WS 連線支援 TLS。
- 用戶端可選擇釘選 Gateway cert 指紋（參閱 `gateway.tls` 設定加上 `gateway.remote.tlsFingerprint` 或 CLI `--tls-fingerprint`）。

## 範圍

此協議暴露**完整的 Gateway API**（狀態、通道、模型、聊天、Agent、工作階段、節點、核准等）。確切的表面由 `src/gateway/protocol/schema.ts` 中的 TypeBox 結構定義。
