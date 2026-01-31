---
title: "Webchat(網頁聊天)"
summary: "Loopback WebChat 靜態主控與 Gateway WebSocket 在聊天介面上之使用"
read_when:
  - 偵錯或配置 WebChat 存取時
---
# WebChat (Gateway WebSocket UI)

狀態：macOS/iOS 的 SwiftUI 聊天介面會直接與 Gateway WebSocket 通訊。

## 這是什麼？
- 針對 Gateway 設計的原生聊天介面（無需內置瀏覽器，也無需本地靜態伺服器）。
- 使用與其他頻道相同的會話紀錄與路由規則。
- 具備確定性路由：回應始終會傳回至 WebChat。

## 快速啟動
1) 啟動 Gateway。
2) 開啟 WebChat 介面 (macOS/iOS App) 或控制介面的「聊天」分頁。
3) 確保已完成 Gateway 認證配置（預設為必填，即使在本地回環 loopback 也是如此）。

## 運作原理與行為
- 使用者介面連線到 Gateway WebSocket，並使用 `chat.history`、`chat.send` 與 `chat.inject` 方法。
- `chat.inject` 會直接在對話紀錄中追加助理筆記，並廣播至介面（不會觸發 Agent 執行）。
- 歷史紀錄始終從 Gateway 獲取（不會監視本地檔案變動）。
- 若 Gateway 無法連線，WebChat 將處於唯讀模式。

## 遠端使用
- 遠端模式會透過 SSH 或 Tailscale 建立 Gateway WebSocket 的隧道。
- 您**不需要**執行單獨的 WebChat 伺服器。

## 配置參考 (WebChat)
完整配置請參閱：[系統配置](/gateway/configuration)

頻道選項：
- 無需專用的 `webchat.*` 配置區塊。WebChat 使用 Gateway 端點及下方的認證設定。

相關全域選項：
- `gateway.port`, `gateway.bind`：WebSocket 主機與連接埠。
- `gateway.auth.mode`, `gateway.auth.token`, `gateway.auth.password`：WebSocket 認證。
- `gateway.remote.url`, `gateway.remote.token`, `gateway.remote.password`：遠端 Gateway 目標。
- `session.*`：會話存儲與主 Key 預設值。
