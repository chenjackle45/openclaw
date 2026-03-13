---
summary: "Nextcloud Talk 支援狀態、功能說明與設定方式"
read_when:
  - Working on Nextcloud Talk channel features
title: "Nextcloud Talk（Nextcloud Talk 插件）"
---

# Nextcloud Talk (plugin)

狀態：透過插件（Webhook Bot）支援。支援私訊、聊天室、反應與 Markdown 訊息。

## 需要安裝插件

Nextcloud Talk 以插件形式提供，不包含在核心安裝中。

透過 CLI 從 npm registry 安裝：

```bash
openclaw plugins install @openclaw/nextcloud-talk
```

從本地 git checkout 安裝：

```bash
openclaw plugins install ./extensions/nextcloud-talk
```

如果你在設定/引導過程中選擇了 Nextcloud Talk，且偵測到 git checkout，OpenClaw 會自動提供本地安裝路徑。

詳細說明：[插件](/zh-Hant/tools/plugin)

## 快速設定（初學者）

1. 安裝 Nextcloud Talk 插件（見上方）。
2. 在你的 Nextcloud 伺服器上建立一個 Bot：

   ```bash
   ./occ talk:bot:install "OpenClaw" "<shared-secret>" "<webhook-url>" --feature reaction
   ```

3. 在目標聊天室設定中啟用 Bot。
4. 設定 OpenClaw：
   - 設定：`channels.nextcloud-talk.baseUrl` + `channels.nextcloud-talk.botSecret`
   - 或環境變數：`NEXTCLOUD_TALK_BOT_SECRET`（僅限預設帳號）
5. 重啟 Gateway（或完成引導流程）。

最低設定：

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

## 注意事項

- Bot 無法主動發起私訊，需由使用者先傳訊息給 Bot。
- Webhook URL 必須可被 Gateway 存取；若在 Proxy 後方，請設定 `webhookPublicUrl`。
- Bot API 不支援媒體上傳；媒體以 URL 形式傳送。
- Webhook 載荷無法區分私訊與聊天室；設定 `apiUser` + `apiPassword` 可啟用聊天室類型查詢（否則私訊會被視為聊天室處理）。

## 存取控制（私訊）

- 預設：`channels.nextcloud-talk.dmPolicy = "pairing"`。未知發送者會收到配對碼。
- 核准方式：
  - `openclaw pairing list nextcloud-talk`
  - `openclaw pairing approve nextcloud-talk <CODE>`
- 公開私訊：`channels.nextcloud-talk.dmPolicy="open"` 加上 `channels.nextcloud-talk.allowFrom=["*"]`。
- `allowFrom` 僅比對 Nextcloud 用戶 ID；顯示名稱不適用。

## 聊天室（群組）

- 預設：`channels.nextcloud-talk.groupPolicy = "allowlist"`（需要 mention 才能觸發）。
- 透過 `channels.nextcloud-talk.rooms` 設定白名單：

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

- 若不允許任何聊天室，保持白名單為空或設定 `channels.nextcloud-talk.groupPolicy="disabled"`。

## 功能

| 功能     | 狀態   |
| -------- | ------ |
| 私訊     | 支援   |
| 聊天室   | 支援   |
| 討論串   | 不支援 |
| 媒體     | 僅 URL |
| 反應     | 支援   |
| 原生指令 | 不支援 |

## 設定參考（Nextcloud Talk）

完整設定：[設定](/zh-Hant/gateway/configuration)

提供者選項：

- `channels.nextcloud-talk.enabled`：啟用/停用頻道啟動。
- `channels.nextcloud-talk.baseUrl`：Nextcloud 實例 URL。
- `channels.nextcloud-talk.botSecret`：Bot 共享密鑰。
- `channels.nextcloud-talk.botSecretFile`：一般檔案形式的密鑰路徑。不接受符號連結。
- `channels.nextcloud-talk.apiUser`：用於聊天室查詢的 API 用戶（私訊偵測）。
- `channels.nextcloud-talk.apiPassword`：用於聊天室查詢的 API/應用程式密碼。
- `channels.nextcloud-talk.apiPasswordFile`：API 密碼檔案路徑。
- `channels.nextcloud-talk.webhookPort`：Webhook 監聽器端口（預設：8788）。
- `channels.nextcloud-talk.webhookHost`：Webhook 主機（預設：0.0.0.0）。
- `channels.nextcloud-talk.webhookPath`：Webhook 路徑（預設：/nextcloud-talk-webhook）。
- `channels.nextcloud-talk.webhookPublicUrl`：外部可存取的 Webhook URL。
- `channels.nextcloud-talk.dmPolicy`：`pairing | allowlist | open | disabled`。
- `channels.nextcloud-talk.allowFrom`：私訊白名單（用戶 ID）。`open` 需要 `"*"`。
- `channels.nextcloud-talk.groupPolicy`：`allowlist | open | disabled`。
- `channels.nextcloud-talk.groupAllowFrom`：群組白名單（用戶 ID）。
- `channels.nextcloud-talk.rooms`：每聊天室的設定與白名單。
- `channels.nextcloud-talk.historyLimit`：群組記錄限制（0 停用）。
- `channels.nextcloud-talk.dmHistoryLimit`：私訊記錄限制（0 停用）。
- `channels.nextcloud-talk.dms`：每個私訊的覆寫設定（historyLimit）。
- `channels.nextcloud-talk.textChunkLimit`：輸出文字區塊大小（字元數）。
- `channels.nextcloud-talk.chunkMode`：`length`（預設）或 `newline`，在長度分割前先在空行（段落邊界）分割。
- `channels.nextcloud-talk.blockStreaming`：停用此頻道的區塊串流。
- `channels.nextcloud-talk.blockStreamingCoalesce`：區塊串流合併調整。
- `channels.nextcloud-talk.mediaMaxMb`：收入媒體上限（MB）。
