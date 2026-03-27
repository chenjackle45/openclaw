---
summary: "各表面的群組聊天行為（WhatsApp／Telegram／Discord／Slack／Signal／iMessage／Microsoft Teams／Zalo）"
read_when:
  - 變更群組聊天行為或提及閘門
title: "Groups（群組）"
sidebarTitle: "群組"
---

# 群組

OpenClaw 在各表面一致對待群組聊天：WhatsApp、Telegram、Discord、Slack、Signal、iMessage、Microsoft Teams、Zalo。

## 初學者介紹（2 分鐘）

OpenClaw「住」在你自己的通訊帳戶中。沒有單獨的 WhatsApp bot 使用者。
如果**你**在群組中，OpenClaw 可看到該群組並在那裡回覆。

預設行為：

- 群組受限制（`groupPolicy: "allowlist"`）。
- 回覆需要提及，除非你明確停用提及閘門。

翻譯：允許清單寄件者可透過提及它觸發 OpenClaw。

> TL;DR
>
> - **DM 存取**由 `*.allowFrom` 控制。
> - **群組存取**由 `*.groupPolicy` + 允許清單（`*.groups`、`*.groupAllowFrom`）控制。
> - **回覆觸發**由提及閘門（`requireMention`、`/activation`）控制。

快速流程（群組訊息發生什麼）：

```
groupPolicy? disabled -> drop
groupPolicy? allowlist -> group allowed? no -> drop
requireMention? yes -> mentioned? no -> store for context only
otherwise -> reply
```

![群組訊息流程](/images/groups-flow.svg)

如果你想...

| 目標                              | 設定什麼                                                   |
| --------------------------------- | ---------------------------------------------------------- |
| 允許所有群組但只在 @mentions 回覆 | `groups: { "*": { requireMention: true } }`                |
| 停用所有群組回覆                  | `groupPolicy: "disabled"`                                  |
| 僅特定群組                        | `groups: { "<group-id>": { ... } }`（無 `"*"` 鍵）         |
| 僅你可在群組中觸發                | `groupPolicy: "allowlist"`、`groupAllowFrom: ["+1555..."]` |

## 工作階段鍵

- 群組工作階段使用 `agent:<agentId>:<channel>:group:<id>` 工作階段鍵（房間／頻道使用 `agent:<agentId>:<channel>:channel:<id>`）。
- Telegram forum topics 新增 `:topic:<threadId>` 至群組 id，所以每個主題有自己的工作階段。
- 直接聊天使用主工作階段（或按寄件者若已配置）。
- 群組工作階段跳過心跳。

## 模式：個人 DM + 公開群組（單代理）

是的 — 這在你的「個人」流量是 **DM** 且「公開」流量是**群組**時運作良好。

為什麼：在單代理模式，DM 通常登陸在**主**工作階段鍵（`agent:main:main`），而群組總使用**非主**工作階段鍵（`agent:main:<channel>:group:<id>`）。如果啟用沙箱，設置 `mode: "non-main"`，那些群組工作階段在 Docker 中運行，而主 DM 工作階段保留在主機上。

這給你一個代理「大腦」（共享工作區 + 記憶），但兩個執行姿態：

- **DM**：完整工具（主機）
- **群組**：沙箱 + 受限工具（Docker）

> 如果你需要真正單獨的工作區／人格（「個人」和「公開」永遠不可混淆），使用第二個代理 + 綁定。見[多代理路由](/zh-Hant/concepts/multi-agent)。

示例（DM 在主機上，群組沙箱 + 僅訊息工具）：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // 群組／頻道是非主 -> 沙箱化
        scope: "session", // 最強隔離（每群組／頻道一個容器）
        workspaceAccess: "none",
      },
    },
  },
  tools: {
    sandbox: {
      tools: {
        // 如果 allow 非空，所有其他被阻止（deny 仍勝利）。
        allow: ["group:messaging", "group:sessions"],
        deny: ["group:runtime", "group:fs", "group:ui", "nodes", "cron", "gateway"],
      },
    },
  },
}
```

想要「群組僅可看資料夾 X」而非「無主機存取」？保持 `workspaceAccess: "none"` 並僅將允許清單路徑掛載到沙箱中：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        scope: "session",
        workspaceAccess: "none",
        docker: {
          binds: [
            // hostPath:containerPath:mode
            "/home/user/FriendsShared:/data:ro",
          ],
        },
      },
    },
  },
}
```

相關：

