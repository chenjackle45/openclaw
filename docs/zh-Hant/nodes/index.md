---
summary: "節點：配對、功能、權限，以及 canvas/camera/screen/device/notifications/system 的 CLI 輔助工具"
read_when:
  - 將 iOS/Android 節點配對至 gateway
  - 使用節點的 canvas/camera 提供 agent 上下文
  - 新增節點指令或 CLI 輔助工具
title: "Nodes（節點）"
---

# 節點

**節點**是連接至 Gateway **WebSocket**（與操作員相同的連接埠）的配套裝置（macOS/iOS/Android/無頭），具有 `role: "node"`，並透過 `node.invoke` 公開指令介面（例如 `canvas.*`、`camera.*`、`device.*`、`notifications.*`、`system.*`）。協定詳情：[Gateway 協定](/zh-Hant/gateway/protocol)。

舊版傳輸：[Bridge 協定](/zh-Hant/gateway/bridge-protocol)（TCP JSONL；已棄用／已移除，適用於目前節點）。

macOS 也可以在**節點模式**下運行：選單列應用程式連接至 Gateway 的 WS 伺服器，並將其本地 canvas/camera 指令公開為節點（因此 `openclaw nodes …` 可對此 Mac 使用）。

注意事項：

- 節點是**周邊裝置**，不是 gateway。它們不執行 gateway 服務。
- Telegram/WhatsApp/等訊息落地在 **gateway**，不在節點。
- 疑難排解執行手冊：[/nodes/troubleshooting](/zh-Hant/nodes/troubleshooting)

## 配對 + 狀態

**WS 節點使用裝置配對。** 節點在 `connect` 期間呈現裝置身份；Gateway 為 `role: node` 建立裝置配對請求。透過裝置 CLI（或 UI）核准。

快速 CLI：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
```

注意事項：

- 當節點的裝置配對角色包含 `node` 時，`nodes status` 將節點標記為**已配對**。
- `node.pair.*`（CLI：`openclaw nodes pending/approve/reject`）是獨立的 gateway 擁有的節點配對儲存；它**不**把守 WS `connect` 握手。

## 遠端節點主機（system.run）

當你的 Gateway 在一台機器上運行，而你想在另一台機器上執行指令時，使用**節點主機**。模型仍然與 **gateway** 通訊；gateway 在選擇 `host=node` 時將 `exec` 呼叫轉發至**節點主機**。

### 執行位置

- **Gateway 主機**：接收訊息、執行模型、路由工具呼叫。
- **節點主機**：在節點機器上執行 `system.run`/`system.which`。
- **核准**：透過 `~/.openclaw/exec-approvals.json` 在節點主機上執行。

### 啟動節點主機（前景）

在節點機器上：

```bash
openclaw node run --host <gateway-host> --port 18789 --display-name "Build Node"
```

### 透過 SSH 隧道連接遠端 gateway（loopback 綁定）

若 Gateway 綁定至 loopback（`gateway.bind=loopback`，本地模式的預設），遠端節點主機無法直接連線。建立 SSH 隧道並將節點主機指向隧道的本地端。

範例（節點主機 → gateway 主機）：

```bash
# 終端機 A（保持執行）：轉發本地 18790 -> gateway 127.0.0.1:18789
ssh -N -L 18790:127.0.0.1:18789 user@gateway-host

# 終端機 B：匯出 gateway token 並透過隧道連線
export OPENCLAW_GATEWAY_TOKEN="<gateway-token>"
openclaw node run --host 127.0.0.1 --port 18790 --display-name "Build Node"
```

注意事項：

- `openclaw node run` 支援 token 或密碼驗證。
- 偏好使用環境變數：`OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`。
- Config 退備為 `gateway.auth.token` / `gateway.auth.password`；在遠端模式下，`gateway.remote.token` / `gateway.remote.password` 也適用。
- 舊版 `CLAWDBOT_GATEWAY_*` 環境變數刻意被節點主機驗證解析忽略。

### 啟動節點主機（服務）

```bash
openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"
openclaw node restart
```

### 配對 + 命名

在 gateway 主機上：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw nodes status
```

命名選項：

- 在 `openclaw node run` / `openclaw node install` 上使用 `--display-name`（持久化至節點上的 `~/.openclaw/node.json`）。
- `openclaw nodes rename --node <id|name|ip> --name "Build Node"`（gateway 覆蓋）。

### 加入允許清單

Exec 核准**按節點主機**進行。從 gateway 新增允許清單條目：

```bash
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/uname"
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/sw_vers"
```

核准存於節點主機的 `~/.openclaw/exec-approvals.json`。

### 將 exec 指向節點

設定預設值（gateway 設定）：

