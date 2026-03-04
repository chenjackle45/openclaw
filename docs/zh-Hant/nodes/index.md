---
summary: "節點：配對、功能、權限，以及 canvas/camera/screen/device/notifications/system CLI 助手"
read_when:
  - Pairing iOS/Android nodes to a gateway
  - Using node canvas/camera for agent context
  - Adding new node commands or CLI helpers
title: "Nodes（節點）"
---

# 節點

**節點**是連接至 Gateway **WebSocket**（與操作員相同的埠）的伴侶裝置（macOS/iOS/Android/無頭），具有 `role: "node"` 並通過 `node.invoke` 公開命令表面（例如 `canvas.*`、`camera.*`、`device.*`、`notifications.*`、`system.*`）。協議詳細資訊：[Gateway 協議](/zh-Hant/gateway/protocol)。

舊版傳輸：[Bridge 協議](/zh-Hant/gateway/bridge-protocol)（TCP JSONL；已棄用/移除，適用於當前節點）。

macOS 也可在**節點模式**執行：菜單欄應用程式連接至 Gateway 的 WS 伺服器，並將其本機 canvas/camera 命令公開為節點（所以 `openclaw nodes …` 對此 Mac 有效）。

注意：

- 節點是**周邊裝置**，不是 Gateway。它們不執行 Gateway 服務。
- Telegram/WhatsApp/等。訊息落地在 **Gateway**，不在節點。
- 疑難排解執行手冊：[/nodes/troubleshooting](/zh-Hant/nodes/troubleshooting)

## 配對 + 狀態

**WS 節點使用裝置配對。** 節點在 `connect` 期間呈現裝置身份；Gateway 為 `role: node` 建立裝置配對請求。通過裝置 CLI（或 UI）批准。

快速 CLI：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
```

注意：

- 當節點的裝置配對角色包括 `node` 時，`nodes status` 將節點標示為**已配對**。
- `node.pair.*`（CLI：`openclaw nodes pending/approve/reject`）是分離的 Gateway 擁有的節點配對存儲；它**不**閘口 WS `connect` 握手。

## 遠端節點主機（system.run）

當你的 Gateway 在一台機器上執行，而你想在另一台機器上執行命令時，使用**節點主機**。模型仍與 **Gateway** 交談；Gateway 在選擇 `host=node` 時將 `exec` 呼叫轉發至**節點主機**。

### 執行內容位置

- **Gateway 主機**：接收訊息、執行模型、路由工具呼叫。
- **節點主機**：在節點機器上執行 `system.run`/`system.which`。
- **批准**：通過 `~/.openclaw/exec-approvals.json` 在節點主機上實施。

### 啟動節點主機（前景）

在節點機器上：

```bash
openclaw node run --host <gateway-host> --port 18789 --display-name "Build Node"
```

### 通過 SSH 隧道的遠端 Gateway（loopback 綁定）

如果 Gateway 綁定至 loopback（`gateway.bind=loopback`，本機模式中的預設），遠端節點主機無法直接連線。建立 SSH 隧道，並將節點主機指向隧道的本機端。

例子（節點主機 -> Gateway 主機）：

```bash
# 終端 A（保持執行）：轉發本機 18790 -> Gateway 127.0.0.1:18789
ssh -N -L 18790:127.0.0.1:18789 user@gateway-host

# 終端 B：匯出 Gateway 令牌並通過隧道連線
export OPENCLAW_GATEWAY_TOKEN="<gateway-token>"
openclaw node run --host 127.0.0.1 --port 18790 --display-name "Build Node"
```

注意：

- 令牌是 Gateway 設定中的 `gateway.auth.token`（Gateway 主機上的 `~/.openclaw/openclaw.json`）。
- `openclaw node run` 讀取 `OPENCLAW_GATEWAY_TOKEN` 作認証。

### 啟動節點主機（服務）

```bash
openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"
openclaw node restart
```

### 配對 + 命名

在 Gateway 主機上：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw nodes status
```

命名選項：

- 在 `openclaw node run` / `openclaw node install` 上的 `--display-name`（保留在節點上的 `~/.openclaw/node.json`）。
- `openclaw nodes rename --node <id|name|ip> --name "Build Node"`（Gateway 覆寫）。

### 白名單命令

執行批准**按節點主機**進行。從 Gateway 新增白名單條目：

```bash
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/uname"
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/sw_vers"
```

批准位在節點主機上的 `~/.openclaw/exec-approvals.json`。

### 將 exec 指向節點

設定預設值（Gateway 設定）：

