---
summary: "選擇 Heartbeat 和 Cron 工作的指導"
read_when:
  - Deciding how to schedule recurring tasks
  - Setting up background monitoring or notifications
  - Optimizing token usage for periodic checks
title: "Cron vs Heartbeat（Cron 對比 Heartbeat）"
---

# Cron vs Heartbeat: 何時使用各自

Heartbeat 和 Cron 工作都讓您可以按排程執行工作。本指南幫助您為您的使用案例選擇正確的機制。

## 快速決策指南

| 使用案例                     | 推薦                | 理由                       |
| ---------------------------- | ------------------- | -------------------------- |
| 每 30 分鐘檢查收件匣         | Heartbeat           | 批次與其他檢查、內容感知   |
| 每天上午 9 點發送報告        | Cron (isolated)     | 需要精確時間               |
| 監控日曆以取得即將到來的事件 | Heartbeat           | 定期感知的自然適配         |
| 執行每週深度分析             | Cron (isolated)     | 獨立工作，可使用不同的模型 |
| 20 分鐘後提醒我              | Cron (main, `--at`) | 單次精確時間               |
| 背景項目健康檢查             | Heartbeat           | 搭載現有週期               |

## Heartbeat：定期感知

Heartbeat 在**主 session**定期執行（預設：30 分鐘）。它們旨在讓代理程式檢查事務並表面任何重要的事項。

### 何時使用 heartbeat

- **多個定期檢查**：代替 5 個分別檢查收件匣、日曆、天氣、通知和項目狀態的 cron 工作，單個 heartbeat 可以批次所有這些。
- **內容感知決策**：代理程式具有完整的主 session 內容，因此可以對什麼是緊急的、什麼可以等待做出聰慧決策。
- **交談連續性**：Heartbeat 執行共用同一 session，所以代理程式會記住最近的對話，並可以自然地跟進。
- **低開銷監控**：一個 heartbeat 取代許多小輪詢工作。

### Heartbeat 優點

- **批次多個檢查**：一個代理程式回合可以一起檢查收件匣、日曆和通知。
- **減少 API 呼叫**：單個 heartbeat 比 5 個隔離 cron 工作便宜。
- **內容感知**：代理程式知道您一直在處理的內容，並可以相應地優先處理。
- **聰慧禁止**：如果不需要關注，代理程式會回覆 `HEARTBEAT_OK`，不會傳遞訊息。
- **自然時序**：根據佇列負載略微漂移，這對大多數監控來說是可以的。

### Heartbeat 範例：HEARTBEAT.md 檢查清單

