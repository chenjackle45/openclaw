---
title: "pairing(Gateway-owned pairing (Option B))"
summary: "適用於 iOS 與其他遠端 Nodes 的 Gateway-owned 配對機制 (Option B)"
read_when:
  - 實作無 macOS UI 的 Node 配對核准時
  - 為遠端 Nodes 新增核准 CLI 流程時
  - 擴充 Gateway Protocol 的 Node 管理功能時
---

# Gateway-owned Pairing (Option B)

在 Gateway-owned 配對中，**Gateway** 是關於允許哪些 Nodes 加入的 Source of Truth。UI (macOS app, 未來的 Clients) 僅是核准或拒絕待處理請求 (Pending Requests) 的前端。

**重要:** WS Nodes 在 `connect` 期間使用 **Device Pairing** (Role `node`)。`node.pair.*` 是分開的 Pairing Store 且 **不** 作為 WS Handshake 的閘道。僅顯式呼叫 `node.pair.*` 的 Clients 使用此流程。

## 概念

- **Pending request (待處理請求)**: Node 請求加入；需要核准。
- **Paired node (已配對 Node)**: 已核准的 Node，附帶發行的 Auth Token。
- **Transport (傳輸)**: Gateway WS Endpoint 轉發請求但不決定成員資格。(舊版 TCP Bridge 支援已停用/移除。)

## 配對如何運作

1. Node 連線至 Gateway WS 並請求配對。
2. Gateway 儲存 **Pending Request** 並發出 `node.pair.requested`。
3. 您核准或拒絕該請求 (CLI 或 UI)。
4. 核准後，Gateway 發行 **新 Token** (Tokens 在重新配對時會輪替)。
5. Node 使用 Token 重新連線，現在狀態為 “Paired”。

Pending Requests 在 **5 分鐘** 後自動過期。

## CLI Workflow (Headless Friendly)

```bash
openclaw nodes pending
openclaw nodes approve <requestId>
openclaw nodes reject <requestId>
openclaw nodes status
openclaw nodes rename --node <id|name|ip> --name "Living Room iPad"
```

`nodes status` 顯示 Paired/Connected Nodes 及其 Capabilities。

## API Surface (Gateway Protocol)

Events:
- `node.pair.requested` — 當新的 Pending Request 建立時發出。
- `node.pair.resolved` — 當 Request 被 Approve/Reject/Expire 時發出。

Methods:
- `node.pair.request` — 建立或重複使用 Pending Request。
- `node.pair.list` — 列出 Pending + Paired Nodes。
- `node.pair.approve` — 核准 Pending Request (發行 Token)。
- `node.pair.reject` — 拒絕 Pending Request。
- `node.pair.verify` — 驗證 `{ nodeId, token }`。

註記:
- `node.pair.request` 對每個 Node 是冪等的 (Idempotent)：重複呼叫回傳相同的 Pending Request。
- 核准 **總是** 產生全新的 Token；`node.pair.request` 從不回傳 Token。
- Requests 可包含 `silent: true` 作為自動核准流程的提示。

## 自動核准 (macOS App)

macOS App 可選用性地嘗試 **Silent Approval**，當：
- 請求被標記為 `silent`，且
- App 能使用相同的使用者驗證對 Gateway Host 的 SSH 連線。

若 Silent Approval 失敗，它會 Fallback 至正常的 “Approve/Reject” 提示。

## 儲存 (本地, 私有)

Pairing State 儲存於 Gateway State Directory 下 (預設 `~/.openclaw`):

- `~/.openclaw/nodes/paired.json`
- `~/.openclaw/nodes/pending.json`

若您覆蓋 `OPENCLAW_STATE_DIR`，`nodes/` 資料夾會隨之移動。

安全性註記:
- Tokens 是機密；將 `paired.json` 視為敏感資料。
- 輪替 Token 需要重新核准 (或刪除該 Node 項目)。

## 傳輸行為 (Transport Behavior)

- Transport 是 **無狀態的 (Stateless)**；它不儲存成員資格。
- 若 Gateway 離線或配對被停用，Nodes 無法配對。
- 若 Gateway 處於 Remote Mode，配對仍在 Remote Gateway 的 Store 進行。
