---
title: "節點"
summary: "節點：配對、功能、權限及用於 canvas/camera/screen/system 的 CLI 輔助工具"
read_when:
  - 配對 iOS/Android 節點至 Gateway 時
  - 使用節點 canvas/camera 為 Agent 提供上下文時
  - 新增節點指令或 CLI 輔助工具時
---

# 節點

一個**節點**是伴隨裝置（macOS/iOS/Android/無頭），以 `role: "node"` 連線到 Gateway **WebSocket**（與操作者相同的連接埠），並透由 `node.invoke` 公開指令介面（例如 `canvas.*`、`camera.*`、`system.*`）。協定詳情：[Gateway 協定](/gateway/protocol)。

舊版傳輸：[Bridge 協定](/gateway/bridge-protocol)（TCP JSONL；已棄用/當前節點已移除）。

macOS 也可在**節點模式**中執行：選單列 App 連線到 Gateway 的 WS 伺服器，將其本地 canvas/camera 指令公開為節點（因此 `openclaw nodes …` 對該 Mac 有效）。

注意：

- 節點是**外圍設備**，不是 Gateway。它們不執行 Gateway 服務。
- Telegram/WhatsApp/等訊息落在 **Gateway** 上，不在節點上。

## 配對 + 狀態

**WS 節點使用裝置配對。** 節點在 `connect` 期間提供裝置身份；Gateway 為 `role: node` 建立裝置配對請求。透由裝置 CLI（或 UI）核准。

快速 CLI：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
```

注意：

- `nodes status` 當節點裝置配對角色包含 `node` 時標記節點為**已配對**。
- `node.pair.*`（CLI：`openclaw nodes pending/approve/reject`）是單獨的 Gateway 所有節點配對儲存；它**不會**限制 WS `connect` 握手。

## 遠端節點主機（system.run）

當 Gateway 執行在一台機器上，且您想在另一台機器上執行指令時，使用**節點主機**。模型仍與 **Gateway** 對話；當選擇 `host=node` 時，Gateway 會將 `exec` 呼叫轉發到**節點主機**。

### 什麼執行在哪裡

- **Gateway 主機**：接收訊息、執行模型、路由工具呼叫。
- **節點主機**：在節點機器上執行 `system.run`/`system.which`。
- **核准**：透由 `~/.openclaw/exec-approvals.json` 在節點主機上強制執行。

### 啟動節點主機（前台）

在節點機器上：

```bash
openclaw node run --host <gateway-host> --port 18789 --display-name "Build Node"
```

### 透過 SSH 隧道的遠端 Gateway（迴圈綁定）

若 Gateway 綁定至迴圈（`gateway.bind=loopback`，本地模式預設），遠端節點主機無法直接連線。建立 SSH 隧道並指向節點主機到隧道的本地端。

範例（節點主機 -> Gateway 主機）：

```bash
# 終端 A（保持執行）：轉發本地 18790 -> Gateway 127.0.0.1:18789
ssh -N -L 18790:127.0.0.1:18789 user@gateway-host

# 終端 B：匯出 Gateway 令牌並透過隧道連線
export OPENCLAW_GATEWAY_TOKEN="<gateway-token>"
openclaw node run --host 127.0.0.1 --port 18790 --display-name "Build Node"
```

注意：

- 令牌是 Gateway 主機上 Gateway 配置（`~/.openclaw/openclaw.json`）中的 `gateway.auth.token`。
- `openclaw node run` 讀取 `OPENCLAW_GATEWAY_TOKEN` 進行認證。

### 啟動節點主機（服務）

```bash
openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"
openclaw node restart
```

### 配對 + 命名

在 Gateway 主機上：

```bash
openclaw nodes pending
openclaw nodes approve <requestId>
openclaw nodes list
```

命名選項：

- `openclaw node run` / `openclaw node install` 上的 `--display-name`（在節點上的 `~/.openclaw/node.json` 中保持）。
- `openclaw nodes rename --node <id|name|ip> --name "Build Node"`（Gateway 覆蓋）。

### 允許清單指令

Exec 核准是**每節點主機**。從 Gateway 新增允許清單項目：

```bash
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/uname"
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/sw_vers"
```

核准位於節點主機上的 `~/.openclaw/exec-approvals.json`。

### 指向節點的 exec

配置預設值（Gateway 配置）：

```bash
openclaw config set tools.exec.host node
openclaw config set tools.exec.security allowlist
openclaw config set tools.exec.node "<id-or-name>"
```

或各工作階段：

```
/exec host=node security=allowlist node=<id-or-name>
```

設定後，任何 `exec` 呼叫搭配 `host=node` 在節點主機上執行（受限於節點允許清單/核准）。

相關：

- [Node 主機 CLI](/cli/node)
- [Exec 工具](/tools/exec)
- [Exec 核准](/tools/exec-approvals)

## 呼叫指令

低級別（原始 RPC）：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command canvas.eval --params '{"javaScript":"location.href"}'
```

