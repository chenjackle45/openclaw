---
title: "Groups(群組)"
summary: "跨介面的群組聊天行為（WhatsApp/Telegram/Discord/Slack/Signal/iMessage/Microsoft Teams）"
read_when:
  - 更改群組聊天行為或提及控制
---
# Groups（群組）

OpenClaw 在各介面間一致地處理群組聊天：WhatsApp、Telegram、Discord、Slack、Signal、iMessage、Microsoft Teams。

## 初學者介紹（2 分鐘）
OpenClaw「住在」您自己的訊息帳戶上。沒有單獨的 WhatsApp 機器人使用者。
如果**您**在某個群組中，OpenClaw 可以看到該群組並在那裡回應。

預設行為：
- 群組受限制（`groupPolicy: "allowlist"`）。
- 除非您明確停用提及控制，否則回覆需要提及。

翻譯：允許清單中的發送者可以透過提及 OpenClaw 來觸發它。

> TL;DR
> - **DM 存取**由 `*.allowFrom` 控制。
> - **群組存取**由 `*.groupPolicy` + 允許清單（`*.groups`、`*.groupAllowFrom`）控制。
> - **回覆觸發**由提及控制（`requireMention`、`/activation`）控制。

快速流程（群組訊息發生什麼）：
```
groupPolicy? disabled -> drop
groupPolicy? allowlist -> group allowed? no -> drop
requireMention? yes -> mentioned? no -> store for context only
otherwise -> reply
```

![群組訊息流程](/images/groups-flow.svg)

如果您想要...
| 目標 | 要設定什麼 |
|------|------------|
| 允許所有群組但只在 @提及時回覆 | `groups: { "*": { requireMention: true } }` |
| 停用所有群組回覆 | `groupPolicy: "disabled"` |
| 僅特定群組 | `groups: { "<group-id>": { ... } }`（無 `"*"` 鍵） |
| 只有您可以在群組中觸發 | `groupPolicy: "allowlist"`、`groupAllowFrom: ["+1555..."]` |

## 會話鍵
- 群組會話使用 `agent:<agentId>:<channel>:group:<id>` 會話鍵（房間/頻道使用 `agent:<agentId>:<channel>:channel:<id>`）。
- Telegram 論壇主題將 `:topic:<threadId>` 新增到群組 ID，以便每個主題都有自己的會話。
- 直接聊天使用主會話（或如果設定則按發送者）。
- 群組會話會跳過心跳。

## 模式：個人 DM + 公開群組（單一代理）

是的——如果您的「個人」流量是 **DM**，而您的「公開」流量是**群組**，這運作良好。

原因：在單代理模式下，DM 通常落入**主**會話鍵（`agent:main:main`），而群組始終使用**非主**會話鍵（`agent:main:<channel>:group:<id>`）。如果您啟用 `mode: "non-main"` 的沙盒，這些群組會話在 Docker 中運行，而您的主 DM 會話保持在主機上。

這給您一個代理「大腦」（共享工作區 + 記憶），但兩種執行姿態：
- **DM**：完整工具（主機）
- **群組**：沙盒 + 受限工具（Docker）

> 如果您需要真正分離的工作區/人格（「個人」和「公開」絕不能混合），請使用第二個代理 + 綁定。請參閱 [多代理路由](/concepts/multi-agent)。

範例（主機上的 DM，沙盒化 + 僅訊息工具的群組）：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main", // 群組/頻道是非主 -> 沙盒化
        scope: "session", // 最強隔離（每個群組/頻道一個容器）
        workspaceAccess: "none"
      }
    }
  },
  tools: {
    sandbox: {
      tools: {
        // 如果 allow 非空，其他所有都被阻止（deny 仍然優先）。
        allow: ["group:messaging", "group:sessions"],
        deny: ["group:runtime", "group:fs", "group:ui", "nodes", "cron", "gateway"]
      }
    }
  }
}
```

想要「群組只能看到資料夾 X」而不是「無主機存取」？保持 `workspaceAccess: "none"` 並只將允許清單路徑掛載到沙盒：

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
            "~/FriendsShared:/data:ro"
          ]
        }
      }
    }
  }
}
```

