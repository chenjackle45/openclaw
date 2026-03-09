---
summary: "Gateway WebSocket 協議：握手、訊框、版本控制"
read_when:
  - 實作或更新 Gateway WS client 時
  - 除錯協議不符或連線失敗時
  - 重新生成協議 schema/models 時
title: "Gateway Protocol（Gateway 協議）"
---

# Gateway 協議（WebSocket）

Gateway WS 協議是 OpenClaw 的**單一控制平面 + 節點傳輸**。所有 client（CLI、Web UI、macOS app、iOS/Android 節點、無頭節點）透過 WebSocket 連線，並在握手時宣告其**角色** + **範圍**。

## 傳輸

- WebSocket，帶有 JSON 酬載的文字訊框。
- 第一個訊框**必須**是 `connect` 請求。

## 握手（connect）

Gateway → Client（連線前挑戰）：

```json
{
  "type": "event",
  "event": "connect.challenge",
  "payload": { "nonce": "…", "ts": 1737264000000 }
}
```

Client → Gateway：

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

Gateway → Client：

```json
{
  "type": "res",
  "id": "…",
  "ok": true,
  "payload": { "type": "hello-ok", "protocol": 3, "policy": { "tickIntervalMs": 15000 } }
}
```

當發出 device token 時，`hello-ok` 也包含：

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

## 訊框格式

- **請求**：`{type:"req", id, method, params}`
- **回應**：`{type:"res", id, ok, payload|error}`
- **事件**：`{type:"event", event, payload, seq?, stateVersion?}`

具有副作用的方法需要**冪等性鍵**（參見 schema）。

## 角色 + 範圍

### 角色

- `operator` = 控制平面 client（CLI/UI/自動化）。
- `node` = 功能主機（相機/螢幕/畫布/system.run）。

### 範圍（operator）

常見範圍：

- `operator.read`
- `operator.write`
- `operator.admin`
- `operator.approvals`
- `operator.pairing`

方法範圍只是第一道關卡。透過 `chat.send` 執行的部分斜線指令會在上面套用更嚴格的指令級別檢查。例如，持久性的 `/config set` 和 `/config unset` 寫入需要 `operator.admin`。

### Caps/commands/permissions（節點）

節點在連線時宣告功能聲明：

- `caps`：高層次功能類別。
- `commands`：invoke 的指令 allowlist。
- `permissions`：細粒度開關（例如 `screen.record`、`camera.capture`）。

Gateway 將這些視為**聲明**並強制執行伺服器端 allowlists。

## Presence

- `system-presence` 返回以設備身份為鍵的項目。
- Presence 項目包含 `deviceId`、`roles` 和 `scopes`，讓 UI 可以為每個設備顯示一行，即使它以 **operator** 和 **node** 兩種身份連線。

### 節點輔助方法

- 節點可以呼叫 `skills.bins` 以獲取目前的 skill 執行檔列表，用於自動允許檢查。

### Operator 輔助方法

- Operator 可以呼叫 `tools.catalog`（`operator.read`）以獲取 agent 的執行環境工具目錄。回應包含分組的工具和來源中繼資料：
  - `source`：`core` 或 `plugin`
  - `pluginId`：`source="plugin"` 時的插件擁有者
  - `optional`：plugin 工具是否為選用

## Exec 核准

- 當 exec 請求需要核准時，gateway 廣播 `exec.approval.requested`。
- Operator client 透過呼叫 `exec.approval.resolve` 解決（需要 `operator.approvals` 範圍）。
- 對於 `host=node`，`exec.approval.request` 必須包含 `systemRunPlan`（規範的 `argv`/`cwd`/`rawCommand`/session 中繼資料）。缺少 `systemRunPlan` 的請求會被拒絕。

## 版本控制

