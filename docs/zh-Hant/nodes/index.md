---
title: "Nodes（節點）"
summary: "節點：配對、功能、權限，以及用於畫布／相機／螢幕／設備／通知／系統的 CLI 幫手"
read_when:
  - 將 iOS／Android 節點配對到 gateway
  - 使用節點畫布／相機進行代理背景
  - 新增新的節點命令或 CLI 幫手
---

# 節點

**節點**是一個伴隨設備（macOS／iOS／Android／無頭），連接到 Gateway **WebSocket**（與操作者相同的連接埠），角色為 `role: "node"` 並透過 `node.invoke` 公開命令表面（例如 `canvas.*`、`camera.*`、`device.*`、`notifications.*`、`system.*`）。協議詳細資料：[Gateway 協議](/zh-Hant/gateway/protocol)。

舊版傳輸：[Bridge 協議](/zh-Hant/gateway/bridge-protocol)（TCP JSONL；現有節點已棄用／移除）。

macOS 也可以在 **節點模式**中執行：menubar app 連接到 Gateway 的 WS 伺服器並公開其本地畫布／相機命令作為節點（所以 `openclaw nodes …` 對此 Mac 有效）。

備註：

- 節點是 **週邊設備**，不是 gateway。他們不執行 gateway 服務。
- Telegram／WhatsApp／等訊息著陸在 **gateway** 上，不在節點上。
- 故障排除執行手冊：[/nodes/troubleshooting](/zh-Hant/nodes/troubleshooting)

## 配對 + 狀態

**WS 節點使用設備配對。** 節點在 `connect` 期間提供設備身分識別；Gateway 為 `role: node` 建立設備配對要求。透過設備 CLI（或 UI）批准。

快速 CLI：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
```

備註：

- 當設備配對角色包含 `node` 時，`nodes status` 標記節點為 **配對**。
- `node.pair.*`（CLI：`openclaw nodes pending/approve/reject`）是獨立的 gateway 擁有的節點配對存儲；它 **不**門控 WS `connect` 握手。

## 遠端節點主機（system.run）

當您的 Gateway 在一台機器上執行而您想要命令在另一台機器上執行時，使用 **節點主機**。模型仍然與 **gateway** 通話；當選擇 `host=node` 時，gateway 將 `exec` 呼叫轉發到 **節點主機**。

### 什麼在哪裡執行

- **Gateway 主機**：接收訊息、執行模型、路由工具呼叫。
- **節點主機**：在節點機器上執行 `system.run`／`system.which`。
- **批准**：透過 `~/.openclaw/exec-approvals.json` 在節點主機上強制執行。

批准備註：

- 批准支援的節點執行綁定精確的要求背景。
- 對於直接 shell／執行時間檔案執行，OpenClaw 也盡力綁定一個混凝土本地檔案操作數並拒絕執行如果該檔案在執行前變更。
- 如果 OpenClaw 無法為解譯器／執行時間命令識別精確一個混凝土本地檔案，批准支援的執行被拒絕而不是假裝完整執行時間涵蓋。使用沙箱、獨立主機或用於更廣泛解譯器語義的明確受信允許清單／完整工作流程。

### 啟動節點主機（前景）

在節點機器上：

```bash
openclaw node run --host <gateway-host> --port 18789 --display-name "Build Node"
```

### 透過 SSH 通道遠端 gateway（loopback 繫結）

如果 Gateway 繫結到 loopback（`gateway.bind=loopback`，本地模式中的預設值），遠端節點主機無法直接連接。建立 SSH 通道並將節點主機指向通道的本地端。

範例（節點主機 -> gateway 主機）：

```bash
# 終端機 A（保持執行）：轉發本地 18790 -> gateway 127.0.0.1:18789
ssh -N -L 18790:127.0.0.1:18789 user@gateway-host

# 終端機 B：匯出 gateway 令牌並透過通道連接
export OPENCLAW_GATEWAY_TOKEN="<gateway-token>"
openclaw node run --host 127.0.0.1 --port 18790 --display-name "Build Node"
```

備註：

- `openclaw node run` 支援令牌或密碼驗證。
- 優先使用環境變數：`OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`。
- 設定回退為 `gateway.auth.token` / `gateway.auth.password`。
- 在本地模式中，節點主機刻意忽略 `gateway.remote.token` / `gateway.remote.password`。
- 在遠端模式中，`gateway.remote.token` / `gateway.remote.password` 根據遠端優先順序規則合格。
- 如果作用中本地 `gateway.auth.*` SecretRef 已設定但未解析，節點主機驗證失敗關閉。

### 啟動節點主機（服務）

```bash
openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"
openclaw node restart
```

### 配對 + 名稱

在 gateway 主機上：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw nodes status
```

命名選項：

- `--display-name`（在 `openclaw node run` / `openclaw node install` 上）（在節點上的 `~/.openclaw/node.json` 中保存）。
- `openclaw nodes rename --node <id|name|ip> --name "Build Node"`（gateway 覆寫）。

### 允許清單命令

執行批准為 **每個節點主機**。從 gateway 新增允許清單條目：

