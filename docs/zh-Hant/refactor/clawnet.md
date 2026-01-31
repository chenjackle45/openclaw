---
title: "Clawnet refactor(Clawnet 重構)"
summary: "Clawnet 重構：統一網路協定、角色、認證、核准、身份"
read_when:
  - 為節點 + 營運者客戶端規劃統一網路協定
  - 重構跨裝置的核准、配對、TLS 和 presence
---
# Clawnet refactor (protocol + auth unification)(Clawnet 重構（協定 + 認證統一）)

## Hi
Hi Peter — 很好的方向；這解鎖了更簡單的 UX + 更強的安全性。

## 目的
單一、嚴謹的文件，涵蓋：
- 當前狀態：協定、流程、信任邊界。
- 痛點：核准、多跳路由、UI 重複。
- 提議的新狀態：一個協定、範圍角色、統一認證/配對、TLS 固定。
- 身份模型：穩定 IDs + 可愛 slugs。
- 遷移計畫、風險、開放問題。

## 目標（來自討論）
- 所有客戶端一個協定（mac app、CLI、iOS、Android、headless node）。
- 每個網路參與者都經過認證 + 配對。
- 角色清晰：nodes vs operators。
- 中央核准路由到使用者所在位置。
- 所有遠端流量的 TLS 加密 + 可選固定。
- 最小程式碼重複。
- 單一機器應該只出現一次（無 UI/node 重複條目）。

## 非目標（明確）
- 移除能力分離（仍需最小特權）。
- 在沒有範圍檢查的情況下公開完整 gateway 控制平面。
- 使認證依賴人類標籤（slugs 保持非安全性）。

---

# 當前狀態（現狀）

## 兩個協定

### 1) Gateway WebSocket（控制平面）
- 完整 API 介面：config、channels、models、sessions、agent runs、logs、nodes 等。
- 預設綁定：loopback。透過 SSH/Tailscale 遠端存取。
- 認證：透過 `connect` 的 token/password。
- 無 TLS 固定（依賴 loopback/tunnel）。
- 程式碼：
  - `src/gateway/server/ws-connection/message-handler.ts`
  - `src/gateway/client.ts`
  - `docs/gateway/protocol.md`

### 2) Bridge（節點傳輸）
- 窄允許清單介面、節點身份 + 配對。
- JSONL over TCP；可選 TLS + cert 指紋固定。
- TLS 在 discovery TXT 中公告指紋。
- 程式碼：
  - `src/infra/bridge/server/connection.ts`
  - `src/gateway/server-bridge.ts`
  - `src/node-host/bridge-client.ts`
  - `docs/gateway/bridge-protocol.md`

## 今日的控制平面客戶端
- CLI → Gateway WS 透過 `callGateway`（`src/gateway/call.ts`）。
- macOS app UI → Gateway WS（`GatewayConnection`）。
- Web Control UI → Gateway WS。
- ACP → Gateway WS。
- Browser control 使用自己的 HTTP 控制伺服器。

## 今日的節點
- macOS app 在 node 模式下連線到 Gateway bridge（`MacNodeBridgeSession`）。
- iOS/Android apps 連線到 Gateway bridge。
- 配對 + per-node token 儲存在 gateway 上。

## 當前核准流程（exec）
- Agent 透過 Gateway 使用 `system.run`。
- Gateway 透過 bridge 調用 node。
- Node runtime 決定核准。
- UI 提示由 mac app 顯示（當 node == mac app）。
- Node 返回 `invoke-res` 到 Gateway。
- 多跳，UI 綁定到 node host。

## 今日的 Presence + identity
- 來自 WS 客戶端的 Gateway presence 條目。
- 來自 bridge 的 Node presence 條目。
- mac app 可以為同一機器顯示兩個條目（UI + node）。
- Node 身份儲存在配對儲存中；UI 身份分離。

---

# 問題 / 痛點

- 要維護兩個協定堆疊（WS + Bridge）。
- 遠端節點上的核准：提示出現在 node host 上，而不是使用者所在位置。
- TLS 固定僅存在於 bridge；WS 依賴 SSH/Tailscale。
- 身份重複：同一機器顯示為多個實例。
- 角色模糊：UI + node + CLI 能力未清楚分離。

---

# 提議的新狀態（Clawnet）

## 一個協定，兩個角色
具有角色 + 範圍的單一 WS 協定。
- **角色：node**（能力主機）
- **角色：operator**（控制平面）
- operator 的可選**範圍**：
  - `operator.read`（狀態 + 查看）
  - `operator.write`（agent run、sends）
  - `operator.admin`（config、channels、models）

