---
summary: "建立 OpenClaw 作為個人助理的完整指南，包含安全警告"
read_when:
  - 入門新的助理實例時
  - 檢視安全/權限含義時
title: "個人助理設定"
---

# 使用 OpenClaw 建立個人助理

OpenClaw 是 **Pi** 代理的 WhatsApp + Telegram + Discord + iMessage Gateway。外掛增加 Mattermost。本指南是「個人助理」設定：一個專屬 WhatsApp 號碼，表現得像您的全天候代理。

## ⚠️ 安全優先

您正在讓代理程式處於可以：

- 在您的機器上執行命令（取決於您的 Pi 工具設定）
- 讀取/寫入工作區檔案
- 透過 WhatsApp/Telegram/Discord/Mattermost（外掛）傳回訊息

開始時要保守：

- 始終設定 `channels.whatsapp.allowFrom`（永不在您的個人 Mac 上完全開放）。
- 為助理使用專屬 WhatsApp 號碼。
- 心跳現在預設為每 30 分鐘。透過設定 `agents.defaults.heartbeat.every: "0m"` 在信任設定前停用。

## 先決條件

- Node **22+**
- OpenClaw 在 PATH 上可用（推薦全域安裝）
- 助理的第二個電話號碼（SIM/eSIM/預付）

```bash
npm install -g openclaw@latest
# 或：pnpm add -g openclaw@latest
```

從原始碼（開發）：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 首次執行時自動安裝 UI 依賴
pnpm build
pnpm link --global
```

## 雙手機設定（推薦）

您想要這個：

```
您的手機（個人）          第二手機（助理）
┌─────────────────┐           ┌─────────────────┐
│  您的 WhatsApp  │  ──────▶  │  助理 WA         │
│  +1-555-YOU     │  訊息     │  +1-555-ASSIST  │
└─────────────────┘           └────────┬────────┘
                                       │ 透過 QR 連結
                                       ▼
                              ┌─────────────────┐
                              │  您的 Mac       │
                              │  (openclaw)      │
                              │    Pi 代理      │
                              └─────────────────┘
