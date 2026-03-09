---
summary: "Android 應用程式（節點）：連線 runbook + Connect/Chat/Voice/Canvas 指令介面"
read_when:
  - 配對或重新連線 Android 節點
  - 除錯 Android gateway 探索或驗證
  - 驗證聊天歷程跨客戶端的一致性
title: "Android App（Android 應用程式）"
---

# Android 應用程式（節點）

## 支援快照

- 角色：配套節點應用程式（Android 不主持 Gateway）。
- 需要 Gateway：是（在 macOS、Linux 或 Windows via WSL2 上執行）。
- 安裝：[開始使用](/zh-Hant/start/getting-started) + [配對](/zh-Hant/channels/pairing)。
- Gateway：[Runbook](/zh-Hant/gateway) + [設定](/zh-Hant/gateway/configuration)。
  - 協定：[Gateway 協定](/zh-Hant/gateway/protocol)（節點 + 控制平面）。

## 系統控制

系統控制（launchd/systemd）位於 Gateway 主機上。請見 [Gateway](/zh-Hant/gateway)。

## 連線 Runbook

Android 節點應用程式 ⇄（mDNS/NSD + WebSocket）⇄ **Gateway**

Android 直接連線至 Gateway WebSocket（預設 `ws://<host>:18789`）並使用裝置配對（`role: node`）。

### 先決條件

- 你可以在「主」機器上執行 Gateway。
- Android 裝置/模擬器可到達 gateway WebSocket：
  - 相同 LAN 具有 mDNS/NSD，**或**
  - 使用 Tailscale tailnet 的廣域 Bonjour / unicast DNS-SD（見下文），**或**
  - 手動 gateway 主機/連接埠（退備）
- 你可以在 gateway 機器上（或透過 SSH）執行 CLI（`openclaw`）。

### 1）啟動 Gateway

```bash
openclaw gateway --port 18789 --verbose
```

在記錄中確認你看到類似的內容：

- `listening on ws://0.0.0.0:18789`

對於僅 tailnet 設定（建議用於跨網路場景），將 gateway 綁定至 tailnet IP：

- 在 gateway 主機的 `~/.openclaw/openclaw.json` 中設定 `gateway.bind: "tailnet"`。
- 重啟 Gateway／macOS 選單列應用程式。

### 2）驗證探索（選用）

從 gateway 機器：

```bash
dns-sd -B _openclaw-gw._tcp local.
```

更多除錯注意事項：[Bonjour](/zh-Hant/gateway/bonjour)。

#### Tailnet 透過 unicast DNS-SD 探索

Android NSD/mDNS 探索不會跨網路。若你的 Android 節點和 gateway 位於不同網路但透過 Tailscale 連線，請改用廣域 Bonjour / unicast DNS-SD：

1. 在 gateway 主機上設定 DNS-SD 區域（例如 `openclaw.internal.`）並發布 `_openclaw-gw._tcp` 記錄。
2. 為選擇的網域設定 Tailscale split DNS，指向該 DNS 伺服器。

詳細資訊和 CoreDNS 設定範例：[Bonjour](/zh-Hant/gateway/bonjour)。

### 3）從 Android 連線

在 Android 應用程式中：

- 應用程式透過**前景服務**（持久通知）保持 gateway 連線。
- 開啟 **Connect** 分頁。
- 使用 **Setup Code** 或 **Manual** 模式。
- 若探索被封鎖，在**進階控制**中使用手動主機/連接埠（以及需要時的 TLS/token/密碼）。

第一次成功配對後，Android 在啟動時自動重新連線：

- 手動端點（若已啟用），否則
- 最後探索到的 gateway（盡力而為）。

### 4）核准配對（CLI）

在 gateway 機器上：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
```

配對詳情：[配對](/zh-Hant/channels/pairing)。

### 5）驗證節點已連線

- 透過節點狀態：

  ```bash
  openclaw nodes status
  ```

- 透過 Gateway：

  ```bash
  openclaw gateway call node.list --params "{}"
  ```

### 6）聊天 + 歷程

Android 聊天分頁支援 session 選擇（預設 `main`，加上其他現有 session）：

- 歷程：`chat.history`
- 傳送：`chat.send`
- 推播更新（盡力而為）：`chat.subscribe` → `event:"chat"`

### 7）Canvas + 相機

#### Gateway Canvas Host（建議用於網頁內容）

若你想讓節點顯示 agent 可在磁碟上編輯的實際 HTML/CSS/JS，將節點指向 Gateway canvas host。

注意：節點從 Gateway HTTP 伺服器（與 `gateway.port` 相同的連接埠，預設 `18789`）載入 canvas。

1. 在 gateway 主機上建立 `~/.openclaw/workspace/canvas/index.html`。

2. 將節點導覽至此（LAN）：

```bash
openclaw nodes invoke --node "<Android Node>" --command canvas.navigate --params '{"url":"http://<gateway-hostname>.local:18789/__openclaw__/canvas/"}'
```

Tailnet（選用）：若兩個裝置都在 Tailscale 上，使用 MagicDNS 名稱或 tailnet IP 取代 `.local`，例如 `http://<gateway-magicdns>:18789/__openclaw__/canvas/`。

此伺服器將即時重新載入客戶端注入 HTML，並在檔案變更時重新載入。
A2UI host 位於 `http://<gateway-host>:18789/__openclaw__/a2ui/`。

Canvas 指令（僅前景）：

- `canvas.eval`、`canvas.snapshot`、`canvas.navigate`（使用 `{"url":""}` 或 `{"url":"/"}` 返回預設框架）。`canvas.snapshot` 返回 `{ format, base64 }`（預設 `format="jpeg"`）。
- A2UI：`canvas.a2ui.push`、`canvas.a2ui.reset`（`canvas.a2ui.pushJSONL` 舊版別名）

相機指令（僅前景；需要權限）：

- `camera.snap`（jpg）
- `camera.clip`（mp4）

參數和 CLI 輔助工具請見 [相機節點](/zh-Hant/nodes/camera)。

### 8）語音 + 擴充的 Android 指令介面

- 語音：Android 在語音分頁中使用單一麥克風開/關流程，具有轉錄擷取和 TTS 播放（已設定時使用 ElevenLabs，退備至系統 TTS）。應用程式離開前景時語音停止。
- 語音喚醒/talk 模式切換目前已從 Android UX/執行階段移除。
- 額外的 Android 指令族（可用性取決於裝置 + 權限）：
  - `device.status`、`device.info`、`device.permissions`、`device.health`
  - `notifications.list`、`notifications.actions`
  - `photos.latest`
  - `contacts.search`、`contacts.add`
  - `calendar.events`、`calendar.add`
  - `motion.activity`、`motion.pedometer`
