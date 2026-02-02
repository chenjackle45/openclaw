---
summary: "Elevated exec mode and /elevated directives"
read_when:
  - Adjusting elevated mode defaults, allowlists, or slash command behavior
title: "Elevated Mode"
---

# Elevated Mode (/elevated directives)

## 功能

- `/elevated on` 在 gateway host 上執行並保留 exec 核准（與 `/elevated ask` 相同）。
- `/elevated full` 在 gateway host 上執行**並**自動核准 exec（跳過 exec 核准）。
- `/elevated ask` 在 gateway host 上執行但保留 exec 核准（與 `/elevated on` 相同）。
- `on`/`ask` 不**強制** `exec.security=full`；已設定的 security/ask 策略仍適用。
- 只在 Agent 被**沙盒化**時改變行為（否則 exec 已在 host 上執行）。
- 指令形式：`/elevated on|off|ask|full`、`/elev on|off|ask|full`。
- 只接受 `on|off|ask|full`；其他會回傳提示並不改變狀態。

## 控制的內容（以及不控制的內容）

- **可用性門**：`tools.elevated` 是全域基線。`agents.list[].tools.elevated` 可進一步限制每個 agent 的提權（兩者都必須允許）。
- **每個會話狀態**：`/elevated on|off|ask|full` 為目前會話金鑰設定提權層級。
- **內嵌指令**：訊息內的 `/elevated on|ask|full` 僅適用於該訊息。
- **群組**：在群組聊天中，提權指令只有在提及 agent 時才被認可。繞過提及需求的僅指令訊息會被視為已提及。
- **Host 執行**：提權強制 `exec` 到 gateway host；`full` 也設定 `security=full`。
- **核准**：`full` 跳過 exec 核准；`on`/`ask` 在 allowlist/ask 規則需要時認可它們。
- **未沙盒化的 agent**：對位置是 no-op；只影響限制、記錄和狀態。
- **工具策略仍適用**：如果工具策略否定 `exec`，提權無法使用。
- **分開於 `/exec`**：`/exec` 為授權寄件者調整每個會話的預設值，不需要提權。

## 解析順序

1. 訊息上的內嵌指令（只適用於該訊息）。
2. 會話覆寫（透過發送僅指令訊息設定）。
3. 全域預設值（config 中的 `agents.defaults.elevatedDefault`）。

## 設定會話預設值

- 發送**只是**指令的訊息（允許空白），例如 `/elevated full`。
- 確認回覆會被傳送（`Elevated mode set to full...` / `Elevated mode disabled.`）。
- 如果提權存取被停用或寄件者不在批准 allowlist 上，指令會回覆可操作的錯誤且不改變會話狀態。
- 發送 `/elevated`（或 `/elevated:`）無引數以查看目前提權層級。

## 可用性 + allowlists

- 功能門：`tools.elevated.enabled`（預設可透過 config 關閉，即使程式碼支援）。
- 寄件者 allowlist：`tools.elevated.allowFrom` 帶有每個 provider allowlist（例如 `discord`、`whatsapp`）。
- Per-agent 門：`agents.list[].tools.elevated.enabled`（選用；只能進一步限制）。
- Per-agent allowlist：`agents.list[].tools.elevated.allowFrom`（選用；設定時，寄件者必須符合**兩個** global + per-agent allowlist）。
- Discord 回退：如果 `tools.elevated.allowFrom.discord` 被省略，`channels.discord.dm.allowFrom` 列表會作為回退使用。設定 `tools.elevated.allowFrom.discord`（即使 `[]`）以覆寫。Per-agent allowlist 不**使用**回退。
- 所有門都必須通過；否則提權會視為不可用。

## 記錄 + 狀態

- 提權 exec 呼叫在 info 層級記錄。
- 會話狀態包含提權模式（例如 `elevated=ask`、`elevated=full`）。
