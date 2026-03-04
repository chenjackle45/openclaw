---
summary: "跨表面的群組聊天行為（WhatsApp/Telegram/Discord/Slack/Signal/iMessage/Microsoft Teams/Zalo）"
read_when:
  - 變更群組聊天行為或提及把關
title: "Groups（群組）"
---

# 群組

OpenClaw 在各表面上一致地對待群組聊天：WhatsApp、Telegram、Discord、Slack、Signal、iMessage、Microsoft Teams、Zalo。

## 初學者介紹（2 分鐘）

OpenClaw「居住」在您自己的訊息帳戶上。沒有單獨的 WhatsApp bot 使用者。
如果**您**在群組中，OpenClaw 可以看到該群組並在那裡回應。

預設行為：

- 群組受限（`groupPolicy: "allowlist"`）。
- 回覆需要提及，除非您明確停用提及把關。

翻譯：允許清單傳送者可以透過提及 OpenClaw 來觸發它。

> TL;DR
>
> - **DM 存取**由 `*.allowFrom` 控制。
> - **群組存取**由 `*.groupPolicy` + 允許清單（`*.groups`、`*.groupAllowFrom`）控制。
> - **回覆觸發**由提及把關（`requireMention`、`/activation`）控制。

快速流程（群組訊息會發生什麼）：

```
groupPolicy? disabled -> drop
groupPolicy? allowlist -> group allowed? no -> drop
requireMention? yes -> mentioned? no -> store for context only
otherwise -> reply
```

![群組訊息流程](/images/groups-flow.svg)

如果您想...

| 目標                                | 要設定什麼                                                 |
| ----------------------------------- | ---------------------------------------------------------- |
| 允許所有群組但只在 @mentions 上回覆 | `groups: { "*": { requireMention: true } }`                |
| 停用所有群組回覆                    | `groupPolicy: "disabled"`                                  |
| 僅特定群組                          | `groups: { "<group-id>": { ... } }`（無 `"*"` 鍵）         |
| 僅您可以在群組中觸發                | `groupPolicy: "allowlist"`, `groupAllowFrom: ["+1555..."]` |

## 會話金鑰

- 群組會話使用 `agent:<agentId>:<channel>:group:<id>` 會話金鑰（房間/頻道使用 `agent:<agentId>:<channel>:channel:<id>`）。
- Telegram 論壇主題在群組 ID 中新增 `:topic:<threadId>`，所以每個主題都有自己的會話。
- 直接聊天使用主會話（或按傳送者配置）。
- 群組會話跳過心跳。

## 模式：個人 DM + 公共群組（單一代理）

是 — 如果您的「個人」流量是 **DM** 且您的「公共」流量是**群組**，這運作得很好。

為什麼：在單一代理模式中，DM 通常降落在**主**會話金鑰（`agent:main:main`），而群組始終使用**非主**會話金鑰（`agent:main:<channel>:group:<id>`）。如果您使用 `mode: "non-main"` 啟用沙箱化，這些群組會話在 Docker 中執行，而您的主 DM 會話保持在主機上。

這給您一個代理「腦」（共享工作區 + 記憶），但兩個執行狀態：

- **DM**：完整工具（主機）
- **群組**：沙箱 + 受限工具（Docker）

> 如果您需要真正獨立的工作區/角色（「個人」和「公共」絕不能混合），請使用第二個代理 + 綁定。參見[多代理路由](/zh-Hant/concepts/multi-agent)。

範例（DM 在主機上、群組沙箱化 + 僅傳訊工具）：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // groups/channels are non-main -> sandboxed
        scope: "session", // strongest isolation (one container per group/channel)
        workspaceAccess: "none",
      },
    },
  },
  tools: {
    sandbox: {
      tools: {
        // If allow is non-empty, everything else is blocked (deny still wins).
        allow: ["group:messaging", "group:sessions"],
        deny: ["group:runtime", "group:fs", "group:ui", "nodes", "cron", "gateway"],
      },
    },
  },
}
```

想要「群組只能看到資料夾 X」而不是「無主機存取」？保持 `workspaceAccess: "none"` 並僅將允許清單路徑掛載到沙箱中：

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

- 設定金鑰和預設值：[Gateway 設定](/zh-Hant/gateway/configuration#agentsdefaultssandbox)
- 偵錯為何工具被阻止：[沙箱 vs 工具政策 vs 提升](/zh-Hant/gateway/sandbox-vs-tool-policy-vs-elevated)
- 綁定掛載詳細資訊：[沙箱化](/zh-Hant/gateway/sandboxing#custom-bind-mounts)

## 顯示標籤

- UI 標籤在可用時使用 `displayName`，格式為 `<channel>:<token>`。
- `#room` 為房間/頻道保留；群組聊天使用 `g-<slug>`（小寫，空格 -> `-`，保留 `#@+._-`）。

## 群組政策

控制每個頻道如何處理群組/房間訊息：

