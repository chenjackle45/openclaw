---
title: "排程任務 (Cron Jobs)"
summary: "Gateway 排程器的任務排程與喚醒機制"
read_when:
  - 安排背景任務或喚醒時
  - 設定應隨同心跳 (Heartbeats) 執行的自動化流程時
  - 需要在心跳與 Cron 之間做出選擇時
---

# 排程任務 (Gateway 排程器)

> **Cron 還是心跳 (Heartbeat)？** 請參閱 [Cron vs Heartbeat](/automation/cron-vs-heartbeat) 瞭解兩者的適用場景。

Cron 是 Gateway 內建的排程器。它會持久化任務、在正確的時間喚醒 Agent，並可選擇將輸出結果傳回聊天頻道。

如果您想要「每天早上執行某件事」或「在 20 分鐘後提醒 Agent」，Cron 就是您需要的機制。

## 核心重點 (TL;DR)
- Cron 在 **Gateway 內部**執行（而非在模型內部）。
- 任務存放在 `~/.openclaw/cron/`，重啟也不會遺失排程。
- 兩種執行風格：
  - **主會話 (Main session)**：加入一個系統事件，並在下一次心跳時執行。
  - **隔離會話 (Isolated session)**：在獨立的 `cron:<jobId>` 中執行 Agent 輪次，可選擇是否傳送輸出。
- 具備喚醒等級：任務可要求「立即喚醒」或「隨下次心跳啟動」。

## 概念說明

### 任務 (Jobs)
一個 Cron 任務包含：
- **排程 (Schedule)**：何時執行。
- **酬載 (Payload)**：要做什麼。
- **投遞 (Delivery)**（選用）：結果要傳送到哪裡。
- **Agent 綁定**（選用）：在特定 Agent 下執行。

### 排程 (Schedules)
支援三種排程類型：
- `at`：單次執行的時間戳記（支援 ISO 8601，預設視為 UTC）。
- `every`：固定間隔（毫秒）。
- `cron`：標準的 5 欄位 Cron 表達式（可選時區）。

### 主會話執行 vs 隔離執行

#### 主會話任務 (系統事件)
加入一個系統事件並視需求喚醒心跳執行器。
- `wakeMode: "next-heartbeat"` (預設)：等待下一個排程的心跳。
- `wakeMode: "now"`：立即觸發一次心跳執行。
適用於：您希望在日常心跳 Prompt 中加入新語境的情況。

#### 隔離任務 (專屬 Cron 會話)
在 `cron:<jobId>` 的專用會話中執行 Agent。
- 每次執行都是**全新會話**（不會繼承先前的對話語境）。
- 摘要會發送至主會話（標註 `Cron` 標籤）。
- 若 `payload.deliver: true`，輸出會發送至指定的通訊頻道；否則僅供內部檢視。
適用於：頻繁、吵雜或「背景雜事」，不希望干擾主對話紀錄。

## CLI 快速啟動範例

單次提醒（主會話，立即喚醒）：
```bash
openclaw cron add \
  --name "Calendar check" \
  --at "20m" \
  --session main \
  --system-event "下次心跳：檢查行事曆。" \
  --wake now
```

定期隔離任務（投遞至 WhatsApp）：
```bash
openclaw cron add \
  --name "Morning status" \
  --cron "0 7 * * *" \
  --tz "Asia/Taipei" \
  --session isolated \
  --message "摘要今天的所有收件匣與行事曆任務。" \
  --deliver \
  --channel whatsapp \
  --to "+886912345678"
```

定期隔離任務（投遞至 Telegram 指定話題）：
```bash
openclaw cron add \
  --name "Nightly summary" \
  --cron "0 22 * * *" \
  --tz "Asia/Taipei" \
  --session isolated \
  --message "摘要今日內容；發送至夜間話題。" \
  --deliver \
  --channel telegram \
  --to "-1001234567890:topic:123"
```

## 故障排除

### 「任務完全沒執行」
- 檢查 Cron 是否已啟用：查看配置 `cron.enabled` 或環境變數 `OPENCLAW_SKIP_CRON`。
- 確保 Gateway 持續執行中（Cron 執行於 Gateway 進程內）。
- 對於 `cron` 排程：確認時區 (`--tz`) 設定是否正確。

### Telegram 投遞到錯誤的位置
- 對於討論群組話題，請使用 `-100…:topic:<id>` 格式，確保 ID 顯式且無歧義。