\`\`\`md

# Heartbeat checklist

- 檢查電子郵件以取得緊急訊息
- 檢查日曆以查看後 2 小時的事件
- 如果背景工作完成，摘要結果
- 如果空閒 8 小時以上，傳送簡短檢查
  \`\`\`

代理程式在每個 heartbeat 上讀取此內容並在一次回合中處理所有項目。

### 設定 Heartbeat

\`\`\`json5
{
agents: {
defaults: {
heartbeat: {
every: "30m", // interval
target: "last", // explicit alert delivery target (default is "none")
activeHours: { start: "08:00", end: "22:00" }, // optional
},
},
},
}
\`\`\`

請參閱 [Heartbeat](/zh-Hant/gateway/heartbeat) 以取得完整設定。

## Cron：精確排程

Cron 工作在精確時間執行，並可在隔離 session 中執行，而不影響主內容。
循環整點排程會自動由確定性的按工作偏移在 0-5 分鐘視窗中分散。

### 何時使用 cron

- **需要精確時間**：「每個星期一上午 9:00 發送此」（不是「大約 9 點某時」）。
- **獨立工作**：不需要交談內容的工作。
- **不同的模型/思考**：值得更強大模型的重型分析。
- **一次性提醒**：「20 分鐘後提醒我」搭配 `--at`。
- **嘈雜/頻繁的工作**：會混亂主 session 歷記錄的工作。
- **外部觸發器**：應獨立執行的工作，無論代理程式是否以其他方式活躍。

### Cron 優點

- **精確時序**：5 欄位或 6 欄位（秒）cron 運算式搭配時區支援。
- **內建負載分散**：循環整點排程預設會錯開最多 5 分鐘。
- **按工作控制**：使用 `--stagger <duration>` 覆蓋錯開或使用 `--exact` 強制精確時序。
- **Session 隔離**：在 `cron:<jobId>` 中執行，無需污染主歷記錄。
- **模型覆蓋**：為每個工作使用更便宜或更強大的模型。
- **傳遞控制**：隔離工作預設為 `announce`（摘要）；視需要選擇 `none`。
- **立即傳遞**：宣告模式直接發佈，無需等待 heartbeat。
- **不需要代理程式內容**：即使主 session 閒置或壓縮也執行。
- **一次性支援**：`--at` 用於精確的將來時間戳記。

### Cron 範例：每日早晨簡報

\`\`\`bash
openclaw cron add \
 --name "Morning briefing" \
 --cron "0 7 \* \* \*" \
 --tz "America/New_York" \
 --session isolated \
 --message "Generate today's briefing: weather, calendar, top emails, news summary." \
 --model opus \
 --announce \
 --channel whatsapp \
 --to "+15551234567"
\`\`\`

這在紐約時間上午 7:00 精確執行，使用 Opus 以取得品質，並直接向 WhatsApp 宣告摘要。

### Cron 範例：一次性提醒

\`\`\`bash
openclaw cron add \
 --name "Meeting reminder" \
 --at "20m" \
 --session main \
 --system-event "Reminder: standup meeting starts in 10 minutes." \
 --wake now \
 --delete-after-run
\`\`\`

請參閱 [Cron jobs](/zh-Hant/automation/cron-jobs) 以取得完整 CLI 參考。

## 決策流程圖

\`\`\`
工作是否需要在精確時間執行？
YES -> 使用 cron
NO -> 繼續...

工作是否需要與主 session 隔離？
YES -> 使用 cron (isolated)
NO -> 繼續...

此工作是否可與其他定期檢查批次？
YES -> 使用 heartbeat (新增至 HEARTBEAT.md)
NO -> 使用 cron

這是一次性提醒嗎？
YES -> 使用 cron 搭配 --at
NO -> 繼續...

它是否需要不同的模型或思考層級？
YES -> 使用 cron (isolated) 搭配 --model/--thinking
NO -> 使用 heartbeat
\`\`\`

## 結合兩者

最有效的設定使用**兩者**：

1. **Heartbeat** 每 30 分鐘批次一次回合處理常規監控（收件匣、日曆、通知）。
2. **Cron** 處理精確排程（每日報告、每週檢查）和一次性提醒。

### 範例：有效自動化設定

**HEARTBEAT.md**（每 30 分鐘檢查一次）：

\`\`\`md

# Heartbeat checklist

- 掃描收件匣中的緊急電子郵件
- 檢查日曆以查看後 2h 的事件
- 檢查任何待處理的工作
- 如果安靜 8 小時以上，進行輕量級檢查
  \`\`\`

**Cron 工作**（精確時序）：

\`\`\`bash

# 每天上午 7 點的早晨簡報

openclaw cron add --name "Morning brief" --cron "0 7 \* \* \*" --session isolated --message "..." --announce

# 星期一上午 9 點的每週項目檢查

openclaw cron add --name "Weekly review" --cron "0 9 \* \* 1" --session isolated --message "..." --model opus

# 一次性提醒

openclaw cron add --name "Call back" --at "2h" --session main --system-event "Call back the client" --wake now
\`\`\`

## Lobster：具有核准的確定性工作流程

Lobster 是需要確定性執行和明確核准的**多步驟工具管線**的工作流程執行時間。
當工作超過單個代理程式回合，並且您想要具有人工檢查點的可恢復工作流程時，請使用它。

### 何時 Lobster 適配

- **多步驟自動化**：您需要工具呼叫的固定管線，而不是一次性提示。
- **核准大門**：副作用應暫停直到您核准，然後繼續。
- **可恢復執行**：繼續暫停的工作流程，無需重新執行早期步驟。

### 它如何與 heartbeat 和 cron 配對

- **Heartbeat/cron** 決定*何時*執行發生。
- **Lobster** 定義*什麼步驟*在執行開始一次發生。

對於排定的工作流程，使用 cron 或 heartbeat 觸發呼叫 Lobster 的代理程式回合。
對於臨時工作流程，直接呼叫 Lobster。

### 操作備註（來自程式碼）

- Lobster 執行為**本地子程序**（`lobster` CLI）在工具模式中，並傳回**JSON 信封**。
- 如果工具傳回 `needs_approval`，您使用 `resumeToken` 和 `approve` 旗標恢復。
- 工具是**選用外掛程式**；經由 `tools.alsoAllow: ["lobster"]` 附加地啟用（推薦）。
- Lobster 預期 `lobster` CLI 在 `PATH` 上可用。

請參閱 [Lobster](/zh-Hant/tools/lobster) 以取得完整使用和範例。

## Main Session 對比 Isolated Session

Heartbeat 和 cron 都可以與主 session 互動，但以不同方式：

|         | Heartbeat                  | Cron (main)           | Cron (isolated)                    |
| ------- | -------------------------- | --------------------- | ---------------------------------- |
| Session | Main                       | Main（經由系統事件）  | `cron:<jobId>` 或自訂 session      |
| 歷史    | 共用                       | 共用                  | 每次執行新鮮（隔離）/ 持久（自訂） |
| 內容    | 完整                       | 完整                  | 無（隔離）/ 累積（自訂）           |
| 模型    | Main session 模型          | Main session 模型     | 可覆蓋                             |
| 輸出    | 在未 `HEARTBEAT_OK` 時傳遞 | Heartbeat 提示 + 事件 | 宣告摘要（預設）                   |

### 何時使用主 session cron

當您想要以下情況時，使用 `--session main` 搭配 `--system-event`：

- 提醒/事件出現在主 session 內容中
- 代理程式在下一個 heartbeat 期間使用完整內容處理它
- 無單獨隔離執行

\`\`\`bash
openclaw cron add \
 --name "Check project" \
 --every "4h" \
 --session main \
 --system-event "Time for a project health check" \
 --wake now
\`\`\`

### 何時使用隔離 cron

當您想要以下情況時，使用 `--session isolated`：

- 沒有先前內容的乾淨平板電腦
- 不同的模型或思考設定
- 直接向頻道宣告摘要
- 不會混亂主 session 歷記錄的歷史

\`\`\`bash
openclaw cron add \
 --name "Deep analysis" \
 --cron "0 6 \* \* 0" \
 --session isolated \
 --message "Weekly codebase analysis..." \
 --model opus \
 --thinking high \
 --announce
\`\`\`

## 成本考量

| 機制            | 成本設定檔                                     |
| --------------- | ---------------------------------------------- |
| Heartbeat       | 每 N 分鐘一次回合；隨著 HEARTBEAT.md 大小縮放  |
| Cron (main)     | 新增事件至下次 heartbeat（無隔離回合）         |
| Cron (isolated) | 每個工作的完整代理程式回合；可使用更便宜的模型 |

**秘訣**：

- 保持 `HEARTBEAT.md` 較小以最小化權杖開銷。
- 將類似檢查批次至 heartbeat，而不是多個 cron 工作。
- 如果您只想要內部處理，對 heartbeat 使用 `target: "none"`。
- 對常規工作使用隔離 cron 搭配更便宜的模型。

## 相關

- [Heartbeat](/zh-Hant/gateway/heartbeat) - 完整 heartbeat 設定
- [Cron jobs](/zh-Hant/automation/cron-jobs) - 完整 cron CLI 和 API 參考
- [System](/zh-Hant/cli/system) - 系統事件 + heartbeat 控制
