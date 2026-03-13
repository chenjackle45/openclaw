---
summary: "Gateway WebSocket 協議：握手、框架、版本控制"
read_when:
  - Implementing or updating gateway WS clients
  - Debugging protocol mismatches or connect failures
  - Regenerating protocol schema/models
title: "Gateway Protocol（Gateway 協議）"
---

# Gateway 協議（WebSocket）

Gateway WS 協議是 OpenClaw 的 **單一控制平面 + 節點傳輸**。所有客戶端（CLI、web UI、macOS 應用、iOS/Android 節點、無頭節點）透過 WebSocket 連接並在握手時聲明其 **角色** + **範圍**。

## 傳輸

- WebSocket，具有 JSON 負載的文字框架。
- 第一個框架 **必須** 是 `connect` 請求。

## 握手（connect）

Gateway → 客戶端（預連接挑戰）：

```json
{
  "type": "event",
  "event": "connect.challenge",
  "payload": { "nonce": "…", "ts": 1737264000000 }
}
```

客戶端 → Gateway：

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

Gateway → 客戶端：

```json
{
  "type": "res",
  "id": "…",
  "ok": true,
  "payload": { "type": "hello-ok", "protocol": 3, "policy": { "tickIntervalMs": 15000 } }
}
```

當發出設備權杖時，`hello-ok` 也包括：

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

## 框架

- **請求**：`{type:"req", id, method, params}`
- **回應**：`{type:"res", id, ok, payload|error}`
- **事件**：`{type:"event", event, payload, seq?, stateVersion?}`

副作用方法需要 **冪等鍵**（見綱要）。

## 角色 + 範圍

### 角色

- `operator` = 控制平面客戶端（CLI/UI/自動化）。
- `node` = 能力主機（攝影機/螢幕/畫布/system.run）。

### 範圍（operator）

常見範圍：

- `operator.read`
- `operator.write`
- `operator.admin`
- `operator.approvals`
- `operator.pairing`

方法範圍僅是第一道門。透過 `chat.send` 到達的某些斜線指令在頂部套用更嚴格的指令級檢查。例如，持久 `/config set` 和 `/config unset` 寫入需要 `operator.admin`。

### 能力/指令/權限（node）

節點在連接時聲明能力聲明：

- `caps`：高級能力類別。
- `commands`：用於 invoke 的指令允許清單。
- `permissions`：細粒度切換（例如 `screen.record`、`camera.capture`）。

Gateway 將這些視為 **聲明** 並強制執行伺服器端允許清單。

## 存在

- `system-presence` 回傳由設備身分索引的項目。
- 存在項目包括 `deviceId`、`roles` 和 `scopes`，讓 UI 可顯示每個設備一行，即使它同時連接為 **operator** 和 **node**。

### 節點協助方法

- 節點可呼叫 `skills.bins` 以取得目前技能可執行檔清單進行自動允許檢查。

### Operator 協助方法

- Operator 可呼叫 `tools.catalog`（`operator.read`）以取得代理的執行時工具目錄。回應包括已分組工具和出處中繼資料：
  - `source`：`core` 或 `plugin`
  - `pluginId`：當 `source="plugin"` 時的外掛所有者
  - `optional`：外掛工具是否可選

## 執行批准

- 當執行請求需要批准時，Gateway 廣播 `exec.approval.requested`。
- Operator 客戶端透過呼叫 `exec.approval.resolve` 解析（需要 `operator.approvals` 範圍）。
- 對於 `host=node`，`exec.approval.request` 必須包括 `systemRunPlan`（正規 `argv`/`cwd`/`rawCommand`/會話中繼資料）。遺失 `systemRunPlan` 的請求被拒絕。

## 版本控制

- `PROTOCOL_VERSION` 駐留在 `src/gateway/protocol/schema.ts` 中。
- 客戶端發送 `minProtocol` + `maxProtocol`；伺服器拒絕不匹配。
- 綱要 + 模型從 TypeBox 定義產生：
  - `pnpm protocol:gen`
  - `pnpm protocol:gen:swift`
  - `pnpm protocol:check`

## 驗證

