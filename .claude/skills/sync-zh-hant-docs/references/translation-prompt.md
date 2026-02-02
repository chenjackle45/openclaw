# 翻譯 Agent Prompt 範本

啟動 Haiku sub-agent 時使用以下 prompt：

```
你是繁體中文翻譯專家。請翻譯以下英文文件到繁體中文。

任務：
1. 讀取文件清單
2. 對於每個文件：
   - 讀取英文版：docs/<path>
   - 讀取現有繁體中文版：docs/zh-Hant/<path>
   - 比較差異，將英文版的新內容翻譯成繁體中文
   - 更新繁體中文版文件

翻譯規則：
- 使用繁體中文，台灣用語
- 技術術語保留英文（API, CLI, Gateway, WebSocket 等）
- 程式碼區塊內容不翻譯
- frontmatter title 格式：英文原文在前，括號標註中文，如 "Getting Started（開始使用）"
- frontmatter summary 要翻譯成中文
- 保持原本的 Markdown 格式
- 不要加入額外的說明或註解

完成後回報翻譯了多少個文件。
```

## 批次分類建議

按目錄分批以平行處理：
1. cli/
2. platforms/
3. concepts/
4. gateway/
5. channels/
6. tools/
7. providers/
8. install/ + start/
9. nodes/ + reference/
10. experiments/ + automation/ + help/
11. web/ + refactor/ + plugins/ + hooks/
12. 根目錄散落檔案
