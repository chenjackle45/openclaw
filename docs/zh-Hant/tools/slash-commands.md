---
summary: "斜杠命令：文本 vs 原生、配置和支援的命令"
read_when:
  - 使用或配置聊天命令
  - 調試命令路由或權限
title: "Slash Commands（斜線命令）"
---

# 斜杠命令

命令由網關處理。大多數命令必須以 `/` 開頭的 **獨立** 訊息發送。
僅限主機的 bash 聊天命令使用 `! <cmd>`（別名 `/bash <cmd>`）。

有兩個相關系統：

- **命令**：獨立 `/...` 訊息。
- **指令**：`/think`、`/verbose`、`/reasoning`、`/elevated`、`/exec`、`/model`、`/queue`。
  - 指令在模型看到前從訊息中剝離。
  - 在正常聊天訊息中（非僅限指令），它們被視為「內聯提示」，**不會** 持續會話設定。
  - 在僅限指令的訊息中（訊息僅包含指令），它們持續到會話並用認可回覆。
  - 指令僅適用於 **授權寄件者**。如果設定 `commands.allowFrom`，它是唯一使用的許可清單；否則授權來自頻道許可清單/配對加 `commands.useAccessGroups`。
    未授權的寄件者看到指令被視為純文本。

還有幾個 **內聯快速鍵**（僅限許可清單/授權寄件者）：`/help`、`/commands`、`/status`、`/whoami`（`/id`）。
它們立即執行、在模型看到訊息前被剝離，剩餘文本通過正常流繼續。

## 設定

```json5
{
  commands: {
    native: "auto",
    nativeSkills: "auto",
    text: true,
    bash: false,
    bashForegroundMs: 2000,
    config: false,
    debug: false,
    restart: false,
    allowFrom: {
      "*": ["user1"],
      discord: ["user:123"],
    },
    useAccessGroups: true,
  },
}
```

- `commands.text`（預設 `true`）在聊天訊息中啟用 `/...` 解析。
  - 在沒有原生命令的表面（WhatsApp/WebChat/Signal/iMessage/Google Chat/MS Teams），即使你設定 `false`，文本命令仍然有效。
- `commands.native`（預設 `"auto"`）註冊原生命令。
  - 自動：對 Discord/Telegram 為開；對 Slack 為關（直到你新增斜杠命令）；對沒有原生支援的提供商被忽略。
  - 設定 `channels.discord.commands.native`、`channels.telegram.commands.native` 或 `channels.slack.commands.native` 按提供商覆蓋（布林或 `"auto"`）。
  - `false` 在啟動時清除 Discord/Telegram 上以前的已註冊命令。Slack 命令在 Slack 應用中管理，不自動移除。
- `commands.nativeSkills`（預設 `"auto"`）在支援時原生註冊 **技能** 命令。
  - 自動：對 Discord/Telegram 為開；對 Slack 為關（Slack 需要為每個技能建立斜杠命令）。
  - 設定 `channels.discord.commands.nativeSkills`、`channels.telegram.commands.nativeSkills` 或 `channels.slack.commands.nativeSkills` 按提供商覆蓋（布林或 `"auto"`）。
- `commands.bash`（預設 `false`）啟用 `! <cmd>` 執行主機 shell 命令（`/bash <cmd>` 是別名；需要 `tools.elevated` 許可清單）。
- `commands.bashForegroundMs`（預設 `2000`）控制 bash 在切換到後台模式前等待多長時間（`0` 立即後台化）。
- `commands.config`（預設 `false`）啟用 `/config`（讀/寫 `openclaw.json`）。
- `commands.debug`（預設 `false`）啟用 `/debug`（執行時僅覆蓋）。
- `commands.allowFrom`（可選）為命令授權設定每個提供商的許可清單。配置時，它是命令和指令的唯一授權來源（頻道許可清單/配對和 `commands.useAccessGroups` 被忽略）。使用 `"*"` 用於全域預設；提供商特定金鑰覆蓋它。
- `commands.useAccessGroups`（預設 `true`）當未設定 `commands.allowFrom` 時，強制執行命令的許可清單/原則。

## 命令清單

文本加原生（啟用時）：

