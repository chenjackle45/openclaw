---
title: "Presence(狀態)"
summary: "OpenClaw 在線狀態條目的生成、合併與顯示方式"
read_when:
  - 除錯「執行實體 (Instances)」標籤頁
  - 調查重複或陳舊的實體行
  - 更改 Gateway WebSocket 連接或系統事件信標 (system-event beacons)
---
# Presence（在線狀態）

OpenClaw 的「在線狀態 (presence)」是一個輕量化、盡力而為的視圖，顯示：
- **Gateway** 本身，以及
- **連接到 Gateway 的客戶端** (Mac 應用程式、WebChat、CLI 等)

在線狀態主要用於渲染 macOS 應用程式的 **Instances** 標籤頁，並提供操作員快速的可見性。

## 在線狀態欄位（顯示內容）

在線狀態條目是具有以下欄位的結構化對象：

- `instanceId`（選填但強烈建議）：穩定的客戶端身份（通常為 `connect.client.instanceId`）
- `host`：易於理解的主機名稱
- `ip`：盡力而為取得的 IP 位址
- `version`：客戶端版本字串
- `deviceFamily` / `modelIdentifier`：硬體提示
- `mode`：`ui`, `webchat`, `cli`, `backend`, `probe`, `test`, `node`, ...
- `lastInputSeconds`：「距上次使用者輸入的秒數」（若已知）
- `reason`：`self`, `connect`, `node-connected`, `periodic`, ...
- `ts`：上次更新時間戳記（自 Epoch 起算的毫秒數）

## 生產者（在線狀態來源）

在線狀態條目由多個來源產生並進行**合併**。

### 1) Gateway 本身條目

Gateway 始終在啟動時植入一個「self」條目，以便 UI 甚至在任何客戶端連接之前就能顯示 Gateway 主機。

### 2) WebSocket 連接

每個 WS 客戶端都從 `connect` 請求開始。握手成功後，Gateway 會為該連接新增或更新 (upsert) 一個在線狀態條目。

#### 為什麼一次性的 CLI 命令不會顯示

CLI 通常是為了執行短暫的一次性命令而連接。為了避免 Instances 列表過於雜亂，`client.mode === "cli"` **不會**被轉換為在線狀態條目。

### 3) `system-event` 信標 (Beacons)

客戶端可以透過 `system-event` 方法發送更豐富的定期信標。Mac 應用程式使用此方法來報告主機名稱、IP 和 `lastInputSeconds`。

### 4) 節點連接 (role: node)

當節點以 `role: node` 透過 Gateway WebSocket 連接時，Gateway 會為該節點新增或更新在線狀態條目（流程與其他 WS 客戶端相同）。

## 合併與去重規則（為什麼 `instanceId` 很重要）

在線狀態條目儲存在單一的記憶體映射 (map) 中：

- 條目以 **在線狀態鍵 (presence key)** 為鍵。
- 最好的鍵是從重新啟動中留存下來的穩定 `instanceId`（來自 `connect.client.instanceId`）。
- 鍵不區分大小寫。

如果客戶端在重新連線時沒有帶上穩定的 `instanceId`，它可能會顯示為**重複的**一行。

## TTL 與容量限制

在線狀態刻意設計為臨時性的：

- **TTL**：超過 5 分鐘未更新的條目會被修剪。
- **最大容量**：200 個條目（最舊的會先被丟棄）。

這能保持列表的新鮮度，並避免記憶體無限制增長。

## 遠端/隧道注意事項（環回 IP）

當客戶端透過 SSH 隧道 / 本地連接埠轉發連接時，Gateway 可能會將遠端位址判定為 `127.0.0.1`。為了避免覆蓋客戶端報告的有效 IP，環回遠端位址會被忽略。

## 消費者

### macOS Instances 標籤頁

macOS 應用程式會渲染 `system-presence` 的輸出，並根據上次更新的時間長短套用一個小的狀態指示燈（Active 動態 / Idle 閒置 / Stale 陳舊）。

## 除錯提示

- 若要查看原始列表，請針對 Gateway 呼叫 `system-presence`。
- 如果您看到重複項：
  - 確認客戶端在握手時發送了穩定的 `client.instanceId`。
  - 確認定期信標使用的是同一個 `instanceId`。
  - 檢查從連接衍生出的條目是否缺少 `instanceId`（出現重複是預期的）。
