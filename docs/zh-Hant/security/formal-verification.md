---
title: "Formal Verification(形式化驗證)"
summary: "OpenClaw 最高風險路徑的機器檢查安全模型。"
permalink: /security/formal-verification/
---

# Formal Verification (Security Models)(形式化驗證（安全模型）)

此頁面追蹤 OpenClaw 的**形式化安全模型**（目前為 TLA+/TLC；需要時會增加更多）。

> 注意：某些較舊的連結可能引用以前的專案名稱。

**目標（北極星）：**提供 OpenClaw 強制執行其
預期安全策略（授權、會話隔離、工具門控和
錯誤設定安全性）的機器檢查論證，基於明確假設。

**這是什麼（今日）：**一個可執行的、攻擊者驅動的**安全回歸套件**：
- 每個聲明都有一個可執行的模型檢查，覆蓋有限狀態空間。
- 許多聲明都有一個配對的**負面模型**，為實際 bug 類別產生反例追蹤。

**這不是什麼（尚未）：**證明「OpenClaw 在所有方面都是安全的」或完整 TypeScript 實作正確的證明。

## 模型位置

模型在單獨的儲存庫中維護：[vignesh07/openclaw-formal-models](https://github.com/vignesh07/openclaw-formal-models)。

## 重要注意事項

- 這些是**模型**，而不是完整的 TypeScript 實作。模型和程式碼之間可能存在偏差。
- 結果受 TLC 探索的狀態空間限制；「綠色」並不意味著超出模型假設和邊界的安全性。
- 某些聲明依賴明確的環境假設（例如，正確部署、正確設定輸入）。

## 重現結果

今日，透過本地克隆模型儲存庫並執行 TLC 來重現結果（見下文）。未來的迭代可以提供：
- CI 執行的模型，具有公共工件（反例追蹤、執行日誌）
- 用於小型、有界檢查的託管「執行此模型」工作流程

開始使用：

```bash
git clone https://github.com/vignesh07/openclaw-formal-models
cd openclaw-formal-models

# 需要 Java 11+（TLC 在 JVM 上執行）。
# 儲存庫提供固定的 `tla2tools.jar`（TLA+ 工具）並提供 `bin/tlc` + Make 目標。

make <target>
```

### Gateway 曝露和開放 gateway 錯誤設定

**聲明：**超出 loopback 的綁定而無認證可能導致遠端破壞/增加曝露；token/password 阻止未經認證的攻擊者（根據模型假設）。

- 綠色執行：
  - `make gateway-exposure-v2`
  - `make gateway-exposure-v2-protected`
- 紅色（預期）：
  - `make gateway-exposure-v2-negative`

另請參閱：模型儲存庫中的 `docs/gateway-exposure-matrix.md`。

### Nodes.run 流水線（最高風險能力）

**聲明：**`nodes.run` 需要 (a) 節點指令允許清單加上宣告的指令，以及 (b) 設定時的即時核准；核准被 token 化以防止重放（在模型中）。

- 綠色執行：
  - `make nodes-pipeline`
  - `make approvals-token`
- 紅色（預期）：
  - `make nodes-pipeline-negative`
  - `make approvals-token-negative`

### 配對儲存（DM 門控）

**聲明：**配對請求遵守 TTL 和待處理請求上限。

- 綠色執行：
  - `make pairing`
  - `make pairing-cap`
- 紅色（預期）：
  - `make pairing-negative`
  - `make pairing-cap-negative`

### 入口門控（提及 + 控制指令繞過）

**聲明：**在需要提及的群組上下文中，未經授權的「控制指令」無法繞過提及門控。

- 綠色：
  - `make ingress-gating`
- 紅色（預期）：
  - `make ingress-gating-negative`

### 路由/會話鍵隔離

**聲明：**來自不同對等方的 DM 不會折疊到相同會話，除非明確連結/設定。

- 綠色：
  - `make routing-isolation`
- 紅色（預期）：
  - `make routing-isolation-negative`


## v1++：額外的有界模型（並發、重試、追蹤正確性）

這些是後續模型，圍繞真實世界失敗模式（非原子更新、重試和訊息扇出）收緊保真度。

### 配對儲存並發 / 冪等性

**聲明：**配對儲存應該即使在交錯下也強制執行 `MaxPending` 和冪等性（即，「檢查後寫入」必須是原子的/鎖定的；刷新不應建立重複項）。

它的意思：
- 在並發請求下，您不能超過頻道的 `MaxPending`。
- 對相同 `(channel, sender)` 的重複請求/刷新不應建立重複的即時待處理列。

- 綠色執行：
  - `make pairing-race`（原子/鎖定上限檢查）
  - `make pairing-idempotency`
  - `make pairing-refresh`
  - `make pairing-refresh-race`
- 紅色（預期）：
  - `make pairing-race-negative`（非原子 begin/commit 上限競爭）
  - `make pairing-idempotency-negative`
  - `make pairing-refresh-negative`
  - `make pairing-refresh-race-negative`

### 入口追蹤關聯 / 冪等性

**聲明：**攝取應該在扇出中保持追蹤關聯，並在供應商重試下具有冪等性。

它的意思：
- 當一個外部事件變成多個內部訊息時，每個部分都保持相同的追蹤/事件身份。
- 重試不會導致雙重處理。
- 如果缺少供應商事件 IDs，去重回退到安全鍵（例如，追蹤 ID）以避免丟棄不同事件。

- 綠色：
  - `make ingress-trace`
  - `make ingress-trace2`
  - `make ingress-idempotency`
  - `make ingress-dedupe-fallback`
- 紅色（預期）：
  - `make ingress-trace-negative`
  - `make ingress-trace2-negative`
  - `make ingress-idempotency-negative`
  - `make ingress-dedupe-fallback-negative`

### 路由 dmScope 優先順序 + identityLinks

**聲明：**路由必須預設保持 DM 會話隔離，僅在明確設定時折疊會話（頻道優先順序 + identity links）。

它的意思：
- 頻道特定 dmScope 覆蓋必須優先於全域預設。
- identityLinks 應僅在明確連結的群組內折疊，而非跨不相關的對等方。

- 綠色：
  - `make routing-precedence`
  - `make routing-identitylinks`
- 紅色（預期）：
  - `make routing-precedence-negative`
  - `make routing-identitylinks-negative`