相關：
- 設定鍵和預設值：[Gateway 設定](/gateway/configuration#agentsdefaultssandbox)
- 除錯為什麼工具被阻止：[沙盒 vs 工具策略 vs 提升](/gateway/sandbox-vs-tool-policy-vs-elevated)
- 綁定掛載詳情：[沙盒](/gateway/sandboxing#custom-bind-mounts)

## 顯示標籤
- UI 標籤在可用時使用 `displayName`，格式為 `<channel>:<token>`。
- `#room` 保留給房間/頻道；群組聊天使用 `g-<slug>`（小寫，空格 -> `-`，保留 `#@+._-`）。

## 群組策略
控制每頻道如何處理群組/房間訊息：

```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "disabled", // "open" | "disabled" | "allowlist"
      groupAllowFrom: ["+15551234567"]
    },
    telegram: {
      groupPolicy: "disabled",
      groupAllowFrom: ["123456789", "@username"]
    },
    signal: {
      groupPolicy: "disabled",
      groupAllowFrom: ["+15551234567"]
    },
    imessage: {
      groupPolicy: "disabled",
      groupAllowFrom: ["chat_id:123"]
    },
    msteams: {
      groupPolicy: "disabled",
      groupAllowFrom: ["user@org.com"]
    },
    discord: {
      groupPolicy: "allowlist",
      guilds: {
        "GUILD_ID": { channels: { help: { allow: true } } }
      }
    },
    slack: {
      groupPolicy: "allowlist",
      channels: { "#general": { allow: true } }
    },
    matrix: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["@owner:example.org"],
      groups: {
        "!roomId:example.org": { allow: true },
        "#alias:example.org": { allow: true }
      }
    }
  }
}
```

| 策略 | 行為 |
|------|------|
| `"open"` | 群組繞過允許清單；提及控制仍適用。 |
| `"disabled"` | 完全阻止所有群組訊息。 |
| `"allowlist"` | 僅允許匹配設定允許清單的群組/房間。 |

備註：
- `groupPolicy` 與提及控制（需要 @提及）分開。
- WhatsApp/Telegram/Signal/iMessage/Microsoft Teams：使用 `groupAllowFrom`（回退：明確的 `allowFrom`）。
- Discord：允許清單使用 `channels.discord.guilds.<id>.channels`。
- Slack：允許清單使用 `channels.slack.channels`。
- Matrix：允許清單使用 `channels.matrix.groups`（房間 ID、別名或名稱）。使用 `channels.matrix.groupAllowFrom` 限制發送者；也支援每房間 `users` 允許清單。
- 群組 DM 單獨控制（`channels.discord.dm.*`、`channels.slack.dm.*`）。
- Telegram 允許清單可以匹配使用者 ID（`"123456789"`、`"telegram:123456789"`、`"tg:123456789"`）或使用者名稱（`"@alice"` 或 `"alice"`）；前綴不區分大小寫。
- 預設為 `groupPolicy: "allowlist"`；如果您的群組允許清單為空，群組訊息會被阻止。

快速心智模型（群組訊息的評估順序）：
1) `groupPolicy`（open/disabled/allowlist）
2) 群組允許清單（`*.groups`、`*.groupAllowFrom`、頻道特定允許清單）
3) 提及控制（`requireMention`、`/activation`）

## 提及控制（預設）
除非按群組覆寫，否則群組訊息需要提及。預設值位於 `*.groups."*"` 下的每個子系統。

回覆機器人訊息算作隱式提及（當頻道支援回覆元資料時）。這適用於 Telegram、WhatsApp、Slack、Discord 和 Microsoft Teams。

```json5
{
  channels: {
    whatsapp: {
      groups: {
        "*": { requireMention: true },
        "123@g.us": { requireMention: false }
      }
    },
    telegram: {
      groups: {
        "*": { requireMention: true },
        "123456789": { requireMention: false }
      }
    },
    imessage: {
      groups: {
        "*": { requireMention: true },
        "123": { requireMention: false }
      }
    }
  },
  agents: {
    list: [
      {
        id: "main",
        groupChat: {
          mentionPatterns: ["@openclaw", "openclaw", "\\+15555550123"],
          historyLimit: 50
        }
      }
    ]
  }
}
```

