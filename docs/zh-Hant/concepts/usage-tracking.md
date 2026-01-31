---
title: "Usage tracking(使用量追蹤)"
summary: "使用量追蹤顯示位置與憑證要求"
read_when:
  - 您正在連接供應商的使用量/配額顯示
  - 您需要解釋使用量追蹤行為或認證要求
---
# Usage tracking（使用量追蹤）

## 它是什麼
- 直接從供應商的使用量端點抓取使用量/配額 (Usage/Quota)。
- 無預估成本；僅顯示供應商回報的統計期間。

## 顯示位置
- 聊天中的 `/status`：帶有 Emoji 的狀態卡片，包含會話權限 + 估計成本（僅限 API 金鑰）。可用時會顯示**當前模型供應商**的使用量。
- 聊天中的 `/usage off|tokens|full`：每則回應的使用量頁腳（OAuth 僅顯示權杖）。
- 聊天中的 `/usage cost`：從 OpenClaw 會話日誌匯總的本地成本摘要。
- CLI：`openclaw status --usage` 打印完整的各供應商明細。
- CLI：`openclaw channels list` 在供應商設定旁打印使用量快照（使用 `--no-usage` 跳過）。
- macOS 選單列：Context 下方的「Usage」區段（僅在可用時）。

## 供應商與憑證
- **Anthropic (Claude)**：認證設定檔中的 OAuth 權仗。
- **GitHub Copilot**：認證設定檔中的 OAuth 權仗。
- **Gemini CLI**：認證設定檔中的 OAuth 權仗。
- **Antigravity**：認證設定檔中的 OAuth 權仗。
- **OpenAI Codex**：認證設定檔中的 OAuth 權仗（如有 `accountId` 則使用之）。
- **MiniMax**：API 金鑰（Coding Plan 金鑰；`MINIMAX_CODE_PLAN_KEY` 或 `MINIMAX_API_KEY`）；使用 5 小時 Coding Plan 的統計期間。
- **z.ai**：透過環境變數/設定/認證儲存的 API 金鑰。

如果不存在匹配的 OAuth/API 憑證，則會隱藏使用量資訊。
