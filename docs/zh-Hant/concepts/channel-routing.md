---
summary: "每個頻道的路由規則（WhatsApp、Telegram、Discord、Slack）和共享上下文"
read_when:
  - 變更頻道路由或收件匣行為
title: "Channel Routing（頻道路由）"
---

# 頻道與路由

OpenClaw 將回覆**路由回訊息來源的頻道**。模型不選擇頻道；路由是確定性的，由主機設定控制。

## 關鍵術語

- **Channel（頻道）**：`whatsapp`、`telegram`、`discord`、`slack`、`signal`、`imessage`、`webchat`。
- **AccountId**：每個頻道的帳號實例（若支援）。
- 選用的頻道預設帳號：`channels.<channel>.defaultAccount` 用於選擇在出站路徑未指定 `accountId` 時使用哪個帳號。
  - 在多帳號設定中，當配置了兩個或更多帳號時，請設定明確的預設值（`defaultAccount` 或 `accounts.default`）。若未設定，退路路由可能會選取第一個正規化的帳號 ID。
- **AgentId**：隔離的工作區 + 工作階段儲存（「大腦」）。
- **SessionKey**：用於儲存上下文和控制並發性的分桶金鑰。

## 工作階段金鑰格式（範例）

直接訊息合併至 agent 的**主要**工作階段：

- `agent:<agentId>:<mainKey>`（預設：`agent:main:main`）

群組和頻道按頻道保持隔離：

- 群組：`agent:<agentId>:<channel>:group:<id>`
- 頻道/房間：`agent:<agentId>:<channel>:channel:<id>`

串：

- Slack/Discord 串在基礎金鑰後附加 `:thread:<threadId>`。
- Telegram 論壇主題在群組金鑰中嵌入 `:topic:<topicId>`。

範例：

- `agent:main:telegram:group:-1001234567890:topic:42`
- `agent:main:discord:channel:123456:thread:987654`

## 主要 DM 路由固定

當 `session.dmScope` 為 `main` 時，直接訊息可能共享一個主要工作階段。
為防止工作階段的 `lastRoute` 被非擁有者的 DM 覆寫，
當以下所有條件成立時，OpenClaw 從 `allowFrom` 推斷固定擁有者：

- `allowFrom` 恰好有一個非萬用字元條目。
- 該條目可以被正規化為該頻道的具體寄件者 ID。
- 入站 DM 寄件者與該固定擁有者不符。

在不符的情況下，OpenClaw 仍會記錄入站工作階段 metadata，但跳過更新主要工作階段的 `lastRoute`。

## 路由規則（如何選擇 agent）

路由為每條入站訊息選擇**一個 agent**：

1. **精確對等匹配**（含 `peer.kind` + `peer.id` 的 `bindings`）。
2. **父對等匹配**（串繼承）。
3. **Guild + 角色匹配**（Discord），透過 `guildId` + `roles`。
4. **Guild 匹配**（Discord），透過 `guildId`。
5. **Team 匹配**（Slack），透過 `teamId`。
6. **帳號匹配**（頻道上的 `accountId`）。
7. **頻道匹配**（該頻道上的任意帳號，`accountId: "*"`）。
8. **預設 agent**（`agents.list[].default`，否則第一個清單條目，退路為 `main`）。

當繫結包含多個匹配欄位（`peer`、`guildId`、`teamId`、`roles`）時，**所有提供的欄位都必須匹配**才能套用該繫結。

匹配的 agent 決定使用哪個工作區和工作階段儲存。

## 廣播群組（執行多個 agent）

廣播群組讓你在 **OpenClaw 通常會回覆時**（例如：在 WhatsApp 群組中，在提及/啟動限制之後）為同一對等方執行**多個 agents**。

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

## 設定概覽

- `agents.list`：命名的 agent 定義（工作區、模型等）。
- `bindings`：將入站頻道/帳號/對等方對映到 agents。

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

## 工作階段儲存

工作階段儲存位於狀態目錄下（預設 `~/.openclaw`）：

- `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- JSONL 轉錄本與儲存並存

可透過 `session.store` 和 `{agentId}` 範本化覆蓋儲存路徑。

## WebChat 行為

WebChat 附加到**選定的 agent** 並預設使用 agent 的主要工作階段。因此，WebChat 讓你在一個地方查看該 agent 的跨頻道上下文。

## 回覆上下文

入站回覆包含：

- `ReplyToId`、`ReplyToBody` 和 `ReplyToSender`（若可用）。
- 引用的上下文作為 `[Replying to ...]` 區塊附加到 `Body`。

這在各頻道中保持一致。