更高級別的輔助工具存在於常見的「為 Agent 提供 MEDIA 附件」工作流。

## 螢幕擷取（canvas 快照）

若節點顯示 Canvas（WebView），`canvas.snapshot` 回傳 `{ format, base64 }`。

CLI 輔助工具（寫至暫存檔並列印 `MEDIA:<path>`）：

```bash
openclaw nodes canvas snapshot --node <idOrNameOrIp> --format png
openclaw nodes canvas snapshot --node <idOrNameOrIp> --format jpg --max-width 1200 --quality 0.9
```

### Canvas 控制

```bash
openclaw nodes canvas present --node <idOrNameOrIp> --target https://example.com
openclaw nodes canvas hide --node <idOrNameOrIp>
openclaw nodes canvas navigate https://example.com --node <idOrNameOrIp>
openclaw nodes canvas eval --node <idOrNameOrIp> --js "document.title"
```

注意：

- `canvas present` 接受 URL 或本地檔案路徑（`--target`），加上選用的 `--x/--y/--width/--height` 以定位。
- `canvas eval` 接受內連 JS（`--js`）或位置參數。

### A2UI（Canvas）

```bash
openclaw nodes canvas a2ui push --node <idOrNameOrIp> --text "Hello"
openclaw nodes canvas a2ui push --node <idOrNameOrIp> --jsonl ./payload.jsonl
openclaw nodes canvas a2ui reset --node <idOrNameOrIp>
```

注意：

- 僅支援 A2UI v0.8 JSONL（v0.9/createSurface 遭拒）。

## 照片 + 影片（節點相機）

照片（`jpg`）：

```bash
openclaw nodes camera list --node <idOrNameOrIp>
openclaw nodes camera snap --node <idOrNameOrIp>            # 預設：兩個方向（2 個 MEDIA 行）
openclaw nodes camera snap --node <idOrNameOrIp> --facing front
```

影片片段（`mp4`）：

```bash
openclaw nodes camera clip --node <idOrNameOrIp> --duration 10s
openclaw nodes camera clip --node <idOrNameOrIp> --duration 3000 --no-audio
```

注意：

- 節點必須**前台執行** `canvas.*` 和 `camera.*`（背景呼叫回傳 `NODE_BACKGROUND_UNAVAILABLE`）。
- 片段時間上限（目前 `<= 60s`）以避免超大 base64 酬載。
- Android 會在可能時提示 `CAMERA`/`RECORD_AUDIO` 權限；被拒的權限失敗於 `*_PERMISSION_REQUIRED`。

## 螢幕錄製（節點）

節點公開 `screen.record`（mp4）。範例：

```bash
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10 --no-audio
```

注意：

- `screen.record` 需要節點 App 前台執行。
- Android 會在錄製前顯示系統螢幕擷取提示。
- 螢幕錄製限制在 `<= 60s`。
- `--no-audio` 停用麥克風擷取（iOS/Android 支援；macOS 使用系統擷取音訊）。
- 當多個螢幕可用時使用 `--screen <index>` 選擇顯示器。

## 位置（節點）

當設定中啟用位置時節點公開 `location.get`。

CLI 輔助工具：

```bash
openclaw nodes location get --node <idOrNameOrIp>
openclaw nodes location get --node <idOrNameOrIp> --accuracy precise --max-age 15000 --location-timeout 10000
```

注意：

