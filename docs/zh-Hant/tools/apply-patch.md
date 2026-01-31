---
title: "Apply patch(套用補丁)"
summary: "使用 apply_patch 工具進行跨檔案的多處補丁修改"
read_when:
  - 需要對多個檔案進行結構化修改時
  - 想要紀錄或偵錯基於補丁的編輯操作時
---

# 套用補丁 (apply_patch tool)

使用結構化補丁格式套用檔案變更。當單次的 `edit` 呼叫顯得過於脆弱時，這項工具非常適合用於處理跨檔案或單一檔案多處 (Multi-hunk) 的編輯任務。

此工具接收單一的 `input` 字串，並包含一或多個檔案操作：

```
*** Begin Patch
*** Add File: path/to/file.txt
+line 1
+line 2
*** Update File: src/app.ts
@@
-舊行內容
+新行內容
*** Delete File: obsolete.txt
*** End Patch
```

## 參數說明
- `input`（必要）：包含 `*** Begin Patch` 與 `*** End Patch` 在內的完整補丁內容。

## 注意事項
- **路徑解析**：相對於工作區根目錄。
- **重新命名**：在 `*** Update File:` 區塊中使用 `*** Move to:` 標記。
- **實驗性功能**：預設為關閉。請透由 `tools.exec.applyPatch.enabled` 啟用。
- **模型限制**：目前僅支援 OpenAI 模型（包括 OpenAI Codex）。您可以透由 `tools.exec.applyPatch.allowModels` 限定特定模型使用。
- **配置位置**：僅存在於 `tools.exec` 區塊下。

## 呼叫範例
```json
{
  "tool": "apply_patch",
  "input": "*** Begin Patch\n*** Update File: src/index.ts\n@@\n-const foo = 1\n+const foo = 2\n*** End Patch"
}
```
