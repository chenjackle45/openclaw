---
summary: "iOS 節點應用程式：連接至 Gateway、配對、Canvas 與疑難排解"
read_when:
  - 配對或重新連接 iOS 節點
  - 從原始碼運行 iOS 應用程式
  - 除錯 Gateway 探索或 Canvas 指令
title: "iOS App（iOS 應用程式）"
---

# iOS 應用程式（Node）

可用性：內部預覽版。iOS 應用程式目前尚未公開發佈。

## 主要功能

- 透過 WebSocket 連接至 Gateway（LAN 或 tailnet）。
- 提供節點能力：Canvas、螢幕快照、相機擷取、定位、Talk 模式、語音喚醒。
- 接收 `node.invoke` 指令並回報節點狀態事件。

## 需求

- 在另一台裝置上運行 Gateway（macOS、Linux 或 Windows via WSL2）。
- 網路路徑：
  - 透過 Bonjour 在同一 LAN 下，**或者**
  - 透過 unicast DNS-SD 使用 tailnet（範例網域：`openclaw.internal.`），**或者**
  - 手動輸入主機/連接埠（備援方案）。

## 快速開始（配對 + 連線）

1. 啟動 Gateway：

```bash
openclaw gateway --port 18789
```

2. 在 iOS 應用程式中，開啟設定並選擇已探索到的 Gateway（或啟用 Manual Host 並輸入主機/連接埠）。

3. 在 Gateway 主機上核准配對請求：

```bash
openclaw devices list
openclaw devices approve <requestId>
```

4. 驗證連線：

```bash
openclaw nodes status
openclaw gateway call node.list --params "{}"
```

## 官方版本的 Relay 推播

官方發佈的 iOS 版本使用外部推播 relay，而非直接將原始 APNs token 傳送至 gateway。

Gateway 端需求：

```json5
{
  gateway: {
    push: {
      apns: {
        relay: {
          baseUrl: "https://relay.example.com",
        },
      },
    },
  },
}
```

運作流程：

- iOS 應用程式使用 App Attest 和應用程式收據向 relay 註冊。
- Relay 回傳一個不透明的 relay handle 及一個限定於此次註冊的傳送授權。
- iOS 應用程式取得已配對 gateway 的身份後，將其包含在 relay 註冊中，使得 relay 支援的註冊委派給該特定 gateway。
- 應用程式透過 `push.apns.register` 將該 relay 支援的註冊轉發至已配對 gateway。
- Gateway 使用儲存的 relay handle 進行 `push.test`、背景喚醒及喚醒提示。
- Gateway relay base URL 必須與官方/TestFlight iOS 版本中預設的 relay URL 一致。
- 若應用程式後來連接至不同 gateway 或具有不同 relay base URL 的版本，它會刷新 relay 註冊而非沿用舊的綁定。

此路徑中 gateway **不需要**：

- 不需要全域 relay token。
- 不需要針對官方/TestFlight relay 支援傳送的直接 APNs 金鑰。

預期操作流程：

1. 安裝官方/TestFlight iOS 版本。
2. 在 gateway 上設定 `gateway.push.apns.relay.baseUrl`。
3. 將應用程式配對至 gateway 並等待完成連接。
4. 應用程式在取得 APNs token、operator 會話連接且 relay 註冊成功後，會自動發佈 `push.apns.register`。
5. 之後，`push.test`、重新連接喚醒及喚醒提示便可使用儲存的 relay 支援的註冊。

相容性備註：

- `OPENCLAW_APNS_RELAY_BASE_URL` 仍可作為 gateway 的臨時環境變數覆蓋。

## 驗證與信任流程

Relay 的存在是為了強制執行兩項直接 APNs-on-gateway 無法為官方 iOS 版本提供的限制：

- 只有透過 Apple 發佈的正版 OpenClaw iOS 版本才能使用託管 relay。
- Gateway 只能為與該特定 gateway 配對的 iOS 裝置傳送 relay 支援的推播。

逐層說明：

1. `iOS app -> gateway`
   - 應用程式首先透過正常的 Gateway 驗證流程與 gateway 配對。
   - 這讓應用程式獲得已驗證的節點會話和已驗證的 operator 會話。
   - operator 會話用於呼叫 `gateway.identity.get`。

2. `iOS app -> relay`
   - 應用程式透過 HTTPS 呼叫 relay 註冊端點。
   - 註冊包含 App Attest 證明和應用程式收據。
   - Relay 驗證 bundle ID、App Attest 證明和 Apple 收據，並要求官方/正式發佈路徑。
   - 這就是阻止本地 Xcode/開發版本使用託管 relay 的原因。本地版本可能有簽名，但它無法滿足 relay 預期的 Apple 官方發佈證明。

