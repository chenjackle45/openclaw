---
title: "Thinking(思考層級)"
summary: "/think + /verbose 指令語法及其對模型推理的影響"
read_when:
  - 調整 Thinking 或 Verbose 指令解析或預設值
---
# 思考層級 (/think 指令)

## 功能說明
- 在任何 Inbound Body 中的 Inline 指令：`/t <level>`、`/think:<level>` 或 `/thinking <level>`。
- 層級（別名）：`off | minimal | low | medium | high | xhigh`（僅限 GPT-5.2 + Codex 模型）
  - minimal → "think"
  - low → "think hard"
  - medium → "think harder"
  - high → "ultrathink"（最大預算）
  - xhigh → "ultrathink+"（僅限 GPT-5.2 + Codex 模型）
  - `highest`、`max` 對應至 `high`。
- Provider 注意事項：
  - Z.AI (`zai/*`) 僅支援二進位思考（`on`/`off`）。任何非 `off` 的層級都會被視為 `on`（對應至 `low`）。

## 解析順序
1. 訊息上的 Inline 指令（僅適用於該訊息）。
2. Session Override（透過傳送僅含指令的訊息設定）。
3. 全域預設值（Config 中的 `agents.defaults.thinkingDefault`）。
4. Fallback：具推理能力模型使用 low；否則為 off。

## 設定 Session 預設值
- 傳送**僅含**指令的訊息（允許空白），例如 `/think:medium` 或 `/t high`。
- 該設定會持續到目前 Session（預設依 Sender 區分）；透過 `/think:off` 或 Session Idle Reset 清除。
- 確認回覆會傳送（`Thinking level set to high.` / `Thinking disabled.`）。如果層級無效（例如 `/thinking big`），指令會被拒絕並給予提示，Session 狀態維持不變。
- 傳送 `/think`（或 `/think:`）不帶參數可查看目前思考層級。

## 各 Agent 應用
- **Embedded Pi**：解析的層級會傳遞至 In-process Pi Agent Runtime。

## Verbose 指令 (/verbose 或 /v)
- 層級：`on`（minimal）| `full` | `off`（預設）。
- 僅含指令的訊息會切換 Session Verbose 並回覆 `Verbose logging enabled.` / `Verbose logging disabled.`；無效層級會回傳提示但不改變狀態。
- `/verbose off` 會儲存明確的 Session Override；透過 Sessions UI 選擇 `inherit` 來清除。
- Inline 指令僅影響該訊息；否則套用 Session/Global 預設值。
- 傳送 `/verbose`（或 `/verbose:`）不帶參數可查看目前 Verbose 層級。
- 當 Verbose 開啟時，會輸出 Structured Tool Results 的 Agent（Pi、其他 JSON Agent）會將每個 Tool Call 作為獨立的 Metadata-only 訊息回傳，前綴為 `<emoji> <tool-name>: <arg>`（如有路徑/指令）。這些 Tool 摘要在每個 Tool 開始時立即傳送（獨立 Bubble），而非 Streaming Deltas。
- 當 Verbose 為 `full` 時，Tool 輸出也會在完成後轉發（獨立 Bubble，截斷至安全長度）。如果在 Run 進行中切換 `/verbose on|full|off`，後續 Tool Bubble 會遵循新設定。

## 推理可見性 (/reasoning)
- 層級：`on|off|stream`。
- 僅含指令的訊息會切換 Thinking Blocks 是否在回覆中顯示。
- 啟用時，推理會作為**獨立訊息**傳送，前綴為 `Reasoning:`。
- `stream`（僅限 Telegram）：在回覆生成時將推理串流至 Telegram Draft Bubble，然後傳送不含推理的最終答案。
- 別名：`/reason`。
- 傳送 `/reasoning`（或 `/reasoning:`）不帶參數可查看目前推理層級。

## 相關文件
- Elevated Mode 文件請見 [Elevated mode](/tools/elevated)。

## Heartbeats
- Heartbeat Probe Body 是設定的 Heartbeat Prompt（預設：`Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK.`）。Heartbeat 訊息中的 Inline 指令會如常套用（但避免從 Heartbeat 變更 Session 預設值）。
- Heartbeat 傳遞預設僅包含最終 Payload。若要同時傳送獨立的 `Reasoning:` 訊息（如有），請設定 `agents.defaults.heartbeat.includeReasoning: true` 或 Per-agent `agents.list[].heartbeat.includeReasoning: true`。

## Web Chat UI
- Web Chat 思考選擇器在頁面載入時會鏡射 Inbound Session Store/Config 中儲存的 Session 層級。
- 選擇另一層級僅適用於下一則訊息（`thinkingOnce`）；傳送後，選擇器會回復至儲存的 Session 層級。
- 若要變更 Session 預設值，請傳送 `/think:<level>` 指令（如前）；選擇器會在下次重新載入後反映。
