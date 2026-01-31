---
title: "Node issue(Node + tsx 崩潰問題)"
summary: "Node + tsx \"__name is not a function\" 崩潰說明與解決方法"
read_when:
  - 除錯僅限 Node 的開發腳本或監視模式失敗
  - 調查 OpenClaw 中的 tsx/esbuild 載入器崩潰
---

# Node + tsx "__name is not a function" crash

## 摘要
透過 Node 使用 `tsx` 執行 OpenClaw 在啟動時失敗，錯誤訊息為：

```
[openclaw] Failed to start CLI: TypeError: __name is not a function
    at createSubsystemLogger (.../src/logging/subsystem.ts:203:25)
    at .../src/agents/auth-profiles/constants.ts:25:20
```

這在將開發腳本從 Bun 切換到 `tsx` 之後開始發生（commit `2871657e`，2026-01-06）。相同的執行時路徑在 Bun 下可以運作。

## 環境
- Node: v25.x（在 v25.3.0 上觀察到）
- tsx: 4.21.0
- OS: macOS（在執行 Node 25 的其他平台上也可能重現）

## 重現步驟（僅限 Node）
```bash
# 在儲存庫根目錄
node --version
pnpm install
node --import tsx src/entry.ts status
```

## 儲存庫中的最小重現
```bash
node --import tsx scripts/repro/tsx-name-repro.ts
```

## Node 版本檢查
- Node 25.3.0: 失敗
- Node 22.22.0 (Homebrew `node@22`): 失敗
- Node 24: 尚未安裝；需要驗證

## 注意事項 / 假設
- `tsx` 使用 esbuild 來轉換 TS/ESM。esbuild 的 `keepNames` 會發出 `__name` helper 並用 `__name(...)` 包裝函式定義。
- 崩潰表明 `__name` 存在但在執行時不是函式，這意味著 helper 在 Node 25 載入器路徑中對此模組而言是缺少的或被覆寫的。
- 在其他 esbuild 使用者中，當 helper 缺少或被重寫時，已報告了類似的 `__name` helper 問題。

## 回歸歷史
- `2871657e`（2026-01-06）：腳本從 Bun 改為 tsx 以使 Bun 成為選用的。
- 在那之前（Bun 路徑），`openclaw status` 和 `gateway:watch` 可以運作。

## 解決方法
- 對開發腳本使用 Bun（目前的臨時回退）。
- 使用 Node + tsc watch，然後執行編譯後的輸出：
  ```bash
  pnpm exec tsc --watch --preserveWatchOutput
  node --watch openclaw.mjs status
  ```
- 本地確認：`pnpm exec tsc -p tsconfig.json` + `node openclaw.mjs status` 在 Node 25 上可以運作。
- 如果可能的話，在 TS 載入器中停用 esbuild keepNames（防止插入 `__name` helper）；tsx 目前未公開此選項。
- 使用 `tsx` 測試 Node LTS (22/24) 以查看問題是否僅限於 Node 25。

## 參考資料
- https://opennext.js.org/cloudflare/howtos/keep_names
- https://esbuild.github.io/api/#keep-names
- https://github.com/evanw/esbuild/issues/1031

## 後續步驟
- 在 Node 22/24 上重現以確認 Node 25 回歸。
- 測試 `tsx` nightly 或如果存在已知回歸則固定到較早版本。
- 如果在 Node LTS 上重現，向上游提交帶有 `__name` 堆疊追蹤的最小重現。
