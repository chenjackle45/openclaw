---
title: "Test(測試)"
summary: "如何在本機執行測試（Vitest）以及何時使用 Force/Coverage 模式"
read_when:
  - 執行或修復測試
---
# 測試

- 完整測試套件（Suites、Live、Docker）：[Testing](/zh-Hant/testing)

- `pnpm test:force`：終止任何佔用預設 Control Port 的殘留 Gateway Process，然後使用隔離的 Gateway Port 執行完整 Vitest Suite，讓 Server 測試不會與執行中的實例衝突。當先前的 Gateway Run 佔用 Port 18789 時使用此項。
- `pnpm test:coverage`：使用 V8 Coverage 執行 Vitest。全域 Thresholds 是 70% Lines/Branches/Functions/Statements。Coverage 排除整合密集的 Entrypoints（CLI Wiring、Gateway/Telegram Bridges、Webchat Static Server）以保持目標專注於可單元測試的邏輯。
- `pnpm test:e2e`：執行 Gateway 端對端 Smoke Tests（Multi-instance WS/HTTP/Node Pairing）。
- `pnpm test:live`：執行 Provider Live Tests（Minimax/Zai）。需要 API Keys 和 `LIVE=1`（或 Provider-specific `*_LIVE_TEST=1`）以取消略過。

## Model 延遲 Bench（Local Keys）

腳本：[`scripts/bench-model.ts`](https://github.com/openclaw/openclaw/blob/main/scripts/bench-model.ts)

使用方式：
- `source ~/.profile && pnpm tsx scripts/bench-model.ts --runs 10`
- 選用 Env：`MINIMAX_API_KEY`、`MINIMAX_BASE_URL`、`MINIMAX_MODEL`、`ANTHROPIC_API_KEY`
- 預設 Prompt："Reply with a single word: ok. No punctuation or extra text."

最後一次執行（2025-12-31，20 次）：
- Minimax Median 1279ms（Min 1114、Max 2431）
- Opus Median 2454ms（Min 1224、Max 3170）

## Onboarding E2E（Docker）

Docker 是選用的；這僅用於容器化 Onboarding Smoke Tests。

在乾淨的 Linux Container 中完整的 Cold-start 流程：

```bash
scripts/e2e/onboard-docker.sh
```

此腳本透過 Pseudo-tty 驅動互動式 Wizard，驗證 Config/Workspace/Session 檔案，然後啟動 Gateway 並執行 `openclaw health`。

## QR Import Smoke（Docker）

確保 `qrcode-terminal` 在 Docker 中的 Node 22+ 下載入：

```bash
pnpm test:docker:qr
```