- `/help`
- `/commands`
- `/skill <name> [input]`（按名稱執行技能）
- `/status`（顯示當前狀態；在可用時為當前模型提供商包含提供商使用量/配額）
- `/allowlist`（列出/新增/移除許可清單項目）
- `/approve <id> allow-once|allow-always|deny`（解決 exec 核准提示）
- `/context [list|detail|json]`（解釋「上下文」；`detail` 顯示每個檔案加每個工具加每個技能加系統提示詞大小）
- `/export-session [path]`（別名：`/export`）（將當前會話匯出為 HTML，含完整系統提示詞）
- `/whoami`（顯示你的寄件者 id；別名：`/id`）
- `/session idle <duration|off>`（管理聚焦線程綁定的非活動自動取消聚焦）
- `/session max-age <duration|off>`（管理聚焦線程綁定的硬最大年齡自動取消聚焦）
- `/subagents list|kill|log|info|send|steer|spawn`（檢查、控制或為當前會話生成子代理執行）
- `/acp spawn|cancel|steer|close|status|set-mode|set|cwd|permissions|timeout|model|reset-options|doctor|install|sessions`（檢查和控制 ACP 執行時會話）
- `/agents`（列出此會話的線程綁定代理）
- `/focus <target>`（Discord：綁定此線程或新線程到會話/子代理目標）
- `/unfocus`（Discord：移除當前線程綁定）
- `/kill <id|#|all>`（立即中止此會話的一個或所有執行中子代理；無確認訊息）
- `/steer <id|#> <message>`（立即操控執行中子代理：在執行時盡可能，否則中止當前工作並在操控訊息上重啟）
- `/tell <id|#> <message>`（`/steer` 的別名）
- `/config show|get|set|unset`（持續配置到磁碟，僅限所有者；需要 `commands.config: true`）
- `/debug show|set|unset|reset`（執行時覆蓋，僅限所有者；需要 `commands.debug: true`）
- `/usage off|tokens|full|cost`（每個回應使用頁腳或本地成本摘要）
- `/tts off|always|inbound|tagged|status|provider|limit|summary|audio`（控制 TTS；查看 [/tts](/zh-Hant/tts)）
  - Discord：原生命令是 `/voice`（Discord 保留 `/tts`）；文本 `/tts` 仍然有效。
- `/stop`
- `/restart`
- `/dock-telegram`（別名：`/dock_telegram`）（切換回覆到 Telegram）
- `/dock-discord`（別名：`/dock_discord`）（切換回覆到 Discord）
- `/dock-slack`（別名：`/dock_slack`）（切換回覆到 Slack）
- `/activation mention|always`（僅限群組）
- `/send on|off|inherit`（僅限所有者）
- `/reset` 或 `/new [model]`（可選模型提示；餘數通過）
- `/think <off|minimal|low|medium|high|xhigh>`（按模型/提供商動態選擇；別名：`/thinking`、`/t`）
- `/verbose on|full|off`（別名：`/v`）
- `/reasoning on|off|stream`（別名：`/reason`；打開時，傳送以 `Reasoning:` 為前綴的單獨訊息；`stream` = Telegram 草稿僅）
- `/elevated on|off|ask|full`（別名：`/elev`；`full` 跳過 exec 核准）
- `/exec host=<sandbox|gateway|node> security=<deny|allowlist|full> ask=<off|on-miss|always> node=<id>`（傳送 `/exec` 以顯示當前）
- `/model <name>`（別名：`/models`；或 `/<alias>` 來自 `agents.defaults.models.*.alias`）
- `/queue <mode>`（加選項如 `debounce:2s cap:25 drop:summarize`；傳送 `/queue` 以查看當前設定）
- `/bash <command>`（僅限主機；`! <command>` 的別名；需要 `commands.bash: true` 加 `tools.elevated` 許可清單）

僅限文本：

- `/compact [instructions]`（查看 [/concepts/compaction](/zh-Hant/concepts/compaction)）
- `! <command>`（僅限主機；一次一個；使用 `!poll` 加 `!stop` 用於長執行工作）
- `!poll`（檢查輸出 / 狀態；接受可選 `sessionId`；`/bash poll` 也有效）
- `!stop`（停止執行中 bash 工作；接受可選 `sessionId`；`/bash stop` 也有效）

注意：

- 命令接受命令和 args 之間的可選 `:`（例如 `/think: high`、`/send: on`、`/help:`）。
- `/new <model>` 接受模型別名、`provider/model` 或提供商名稱（模糊匹配）；如果無匹配，文本被視為訊息體。
- 如需完整提供商使用分解，使用 `openclaw status --usage`。
- `/allowlist add|remove` 需要 `commands.config=true` 並尊重頻道 `configWrites`。
- `/usage` 控制每個回應使用頁腳；`/usage cost` 從 OpenClaw 會話日誌列印本地成本摘要。
- `/restart` 預設啟用；設定 `commands.restart: false` 禁用它。
- 僅 Discord 原生命令：`/vc join|leave|status` 控制語音頻道（需要 `channels.discord.voice` 和原生命令；不作為文本提供）。
- Discord 線程綁定命令（`/focus`、`/unfocus`、`/agents`、`/session idle`、`/session max-age`）需要有效的線程綁定被啟用（`session.threadBindings.enabled` 和/或 `channels.discord.threadBindings.enabled`）。
- ACP 命令參考和執行時行為：[ACP 代理](/zh-Hant/tools/acp-agents)。
- `/verbose` 用於調試和額外可見性；在正常使用中保持 **關閉**。
- 工具失敗摘要仍在相關時顯示，但詳細失敗文本僅在 `/verbose` 是 `on` 或 `full` 時包含。
- `/reasoning`（和 `/verbose`）在群組設定中風險大：它們可能會透露內部推理或你未打算暴露的工具輸出。傾向於保持關閉，特別是在群組聊天中。
- **快速路徑：** 來自許可清單寄件者的僅限命令訊息被立即處理（繞過隊列加模型）。
- **群組提及閘控：** 來自許可清單寄件者的僅限命令訊息繞過提及需求。
- **內聯快速鍵（僅限許可清單寄件者）：** 某些命令也在嵌入正常訊息時有效，並在模型看到剩餘文本前被剝離。
  - 範例：`hey /status` 觸發狀態回覆，剩餘文本通過正常流繼續。
