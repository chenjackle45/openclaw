---
summary: "SecretRef 憑證範圍的正式支援與不支援清單"
read_when:
  - 驗證 SecretRef 憑證覆蓋範圍
  - 稽核憑證是否符合 `secrets configure` 或 `secrets apply` 的資格
  - 了解為什麼某個憑證超出支援範圍
title: "SecretRef Credential Surface（SecretRef 憑證範圍）"
---

# SecretRef 憑證範圍

本頁定義 SecretRef 憑證範圍的正式規範。

範圍意圖：

- 納入範圍：嚴格限定為使用者提供的憑證，OpenClaw 不自行建立或輪換。
- 排除範圍：執行階段建立或輪換的憑證、OAuth 更新材料，以及類 session 的工件。

## 支援的憑證

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
- `channels.feishu.verificationToken`
- `channels.feishu.accounts.*.appSecret`
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
- `channels.googlechat.serviceAccount` 透過同層級的 `serviceAccountRef`（相容性例外）
- `channels.googlechat.accounts.*.serviceAccount` 透過同層級的 `serviceAccountRef`（相容性例外）

### `auth-profiles.json` 目標（`secrets configure` + `secrets apply` + `secrets audit`）

- `profiles.*.keyRef`（`type: "api_key"`）
- `profiles.*.tokenRef`（`type: "token"`）

[//]: # "secretref-supported-list-end"

注意事項：

- Auth profile 計畫目標需要 `agentId`。
- 計畫條目目標為 `profiles.*.key` / `profiles.*.token`，並寫入同層級的 ref（`keyRef` / `tokenRef`）。
- Auth profile ref 包含在執行階段解析與稽核覆蓋範圍中。
- 對於 SecretRef 管理的模型提供商，生成的 `agents/*/agent/models.json` 條目會持久保存 `apiKey`／header 範圍的非機密標記（非已解析的機密值）。
- 對於網路搜尋：
  - 在明確提供商模式下（已設定 `tools.web.search.provider`），僅選定的提供商金鑰有效。
  - 在自動模式下（未設定 `tools.web.search.provider`），`tools.web.search.apiKey` 與提供商專屬金鑰均有效。

## 不支援的憑證

超出範圍的憑證包括：

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

原因：

- 這些憑證屬於自行建立、輪換、帶有 session 狀態或 OAuth 持久性等類型，不適合唯讀的外部 SecretRef 解析。