```bash
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/uname"
openclaw approvals allowlist add --node <id|name|ip> "/usr/bin/sw_vers"
```

批准存儲在節點主機上的 `~/.openclaw/exec-approvals.json`。

### 指向節點的 exec

設定預設值（gateway 設定）：

```bash
openclaw config set tools.exec.host node
openclaw config set tools.exec.security allowlist
openclaw config set tools.exec.node "<id-or-name>"
```

或每個工作階段：

```
/exec host=node security=allowlist node=<id-or-name>
```

設定後，任何 `exec` 呼叫用 `host=node` 執行在節點主機上（受節點允許清單／批准限制）。

相關：

- [節點主機 CLI](/zh-Hant/cli/node)
- [執行工具](/zh-Hant/tools/exec)
- [執行批准](/zh-Hant/tools/exec-approvals)

## 叫用命令

低層級（原始 RPC）：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command canvas.eval --params '{"javaScript":"location.href"}'
```

高層級幫手存在用於常見「給代理一個 MEDIA 附件」工作流程。

## 螢幕擷取畫面（畫布快照）

如果節點顯示畫布（WebView），`canvas.snapshot` 傳回 `{ format, base64 }`。

CLI 幫手（寫入臨時檔案並列印 `MEDIA:<path>`）：

```bash
openclaw nodes canvas snapshot --node <idOrNameOrIp> --format png
openclaw nodes canvas snapshot --node <idOrNameOrIp> --format jpg --max-width 1200 --quality 0.9
```

### 畫布控制

```bash
openclaw nodes canvas present --node <idOrNameOrIp> --target https://example.com
openclaw nodes canvas hide --node <idOrNameOrIp>
openclaw nodes canvas navigate https://example.com --node <idOrNameOrIp>
openclaw nodes canvas eval --node <idOrNameOrIp> --js "document.title"
```

備註：

- `canvas present` 接受 URL 或本地檔案路徑（`--target`），加上選擇性 `--x/--y/--width/--height` 以定位。
- `canvas eval` 接受內聯 JS（`--js`）或位置引數。

### A2UI（畫布）

```bash
openclaw nodes canvas a2ui push --node <idOrNameOrIp> --text "Hello"
openclaw nodes canvas a2ui push --node <idOrNameOrIp> --jsonl ./payload.jsonl
openclaw nodes canvas a2ui reset --node <idOrNameOrIp>
```

備註：

- 僅支援 A2UI v0.8 JSONL（v0.9／createSurface 被拒絕）。

## 相片 + 影片（節點相機）

相片（`jpg`）：

```bash
openclaw nodes camera list --node <idOrNameOrIp>
openclaw nodes camera snap --node <idOrNameOrIp>            # 預設：兩個面向（2 個 MEDIA 行）
openclaw nodes camera snap --node <idOrNameOrIp> --facing front
```

影片片段（`mp4`）：

```bash
openclaw nodes camera clip --node <idOrNameOrIp> --duration 10s
openclaw nodes camera clip --node <idOrNameOrIp> --duration 3000 --no-audio
```

備註：

- 節點必須為 `canvas.*` 和 `camera.*` 而 **前景**（背景呼叫傳回 `NODE_BACKGROUND_UNAVAILABLE`）。
- 片段時間受限制（目前 `<= 60s`）以避免超大 base64 有效負載。
- Android 會在可能時提示 `CAMERA`／`RECORD_AUDIO` 權限；拒絕權限因 `*_PERMISSION_REQUIRED` 而失敗。

## 螢幕記錄（節點）

支援的節點公開 `screen.record`（mp4）。範例：

```bash
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10
openclaw nodes screen record --node <idOrNameOrIp> --duration 10s --fps 10 --no-audio
```

備註：

- `screen.record` 可用性取決於節點平台。
- 螢幕記錄受限於 `<= 60s`。
- `--no-audio` 停用在支援平台上的麥克風擷取。
- 使用 `--screen <index>` 在多個螢幕可用時選擇顯示。

## 位置（節點）

當在設定中啟用位置時，節點公開 `location.get`。

CLI 幫手：

```bash
openclaw nodes location get --node <idOrNameOrIp>
openclaw nodes location get --node <idOrNameOrIp> --accuracy precise --max-age 15000 --location-timeout 10000
```

備註：

- 位置 **預設關閉**。
- 「始終」需要系統權限；背景擷取為盡力。
- 回應包括 lat／lon、精確度（公尺）和時間戳記。

## SMS（Android 節點）

當使用者授予 **SMS** 權限且設備支援電話術時，Android 節點可以公開 `sms.send`。

低層級叫用：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command sms.send --params '{"to":"+15555550123","message":"Hello from OpenClaw"}'
```

備註：

- 在函式可被廣告前，必須在 Android 設備上接受權限提示。
- 僅限 Wi-Fi 的沒有電話術的設備將不會廣告 `sms.send`。

## Android 設備 + 個人資料命令

當啟用對應功能時，Android 節點可以廣告額外命令家族。

可用家族：

