---
title: "peekaboo(Peekaboo Bridge)"
summary: "用於 macOS UI 自動化的 PeekabooBridge 整合"
read_when:
  - 在 OpenClaw.app 中託管 PeekabooBridge 時
  - 透過 Swift Package Manager 整合 Peekaboo 時
  - 變更 PeekabooBridge 協定/路徑時
---

# Peekaboo Bridge (macOS UI 自動化)

OpenClaw 可以託管 **PeekabooBridge**，作為一個本地的、具備權限感知的 UI 自動化 Broker。這讓 `peekaboo` CLI 能夠在重複使用 macOS 應用程式的 TCC 權限的同時驅動 UI 自動化。

## 這是什麼（與不是什麼）

- **Host**: OpenClaw.app 可以作為 PeekabooBridge 主機。
- **Client**: 使用 `peekaboo` CLI（無獨立的 `openclaw ui ...` 介面）。
- **UI**: 視覺覆蓋層保留在 Peekaboo.app 中；OpenClaw 是一個輕量級的 Broker 主機。

## 啟用 Bridge

在 macOS 應用程式中：
- Settings → **Enable Peekaboo Bridge**

啟用時，OpenClaw 會啟動一個本地 UNIX socket 伺服器。若停用，主機將停止，`peekaboo` 將回退至其他可用的主機。

## Client 探索順序

Peekaboo Clients 通常依照此順序嘗試主機：

1. Peekaboo.app (完整 UX)
2. Claude.app (若已安裝)
3. OpenClaw.app (輕量 Broker)

使用 `peekaboo bridge status --verbose` 查看哪個主機處於活動狀態以及正在使用哪個 socket 路徑。您可以透過以下方式覆寫：

```bash
export PEEKABOO_BRIDGE_SOCKET=/path/to/bridge.sock
```

## 安全性與權限

- Bridge 會驗證 **呼叫者的程式碼簽章**；強制執行 TeamID 允許清單（Peekaboo 主機 TeamID + OpenClaw 應用程式 TeamID）。
- 請求會在約 10 秒後逾時。
- 若缺少所需權限，Bridge 會回傳明確的錯誤訊息，而非啟動 System Settings。

## 快照行為 (自動化)

快照儲存在記憶體中，並在短時間視窗後自動過期。
若您需要更長的保留時間，請從 Client 重新擷取。

## 故障排除

- 若 `peekaboo` 報告 “bridge client is not authorized”，請確保 Client 已正確簽署，或僅在 **debug** 模式下使用 `PEEKABOO_ALLOW_UNSIGNED_SOCKET_CLIENTS=1` 運行主機。
- 若找不到主機，請開啟其中一個主機應用程式 (Peekaboo.app 或 OpenClaw.app) 並確認權限已授權。
