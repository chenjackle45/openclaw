---
summary: "每個頻道的路由規則（WhatsApp、Telegram、Discord、Slack）和共享上下文"
read_when:
  - 變更頻道路由或收件箱行為
title: "Channel Routing（頻道路由）"
---

# 頻道與路由

OpenClaw 將回覆路由**回訊息來自的頻道**。模型不選擇頻道；路由是確定性的並由主機設定控制。

## 關鍵術語

- **頻道**：`whatsapp`、`telegram`、`discord`、`slack`、`signal`、`imessage`、`webchat`。
- **AccountId**：per-channel 帳戶實例（如果支援）。
- 選用的頻道預設帳戶：`channels.<channel>.defaultAccount` 選擇當傳出路徑未指定 `accountId` 時使用哪個帳戶。
- **AgentId**：隔離的工作區 + 會話儲存（「腦」）。
- **SessionKey**：用於儲存上下文和控制並行的桶金鑰。

## 會話金鑰形狀（範例）

直接訊息摺疊到代理的**主**會話：

- `agent:<agentId>:<mainKey>`（預設：`agent:main:main`）

群組和頻道保持按頻道隔離：

- 群組：`agent:<agentId>:<channel>:group:<id>`
- 頻道/房間：`agent:<agentId>:<channel>:channel:<id>`

執行緒：

- Slack/Discord 執行緒附加 `:thread:<threadId>` 到基礎金鑰。
- Telegram 論壇主題在群組金鑰中嵌入 `:topic:<topicId>`。

範例：

- `agent:main:telegram:group:-1001234567890:topic:42`
- `agent:main:discord:channel:123456:thread:987654`

## 主 DM 路由固定

當 `session.dmScope` 是 `main` 時，直接訊息可能共享一個主會話。為了防止會話的 `lastRoute` 被非擁有者 DM 覆寫，OpenClaw 在所有這些都為真時推斷來自 `allowFrom` 的固定擁有者：

- `allowFrom` 恰好有一個非通配符條目。
- 該條目可以標準化為該頻道的具體傳送者 ID。
- 傳入的 DM 傳送者與該固定擁有者不相符。

在該不相符情況中，OpenClaw 仍然記錄傳入會話中繼資料，但它跳過更新主會話 `lastRoute`。

## 路由規則（代理如何被選擇）

路由為每個傳入訊息選擇**一個代理**：

1. **精確 peer 比對**（`bindings` 具有 `peer.kind` + `peer.id`）。
2. **父 peer 比對**（執行緒繼承）。
3. **Guild + 角色比對**（Discord）透過 `guildId` + `roles`。
4. **Guild 比對**（Discord）透過 `guildId`。
5. **Team 比對**（Slack）透過 `teamId`。
6. **帳戶比對**（頻道上的 `accountId`）。
7. **頻道比對**（任何帳戶在該頻道上，`accountId: "*"`）。
8. **預設代理**（`agents.list[].default`，else 第一個清單條目，回落到 `main`）。

當綁定包含多個比對欄位（`peer`、`guildId`、`teamId`、`roles`）時，**所有提供的欄位必須相符**才能應用該綁定。

相符的代理決定使用哪個工作區和會話儲存。

## 廣播群組（執行多個代理）

廣播群組使您能夠為相同的 peer **執行多個代理**，**當 OpenClaw 通常會回覆時**（例如：在 WhatsApp 群組中，在提及/啟動把關之後）。

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

參見：[廣播群組](/zh-Hant/channels/broadcast-groups)。

## 設定概述

- `agents.list`：命名代理定義（工作區、模型等）。
- `bindings`：將傳入頻道/帳戶/peer 對應到代理。

範例：

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

## 會話儲存

會話儲存位於狀態目錄（預設 `~/.openclaw`）下：

- `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- JSONL 成績單與儲存一起存在

您可以透過 `session.store` 和 `{agentId}` 範本化覆蓋儲存路徑。

## WebChat 行為

WebChat 附加到**選定的代理**並預設為代理的主會話。因此，WebChat 使您可以在一個位置看到該代理的跨頻道上下文。

## 回覆上下文

傳入回覆包含：

- `ReplyToId`、`ReplyToBody` 和 `ReplyToSender`（如果可用）。
- 引用的上下文作為 `[Replying to ...]` 區塊附加到 `Body`。

這在頻道中一致。
