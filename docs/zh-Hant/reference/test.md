---
summary: "如何在本機執行測試（vitest）以及何時使用強制/覆蓋模式"
read_when:
  - 執行或修正測試
title: "Tests（測試）"
---

# 測試

- 完整測試套件（套件、即時、Docker）：[測試](/zh-Hant/help/testing)

- `pnpm test:force`：殺死任何持有預設控制埠的 lingering Gateway 進程，然後以隔離的 Gateway 埠執行完整 Vitest 套件，使伺服器測試不會與執行中的實例衝突。當先前的 Gateway 執行讓連接埠 18789 被佔用時，請使用此選項。
- `pnpm test:coverage`：執行 Vitest 並進行 V8 覆蓋。全域閾值為 70% 行/分支/函式/陳述句。覆蓋排除整合密集的進入點（CLI 佈線、Gateway/Telegram 橋接、webchat 靜態伺服器），以保持目標專注於單位可測試邏輯。
- `pnpm test:e2e`：執行 Gateway 端對端煙霧測試（多實例 WS/HTTP/節點配對）。
- `pnpm test:live`：執行提供者即時測試（minimax/zai）。需要 API 金鑰和 `LIVE=1`（或特定提供者 `*_LIVE_TEST=1`）以取消跳過。

## 模型延遲基準（本機金鑰）

指令碼：[`scripts/bench-model.ts`](https://github.com/openclaw/openclaw/blob/main/scripts/bench-model.ts)

使用方式：

- `source ~/.profile && pnpm tsx scripts/bench-model.ts --runs 10`
- 選擇性環境：`MINIMAX_API_KEY`、`MINIMAX_BASE_URL`、`MINIMAX_MODEL`、`ANTHROPIC_API_KEY`
- 預設提示：「用單個字回應：ok。無標點符號或額外文字。」

最後執行（2025-12-31，20 次執行）：

- minimax 中值 1279ms（最小 1114，最大 2431）
- opus 中值 2454ms（最小 1224，最大 3170）

## 上線 E2E（Docker）

Docker 是選擇性的；這僅在容器化上線煙霧測試中需要。

在乾淨 Linux 容器中的完整冷啟動流程：

```bash
scripts/e2e/onboard-docker.sh
```

此指令碼透過 pseudo-tty 驅動互動式精靈，驗證設定/工作區/會話檔案，然後啟動 Gateway 並執行 `openclaw health`。

## QR 匯入煙霧（Docker）

確保 `qrcode-terminal` 在 Docker 中的 Node 22+ 下載入：

```bash
pnpm test:docker:qr
```
