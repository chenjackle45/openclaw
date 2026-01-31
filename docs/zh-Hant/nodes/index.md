---
title: "Index(節點總覽)"
summary: "節點：配對、功能能力、權限管理，以及用於畫布/相機/螢幕/系統的 CLI 輔助工具"
read_when:
  - 正在將 iOS/Android 節點配對至 Gateway 時
  - 使用節點畫布或相機為 Agent 提供上下文時
  - 新增節點指令或 CLI 輔助工具時
---

# 節點 (Nodes)

**節點 (Node)** 是一個伴隨裝置（macOS/iOS/Android/無頭伺服器），它以 `role: "node"` 的身份連線到 Gateway 的 **WebSocket**（與操作介面使用相同的連接埠），並透過 `node.invoke` 暴露指令集（例如 `canvas.*`、`camera.*`、`system.*`）。詳細協定請參閱 [Gateway 協定](/gateway/protocol)。

macOS 也可以在**節點模式 (Node mode)** 下執行：選單列應用程式連線到 Gateway 的 WS 伺服器，並將其本地的畫布/相機指令作為節點暴露（因此對該 Mac 執行 `openclaw nodes …` 是有效的）。

> [!NOTE]
> - 節點是**外圍設備**，而非 Gateway。它們不執行 Gateway 服務。
> - Telegram/WhatsApp 等訊息實體會傳送到 **Gateway**，而非節點。

## 配對與狀態

**WS 節點使用裝置配對機制。** 節點在連線 (`connect`) 時會提供裝置身份；Gateway 會為 `role: node` 建立裝置配對請求。請透過裝置 CLI 或網頁 UI 進行核准。

常用 CLI 指令：
```bash
openclaw devices list               # 列出所有配對請求與裝置
openclaw devices approve <requestId> # 核准配對請求
openclaw nodes status               # 查看當前連線的節點狀態
openclaw nodes describe --node <ID>  # 詳述特定節點的功能能力
```

## 遠端節點主機 (system.run)

當您的 Gateway 執行在一台機器上，而您希望指令在另一台機器上執行時，請使用**節點主機 (Node host)**。模型仍然與 **Gateway** 對話；當選擇 `host=node` 時，Gateway 會將 `exec` 呼叫轉發給**節點主機**。

### 角色分工
- **Gateway 主機**：接收訊息、執行模型、路由工具呼叫。
- **節點主機**：在節點機器上執行指令（如 `system.run`）。
- **核准機制**：由節點主機透過 `~/.openclaw/exec-approvals.json` 強制執行。

### 啟動節點主機 (前台執行)
在節點機器上：
```bash
openclaw node run --host <gateway主機> --port 18789 --display-name "編譯節點"
```

### 配對與命名
在 Gateway 主機上：
```bash
openclaw nodes pending # 查看待處理的節點請求
openclaw nodes approve <requestId> # 核准請求
```

### 設定指令允許清單
執行核准是以**每個節點主機**為單位的。從 Gateway 端新增允許清單條目：
```bash
openclaw approvals allowlist add --node <ID> "/usr/bin/uname"
```

詳見：[執行工具 (Exec Tool)](/tools/exec)、[執行核准](/tools/exec-approvals)。

## 常用指令呼叫

### 畫布快照 (Screenshots)
若節點正在顯示畫布 (WebView)，可以使用 `canvas.snapshot` 獲取快照。

CLI 輔助工具（會寫入暫存檔並印出 `MEDIA:<路徑>`）：
```bash
openclaw nodes canvas snapshot --node <ID> --format png
```

### 畫布控制
```bash
openclaw nodes canvas present --node <ID> --target https://example.com # 顯示目標網址
openclaw nodes canvas navigate https://example.com --node <ID>      # 導覽至網址
openclaw nodes canvas eval --node <ID> --js "document.title"        # 執行 JS
```

### A2UI (畫布)
```bash
openclaw nodes canvas a2ui push --node <ID> --text "你好"
openclaw nodes canvas a2ui reset --node <ID>
```

## 相機拍照與影片 (Camera)

拍照 (`jpg`)：
```bash
openclaw nodes camera snap --node <ID> --facing front # 使用前鏡頭拍照
```

錄製短片 (`mp4`)：
```bash
openclaw nodes camera clip --node <ID> --duration 10s # 錄製 10 秒影片
```

> [!IMPORTANT]
> - 節點應用程式必須處於**前台運行狀態**才能使用 `canvas.*` 與 `camera.*` 功能。
> - 影片長度目前限制在 60 秒以內。

## 螢幕錄製 (Screen)
節點暴露了 `screen.record` (mp4) 功能。
```bash
openclaw nodes screen record --node <ID> --duration 10s --fps 10
```

## 位置資訊 (Location)
若在設定中啟用了位置功能，節點可暴露 `location.get`。
```bash
openclaw nodes location get --node <ID>
```
注意：位置功能預設為**關閉**。回應包含經緯度、精確度（公尺）及時間戳記。

## 系統指令 (System)
macOS 節點或無頭節點主機可暴露系統相關指令。
```bash
openclaw nodes run --node <ID> -- echo "來自節點的問候"
openclaw nodes notify --node <ID> --title "通知" --body "Gateway 已就緒"
```

## 無頭節點主機 (Headless node host)
OpenClaw 可以執行一個**無頭節點主機**（無 UI 介面），連線至 Gateway 通訊埠並暴露系統執行功能。對於 Linux/Windows 或在伺服器旁執行輕量化節點非常有用。

啟動方式：
```bash
openclaw node run --host <gateway主機> --port 18789
```
注意：執行核准是在本地透過 `~/.openclaw/exec-approvals.json` 強制執行的。
