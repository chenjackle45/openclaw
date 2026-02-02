---
title: "Cron vs Heartbeat"
summary: "為自動化選擇心跳和 Cron 任務的指引"
read_when:
  - 決定如何排程定期任務時
  - 設定背景監控或通知時
  - 為定期檢查優化 Token 使用時
---

# Cron vs Heartbeat：何時使用各自

心跳和 Cron 任務都讓您定期執行任務。本指南幫您為您的使用案例選擇正確的機制。

## 快速決策指南

| 使用案例 | 推薦 | 原因 |
| ---- | ---- | ---- |
| 每 30 分鐘檢查收件匣 | Heartbeat | 與其他檢查批次化，具備語境意識 |
| 每天早上 9 點準時發送報告 | Cron (隔離) | 需要精確時間 |
| 監控日曆中的即將到來事件 | Heartbeat | 週期性覺察的自然適配 |
| 執行每週深度分析 | Cron (隔離) | 獨立任務，可使用不同模型 |
| 20 分鐘後提醒我 | Cron (main, `--at`) | 一次性精確時間 |
| 背景專案健康檢查 | Heartbeat | 依附於現有週期 |

## Heartbeat：週期性覺察

Heartbeats 在**主會話**以常規間隔（預設：30 分鐘）執行。它們設計用於 Agent 檢查事項並表面任何重要的內容。

### 何時使用 Heartbeat

- **多個週期檢查**：與其設定 5 個分開的 Cron 任務檢查收件匣、日曆、天氣、通知和專案狀態，一個 Heartbeat 可以批次所有這些。
- **語境覺察決策**：Agent 有完整的主會話語境，所以可以做出聰慧決策，關於什麼是緊急 vs 什麼可以等待。
- **對話連續性**：Heartbeat 執行共享相同會話，所以 Agent 記得最近的對話並可以自然地跟進。
- **低開銷監控**：一個 Heartbeat 取代許多小型輪詢任務。

### Heartbeat 優勢

- **批次多個檢查**：一次 Agent 輪次可審查收件匣、日曆和通知。
- **減少 API 呼叫**：一個 Heartbeat 比 5 個隔離 Cron 任務便宜。
- **語境覺察**：Agent 知道您在做什麼，可以相應地優先考慮。
- **智慧抑制**：若沒有需要注意的東西，Agent 回覆 `HEARTBEAT_OK` 且沒有訊息被投遞。
- **自然時間**：基於佇列負載稍微漂移，這對大多數監控都很好。

### Heartbeat 範例：HEARTBEAT.md 檢查清單

```md
# Heartbeat 檢查清單

- 檢查電郵的緊急訊息
- 檢閱下一個 2 小時內的日曆事件
- 若背景任務完成，摘要結果
- 若閒置 8+ 小時，傳送簡短檢查
```

Agent 在每次 Heartbeat 時讀取此內容並在一個輪次中處理所有項目。

### 配置 Heartbeat

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m", // interval
        target: "last", // where to deliver alerts
        activeHours: { start: "08:00", end: "22:00" }, // optional
      },
    },
  },
}
```

見 [Heartbeat](/gateway/heartbeat) 瞭解完整配置。

## Cron：精確排程

Cron 任務在**精確時間**執行，可在隔離會話中執行而不影響主語境。

### 何時使用 Cron

- **精確時間必要**：「每週一早上 9:00 AM 傳送」（不是「9 點前後某時」）。
- **獨立任務**：不需要對話語境的任務。
- **不同模型/思考**：重量級分析值得更強大的模型。
- **一次性提醒**：「提醒我在 20 分鐘」搭配 `--at`。
- **嘈雜/頻繁任務**：不應充斥主會話歷史的任務。
- **外部觸發**：應獨立於 Agent 是否活躍執行的任務。

### Cron 優勢

- **精確時間**：5 欄位 Cron 表達式搭配時區支援。
- **會話隔離**：在 `cron:<jobId>` 中執行而不污染主歷史。
- **模型覆寫**：每項任務使用更便宜或更強大的模型。
- **投遞控制**：可直接投遞至頻道；仍預設發佈摘要至主（可配置）。
- **不需 Agent 語境**：即使主會話閒置或壓縮時執行。
- **一次性支援**：`--at` 用於精確未來時間戳記。

### Cron 範例：每日早晨簡報

```bash
openclaw cron add \
  --name "Morning briefing" \
  --cron "0 7 * * *" \
  --tz "America/New_York" \
  --session isolated \
  --message "Generate today's briefing: weather, calendar, top emails, news summary." \
  --model opus \
  --deliver \
  --channel whatsapp \
  --to "+15551234567"
```

這在紐約時間早上 7:00 精確執行，使用 Opus 表示質量，並直接投遞至 WhatsApp。

### Cron 範例：一次性提醒

```bash
openclaw cron add \
  --name "Meeting reminder" \
  --at "20m" \
  --session main \
  --system-event "Reminder: standup meeting starts in 10 minutes." \
  --wake now \
  --delete-after-run
```

見 [Cron jobs](/automation/cron-jobs) 瞭解完整 CLI 參考。

## 決策流程圖

```
任務需要在確切時間執行嗎？
  是 -> 使用 Cron
  否 -> 繼續...

任務需要與主會話隔離嗎？
  是 -> 使用 Cron (隔離)
  否 -> 繼續...

