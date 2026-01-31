---
title: "message(訊息發送)"
summary: "`openclaw message` CLI 參考（發送訊息與執行頻道動作）"
read_when:
  - 想要新增或修改訊息相關的 CLI 動作時
  - 想要調整外發頻道的行為模式時
---

# `openclaw message`

用於發送訊息與執行頻道動作的統一入口指令（支援 Discord、Google Chat、Slack、Mattermost、Telegram、WhatsApp、Signal、iMessage 與 MS Teams）。

## 基本用法

```bash
openclaw message <子指令> [旗標]
```

**頻道選擇**：
- 若配置了多個頻道，則必須指定 `--channel`。
- 若僅配置了一個頻道，系統會將其設為預設。
- 支援數值：`whatsapp|telegram|discord|googlechat|slack|mattermost|signal|imessage|msteams`（Mattermost 需要安裝外掛）。

**目標格式 (`--target`)**：
- **WhatsApp**：E.164 格式號碼或群組 JID。
- **Telegram**：聊天 ID 或 `@使用者名稱`。
- **Discord**：`channel:<ID>` 或 `user:<ID>`（或 `<@ID>` 提及；純數值 ID 會被視為頻道）。
- **Google Chat**：`spaces/<空間ID>` 或 `users/<使用者ID>`。
- **Slack**：`channel:<ID>` 或 `user:<ID>`（亦可接受原始頻道 ID）。
- **Mattermost**：`channel:<ID>`、`user:<ID>` 或 `@使用者名稱`。
- **Signal**：`+E.164`、`group:<ID>`、`signal:+E.164`、`signal:group:<ID>` 或 `username:<名稱>`。
- **iMessage**：Handle、`chat_id:<ID>`、`chat_guid:<GUID>` 或 `chat_identifier:<ID>`。
- **MS Teams**：對話 ID (`19:...@thread.tacv2`)、`conversation:<ID>` 或 `user:<AAD-物件-ID>`。

**名稱查詢**：
- 對於支援的供應商（如 Discord/Slack 等），像 `Help` 或 `#help` 這樣的頻道名稱會透過目錄快取進行解析。若快取未命中，則會嘗試執行即時目錄查詢。

## 常用參數

- `--channel <名稱>`：指定通訊頻道。
- `--account <ID>`：指定使用的帳戶。
- `--target <目的地>`：目標頻道或使用者。
- `--targets <名稱>`：指定多個目的地（僅適用於廣播）。
- `--json`：機器可讀輸出。
- `--dry-run`：執行測試而不實際發送。

## 動作子指令

### 核心功能 (Core)

- `send` (發送)：最基礎的訊息發送。
  - **必要參數**：`--target` 以及 `--message` 或 `--media`。
  - **選用參數**：`--reply-to` (回覆 ID)、`--thread-id` (討論串 ID)、`--gif-playback`。
- `poll` (投票)：發起投票動作。
  - **必要參數**：`--target`, `--poll-question`, `--poll-option` (可重複)。
- `react` (表情回應)：對特定訊息新增或移除表情符號回應。
  - **必要參數**：`--message-id`, `--target`。
  - **選用參數**：`--emoji`, `--remove`。
- `read` (讀取訊息)：讀取歷史訊息內容。
- `edit` / `delete` (編輯/刪除)：對已發送訊息進行操作。
- `pin` / `unpin` / `pins` (置頂管理)：訊息置頂操作。

### 討論串 (Threads)
- `thread create`：建立新的討論串。
- `thread list`：列出討論串。
- `thread reply`：回覆特定的討論串。

### 表情符號與貼圖 (Emojis & Stickers)
- `emoji list` / `emoji upload`：管理表情符號。
- `sticker send` / `sticker upload`：發送或上傳貼圖。

### 角色 / 頻道 / 成員 / 語音 (Moderation & Voice)
- `role info / add / remove`：管理功能權限組。
- `channel info / list`：查看頻道資訊。
- `member info`：查看成員資訊。
- `voice status`：查看語音頻道狀態。

### 活動 (Events)
- `event list` / `event create`：管理 Discord 排程活動。

### 管理功能 (Moderation)
- `timeout`：禁言成員。
- `kick`：踢出成員。
- `ban`：封鎖成員。

### 廣播 (Broadcast)
- `broadcast`：將訊息發送至多個目的地（可跨不同頻道）。

## 指令範例

**發送 Discord 回覆**：
```bash
openclaw message send --channel discord \
  --target channel:123 --message "你好" --reply-to 456
```

**發起 Discord 投票**：
```bash
openclaw message poll --channel discord \
  --target channel:123 \
  --poll-question "今天下午吃什麼？" \
  --poll-option 披薩 --poll-option 壽司 \
  --poll-multi --poll-duration-hours 48
```

**發送 Telegram 行內按鈕 (Inline Buttons)**：
```bash
openclaw message send --channel telegram --target @mychat --message "請選擇：" \
  --buttons '[ [{"text":"是","callback_data":"cmd:yes"}], [{"text":"否","callback_data":"cmd:no"}] ]'
```
