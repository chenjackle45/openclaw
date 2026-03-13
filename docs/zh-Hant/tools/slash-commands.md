---
summary: "斜線命令：文字型與原生型、設定與支援的指令列表"
read_when:
  - 使用或設定聊天指令
  - 除錯指令路由或權限問題
title: "Slash Commands（斜線命令）"
---

# 斜線命令

指令由 Gateway 處理。大多數指令必須以 `/` 開頭的**獨立**訊息傳送。
僅主機的 bash 聊天指令使用 `! <cmd>`（`/bash <cmd>` 為別名）。

有兩個相關的系統：

- **指令**：獨立的 `/...` 訊息。
- **指令集**：`/think`、`/fast`、`/verbose`、`/reasoning`、`/elevated`、`/exec`、`/model`、`/queue`。
  - 指令集在模型看到訊息之前被移除。
  - 在正常聊天訊息中（非指令集專用），它們被視為「行內提示」且**不**保持工作階段設定。
  - 在指令集專用訊息中（訊息僅包含指令集），它們保持到工作階段並回覆確認。
  - 指令集僅適用於**授權傳送者**。如果設定了 `commands.allowFrom`，它是唯一的授權列表；否則授權來自頻道允許列表／配對加上 `commands.useAccessGroups`。
    未授權的傳送者將看到指令集被視為純文字。

還有一些**行內快捷鍵**（僅限授權列表／授權傳送者）：`/help`、`/commands`、`/status`、`/whoami`（`/id`）。
它們立即執行，在模型看到訊息之前被移除，其餘文字繼續通過正常流程。

## 設定

