---
title: "update(系統更新)"
summary: "`openclaw update` CLI 參考（安全源碼更新與 Gateway 自動重啟）"
read_when:
  - 想要安全地更新原始碼或切換頻道時
  - 需要瞭解 `--update` 捷徑行為時
---

# `openclaw update`

安全地更新 OpenClaw，並在穩定 (Stable)、測試 (Beta) 與開發 (Dev) 頻道之間切換。

如果您是透過 **npm/pnpm** 全域安裝（無 git 元數據），更新流程將依照 [更新指南 (Updating)](/install/updating) 中的套件管理員流程執行。

## 使用範例

```bash
# 執行更新
openclaw update

# 查看目前更新狀態
openclaw update status

# 啟動互動式更新嚮導
openclaw update wizard

# 切換至測試或開發頻道
openclaw update --channel beta
openclaw update --channel dev

# 指定特定的 npm 標籤或版本
openclaw update --tag beta

# 更新後不重新啟動 Gateway
openclaw update --no-restart

# 使用捷徑旗標執行更新
openclaw --update
```

## 參數選項

- `--no-restart`：更新成功後跳過重新啟動 Gateway 服務的步驟。
- `--channel <stable|beta|dev>`：設定更新頻道（包含 Git 與 NPM；此設定會持久化於配置中）。
- `--tag <標籤|版本>`：僅針對本次更新覆寫 npm 發佈標籤。
- `--json`：輸出機器可讀的 `UpdateRunResult` JSON 格式。
- `--timeout <秒數>`：各步驟的超時設定（預設為 1200 秒）。

**注意**：降級行為需要手動確認，因為舊版本可能會導致現有配置失效。

## `update status` 指令

顯示目前啟動的更新頻道、Git 標籤/分支/SHA 資訊（適用於源碼安裝），以及是否有可用更新。

```bash
openclaw update status
openclaw update status --json
```

## `update wizard` 指令

互動式流程，引導您挑選更新頻道，並確認更新後是否要重啟 Gateway（預設為重啟）。如果您在沒有 Git 源碼的情況下選擇 `dev` 頻道，嚮導會建議為您建立一個。

## 執行流程說明

當您明確地切換頻道時（使用 `--channel ...`），OpenClaw 會同步確保安裝方式對齊：

- `dev`：確保存在 Git Checkout 目錄（預設：`~/openclaw`），更新該目錄並從中安裝全域 CLI。
- `stable`/`beta`：使用對應的發佈標籤從 npm 安裝。

### Git Checkout 流程細節：
1. 要求工作樹（Worktree）是乾淨的（無未提交的變動）。
2. 切換至選定的頻道。
3. 抓取遠端更新（僅限 dev）。
4. （僅限 dev）在臨時工作樹進行 Preflight Lint 與 TypeScript 編譯；若失敗則向上回溯最多 10 個 Commit 以尋找最新的穩定版本。
5. 執行 Rebase 至選定的 Commit。
6. 安裝相依項 (pnpm 優先)。
7. 建置系統與 Control UI。
8. 執行 `openclaw doctor` 作為最終的安全性檢查。
9. 同步外掛至對應頻道。

## 相關連結

- `openclaw doctor`（對於 Git 安裝，會優先建議執行更新）
- [開發頻道介紹](/install/development-channels)
- [更新指南 (Updating)](/install/updating)
- [CLI 指令總覽](/cli)
