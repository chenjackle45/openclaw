---
title: "Agent send(Agent 指令)"
summary: "直接 `openclaw agent` CLI 執行（含選用傳遞）"
read_when:
  - 新增或修改 Agent CLI 進入點
---
# `openclaw agent`（直接 Agent 執行）

`openclaw agent` 可在不需要 Inbound Chat 訊息的情況下執行單一 Agent Turn。預設情況下會**透過 Gateway**；新增 `--local` 可強制使用目前機器上的 Embedded Runtime。

## 行為

- 必填：`--message <text>`
- Session 選擇：
  - `--to <dest>` 衍生 Session Key（Group/Channel 目標保持隔離；Direct Chat 折疊為 `main`），**或**
  - `--session-id <id>` 透過 ID 重用現有 Session，**或**
  - `--agent <id>` 直接指定目標 Agent（使用該 Agent 的 `main` Session Key）
- 執行與正常 Inbound 回覆相同的 Embedded Agent Runtime。
- Thinking/Verbose Flags 會持續儲存至 Session Store。
- 輸出：
  - 預設：列印回覆文字（加上 `MEDIA:<url>` 行）
  - `--json`：列印結構化 Payload + Metadata
- 選用透過 `--deliver` + `--channel` 將回覆傳遞回 Channel（目標格式與 `openclaw message --target` 相符）。
- 使用 `--reply-channel`/`--reply-to`/`--reply-account` 可覆寫傳遞設定而不改變 Session。

如果無法連接 Gateway，CLI 會**回退**至 Embedded 本機執行。

## 範例

```bash
openclaw agent --to +15555550123 --message "status update"
openclaw agent --agent ops --message "Summarize logs"
openclaw agent --session-id 1234 --message "Summarize inbox" --thinking medium
openclaw agent --to +15555550123 --message "Trace logs" --verbose on --json
openclaw agent --to +15555550123 --message "Summon reply" --deliver
openclaw agent --agent ops --message "Generate report" --deliver --reply-channel slack --reply-to "#reports"
```

## Flags

- `--local`：本機執行（需要 Shell 中有 Model Provider API Keys）
- `--deliver`：將回覆傳送至選定的 Channel
- `--channel`：傳遞 Channel（`whatsapp|telegram|discord|googlechat|slack|signal|imessage`，預設：`whatsapp`）
- `--reply-to`：傳遞目標覆寫
- `--reply-channel`：傳遞 Channel 覆寫
- `--reply-account`：傳遞 Account ID 覆寫
- `--thinking <off|minimal|low|medium|high|xhigh>`：持續 Thinking 層級（僅限 GPT-5.2 + Codex 模型）
- `--verbose <on|full|off>`：持續 Verbose 層級
- `--timeout <seconds>`：覆寫 Agent Timeout
- `--json`：輸出結構化 JSON
