---
title: "Workspace Memory(工作區記憶體研究)"
summary: "研究注意事項：Clawd 工作區的離線記憶體系統（Markdown 來源真相 + 衍生索引）"
read_when:
  - 設計超越每日 Markdown 日誌的工作區記憶體（~/.openclaw/workspace）
  - 決定：獨立 CLI vs 深度 OpenClaw 整合
  - 新增離線召回 + 反思（retain/recall/reflect）
---

# Workspace Memory v2 (offline): research notes(工作區記憶體 v2（離線）：研究注意事項)

目標：Clawd 風格工作區（`agents.defaults.workspace`，預設 `~/.openclaw/workspace`），其中「記憶體」儲存為每天一個 Markdown 檔案（`memory/YYYY-MM-DD.md`）加上一小組穩定檔案（例如 `memory.md`、`SOUL.md`）。

本文件提議一個**離線優先**的記憶體架構，將 Markdown 保留為規範的、可審查的來源真相，但透過衍生索引新增**結構化召回**（搜尋、實體摘要、信心更新）。

## 為什麼要改變？

當前設定（每天一個檔案）非常適合：
- 「僅追加」日誌
- 人工編輯
- git 支援的持久性 + 可審計性
- 低摩擦捕獲（「只需寫下來」）

它的弱點在於：
- 高召回檢索（「我們對 X 做了什麼決定？」、「我們上次嘗試 Y 時發生了什麼？」）
- 以實體為中心的答案（「告訴我關於 Alice / The Castle / warelay」）而不重新閱讀許多檔案
- 意見/偏好穩定性（以及它何時改變的證據）
- 時間限制（「2025 年 11 月期間什麼是真的？」）和衝突解決

## 設計目標

- **離線**：無網路工作；可在筆電/Castle 上執行；無雲端依賴。
- **可解釋**：檢索的項目應該可歸因（檔案 + 位置）並可與推論分離。
- **低儀式**：每日日誌保持 Markdown，無繁重的 schema 工作。
- **增量**：v1 僅使用 FTS 即有用；語意/向量和圖是可選升級。
- **代理友善**：使「在 token 預算內召回」變得簡單（返回小事實束）。

## 北極星模型（Hindsight × Letta）

要混合的兩個部分：

1) **Letta/MemGPT 風格的控制迴圈**
- 保持一個小「核心」始終在上下文中（persona + 關鍵使用者事實）
- 其他一切都是上下文外的，透過工具檢索
- 記憶體寫入是明確的工具呼叫（append/replace/insert），持久化，然後下一輪重新注入

2) **Hindsight 風格的記憶體基板**
- 分離觀察到的 vs 相信的 vs 總結的
- 支援 retain/recall/reflect
- 具有信心的意見可以隨證據演變
- 實體感知檢索 + 時間查詢（即使沒有完整知識圖）

## 提議的架構（Markdown 來源真相 + 衍生索引）

### 規範儲存（git 友善）

保持 `~/.openclaw/workspace` 作為規範的人類可讀記憶體。

建議的工作區佈局：

```
~/.openclaw/workspace/
  memory.md                    # 小：持久事實 + 偏好（核心ish）
  memory/
    YYYY-MM-DD.md              # 每日日誌（追加；敘事）
  bank/                        # 「型別化」記憶體頁面（穩定、可審查）
    world.md                   # 關於世界的客觀事實
    experience.md              # 代理做了什麼（第一人稱）
    opinions.md                # 主觀偏好/判斷 + 信心 + 證據指標
    entities/
      Peter.md
      The-Castle.md
      warelay.md
      ...
```

注意事項：
- **每日日誌保持每日日誌**。無需將其轉換為 JSON。
- `bank/` 檔案是**策劃的**，由反思作業產生，仍然可以手工編輯。
- `memory.md` 保持「小 + 核心ish」：您希望 Clawd 每次會話看到的東西。

### 衍生儲存（機器召回）

在工作區下新增衍生索引（不一定 git 追蹤）：

```
~/.openclaw/workspace/.memory/index.sqlite
```

支援它：
- 用於事實 + 實體連結 + 意見 metadata 的 SQLite schema
- 用於詞彙召回的 SQLite **FTS5**（快速、小、離線）
- 用於語意召回的可選 embeddings 表（仍然離線）

索引始終**可從 Markdown 重建**。

## Retain / Recall / Reflect（操作迴圈）

### Retain：將每日日誌正規化為「事實」

Hindsight 在這裡重要的關鍵洞察：儲存**敘事、自包含的事實**，而不是微小片段。

`memory/YYYY-MM-DD.md` 的實用規則：
- 在一天結束時（或期間），新增一個 `## Retain` 區段，其中包含 2-5 個要點，這些要點是：
  - 敘事（跨輪上下文保留）
  - 自包含（獨立稍後有意義）
  - 標記有類型 + 實體提及

範例：

```
## Retain
- W @Peter：目前在 Marrakech（2025 年 11 月 27 日至 12 月 1 日）參加 Andy 的生日。
- B @warelay：我透過在 try/catch 中包裝 connection.update handlers 修復了 Baileys WS 崩潰（見 memory/2025-11-27.md）。
- O(c=0.95) @Peter：偏好在 WhatsApp 上簡潔回覆（<1500 字元）；長內容進入檔案。
```