- 目前：`/help`、`/commands`、`/status`、`/whoami`（`/id`）。
- 未授權的僅限命令訊息被無聲忽略，內聯 `/...` 標記被視為純文本。
- **技能命令：** `user-invocable` 技能被公開為斜杠命令。名稱被清理為 `a-z0-9_`（最多 32 個字符）；衝突獲得數字尾碼（例如 `_2`）。
  - `/skill <name> [input]` 按名稱執行技能（當原生命令限制阻止每個技能命令時有用）。
  - 預設情況下，技能命令被轉發到模型作為正常請求。
  - 技能可選擇宣告 `command-dispatch: tool` 將命令直接路由到工具（確定性，無模型）。
  - 範例：`/prose`（OpenProse 外掛）— 查看 [OpenProse](/zh-Hant/prose)。
- **原生命令引數：** Discord 為動態選項使用自動完成（當你省略必需 args 時為按鈕選單）。Telegram 和 Slack 在命令支援選擇且你省略 arg 時顯示按鈕選單。

## 使用表面（什麼顯示在哪裡）

- **提供商使用量/配額**（範例：「Claude 剩餘 80%」）當啟用使用量追蹤時在當前模型提供商的 `/status` 中顯示。
- **每個回應 token/成本** 由 `/usage off|tokens|full`（附加到正常回覆）控制。
- `/model status` 關於 **模型/認證/端點**，非使用量。

## 模型選擇（`/model`）

`/model` 實作為指令。

範例：

```
/model
/model list
/model 3
/model openai/gpt-5.2
/model opus@anthropic:default
/model status
```

注意：

- `/model` 和 `/model list` 顯示緊湊、編號選擇器（模型系列加可用提供商）。
- 在 Discord 上，`/model` 和 `/models` 開啟互動式選擇器，帶提供商和模型下拉加提交步驟。
- `/model <#>` 從該選擇器選擇（並在可能時偏好當前提供商）。
- `/model status` 顯示詳細檢視，包括配置的提供商端點（`baseUrl`）和 API 模式（`api`）（如可用）。

## 調試覆蓋

`/debug` 讓你設定 **執行時僅** 配置覆蓋（記憶體，非磁碟）。僅限所有者。預設禁用；用 `commands.debug: true` 啟用。

範例：

```
/debug show
/debug set messages.responsePrefix="[openclaw]"
/debug set channels.whatsapp.allowFrom=["+1555","+4477"]
/debug unset messages.responsePrefix
/debug reset
```

注意：

- 覆蓋立即適用於新配置讀取，但 **不** 寫到 `openclaw.json`。
- 使用 `/debug reset` 清除所有覆蓋並返回到磁碟配置。

## 設定更新

`/config` 寫到你的磁碟配置（`openclaw.json`）。僅限所有者。預設禁用；用 `commands.config: true` 啟用。

範例：

```
/config show
/config show messages.responsePrefix
/config get messages.responsePrefix
/config set messages.responsePrefix="[openclaw]"
/config unset messages.responsePrefix
```

注意：

- 配置在寫入前被驗證；無效的更改被拒絕。
- `/config` 更新在重啟間持續。

## 表面注意

- **文本命令** 在正常聊天會話中執行（DM 共享 `main`，群組有自己的會話）。
- **原生命令** 使用隔離會話：
  - Discord：`agent:<agentId>:discord:slash:<userId>`
  - Slack：`agent:<agentId>:slack:slash:<userId>`（前綴通過 `channels.slack.slashCommand.sessionPrefix` 可配置）
  - Telegram：`telegram:slash:<userId>`（通過 `CommandTargetSessionKey` 目標聊天會話）
- **`/stop`** 目標活躍聊天會話，所以它可以中止當前執行。
- **Slack：** `channels.slack.slashCommand` 仍然對單個 `/openclaw` 風格命令被支援。如果你啟用 `commands.native`，你必須為每個內建命令建立一個 Slack 斜杠命令（相同名稱作為 `/help`）。Slack 的命令引數選單作為臨時 Block Kit 按鈕傳遞。
  - Slack 原生例外：註冊 `/agentstatus`（不是 `/status`）因為 Slack 保留 `/status`。Slack 訊息中仍然有效文本 `/status`。