備註：
- `mentionPatterns` 是不區分大小寫的正則表達式。
- 提供明確提及的介面仍然通過；模式是回退。
- 每代理覆寫：`agents.list[].groupChat.mentionPatterns`（當多個代理共享群組時有用）。
- 提及控制僅在提及偵測可能時強制執行（原生提及或設定了 `mentionPatterns`）。
- Discord 預設值位於 `channels.discord.guilds."*"`（可按伺服器/頻道覆寫）。
- 群組歷史上下文在頻道間統一包裝，是**僅待處理**（因提及控制而跳過的訊息）；使用 `messages.groupChat.historyLimit` 作為全域預設，使用 `channels.<channel>.historyLimit`（或 `channels.<channel>.accounts.*.historyLimit`）作為覆寫。設為 `0` 停用。

## 群組/頻道工具限制（可選）
某些頻道設定支援限制**特定群組/房間/頻道內**可用的工具。

- `tools`：允許/拒絕整個群組的工具。
- `toolsBySender`：群組內的每發送者覆寫（鍵是發送者 ID/使用者名稱/電子郵件/電話號碼，取決於頻道）。使用 `"*"` 作為萬用字元。

解析順序（最具體的優先）：
1) 群組/頻道 `toolsBySender` 匹配
2) 群組/頻道 `tools`
3) 預設（`"*"`）`toolsBySender` 匹配
4) 預設（`"*"`）`tools`

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
            "123456789": { alsoAllow: ["exec"] }
          }
        }
      }
    }
  }
}
```

備註：
- 群組/頻道工具限制在全域/代理工具策略之外套用（deny 仍然優先）。
- 某些頻道對房間/頻道使用不同的巢狀結構（例如，Discord `guilds.*.channels.*`、Slack `channels.*`、MS Teams `teams.*.channels.*`）。

## 群組允許清單
當設定 `channels.whatsapp.groups`、`channels.telegram.groups` 或 `channels.imessage.groups` 時，鍵作為群組允許清單。使用 `"*"` 允許所有群組，同時仍設定預設提及行為。

常見意圖（複製/貼上）：

1) 停用所有群組回覆
```json5
{
  channels: { whatsapp: { groupPolicy: "disabled" } }
}
```

2) 僅允許特定群組（WhatsApp）
```json5
{
  channels: {
    whatsapp: {
      groups: {
        "123@g.us": { requireMention: true },
        "456@g.us": { requireMention: false }
      }
    }
  }
}
```

3) 允許所有群組但需要提及（明確）
```json5
{
  channels: {
    whatsapp: {
      groups: { "*": { requireMention: true } }
    }
  }
}
```

4) 只有擁有者可以在群組中觸發（WhatsApp）
```json5
{
  channels: {
    whatsapp: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"],
      groups: { "*": { requireMention: true } }
    }
  }
}
```

## 啟動（僅限擁有者）
群組擁有者可以切換每群組啟動：
- `/activation mention`
- `/activation always`

擁有者由 `channels.whatsapp.allowFrom` 決定（或未設定時機器人的自身 E.164）。作為獨立訊息發送命令。其他介面目前忽略 `/activation`。

## 上下文欄位
群組入站負載設定：
- `ChatType=group`
- `GroupSubject`（如果已知）
- `GroupMembers`（如果已知）
- `WasMentioned`（提及控制結果）
- Telegram 論壇主題還包含 `MessageThreadId` 和 `IsForum`。

代理系統提示在新群組會話的第一輪包含群組介紹。它提醒模型像人類一樣回應，避免 Markdown 表格，並避免輸入字面的 `\n` 序列。

## iMessage 特定
- 路由或允許清單時偏好 `chat_id:<id>`。
- 列出聊天：`imsg chats --limit 20`。
- 群組回覆始終返回到相同的 `chat_id`。

## WhatsApp 特定
請參閱 [群組訊息](/concepts/group-messages) 了解僅 WhatsApp 行為（歷史注入、提及處理詳情）。