- 位置**預設關閉**。
- 「Always」需要系統權限；背景擷取是最佳努力。
- 回應包含經度/緯度、準確度（公尺）及時間戳記。

## SMS（Android 節點）

Android 節點可在使用者授予 **SMS** 權限且裝置支援電話時公開 `sms.send`。

低級別呼叫：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command sms.send --params '{"to":"+15555550123","message":"Hello from OpenClaw"}'
```

注意：

- Android 裝置上必須接受權限提示後才能宣傳該功能。
- 無電話功能的 Wi-Fi 專用裝置不會宣傳 `sms.send`。

## 系統指令（節點主機 / Mac 節點）

macOS 節點公開 `system.run`、`system.notify` 和 `system.execApprovals.get/set`。
無頭節點主機公開 `system.run`、`system.which` 和 `system.execApprovals.get/set`。

範例：

```bash
openclaw nodes run --node <idOrNameOrIp> -- echo "Hello from mac node"
openclaw nodes notify --node <idOrNameOrIp> --title "Ping" --body "Gateway ready"
```

注意：

- `system.run` 在酬載中回傳 stdout/stderr/結束碼。
- `system.notify` 在 macOS App 上尊重通知權限狀態。
- `system.run` 支援 `--cwd`、`--env KEY=VAL`、`--command-timeout` 和 `--needs-screen-recording`。
- `system.notify` 支援 `--priority <passive|active|timeSensitive>` 和 `--delivery <system|overlay|auto>`。
- macOS 節點放棄 `PATH` 覆蓋；無頭節點主機僅接受 `PATH` 當其前綴節點主機 PATH 時。
- 在 macOS 節點模式中，`system.run` 透由 macOS App 中的 exec 核准限制（設定 → Exec 核准）。
  Ask/allowlist/full 表現與無頭節點主機相同；被拒的提示回傳 `SYSTEM_RUN_DENIED`。
- 在無頭節點主機上，`system.run` 透由 exec 核准限制（`~/.openclaw/exec-approvals.json`）。

## Exec 節點綁定

當多個節點可用時，您可將 exec 綁定至特定節點。
這設定 `exec host=node` 的預設節點（可依 Agent 覆蓋）。

全域預設值：

```bash
openclaw config set tools.exec.node "node-id-or-name"
```

各 Agent 覆蓋：

```bash
openclaw config get agents.list
openclaw config set agents.list[0].tools.exec.node "node-id-or-name"
```

取消設定以允許任何節點：

```bash
openclaw config unset tools.exec.node
openclaw config unset agents.list[0].tools.exec.node
```

## 權限對應

節點可能在 `node.list` / `node.describe` 中包含 `permissions` 對應，以權限名稱（例如 `screenRecording`、`accessibility`）為鍵，布林值（`true` = 已授予）。

## 無頭節點主機（跨平台）

OpenClaw 可執行**無頭節點主機**（無 UI），連線到 Gateway WebSocket 並公開 `system.run` / `system.which`。這在 Linux/Windows 或在伺服器旁執行最小節點時很有用。

啟動它：

```bash
openclaw node run --host <gateway-host> --port 18789
```

注意：

- 仍需配對（Gateway 將顯示節點核准提示）。
- 節點主機將其節點 id、令牌、顯示名稱及 Gateway 連線資訊儲存在 `~/.openclaw/node.json`。
- Exec 核准透由本地 `~/.openclaw/exec-approvals.json` 強制執行
  （參見 [Exec 核准](/tools/exec-approvals)）。
- 在 macOS 上，無頭節點主機偏好伴隨 App exec 主機當可達到且在 App 不可用時回退至本地執行。設定 `OPENCLAW_NODE_EXEC_HOST=app` 以需要 App，或 `OPENCLAW_NODE_EXEC_FALLBACK=0` 以停用回退。
- Gateway WS 使用 TLS 時新增 `--tls` / `--tls-fingerprint`。

## Mac 節點模式

- macOS 選單列 App 作為節點連線到 Gateway WS 伺服器（因此 `openclaw nodes …` 對該 Mac 有效）。
- 在遠端模式中，App 為 Gateway 連接埠開啟 SSH 隧道並連線到 `localhost`。