- `PROTOCOL_VERSION` 位於 `src/gateway/protocol/schema.ts`。
- Client 傳送 `minProtocol` + `maxProtocol`；伺服器拒絕不符的情況。
- Schema + models 從 TypeBox 定義生成：
  - `pnpm protocol:gen`
  - `pnpm protocol:gen:swift`
  - `pnpm protocol:check`

## 認證

- 若設定了 `OPENCLAW_GATEWAY_TOKEN`（或 `--token`），`connect.params.auth.token`
  必須符合，否則 socket 被關閉。
- 配對後，Gateway 發出**device token**，範圍限定於連線角色 + 範圍。它在 `hello-ok.auth.deviceToken` 中返回，client 應持久化以供未來連線使用。
- Device token 可透過 `device.token.rotate` 和 `device.token.revoke` 輪換/撤銷（需要 `operator.pairing` 範圍）。

## 設備身份 + 配對

- 節點應包含從金鑰對指紋衍生的穩定設備身份（`device.id`）。
- Gateway 按設備 + 角色發出 token。
- 除非啟用本地自動核准，否則新設備 ID 需要配對核准。
- **本地**連線包含 loopback 和 gateway 主機自身的 tailnet 地址（讓相同主機的 tailnet 綁定仍可自動核准）。
- 所有 WS client 在 `connect` 時必須包含 `device` 身份（operator + node）。
  Control UI 僅在啟用 `gateway.controlUi.dangerouslyDisableDeviceAuth` 時可以省略（緊急情況）。
- 所有連線必須簽署伺服器提供的 `connect.challenge` nonce。

### 設備認證遷移診斷

對於仍使用舊版預挑戰簽名行為的 client，`connect` 現在在 `error.details.code` 下返回 `DEVICE_AUTH_*` 詳細代碼，並帶有穩定的 `error.details.reason`。

常見的遷移失敗：

| 訊息                        | details.code                     | details.reason           | 含義                                         |
| --------------------------- | -------------------------------- | ------------------------ | -------------------------------------------- |
| `device nonce required`     | `DEVICE_AUTH_NONCE_REQUIRED`     | `device-nonce-missing`   | Client 省略了 `device.nonce`（或傳送空白）。 |
| `device nonce mismatch`     | `DEVICE_AUTH_NONCE_MISMATCH`     | `device-nonce-mismatch`  | Client 使用過期/錯誤的 nonce 簽名。          |
| `device signature invalid`  | `DEVICE_AUTH_SIGNATURE_INVALID`  | `device-signature`       | 簽名酬載與 v2 酬載不符。                     |
| `device signature expired`  | `DEVICE_AUTH_SIGNATURE_EXPIRED`  | `device-signature-stale` | 簽名時間戳超出允許的偏差。                   |
| `device identity mismatch`  | `DEVICE_AUTH_DEVICE_ID_MISMATCH` | `device-id-mismatch`     | `device.id` 與公鑰指紋不符。                 |
| `device public key invalid` | `DEVICE_AUTH_PUBLIC_KEY_INVALID` | `device-public-key`      | 公鑰格式/規範化失敗。                        |

遷移目標：

- 始終等待 `connect.challenge`。
- 簽署包含伺服器 nonce 的 v2 酬載。
- 在 `connect.params.device.nonce` 中傳送相同的 nonce。
- 首選簽名酬載為 `v3`，在設備/client/角色/範圍/token/nonce 欄位之外還綁定 `platform` 和 `deviceFamily`。
- 舊版 `v2` 簽名仍被接受以保持相容性，但配對設備的中繼資料固定仍在重新連線時控制指令政策。

## TLS + 固定

- WS 連線支援 TLS。
- Client 可以選用固定 gateway 憑證指紋（參見 `gateway.tls` 設定以及 `gateway.remote.tlsFingerprint` 或 CLI `--tls-fingerprint`）。

## 範圍

此協議暴露**完整的 gateway API**（狀態、頻道、模型、聊天、agent、sessions、節點、核准等）。確切的介面由 `src/gateway/protocol/schema.ts` 中的 TypeBox schema 定義。