```bash
openclaw config set tools.exec.host node
openclaw config set tools.exec.security allowlist
openclaw config set tools.exec.node "<id-or-name>"
```

或按 session：

```
/exec host=node security=allowlist node=<id-or-name>
```

設定後，任何帶 `host=node` 的 `exec` 呼叫都在節點主機上執行（受節點允許清單/核准約束）。

相關：

- [節點主機 CLI](/zh-Hant/cli/node)
- [Exec 工具](/zh-Hant/tools/exec)
- [Exec 核准](/zh-Hant/tools/exec-approvals)

## 呼叫指令

低階（原始 RPC）：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command canvas.eval --params '{"javaScript":"location.href"}'
```

針對常見的「給 agent 一個 MEDIA 附件」工作流程，有更高階的輔助工具。

## 截圖（Canvas 快照）

若節點正在顯示 Canvas（WebView），`canvas.snapshot` 返回 `{ format, base64 }`。

CLI 輔助工具（寫入暫存檔並列印 `MEDIA:<path>`）：

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

注意事項：

- `canvas present` 接受 URL 或本地檔案路徑（`--target`），加上可選的 `--x/--y/--width/--height` 以定位。
- `canvas eval` 接受內嵌 JS（`--js`）或位置引數。

### A2UI（Canvas）

```bash
openclaw nodes canvas a2ui push --node <idOrNameOrIp> --text "Hello"
openclaw nodes canvas a2ui push --node <idOrNameOrIp> --jsonl ./payload.jsonl
openclaw nodes canvas a2ui reset --node <idOrNameOrIp>
```

注意事項：

- 僅支援 A2UI v0.8 JSONL（v0.9/createSurface 會被拒絕）。

## 照片 + 影片（節點相機）

照片（`jpg`）：

```bash
openclaw nodes camera list --node <idOrNameOrIp>
openclaw nodes camera snap --node <idOrNameOrIp>            # 預設：兩個鏡頭（2 MEDIA 行）
openclaw nodes camera snap --node <idOrNameOrIp> --facing front
```

影片片段（`mp4`）：

```bash
openclaw nodes camera clip --node <idOrNameOrIp> --duration 10s
openclaw nodes camera clip --node <idOrNameOrIp> --duration 3000 --no-audio
```

注意事項：

- 節點必須**在前景**才能使用 `canvas.*` 和 `camera.*`（背景呼叫返回 `NODE_BACKGROUND_UNAVAILABLE`）。
- 片段時長受到限制（目前 `<= 60s`）以避免過大的 base64 資料。
- Android 在可能時會提示 `CAMERA`/`RECORD_AUDIO` 權限；拒絕的權限會以 `*_PERMISSION_REQUIRED` 失敗。

## 螢幕錄製（節點）

支援的節點公開 `screen.record`（mp4）。範例：

```bash
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10 --no-audio
```

注意事項：

- `screen.record` 可用性取決於節點平台。
- 螢幕錄製限制為 `<= 60s`。
- `--no-audio` 在支援的平台上停用麥克風擷取。
- 有多個螢幕時，使用 `--screen <index>` 選擇顯示器。

## 位置（節點）

在設定中啟用位置後，節點公開 `location.get`。

CLI 輔助工具：

```bash
openclaw nodes location get --node <idOrNameOrIp>
openclaw nodes location get --node <idOrNameOrIp> --accuracy precise --max-age 15000 --location-timeout 10000
```

注意事項：

- 位置**預設關閉**。
- 「永遠」需要系統權限；背景擷取是盡力而為。
- 回應包含緯度/經度、精度（公尺）與時間戳記。

## SMS（Android 節點）

當使用者授予 **SMS** 權限且裝置支援電話服務時，Android 節點可公開 `sms.send`。

低階呼叫：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command sms.send --params '{"to":"+15555550123","message":"Hello from OpenClaw"}'
```

注意事項：

- 必須在 Android 裝置上接受權限提示，才能公開該功能。
- 僅 Wi-Fi 且無電話服務的裝置不會公開 `sms.send`。

## Android 裝置 + 個人資料指令

啟用對應功能後，Android 節點可公開額外的指令族。

可用族：

- `device.status`、`device.info`、`device.permissions`、`device.health`
- `notifications.list`、`notifications.actions`
- `photos.latest`
- `contacts.search`、`contacts.add`
- `calendar.events`、`calendar.add`
- `motion.activity`、`motion.pedometer`

