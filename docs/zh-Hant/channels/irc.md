---
title: IRC
description: 將 OpenClaw 連接到 IRC 頻道和直接訊息。
summary: "IRC 外掛程式設定、存取控制和故障排除"
read_when:
  - 您想將 OpenClaw 連接到 IRC 頻道或 DM
  - 您正在設定 IRC 允許清單、群組政策或提及把關
---

當您想要 OpenClaw 在經典頻道（`#room`）和直接訊息中時使用 IRC。
IRC 作為擴充外掛程式發貨，但在 `channels.irc` 的主設定中進行設定。

## 快速開始

1. 在 `~/.openclaw/openclaw.json` 中啟用 IRC 設定。
2. 至少設定：

```json
{
  "channels": {
    "irc": {
      "enabled": true,
      "host": "irc.libera.chat",
      "port": 6697,
      "tls": true,
      "nick": "openclaw-bot",
      "channels": ["#openclaw"]
    }
  }
}
```

3. 啟動/重新啟動 Gateway：

```bash
openclaw gateway run
```

## 安全預設值

- `channels.irc.dmPolicy` 預設為 `"pairing"`。
- `channels.irc.groupPolicy` 預設為 `"allowlist"`。
- 使用 `groupPolicy="allowlist"`，設定 `channels.irc.groups` 定義允許的頻道。
- 使用 TLS（`channels.irc.tls=true`），除非您有意接受明文傳輸。

## 存取控制

IRC 頻道有兩個獨立的「門」：

1. **頻道存取**（`groupPolicy` + `groups`）：bot 是否接受來自頻道的訊息。
2. **傳送者存取**（`groupAllowFrom` / 每個頻道 `groups["#channel"].allowFrom`）：誰被允許在該頻道內觸發 bot。

設定金鑰：

- DM 允許清單（DM 傳送者存取）：`channels.irc.allowFrom`
- 群組傳送者允許清單（頻道傳送者存取）：`channels.irc.groupAllowFrom`
- 每個頻道控制（頻道 + 傳送者 + 提及規則）：`channels.irc.groups["#channel"]`
- `channels.irc.groupPolicy="open"` 允許未配置的頻道（**仍然預設提及把關**）

允許清單條目應該使用穩定的傳送者身份（`nick!user@host`）。
裸露昵稱比對是可變的，僅在 `channels.irc.dangerouslyAllowNameMatching: true` 時啟用。

### 常見陷阱：`allowFrom` 是 DM，不是頻道

如果您看到日誌，如：

- `irc: drop group sender alice!ident@host (policy=allowlist)`

…這意味著傳送者未被允許用於**群組/頻道**訊息。透過以下任一方式修復：

- 設定 `channels.irc.groupAllowFrom`（全域用於所有頻道），或
- 設定每個頻道傳送者允許清單：`channels.irc.groups["#channel"].allowFrom`

範例（允許 `#tuirc-dev` 中的任何人與 bot 交談）：

```json5
{
  channels: {
    irc: {
      groupPolicy: "allowlist",
      groups: {
        "#tuirc-dev": { allowFrom: ["*"] },
      },
    },
  },
}
```

## 回覆觸發（提及）

即使頻道被允許（透過 `groupPolicy` + `groups`）且傳送者被允許，OpenClaw 預設為群組上下文中的**提及把關**。

這意味著您可能看到日誌，如 `drop channel … (missing-mention)`，除非訊息包含與 bot 相符的提及模式。

要使 bot 在 IRC 頻道中回覆**無需提及**，停用該頻道的提及把關：

```json5
{
  channels: {
    irc: {
      groupPolicy: "allowlist",
      groups: {
        "#tuirc-dev": {
          requireMention: false,
          allowFrom: ["*"],
        },
      },
    },
  },
}
```

或允許**所有** IRC 頻道（無每個頻道允許清單）並仍然無提及回覆：

```json5
{
  channels: {
    irc: {
      groupPolicy: "open",
      groups: {
        "*": { requireMention: false, allowFrom: ["*"] },
      },
    },
  },
}
```

## 安全注意（建議用於公開頻道）

如果您允許 `allowFrom: ["*"]` 在公開頻道中，任何人都可以提示 bot。
為了降低風險，限制該頻道的工具。

### 對頻道中的每個人相同的工具

```json5
{
  channels: {
    irc: {
      groups: {
        "#tuirc-dev": {
          allowFrom: ["*"],
          tools: {
            deny: ["group:runtime", "group:fs", "gateway", "nodes", "cron", "browser"],
          },
        },
      },
    },
  },
}
```

### 每個傳送者不同的工具（擁有者獲得更多權力）

使用 `toolsBySender` 應用對 `"*"` 的更嚴格政策和對您昵稱的較寬鬆政策：

```json5
{
  channels: {
    irc: {
      groups: {
        "#tuirc-dev": {
          allowFrom: ["*"],
          toolsBySender: {
            "*": {
              deny: ["group:runtime", "group:fs", "gateway", "nodes", "cron", "browser"],
            },
            "id:eigen": {
              deny: ["gateway", "nodes", "cron"],
            },
          },
        },
      },
    },
  },
}
```

註：

- `toolsBySender` 金鑰應該為 IRC 傳送者身份值使用 `id:`：
  `id:eigen` 或 `id:eigen!~eigen@174.127.248.171` 以進行更強的比對。
- 舊版未加前綴的金鑰仍被接受並比對為 `id:`。
- 第一個相符的傳送者政策獲勝；`"*"` 是通配符回落。

有關群組存取 vs 提及把關（以及它們如何互動）的更多資訊，請參見：[/channels/groups](/zh-Hant/channels/groups)。

## NickServ

在連接後以 NickServ 識別：

```json
{
  "channels": {
    "irc": {
      "nickserv": {
        "enabled": true,
        "service": "NickServ",
        "password": "your-nickserv-password"
      }
    }
  }
}
```

連接時的選用一次性註冊：

```json
{
  "channels": {
    "irc": {
      "nickserv": {
        "register": true,
        "registerEmail": "bot@example.com"
      }
    }
  }
}
```

昵稱註冊後停用 `register` 以避免重複的 REGISTER 嘗試。

## 環境變數

預設帳戶支援：

- `IRC_HOST`
- `IRC_PORT`
- `IRC_TLS`
- `IRC_NICK`
- `IRC_USERNAME`
- `IRC_REALNAME`
- `IRC_PASSWORD`
- `IRC_CHANNELS`（逗號分隔）
- `IRC_NICKSERV_PASSWORD`
- `IRC_NICKSERV_REGISTER_EMAIL`

## 故障排除

- 如果 bot 連接但從不在頻道中回覆，請驗證 `channels.irc.groups` **和**提及把關是否丟棄訊息（`missing-mention`）。如果您想要它不需要 ping 就回覆，為頻道設定 `requireMention:false`。
- 如果登入失敗，請驗證昵稱可用性和伺服器密碼。
- 如果 TLS 在自訂網路上失敗，請驗證主機/連接埠和憑證設定。