```

若您將個人 WhatsApp 連結到 OpenClaw，發給您的每則訊息都會變成「代理輸入」。這很少是您想要的。

## 5 分鐘快速開始

1. 配對 WhatsApp Web（顯示 QR；用助理手機掃描）：

```bash
openclaw channels login
```

2. 啟動 Gateway（保持執行）：

```bash
openclaw gateway --port 18789
```

3. 在 `~/.openclaw/openclaw.json` 中放入最小配置：

```json5
{
  channels: { whatsapp: { allowFrom: ["+15555550123"] } },
}
```

現在從您已核准的手機訊息助理號碼。

入門完成後，我們會自動開啟儀表板並顯示令牌化連結。稍後重新開啟：`openclaw dashboard`。

## 給代理程式一個工作區（AGENTS）

OpenClaw 從工作區目錄讀取操作指令和「記憶」。

根據預設，OpenClaw 使用 `~/.openclaw/workspace` 作為代理工作區，並在設定/首次代理執行時自動建立它（加上起始 `AGENTS.md`、`SOUL.md`、`TOOLS.md`、`IDENTITY.md`、`USER.md`）。`BOOTSTRAP.md` 僅在工作區全新時建立（您刪除後不應返回）。

提示：將此資料夾視為 OpenClaw 的「記憶」並使其成為 git 儲存庫（最好是私有的），以便備份 `AGENTS.md` + 記憶檔案。如果已安裝 git，全新工作區會自動初始化。

```bash
openclaw setup
```

完整工作區佈局 + 備份指南：[Agent 工作區](/concepts/agent-workspace)
記憶工作流：[記憶](/concepts/memory)

選用：使用 `agents.defaults.workspace` 選擇不同工作區（支援 `~`）。

```json5
{
  agent: {
    workspace: "~/.openclaw/workspace",
  },
}
```

若您已從儲存庫提供自己的工作區檔案，可以完全停用引導檔案建立：

```json5
{
  agent: {
    skipBootstrap: true,
  },
}
```

## 將其轉變為「助理」的配置

OpenClaw 預設為良好的助理設定，但您通常會想調整：

- `SOUL.md` 中的人格/指令
- 思考預設值（若需要）
- 心跳（一旦您信任它）

範例：

```json5
{
  logging: { level: "info" },
  agent: {
    model: "anthropic/claude-opus-4-5",
    workspace: "~/.openclaw/workspace",
    thinkingDefault: "high",
    timeoutSeconds: 1800,
    // 從 0 開始；稍後啟用。
    heartbeat: { every: "0m" },
  },
  channels: {
    whatsapp: {
      allowFrom: ["+15555550123"],
      groups: {
        "*": { requireMention: true },
      },
    },
  },
  routing: {
    groupChat: {
      mentionPatterns: ["@openclaw", "openclaw"],
    },
  },
  session: {
    scope: "per-sender",
    resetTriggers: ["/new", "/reset"],
    reset: {
      mode: "daily",
      atHour: 4,
      idleMinutes: 10080,
    },
  },
}
```

## 會話和記憶

- 會話檔案：`~/.openclaw/agents/<agentId>/sessions/{{SessionId}}.jsonl`
- 會話中繼資料（令牌使用、最後路由等）：`~/.openclaw/agents/<agentId>/sessions/sessions.json`（舊版：`~/.openclaw/sessions/sessions.json`）
- `/new` 或 `/reset` 為該聊天開始新會話（可透過 `resetTriggers` 設定）。若單獨發送，代理程式會回覆簡短問候以確認重設。
- `/compact [instructions]` 壓縮會話語境並報告剩餘語境預算。

## 心跳（主動模式）

根據預設，OpenClaw 每 30 分鐘執行一次心跳，提示：
`若存在 HEARTBEAT.md（工作區語境），嚴格遵循。不要推斷或重複先前聊天的舊工作。若無需關注，回覆 HEARTBEAT_OK。`
設定 `agents.defaults.heartbeat.every: "0m"` 以停用。

- 若 `HEARTBEAT.md` 存在但有效為空（僅空行和 markdown 標題如 `# 標題`），OpenClaw 跳過心跳執行以節省 API 呼叫。
- 若檔案缺失，心跳仍執行且模型決定要做什麼。
- 若代理程式回覆 `HEARTBEAT_OK`（選用短填充；見 `agents.defaults.heartbeat.ackMaxChars`），OpenClaw 抑制該心跳的出站傳遞。
- 心跳執行完整代理程式轉換 — 較短間隔消耗更多令牌。

```json5
{
  agent: {
    heartbeat: { every: "30m" },
  },
}
```

## 媒體進出

入站附件（圖片/音訊/文件）可透過範本表面化到您的命令：

- `{{MediaPath}}`（本地暫存檔案路徑）
- `{{MediaUrl}}`（虛擬 URL）
- `{{Transcript}}`（若已啟用音訊轉錄）

出站附件來自代理程式：在自己的行上包含 `MEDIA:<path-or-url>`（無空格）。範例：

```
這是螢幕截圖。
MEDIA:https://example.com/screenshot.png
```

OpenClaw 提取這些並將其作為媒體與文字一起傳送。

## 操作檢核清單

```bash
openclaw status          # 本地狀態（認證、會話、佇列事件）
openclaw status --all    # 完整診斷（唯讀、可貼上）
openclaw status --deep   # 新增 Gateway 健康檢查（Telegram + Discord）
openclaw health --json   # Gateway 健康快照（WS）
```

日誌位於 `/tmp/openclaw/`（預設：`openclaw-YYYY-MM-DD.log`）。

## 後續步驟

- WebChat：[WebChat](/web/webchat)
- Gateway 操作：[Gateway 操作手冊](/gateway)
- Cron + 喚醒：[Cron 工作](/automation/cron-jobs)
- macOS 菜單列伴侶：[OpenClaw macOS 應用程式](/platforms/macos)
- iOS 節點應用程式：[iOS 應用程式](/platforms/ios)
- Android 節點應用程式：[Android 應用程式](/platforms/android)
- Windows 狀態：[Windows（WSL2）](/platforms/windows)
- Linux 狀態：[Linux 應用程式](/platforms/linux)
- 安全性：[安全性](/gateway/security)
