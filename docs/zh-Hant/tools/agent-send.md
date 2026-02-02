---
summary: "Direct `openclaw agent` CLI runs (with optional delivery)"
read_when:
  - Adding or modifying the agent CLI entrypoint
title: "Agent Send"
---

# `openclaw agent` (direct agent runs)

`openclaw agent` 執行單一 Agent turn，無需內進 chat 訊息。
預設會**透過 Gateway**；新增 `--local` 以強制目前機器上的嵌入式
執行時間。

## 行為

- 必填：`--message <text>`
- Session 選擇：
  - `--to <dest>` 衍生 session key（group/channel 目標保持隔離；direct chat 折疊為 `main`），**或**
  - `--session-id <id>` 透過 id 重用現有 session，**或**
  - `--agent <id>` 直接指定目標 agent（使用該 agent 的 `main` session key）
- 執行與一般內進回覆相同的嵌入式 agent 執行時間。
- Thinking/verbose flags 持續進入 session store。
- 輸出：
  - 預設：列印回覆文字（加上 `MEDIA:<url>` 行）
  - `--json`：列印結構化裝載 + 中繼資料
- 選用透過 `--deliver` + `--channel` 傳遞回 channel（目標格式符合 `openclaw message --target`）。
- 使用 `--reply-channel`/`--reply-to`/`--reply-account` 覆寫傳遞而不變更 session。

如果 Gateway 無法連線，CLI **回退**到嵌入式本機執行。

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

- `--local`：本機執行（需要 shell 中的 model provider API 金鑰）
- `--deliver`：將回覆傳送到所選 channel
- `--channel`：傳遞 channel（`whatsapp|telegram|discord|googlechat|slack|signal|imessage`，預設：`whatsapp`）
- `--reply-to`：傳遞目標覆寫
- `--reply-channel`：傳遞 channel 覆寫
- `--reply-account`：傳遞 account id 覆寫
- `--thinking <off|minimal|low|medium|high|xhigh>`：持續 thinking 層級（僅 GPT-5.2 + Codex 模型）
- `--verbose <on|full|off>`：持續 verbose 層級
- `--timeout <seconds>`：覆寫 agent 逾時
- `--json`：輸出結構化 JSON
