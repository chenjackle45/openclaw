---
summary: "/think + /verbose 的指令語法以及它們如何影響模型推理"
read_when:
  - 調整 thinking 或 verbose 指令解析或預設值
title: "Thinking Levels（Thinking 級別）"
---

# Thinking 級別（/think 指令）

## 什麼作用

- 內聯指令在任何入站主體中：`/t <level>`、`/think:<level>` 或 `/thinking <level>`。
- 級別（別名）：`off | minimal | low | medium | high | xhigh`（僅 GPT-5.2 + Codex 模型）
  - minimal → "think"
  - low → "think hard"
  - medium → "think harder"
  - high → "ultrathink"（最大預算）
  - xhigh → "ultrathink+"（僅 GPT-5.2 + Codex 模型）
  - `x-high`、`x_high`、`extra-high`、`extra high` 和 `extra_high` 對應到 `xhigh`。
  - `highest`、`max` 對應到 `high`。
- 提供者注意：
  - Z.AI（`zai/*`）只支援二進位 thinking（`on`/`off`）。任何非 `off` 級別被視為 `on`（對應到 `low`）。

## 解析順序

1. 訊息上的內聯指令（只套用到該訊息）。
2. Session 覆蓋（透過傳送僅含指令的訊息設定）。
3. 全域預設（配置中的 `agents.defaults.thinkingDefault`）。
4. 後備：推理能力強的模型為 low；否則 off。

## 設定 session 預設

- 傳送**只有**指令的訊息（允許空格），例如 `/think:medium` 或 `/t high`。
- 該設定適用於目前 session（預設按發送者）；透過 `/think:off` 或 session 空閒重置清除。
- 回覆確認被傳送（`Thinking level set to high.` / `Thinking disabled.`）。若級別無效（例如 `/thinking big`），指令被拒絕並有提示，session 狀態保持不變。
- 傳送 `/think`（或 `/think:`）無參數以查看目前 thinking 級別。

## 代理應用

- **嵌入式 Pi**：解析的級別被傳遞到流程中 Pi 代理執行時。

## Verbose 指令（/verbose 或 /v）

- 級別：`on`（最少） | `full` | `off`（預設）。
- 僅指令訊息切換 session verbose 並回覆 `Verbose logging enabled.` / `Verbose logging disabled.`；無效級別返回提示而不改變狀態。
- `/verbose off` 儲存明確的 session 覆蓋；透過 Sessions UI 清除它，選擇 `inherit`。
- 內聯指令只影響該訊息；否則套用 session/全域預設。
- 傳送 `/verbose`（或 `/verbose:`）無參數以查看目前 verbose 級別。
- 當 verbose 開啟時，發出結構化工具結果的代理（Pi、其他 JSON 代理）將每個工具呼叫作為自己的元數據專用訊息傳回，加上 `<emoji> <tool-name>: <arg>` 前綴當可用時（路徑/指令）。這些工具摘要在每個工具啟動時立即傳送（分開的氣泡），不是串流增量。
- 當 verbose 是 `full` 時，工具輸出也在完成後轉發（分開的氣泡，截斷至安全長度）。若你在執行中改變 `/verbose on|full|off`，後續工具氣泡遵循新設定。

## 推理可見性（/reasoning）

- 級別：`on|off|stream`。
- 僅指令訊息切換是否在回覆中顯示 thinking 區塊。
- 啟用時，推理作為**分開的訊息**被傳送，加上 `Reasoning:` 前綴。
- `stream`（僅 Telegram）：在 Telegram 草稿氣泡中串流推理，同時回覆生成，然後傳送最終回答而不推理。
- 別名：`/reason`。
- 傳送 `/reasoning`（或 `/reasoning:`）無參數以查看目前推理級別。

## 相關

- Elevated mode 文件位於 [Elevated mode](/zh-Hant/tools/elevated)。

## Heartbeat

- Heartbeat 探測主體是配置的 heartbeat 提示（預設：`Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`）。Heartbeat 訊息中的內聯指令照常套用（但避免從 heartbeat 改變 session 預設）。
- Heartbeat 傳遞預設為僅最終負載。若也要傳送分開的 `Reasoning:` 訊息（當可用時），設定 `agents.defaults.heartbeat.includeReasoning: true` 或每個代理 `agents.list[].heartbeat.includeReasoning: true`。

## Web 聊天 UI

- Web 聊天 thinking 選擇器在頁面載入時反映 session 的儲存級別，從入站 session 存儲/配置。
- 選擇另一個級別只套用到下一條訊息（`thinkingOnce`）；傳送後，選擇器快速回到儲存的 session 級別。
- 若要變更 session 預設，傳送 `/think:<level>` 指令（如前所述）；選擇器將在下一次重載後反映它。
