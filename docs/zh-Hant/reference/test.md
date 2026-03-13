---
title: "Tests（測試）"
summary: "如何在本地執行測試（vitest）以及何時使用強制／涵蓋模式"
read_when:
  - 執行或修復測試
---

# 測試

- 完整測試套件（套件、實況、Docker）：[測試](/zh-Hant/help/testing)

- `pnpm test:force`：終止任何佔據預設控制連接埠的舊有閘道程序，然後使用隔離的閘道連接埠執行完整 Vitest 套件，以便伺服器測試不會與執行中的實例衝突。當先前的閘道執行使連接埠 18789 佔據時使用。
- `pnpm test:coverage`：使用 V8 涵蓋（透過 `vitest.unit.config.ts`）執行單位套件。全局閾值為 70% 行／分支／函式／陳述式。涵蓋排除整合繁重的進入點（CLI 接線、閘道／telegram 橋接、webchat 靜態伺服器）以保持目標專注於單位可測試邏輯。
- `pnpm test`（在 Node 24+ 上）：OpenClaw 自動停用 Vitest `vmForks` 並使用 `forks` 以避免 `ERR_VM_MODULE_LINK_FAILURE` / `module is already linked`。您可以使用 `OPENCLAW_TEST_VM_FORKS=0|1` 強制行為。
- `pnpm test`：預設執行快速核心單位通道以提供快速本地回饋。
- `pnpm test:channels`：執行頻道繁重的套件。
- `pnpm test:extensions`：執行擴充套件／外掛套件。
- 閘道整合：透過 `OPENCLAW_TEST_INCLUDE_GATEWAY=1 pnpm test` 或 `pnpm test:gateway` 選擇加入。
- `pnpm test:e2e`：執行閘道端到端煙霧測試（多實例 WS／HTTP／node 配對）。預設為 `vitest.e2e.config.ts` 中的 `vmForks` + 自適應背景工作；使用 `OPENCLAW_E2E_WORKERS=<n>` 調整並設定 `OPENCLAW_E2E_VERBOSE=1` 以取得詳細記錄。
- `pnpm test:live`：執行提供者實況測試（minimax／zai）。需要 API 金鑰和 `LIVE=1`（或提供者特定 `*_LIVE_TEST=1`）以取消略過。

## 本地 PR 門

對於本地 PR 著陸／門檢查，執行：

- `pnpm check`
- `pnpm build`
- `pnpm test`
- `pnpm check:docs`

如果 `pnpm test` 在已載入的主機上翻轉，在將其視為迴歸前重新執行一次，然後使用 `pnpm vitest run <path/to/test>` 隔離。對於記憶體受限的主機，使用：

- `OPENCLAW_TEST_PROFILE=low OPENCLAW_TEST_SERIAL_GATEWAY=1 pnpm test`

## 模型潛時基準（本地金鑰）

指令碼：[`scripts/bench-model.ts`](https://github.com/openclaw/openclaw/blob/main/scripts/bench-model.ts)

用法：

- `source ~/.profile && pnpm tsx scripts/bench-model.ts --runs 10`
- 選擇性環境：`MINIMAX_API_KEY`、`MINIMAX_BASE_URL`、`MINIMAX_MODEL`、`ANTHROPIC_API_KEY`
- 預設提示：「回覆單一單字：ok。沒有標點符號或額外文字。」

上次執行（2025-12-31，20 次執行）：

- minimax 中位 1279ms（最小 1114，最大 2431）
- opus 中位 2454ms（最小 1224，最大 3170）

## CLI 啟動基準

指令碼：[`scripts/bench-cli-startup.ts`](https://github.com/openclaw/openclaw/blob/main/scripts/bench-cli-startup.ts)

用法：

- `pnpm tsx scripts/bench-cli-startup.ts`
- `pnpm tsx scripts/bench-cli-startup.ts --runs 12`
- `pnpm tsx scripts/bench-cli-startup.ts --entry dist/entry.js --timeout-ms 45000`

這會對以下命令進行基準測試：

- `--version`
- `--help`
- `health --json`
- `status --json`
- `status`

輸出包括每個命令的平均、p50、p95、最小值／最大值，以及結束代碼／信號分佈。

## 登機 E2E（Docker）

Docker 是選擇性的；僅當需要容器化登機煙霧測試時才需要。

乾淨 Linux 容器中的完整冷啟動流程：

```bash
scripts/e2e/onboard-docker.sh
```

此指令碼透過虛擬 tty 驅動互動式精靈，驗證設定／工作區／工作階段檔案，然後啟動閘道並執行 `openclaw health`。

## QR 匯入煙霧（Docker）

確保 `qrcode-terminal` 在支援的 Docker Node 執行時間下載入（Node 24 預設，Node 22 相容）：

```bash
pnpm test:docker:qr
```
