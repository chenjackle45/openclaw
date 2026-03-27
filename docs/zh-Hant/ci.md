---
title: "CI Pipeline（CI 管道）"
summary: "CI 工作圖、範圍閘道及本地指令等價物"
read_when:
  - 需要瞭解 CI 工作何時執行或未執行的原因時
  - 正在除錯失敗的 GitHub Actions 檢查時
---

# CI 管道

CI 在每次推送至 `main` 和每個拉取請求時執行。它使用智慧範圍限定來在只有無關區域變更時跳過昂貴的工作。

## 工作概觀

| 工作              | 目的                                                       | 執行時機                         |
| ----------------- | ---------------------------------------------------------- | -------------------------------- |
| `preflight`       | 文件範圍、變更範圍、金鑰掃描、工作流程稽核、產品相依性稽核 | 始終；非文件變更時僅限 node 稽核 |
| `docs-scope`      | 偵測文件專用變更                                           | 始終                             |
| `changed-scope`   | 偵測哪些區域變更（node/macos/android/windows）             | 非文件變更                       |
| `check`           | TypeScript 型別、Lint、格式化                              | 非文件、node 變更                |
| `check-docs`      | Markdown lint + 中斷連結檢查                               | 文件變更                         |
| `secrets`         | 偵測洩露的祕密                                             | 始終                             |
| `build-artifacts` | 建置 dist 一次，與 `release-check` 共享                    | 推送至 `main`、node 變更         |
| `release-check`   | 驗證 npm pack 內容                                         | 推送至 `main` 後跟隨建置         |
| `checks`          | Node 測試 + PR 上的協議檢查；推送時的 Bun 相容性           | 非文件、node 變更                |
| `compat-node22`   | 最小支援 Node 執行時相容性                                 | 推送至 `main`、node 變更         |
| `checks-windows`  | Windows 特定測試                                           | 非文件、windows 相關變更         |
| `macos`           | Swift lint/build/test + TS 測試                            | macos 變更的 PR                  |
| `android`         | Gradle 建置 + 測試                                         | 非文件、android 變更             |

## 快速失敗順序

工作被排序，以便廉價檢查在昂貴的工作執行前失敗：

1. `docs-scope` + `changed-scope` + `check` + `secrets`（並行，廉價閘道優先）
2. PR：`checks`（Linux Node 測試分成 2 個分片）、`checks-windows`、`macos`、`android`
3. 推送至 `main`：`build-artifacts` + `release-check` + Bun 相容性 + `compat-node22`

範圍邏輯位於 `scripts/ci-changed-scope.mjs` 並由 `src/scripts/ci-changed-scope.test.ts` 中的單元測試涵蓋。相同的共享範圍模組也透過較窄的 `changed-smoke` 閘道驅動單獨的 `install-smoke` 工作流程，因此 Docker/安裝煙霧測試只對安裝、封裝和容器相關變更執行。

## 執行器

| 執行器                           | 工作                            |
| -------------------------------- | ------------------------------- |
| `blacksmith-16vcpu-ubuntu-2404`  | 大多數 Linux 工作，包括範圍偵測 |
| `blacksmith-32vcpu-windows-2025` | `checks-windows`                |
| `macos-latest`                   | `macos`、`ios`                  |

## 本地等價物

```bash
pnpm check          # 型別 + lint + 格式化
pnpm test           # vitest 測試
pnpm check:docs     # 文件格式 + lint + 中斷連結
pnpm release:check  # 驗證 npm pack
```
