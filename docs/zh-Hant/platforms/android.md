---
summary: "Android 應用程式（節點）：連接 runbook + Canvas/Chat/Camera"
read_when:
  - 配對或重新連接 Android 節點
  - 偵錯 Android gateway 發現或驗證
  - 驗證聊天歷史跨客戶端的對等性
title: "Android App（Android 應用程式）"
---

# Android 應用程式（節點）

## 支援快照

- 角色：伴隨節點應用程式（Android 不主持 Gateway）。
- 需要 Gateway：是（在 macOS、Linux 或 Windows via WSL2 上執行）。
- 安裝：[開始使用](/zh-Hant/start/getting-started) + [配對](/zh-Hant/gateway/pairing)。
- Gateway：[Runbook](/zh-Hant/gateway) + [配置](/zh-Hant/gateway/configuration)。
  - 協定：[Gateway 協定](/zh-Hant/gateway/protocol)（節點 + 控制平面）。

## 系統控制

系統控制（launchd/systemd）位於 Gateway 主機上。詳見 [Gateway](/zh-Hant/gateway)。

## 連接 Runbook

Android 節點應用程式 ⇄ (mDNS/NSD + WebSocket) ⇄ **Gateway**

Android 直接連接到 Gateway WebSocket（預設 `ws://<host>:18789`）並使用 Gateway 擁有的配對。

### 先決條件

- 你可在「主」機器上執行 Gateway。
- Android 設備/模擬器可到達 gateway WebSocket：
  - 相同 LAN 具有 mDNS/NSD，**或**
  - 使用 Tailscale tailnet 的廣域 Bonjour / unicast DNS-SD（詳見下文），**或**
  - 手動 gateway 主機/連接埠（退位）
- 你可在 gateway 機器上（或透過 SSH）執行 CLI（`openclaw`）。

### 1) 啟動 Gateway

```bash
openclaw gateway --port 18789 --verbose
```

在日誌中確認你看到類似的內容：

- `listening on ws://0.0.0.0:18789`

對於僅 tailnet 設定（建議用於 Vienna ⇄ London），將 gateway 綁定到 tailnet IP：

- 在 gateway 主機上的 `~/.openclaw/openclaw.json` 中設定 `gateway.bind: "tailnet"`。
- 重啟 Gateway / macOS 功能表欄應用程式。

### 2) 驗證發現（選用）

從 gateway 機器：

```bash
dns-sd -B _openclaw-gw._tcp local.
```

更多偵錯注意：[Bonjour](/zh-Hant/gateway/bonjour)。

#### Tailnet（Vienna ⇄ London）透過 unicast DNS-SD 發現

Android NSD/mDNS 發現不會跨網路。如果你的 Android 節點和 gateway 位於不同網路但透過 Tailscale 連接，改用廣域 Bonjour / unicast DNS-SD：

1. 在 gateway 主機上設定 DNS-SD 區域（例 `openclaw.internal.`）並發佈 `_openclaw-gw._tcp` 記錄。
2. 為選擇的網域配置 Tailscale 拆分 DNS，指向該 DNS 伺服器。

詳細資訊和 CoreDNS 配置範例：[Bonjour](/zh-Hant/gateway/bonjour)。

### 3) 從 Android 連接

在 Android 應用程式中：

- 應用程式透過**前景服務**（持久通知）保持其 gateway 連接活躍。
- 開啟**設定**。
- 在**發現的 Gateways** 下，選擇你的 gateway 並點擊**連接**。
- 如果 mDNS 被阻擋，使用**進階 → 手動 Gateway**（主機 + 連接埠）並**連接（手動）**。

第一次成功配對後，Android 在啟動時自動重新連接：

- 手動端點（如果啟用），否則
- 最後發現的 gateway（盡力）。

### 4) 批准配對 (CLI)

在 gateway 機器上：

```bash
openclaw nodes pending
openclaw nodes approve <requestId>
```

配對詳節：[Gateway 配對](/zh-Hant/gateway/pairing)。

### 5) 驗證節點已連接

- 透過節點狀態：

  ```bash
  openclaw nodes status
  ```

- 透過 Gateway：

  ```bash
  openclaw gateway call node.list --params "{}"
  ```

### 6) 聊天 + 歷史

Android 節點的聊天工作表使用 gateway 的**主要會話金鑰**（`main`），所以歷史和回覆與 WebChat 和其他客戶端共用：

- 歷史：`chat.history`
- 傳送：`chat.send`
- 推播更新（盡力）：`chat.subscribe` → `event:"chat"`

### 7) Canvas + 攝像頭

#### Gateway Canvas Host（推薦用於網路內容）

如果你想要節點顯示代理可在磁碟上編輯的實際 HTML/CSS/JS，將節點指向 Gateway canvas 主機。

注意：節點在 `canvasHost.port`（預設 `18793`）上使用獨立 canvas 主機。

1. 在 gateway 主機上建立 `~/.openclaw/workspace/canvas/index.html`。

2. 導覽節點到它（LAN）：

```bash
openclaw nodes invoke --node "<Android Node>" --command canvas.navigate --params '{"url":"http://<gateway-hostname>.local:18793/__openclaw__/canvas/"}'
```

Tailnet（選用）：如果兩個設備都在 Tailscale 上，改用 MagicDNS 名稱或 tailnet IP 而非 `.local`，例 `http://<gateway-magicdns>:18793/__openclaw__/canvas/`。

此伺服器將實時重新載入客戶端注入 HTML 並在檔案變更時重新載入。
A2UI 主機位於 `http://<gateway-host>:18793/__openclaw__/a2ui/`。

Canvas 命令（僅前景）：

- `canvas.eval`、`canvas.snapshot`、`canvas.navigate`（使用 `{"url":""}` 或 `{"url":"/"}` 回到預設支架）。`canvas.snapshot` 回傳 `{ format, base64 }`（預設 `format="jpeg"`）。
- A2UI：`canvas.a2ui.push`、`canvas.a2ui.reset`（`canvas.a2ui.pushJSONL` 舊版別名）

攝像頭命令（僅前景；權限門控）：

- `camera.snap`（jpg）
- `camera.clip`（mp4）

詳見 [攝像頭節點](/zh-Hant/nodes/camera) 以獲取參數和 CLI 助手。
