---
summary: "每個頻道的路由規則（WhatsApp、Telegram、Discord、Slack）和共享上下文"
read_when:
  - 變更頻道路由或收件匣行為
title: "Channel Routing（頻道路由）"
sidebarTitle: "頻道路由"
---

# 頻道與路由

OpenClaw 將回覆**路由回訊息來自的頻道**。模型不選擇頻道；路由是確定性的，由主機配置控制。

## 關鍵術語

- **頻道**：`telegram`、`whatsapp`、`discord`、`irc`、`googlechat`、`slack`、`signal`、`imessage`、`line`，加上擴展頻道。`webchat` 是內部 WebChat UI 頻道，不是可配置的傳出頻道。
- **AccountId**：每頻道帳戶實例（當支援時）。
- 選擇性頻道預設帳戶：`channels.<channel>.defaultAccount` 選擇
  當傳出路徑未指定 `accountId` 時使用哪個帳戶。
  - 在多帳戶設置中，當配置兩個或多個帳戶時設定明確預設（`defaultAccount` 或 `accounts.default`）。不設定它，回退路由可能選擇第一個正常化帳戶 ID。
- **AgentId**：隔離的工作區 + 工作階段存儲（「大腦」）。
- **SessionKey**：用於儲存上下文和控制並行的儲存池鍵。

## 工作階段鍵形狀（示例）

直接訊息摺疊到代理的**主**工作階段：

- `agent:<agentId>:<mainKey>`（預設：`agent:main:main`）

群組和頻道保持每頻道隔離：

- 群組：`agent:<agentId>:<channel>:group:<id>`
- 頻道／房間：`agent:<agentId>:<channel>:channel:<id>`

執行緒：

- Slack／Discord 執行緒追加 `:thread:<threadId>` 至基本鍵。
- Telegram forum topics 在群組鍵中內嵌 `:topic:<topicId>`。

示例：

- `agent:main:telegram:group:-1001234567890:topic:42`
- `agent:main:discord:channel:123456:thread:987654`

## 主 DM 路由釘選

當 `session.dmScope` 是 `main` 時，直接訊息可能共享一個主工作階段。
為防止工作階段的 `lastRoute` 被非擁有者 DM 覆寫，
OpenClaw 當所有這些都為真時推斷釘選擁有者自 `allowFrom`：

- `allowFrom` 恰好有一個非萬用字元條目。
- 該條目可正常化為該頻道的具體寄件者 ID。
- 傳入 DM 寄件者不符合該釘選擁有者。

在該不符情況，OpenClaw 仍記錄傳入工作階段中繼資料，但跳過更新主工作階段 `lastRoute`。

## 路由規則（如何選擇代理）

路由為每個傳入訊息選擇**一個代理**：

1. **精確對等匹配**（`bindings` 含 `peer.kind` + `peer.id`）。
2. **父對等匹配**（執行緒繼承）。
3. **公會 + 角色匹配**（Discord）透過 `guildId` + `roles`。
4. **公會匹配**（Discord）透過 `guildId`。
5. **團隊匹配**（Slack）透過 `teamId`。
6. **帳戶匹配**（頻道上的 `accountId`）。
7. **頻道匹配**（該頻道上的任何帳戶，`accountId: "*"`）。
8. **預設代理**（`agents.list[].default`，否則首個清單條目，回退到 `main`）。

當綁定包括多個匹配欄位（`peer`、`guildId`、`teamId`、`roles`）時，**所有提供的欄位必須匹配**該綁定才能套用。

匹配的代理決定使用哪個工作區和工作階段存儲。

## 廣播群組（運行多個代理）

廣播群組讓你為相同對等運行**多個代理**當 OpenClaw 通常會回覆時（例如：在 WhatsApp 群組中，提及／啟用閘門後）。

設定：

```json5
{
  broadcast: {
    strategy: "parallel",
    "120363403215116621@g.us": ["alfred", "baerbel"],
    "+15555550123": ["support", "logger"],
  },
}
```

見：[廣播群組](/zh-Hant/channels/broadcast-groups)。

## 設定概述

- `agents.list`：命名代理定義（工作區、模型等）。
- `bindings`：將傳入頻道／帳戶／對等映射至代理。

示例：

```json5
{
  agents: {
    list: [{ id: "support", name: "Support", workspace: "~/.openclaw/workspace-support" }],
  },
  bindings: [
    { match: { channel: "slack", teamId: "T123" }, agentId: "support" },
    { match: { channel: "telegram", peer: { kind: "group", id: "-100123" } }, agentId: "support" },
  ],
}
```

## 工作階段儲存

工作階段存儲位於狀態目錄下（預設 `~/.openclaw`）：

- `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- JSONL 文字記錄位在存儲旁邊

你可透過 `session.store` 和 `{agentId}` 樣板覆蓋存儲路徑。

Gateway 和 ACP 工作階段發現也掃描磁碟支援的代理存儲在
預設 `agents/` 根下和樣板化 `session.store` 根下。發現的
存儲必須停留在該已解決代理根內並使用常規
`sessions.json` 檔案。符號連結和超出根的路徑被忽略。

## WebChat 行為

WebChat 附加到**選定代理**並預設為代理的主
工作階段。因此，WebChat 讓你在一個地方看到該
代理的跨頻道上下文。

## 回覆上下文

傳入回覆包括：

- 可用時的 `ReplyToId`、`ReplyToBody` 和 `ReplyToSender`。
- 引用上下文作為 `[Replying to ...]` 區塊追加到 `Body`。

這在各頻道中是一致的。
