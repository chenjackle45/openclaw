---
summary: "選單列狀態邏輯與呈現給使用者的資訊"
read_when:
  - 調整 Mac 選單 UI 或狀態邏輯時
title: "選單列狀態邏輯"
---

# 選單列狀態邏輯

## 顯示內容
- 我們會在選單列圖示與選單的第一行狀態列中顯示目前的 Agent 工作狀態。
- 當有工作進行時，健康狀態會被隱藏；當所有工作階段閒置時，健康狀態會重新出現。
- 選單中的「Nodes」區塊僅列出 **裝置**（透過 `node.list` 配對的節點），不列出用戶端/存在 (presence) 項目。
- 當有供應商使用量快照可用時，「Usage」區塊會出現在 Context 下方。

## 狀態模型
- 工作階段 (Sessions): 事件包含 `runId` (每次執行) 與 payload 中的 `sessionKey`。
  「Main」工作階段的鍵值為 `main`；若不存在，我們會退回至最近更新的工作階段。
- 優先順序: Main 永遠優先。若 Main 處於活動狀態，會立即顯示其狀態。若 Main 閒置，則顯示最近活動的非 Main 工作階段。我們不會在活動中途反覆切換；僅在當前工作階段變為閒置或 Main 變為活動狀態時切換。
- 活動種類 (Activity kinds):
  - `job`: 高層級指令執行 (`state: started|streaming|done|error`)。
  - `tool`: `phase: start|result` 帶有 `toolName` 與 `meta/args`。

## IconState 列舉 (Swift)
- `idle`
- `workingMain(ActivityKind)`
- `workingOther(ActivityKind)`
- `overridden(ActivityKind)` (除錯覆蓋)

### ActivityKind → 圖形 (Glyph)
- `exec` → 💻
- `read` → 📄
- `write` → ✍️
- `edit` → 📝
- `attach` → 📎
- default → 🛠️

### 視覺對應
- `idle`: 正常生物圖示。
- `workingMain`: 帶有圖形徽章、全色調、腿部「工作中」動畫。
- `workingOther`: 帶有圖形徽章、淡化色調、無快速移動。
- `overridden`: 無視活動狀態，使用選定的圖形/色調。

## 狀態列文字 (選單)
- 當工作進行時: `<Session role> · <activity label>`
  - 範例: `Main · exec: pnpm test`, `Other · read: apps/macos/Sources/OpenClaw/AppState.swift`.
- 當閒置時: 退回顯示健康摘要。

## 事件攝取 (Event ingestion)
- 來源: 控制頻道 `agent` 事件 (`ControlChannel.handleAgentEvent`)。
- 解析欄位:
  - `stream: "job"` 帶有 `data.state` 用於開始/停止。
  - `stream: "tool"` 帶有 `data.phase`, `name`, 可選 `meta`/`args`。
- 標籤:
  - `exec`: `args.command` 的第一行。
  - `read`/`write`: 縮短的路徑。
  - `edit`: 路徑加上從 `meta`/diff 統計推斷的變更種類。
  - fallback: 工具名稱。

## 除錯覆蓋
- Settings ▸ Debug ▸ “Icon override” 選擇器:
  - `System (auto)` (預設)
  - `Working: main` (依工具種類)
  - `Working: other` (依工具種類)
  - `Idle`
- 透過 `@AppStorage("iconOverride")` 儲存；對應至 `IconState.overridden`。

## 測試檢查清單
- 觸發 Main 工作階段作業：驗證圖示立即切換且狀態列顯示 Main 標籤。
- 在 Main 閒置時觸發非 Main 工作階段作業：圖示/狀態顯示非 Main；保持穩定直到完成。
- 在其他作業活動時啟動 Main：圖示瞬間切換至 Main。
- 快速工具爆發：確保徽章不會閃爍 (工具結果有 TTL 寬限期)。
- 一旦所有工作階段閒置，健康列重新出現。
