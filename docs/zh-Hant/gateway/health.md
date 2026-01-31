---
title: "health(Health Checks (CLI))"
summary: "Channel 連線的健康檢查步驟"
read_when:
  - 診斷 WhatsApp Channel 健康狀況時
---

# 健康檢查 (Health Checks (CLI))

不靠猜測來驗證 Channel 連線的簡短指南。

## 快速檢查

- `openclaw status` — 本地摘要：Gateway 可達性/模式、更新提示、連結的 Channel Auth Age、Sessions + 近期活動。
- `openclaw status --all` — 完整本地診斷 (唯讀, 彩色, 適合貼上以供除錯)。
- `openclaw status --deep` — 亦探測運行中的 Gateway (若支援則進行 Per-channel Probes)。
- `openclaw health --json` — 詢問運行中的 Gateway 取得完整健康快照 (僅限 WS；無直接 Baileys Socket)。
- 在 WhatsApp/WebChat 中發送 `/status` 作為獨立訊息，以取得狀態回覆而不呼叫 Agent。
- Logs: tail `/tmp/openclaw/openclaw-*.log` 並過濾 `web-heartbeat`, `web-reconnect`, `web-auto-reply`, `web-inbound`。

## 深度診斷

- 磁碟上的憑證: `ls -l ~/.openclaw/credentials/whatsapp/<accountId>/creds.json` (mtime 應該要是近期的)。
- Session Store: `ls -l ~/.openclaw/agents/<agentId>/sessions/sessions.json` (路徑可在 Config 中覆蓋)。總數與近期接收者會透過 `status` 呈現。
- Relink 流程: 當日誌出現狀態碼 409–515 或 `loggedOut` 時，執行 `openclaw channels logout && openclaw channels login --verbose`。(註：QR Login 流程在配對後遇到狀態 515 時會自動重啟一次。)

## 當發生失敗時

- `logged out` 或狀態 409–515 → 使用 `openclaw channels logout` 然後 `openclaw channels login` 重新連結。
- Gateway 無法連線 → 啟動它：`openclaw gateway --port 18789` (若 Port 忙碌則使用 `--force`)。
- 無 Inbound 訊息 → 確認連結的手機在線且發送者是被允許的 (`channels.whatsapp.allowFrom`)；對於群組聊天，確保 Allowlist + Mention Rules 相符 (`channels.whatsapp.groups`, `agents.list[].groupChat.mentionPatterns`)。

## 專用 "health" 指令

`openclaw health --json` 詢問運行中的 Gateway 取得其健康快照 (CLI 無直接 Channel Sockets)。它會報告連結 Creds/Auth Age (若可用)、Per-channel Probe 摘要、Session-store 摘要以及 Probe Duration。若 Gateway 無法連線或 Probe 失敗/超時，它會以非零狀態退出。使用 `--timeout <ms>` 覆蓋預設的 10s。
