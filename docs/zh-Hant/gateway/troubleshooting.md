---
summary: "Gateway、Channel、自動化、節點及瀏覽器的深入疑難排解手冊"
read_when:
  - 疑難排解中心將您導向此處進行更深入的診斷
  - 您需要基於症狀的穩定手冊章節與確切指令
title: "Troubleshooting（疑難排解）"
---

# Gateway 疑難排解

本頁是深入手冊。
如果您想先進行快速分類，請從 [/help/troubleshooting](/zh-Hant/help/troubleshooting) 開始。

## 指令階梯

依此順序優先執行這些指令：

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

健康狀態的預期訊號：

- `openclaw gateway status` 顯示 `Runtime: running` 及 `RPC probe: ok`。
- `openclaw doctor` 未回報任何阻礙性的設定/服務問題。
- `openclaw channels status --probe` 顯示已連接/就緒的 Channel。

## Anthropic 長上下文的 429 額外用量要求

當日誌/錯誤包含以下訊息時使用此章節：
`HTTP 429: rate_limit_error: Extra usage is required for long context requests`。

```bash
openclaw logs --follow
openclaw models status
openclaw config get agents.defaults.models
```

注意事項：

- 選取的 Anthropic Opus/Sonnet 模型具有 `params.context1m: true`。
- 目前的 Anthropic 憑證不符合長上下文用量資格。
- 僅在需要 1M beta 路徑的長對話/模型執行中，請求才會失敗。

修正選項：

1. 為該模型停用 `context1m` 以回退至一般上下文視窗。
2. 使用具有計費的 Anthropic API 金鑰，或在訂閱帳戶上啟用 Anthropic Extra Usage。
3. 設定後備模型，使執行在 Anthropic 長上下文請求被拒絕時仍可繼續。

相關資源：

