---
title: "SecretRef Credential Surface（SecretRef 認證表面）"
summary: "規範支援 vs 不支援的 SecretRef 認證表面"
read_when:
  - 驗證 SecretRef 認證涵蓋
  - 稽核認證是否符合 `secrets configure` 或 `secrets apply` 資格
  - 驗證為什麼認證超出支援的表面
---

# SecretRef 認證表面

此頁面定義規範的 SecretRef 認證表面。

範圍意圖：

- 在範圍內：嚴格的使用者提供認證，OpenClaw 不造幣或輪換。
- 超出範圍：執行時間造幣或輪換認證、OAuth 重新整理資料和工作階段類似的成品。

## 支援的認證

### `openclaw.json` 目標（`secrets configure` + `secrets apply` + `secrets audit`）

[//]: # "secretref-supported-list-start"

- `models.providers.*.apiKey`
- `models.providers.*.headers.*`
- `skills.entries.*.apiKey`
- `agents.defaults.memorySearch.remote.apiKey`
- `agents.list[].memorySearch.remote.apiKey`
- `talk.apiKey`
- `talk.providers.*.apiKey`
- `messages.tts.elevenlabs.apiKey`
- `messages.tts.openai.apiKey`
- `tools.web.fetch.firecrawl.apiKey`
- `tools.web.search.apiKey`
- `tools.web.search.gemini.apiKey`
- `tools.web.search.grok.apiKey`
- `tools.web.search.kimi.apiKey`
- `tools.web.search.perplexity.apiKey`
- `gateway.auth.password`
- `gateway.auth.token`
- `gateway.remote.token`
- `gateway.remote.password`
- `cron.webhookToken`
- `channels.telegram.botToken`
- `channels.telegram.webhookSecret`
- `channels.telegram.accounts.*.botToken`
- `channels.telegram.accounts.*.webhookSecret`
- `channels.slack.botToken`
- `channels.slack.appToken`
- `channels.slack.userToken`
- `channels.slack.signingSecret`
- `channels.slack.accounts.*.botToken`
- `channels.slack.accounts.*.appToken`
- `channels.slack.accounts.*.userToken`
- `channels.slack.accounts.*.signingSecret`
- `channels.discord.token`
- `channels.discord.pluralkit.token`
- `channels.discord.voice.tts.elevenlabs.apiKey`
- `channels.discord.voice.tts.openai.apiKey`
- `channels.discord.accounts.*.token`
- `channels.discord.accounts.*.pluralkit.token`
- `channels.discord.accounts.*.voice.tts.elevenlabs.apiKey`
- `channels.discord.accounts.*.voice.tts.openai.apiKey`
- `channels.irc.password`
- `channels.irc.nickserv.password`
- `channels.irc.accounts.*.password`
- `channels.irc.accounts.*.nickserv.password`
- `channels.bluebubbles.password`
- `channels.bluebubbles.accounts.*.password`
- `channels.feishu.appSecret`
- `channels.feishu.encryptKey`
- `channels.feishu.verificationToken`
- `channels.feishu.accounts.*.appSecret`
- `channels.feishu.accounts.*.encryptKey`
- `channels.feishu.accounts.*.verificationToken`
- `channels.msteams.appPassword`
- `channels.mattermost.botToken`
- `channels.mattermost.accounts.*.botToken`
- `channels.matrix.password`
- `channels.matrix.accounts.*.password`
- `channels.nextcloud-talk.botSecret`
- `channels.nextcloud-talk.apiPassword`
- `channels.nextcloud-talk.accounts.*.botSecret`
- `channels.nextcloud-talk.accounts.*.apiPassword`
- `channels.zalo.botToken`
- `channels.zalo.webhookSecret`
- `channels.zalo.accounts.*.botToken`
- `channels.zalo.accounts.*.webhookSecret`
- `channels.googlechat.serviceAccount`（透過兄弟 `serviceAccountRef`）（相容性例外）
- `channels.googlechat.accounts.*.serviceAccount`（透過兄弟 `serviceAccountRef`）（相容性例外）

### `auth-profiles.json` 目標（`secrets configure` + `secrets apply` + `secrets audit`）

- `profiles.*.keyRef`（`type: "api_key"`）
- `profiles.*.tokenRef`（`type: "token"`）

[//]: # "secretref-supported-list-end"

備註：

- 驗證設定檔計畫目標需要 `agentId`。
- 計畫條目目標 `profiles.*.key` / `profiles.*.token` 和寫入兄弟重新（`keyRef` / `tokenRef`）。
- 驗證設定檔重新包含在執行時間解析和稽核涵蓋中。
- 對於 SecretRef 管理的模型提供者，已產生 `agents/*/agent/models.json` 條目保持非機密標記（而非已解析的機密值）用於 `apiKey`／標頭表面。
- 標記持久化是來源權威的：OpenClaw 從使用中的來源設定快照（預解析）寫入標記，而非從已解析的執行時間機密值。
- 對於 web 搜尋：
  - 在明確提供者模式中（`tools.web.search.provider` 設定），僅有所選提供者金鑰是活躍的。
  - 在自動模式中（`tools.web.search.provider` 未設定），僅有依優先權解析的第一個提供者金鑰是活躍的。
  - 在自動模式中，未選擇的提供者重新被視為非活躍，直到選擇。

## 不支援的認證

超出範圍的認證包括：

[//]: # "secretref-unsupported-list-start"

- `commands.ownerDisplaySecret`
- `channels.matrix.accessToken`
- `channels.matrix.accounts.*.accessToken`
- `hooks.token`
- `hooks.gmail.pushToken`
- `hooks.mappings[].sessionKey`
- `auth-profiles.oauth.*`
- `discord.threadBindings.*.webhookToken`
- `whatsapp.creds.json`

[//]: # "secretref-unsupported-list-end"

基本原理：

- 這些認證是造幣、輪換、工作階段承擔或 OAuth 持久類別，不符合唯讀外部 SecretRef 解析。