\`\`\`json5
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
"\*": ["user1"],
discord: ["user:123"],
},
useAccessGroups: true,
},
}
\`\`\`

- \`commands.text\`（預設 \`true\`）啟用在聊天訊息中解析 \`/...\`。
  - 在不支援原生指令的介面上（WhatsApp／WebChat／Signal／iMessage／Google Chat／MS Teams），即使設定為 \`false\`，文字指令仍然可以運作。
- \`commands.native\`（預設 \`"auto"\`）註冊原生指令。
  - 自動：Discord／Telegram 為開啟；Slack 為關閉（直到你新增斜線指令）；不支援的供應商忽略。
  - 設定 \`channels.discord.commands.native\`、\`channels.telegram.commands.native\` 或 \`channels.slack.commands.native\` 來覆蓋各供應商（布林值或 \`"auto"\`）。
  - \`false\` 會在啟動時清除 Discord／Telegram 上先前註冊的指令。Slack 指令由 Slack 應用程式管理，不會自動移除。
- \`commands.nativeSkills\`（預設 \`"auto"\`）在支援的情況下原生註冊**技能**指令。
  - 自動：Discord／Telegram 為開啟；Slack 為關閉（Slack 需要為每個技能建立一個斜線指令）。
  - 設定 \`channels.discord.commands.nativeSkills\`、\`channels.telegram.commands.nativeSkills\` 或 \`channels.slack.commands.nativeSkills\` 來覆蓋各供應商（布林值或 \`"auto"\`）。
- \`commands.bash\`（預設 \`false\`）啟用 \`! <cmd>\` 來執行主機 shell 指令（\`/bash <cmd>\` 為別名；需要 \`tools.elevated\` 允許列表）。
- \`commands.bashForegroundMs\`（預設 \`2000\`）控制 bash 在切換到背景模式之前等待多久（\`0\` 立即進入背景）。
- \`commands.config\`（預設 \`false\`）啟用 \`/config\`（讀／寫 \`openclaw.json\`）。
- \`commands.debug\`（預設 \`false\`）啟用 \`/debug\`（執行時期只有的覆蓋）。
- \`commands.allowFrom\`（選用）為指令授權設定各供應商允許列表。配置後，它是指令與指令集的唯一授權來源（頻道允許列表／配對和 \`commands.useAccessGroups\` 被忽略）。使用 \`"\*"\` 作為全域預設；供應商特定的鍵覆蓋它。
- \`commands.useAccessGroups\`（預設 \`true\`）在未設定 \`commands.allowFrom\` 時執行指令的允許列表／原則。

## 指令列表

文字 + 原生（啟用時）：

- \`/help\`
- \`/commands\`
- \`/skill <name> [input]\`（按名稱執行技能）
- \`/status\`（顯示目前狀態；包括目前模型供應商的供應商使用量／配額，如有）
- \`/allowlist\`（列出／新增／移除允許列表項目）
- \`/approve <id> allow-once|allow-always|deny\`（解決執行批准提示）
- \`/context [list|detail|json]\`（說明「上下文」；\`detail\` 顯示每個檔案 + 每個工具 + 每個技能 + 系統提示大小）
- \`/export-session [path]\`（別名：\`/export\`）（將目前工作階段匯出為 HTML，含完整系統提示）
- \`/whoami\`（顯示你的傳送者 ID；別名：\`/id\`）
- \`/session idle <duration|off>\`（管理聚焦執行緒繫結的閒置自動取消聚焦）
- \`/session max-age <duration|off>\`（管理聚焦執行緒繫結的硬性最大年期自動取消聚焦）
- \`/subagents list|kill|log|info|send|steer|spawn\`（檢查、控制或為目前工作階段生成子代理執行）
- \`/acp spawn|cancel|steer|close|status|set-mode|set|cwd|permissions|timeout|model|reset-options|doctor|install|sessions\`（檢查和控制 ACP 執行時期工作階段）
- \`/agents\`（列出此工作階段的執行緒繫結代理）
- \`/focus <target>\`（Discord：將此執行緒繫結到工作階段／子代理目標，或繫結新的執行緒）
- \`/unfocus\`（Discord：移除目前的執行緒繫結）
- \`/kill <id|#|all>\`（立即中止此工作階段的一個或所有執行中的子代理；無確認訊息）
- \`/steer <id|#> <message>\`（立即指揮執行中的子代理：執行時期內如果可能，否則中止目前工作並在指揮訊息上重啟）
- \`/tell <id|#> <message>\`（\`/steer\` 的別名）
- \`/config show|get|set|unset\`（將設定保存到磁碟，僅限擁有者；需要 \`commands.config: true\`）
- \`/debug show|set|unset|reset\`（執行時期覆蓋，僅限擁有者；需要 \`commands.debug: true\`）
- \`/usage off|tokens|full|cost\`（每個回覆的使用量頁尾或本機成本摘要）
- \`/tts off|always|inbound|tagged|status|provider|limit|summary|audio\`（控制 TTS；見 [/tts](/zh-Hant/tts)）
  - Discord：原生指令是 \`/voice\`（Discord 保留 \`/tts\`）；文字 \`/tts\` 仍然可以運作。
- \`/stop\`
- \`/restart\`
- \`/dock-telegram\`（別名：\`/dock_telegram\`）（切換回覆至 Telegram）
- \`/dock-discord\`（別名：\`/dock_discord\`）（切換回覆至 Discord）
- \`/dock-slack\`（別名：\`/dock_slack\`）（切換回覆至 Slack）
- \`/activation mention|always\`（僅群組）
- \`/send on|off|inherit\`（僅限擁有者）
- \`/reset\` 或 \`/new [model]\`（選用模型提示；其餘文字通過正常流程傳遞）
- \`/think <off|minimal|low|medium|high|xhigh>\`（依模型／供應商的動態選擇；別名：\`/thinking\`、\`/t\`）
- \`/fast status|on|off\`（省略引數時顯示目前有效的快速模式狀態）
- \`/verbose on|full|off\`（別名：\`/v\`）
- \`/reasoning on|off|stream\`（別名：\`/reason\`；啟用時，以 \`Reasoning:\` 前綴傳送單獨訊息；\`stream\` = 僅限 Telegram 草稿）
- \`/elevated on|off|ask|full\`（別名：\`/elev\`；\`full\` 跳過執行批准）
- \`/exec host=<sandbox|gateway|node> security=<deny|allowlist|full> ask=<off|on-miss|always> node=<id>\`（傳送 \`/exec\` 來顯示目前設定）
- \`/model <name>\`（別名：\`/models\`；或 \`/<alias>\`（來自 \`agents.defaults.models.\*.alias\`））
- \`/queue <mode>\`（加選項如 \`debounce:2s cap:25 drop:summarize\`；傳送 \`/queue\` 來查看目前設定）
- \`/bash <command>\`（僅主機；\`! <command>\` 的別名；需要 \`commands.bash: true\` + \`tools.elevated\` 允許列表）

僅文字：

- \`/compact [instructions]\`（見 [/concepts/compaction](/zh-Hant/concepts/compaction)）
- \`! <command>\`（僅主機；一次一個；用 \`!poll\` + \`!stop\` 來處理長期執行的工作）
- \`!poll\`（檢查輸出 ／ 狀態；接受選用 \`sessionId\`；\`/bash poll\` 也可以運作）
- \`!stop\`（停止執行中的 bash 工作；接受選用 \`sessionId\`；\`/bash stop\` 也可以運作）

注意：

- 指令接受指令與引數之間選用的 \`:\`（例如 \`/think: high\`、\`/send: on\`、\`/help:\`）。
- \`/new <model>\` 接受模型別名、\`provider/model\` 或供應商名稱（模糊比對）；如果沒有比對，文字被視為訊息主體。
- 如需完整供應商使用量明細，使用 \`openclaw status --usage\`。
- \`/allowlist add|remove\` 需要 \`commands.config=true\` 並尊重頻道 \`configWrites\`。
- 在多帳號頻道中，設定目標的 \`/allowlist --account <id>\` 和 \`/config set channels.<provider>.accounts.<id>...\` 也尊重目標帳號的 \`configWrites\`。
- \`/usage\` 控制每個回覆的使用量頁尾；\`/usage cost\` 從 OpenClaw 工作階段日誌列印本機成本摘要。
- \`/restart\` 預設啟用；設定 \`commands.restart: false\` 以停用它。
- 僅限 Discord 的原生指令：\`/vc join|leave|status\` 控制語音頻道（需要 \`channels.discord.voice\` 和原生指令；作為文字不可用）。
- Discord 執行緒繫結指令（\`/focus\`、\`/unfocus\`、\`/agents\`、\`/session idle\`、\`/session max-age\`）需要有效的執行緒繫結被啟用（\`session.threadBindings.enabled\` 和／或 \`channels.discord.threadBindings.enabled\`）。
- ACP 指令參考和執行時期行為：[ACP Agents](/zh-Hant/tools/acp-agents)。
- \`/verbose\` 用於除錯和額外可見性；在正常使用中保持**關閉**。
- \`/fast on|off\` 保存工作階段覆蓋。用工作階段 UI 的 \`inherit\` 選項來清除它，並回退到設定預設值。
- 工具失敗摘要在相關時仍會顯示，但詳細失敗文字僅在 \`/verbose\` 為 \`on\` 或 \`full\` 時包含。
- \`/reasoning\`（和 \`/verbose\`）在群組設定中很危險：它們可能洩露你無意暴露的內部推理或工具輸出。最好保持關閉，尤其是在群組聊天中。
- **快速路徑：**來自允許列表傳送者的指令專用訊息會立即處理（略過佇列 + 模型）。
- **群組提及閘門：**來自允許列表傳送者的指令專用訊息略過提及要求。
- **行內快捷鍵（僅限授權傳送者）：**某些指令在嵌入正常訊息時也可以運作，並在模型看到其餘文字之前被移除。
  - 例如：\`hey /status\` 會觸發狀態回覆，其餘文字繼續通過正常流程。
- 目前：\`/help\`、\`/commands\`、\`/status\`、\`/whoami\`（\`/id\`）。
- 未授權的指令專用訊息被無聲忽略，行內 \`/...\` 代幣被視為純文字。
- **技能指令：**\`user-invocable\` 技能被公開為斜線指令。名稱被清理為 \`a-z0-9\_\`（最多 32 個字元）；衝突得到數字後綴（例如 \`\_2\`）。
  - \`/skill <name> [input]\` 按名稱執行技能（當原生指令限制阻止逐項技能指令時很有用）。
  - 預設情況下，技能指令被轉發至模型作為正常要求。
  - 技能可以選擇宣告 \`command-dispatch: tool\` 以將指令直接路由到工具（決定性的，無模型）。
  - 例如：\`/prose\`（OpenProse 外掛程式）——見 [OpenProse](/zh-Hant/prose)。
- **原生指令引數：**Discord 對動態選項使用自動完成（當你省略必需的引數時用按鈕選單）。Telegram 和 Slack 在指令支援選擇且你省略引數時顯示按鈕選單。

## 使用表面（什麼顯示在哪裡）

- **供應商使用量／配額**（例如：「Claude 剩餘 80%」）在啟用使用量追蹤時顯示在 \`/status\` 中（針對目前模型供應商）。
- **每個回覆的權杖／成本**由 \`/usage off|tokens|full\` 控制（附加到正常回覆）。
- \`/model status\` 是關於**模型／驗證／端點**，不是使用量。

## 模型選擇（\`/model\`）

\`/model\` 被實作為指令集。

例子：

\`\`\`
/model
/model list
/model 3
/model openai/gpt-5.2
/model opus@anthropic:default
/model status
\`\`\`

注意：

- \`/model\` 和 \`/model list\` 顯示緊湊的編號選擇器（模型家族 + 可用供應商）。
- 在 Discord 上，\`/model\` 和 \`/models\` 開啟互動選擇器，含供應商和模型下拉列表加上提交步驟。
- \`/model <#>\` 從該選擇器中選擇（並在可能時偏好目前供應商）。
- \`/model status\` 顯示詳細檢視，包括設定的供應商端點（\`baseUrl\`）和 API 模式（\`api\`）（如有）。

## 除錯覆蓋

\`/debug\` 讓你設定**執行時期專用**設定覆蓋（記憶體，不磁碟）。僅限擁有者。預設停用；用 \`commands.debug: true\` 啟用。

例子：

\`\`\`
/debug show
/debug set messages.responsePrefix="[openclaw]"
/debug set channels.whatsapp.allowFrom=["+1555","+4477"]
/debug unset messages.responsePrefix
/debug reset
\`\`\`

注意：

- 覆蓋立即適用於新的設定讀取，但**不**寫入 \`openclaw.json\`。
- 用 \`/debug reset\` 清除所有覆蓋並回退到磁碟設定。

## 設定更新

\`/config\` 寫入你的磁碟設定（\`openclaw.json\`）。僅限擁有者。預設停用；用 \`commands.config: true\` 啟用。

例子：

\`\`\`
/config show
/config show messages.responsePrefix
/config get messages.responsePrefix
/config set messages.responsePrefix="[openclaw]"
/config unset messages.responsePrefix
\`\`\`

注意：

- 設定在寫入之前被驗證；無效的改變被拒絕。
- \`/config\` 更新跨重啟保存。

## 表面注意事項

- **文字指令**在正常聊天工作階段中執行（DM 共用 \`main\`，群組各有自己的工作階段）。
- **原生指令**使用隔離的工作階段：
  - Discord：\`agent:<agentId>:discord:slash:<userId>\`
  - Slack：\`agent:<agentId>:slack:slash:<userId>\`（前綴可透過 \`channels.slack.slashCommand.sessionPrefix\` 設定）
  - Telegram：\`telegram:slash:<userId>\`（透過 \`CommandTargetSessionKey\` 鎖定聊天工作階段）
- **\`/stop\`** 鎖定活躍的聊天工作階段，以便它可以中止目前的執行。
- **Slack：** \`channels.slack.slashCommand\` 仍支援單一的 \`/openclaw\` 風格指令。如果啟用 \`commands.native\`，你必須為每個內建指令建立一個 Slack 斜線指令（相同的名稱作為 \`/help\`）。Slack 的指令引數選單作為臨時的 Block Kit 按鈕傳遞。
  - Slack 原生例外：註冊 \`/agentstatus\`（不是 \`/status\`），因為 Slack 保留 \`/status\`。文字 \`/status\` 在 Slack 訊息中仍然可以運作。
