---
title: "Markdown formatting(Markdown 格式化)"
summary: "用於出站頻道的 Markdown 格式化管線"
read_when:
  - 您正在更改出站頻道的 Markdown 格式化或分塊方式
  - 您正在新增頻道格式化程式或樣式映射
  - 您正在除錯跨頻道的格式化衰退問題
---
# Markdown formatting（Markdown 格式化）

OpenClaw 透過在渲染頻道特定輸出之前，將其轉換為共享的中間表示 (Intermediate Representation, IR) 來格式化出站 Markdown。IR 保持源文字完整，同時攜帶樣式/連結範圍，以便分塊（chunking）和渲染在所有頻道中保持一致。

## 目標

- **一致性**：一次解析步驟，多個渲染器。
- **安全分塊**：在渲染之前拆分文字，確保行內格式（inline formatting）絕不會跨分塊斷裂。
- **頻道適配**：在不重新解析 Markdown 的情況下，將同一個 IR 映射到 Slack mrkdwn、Telegram HTML 和 Signal 樣式範圍。

## 管線 (Pipeline)

1. **解析 Markdown -> IR**
   - IR 是純文字加上樣式範圍（粗體/斜體/刪除線/程式碼/雷擊隱藏）和連結範圍。
   - 偏移量 (Offsets) 使用 UTF-16 代碼單元，以便 Signal 樣式範圍與其 API 對齊。
   - 僅當頻道選擇進行表格轉換時，才會解析表格。
2. **對 IR 進行分塊（格式優先）**
   - 分塊發生在渲染前的 IR 文字上。
   - 行內格式不會跨分塊拆分；範圍按分塊進行切片。
3. **按頻道渲染**
   - **Slack**：mrkdwn 權杖（粗體/斜體/刪除線/程式碼），連結格式為 `<url|label>`。
   - **Telegram**：HTML 標籤 (`<b>`, `<i>`, `<s>`, `<code>`, `<pre><code>`, `<a href>`)。
   - **Signal**：純文字 + `text-style` 範圍；當標籤不同時，連結變為 `label (url)`。

## IR 範例

輸入 Markdown：

```markdown
Hello **world** — see [docs](https://docs.openclaw.ai).
```

IR (示意圖)：

```json
{
  "text": "Hello world — see docs.",
  "styles": [
    { "start": 6, "end": 11, "style": "bold" }
  ],
  "links": [
    { "start": 19, "end": 23, "href": "https://docs.openclaw.ai" }
  ]
}
```

## 使用場景

- Slack、Telegram 和 Signal 出站適配器從 IR 進行渲染。
- 其他頻道（WhatsApp、iMessage、MS Teams、Discord）仍使用純文字或其自身的格式化規則，且在啟用時於分塊前套用 Markdown 表格轉換。

## 表格處理

並非所有聊天客戶端都一致支援 Markdown 表格。使用 `markdown.tables` 控制每個頻道（及帳戶）的轉換：

- `code`：將表格渲染為程式碼區塊（大多數頻道的預設值）。
- `bullets`：將每一行轉換為項目符號（Signal + WhatsApp 的預設值）。
- `off`：停用表格解析和轉換；原始表格文字直接通過。

設定鍵：

```yaml
channels:
  discord:
    markdown:
      tables: code
    accounts:
      work:
        markdown:
          tables: off
```

## 分塊規則 (Chunking rules)

- 分塊限制來自頻道適配器/設定，並套用於 IR 文字。
- 程式碼圍欄（Code fences）被保留為單個區塊，並帶有尾隨換行符，以便頻道正確渲染。
- 列表前綴和引用區塊前綴是 IR 文字的一部分，因此分塊不會從前綴中間拆分。
- 行內樣式（粗體/斜體/刪除線/行內程式碼/雷擊隱藏）絕不會跨分塊拆分；渲染器會在每個分塊內重新開啟樣式。

如果您需要更多關於跨頻道分塊行為的資訊，請參見 [Streaming + chunking（串流與分塊）](/concepts/streaming)。

## 連結策略

- **Slack**：`[label](url)` -> `<url|label>`；原始 URL 保持不變。解析期間停用自動連結以避免重複連結。
- **Telegram**：`[label](url)` -> `<a href="url">label</a>` (HTML 解析模式)。
- **Signal**：`[label](url)` -> `label (url)`，除非標籤與 URL 匹配。

## 雷擊隱藏 (Spoilers)

雷擊隱藏標記 (`||spoiler||`) 僅針對 Signal 進行解析，並映射到 SPOILER 樣式範圍。其他頻道將其視為純文字。

## 如何新增或更新頻道格式化程式

1. **一次解析**：使用共享的 `markdownToIR(...)` 輔助函數，並帶有適合頻道的選項（自動連結、標題樣式、引用區塊前綴）。
2. **渲染**：實作一個帶有 `renderMarkdownWithMarkers(...)` 和樣式標記映射（或 Signal 樣式範圍）的渲染器。
3. **分塊**：在渲染前呼叫 `chunkMarkdownIR(...)`；渲染每個分塊。
4. **接入適配器**：更新頻道的出站適配器以使用新的分塊器和渲染器。
5. **測試**：如果頻道使用分塊，請新增或更新格式測試和出站傳遞測試。

## 常見問題

- Slack 的角括號權杖（`<@U123>`, `<#C123>`, `<https://...>`）必須保留；請安全地轉義原始 HTML。
- Telegram HTML 要求轉義標籤以外的文字，以避免 markup 損壞。
- Signal 樣式範圍依賴於 UTF-16 偏移量；不要使用代碼點 (code point) 偏移量。
- 為程式碼圍欄保留尾隨換行符，以便結束標記落在自己的一行上。
