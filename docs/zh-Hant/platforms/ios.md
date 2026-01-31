---
title: "ios(iOS)"
summary: "iOS 節點應用程式: 連接至 Gateway、配對、Canvas 與故障排除"
read_when:
  - 配對或重新連接 iOS 節點時
  - 從原始碼運行 iOS 應用程式時
  - Debug Gateway 探索或 Canvas 指令時
---

# iOS 應用程式 (Node)

可用性：內部預覽版。iOS 應用程式目前尚未公開發佈。

## 主要功能

- 透過 WebSocket 連接至 Gateway（LAN 或 Tailnet）。
- 暴露節點能力：Canvas、螢幕快照、相機擷取、定位、Talk 模式、語音喚醒。
- 接收 `node.invoke` 指令並回報節點狀態事件。

## 需求

- 在另一台裝置上運行 Gateway（macOS、Linux 或 Windows WSL2）。
- 網路路徑：
  - 透過 Bonjour 在同一 LAN 下，**或者**
  - 透過 unicast DNS-SD 使用 Tailnet（範例網域：`openclaw.internal.`），**或者**
  - 手動輸入主機/通訊埠（備援方案）。

## 快速開始 (配對 + 連線)

1) 啟動 Gateway：

```bash
openclaw gateway --port 18789
```

2) 在 iOS 應用程式中，開啟設定並選擇已探索到的 Gateway（或啟用 Manual Host 並輸入主機/通訊埠）。

3) 在 Gateway 主機上核准配對請求：

```bash
openclaw nodes pending
openclaw nodes approve <requestId>
```

4) 驗證連線：

```bash
openclaw nodes status
openclaw gateway call node.list --params "{}"
```

## 探索路徑

### Bonjour (LAN)

Gateway 會在 `local.` 上廣播 `_openclaw-gw._tcp`。iOS 應用程式會自動列出這些 Gateway。

### Tailnet (跨網路)

若 mDNS 被阻擋，請使用 unicast DNS-SD 區域（選擇一個網域；例如：`openclaw.internal.`）與 Tailscale Split DNS。
關於 CoreDNS 範例請參閱 [Bonjour](/gateway/bonjour)。

### 手動主機/通訊埠

在設定中，啟用 **Manual Host** 並輸入 Gateway 主機 + 通訊埠（預設 `18789`）。

## Canvas + A2UI

iOS 節點會渲染 WKWebView canvas。使用 `node.invoke` 來驅動它：

```bash
openclaw nodes invoke --node "iOS Node" --command canvas.navigate --params '{"url":"http://<gateway-host>:18793/__openclaw__/canvas/"}'
```

注意：
- Gateway Canvas Host 服務於 `/__openclaw__/canvas/` 與 `/__openclaw__/a2ui/`。
- 當廣播了 Canvas Host URL 時，iOS 節點在連線時會自動導航至 A2UI。
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
- iOS 可能會暫停背景音訊；當應用程式未處於活動狀態時，請將語音功能視為盡力而為 (best-effort)。

## 常見錯誤

- `NODE_BACKGROUND_UNAVAILABLE`: 將 iOS 應用程式帶到前景（Canvas/相機/螢幕指令需要前景執行）。
- `A2UI_HOST_NOT_CONFIGURED`: Gateway 未廣播 Canvas Host URL；請檢查 [Gateway configuration](/gateway/configuration) 中的 `canvasHost`。
- 配對提示從未出現：執行 `openclaw nodes pending` 並手動核准。
- 重新安裝後連線失敗：Keychain 配對 Token 已被清除；請重新配對節點。

## 相關文件

- [Pairing](/gateway/pairing)
- [Discovery](/gateway/discovery)
- [Bonjour](/gateway/bonjour)
