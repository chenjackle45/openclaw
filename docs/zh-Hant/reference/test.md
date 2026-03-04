---
summary: “如何在本機執行測試（vitest）以及何時使用強制/覆蓋範圍模式”
read_when:
  - 執行或修復測試
title: "Tests（測試）"
---

# 測試

- 完整測試工具包（套件、即時、Docker）：[測試](/zh-Hant/help/testing)

- `pnpm test:force`：終止任何佔據預設控制埠的延遲閘道處理程序，然後執行完整的 Vitest 套件，使用隔離的閘道埠以便伺服器測試不與執行中的實例衝突。當先前的閘道執行佔據了埠 18789 時使用此命令。
- `pnpm test:coverage`：執行具有 V8 覆蓋的單位套件（透過 `vitest.unit.config.ts`）。全域閾值為 70% 的行/分支/函式/陳述式。覆蓋排除整合繁重的進入點（CLI 佈線、閘道/Telegram 橋、webchat 靜態伺服器），以使目標專注於單位可測試邏輯。
- `pnpm test` 在 Node 24+：OpenClaw 自動停用 Vitest `vmForks` 並使用 `forks` 以避免 `ERR_VM_MODULE_LINK_FAILURE` / `module is already linked`。您可以使用 `OPENCLAW_TEST_VM_FORKS=0|1` 強制行為。
- `pnpm test`：預設執行快速核心單位賽道以獲得快速本機回饋。
- `pnpm test:channels`：執行通道繁重套件。
- `pnpm test:extensions`：執行擴充功能/外掛套件。
- 閘道整合：透過 `OPENCLAW_TEST_INCLUDE_GATEWAY=1 pnpm test` 或 `pnpm test:gateway` 選擇加入。
- `pnpm test:e2e`：執行閘道端對端煙霧測試（多實例 WS/HTTP/節點配對）。預設為 `vmForks` + `vitest.e2e.config.ts` 中的自適應工作者；使用 `OPENCLAW_E2E_WORKERS=<n>` 調整，並設定 `OPENCLAW_E2E_VERBOSE=1` 以取得詳細日誌。
- `pnpm test:live`：執行供應商即時測試（minimax/zai）。需要 API 金鑰以及 `LIVE=1`（或供應商特定 `*_LIVE_TEST=1`）以取消跳過。

## 本機 PR 閘道

針對本機 PR 登錄/閘道檢查，執行：

- `pnpm check`
- `pnpm build`
- `pnpm test`
- `pnpm check:docs`

如果 `pnpm test` 在負載重的主機上不穩定，在視為迴歸之前重新執行一次，然後使用 `pnpm vitest run <path/to/test>` 隔離。針對記憶體受限的主機，使用：

- `OPENCLAW_TEST_PROFILE=low OPENCLAW_TEST_SERIAL_GATEWAY=1 pnpm test`

## 模型延遲基準（本機金鑰）

指令碼：[`scripts/bench-model.ts`](https://github.com/openclaw/openclaw/blob/main/scripts/bench-model.ts)

用法：

- `source ~/.profile && pnpm tsx scripts/bench-model.ts --runs 10`
- 選用環境：`MINIMAX_API_KEY`、`MINIMAX_BASE_URL`、`MINIMAX_MODEL`、`ANTHROPIC_API_KEY`
- 預設提示：「用一個單字回覆：ok。無標點符號或額外文字。」

最後執行（2025-12-31，20 次執行）：

- minimax 中位數 1279ms（最小 1114，最大 2431）
- opus 中位數 2454ms（最小 1224，最大 3170）

## CLI 啟動基準

指令碼：[`scripts/bench-cli-startup.ts`](https://github.com/openclaw/openclaw/blob/main/scripts/bench-cli-startup.ts)

用法：

- `pnpm tsx scripts/bench-cli-startup.ts`
- `pnpm tsx scripts/bench-cli-startup.ts --runs 12`
- `pnpm tsx scripts/bench-cli-startup.ts --entry dist/entry.js --timeout-ms 45000`

此基準測試這些命令：

- `--version`
- `--help`
- `health --json`
- `status --json`
- `status`

輸出包括每個命令的平均、p50、p95、最小/最大和結束碼/信號分佈。

## 入職 E2E（Docker）

Docker 是選用的；這只有在容器化入職煙霧測試中才需要。

在乾淨 Linux 容器中的完整冷啟動流程：

```bash
scripts/e2e/onboard-docker.sh
```

此指令碼透過虛擬 tty 驅動互動式精靈，驗證設定/工作區/工作階段檔案，然後啟動閘道並執行 `openclaw health`。

## QR 匯入煙霧（Docker）

確保 `qrcode-terminal` 在 Docker 中的 Node 22+ 下載入：

```bash
pnpm test:docker:qr
```
