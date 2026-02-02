---
title: "Pi 開發工作流"
---

# Pi 開發工作流

本指南總結在 OpenClaw 中進行 pi 整合工作的合理工作流。

## 類型檢查與 Linting

- 類型檢查並構建：`pnpm build`
- Lint：`pnpm lint`
- 格式檢查：`pnpm format`
- 推送前完整檢查：`pnpm lint && pnpm build && pnpm test`

## 執行 Pi 測試

使用 pi 整合測試集的專用腳本：

```bash
scripts/pi/run-tests.sh
```

包含測試實際提供商行為的即時測試：

```bash
scripts/pi/run-tests.sh --live
```

該腳本透過以下 glob 執行所有 pi 相關的單元測試：

- `src/agents/pi-*.test.ts`
- `src/agents/pi-embedded-*.test.ts`
- `src/agents/pi-tools*.test.ts`
- `src/agents/pi-settings.test.ts`
- `src/agents/pi-tool-definition-adapter.test.ts`
- `src/agents/pi-extensions/*.test.ts`

## 手動測試

推薦流程：

- 以開發模式執行閘道：
  - `pnpm gateway:dev`
- 直接觸發代理：
  - `pnpm openclaw agent --message "Hello" --thinking low`
- 使用 TUI 進行互動式除錯：
  - `pnpm tui`

對於工具呼叫行為，提示 `read` 或 `exec` 操作，以便查看工具串流和載荷處理。

## 潔淨重置

狀態位於 OpenClaw 狀態目錄下。預設為 `~/.openclaw`。如果設定 `OPENCLAW_STATE_DIR`，請改用該目錄。

重置所有內容：

- `openclaw.json` 用於設定
- `credentials/` 用於驗證設定檔和令牌
- `agents/<agentId>/sessions/` 用於代理會話歷史
- `agents/<agentId>/sessions.json` 用於會話索引
- `sessions/` 如果存在舊版路徑
- `workspace/` 如果需要潔淨工作區

如果只想重置會話，刪除該代理的 `agents/<agentId>/sessions/` 和 `agents/<agentId>/sessions.json`。如果不想重新驗證，請保持 `credentials/`。

## 參考

- https://docs.openclaw.ai/testing
- https://docs.openclaw.ai/start/getting-started