- 如果設定 `OPENCLAW_GATEWAY_TOKEN`（或 `--token`），`connect.params.auth.token` 必須符合或 socket 關閉。
- 配對後，Gateway 發出針對連接角色 + 範圍的 **設備權杖**。它在 `hello-ok.auth.deviceToken` 中回傳，應由客戶端持久化以供未來連接。
- 設備權杖可透過 `device.token.rotate` 和 `device.token.revoke` 輪換/撤銷（需要 `operator.pairing` 範圍）。
- 驗證失敗包括 `error.details.code` 加上復原提示：
  - `error.details.canRetryWithDeviceToken`（布林值）
  - `error.details.recommendedNextStep`（`retry_with_device_token`、`update_auth_configuration`、`update_auth_credentials`、`wait_then_retry`、`review_auth_configuration`）
- 客戶端行為針對 `AUTH_TOKEN_MISMATCH`：
  - 受信任客戶端可嘗試一次有界重試與快取逐設備權杖。
  - 如果該重試失敗，客戶端應停止自動重新連接迴圈並表面 operator 動作指導。

## 設備身分 + 配對

- 節點應包括穩定設備身分（`device.id`）衍生自金鑰對指紋。
- Gateway 發出各設備 + 角色的權杖。
- 新設備 ID 需要配對批准，除非啟用本地自動批准。
- **本地** 連接包括環回和 Gateway 主機自身的 tailnet 地址（所以相同主機 tailnet 繫結仍可自動批准）。
- 所有 WS 客戶端必須在 `connect` 期間包括 `device` 身分（operator + node）。
  Control UI 只能在這些模式中省略它：
  - `gateway.controlUi.allowInsecureAuth=true` 用於 localhost 唯一不安全 HTTP 相容性。
  - `gateway.controlUi.dangerouslyDisableDeviceAuth=true`（破裂玻璃，嚴重安全降級）。
- 所有連接必須簽署伺服器提供的 `connect.challenge` nonce。

### 設備驗證遷移診斷

對於仍使用預挑戰簽署行為的遺留客戶端，`connect` 現在在 `error.details.code` 下回傳 `DEVICE_AUTH_*` 細節代碼與穩定的 `error.details.reason`。

常見遷移失敗：

| 訊息                        | details.code                     | details.reason           | 含義                                      |
| --------------------------- | -------------------------------- | ------------------------ | ----------------------------------------- |
| `device nonce required`     | `DEVICE_AUTH_NONCE_REQUIRED`     | `device-nonce-missing`   | 客戶端省略 `device.nonce`（或發送空白）。 |
| `device nonce mismatch`     | `DEVICE_AUTH_NONCE_MISMATCH`     | `device-nonce-mismatch`  | 客戶端以陳舊/錯誤 nonce 簽署。            |
| `device signature invalid`  | `DEVICE_AUTH_SIGNATURE_INVALID`  | `device-signature`       | 簽署負載不符 v2 負載。                    |
| `device signature expired`  | `DEVICE_AUTH_SIGNATURE_EXPIRED`  | `device-signature-stale` | 簽署時間戳在允許偏斜外。                  |
| `device identity mismatch`  | `DEVICE_AUTH_DEVICE_ID_MISMATCH` | `device-id-mismatch`     | `device.id` 不符公鑰指紋。                |
| `device public key invalid` | `DEVICE_AUTH_PUBLIC_KEY_INVALID` | `device-public-key`      | 公鑰格式/標準化失敗。                     |

遷移目標：

- 一律等待 `connect.challenge`。
- 簽署包括伺服器 nonce 的 v2 負載。
- 在 `connect.params.device.nonce` 中發送相同 nonce。
- 偏好簽署負載是 `v3`，它除了設備/客戶端/角色/範圍/權杖/nonce 欄位外還繫結 `platform` 和 `deviceFamily`。
- 遺留 `v2` 簽署保持相容接受，但配對設備中繼資料釘選仍控制重新連接時的指令政策。

## TLS + 釘選

- TLS 對 WS 連接支援。
- 客戶端可選用釘選 Gateway 憑證指紋（見 `gateway.tls` 設定加上 `gateway.remote.tlsFingerprint` 或 CLI `--tls-fingerprint`）。

## 範圍

此協議暴露 **完整 Gateway API**（狀態、通道、模型、聊天、代理、會話、節點、批准等）。確切表面由 `src/gateway/protocol/schema.ts` 中的 TypeBox 綱要定義。