```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "disabled", // "open" | "disabled" | "allowlist"
      groupAllowFrom: ["+15551234567"],
    },
    telegram: {
      groupPolicy: "disabled",
      groupAllowFrom: ["123456789"], // numeric Telegram user id (wizard can resolve @username)
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

| 政策          | 行為                                    |
| ------------- | --------------------------------------- |
| `"open"`      | 群組繞過允許清單；提及把關仍然適用。    |
| `"disabled"`  | 完全阻止所有群組訊息。                  |
| `"allowlist"` | 僅允許與配置的允許清單相符的群組/房間。 |

註：

- `groupPolicy` 與提及把關分開（需要 @mentions）。
- WhatsApp/Telegram/Signal/iMessage/Microsoft Teams/Zalo：使用 `groupAllowFrom`（回落：明確 `allowFrom`）。
- DM 配對批准（`*-allowFrom` 儲存條目）僅適用於 DM 存取；群組傳送者授權保持對群組允許清單的明確性。
- Discord：允許清單使用 `channels.discord.guilds.<id>.channels`。
- Slack：允許清單使用 `channels.slack.channels`。
- Matrix：允許清單使用 `channels.matrix.groups`（房間 ID、別名或名稱）。使用 `channels.matrix.groupAllowFrom` 限制傳送者；每個房間 `users` 允許清單也支援。
- 群組 DM 單獨控制（`channels.discord.dm.*`、`channels.slack.dm.*`）。
- Telegram 允許清單可以比對使用者 ID（`"123456789"`、`"telegram:123456789"`、`"tg:123456789"`）或使用者名稱（`"@alice"` 或 `"alice"`）；前綴不區分大小寫。
- 預設為 `groupPolicy: "allowlist"`；如果您的群組允許清單為空，群組訊息被阻止。
- 執行時安全：當供應商區塊完全遺漏（`channels.<provider>` 缺失）時，群組政策回落到失敗關閉模式（通常 `allowlist`）而不是繼承 `channels.defaults.groupPolicy`。

快速心智模型（群組訊息的評估順序）：

1. `groupPolicy`（開放/禁用/允許清單）
2. 群組允許清單（`*.groups`、`*.groupAllowFrom`、頻道特定允許清單）
3. 提及把關（`requireMention`、`/activation`）

## 提及把關（預設）

群組訊息需要提及，除非按群組覆蓋。預設位於 `*.groups."*"` 下的每個子系統。

回覆 bot 訊息計為隱含提及（當頻道支援回覆中繼資料時）。這適用於 Telegram、WhatsApp、Slack、Discord 和 Microsoft Teams。

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

註：

- `mentionPatterns` 是不區分大小寫的正則表達式。
- 提供明確提及的表面仍然通過；模式是回落。
- 每個代理覆蓋：`agents.list[].groupChat.mentionPatterns`（當多個代理共享群組時很有用）。
- 提及把關僅在提及偵測可能時強制執行（原生提及或設定 `mentionPatterns`）。
- Discord 預設位於 `channels.discord.guilds."*"`（按 guild/channel 覆蓋）。
- 群組歷史上下文在頻道中統一包裝，並且是**待機狀態**（由於提及把關被跳過的訊息）；使用 `messages.groupChat.historyLimit` 作為全域預設，`channels.<channel>.historyLimit`（或 `channels.<channel>.accounts.*.historyLimit`）用於覆蓋。設定 `0` 以停用。

## 群組/頻道工具限制（選用）

某些頻道設定支援限制**特定群組/房間/頻道內**可用的工具。

- `tools`：允許/拒絕整個群組的工具。
- `toolsBySender`：群組內每個傳送者的覆蓋。
  使用明確的金鑰前綴：
  `id:<senderId>`、`e164:<phone>`、`username:<handle>`、`name:<displayName>` 和 `"*"` 通配符。
  舊版未加前綴的金鑰仍被接受並比對為 `id:`。

解析順序（最具體的獲勝）：

1. 群組/頻道 `toolsBySender` 比對
2. 群組/頻道 `tools`
3. 預設（`"*"`）`toolsBySender` 比對
4. 預設（`"*"`）`tools`

範例（Telegram）：

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

註：

- 群組/頻道工具限制適用於全域/代理工具政策（拒絕仍然獲勝）。
- 某些頻道對房間/頻道使用不同的巢狀結構（例如，Discord `guilds.*.channels.*`、Slack `channels.*`、MS Teams `teams.*.channels.*`）。

## 群組允許清單

當配置 `channels.whatsapp.groups`、`channels.telegram.groups` 或 `channels.imessage.groups` 時，金鑰充當群組允許清單。使用 `"*"` 允許所有群組，同時仍設定預設提及行為。

常見意圖（複製/貼上）：

1. 停用所有群組回覆

```json5
{
  channels: { whatsapp: { groupPolicy: "disabled" } },
}
```

2. 僅允許特定群組（WhatsApp）

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

4. 僅擁有者可以在群組中觸發（WhatsApp）

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

## 啟動（僅擁有者）

群組擁有者可以切換每個群組啟動：

- `/activation mention`
- `/activation always`

擁有者由 `channels.whatsapp.allowFrom` 決定（或當未設定時 bot 的自我 E.164）。作為獨立訊息傳送命令。其他表面目前忽略 `/activation`。

## 上下文欄位

群組傳入負載集合：

- `ChatType=group`
- `GroupSubject`（如果已知）
- `GroupMembers`（如果已知）
- `WasMentioned`（提及把關結果）
- Telegram 論壇主題也包含 `MessageThreadId` 和 `IsForum`。

代理系統提示包含新群組會話第一輪的群組介紹。它提醒模型像人一樣回應，避免 Markdown 表格，避免輸入字面 `\n` 序列。

## iMessage 特殊性

- 路由或允許清單時偏好 `chat_id:<id>`。
- 列出聊天：`imsg chats --limit 20`。
- 群組回覆始終回到相同的 `chat_id`。

## WhatsApp 特殊性

參見[群組訊息](/zh-Hant/channels/group-messages)以了解 WhatsApp 專用行為（歷史注入、提及處理詳細資訊）。
