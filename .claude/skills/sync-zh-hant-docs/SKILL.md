---
name: sync-zh-hant-docs
description: 同步 OpenClaw 官方更新並翻譯繁體中文文件。當需要將 zh-hant-docs 分支與最新官方版本同步、找出有變動的英文文件、或批次翻譯成繁體中文時使用此技能。觸發情境：(1) 同步最新版本 (2) 找出需要翻譯的文件 (3) 平行翻譯文件 (4) 檢查 docs.json 導航結構
---

# OpenClaw 繁體中文文件同步與翻譯

當 OpenClaw 官方發布新版本後，執行此流程來同步更新並翻譯繁體中文文件。

## 執行流程

### 階段一：確認版本差異

1. Fetch 最新版本
   ```bash
   git fetch origin --tags
   ```

2. 找出最新 tag 並比較差異
   ```bash
   git tag -l "v202*" | sort -V | tail -1
   git rev-list --left-right --count HEAD...<最新tag>
   ```

3. 顯示差異統計給使用者確認

### 階段二：同步最新版本

1. 詢問使用者是否執行 rebase
2. 執行 `git rebase <最新tag>`
3. 處理衝突（如有）：
   - `docs/docs.json`：保留繁體中文專屬 navigation 結構
   - `docs/index.md`：保留繁體中文首頁
4. 確保 docs.json 維持繁體中文專屬設定（只有 `groups`，不要 `languages`）

### 階段三：找出需要翻譯的文件

1. 找出分支基點：`git merge-base HEAD <最新tag>`
2. 列出英文版有變動的文件（排除 zh-Hant、zh-CN）
3. 分類：需更新（繁中版存在）vs 需新增（繁中版不存在）

### 階段四：平行翻譯

使用 Haiku sub-agents 平行翻譯，按目錄分批：
- cli/, platforms/, concepts/, gateway/
- channels/, tools/, providers/
- install/, start/, nodes/, reference/
- experiments/, automation/, help/
- web/, refactor/, plugins/, hooks/
- 根目錄散落檔案

每個 agent 的 prompt 參考 `references/translation-prompt.md`。

### 階段五：處理新增文件

找出需要新建的繁體中文文件並翻譯建立。

### 階段六：檢查 docs.json

確認 navigation 中的所有路徑都存在對應文件，如有新文件需更新 navigation。

### 階段七：完成

顯示變更統計，詢問使用者是否要 commit（不要自動 commit）。

## 翻譯規則

參考 `references/translation-rules.md`。

## 注意事項

- Haiku agent 可能有 token 限制，未完成需拆分繼續
- docs.json 只有繁體中文，沒有多語言結構
- 不要自動 commit，讓使用者檢查後再決定