- `device.status`、`device.info`、`device.permissions`、`device.health`
- `notifications.list`、`notifications.actions`
- `photos.latest`
- `contacts.search`、`contacts.add`
- `calendar.events`、`calendar.add`
- `motion.activity`、`motion.pedometer`

範例叫用：

```bash
openclaw nodes invoke --node <idOrNameOrIp> --command device.status --params '{}'
openclaw nodes invoke --node <idOrNameOrIp> --command notifications.list --params '{}'
openclaw nodes invoke --node <idOrNameOrIp> --command photos.latest --params '{"limit":1}'
```

備註：

- 動作命令由可用感應器的功能門控。

## 系統命令（節點主機／mac 節點）

macOS 節點公開 `system.run`、`system.notify` 和 `system.execApprovals.get/set`。
無頭節點主機公開 `system.run`、`system.which` 和 `system.execApprovals.get/set`。

範例：

```bash
openclaw nodes run --node <idOrNameOrIp> -- echo "Hello from mac node"
openclaw nodes notify --node <idOrNameOrIp> --title "Ping" --body "Gateway ready"
```

備註：

- `system.run` 在有效負載中傳回 stdout／stderr／結束代碼。
- `system.notify` 尊重 macOS app 上的通知權限狀態。
- 無法辨識的節點 `platform` / `deviceFamily` 中繼資料使用保守預設允許清單，排除 `system.run` 和 `system.which`。如果您有意需要這些命令用於未知平台，透過 `gateway.nodes.allowCommands` 明確新增它們。
- `system.run` 支援 `--cwd`、`--env KEY=VAL`、`--command-timeout` 和 `--needs-screen-recording`。
- 用於 shell 包裝器（`bash|sh|zsh ... -c/-lc`），要求範圍的 `--env` 值被縮減為明確允許清單（`TERM`、`LANG`、`LC_*`、`COLORTERM`、`NO_COLOR`、`FORCE_COLOR`）。
- 用於允許始終決定在允許清單模式中，已知發派包裝器（`env`、`nice`、`nohup`、`stdbuf`、`timeout`）保持內部可執行檔路徑而不是包裝器路徑。如果解套不安全，沒有允許清單條目自動保存。
- 在允許清單模式中的 Windows 節點主機上，shell 包裝器執行透過 `cmd.exe /c` 需要批准（允許清單條目單獨不自動允許包裝器表單）。
- `system.notify` 支援 `--priority <passive|active|timeSensitive>` 和 `--delivery <system|overlay|auto>`。
- 節點主機忽略 `PATH` 覆寫並移除危險啟動／shell 金鑰（`DYLD_*`、`LD_*`、`NODE_OPTIONS`、`PYTHON*`、`PERL*`、`RUBYOPT`、`SHELLOPTS`、`PS4`）。如果您需要額外 PATH 條目，設定節點主機服務環境（或在標準位置安裝工具）而不是透過 `--env` 傳遞 `PATH`。
- 在 macOS 節點模式上，`system.run` 被執行批准在 macOS app（設定 → 執行批准）門控。
  詢問／允許清單／完整行為相同為無頭節點主機；拒絕提示傳回 `SYSTEM_RUN_DENIED`。
- 在無頭節點主機上，`system.run` 被執行批准（`~/.openclaw/exec-approvals.json`）門控。

## 執行節點綁定

當有多個節點可用時，您可以綁定執行到特定節點。
這設定 `exec host=node` 的預設節點（並可在每個代理上覆寫）。

全局預設值：

```bash
openclaw config set tools.exec.node "node-id-or-name"
```

每個代理覆寫：

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

節點可能在 `node.list` / `node.describe` 中包括 `permissions` 對應，由權限名稱鍵入（例如 `screenRecording`、`accessibility`）及布林值（`true` = 授予）。

## 無頭節點主機（跨平台）

OpenClaw 可以執行 **無頭節點主機**（無 UI），連接到 Gateway WebSocket 並公開 `system.run` / `system.which`。這在 Linux／Windows 上有用或用於執行最小節點與伺服器一起。

啟動它：

```bash
openclaw node run --host <gateway-host> --port 18789
```

備註：

- 配對仍然需要（Gateway 將顯示設備配對提示）。
- 節點主機在 `~/.openclaw/node.json` 中儲存其節點 id、令牌、顯示名稱和 gateway 連接資訊。
- 執行批准透過 `~/.openclaw/exec-approvals.json` 本地強制執行（參閱 [執行批准](/zh-Hant/tools/exec-approvals)）。
- 在 macOS 上，無頭節點主機預設本地執行 `system.run`。設定 `OPENCLAW_NODE_EXEC_HOST=app` 以透過伴隨應用程式執行主機路由 `system.run`；新增 `OPENCLAW_NODE_EXEC_FALLBACK=0` 以需要應用程式主機並失敗關閉如果它不可用。
- 當 Gateway WS 使用 TLS 時新增 `--tls` / `--tls-fingerprint`。

## Mac 節點模式

- macOS menubar app 連接到 Gateway WS 伺服器作為節點（所以 `openclaw nodes …` 對此 Mac 有效）。
- 在遠端模式中，應用程式為 Gateway 連接埠開啟 SSH 通道並連接到 `localhost`。