```bash
openclaw config set tools.exec.host node
openclaw config set tools.exec.security allowlist
openclaw config set tools.exec.node "<id-or-name>"
```

或每個會話：

```
/exec host=node security=allowlist node=<id-or-name>
```

一旦設定，任何帶 `host=node` 的 `exec` 呼叫執行在節點主機上（受節點白名單/批准約束）。

相關：

- [節點主機 CLI](/zh-Hant/cli/node)
- [Exec 工具](/zh-Hant/tools/exec)
- [Exec 批准](/zh-Hant/tools/exec-approvals)

## 叫用命令

低階（原生 RPC）：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command canvas.eval --params '{"javaScript":"location.href"}'
```

針對常見「給代理 MEDIA 附件」工作流程存在更高階的助手。

## 螢幕快照（Canvas 快照）

如果節點顯示 Canvas（WebView），`canvas.snapshot` 返回 `{ format, base64 }`。

CLI 助手（寫至臨時檔案並列印 `MEDIA:<path>`）：

```bash
openclaw nodes canvas snapshot --node <idOrNameOrIp> --format png
openclaw nodes canvas snapshot --node <idOrNameOrIp> --format jpg --max-width 1200 --quality 0.9
```

### Canvas 控制項

```bash
openclaw nodes canvas present --node <idOrNameOrIp> --target https://example.com
openclaw nodes canvas hide --node <idOrNameOrIp>
openclaw nodes canvas navigate https://example.com --node <idOrNameOrIp>
openclaw nodes canvas eval --node <idOrNameOrIp> --js "document.title"
```

注意：

- `canvas present` 接受 URL 或本機檔案路徑（`--target`），加上選用的 `--x/--y/--width/--height` 以定位。
- `canvas eval` 接受內聯 JS（`--js`）或位置引數。

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

注意：

- 節點必須**處於前景**以進行 `canvas.*` 和 `camera.*`（背景呼叫返回 `NODE_BACKGROUND_UNAVAILABLE`）。
- 片段持續時間被限制（目前 `<= 60s`）以避免超大 base64 有效負載。
- Android 在可能時會提示 `CAMERA`/`RECORD_AUDIO` 權限；拒絕的權限失敗並帶 `*_PERMISSION_REQUIRED`。

## 螢幕錄製（節點）

節點公開 `screen.record`（mp4）。例子：

```bash
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10 --no-audio
```

注意：

- `screen.record` 需要節點應用程式處於前景。
- Android 會在錄製前顯示系統螢幕擷取提示。
- 螢幕錄製被限制至 `<= 60s`。
- `--no-audio` 禁用麥克風擷取（在 iOS/Android 支援；macOS 使用系統擷取音訊）。
- 當有多個螢幕可用時，使用 `--screen <index>` 選擇顯示。

## 位置（節點）

當在設定中啟用「位置」時，節點公開 `location.get`。

CLI 助手：

```bash
openclaw nodes location get --node <idOrNameOrIp>
openclaw nodes location get --node <idOrNameOrIp> --accuracy precise --max-age 15000 --location-timeout 10000
```

注意：

- 位置**預設關閉**。
- 「始終」需要系統權限；背景抓取是最盡力。
- 響應包括緯度/經度、精度（公尺）和時間戳。

## SMS（Android 節點）

當使用者授予 **SMS** 權限且裝置支援電話服務時，Android 節點可公開 `sms.send`。

低階叫用：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command sms.send --params '{"to":"+15555550123","message":"Hello from OpenClaw"}'
```

注意：

- 必須在 Android 裝置上接受權限提示，才能公開功能。
- Wi-Fi 專用裝置無電話服務將不公開 `sms.send`。

## Android 裝置 + 個人資料命令

當啟用對應功能時，Android 節點可公開額外的命令族。

可用族：

- `device.status`, `device.info`, `device.permissions`, `device.health`
- `notifications.list`, `notifications.actions`
- `photos.latest`
- `contacts.search`, `contacts.add`
- `calendar.events`, `calendar.add`
- `motion.activity`, `motion.pedometer`
- `app.update`

