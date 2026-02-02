---
title: "Nextcloud Talk"
summary: "Nextcloud Talk 支援狀態、功能與設定"
read_when:
  - 處理 Nextcloud Talk 頻道功能時
---
# Nextcloud Talk (插件)

狀態：透過插件（Webhook 機器人）支援。支援私訊、聊天室、表情回饋與 Markdown 訊息。

## 安裝插件

Nextcloud Talk 不隨核心安裝綑綁。

透過 CLI 安裝（npm 套件庫）：

```bash
openclaw plugins install @openclaw/nextcloud-talk
```

本地簽出（從 git 儲存庫執行時）：

```bash
openclaw plugins install ./extensions/nextcloud-talk
```

如果在設定/入門期間選擇 Nextcloud Talk 並偵測到 git 簽出，OpenClaw 會自動提供本地安裝路徑。

詳情：[插件](/plugin)

## 快速設定（初學者）

1. 安裝 Nextcloud Talk 插件。
2. 在您的 Nextcloud 伺服器上建立機器人：
   ```bash
   ./occ talk:bot:install "OpenClaw" "<共享金鑰>" "<webhook-url>" --feature reaction
   ```
3. 在目標聊天室設定中啟用機器人。
4. 設定 OpenClaw：
   - 設定：`channels.nextcloud-talk.baseUrl` + `channels.nextcloud-talk.botSecret`
   - 或環境變數：`NEXTCLOUD_TALK_BOT_SECRET`（僅預設帳戶）
5. 重啟 Gateway（或完成入門）。

最小設定：

```json5
{
  channels: {
    "nextcloud-talk": {
      enabled: true,
      baseUrl: "https://cloud.example.com",
      botSecret: "shared-secret",
      dmPolicy: "pairing",
    },
  },
}
```

## 備註

- 機器人無法主動發起私訊。使用者必須先訊息機器人。
- Webhook URL 必須可被 Gateway 存取；如果在代理後面，設定 `webhookPublicUrl`。
- 機器人 API 不支援媒體上傳；媒體以 URL 形式發送。
- Webhook payload 不區分私訊 vs 聊天室；設定 `apiUser` + `apiPassword` 以啟用聊天室類型查詢（否則私訊被視為聊天室）。

## 存取控制（私訊）

- 預設：`channels.nextcloud-talk.dmPolicy = "pairing"`。未知發送者獲得配對碼。
- 核准方式：
  - `openclaw pairing list nextcloud-talk`
  - `openclaw pairing approve nextcloud-talk <CODE>`
- 公開私訊：`channels.nextcloud-talk.dmPolicy="open"` 加上 `channels.nextcloud-talk.allowFrom=["*"]`。

## 聊天室（群組）

- 預設：`channels.nextcloud-talk.groupPolicy = "allowlist"`（提及閘門）。
- 允許清單聊天室設定 `channels.nextcloud-talk.rooms`：

```json5
{
  channels: {
    "nextcloud-talk": {
      rooms: {
        "room-token": { requireMention: true },
      },
    },
  },
}
```

- 要不允許任何聊天室，保持允許清單為空或設定 `channels.nextcloud-talk.groupPolicy="disabled"`。

## 功能

| 特性         | 狀態          |
| --------------- | ------------- |
| 私訊 | 支援     |
| 聊天室           | 支援     |
| 執行緒         | 不支援 |
| 媒體           | 僅 URL      |
| 表情回饋       | 支援     |
| 原生指令 | 不支援 |

## 設定參考（Nextcloud Talk）

完整設定：[設定](/gateway/configuration)

供應商選項：

- `channels.nextcloud-talk.enabled`：啟用/停用頻道啟動。
- `channels.nextcloud-talk.baseUrl`：Nextcloud 實例 URL。
- `channels.nextcloud-talk.botSecret`：機器人共享金鑰。
- `channels.nextcloud-talk.botSecretFile`：金鑰檔案路徑。
- `channels.nextcloud-talk.apiUser`：聊天室查詢的 API 使用者（私訊偵測）。
- `channels.nextcloud-talk.apiPassword`：聊天室查詢的 API/應用程式密碼。
- `channels.nextcloud-talk.apiPasswordFile`：API 密碼檔案路徑。
- `channels.nextcloud-talk.webhookPort`：Webhook 監聽器埠（預設：8788）。
- `channels.nextcloud-talk.webhookHost`：Webhook 主機（預設：0.0.0.0）。
- `channels.nextcloud-talk.webhookPath`：Webhook 路徑（預設：/nextcloud-talk-webhook）。
- `channels.nextcloud-talk.webhookPublicUrl`：外部可存取的 Webhook URL。
- `channels.nextcloud-talk.dmPolicy`：`pairing | allowlist | open | disabled`。
- `channels.nextcloud-talk.allowFrom`：私訊允許清單（使用者 ID）。`open` 需要 `"*"`。
- `channels.nextcloud-talk.groupPolicy`：`allowlist | open | disabled`。
- `channels.nextcloud-talk.groupAllowFrom`：群組允許清單（使用者 ID）。
- `channels.nextcloud-talk.rooms`：每聊天室設定與允許清單。
- `channels.nextcloud-talk.historyLimit`：群組歷史上下文限制（0 停用）。
- `channels.nextcloud-talk.dmHistoryLimit`：私訊歷史限制（0 停用）。
- `channels.nextcloud-talk.dms`：每私訊覆寫（historyLimit）。
- `channels.nextcloud-talk.textChunkLimit`：外發文字分塊大小（字元）。
- `channels.nextcloud-talk.chunkMode`：`length`（預設）或 `newline` 在長度分塊前在空白行（段落邊界）分割。
- `channels.nextcloud-talk.blockStreaming`：為此頻道停用塊串流。
- `channels.nextcloud-talk.blockStreamingCoalesce`：塊串流合併調優。
- `channels.nextcloud-talk.mediaMaxMb`：入站媒體上限（MB）。
