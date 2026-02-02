---
title: "Tlon"
summary: "Tlon/Urbit 支援狀態、功能與設定"
read_when:
  - 處理 Tlon/Urbit 頻道功能時
---

# Tlon (插件)

Tlon 是一個建構在 Urbit 之上的去中心化通訊軟體。OpenClaw 透過連接至您的 Urbit ship，可以回應私訊 (DM) 與群組對話訊息。群組回覆需要 @ 標註，執行緒回覆與文字附加 URL 的媒體降級都受支援。表情回饋、民調與原生媒體上傳則不受支援。

狀態：透過插件支援。私訊、群組標註、執行緒回覆與文字形式的媒體回退都受支援。表情回饋、民調與原生媒體上傳不受支援。

## 安裝插件

Tlon 不隨核心安裝綑綁。

透過 CLI 安裝（npm 套件庫）：

```bash
openclaw plugins install @openclaw/tlon
```

本地簽出（從 git 儲存庫執行時）：

```bash
openclaw plugins install ./extensions/tlon
```

詳情：[插件](/plugin)

## 設定

1. 安裝 Tlon 插件。
2. 蒐集您的 ship URL 與登入代碼。
3. 設定 `channels.tlon`。
4. 重啟 Gateway。
5. 對機器人發送私訊或在群組中標註它。

最小設定（單一帳戶）：

```json5
{
  channels: {
    tlon: {
      enabled: true,
      ship: "~sampel-palnet",
      url: "https://your-ship-host",
      code: "lidlut-tabwed-pillex-ridrup",
    },
  },
}
```

## 群組頻道

自動探索預設啟用。您也可以手動固定頻道：

```json5
{
  channels: {
    tlon: {
      groupChannels: ["chat/~host-ship/general", "chat/~host-ship/support"],
    },
  },
}
```

停用自動探索：

```json5
{
  channels: {
    tlon: {
      autoDiscoverChannels: false,
    },
  },
}
```

## 存取控制

DM 允許清單（空 = 允許全部）：

```json5
{
  channels: {
    tlon: {
      dmAllowlist: ["~zod", "~nec"],
    },
  },
}
```

群組授權（預設受限）：

```json5
{
  channels: {
    tlon: {
      defaultAuthorizedShips: ["~zod"],
      authorization: {
        channelRules: {
          "chat/~host-ship/general": {
            mode: "restricted",
            allowedShips: ["~zod", "~nec"],
          },
          "chat/~host-ship/announcements": {
            mode: "open",
          },
        },
      },
    },
  },
}
```

## 交付目標（CLI/cron）

與 `openclaw message send` 或 cron 交付一起使用：

- DM：`~sampel-palnet` 或 `dm/~sampel-palnet`
- 群組：`chat/~host-ship/channel` 或 `group:~host-ship/channel`

## 備註

- 群組回覆需要標註（例如 `~your-bot-ship`）才能回應。
- 執行緒回覆：如果入站訊息位於執行緒中，OpenClaw 會在執行緒中回應。
- 媒體：`sendMedia` 回退到文字 + URL（無原生上傳）。