- [/providers/anthropic](/zh-Hant/providers/anthropic)
- [/reference/token-use](/zh-Hant/reference/token-use)
- [/help/faq#why-am-i-seeing-http-429-ratelimiterror-from-anthropic](/zh-Hant/help/faq#why-am-i-seeing-http-429-ratelimiterror-from-anthropic)

## 沒有回覆

如果 Channel 正常運作但沒有任何回應，在重新連接任何東西之前，先檢查路由和策略。

```bash
openclaw status
openclaw channels status --probe
openclaw pairing list --channel <channel> [--account <id>]
openclaw config get channels
openclaw logs --follow
```

注意事項：

- DM 發送者的配對待審。
- 群組提及限制（`requireMention`、`mentionPatterns`）。
- Channel/群組白名單不符。

常見特徵：

- `drop guild message (mention required` → 群組訊息被忽略，直到提及為止。
- `pairing request` → 發送者需要核准。
- `blocked` / `allowlist` → 發送者/Channel 被策略過濾。

相關資源：

- [/channels/troubleshooting](/zh-Hant/channels/troubleshooting)
- [/channels/pairing](/zh-Hant/channels/pairing)
- [/channels/groups](/zh-Hant/channels/groups)

## 儀表板控制 UI 連線問題

當儀表板/控制 UI 無法連線時，驗證 URL、驗證模式及安全上下文假設。

```bash
openclaw gateway status
openclaw status
openclaw logs --follow
openclaw doctor
openclaw gateway status --json
```

注意事項：

- 正確的探針 URL 和儀表板 URL。
- 用戶端與 Gateway 之間的驗證模式/Token 不符。
- 需要裝置身分識別的情況下使用了 HTTP。

常見特徵：

- `device identity required` → 非安全上下文或缺少裝置驗證。
- `device nonce required` / `device nonce mismatch` → 用戶端未完成基於挑戰的裝置驗證流程（`connect.challenge` + `device.nonce`）。
- `device signature invalid` / `device signature expired` → 用戶端對目前握手簽署了錯誤的 payload（或時間戳過期）。
- `AUTH_TOKEN_MISMATCH` 且 `canRetryWithDeviceToken=true` → 用戶端可使用快取的裝置 Token 進行一次受信任的重試。
- 重試後仍持續 `unauthorized` → 共享 Token/裝置 Token 漂移；重新整理 Token 設定並在需要時重新核准/輪替裝置 Token。
- `gateway connect failed:` → 錯誤的主機/連接埠/URL 目標。

### 驗證詳細代碼快速對照表

使用失敗的 `connect` 回應中的 `error.details.code` 來選擇下一步動作：

| 詳細代碼                     | 含義                                    | 建議動作                                                                                                                                            |
| ---------------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AUTH_TOKEN_MISSING`         | 用戶端未傳送必要的共享 Token。          | 在用戶端貼上/設定 Token 並重試。對於儀表板路徑：`openclaw config get gateway.auth.token` 然後貼入控制 UI 設定。                                     |
| `AUTH_TOKEN_MISMATCH`        | 共享 Token 與 Gateway 驗證 Token 不符。 | 若 `canRetryWithDeviceToken=true`，允許一次受信任的重試。若仍失敗，執行 [Token 漂移恢復清單](/zh-Hant/cli/devices#token-drift-recovery-checklist)。 |
| `AUTH_DEVICE_TOKEN_MISMATCH` | 快取的每裝置 Token 已過時或已撤銷。     | 使用 [devices CLI](/zh-Hant/cli/devices) 輪替/重新核准裝置 Token，然後重新連線。                                                                    |
| `PAIRING_REQUIRED`           | 裝置身分識別已知但未核准此角色。        | 核准待審請求：`openclaw devices list` 然後 `openclaw devices approve <requestId>`。                                                                 |

裝置驗證 v2 遷移檢查：

```bash
openclaw --version
openclaw doctor
openclaw gateway status
```

如果日誌顯示 nonce/簽章錯誤，更新連線用戶端並驗證它：

1. 等待 `connect.challenge`
2. 簽署綁定挑戰的 payload
3. 傳送 `connect.params.device.nonce` 及相同的挑戰 nonce

相關資源：

- [/web/control-ui](/zh-Hant/web/control-ui)
- [/gateway/authentication](/zh-Hant/gateway/authentication)
- [/gateway/remote](/zh-Hant/gateway/remote)
- [/cli/devices](/zh-Hant/cli/devices)

## Gateway 服務未執行

當服務已安裝但行程無法持續運作時使用此章節。

```bash
openclaw gateway status
openclaw status
openclaw logs --follow
openclaw doctor
openclaw gateway status --deep
```

注意事項：

- `Runtime: stopped` 並附帶退出提示。
- 服務設定不符（`Config (cli)` 與 `Config (service)` 不一致）。
- 連接埠/監聽器衝突。

常見特徵：

- `Gateway start blocked: set gateway.mode=local` → 本地 Gateway 模式未啟用。修正：在設定中設定 `gateway.mode="local"`（或執行 `openclaw configure`）。如果您使用 Podman 以專用的 `openclaw` 使用者執行 OpenClaw，設定位於 `~openclaw/.openclaw/openclaw.json`。
- `refusing to bind gateway ... without auth` → 非回環繫結但未設定 Token/密碼。
- `another gateway instance is already listening` / `EADDRINUSE` → 連接埠衝突。

相關資源：

- [/gateway/background-process](/zh-Hant/gateway/background-process)
- [/gateway/configuration](/zh-Hant/gateway/configuration)
- [/gateway/doctor](/zh-Hant/gateway/doctor)

## Channel 已連線但訊息未流通

如果 Channel 狀態顯示已連線但訊息流已中斷，請關注策略、權限及 Channel 特定的傳送規則。

```bash
openclaw channels status --probe
openclaw pairing list --channel <channel> [--account <id>]
openclaw status --deep
openclaw logs --follow
openclaw config get channels
```

注意事項：

- DM 策略（`pairing`、`allowlist`、`open`、`disabled`）。
- 群組白名單及提及要求。
- 缺少 Channel API 權限/範圍。

常見特徵：

- `mention required` → 訊息被群組提及策略忽略。
- `pairing` / 待核准追蹤 → 發送者未獲批准。
- `missing_scope`、`not_in_channel`、`Forbidden`、`401/403` → Channel 驗證/權限問題。

相關資源：

- [/channels/troubleshooting](/zh-Hant/channels/troubleshooting)
- [/channels/whatsapp](/zh-Hant/channels/whatsapp)
- [/channels/telegram](/zh-Hant/channels/telegram)
- [/channels/discord](/zh-Hant/channels/discord)

## Cron 和心跳傳送

如果 cron 或心跳未執行或未傳送，先驗證排程器狀態，再確認傳送目標。

```bash
openclaw cron status
openclaw cron list
openclaw cron runs --id <jobId> --limit 20
openclaw system heartbeat last
openclaw logs --follow
```

注意事項：

- Cron 已啟用且存在下次喚醒時間。
- 工作執行歷史狀態（`ok`、`skipped`、`error`）。
- 心跳跳過原因（`quiet-hours`、`requests-in-flight`、`alerts-disabled`）。

常見特徵：

- `cron: scheduler disabled; jobs will not run automatically` → cron 已停用。
- `cron: timer tick failed` → 排程器滴答失敗；檢查檔案/日誌/執行期錯誤。
- `heartbeat skipped` 且 `reason=quiet-hours` → 在活躍時段視窗之外。
- `heartbeat: unknown accountId` → 心跳傳送目標的帳號 id 無效。
- `heartbeat skipped` 且 `reason=dm-blocked` → 心跳目標解析為 DM 類型的目的地，但 `agents.defaults.heartbeat.directPolicy`（或每個 Agent 的覆寫）設定為 `block`。

相關資源：

- [/automation/troubleshooting](/zh-Hant/automation/troubleshooting)
- [/automation/cron-jobs](/zh-Hant/automation/cron-jobs)
- [/gateway/heartbeat](/zh-Hant/gateway/heartbeat)

## 節點配對工具失敗

如果節點已配對但工具失敗，請隔離前景、權限及核准狀態。

```bash
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
openclaw approvals get --node <idOrNameOrIp>
openclaw logs --follow
openclaw status
```

注意事項：

- 節點在線且具有預期的功能。
- 相機/麥克風/位置/螢幕的 OS 權限授予。
- Exec 核准及白名單狀態。

常見特徵：

- `NODE_BACKGROUND_UNAVAILABLE` → 節點應用程式必須在前景執行。
- `*_PERMISSION_REQUIRED` / `LOCATION_PERMISSION_REQUIRED` → 缺少 OS 權限。
- `SYSTEM_RUN_DENIED: approval required` → exec 核准待審。
- `SYSTEM_RUN_DENIED: allowlist miss` → 指令被白名單封鎖。

相關資源：

- [/nodes/troubleshooting](/zh-Hant/nodes/troubleshooting)
- [/nodes/index](/zh-Hant/nodes/index)
- [/tools/exec-approvals](/zh-Hant/tools/exec-approvals)

## 瀏覽器工具失敗

當 Gateway 本身健康但瀏覽器工具動作失敗時使用此章節。

```bash
openclaw browser status
openclaw browser start --browser-profile openclaw
openclaw browser profiles
openclaw logs --follow
openclaw doctor
```

注意事項：

- 有效的瀏覽器可執行檔路徑。
- CDP 設定檔可達性。
- `profile="chrome"` 的擴充功能中繼分頁附件。

常見特徵：

- `Failed to start Chrome CDP on port` → 瀏覽器行程啟動失敗。
- `browser.executablePath not found` → 設定的路徑無效。
- `Chrome extension relay is running, but no tab is connected` → 擴充功能中繼未附加。
- `Browser attachOnly is enabled ... not reachable` → 附加模式設定檔沒有可達的目標。

相關資源：

- [/tools/browser-linux-troubleshooting](/zh-Hant/tools/browser-linux-troubleshooting)
- [/tools/chrome-extension](/zh-Hant/tools/chrome-extension)
- [/tools/browser](/zh-Hant/tools/browser)

## 升級後突然出現問題

大多數升級後的問題是設定漂移或現在強制執行更嚴格的預設值。

### 1) 驗證和 URL 覆寫行為已變更

```bash
openclaw gateway status
openclaw config get gateway.mode
openclaw config get gateway.remote.url
openclaw config get gateway.auth.mode
```

檢查事項：

- 如果 `gateway.mode=remote`，CLI 呼叫可能以遠端為目標，而您的本地服務正常。
- 明確的 `--url` 呼叫不會回退到儲存的憑證。

常見特徵：

- `gateway connect failed:` → 錯誤的 URL 目標。
- `unauthorized` → 端點可達但驗證錯誤。

### 2) 繫結和驗證護欄更加嚴格

```bash
openclaw config get gateway.bind
openclaw config get gateway.auth.token
openclaw gateway status
openclaw logs --follow
```

檢查事項：

- 非回環繫結（`lan`、`tailnet`、`custom`）需要設定驗證。
- 舊版金鑰如 `gateway.token` 無法取代 `gateway.auth.token`。

常見特徵：

- `refusing to bind gateway ... without auth` → 繫結+驗證不符。
- `RPC probe: failed` 但執行期正在執行 → Gateway 正常運作但目前的驗證/URL 無法存取。

### 3) 配對和裝置身分識別狀態已變更

```bash
openclaw devices list
openclaw pairing list --channel <channel> [--account <id>]
openclaw logs --follow
openclaw doctor
```

檢查事項：

- 儀表板/節點的待審裝置核准。
- 策略或身分識別變更後的待審 DM 配對核准。

常見特徵：

- `device identity required` → 裝置驗證未滿足。
- `pairing required` → 發送者/裝置必須獲得核准。

如果檢查後服務設定和執行期仍然不一致，請從相同的設定檔/狀態目錄重新安裝服務中繼資料：

```bash
openclaw gateway install --force
openclaw gateway restart
```

相關資源：

- [/gateway/pairing](/zh-Hant/gateway/pairing)
- [/gateway/authentication](/zh-Hant/gateway/authentication)
- [/gateway/background-process](/zh-Hant/gateway/background-process)