### 角色行為

**Node**
- 可以註冊能力（`caps`、`commands`、permissions）。
- 可以接收 `invoke` 指令（`system.run`、`camera.*`、`canvas.*`、`screen.record` 等）。
- 可以發送事件：`voice.transcript`、`agent.request`、`chat.subscribe`。
- 無法呼叫 config/models/channels/sessions/agent 控制平面 APIs。

**Operator**
- 完整控制平面 API，由範圍門控。
- 接收所有核准。
- 不直接執行 OS 動作；路由到節點。

### 關鍵規則
角色是每個連線的，而不是每個裝置。裝置可以分別開啟兩個角色。

---

# 統一認證 + 配對

## 客戶端身份
每個客戶端提供：
- `deviceId`（穩定，從裝置鍵衍生）。
- `displayName`（人類名稱）。
- `role` + `scope` + `caps` + `commands`。

## 配對流程（統一）
- 客戶端未經認證連線。
- Gateway 為該 `deviceId` 建立**配對請求**。
- Operator 接收提示；核准/拒絕。
- Gateway 發出綁定到以下的憑證：
  - 裝置公鑰
  - role(s)
  - scope(s)
  - capabilities/commands
- 客戶端持久化 token，重新連線已認證。

## 裝置綁定認證（避免 bearer token 重放）
首選：裝置鍵對。
- 裝置一次生成鍵對。
- `deviceId = fingerprint(publicKey)`。
- Gateway 發送 nonce；裝置簽名；gateway 驗證。
- Tokens 發行給公鑰（擁有證明），而不是字串。

替代方案：
- mTLS（客戶端 certs）：最強，更多操作複雜性。
- 短期 bearer tokens 僅作為臨時階段（早期輪換 + 撤銷）。

## 靜默核准（SSH 啟發式）
精確定義它以避免弱連結。首選一個：
- **僅本地**：當客戶端透過 loopback/Unix socket 連線時自動配對。
- **透過 SSH 挑戰**：gateway 發出 nonce；客戶端透過獲取它來證明 SSH。
- **物理 presence 視窗**：在 gateway host UI 上本地核准後，允許在短視窗內自動配對（例如 10 分鐘）。

始終記錄 + 記錄自動核准。

---

# TLS 無處不在（dev + prod）

## 重用現有 bridge TLS
使用當前 TLS runtime + 指紋固定：
- `src/infra/bridge/server/tls.ts`
- `src/node-host/bridge-client.ts` 中的指紋驗證邏輯

## 套用到 WS
- WS 伺服器支援具有相同 cert/key + 指紋的 TLS。
- WS 客戶端可以固定指紋（可選）。
- Discovery 為所有端點公告 TLS + 指紋。
  - Discovery 僅是定位器提示；從不是信任錨點。

## 為什麼
- 減少對 SSH/Tailscale 的機密性依賴。
- 預設使遠端行動連線安全。

---

# 核准重新設計（集中式）

## 當前
核准發生在 node host 上（mac app node runtime）。提示出現在 node 執行的位置。

## 提議
核准是 **gateway 託管的**，UI 傳遞給 operator 客戶端。

### 新流程
1) Gateway 接收 `system.run` 意圖（agent）。
2) Gateway 建立核准記錄：`approval.requested`。
3) Operator UI(s) 顯示提示。
4) 核准決策發送到 gateway：`approval.resolve`。
5) 如果核准，Gateway 調用 node 指令。
6) Node 執行，返回 `invoke-res`。

### 核准語意（強化）
- 廣播到所有 operators；僅活躍 UI 顯示模態（其他獲得 toast）。
- 第一個解決方案獲勝；gateway 拒絕後續解決為已解決。
- 預設逾時：在 N 秒後拒絕（例如 60 秒），記錄原因。
- 解決需要 `operator.approvals` 範圍。

## 好處
- 提示出現在使用者所在位置（mac/phone）。
- 遠端節點的一致核准。
- Node runtime 保持 headless；無 UI 依賴。

---

# 角色清晰範例

## iPhone app
- **Node 角色**用於：mic、camera、voice chat、location、push-to-talk。
- 可選 **operator.read** 用於狀態和聊天視圖。
- 僅在明確啟用時可選 **operator.write/admin**。

## macOS app
- 預設為 Operator 角色（控制 UI）。
- 當「Mac node」啟用時為 Node 角色（system.run、screen、camera）。
- 兩個連線的相同 deviceId → 合併 UI 條目。