任務可與其他週期檢查批次化嗎？
  是 -> 使用 Heartbeat (加到 HEARTBEAT.md)
  否 -> 使用 Cron

這是一次性提醒嗎？
  是 -> 使用 Cron with --at
  否 -> 繼續...

它需要不同模型或思考等級嗎？
  是 -> 使用 Cron (隔離) with --model/--thinking
  否 -> 使用 Heartbeat
```

## 合併兩者

最有效的設定使用**兩者**：

1. **Heartbeat** 每 30 分鐘處理例行監控（收件匣、日曆、通知）在一個批次輪次。
2. **Cron** 處理精確排程（每日報告、每週檢查）和一次性提醒。

### 範例：有效的自動化設定

**HEARTBEAT.md** (每 30 分鐘檢查)：

```md
# Heartbeat 檢查清單

- 掃描收件匣尋找緊急電郵
- 檢查日曆中下一個 2 小時的事件
- 檢閱任何掛起的任務
- 若安靜 8+ 小時則輕檢查
```

**Cron 任務** (精確時間)：

```bash
# 每天早上 7 點的每日簡報
openclaw cron add --name "Morning brief" --cron "0 7 * * *" --session isolated --message "..." --deliver

# 週一早上 9 點的每週檢查
openclaw cron add --name "Weekly review" --cron "0 9 * * 1" --session isolated --message "..." --model opus

# 一次性提醒
openclaw cron add --name "Call back" --at "2h" --session main --system-event "Call back the client" --wake now
```

## Lobster：具有核准的決定性工作流

Lobster 是**多步工具管道**的工作流執行時，需要決定性執行和明確核准。當任務多於單個 Agent 輪次，且您想要有人工檢查點的可恢復工作流時，使用它。

### 何時 Lobster 適配

- **多步自動化**：您需要固定工具呼叫管道，不是一次性提示。
- **核准閘門**：副作用應暫停直到您核准，然後繼續。
- **可恢復執行**：繼續暫停的工作流而不重新執行先前的步驟。

### 它如何與 Heartbeat 和 Cron 配對

- **Heartbeat/Cron** 決定**何時**執行發生。
- **Lobster** 定義**哪些步驟**在執行啟動時發生。

對於排程的工作流，使用 Cron 或 Heartbeat 觸發呼叫 Lobster 的 Agent 輪次。對於臨時工作流，直接呼叫 Lobster。

### 操作筆記（來自程式碼）

- Lobster 執行為**本地子程序**（`lobster` CLI）在工具模式中，返回 **JSON 信封**。
- 若工具返回 `needs_approval`，使用 `resumeToken` 和 `approve` 旗標恢復。
- 工具是**選用外掛**；透過 `tools.alsoAllow: ["lobster"]` 附加啟用（推薦）。
- 若您傳送 `lobsterPath`，它必須是**絕對路徑**。

見 [Lobster](/tools/lobster) 瞭解完整用法和範例。

## 主會話 vs 隔離會話

Heartbeat 和 Cron 都可與主會話互動，但方式不同：

| | Heartbeat | Cron (main) | Cron (隔離) |
| -- | -- | -- | -- |
| 會話 | Main | Main (via system event) | `cron:<jobId>` |
| 歷史 | 共享 | 共享 | 每次執行新 |
| 語境 | 完整 | 完整 | 無（乾淨啟動） |
| 模型 | 主會話模型 | 主會話模型 | 可覆寫 |
| 輸出 | 若非 `HEARTBEAT_OK` 則投遞 | Heartbeat prompt + 事件 | 摘要發佈至主 |

### 何時使用主會話 Cron

使用 `--session main` 搭配 `--system-event` 當您想要：

- 提醒/事件出現在主會話語境中
- Agent 在下次心跳期間以完整語境處理它
- 無分開隔離執行

```bash
openclaw cron add \
  --name "Check project" \
  --every "4h" \
  --session main \
  --system-event "Time for a project health check" \
  --wake now
```

### 何時使用隔離 Cron

使用 `--session isolated` 當您想要：

- 乾淨的盤子而無先前語境
- 不同的模型或思考設定
- 輸出直接投遞至頻道（摘要仍預設發佈至主）
- 不充斥主會話的歷史

```bash
openclaw cron add \
  --name "Deep analysis" \
  --cron "0 6 * * 0" \
  --session isolated \
  --message "Weekly codebase analysis..." \
  --model opus \
  --thinking high \
  --deliver
```

## 成本考量

| 機制 | 成本表現 |
| -- | -- |
| Heartbeat | 每 N 分鐘一個輪次；隨 HEARTBEAT.md 大小擴展 |
| Cron (main) | 新增事件至下次心跳（無隔離輪次） |
| Cron (隔離) | 每項任務完整 Agent 輪次；可使用更便宜模型 |

**提示**：

- 保持 `HEARTBEAT.md` 小以最小化 Token 開銷。
- 將類似檢查批次到 Heartbeat 而非多個 Cron 任務。
- 若僅想內部處理，使用 `target: "none"` 在 Heartbeat。
- 對常規任務使用隔離 Cron 搭配更便宜模型。

## 相關

- [Heartbeat](/gateway/heartbeat) - 完整 Heartbeat 配置
- [Cron jobs](/automation/cron-jobs) - 完整 Cron CLI 和 API 參考
- [System](/cli/system) - 系統事件 + Heartbeat 控制
