---
title: "gateway-lock(Gateway Lock)"
summary: "使用 WebSocket Listener Bind 的 Gateway 單例防護 (Singleton Guard)"
read_when:
  - 運行或除錯 Gateway 程序時
  - 調查單一實例強制執行 (Single-instance enforcement) 時
---

# Gateway Lock

最後更新: 2025-12-11

## 為何需要
- 確保同一主機上每個 Base Port 僅運行一個 Gateway Instance；額外的 Gateways 必須使用隔離的 Profiles 與唯一的 Ports。
- 在崩潰/SIGKILL 後存活而不留下陳舊的 Lock Files。
- 當 Control Port 已被佔用時，透過明確錯誤快速失敗 (Fail fast)。

## 機制
- Gateway 在啟動時立即使用獨佔的 TCP Listener 綁定 WebSocket Listener (預設 `ws://127.0.0.1:18789`)。
- 若綁定失敗並出現 `EADDRINUSE`，啟動會拋出 `GatewayLockError("another gateway instance is already listening on ws://127.0.0.1:<port>")`。
- OS 會在任何程序退出 (包含崩潰與 SIGKILL) 時自動釋放 Listener—無需個別的 Lock File 或清理步驟。
- 在關閉時，Gateway 關閉 WebSocket Server 與底層 HTTP Server 以迅速釋放 Port。

## 錯誤表面 (Error Surface)
- 若另一個程序持有該 Port，啟動會拋出 `GatewayLockError("another gateway instance is already listening on ws://127.0.0.1:<port>")`。
- 其他綁定失敗呈現為 `GatewayLockError("failed to bind gateway socket on ws://127.0.0.1:<port>: …")`。

## 操作註記
- 若 Port 被 *另一個* 程序佔用，錯誤是一樣的；釋放該 Port 或使用 `openclaw gateway --port <port>` 選擇另一個。
- macOS App 在衍生 Gateway 之前仍維護其自己的輕量級 PID Guard；Runtime Lock 則由 WebSocket Bind 強制執行。