叫用例子：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command device.status --params '{}'
openclaw nodes invoke --node <idOrNameOrIp> --command notifications.list --params '{}'
openclaw nodes invoke --node <idOrNameOrIp> --command photos.latest --params '{"limit":1}'
```

注意：

- 動作命令由可用感測器的功能閘口。
- `app.update` 由節點執行時的權限 + 政策閘口。

## 系統命令（節點主機 / Mac 節點）

macOS 節點公開 `system.run`、`system.notify` 和 `system.execApprovals.get/set`。
無頭節點主機公開 `system.run`、`system.which` 和 `system.execApprovals.get/set`。

例子：

```bash
openclaw nodes run --node <idOrNameOrIp> -- echo "Hello from mac node"
openclaw nodes notify --node <idOrNameOrIp> --title "Ping" --body "Gateway ready"
```

注意：

- `system.run` 返回有效負載中的 stdout/stderr/退出碼。
- `system.notify` 在 macOS 應用程式上尊重通知權限狀態。
- 無法識別的節點 `platform` / `deviceFamily` 元資料使用保守的預設白名單，排除 `system.run` 和 `system.which`。如果你刻意需要這些命令作未知平台，通過 `gateway.nodes.allowCommands` 明確新增它們。
- `system.run` 支援 `--cwd`、`--env KEY=VAL`、`--command-timeout` 和 `--needs-screen-recording`。
- 對於殼層包裝器（`bash|sh|zsh ... -c/-lc`），請求範圍 `--env` 值被簡化至明確白名單（`TERM`、`LANG`、`LC_*`、`COLORTERM`、`NO_COLOR`、`FORCE_COLOR`）。
- 在白名單模式中，已知調度包裝器（`env`、`nice`、`nohup`、`stdbuf`、`timeout`）持續內部可執行路徑而不是包裝器路徑。如果解除包裝不安全，無白名單條目自動保留。
- 在 Windows 節點主機上的白名單模式中，通過 `cmd.exe /c` 的殼層包裝器執行需要批准（僅白名單條目不自動允許包裝器形式）。
- `system.notify` 支援 `--priority <passive|active|timeSensitive>` 和 `--delivery <system|overlay|auto>`。
- 節點主機忽略 `PATH` 覆寫並移除危險的啟動/殼層鍵（`DYLD_*`、`LD_*`、`NODE_OPTIONS`、`PYTHON*`、`PERL*`、`RUBYOPT`、`SHELLOPTS`、`PS4`）。如果需要額外 PATH 條目，設定節點主機服務環境（或在標準位置安裝工具）而不是通過 `--env` 傳遞 `PATH`。
- 在 macOS 節點模式上，`system.run` 由 macOS 應用程式中的執行批准閘口（設定 → Exec 批准）。Ask/白名單/完整表現相同；拒絕的提示返回 `SYSTEM_RUN_DENIED`。
- 在無頭節點主機上，`system.run` 由執行批准閘口（`~/.openclaw/exec-approvals.json`）。

## Exec 節點綁定

當有多個節點可用時，你可綁定 exec 至特定節點。
這設定 `exec host=node` 的預設節點（可按代理覆寫）。

全域預設：

```bash
openclaw config set tools.exec.node "node-id-or-name"
```

按代理覆寫：

```bash
openclaw config get agents.list
openclaw config set agents.list[0].tools.exec.node "node-id-or-name"
```

解除設定以允許任何節點：

```bash
openclaw config unset tools.exec.node
openclaw config unset agents.list[0].tools.exec.node
```

## 權限對應

節點可在 `node.list` / `node.describe` 中包括 `permissions` 對應，由權限名稱鍵（例如 `screenRecording`、`accessibility`）加布林值（`true` = 已授予）。

## 無頭節點主機（跨平台）

OpenClaw 可執行**無頭節點主機**（無 UI），連接至 Gateway WebSocket 並公開 `system.run` / `system.which`。這在 Linux/Windows 或執行最小節點與伺服器並行時有用。

啟動它：

```bash
openclaw node run --host <gateway-host> --port 18789
```

注意：

- 配對仍需（Gateway 將顯示裝置配對提示）。
- 節點主機在 `~/.openclaw/node.json` 中儲存其節點 id、令牌、顯示名稱和 Gateway 連線資訊。
- 執行批准在本機通過 `~/.openclaw/exec-approvals.json` 實施（見 [Exec 批准](/zh-Hant/tools/exec-approvals)）。
- 在 macOS 上，無頭節點主機預設在本機執行 `system.run`。設定 `OPENCLAW_NODE_EXEC_HOST=app` 通過伴侶應用程式 exec 主機路由 `system.run`；新增 `OPENCLAW_NODE_EXEC_FALLBACK=0` 以要求應用程式主機，如果不可用則失敗關閉。
- 當 Gateway WS 使用 TLS 時新增 `--tls` / `--tls-fingerprint`。

## Mac 節點模式

- macOS 菜單欄應用程式連接至 Gateway WS 伺服器作節點（所以 `openclaw nodes …` 對此 Mac 有效）。
- 在遠端模式中，應用程式開啟 Gateway 埠的 SSH 隧道並連接至 `localhost`。
