---
title: "android(Android)"
summary: "Android 應用程式 (Node): 連線操作手冊 + Canvas/聊天/相機功能"
read_when:
  - 配對或重新連接 Android 節點時
  - 除錯 Android Gateway 探索或認證時
  - 驗證跨客戶端的聊天記錄一致性時
---

# Android 應用程式 (Node)

## 支援快照
- 角色：配套節點應用程式（Android 不託管 Gateway）。
- Gateway 需求：是（需在 macOS、Linux 或 Windows WSL2 上運行）。
- 安裝：[Getting Started](/start/getting-started) + [Pairing](/gateway/pairing)。
- Gateway：[Runbook](/gateway) + [Configuration](/gateway/configuration)。
  - 協定：[Gateway protocol](/gateway/protocol)（節點 + 控制平面）。

## 系統控制
系統控制 (launchd/systemd) 位於 Gateway 主機上。請參閱 [Gateway](/gateway)。

## 連線操作手冊

Android 節點應用程式 ⇄ (mDNS/NSD + WebSocket) ⇄ **Gateway**

Android 直接連線至 Gateway WebSocket（預設 `ws://<host>:18789`）並使用 Gateway 擁有的配對機制。

### 先決條件

- 您可以在「主控」機器上運行 Gateway。
- Android 裝置/模擬器可以連線至 Gateway WebSocket：
  - 透過 mDNS/NSD 在同一 LAN 下，**或者**
  - 使用 Wide-Area Bonjour / unicast DNS-SD 在同一 Tailscale tailnet 下（見下文），**或者**
  - 手動輸入 Gateway 主機/通訊埠（備援方案）
- 您可以在 Gateway 機器上運行 CLI (`openclaw`)（或透過 SSH）。

### 1) 啟動 Gateway

```bash
openclaw gateway --port 18789 --verbose
```

確認日誌中出現類似訊息：
- `listening on ws://0.0.0.0:18789`

對於僅使用 Tailnet 的設置（推薦用於 維也納 ⇄ 倫敦 遠端連線），將 Gateway 綁定至 Tailnet IP：

- 在 Gateway 主機上的 `~/.openclaw/openclaw.json` 設定 `gateway.bind: "tailnet"`。
- 重新啟動 Gateway / macOS 選單列應用程式。

### 2) 驗證探索 (選用)

在 Gateway 機器上：

```bash
dns-sd -B _openclaw-gw._tcp local.
```

更多除錯筆記：[Bonjour](/gateway/bonjour)。

#### 透過 unicast DNS-SD 進行 Tailnet (維也納 ⇄ 倫敦) 探索

Android NSD/mDNS 探索無法跨越網路。如果您的 Android 節點與 Gateway 位於不同網路但透過 Tailscale 連接，請改用 Wide-Area Bonjour / unicast DNS-SD：

1) 在 Gateway 主機上設定 DNS-SD 區域（例如 `openclaw.internal.`）並發佈 `_openclaw-gw._tcp` 記錄。
2) 為您選擇的網域配置 Tailscale Split DNS，指向該 DNS 伺服器。

詳細資訊與 CoreDNS 配置範例：[Bonjour](/gateway/bonjour)。

### 3) 從 Android 連線

在 Android 應用程式中：

- 應用程式透過 **前景服務** (foreground service, 持續通知) 保持 Gateway 連線。
- 開啟 **Settings** (設定)。
- 在 **Discovered Gateways** (已探索的 Gateway) 下，選擇您的 Gateway 並點擊 **Connect** (連線)。
- 若 mDNS 被阻擋，請使用 **Advanced → Manual Gateway** (手動 Gateway，輸入主機 + 通訊埠) 並點擊 **Connect (Manual)** (手動連線)。

首次成功配對後，Android 啟動時會自動重新連線：
- 手動端點（若已啟用），否則
- 最後一次探索到的 Gateway（盡力而為）。

### 4) 核准配對 (CLI)

在 Gateway 機器上：

```bash
openclaw nodes pending
openclaw nodes approve <requestId>
```

配對詳情：[Gateway pairing](/gateway/pairing)。

### 5) 驗證節點已連線

- 透過 nodes status:
  ```bash
  openclaw nodes status
  ```
- 透過 Gateway:
  ```bash
  openclaw gateway call node.list --params "{}"
  ```

### 6) 聊天 + 歷史記錄

Android 節點的聊天頁面使用 Gateway 的 **主要會話金鑰** (`main`)，因此歷史記錄與回覆會與 WebChat 及其他客戶端共享：

- 歷史記錄：`chat.history`
- 傳送：`chat.send`
- 推送更新（盡力而為）：`chat.subscribe` → `event:"chat"`

### 7) Canvas + 相機

#### Gateway Canvas Host (推薦用於網頁內容)

若您希望節點顯示 Agent 可在磁碟上編輯的真實 HTML/CSS/JS，請將節點指向 Gateway Canvas Host。

注意：節點使用位於 `canvasHost.port`（預設 `18793`）的獨立 Canvas 主機。

1) 在 Gateway 主機上建立 `~/.openclaw/workspace/canvas/index.html`。

2) 將節點導航至該頁面 (LAN)：

```bash
openclaw nodes invoke --node "<Android Node>" --command canvas.navigate --params '{"url":"http://<gateway-hostname>.local:18793/__openclaw__/canvas/"}'
```

Tailnet (選用)：若兩台裝置皆在 Tailscale 上，請使用 MagicDNS 名稱或 Tailnet IP 取代 `.local`，例如 `http://<gateway-magicdns>:18793/__openclaw__/canvas/`。

此伺服器會將 Live-reload 用戶端注入至 HTML 中，並在檔案變更時重新載入。
A2UI 主機位於 `http://<gateway-host>:18793/__openclaw__/a2ui/`。

Canvas 指令（僅限前景）：
- `canvas.eval`, `canvas.snapshot`, `canvas.navigate`（使用 `{"url":""}` 或 `{"url":"/"}` 返回預設鷹架頁面）。`canvas.snapshot` 回傳 `{ format, base64 }`（預設 `format="jpeg"`）。
- A2UI: `canvas.a2ui.push`, `canvas.a2ui.reset`（舊版別名 `canvas.a2ui.pushJSONL`）

相機指令（僅限前景；需權限）：
- `camera.snap` (jpg)
- `camera.clip` (mp4)

參數與 CLI 輔助工具請參閱 [Camera node](/nodes/camera)。
