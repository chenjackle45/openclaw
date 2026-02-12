---
summary: "節點：配對、功能、權限和用於 Canvas/攝影機/螢幕/系統的 CLI 輔助程式"
read_when:
  - 配對 iOS/Android 節點到 Gateway
  - 使用節點 Canvas/攝影機進行 Agent 內容
  - 新增新節點命令或 CLI 輔助程式
title: "Nodes（節點）"
---

# 節點

**節點**是連接到 Gateway **WebSocket**（與操作員相同的連接埠）的伴侶裝置（macOS/iOS/Android/無頭），具有 `role: "node"`，並透過 `node.invoke` 公開命令介面（例如 `canvas.*`、`camera.*`、`system.*`）。協議詳情：[Gateway 協議](/zh-Hant/gateway/protocol)。

舊版傳輸：[橋接協議](/zh-Hant/gateway/bridge-protocol)（TCP JSONL；已棄用/已移除針對目前節點）。

macOS 也可以在**節點模式**中執行：菜單欄應用程式連接到 Gateway 的 WS 伺服器並將其本機 Canvas/攝影機命令公開為節點（因此 `openclaw nodes …` 對此 Mac 有效）。

注意事項：

- 節點是**周邊裝置**，不是 Gateway。它們不執行 Gateway 服務。
- Telegram/WhatsApp/等。訊息登陸在 **Gateway** 上，而非節點。
- 疑難排解執行手冊：[/nodes/troubleshooting](/zh-Hant/nodes/troubleshooting)

## 配對 + 狀態

**WS 節點使用裝置配對。** 節點在 `connect` 時顯示裝置身分；Gateway 為 `role: node` 建立裝置配對請求。透過裝置 CLI（或 UI）核准。

快速 CLI：

```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw devices reject <requestId>
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
```

注意事項：

- 當節點的裝置配對角色包括 `node` 時，`nodes status` 將節點標記為**配對**。
- `node.pair.*`（CLI：`openclaw nodes pending/approve/reject`）是單獨的 Gateway 所有節點配對存儲；它**不會**門控 WS `connect` 握手。

## 遠端節點主機（system.run）

當 Gateway 在一台機器上執行而你想在另一台機器上執行命令時，使用**節點主機**。模型仍然與 **Gateway** 交談；當選擇 `host=node` 時，Gateway 將 `exec` 呼叫轉發到**節點主機**。

### 什麼在哪裡執行

- **Gateway 主機**：接收訊息、執行模型、路由工具呼叫。
- **節點主機**：在節點機器上執行 `system.run`/`system.which`。
- **核准**：透過 `~/.openclaw/exec-approvals.json` 在節點主機上執行。

### 啟動節點主機（前景）

在節點機器上：

```bash
openclaw node run --host <gateway-host> --port 18789 --display-name "Build Node"
```

### 透過 SSH 隧道遠端 Gateway（迴圈繫結）

如果 Gateway 繫結到迴圈（`gateway.bind=loopback`，本機模式預設），遠端節點主機無法直接連接。建立 SSH 隧道並指向節點主機至隧道的本機端。

範例（節點主機 -> Gateway 主機）：

```bash
# Terminal A（保持執行）：轉發本機 18790 -> Gateway 127.0.0.1:18789
ssh -N -L 18790:127.0.0.1:18789 user@gateway-host

# Terminal B：匯出 Gateway 標記並透過隧道連接
export OPENCLAW_GATEWAY_TOKEN="<gateway-token>"
openclaw node run --host 127.0.0.1 --port 18790 --display-name "Build Node"
```

注意事項：

- 標記是 Gateway 配置中的 `gateway.auth.token`（Gateway 主機上的 `~/.openclaw/openclaw.json`）。
- `openclaw node run` 讀取 `OPENCLAW_GATEWAY_TOKEN` 進行驗證。

### 啟動節點主機（服務）

```bash
openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"
openclaw node restart
```

### 配對和命名

在 Gateway 主機上：

```bash
openclaw nodes pending
openclaw nodes approve <requestId>
```

詳見 [Nodes CLI](/zh-Hant/cli/nodes)。