## CLI
- 始終為 Operator 角色。
- 範圍由子指令導出：
  - `status`、`logs` → read
  - `agent`、`message` → write
  - `config`、`channels` → admin
  - approvals + pairing → `operator.approvals` / `operator.pairing`

---

# Identity + slugs

## 穩定 ID
認證所需；從不改變。
首選：
- 鍵對指紋（公鑰雜湊）。

## 可愛 slug（龍蝦主題）
僅人類標籤。
- 範例：`scarlet-claw`、`saltwave`、`mantis-pinch`。
- 儲存在 gateway 註冊表中，可編輯。
- 碰撞處理：`-2`、`-3`。

## UI 分組
跨角色的相同 `deviceId` → 單一「Instance」列：
- 徽章：`operator`、`node`。
- 顯示能力 + 最後看到。

---

# 遷移策略

## 第 0 階段：文件 + 對齊
- 發布此文件。
- 清點所有協定呼叫 + 核准流程。

## 第 1 階段：向 WS 新增 roles/scopes
- 使用 `role`、`scope`、`deviceId` 擴充 `connect` 參數。
- 為 node 角色新增允許清單門控。

## 第 2 階段：Bridge 相容性
- 保持 bridge 執行。
- 平行新增 WS node 支援。
- 在 config 旗標後門控功能。

## 第 3 階段：中央核准
- 在 WS 中新增核准請求 + 解決事件。
- 更新 mac app UI 以提示 + 回應。
- Node runtime 停止提示 UI。

## 第 4 階段：TLS 統一
- 使用 bridge TLS runtime 為 WS 新增 TLS 設定。
- 向客戶端新增固定。

## 第 5 階段：棄用 bridge
- 將 iOS/Android/mac node 遷移到 WS。
- 保持 bridge 作為回退；穩定後移除。

## 第 6 階段：裝置綁定認證
- 為所有非本地連線要求基於鍵的身份。
- 新增撤銷 + 輪換 UI。

---

# 安全注意事項

- 在 gateway 邊界強制執行角色/允許清單。
- 沒有客戶端在沒有 operator 範圍的情況下獲得「完整」API。
- *所有*連線都需要配對。
- TLS + 固定降低行動裝置的 MITM 風險。
- SSH 靜默核准是一種便利；仍然記錄 + 可撤銷。
- Discovery 從不是信任錨點。
- 能力聲明按平台/類型針對伺服器允許清單驗證。

# 串流 + 大型 payloads（節點媒體）
WS 控制平面適用於小訊息，但節點也執行：
- camera clips
- screen recordings
- audio streams

選項：
1) WS binary 幀 + chunking + backpressure 規則。
2) 單獨的串流端點（仍然 TLS + auth）。
3) 為媒體密集型指令保持 bridge 更長時間，最後遷移。

在實作前選擇一個以避免偏差。

# 能力 + 指令策略
- Node 報告的 caps/commands 被視為**聲明**。
- Gateway 按平台/類型強制執行允許清單。
- 任何新指令都需要 operator 核准或明確允許清單變更。
- 使用時間戳審計變更。

# Audit + 速率限制
- 記錄：配對請求、核准/拒絕、token 發行/輪換/撤銷。
- 速率限制配對垃圾郵件和核准提示。

# 協定衛生
- 明確協定版本 + 錯誤碼。
- 重新連線規則 + heartbeat 策略。
- Presence TTL 和 last-seen 語意。

---

# 開放問題

1) 執行兩個角色的單一裝置：token 模型
   - 建議每個角色單獨 tokens（node vs operator）。
   - 相同 deviceId；不同範圍；更清楚的撤銷。

2) Operator 範圍粒度
   - read/write/admin + approvals + pairing（最小可行）。
   - 稍後考慮每個功能範圍。

3) Token 輪換 + 撤銷 UX
   - 角色變更時自動輪換。
   - UI 按 deviceId + 角色撤銷。

4) Discovery
   - 擴充當前 Bonjour TXT 以包含 WS TLS 指紋 + 角色提示。
   - 僅作為定位器提示。

5) 跨網路核准
   - 廣播到所有 operator 客戶端；活躍 UI 顯示模態。
   - 第一個回應獲勝；gateway 強制執行原子性。

---

# 摘要（TL;DR）

- 今日：WS 控制平面 + Bridge node 傳輸。
- 痛點：核准 + 重複 + 兩個堆疊。
- 提議：具有明確角色 + 範圍、統一配對 + TLS 固定、gateway 託管核准、穩定裝置 IDs + 可愛 slugs 的一個 WS 協定。
- 結果：更簡單的 UX、更強的安全性、更少的重複、更好的行動路由。
