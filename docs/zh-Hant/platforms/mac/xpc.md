---
title: "xpc(IPC Architecture)"
summary: "OpenClaw 應用程式、Gateway 節點傳輸與 PeekabooBridge 的 macOS IPC 架構"
read_when:
  - 編輯 IPC 合約或選單列應用程式 IPC 時
---

# OpenClaw macOS IPC 架構

**目前模型:** 本地 Unix Socket 連接 **節點主機服務** 與 **macOS 應用程式**，用於執行核准 + `system.run`。存在一個 `openclaw-mac` 除錯 CLI 用於探索/連接檢查；Agent 動作仍透過 Gateway WebSocket 與 `node.invoke` 流動。UI 自動化使用 PeekabooBridge。

## 目標
- 單一 GUI 應用程式實例擁有所有面向 TCC 的工作（通知、螢幕錄製、麥克風、語音、AppleScript）。
- 自動化的小型介面：Gateway + 節點指令，加上用於 UI 自動化的 PeekabooBridge。
- 可預測的權限：始終為相同的已簽署 Bundle ID，由 launchd 啟動，因此 TCC 授權得以保留。

## 運作方式

### Gateway + 節點傳輸
- 應用程式運行 Gateway (Local 模式) 並作為節點連接至它。
- Agent 動作透過 `node.invoke` 執行（例如 `system.run`, `system.notify`, `canvas.*`）。

### 節點服務 + 應用程式 IPC
- 無顯示畫面的節點主機服務連接至 Gateway WebSocket。
- `system.run` 請求透過本地 Unix Socket 轉發至 macOS 應用程式。
- 應用程式在 UI 上下文中執行執行檔，若需要則提示，並回傳輸出。

圖示 (SCI):

```
Agent -> Gateway -> Node Service (WS)
                      |  IPC (UDS + token + HMAC + TTL)
                      v
                  Mac App (UI + TCC + system.run)
```

### PeekabooBridge (UI 自動化)
- UI 自動化使用名為 `bridge.sock` 的獨立 UNIX socket 與 PeekabooBridge JSON 協定。
- 主機優先順序 (用戶端側): Peekaboo.app → Claude.app → OpenClaw.app → 本地執行。
- 安全性: Bridge 主機需要允許的 TeamID；僅限 DEBUG 的同 UID 逃生梯由 `PEEKABOO_ALLOW_UNSIGNED_SOCKET_CLIENTS=1` 保護（Peekaboo 慣例）。
- 詳情請參閱: [PeekabooBridge usage](/platforms/mac/peekaboo)。

## 操作流程
- 重啟/重建: `SIGN_IDENTITY="Apple Development: <Developer Name> (<TEAMID>)" scripts/restart-mac.sh`
  - 殺死現有實例
  - Swift 建置 + 打包
  - 寫入/啟動/重啟 LaunchAgent
- 單一實例: 若另一個具有相同 Bundle ID 的實例正在運行，應用程式會提早退出。

## 強化筆記
- 對所有特權介面偏好要求 TeamID 相符。
- PeekabooBridge: `PEEKABOO_ALLOW_UNSIGNED_SOCKET_CLIENTS=1` (僅限 DEBUG) 可能允許同 UID 呼叫者進行本地開發。
- 所有通訊保持僅限本地；不暴露網路 Socket。
- TCC 提示僅源自 GUI 應用程式套件；在重建之間保持簽署的 Bundle ID 穩定。
- IPC 強化：Socket 模式 `0600`、Token、對等 UID 檢查、HMAC 挑戰/回應、短 TTL。