最小解析：
- 類型前綴：`W`（世界）、`B`（經驗/傳記）、`O`（意見）、`S`（觀察/摘要；通常生成）
- 實體：`@Peter`、`@warelay` 等（slugs 對應到 `bank/entities/*.md`）
- 意見信心：`O(c=0.0..1.0)` 可選

如果您不希望作者考慮它：反思作業可以從日誌的其餘部分推斷這些要點，但擁有明確的 `## Retain` 區段是最簡單的「品質槓桿」。

### Recall：對衍生索引的查詢

召回應該支援：
- **詞彙**：「找到精確術語/名稱/指令」（FTS5）
- **實體**：「告訴我關於 X」（實體頁面 + 實體連結事實）
- **時間**：「11 月 27 日左右發生了什麼」/「自上週以來」
- **意見**：「Peter 更喜歡什麼？」（具有信心 + 證據）

返回格式應該是代理友善的並引用來源：
- `kind`（`world|experience|opinion|observation`）
- `timestamp`（來源日，或提取的時間範圍如果存在）
- `entities`（`["Peter","warelay"]`）
- `content`（敘事事實）
- `source`（`memory/2025-11-27.md#L12` 等）

### Reflect：產生穩定頁面 + 更新信念

反思是一個排程作業（每日或 heartbeat `ultrathink`），它：
- 從最近的事實更新 `bank/entities/*.md`（實體摘要）
- 基於強化/矛盾更新 `bank/opinions.md` 信心
- 可選地提議對 `memory.md` 的編輯（「核心ish」持久事實）

意見演變（簡單、可解釋）：
- 每個意見有：
  - 陳述
  - 信心 `c ∈ [0,1]`
  - last_updated
  - 證據連結（支援 + 矛盾事實 IDs）
- 當新事實到達時：
  - 透過實體重疊 + 相似性找到候選意見（首先 FTS，稍後 embeddings）
  - 透過小 deltas 更新信心；大跳躍需要強烈矛盾 + 重複證據

## CLI 整合：獨立 vs 深度整合

建議：**深度整合到 OpenClaw**，但保持可分離的核心程式庫。

### 為什麼整合到 OpenClaw？
- OpenClaw 已經知道：
  - 工作區路徑（`agents.defaults.workspace`）
  - 會話模型 + heartbeats
  - 日誌 + 疑難排解模式
- 您希望代理本身呼叫工具：
  - `openclaw memory recall "…" --k 25 --since 30d`
  - `openclaw memory reflect --since 7d`

### 為什麼仍然拆分程式庫？
- 保持記憶體邏輯可測試，無需 gateway/runtime
- 從其他上下文重複使用（本地腳本、未來桌面 app 等）

形狀：
記憶體工具旨在成為一個小型 CLI + 程式庫層，但這僅是探索性的。

## "S-Collide" / SuCo：何時使用它（研究）

如果「S-Collide」指的是 **SuCo（Subspace Collision）**：它是一種 ANN 檢索方法，透過在子空間中使用學習的/結構化的碰撞來定位強大的召回/延遲權衡（論文：arXiv 2411.14754，2024）。

對於 `~/.openclaw/workspace` 的務實看法：
- **不要開始**使用 SuCo。
- 從 SQLite FTS +（可選）簡單 embeddings 開始；您將立即獲得大部分 UX 勝利。
- 僅在以下情況下考慮 SuCo/HNSW/ScaNN 類解決方案：
  - 語料庫很大（數萬/數十萬個 chunks）
  - 暴力 embedding 搜尋變得太慢
  - 召回品質明顯受詞彙搜尋瓶頸

離線友善的替代方案（複雜度遞增）：
- SQLite FTS5 + metadata 過濾器（零 ML）
- Embeddings + 暴力（如果 chunk 計數低，效果驚人）
- HNSW 索引（常見、穩健；需要程式庫綁定）
- SuCo（研究級；如果有您可以嵌入的可靠實作，則有吸引力）

開放問題：
- 在您的機器（筆電 + 桌面）上，什麼是用於「個人助理記憶體」的**最佳**離線 embedding 模型？
  - 如果您已經有 Ollama：使用本地模型嵌入；否則在工具鏈中提供一個小的 embedding 模型。

## 最小有用試點

如果您想要一個最小的、仍然有用的版本：

- 在每日日誌中新增 `bank/` 實體頁面和一個 `## Retain` 區段。
- 使用 SQLite FTS 進行帶引用的召回（路徑 + 行號）。
- 僅在召回品質或規模需要時新增 embeddings。

## 參考

- Letta / MemGPT 概念：「核心記憶體區塊」+「檔案記憶體」+ 工具驅動的自編輯記憶體。
- Hindsight Technical Report：「retain / recall / reflect」、四網路記憶體、敘事事實提取、意見信心演變。
- SuCo：arXiv 2411.14754（2024）：「Subspace Collision」近似最近鄰檢索。
