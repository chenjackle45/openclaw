---
summary: "Apply multi-file patches with the apply_patch tool"
read_when:
  - You need structured file edits across multiple files
  - You want to document or debug patch-based edits
title: "apply_patch Tool"
---

# apply_patch tool

使用結構化 patch 格式套用檔案變更。這對多檔案或多 hunk 編輯很理想，其中單一 `edit` 呼叫會很脆弱。

工具接受單一 `input` 字串，其包裝一或多個檔案操作：

```
*** Begin Patch
*** Add File: path/to/file.txt
+line 1
+line 2
*** Update File: src/app.ts
@@
-old line
+new line
*** Delete File: obsolete.txt
*** End Patch
```

## 參數

- `input`（必填）：完整 patch 內容，包括 `*** Begin Patch` 和 `*** End Patch`。

## 注意

- 路徑相對於工作區根目錄解析。
- 在 `*** Update File:` hunk 內使用 `*** Move to:` 來重新命名檔案。
- `*** End of File` 在需要時標記只限 EOF 的插入。
- 實驗性且預設停用。使用 `tools.exec.applyPatch.enabled` 啟用。
- 僅限 OpenAI（包括 OpenAI Codex）。選用地透過 `tools.exec.applyPatch.allowModels` 按模型限制。
- Config 只在 `tools.exec` 下。

## 範例

```json
{
  "tool": "apply_patch",
  "input": "*** Begin Patch\n*** Update File: src/index.ts\n@@\n-const foo = 1\n+const foo = 2\n*** End Patch"
}
```
