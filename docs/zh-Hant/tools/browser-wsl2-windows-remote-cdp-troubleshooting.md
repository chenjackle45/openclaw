---
summary: "分層排除 WSL2 Gateway + Windows Chrome 遠端 CDP 和 extension-relay 設定的問題"
read_when:
  - 在 WSL2 中執行 OpenClaw Gateway，同時 Chrome 在 Windows 上
  - 看到 WSL2 和 Windows 上重疊的 browser/control-ui 錯誤
  - 在分離主機設定中決定使用原始遠端 CDP 還是 Chrome extension relay
title: "WSL2 + Windows + remote Chrome CDP troubleshooting（WSL2 + Windows + 遠端 Chrome CDP 疑難排解）"
---

# WSL2 + Windows + remote Chrome CDP troubleshooting

本指南涵蓋常見的分離主機設定，其中：

- OpenClaw Gateway 在 WSL2 內執行
- Chrome 在 Windows 上執行
- 瀏覽器控制必須跨越 WSL2/Windows 邊界

也涵蓋來自 [issue #39369](https://github.com/openclaw/openclaw/issues/39369) 的分層失敗模式：多個獨立問題可能同時出現，這讓錯誤的層看起來像是首先損壞的層。

## 先選擇正確的瀏覽器模式

有兩種有效模式：

### 選項 1：原始遠端 CDP

使用從 WSL2 指向 Windows Chrome CDP 端點的遠端瀏覽器 profile。

在以下情況選擇此方式：

- 你只需要瀏覽器控制
- 你習慣將 Chrome 遠端偵錯暴露給 WSL2
- 你不需要 Chrome extension relay

### 選項 2：Chrome extension relay

使用內建的 `chrome` profile 加上 OpenClaw Chrome extension。

在以下情況選擇此方式：

- 你想透過工具列按鈕附加至現有的 Windows Chrome 分頁
- 你想要基於 extension 的控制而非原始的 `--remote-debugging-port`
- relay 本身必須能夠跨越 WSL2/Windows 邊界

如果你在命名空間之間使用 extension relay，`browser.relayBindHost` 是 [Browser](/zh-Hant/tools/browser) 和 [Chrome extension](/zh-Hant/tools/chrome-extension) 中介紹的重要設定。

## 正常運作的架構

參考架構：

- WSL2 在 `127.0.0.1:18789` 執行 Gateway
- Windows 在普通瀏覽器中開啟 Control UI，網址為 `http://127.0.0.1:18789/`
- Windows Chrome 在 `9222` 埠公開 CDP 端點
- WSL2 可以連接該 Windows CDP 端點
- OpenClaw 將瀏覽器 profile 指向從 WSL2 可連接的位址

## 為何此設定令人困惑

多種失敗可能重疊：

- WSL2 無法連接 Windows CDP 端點
- Control UI 從不安全來源開啟
- `gateway.controlUi.allowedOrigins` 與頁面來源不符
- token 或配對遺失
- 瀏覽器 profile 指向錯誤的位址
- extension relay 仍然僅限 loopback，而你實際上需要跨命名空間存取

因此，修復一層仍可能留下不同的錯誤。

## Control UI 的關鍵規則

當 UI 從 Windows 開啟時，除非你有刻意的 HTTPS 設定，否則使用 Windows localhost。

使用：

`http://127.0.0.1:18789/`

不要預設使用區域網路 IP 作為 Control UI。在 LAN 或 tailnet 位址上使用純 HTTP 可能觸發與 CDP 本身無關的不安全來源/裝置驗證行為。見 [Control UI](/zh-Hant/web/control-ui)。

## 分層驗證

由上至下逐步進行。不要跳過。

### 第 1 層：驗證 Chrome 在 Windows 上提供 CDP

在 Windows 上啟用遠端偵錯啟動 Chrome：

```powershell
chrome.exe --remote-debugging-port=9222
```

從 Windows 先驗證 Chrome 本身：

```powershell
curl http://127.0.0.1:9222/json/version
curl http://127.0.0.1:9222/json/list
```

若這在 Windows 上失敗，目前還不是 OpenClaw 的問題。

### 第 2 層：驗證 WSL2 可以連接該 Windows 端點

從 WSL2 測試你計劃在 `cdpUrl` 中使用的確切位址：

```bash
curl http://WINDOWS_HOST_OR_IP:9222/json/version
curl http://WINDOWS_HOST_OR_IP:9222/json/list
```

正常結果：

- `/json/version` 回傳帶有 Browser / Protocol-Version 元資料的 JSON
- `/json/list` 回傳 JSON（若無頁面開啟則空陣列也可以）

若失敗：

- Windows 尚未將埠公開給 WSL2
- WSL2 端的位址錯誤
- 防火牆/埠轉發/本地代理仍然遺失

先修復這個，再碰 OpenClaw 設定。

### 第 3 層：設定正確的瀏覽器 profile

對於原始遠端 CDP，將 OpenClaw 指向從 WSL2 可連接的位址：

```json5
{
  browser: {
    enabled: true,
    defaultProfile: "remote",
    profiles: {
      remote: {
        cdpUrl: "http://WINDOWS_HOST_OR_IP:9222",
        attachOnly: true,
        color: "#00AA00",
      },
    },
  },
}
```

注意：

- 使用 WSL2 可連接的位址，而不是只在 Windows 上有效的位址
- 對外部管理的瀏覽器保留 `attachOnly: true`
- 在期望 OpenClaw 成功之前，先用 `curl` 測試相同的 URL

### 第 4 層：若你使用 Chrome extension relay

若瀏覽器機器和 Gateway 被命名空間邊界分隔，relay 可能需要非 loopback 的綁定位址。

範例：

```json5
{
  browser: {
    enabled: true,
    defaultProfile: "chrome",
    relayBindHost: "0.0.0.0",
  },
}
```

僅在需要時使用：

- 預設行為更安全，因為 relay 保持僅限 loopback
- `0.0.0.0` 擴大暴露面
- 保持 Gateway 驗證、節點配對和周邊網路私密

若你不需要 extension relay，優先使用上面的原始遠端 CDP profile。

### 第 5 層：單獨驗證 Control UI 層

從 Windows 開啟 UI：

`http://127.0.0.1:18789/`

然後驗證：

- 頁面來源符合 `gateway.controlUi.allowedOrigins` 的預期
- token 驗證或配對設定正確
- 你沒有把 Control UI 驗證問題誤當成瀏覽器問題來偵錯

參考頁面：

- [Control UI](/zh-Hant/web/control-ui)

### 第 6 層：驗證端對端瀏覽器控制

從 WSL2：

```bash
openclaw browser open https://example.com --browser-profile remote
openclaw browser tabs --browser-profile remote
```

對於 extension relay：

```bash
openclaw browser tabs --browser-profile chrome
```

正常結果：

- 分頁在 Windows Chrome 中開啟
- `openclaw browser tabs` 回傳目標
- 後續動作（`snapshot`、`screenshot`、`navigate`）從同一 profile 有效

## 常見誤導性錯誤

將每條訊息視為特定層的線索：

- `control-ui-insecure-auth`
  - UI 來源/安全 context 問題，而非 CDP 傳輸問題
- `token_missing`
  - 驗證設定問題
- `pairing required`
  - 裝置審批問題
- `Remote CDP for profile "remote" is not reachable`
  - WSL2 無法連接已設定的 `cdpUrl`
- `gateway timeout after 1500ms`
  - 通常仍是 CDP 可達性問題或緩慢/不可達的遠端端點
- `Chrome extension relay is running, but no tab is connected`
  - 已選擇 extension relay profile，但尚無已附加的分頁

## 快速分類檢查清單

1. Windows：`curl http://127.0.0.1:9222/json/version` 是否有效？
2. WSL2：`curl http://WINDOWS_HOST_OR_IP:9222/json/version` 是否有效？
3. OpenClaw 設定：`browser.profiles.<name>.cdpUrl` 是否使用那個確切的 WSL2 可連接位址？
4. Control UI：你是否開啟 `http://127.0.0.1:18789/` 而不是 LAN IP？
5. 僅限 Extension relay：你是否確實需要 `browser.relayBindHost`，若需要是否明確設定？

## 實務結論

此設定通常是可行的。困難之處在於瀏覽器傳輸、Control UI 來源安全性、token/配對，以及 extension-relay 拓撲各自可能獨立失敗，但從使用者端看起來很相似。

當不確定時：

- 先在本地驗證 Windows Chrome 端點
- 其次從 WSL2 驗證相同端點
- 然後才偵錯 OpenClaw 設定或 Control UI 驗證