呼叫範例：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command device.status --params '{}'
openclaw nodes invoke --node <idOrNameOrIp> --command notifications.list --params '{}'
openclaw nodes invoke --node <idOrNameOrIp> --command photos.latest --params '{"limit":1}'
```

注意事項：

- 動作指令受可用感應器的功能限制。

## 系統指令（節點主機／Mac 節點）

macOS 節點公開 `system.run`、`system.notify` 和 `system.execApprovals.get/set`。
無頭節點主機公開 `system.run`、`system.which` 和 `system.execApprovals.get/set`。

範例：

```bash
openclaw nodes run --node <idOrNameOrIp> -- echo "Hello from mac node"
openclaw nodes notify --node <idOrNameOrIp> --title "Ping" --body "Gateway ready"
```

注意事項：

- `system.run` 在有效負載中返回 stdout/stderr/退出碼。
- `system.notify` 在 macOS 應用程式上遵守通知權限狀態。
- 無法識別的節點 `platform` / `deviceFamily` 中繼資料使用保守的預設允許清單，排除 `system.run` 和 `system.which`。若刻意需要這些指令用於未知平台，請透過 `gateway.nodes.allowCommands` 明確新增。
- `system.run` 支援 `--cwd`、`--env KEY=VAL`、`--command-timeout` 和 `--needs-screen-recording`。
- 對於 shell 包裝器（`bash|sh|zsh ... -c/-lc`），請求範圍的 `--env` 值縮減為明確允許清單（`TERM`、`LANG`、`LC_*`、`COLORTERM`、`NO_COLOR`、`FORCE_COLOR`）。
- 在允許清單模式下，已知的調度包裝器（`env`、`nice`、`nohup`、`stdbuf`、`timeout`）持久化內部可執行路徑而非包裝器路徑。若解除包裝不安全，則不自動持久化允許清單條目。
- 在 Windows 節點主機的允許清單模式下，透過 `cmd.exe /c` 的 shell 包裝器執行需要核准（僅允許清單條目不會自動允許包裝器形式）。
- `system.notify` 支援 `--priority <passive|active|timeSensitive>` 和 `--delivery <system|overlay|auto>`。
- 節點主機忽略 `PATH` 覆蓋，並剝除危險的啟動/shell 金鑰（`DYLD_*`、`LD_*`、`NODE_OPTIONS`、`PYTHON*`、`PERL*`、`RUBYOPT`、`SHELLOPTS`、`PS4`）。若需要額外的 PATH 條目，請設定節點主機服務環境（或在標準位置安裝工具），而不是透過 `--env` 傳遞 `PATH`。
- 在 macOS 節點模式下，`system.run` 由 macOS 應用程式的 exec 核准把守（設定 → Exec 核准）。Ask/allowlist/full 的行為與無頭節點主機相同；被拒絕的提示返回 `SYSTEM_RUN_DENIED`。
- 在無頭節點主機上，`system.run` 由 exec 核准把守（`~/.openclaw/exec-approvals.json`）。

## Exec 節點綁定

當有多個節點可用時，你可以將 exec 綁定至特定節點。
這設定 `exec host=node` 的預設節點（可按 agent 覆蓋）。

全域預設：

```bash
openclaw config set tools.exec.node "node-id-or-name"
```

按 agent 覆蓋：

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

節點可在 `node.list` / `node.describe` 中包含 `permissions` 對應，以權限名稱為鍵（例如 `screenRecording`、`accessibility`），值為布林值（`true` = 已授予）。

## 無頭節點主機（跨平台）

OpenClaw 可執行**無頭節點主機**（無 UI），連接至 Gateway WebSocket 並公開 `system.run` / `system.which`。這在 Linux/Windows 上或需要在伺服器旁運行最小節點時很有用。

啟動：

```bash
openclaw node run --host <gateway-host> --port 18789
```

注意事項：

- 仍需配對（Gateway 會顯示裝置配對提示）。
- 節點主機在 `~/.openclaw/node.json` 中儲存其節點 id、token、顯示名稱和 gateway 連線資訊。
- Exec 核准在本地透過 `~/.openclaw/exec-approvals.json` 執行（見 [Exec 核准](/zh-Hant/tools/exec-approvals)）。
- 在 macOS 上，無頭節點主機預設在本地執行 `system.run`。設定 `OPENCLAW_NODE_EXEC_HOST=app` 可透過配套應用程式 exec 主機路由 `system.run`；加上 `OPENCLAW_NODE_EXEC_FALLBACK=0` 可要求應用程式主機，若不可用則關閉失敗。
- 當 Gateway WS 使用 TLS 時，加上 `--tls` / `--tls-fingerprint`。

## Mac 節點模式

- macOS 選單列應用程式連接至 Gateway WS 伺服器作為節點（因此 `openclaw nodes …` 可對此 Mac 使用）。
- 在遠端模式下，應用程式為 Gateway 連接埠開啟 SSH 隧道並連接至 `localhost`。
