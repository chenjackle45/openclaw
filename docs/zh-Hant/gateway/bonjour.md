---
title: "bonjour(Bonjour / mDNS)"
summary: "Bonjour/mDNS 發現機制 + 除錯 (Gateway beacons, clients, 與常見失敗模式)"
read_when:
  - 除錯 macOS/iOS 上的 Bonjour 發現問題時
  - 變更 mDNS service types, TXT records, 或 discovery UX 時
---

# Bonjour / mDNS 發現機制

OpenClaw 使用 Bonjour (mDNS / DNS‑SD) 作為 **僅限 LAN 的便利功能** 來發現活動的 Gateway (WebSocket Endpoint)。這是盡力而為 (best‑effort) 的機制，並 **不** 取代 SSH 或基於 Tailnet 的連線。

## 透過 Tailscale 的廣域 Bonjour (Unicast DNS‑SD)

若 Node 與 Gateway 位於不同網路，Multicast mDNS 無法跨越邊界。您可以透過切換至 Tailscale 上的 **Unicast DNS‑SD** ("廣域 Bonjour", Wide‑Area Bonjour) 來保持相同的發現體驗。

高層次步驟:

1) 在 Gateway Host 上運行 DNS Server (透過 Tailnet 可達)。
2) 在專用區域 (Dedicated Zone) 下發布 `_openclaw-gw._tcp` 的 DNS‑SD 記錄 (範例: `openclaw.internal.`)。
3) 設定 Tailscale **Split DNS**，讓用戶端 (包含 iOS) 透過該 DNS Server 解析您選擇的網域。

OpenClaw 支援任何發現網域；`openclaw.internal.` 僅為範例。iOS/Android Nodes 會同時瀏覽 `local.` 與您設定的廣域網域。

### Gateway Config (推薦)

```json5
{
  gateway: { bind: "tailnet" }, // 僅限 tailnet (推薦)
  discovery: { wideArea: { enabled: true } } // 啟用廣域 DNS-SD 發布
}
```

### 一次性 DNS Server 設定 (Gateway Host)

```bash
openclaw dns setup --apply
```

這會安裝 CoreDNS 並設定它：
- 僅在 Gateway 的 Tailscale 介面上聆聽 Port 53
- 從 `~/.openclaw/dns/<domain>.db` 服務您選擇的網域 (範例: `openclaw.internal.`)

從連線至 Tailnet 的機器驗證：

```bash
dns-sd -B _openclaw-gw._tcp openclaw.internal.
dig @<TAILNET_IPV4> -p 53 _openclaw-gw._tcp.openclaw.internal PTR +short
```

### Tailscale DNS 設定

在 Tailscale Admin Console:

- 新增指向 Gateway Tailnet IP (UDP/TCP 53) 的 Nameserver。
- 新增 Split DNS，讓您的發現網域使用該 Nameserver。

一旦用戶端接受 Tailnet DNS，iOS Nodes 即可在您的發現網域中瀏覽 `_openclaw-gw._tcp` 而無需 Multicast。

### Gateway Listener 安全性 (推薦)

Gateway WS Port (預設 `18789`) 預設綁定至 Loopback。為了 LAN/Tailnet 存取，請明確綁定並保持 Auth 啟用。

對於僅限 Tailnet 的設定：
- 在 `~/.openclaw/openclaw.json` 中設定 `gateway.bind: "tailnet"`。
- 重啟 Gateway (或重啟 macOS Menubar App)。

## 廣播內容

僅 Gateway 會廣播 `_openclaw-gw._tcp`。

## Service Types

- `_openclaw-gw._tcp` — Gateway 傳輸信標 (macOS/iOS/Android Nodes 使用)。

## TXT Keys (非機密提示)

Gateway 廣播小型的非機密提示以方便 UI 流程：

- `role=gateway`
- `displayName=<friendly name>`
- `lanHost=<hostname>.local`
- `gatewayPort=<port>` (Gateway WS + HTTP)
- `gatewayTls=1` (僅當 TLS 啟用時)
- `gatewayTlsSha256=<sha256>` (僅當 TLS 啟用且 Fingerprint 可用時)
- `canvasPort=<port>` (僅當 Canvas Host 啟用時; 預設 `18793`)
- `sshPort=<port>` (未覆蓋時預設為 22)
- `transport=gateway`
- `cliPath=<path>` (選用; 可運行的 `openclaw` entrypoint 的絕對路徑)
- `tailnetDns=<magicdns>` (當 Tailnet 可用時的選用提示)

## macOS 上的除錯

有用的內建工具：

- 瀏覽實例 (Instances):
  ```bash
  dns-sd -B _openclaw-gw._tcp local.
  ```
- 解析單一實例 (替換 `<instance>`):
  ```bash
  dns-sd -L "<instance>" _openclaw-gw._tcp local.
  ```

若瀏覽 (Browse) 成功但解析 (Resolve) 失敗，通常是遇到 LAN Policy 或 mDNS Resolver 問題。

## Gateway 日誌除錯

Gateway 寫入滾動日誌檔 (啟動時印出 `gateway log file: ...`)。尋找 `bonjour:` 行，特別是：

- `bonjour: advertise failed ...`
- `bonjour: ... name conflict resolved` / `hostname conflict resolved`
- `bonjour: watchdog detected non-announced service ...`

## iOS Node 上的除錯

iOS Node 使用 `NWBrowser` 發現 `_openclaw-gw._tcp`。

擷取日誌：
- Settings → Gateway → Advanced → **Discovery Debug Logs**
- Settings → Gateway → Advanced → **Discovery Logs** → 重現問題 → **Copy**

日誌包含 Browser 狀態轉換與 Result-set 變更。

## 常見失敗模式

- **Bonjour 不跨網段**: 使用 Tailnet 或 SSH。
- **Multicast 被阻擋**: 部分 Wi‑Fi 網路停用 mDNS。
- **睡眠 / 介面變動**: macOS 可能暫時遺失 mDNS 結果；重試。
- **瀏覽成功但解析失敗**: 保持機器名稱簡單 (避免 Emoji 或標點符號)，然後重啟 Gateway。服務實例名稱源自 Host Name，過於複雜的名稱可能混淆部分 Resolvers。

## 跳脫的實例名稱 (`\032`)

Bonjour/DNS‑SD 常將服務實例名稱中的 Byte 跳脫為十進位 `\DDD` 序列 (例如空白變為 `\032`)。

- 這在協定層級是正常的。
- UI 應解碼以顯示 (iOS 使用 `BonjourEscapes.decode`)。

## 停用 / 設定

- `OPENCLAW_DISABLE_BONJOUR=1` 停用廣播 (舊版: `OPENCLAW_DISABLE_BONJOUR`)。
- `~/.openclaw/openclaw.json` 中的 `gateway.bind` 控制 Gateway Bind Mode。
- `OPENCLAW_SSH_PORT` 覆蓋 TXT 中廣播的 SSH Port (舊版: `OPENCLAW_SSH_PORT`)。
- `OPENCLAW_TAILNET_DNS` 在 TXT 中發布 MagicDNS 提示 (舊版: `OPENCLAW_TAILNET_DNS`)。
- `OPENCLAW_CLI_PATH` 覆蓋廣播的 CLI Path (舊版: `OPENCLAW_CLI_PATH`)。

## 相關文件

- 發現策略與傳輸選擇: [Discovery](/gateway/discovery)
- Node 配對 + 核准: [Gateway pairing](/gateway/pairing)
