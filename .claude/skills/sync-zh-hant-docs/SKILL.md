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
   - `docs/docs.json`：接受上游版本（`git checkout --ours`），然後重建 zh-Hant 專屬導航
   - `docs/index.md`：接受上游版本（`git checkout --ours`），然後用 zh-Hant 中文內容覆蓋（見「首頁維護」段落）
   - 其他重複的舊 commit（orphan 導航、homepage 修改等）：直接 `git rebase --skip`
4. docs.json 導航結構：
   - **不使用 `languages` 包裝**，直接在 `navigation` 下放 `tabs`（避免出現語言切換下拉選單）
   - 使用 `tabs` 結構（與英文版一致）
   - tabs 和 groups 名稱使用**中文**
   - 只有 zh-Hant 語言，不包含 en/zh-Hans/ja
   - 新增的文件必須加入對應的 tab/group
   - `redirects` 須包含 `{"source": "/", "destination": "/zh-Hant"}`
   - `navbar.links` 須包含「譯者 Jackle」連結（href: https://jackle.pro/about, icon: user）

### 階段三：找出需要翻譯的文件

1. 因為 rebase 後 merge-base 等於最新 tag，改用前一個已知 tag 比較差異：
   ```bash
   git diff --name-only <前一版tag> <最新tag> -- docs/ | grep -v 'zh-Hant/' | grep -v 'zh-CN/' | grep -v 'ja-JP/'
   ```
2. 注意路徑重映射：部分 zh-Hant 文件的路徑與英文版不同（參考 remap 表）
3. 分類：需更新（繁中版存在）vs 需新增（繁中版不存在）vs 路徑重映射更新

### 階段四：平行翻譯

使用 Haiku sub-agents 平行翻譯，按目錄分批（每批 25-35 檔）：

1. cli/ + channels/
2. concepts/ + gateway/
3. tools/ + providers/
4. install/ + platforms/
5. start/ + help/ + automation/
6. reference/ + web/ + 根目錄散落檔案

每個 agent 的 prompt 參考 `references/translation-prompt.md`。

**關鍵**：Haiku agent 有 token 限制，每批可能無法全部完成。完成後檢查回報，未完成的檔案啟動補翻 agent。

### 階段五：修正 frontmatter title

翻譯完成後，用 Python 腳本批次檢查所有 zh-Hant 檔案的 frontmatter title 格式：

1. 與英文原檔 title 對比
2. 確認使用全形括號 `（）`
3. 確認英文在前、中文在後
4. 品牌名不加中文翻譯
5. 修正所有不符規則的 title

### 階段六：修正內部連結

所有 zh-Hant 文件和根 `docs/index.md` 的內部連結必須指向 `/zh-Hant/` 路徑：

1. 用 Python 腳本批次掃描所有 `docs/zh-Hant/**/*.md` 和 `docs/index.md`
2. 將 markdown 連結 `[text](/path)` 修正為 `[text](/zh-Hant/path)`
3. 將 href 屬性 `href="/path"` 修正為 `href="/zh-Hant/path"`
4. 排除：已有 `/zh-Hant/` 前綴、外部連結（http）、錨點（#）、assets 路徑、圖片檔

### 階段七：檢查 docs.json

確認 navigation 中的所有路徑都存在對應文件，如有新文件需更新 navigation。

### 階段八：更新首頁版本標示

兩份首頁（`docs/index.md` 和 `docs/zh-Hant/index.md`）的 Warning 區塊中包含版本資訊，必須更新：

1. `**對應版本：`v<新版本>`**` — 改為本次同步的 tag 版本號
2. `翻譯更新日期：YYYY-MM-DD` — 改為當天日期

### 階段九：完成

顯示變更統計，詢問使用者是否要 commit（不要自動 commit）。

## 翻譯規則

參考 `references/translation-rules.md`。

## 路徑重映射表

部分 zh-Hant 文件的路徑與英文版不同：

| 英文路徑                        | zh-Hant 路徑                 |
| ------------------------------- | ---------------------------- |
| automation/hooks                | hooks                        |
| channels/broadcast-groups       | broadcast-groups             |
| channels/channel-routing        | concepts/channel-routing     |
| channels/group-messages         | concepts/group-messages      |
| channels/groups                 | concepts/groups              |
| channels/pairing                | start/pairing                |
| help/debugging                  | debugging                    |
| help/environment                | environment                  |
| help/scripts                    | scripts                      |
| help/testing                    | testing                      |
| install/exe-dev                 | platforms/exe-dev            |
| install/fly                     | platforms/fly                |
| install/gcp                     | platforms/gcp                |
| install/hetzner                 | platforms/hetzner            |
| install/macos-vm                | platforms/macos-vm           |
| reference/token-use             | token-use                    |
| security/formal-verification    | security/formal-verification |
| tools/multi-agent-sandbox-tools | multi-agent-sandbox-tools    |
| tools/plugin                    | plugin                       |
| providers/bedrock               | bedrock                      |
| web/tui                         | tui                          |

## 首頁維護

`docs/index.md` 和 `docs/zh-Hant/index.md` 都是中文首頁，內容須保持同步。每次 rebase 後 `docs/index.md` 會被上游英文版覆蓋，**必須用 zh-Hant 中文內容重新覆蓋**。

首頁包含以下關鍵區塊（rebase 後必須確認存在）：

1. **翻譯聲明 + 譯者社群連結**（`<Warning>` 區塊）：

   ```
   <Warning>
   **非官方翻譯聲明**
   ...譯者資訊...
   **對應版本：`v<版本號>`** · 翻譯更新日期：YYYY-MM-DD

   <CardGroup cols={3}>
     <Card title="Jackle 部落格" href="https://jackle.pro/about" icon="globe">
     <Card title="Facebook" href="https://www.facebook.com/jackle45/" icon="facebook">
     <Card title="Threads" href="https://www.threads.com/@jackle9527" icon="at-sign">
   </CardGroup>
   </Warning>
   ```

2. **頁尾署名**（頁面最底部）：

   ```
   <p align="center">
     <sub>繁體中文翻譯與維護：<a href="https://jackle.pro/about">陳泰呈（Jackle）</a> · <a href="https://www.facebook.com/jackle45/">Facebook</a> · <a href="https://www.threads.com/@jackle9527">Threads</a></sub>
   </p>
   ```

3. **所有內部連結必須使用 `/zh-Hant/` 前綴**

## 注意事項

- Haiku agent 可能有 token 限制，未完成需拆分繼續
- docs.json 只有繁體中文，tabs/groups 名稱用中文
- docs.json 的 `navigation` 直接用 `tabs`，**不要用 `languages` 包裝**（否則會出現語言切換下拉選單）
- docs.json 的 `navbar.links` 須包含「譯者 Jackle」連結
- 不要自動 commit，讓使用者檢查後再決定
- frontmatter title 是最常出錯的地方，翻譯完成後務必用腳本批次檢查修正
- 翻譯完成後務必批次修正所有內部連結加上 `/zh-Hant/` 前綴
- rebase 後 `docs/index.md` 會被英文版覆蓋，必須重新覆蓋為中文版（含譯者區塊、版本標示、社群連結）
- 每次同步完成後更新首頁的版本號和日期
