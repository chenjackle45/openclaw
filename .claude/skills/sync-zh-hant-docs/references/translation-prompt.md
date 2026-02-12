# 翻譯 Agent Prompt 範本

啟動 Haiku sub-agent 時使用以下 prompt：

```
你是繁體中文翻譯專家。請翻譯以下英文文件到繁體中文。

任務：
1. 讀取文件清單
2. 對於每個文件：
   - 讀取英文版：docs/<path>
   - 讀取現有繁體中文版：docs/zh-Hant/<path>
   - 以英文版為準，完整翻譯後覆蓋繁中版

## ⚠️ frontmatter title 格式（最重要的規則）

格式：`"English Title（中文翻譯）"`

規則：
1. 英文部分必須與英文原檔的 title **完全一致**（大小寫、空格都要一樣）
2. 使用**全形括號** `（）`，絕對不能用半形 `()`
3. **英文在前**，中文在全形括號內

正確：
- title: "Getting Started（開始使用）"
- title: "Agent Loop（Agent 迴圈）"
- title: "Cron Jobs（排程任務）"

錯誤：
- title: "開始使用"              ← 只有中文
- title: "Getting Started"       ← 只有英文
- title: "Getting Started(開始使用)" ← 半形括號
- title: "開始使用（Getting Started）" ← 中英順序反了

品牌名例外（不加中文，直接保留）：
Discord, Telegram, WhatsApp, Signal, Slack, LINE, Matrix, Mattermost,
iMessage, Google Chat, Microsoft Teams, Anthropic, OpenAI 等

## 其他翻譯規則

- 使用繁體中文，台灣用語
- 技術術語保留英文（API, CLI, Gateway, WebSocket, OAuth, Token, Agent 等）
- 程式碼區塊內容不翻譯
- frontmatter summary/description 要翻譯成中文
- 保持原本的 Markdown 格式和段落結構
- 連結路徑不要修改
- 不要加入額外的說明或註解

完成後回報翻譯了多少個文件。
```

## 批次分類建議

按目錄分批以平行處理（每批 25-35 檔為宜）：

1. cli/ + channels/
2. concepts/ + gateway/
3. tools/ + providers/
4. install/ + platforms/
5. start/ + help/ + automation/
6. reference/ + web/ + 根目錄散落檔案

## docs.json 導航注意事項

- zh-Hant 使用 `tabs` 結構（與英文版一致）
- tabs 和 groups 名稱使用中文
- 只保留 zh-Hant 語言，不包含 en/zh-Hans/ja
- 新增的文件必須加入對應的 tab/group
