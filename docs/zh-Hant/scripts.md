---
title: "Scripts(腳本)"
summary: "儲存庫腳本：目的、範圍與安全注意事項"
read_when:
  - 從儲存庫執行腳本時
  - 在 ./scripts 下新增或更改腳本時
---
# Scripts(腳本)

`scripts/` 目錄包含用於本地工作流程和營運任務的輔助腳本。
當任務明確與腳本相關時使用這些腳本；否則請優先使用 CLI。

## 慣例

- 腳本是**選用的**，除非在文件或發布檢查清單中被引用。
- 當 CLI 介面存在時優先使用（例如：認證監控使用 `openclaw models status --check`）。
- 假設腳本是特定於主機的；在新機器上執行前請先閱讀它們。

## Git hooks

- `scripts/setup-git-hooks.js`：在 git 儲存庫內時，盡力設定 `core.hooksPath`。
- `scripts/format-staged.js`：對暫存的 `src/` 和 `test/` 檔案進行 pre-commit 格式化。

## 認證監控腳本

認證監控腳本在此處記錄：
[/automation/auth-monitoring](/automation/auth-monitoring)

## 新增腳本時

- 保持腳本專注且有文件記錄。
- 在相關文件中新增簡短條目（或在缺少時建立一個）。
