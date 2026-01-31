---
title: "Openclaw(建立個人助理 OpenClaw)"
summary: "將 OpenClaw 作為個人助理執行的全方位指南，包含安全警告與建議"
read_when:
  - 正在入門新的助理實例時
  - 檢視權限與安全影響時
---
# 使用 OpenClaw 建立個人助理

OpenClaw 是一個整合了 WhatsApp + Telegram + Discord + iMessage 等頻道的 **Pi** Agent Gateway（插件另可增加 Mattermost）。本指南將引導您進行「個人助理」設定：使用一個專屬的 WhatsApp 號碼，作為您全天候在線的智囊。

## ⚠️ 安全優先

您正將 Agent 置於可以執行以下操作的位置：
- 在您的機器上執行指令（取決於您的工具設定）
- 讀取與寫入工作區檔案
- 透過 WhatsApp/Telegram/Discord/Mattermost 發送訊息

請從保守的設定開始：
- **務必**設定 `channels.whatsapp.allowFrom`（絕不讓您的個人 Mac 對全世界開放）。
- 為助理使用**專屬**的 WhatsApp 號碼。
- 心跳 (Heartbeats) 預設為每 30 分鐘執行一次。在您完全信任設定之前，請先將其停用：`agents.defaults.heartbeat.every: "0m"`。

## 先決條件

- Node **22+**
- 已將 OpenClaw 加入 PATH（推薦全域安裝）
- 用於助理的第二個電話號碼（實體 SIM/eSIM/預付卡皆可）

```bash
npm install -g openclaw@latest
# 或使用: pnpm add -g openclaw@latest
```

## 雙手機設定（強力推薦）

理想的配置如下：

```
您的手機 (個人用)                第二台手機 (助理用)
┌─────────────────┐           ┌─────────────────┐
│  個人 WhatsApp  │  ──────▶  │  助理 WhatsApp  │
│  +1-555-您的號碼 │   發送訊息  │  +1-555-助理號碼 │
└─────────────────┘           └────────┬────────┘
                                       │ 透過 QR Code 連結
                                       ▼
                              ┌─────────────────┐
                              │  您的電腦 (Mac)   │
                              │  (執行 OpenClaw)  │
                              │    Pi Agent     │
                              └─────────────────┘
```

如果您將「個人 WhatsApp」直接連結到 OpenClaw，發給您的**每一則**訊息都會變成 Agent 的輸入，這通常不是您想要的。

## 5 分鐘快速啟動

1) **配對 WhatsApp Web**（終端機會顯示 QR Code，請用「助理手機」掃描）：

```bash
openclaw channels login
```

2) **啟動 Gateway**（保持執行狀態）：

```bash
openclaw gateway --port 18789
```

3) **建立基本配置**於 `~/.openclaw/openclaw.json`：

```json5
{
  channels: { whatsapp: { allowFrom: ["+15555550123"] } }
}
```

現在，從您已核准 (Allowlisted) 的手機發送訊息給助理號碼。

## 給予 Agent 一個工作區 (AGENTS)

OpenClaw 從工作區目錄讀取操作指令與「記憶」。

預設情況下，OpenClaw 使用 `~/.openclaw/workspace` 作為 Agent 工作區。在首次執行時，系統會自動建立此目錄及初始檔案（`AGENTS.md`, `SOUL.md`, `TOOLS.md`, `IDENTITY.md`, `USER.md`）。

**提示**：將此目錄視為 OpenClaw 的「記憶」，建議將其建立為 Git 倉庫（最好是私有的），以便備份。

```bash
openclaw setup
```

## 將其轉化為「助理」的配置

OpenClaw 的預設值已經是相當不錯的助理設定，但您通常會需要調整：
- `SOUL.md` 中的人格特質/指令
- 思考行為預設值
- 信任後啟用的心跳機制

範例配置：

```json5
{
  logging: { level: "info" },
  agent: {
    model: "anthropic/claude-3-5-sonnet",
    workspace: "~/.openclaw/workspace",
    thinkingDefault: "high",
    timeoutSeconds: 1800,
    heartbeat: { every: "0m" } // 初始設為 0，等信任後再開啟
  },
  channels: {
    whatsapp: {
      allowFrom: ["+15555550123"],
      groups: {
        "*": { requireMention: true }
      }
    }
  }
}
```

## 會話與記憶

- **重設會話**：發送 `/new` 或 `/reset` 可為該聊天開啟全新的會話。如果單獨發送此指令，Agent 會回覆短暫的問候以確認重設。
- **壓縮會話**：發送 `/compact [說明]` 可壓縮會話語境。

## 心跳機制 (Proactive mode)

預設情況下，OpenClaw 每 30 分鐘會執行一次心跳偵測，讓 Agent 有機會主動發起任務。
- 如果工作區有 `HEARTBEAT.md`，Agent 會嚴格遵守其中的任務。
- 如果 Agent 回覆 `HEARTBEAT_OK`，OpenClaw 則不會對外發送任何訊息。
- 較短的心跳間隔會消耗更多 Token，請根據需求調整。

## 媒體檔案處理

Agent 接收到的附件（圖片/音訊/文件）可透過模板變數讀取：
- `{{MediaPath}}`：本地暫存路徑
- `{{Transcript}}`：語音轉文字結果

Agent 發送附件：只需在回覆中加入 `MEDIA:<路徑或網址>` 即可。

## 維運檢核

```bash
openclaw status          # 檢查狀態（憑證、會話、隊列）
openclaw status --all    # 完整診斷
openclaw status --deep   # 加入 Gateway 健康偵測 (Telegram + Discord)
```

日誌檔案存放於 `/tmp/openclaw/`。