3. `gateway 身份委派`
   - 在 relay 註冊之前，應用程式從 `gateway.identity.get` 取得已配對 gateway 的身份。
   - 應用程式將該 gateway 身份包含在 relay 註冊酬載中。
   - Relay 回傳委派給該 gateway 身份的 relay handle 和限定於此次註冊的傳送授權。

4. `gateway -> relay`
   - Gateway 儲存來自 `push.apns.register` 的 relay handle 和傳送授權。
   - 在 `push.test`、重新連接喚醒及喚醒提示時，gateway 使用自己的裝置身份簽署傳送請求。
   - Relay 驗證儲存的傳送授權和 gateway 簽名是否與註冊時的委派 gateway 身份一致。
   - 另一個 gateway 無法重用該儲存的註冊，即使它設法取得了 handle。

5. `relay -> APNs`
   - Relay 擁有正式 APNs 憑證和官方版本的原始 APNs token。
   - Gateway 永遠不會儲存 relay 支援的官方版本的原始 APNs token。
   - Relay 代表已配對的 gateway 向 APNs 傳送最終推播。

此設計的緣由：

- 讓正式 APNs 憑證不進入使用者 gateway。
- 避免在 gateway 上儲存官方版本的原始 APNs token。
- 僅允許官方/TestFlight OpenClaw 版本使用託管 relay。
- 防止一個 gateway 向屬於不同 gateway 的 iOS 裝置傳送喚醒推播。

本地/手動版本維持直接使用 APNs。若你在沒有 relay 的情況下測試這些版本，gateway 仍需要直接 APNs 憑證：

```bash
export OPENCLAW_APNS_TEAM_ID="TEAMID"
export OPENCLAW_APNS_KEY_ID="KEYID"
export OPENCLAW_APNS_PRIVATE_KEY_P8="$(cat /path/to/AuthKey_KEYID.p8)"
```

## 探索路徑

### Bonjour（LAN）

Gateway 會在 `local.` 上廣播 `_openclaw-gw._tcp`。iOS 應用程式會自動列出這些 Gateway。

### Tailnet（跨網路）

若 mDNS 被封鎖，請使用 unicast DNS-SD 區域（選擇一個網域；例如：`openclaw.internal.`）搭配 Tailscale split DNS。
CoreDNS 範例請參閱 [Bonjour](/zh-Hant/gateway/bonjour)。

### 手動主機/連接埠

在設定中，啟用 **Manual Host** 並輸入 Gateway 主機 + 連接埠（預設 `18789`）。

## Canvas + A2UI

iOS 節點會渲染 WKWebView canvas。使用 `node.invoke` 來驅動它：

```bash
openclaw nodes invoke --node "iOS Node" --command canvas.navigate --params '{"url":"http://<gateway-host>:18789/__openclaw__/canvas/"}'
```

備註：

- Gateway canvas host 提供 `/__openclaw__/canvas/` 與 `/__openclaw__/a2ui/`。
- 由 Gateway HTTP 伺服器提供服務（與 `gateway.port` 相同連接埠，預設 `18789`）。
- 當廣播了 canvas host URL 時，iOS 節點在連線時會自動導航至 A2UI。
- 使用 `canvas.navigate` 與 `{"url":""}` 可返回內建的鷹架頁面。

### Canvas eval / snapshot

```bash
openclaw nodes invoke --node "iOS Node" --command canvas.eval --params '{"javaScript":"(() => { const {ctx} = window.__openclaw; ctx.clearRect(0,0,innerWidth,innerHeight); ctx.lineWidth=6; ctx.strokeStyle=\"#ff2d55\"; ctx.beginPath(); ctx.moveTo(40,40); ctx.lineTo(innerWidth-40, innerHeight-40); ctx.stroke(); return \"ok\"; })()"}'
```

```bash
openclaw nodes invoke --node "iOS Node" --command canvas.snapshot --params '{"maxWidth":900,"format":"jpeg"}'
```

## 語音喚醒 + Talk 模式

- 語音喚醒與 Talk 模式可在設定中開啟。
- iOS 可能會暫停背景音訊；當應用程式未處於活動狀態時，請將語音功能視為盡力而為（best-effort）。

## 常見錯誤

- `NODE_BACKGROUND_UNAVAILABLE`：將 iOS 應用程式帶到前景（canvas/相機/螢幕指令需要前景執行）。
- `A2UI_HOST_NOT_CONFIGURED`：Gateway 未廣播 canvas host URL；請檢查 [Gateway configuration](/zh-Hant/gateway/configuration) 中的 `canvasHost`。
- 配對提示從未出現：執行 `openclaw devices list` 並手動核准。
- 重新安裝後連線失敗：Keychain 配對 token 已被清除；請重新配對節點。

## 相關文件

- [Pairing](/zh-Hant/channels/pairing)
- [Discovery](/zh-Hant/gateway/discovery)
- [Bonjour](/zh-Hant/gateway/bonjour)
