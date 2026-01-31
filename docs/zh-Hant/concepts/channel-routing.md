---
title: "Channel routing(頻道路由)"
summary: "按頻道（WhatsApp、Telegram、Discord、Slack）的路由規則與共享上下文"
read_when:
  - 更改頻道路由或收件匣行為
---
# Channels & routing（頻道與路由）

OpenClaw 將回覆**路由回訊息來源的頻道**。模型不會選擇頻道；路由是確定性的，由主機設定控制。

## 關鍵術語

- **Channel（頻道）**：`whatsapp`、`telegram`、`discord`、`slack`、`signal`、`imessage`、`webchat`。
- **AccountId**：按頻道的帳戶實例（如果支援）。
- **AgentId**：隔離的工作區 + 會話儲存（「大腦」）。
- **SessionKey**：用於儲存上下文和控制並行性的儲存鍵 (Bucket key)。

## 會話鍵形狀（範例）

直接訊息 (Direct messages) 會合併到代理的**主 (main)** 會話：

- `agent:<agentId>:<mainKey>`（預設：`agent:main:main`）

群組和房間保持按頻道隔離：

- 群組：`agent:<agentId>:<channel>:group:<id>`
- 頻道/房間：`agent:<agentId>:<channel>:channel:<id>`

討論串 (Threads)：

- Slack/Discord 討論串在基礎鍵後附加 `:thread:<threadId>`。
- Telegram 論壇主題在群組鍵中嵌入 `:topic:<topicId>`。

範例：

- `agent:main:telegram:group:-1001234567890:topic:42`
- `agent:main:discord:channel:123456:thread:987654`

## 路由規則（如何選擇代理）

對於每條入站訊息，路由會挑選**一個代理**：

1. **精確對象匹配**（具備 `peer.kind` + `peer.id` 的 `bindings`）。
2. **伺服器 (Guild) 匹配** (Discord) 透過 `guildId`。
3. **團隊 (Team) 匹配** (Slack) 透過 `teamId`。
4. **帳戶匹配**（頻道上的 `accountId`）。
5. **頻道匹配**（該頻道上的任何帳戶）。
6. **預設代理** (`agents.list[].default`，若無則為列表第一項，回退至 `main`)。

匹配到的代理決定了使用哪個工作區和會話儲存。

## 廣播群組 (Broadcast groups)（運行多個代理）

廣播群組讓您可以在 **OpenClaw 平常會回覆時**（例如：在 WhatsApp 群組中，經過提及/啟動控制後），為同一個對象運行**多個代理**。

設定：

```json5
{
  broadcast: {
    strategy: "parallel",
    "120363403215116621@g.us": ["alfred", "baerbel"],
    "+15555550123": ["support", "logger"]
  }
}
```

請參閱：[廣播群組 (Broadcast Groups)](/broadcast-groups)。

## 設定概覽

- `agents.list`：具名的代理定義（工作區、模型等）。
- `bindings`：將入站頻道/帳戶/對象映射到代理。

範例：

```json5
{
  agents: {
    list: [
      { id: "support", name: "Support", workspace: "~/.openclaw/workspace-support" }
    ]
  },
  bindings: [
    { match: { channel: "slack", teamId: "T123" }, agentId: "support" },
    { match: { channel: "telegram", peer: { kind: "group", id: "-100123" } }, agentId: "support" }
  ]
}
```

## 會話儲存

會話儲存位於狀態目錄（預設 `~/.openclaw`）下：

- `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- JSONL 轉錄記錄與儲存檔並存

您可以透過 `session.store` 和 `{agentId}` 模板覆寫儲存路徑。

## WebChat 行為

WebChat 附加到**選定的代理**，並預設為代理的主會話。因此，WebChat 讓您可以在一個地方查看該代理的跨頻道上下文。

## 回覆上下文

入站回覆包含：
- `ReplyToId`、`ReplyToBody` 和 `ReplyToSender`（如果可用）。
- 引用上下文會作為 `[Replying to ...]` 區塊附加到 `Body` 中。

這在所有頻道中都是一致的。