- 配置鍵和預設值：[Gateway 配置](/zh-Hant/gateway/configuration-reference#agentsdefaultssandbox)
- 調試工具為何被阻止：[沙箱 vs 工具原則 vs 提升](/zh-Hant/gateway/sandbox-vs-tool-policy-vs-elevated)
- 綁定掛載詳情：[沙箱化](/zh-Hant/gateway/sandboxing#custom-bind-mounts)

## 顯示標籤

- UI 標籤在可用時使用 `displayName`，格式為 `<channel>:<token>`。
- `#room` 為房間／頻道保留；群組聊天使用 `g-<slug>`（小寫、空格 -> `-`、保持 `#@+._-`）。

## 群組原則

控制如何處理每個頻道的群組／房間訊息：

```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "disabled", // "open" | "disabled" | "allowlist"
      groupAllowFrom: ["+15551234567"],
    },
    telegram: {
      groupPolicy: "disabled",
      groupAllowFrom: ["123456789"], // numeric Telegram user id（精靈可解決 @username）
    },
    signal: {
      groupPolicy: "disabled",
      groupAllowFrom: ["+15551234567"],
    },
    imessage: {
      groupPolicy: "disabled",
      groupAllowFrom: ["chat_id:123"],
    },
    msteams: {
      groupPolicy: "disabled",
      groupAllowFrom: ["user@org.com"],
    },
    discord: {
      groupPolicy: "allowlist",
      guilds: {
        GUILD_ID: { channels: { help: { allow: true } } },
      },
    },
    slack: {
      groupPolicy: "allowlist",
      channels: { "#general": { allow: true } },
    },
    matrix: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["@owner:example.org"],
      groups: {
        "!roomId:example.org": { allow: true },
        "#alias:example.org": { allow: true },
      },
    },
  },
}
```

| 原則          | 行為                                   |
| ------------- | -------------------------------------- |
| `"open"`      | 群組略過允許清單；提及閘門仍適用。     |
| `"disabled"`  | 完全阻止所有群組訊息。                 |
| `"allowlist"` | 僅允許符合已配置允許清單的群組／房間。 |

備註：

- `groupPolicy` 獨立於提及閘門（需要 @mentions）。
- WhatsApp／Telegram／Signal／iMessage／Microsoft Teams／Zalo：使用 `groupAllowFrom`（回退：明確 `allowFrom`）。
- DM 配對核准（`*-allowFrom` 存儲條目）僅套用於 DM 存取；群組寄件者授權保持明確到群組允許清單。
- Discord：允許清單使用 `channels.discord.guilds.<id>.channels`。
- Slack：允許清單使用 `channels.slack.channels`。
- Matrix：允許清單使用 `channels.matrix.groups`（房間 ID、別名或名稱）。使用 `channels.matrix.groupAllowFrom` 限制寄件者；每房間 `users` 允許清單也支援。
- 群組 DM 單獨控制（`channels.discord.dm.*`、`channels.slack.dm.*`）。
- Telegram 允許清單可符合使用者 ID（`"123456789"`、`"telegram:123456789"`、`"tg:123456789"`）或使用者名稱（`"@alice"` 或 `"alice"`）；前綴不分大小寫。
- 預設是 `groupPolicy: "allowlist"`；如果群組允許清單為空，群組訊息被阻止。
- 執行時安全：當提供者區塊完全缺失（`channels.<provider>` 不存在），群組原則回退到失敗關閉模式（通常 `allowlist`）而非繼承 `channels.defaults.groupPolicy`。

快速心智模型（群組訊息評估順序）：

1. `groupPolicy`（open／disabled／allowlist）
2. 群組允許清單（`*.groups`、`*.groupAllowFrom`、頻道特定允許清單）
3. 提及閘門（`requireMention`、`/activation`）

## 提及閘門（預設）

群組訊息需要提及，除非按群組覆蓋。預設位於每子系統 `*.groups."*"` 下。

回覆 bot 訊息計為隱含提及（當頻道支援回覆中繼資料時）。這套用於 Telegram、WhatsApp、Slack、Discord 和 Microsoft Teams。

```json5
{
  channels: {
    whatsapp: {
      groups: {
        "*": { requireMention: true },
        "123@g.us": { requireMention: false },
      },
    },
    telegram: {
      groups: {
        "*": { requireMention: true },
        "123456789": { requireMention: false },
      },
    },
    imessage: {
      groups: {
        "*": { requireMention: true },
        "123": { requireMention: false },
      },
    },
  },
  agents: {
    list: [
      {
        id: "main",
        groupChat: {
          mentionPatterns: ["@openclaw", "openclaw", "\\+15555550123"],
          historyLimit: 50,
        },
      },
    ],
  },
}
```

備註：

- `mentionPatterns` 是不分大小寫的安全正則表達式模式；無效模式和不安全的嵌套重複形式被忽略。
- 提供明確提及的表面仍通過；模式是回退。
- 按代理覆蓋：`agents.list[].groupChat.mentionPatterns`（當多個代理共享群組時有用）。
- 提及閘門僅在提及偵測可能時執行（原生提及或 `mentionPatterns` 已配置）。
- Discord 預設位在 `channels.discord.guilds."*"`（按公會／頻道可覆蓋）。
- 群組歷史上下文統一包裝在各頻道且是**待決專用**（提及閘門跳過的訊息）；使用 `messages.groupChat.historyLimit` 為全域預設，使用 `channels.<channel>.historyLimit`（或 `channels.<channel>.accounts.*.historyLimit`）進行覆蓋。設定 `0` 停用。

## 群組／頻道工具限制（選擇性）

某些頻道配置支援限制**在特定群組／房間／頻道內**可用的工具。

- `tools`：允許／拒絕整個群組的工具。
- `toolsBySender`：群組內的按寄件者覆蓋。
  使用明確鍵前綴：
  `id:<senderId>`、`e164:<phone>`、`username:<handle>`、`name:<displayName>` 和 `"*"` 萬用字元。
  舊版未前綴鍵仍被接受並符合 `id:` 僅。

解決順序（最具體的勝利）：

1. 群組／頻道 `toolsBySender` 符合
2. 群組／頻道 `tools`
3. 預設 (`"*"`) `toolsBySender` 符合
4. 預設 (`"*"`) `tools`

示例（Telegram）：

```json5
{
  channels: {
    telegram: {
      groups: {
        "*": { tools: { deny: ["exec"] } },
        "-1001234567890": {
          tools: { deny: ["exec", "read", "write"] },
          toolsBySender: {
            "id:123456789": { alsoAllow: ["exec"] },
          },
        },
      },
    },
  },
}
```

備註：

- 群組／頻道工具限制除全域／代理工具原則外套用（拒絕仍勝利）。
- 某些頻道對房間／頻道使用不同嵌套（例如 Discord `guilds.*.channels.*`、Slack `channels.*`、Microsoft Teams `teams.*.channels.*`）。

## 群組允許清單

當 `channels.whatsapp.groups`、`channels.telegram.groups` 或 `channels.imessage.groups` 已配置時，鍵充當群組允許清單。使用 `"*"` 允許所有群組，同時仍設定預設提及行為。

常見意圖（複製／貼上）：

1. 停用所有群組回覆

```json5
{
  channels: { whatsapp: { groupPolicy: "disabled" } },
}
```

2. 允許特定群組（WhatsApp）

```json5
{
  channels: {
    whatsapp: {
      groups: {
        "123@g.us": { requireMention: true },
        "456@g.us": { requireMention: false },
      },
    },
  },
}
```

3. 允許所有群組但需要提及（明確）

```json5
{
  channels: {
    whatsapp: {
      groups: { "*": { requireMention: true } },
    },
  },
}
```

4. 僅擁有者可在群組中觸發（WhatsApp）

```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"],
      groups: { "*": { requireMention: true } },
    },
  },
}
```

## 啟用（擁有者專用）

群組擁有者可按群組切換啟用：

- `/activation mention`
- `/activation always`

擁有者由 `channels.whatsapp.allowFrom` 決定（或 bot 自身 E.164 未設定時）。以獨立訊息傳送命令。其他表面目前忽略 `/activation`。

## 上下文欄位

群組傳入酬載設定：

- `ChatType=group`
- `GroupSubject`（若已知）
- `GroupMembers`（若已知）
- `WasMentioned`（提及閘門結果）
- Telegram forum topics 也包括 `MessageThreadId` 和 `IsForum`。

代理系統提示在新群組工作階段的首次輪中包括群組介紹。它提醒模型像人一樣回覆、避免 Markdown 表格、避免輸入字面 `\n` 序列。

## iMessage 具體情況

- 路由或允許清單時偏好 `chat_id:<id>`。
- 列出聊天：`imsg chats --limit 20`。
- 群組回覆總回到相同 `chat_id`。

## WhatsApp 具體情況

見[群組訊息](/zh-Hant/channels/group-messages)以了解 WhatsApp 專用行為（歷史注入、提及處理詳情）。
