---
title: "Zalo"
summary: "Zalo Bot API 支援狀態、功能與設定"
read_when:
  - 處理 Zalo 功能或 Webhook 時
---

# Zalo (Bot API)

狀態：實驗性功能。支援私訊；群組處理可透過明確的群組策略控制啟用。

## 需要外掛程式

Zalo 以外掛程式形式發布，未隨核心安裝捆綁。

- 透過 CLI 安裝：`openclaw plugins install @openclaw/zalo`
- 或在入門期間選擇 **Zalo** 並確認安裝提示
- 詳情：[Plugins](/zh-Hant/tools/plugin)

## 快速設定（初學者）

1. 安裝 Zalo 外掛程式：
   - 從原始碼 checkout：`openclaw plugins install ./extensions/zalo`
   - 從 npm（如已發布）：`openclaw plugins install @openclaw/zalo`
   - 或在入門期間選擇 **Zalo** 並確認安裝提示
2. 設定 token：
   - 環境變數：`ZALO_BOT_TOKEN=...`
   - 或設定：`channels.zalo.botToken: "..."`
3. 重啟 Gateway（或完成入門）。
4. DM 存取預設為配對；初次聯絡時核准配對碼。

最小設定：

```json5
{
  channels: {
    zalo: {
      enabled: true,
      botToken: "12345689:abc-xyz",
      dmPolicy: "pairing",
    },
  },
}
```

## 這是什麼

Zalo 是一個以越南為核心的訊息應用程式；其 Bot API 讓 Gateway 為 1:1 對話執行 bot。
適合支援或通知場景，需要確定性地路由回 Zalo。

- Gateway 擁有的 Zalo Bot API 頻道。
- 確定性路由：回覆路由回 Zalo；模型不選擇頻道。
- DM 共享 agent 的主要工作階段。
- 群組已支援，配備策略控制（`groupPolicy` + `groupAllowFrom`），預設為安全的 allowlist 模式。

## 設定（快速路徑）

### 1) 建立 bot token（Zalo Bot 平台）

1. 前往 [https://bot.zaloplatforms.com](https://bot.zaloplatforms.com) 並登入。
2. 建立新 bot 並設定其參數。
3. 複製 bot token（格式：`12345689:abc-xyz`）。

### 2) 設定 token（環境變數或設定）

範例：

```json5
{
  channels: {
    zalo: {
      enabled: true,
      botToken: "12345689:abc-xyz",
      dmPolicy: "pairing",
    },
  },
}
```

環境變數選項：`ZALO_BOT_TOKEN=...`（僅適用於預設帳號）。

多帳號支援：使用 `channels.zalo.accounts` 搭配每帳號 token 和可選的 `name`。

3. 重啟 Gateway。Zalo 在 token 已解析時啟動（環境變數或設定）。
4. DM 存取預設為配對。初次聯絡 bot 時核准配對碼。

## 運作方式（行為）

- 入站訊息被正規化為共享頻道 envelope，包含媒體佔位符。
- 回覆始終路由回同一個 Zalo 聊天。
- 預設長輪詢；webhook 模式可使用 `channels.zalo.webhookUrl`。

## 限制

- 外發文字分塊至 2000 字元（Zalo API 限制）。
- 媒體下載/上傳由 `channels.zalo.mediaMaxMb` 限制（預設 5）。
- 由於 2000 字元限制使串流效益有限，串流預設停用。

## 存取控制（DM）

### DM 存取

- 預設：`channels.zalo.dmPolicy = "pairing"`。未知發送者收到配對碼；訊息在核准前被忽略（配對碼 1 小時後過期）。
- 核准方式：
  - `openclaw pairing list zalo`
  - `openclaw pairing approve zalo <CODE>`
- 配對是預設的 token 交換機制。詳情：[配對](/zh-Hant/start/pairing)
- `channels.zalo.allowFrom` 接受數字使用者 ID（無使用者名稱查詢功能）。

## 存取控制（群組）

- `channels.zalo.groupPolicy` 控制群組入站處理：`open | allowlist | disabled`。
- 預設行為為安全關閉：`allowlist`。
- `channels.zalo.groupAllowFrom` 限制哪些發送者 ID 可在群組中觸發 bot。
- 若未設定 `groupAllowFrom`，Zalo 退回使用 `allowFrom` 進行發送者檢查。
- `groupPolicy: "disabled"` 封鎖所有群組訊息。
- `groupPolicy: "open"` 允許任何群組成員（受提及閘控）。
- 執行時注意：若 `channels.zalo` 完全缺失，執行時仍會退回到 `groupPolicy="allowlist"` 以確保安全。

## 長輪詢 vs Webhook

- 預設：長輪詢（不需要公開 URL）。
- Webhook 模式：設定 `channels.zalo.webhookUrl` 和 `channels.zalo.webhookSecret`。
  - Webhook secret 必須為 8-256 字元。
  - Webhook URL 必須使用 HTTPS。
  - Zalo 傳送事件時附帶 `X-Bot-Api-Secret-Token` 標頭進行驗證。
  - Gateway HTTP 在 `channels.zalo.webhookPath`（預設為 webhook URL 路徑）處理 webhook 請求。
  - 請求必須使用 `Content-Type: application/json`（或 `+json` 媒體類型）。
  - 重複事件（`event_name + message_id`）在短暫的重播時間窗口內會被忽略。
  - 爆量流量按路徑/來源進行速率限制，可能回傳 HTTP 429。

**注意：** getUpdates（輪詢）和 webhook 根據 Zalo API 文件為互斥模式。

## 支援的訊息類型

- **文字訊息**：完整支援，含 2000 字元分塊。
- **圖片訊息**：下載並處理入站圖片；透過 `sendPhoto` 傳送圖片。
- **貼圖**：已記錄但未完整處理（不產生 agent 回應）。
- **不支援的類型**：已記錄（例如來自受保護使用者的訊息）。

## 功能

| 功能         | 狀態                                  |
| ------------ | ------------------------------------- |
| 私訊         | ✅ 支援                               |
| 群組         | ⚠️ 支援，含策略控制（預設 allowlist） |
| 媒體（圖片） | ✅ 支援                               |
| Reactions    | ❌ 不支援                             |
| Threads      | ❌ 不支援                             |
| 投票         | ❌ 不支援                             |
| 原生指令     | ❌ 不支援                             |
| 串流         | ⚠️ 已停用（2000 字元限制）            |

## 傳遞目標（CLI/cron）

- 使用聊天 ID 作為目標。
- 範例：`openclaw message send --channel zalo --target 123456789 --message "hi"`。

## 疑難排解

**Bot 不回應：**

- 確認 token 有效：`openclaw channels status --probe`
- 確認發送者已核准（配對或 allowFrom）
- 檢查 Gateway 日誌：`openclaw logs --follow`

**Webhook 未收到事件：**

- 確保 webhook URL 使用 HTTPS
- 確認 secret token 為 8-256 字元
- 確認 Gateway HTTP 端點可在設定路徑上存取
- 確認 getUpdates 輪詢未執行（兩者互斥）

## 設定參考（Zalo）

完整設定：[設定](/zh-Hant/gateway/configuration)

提供者選項：

- `channels.zalo.enabled`：啟用/停用頻道啟動。
- `channels.zalo.botToken`：來自 Zalo Bot 平台的 bot token。
- `channels.zalo.tokenFile`：從一般檔案路徑讀取 token。不接受符號連結。
- `channels.zalo.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.zalo.allowFrom`：DM allowlist（使用者 ID）。`open` 需要 `"*"`。設定精靈會要求數字 ID。
- `channels.zalo.groupPolicy`：`open | allowlist | disabled`（預設：allowlist）。
- `channels.zalo.groupAllowFrom`：群組發送者 allowlist（使用者 ID）。未設定時退回 `allowFrom`。
- `channels.zalo.mediaMaxMb`：入站/外發媒體上限（MB，預設 5）。
- `channels.zalo.webhookUrl`：啟用 webhook 模式（需要 HTTPS）。
- `channels.zalo.webhookSecret`：Webhook secret（8-256 字元）。
- `channels.zalo.webhookPath`：Gateway HTTP 伺服器上的 webhook 路徑。
- `channels.zalo.proxy`：API 請求的代理 URL。

多帳號選項：

- `channels.zalo.accounts.<id>.botToken`：每帳號 token。
- `channels.zalo.accounts.<id>.tokenFile`：每帳號一般 token 檔案。不接受符號連結。
- `channels.zalo.accounts.<id>.name`：顯示名稱。
- `channels.zalo.accounts.<id>.enabled`：啟用/停用帳號。
- `channels.zalo.accounts.<id>.dmPolicy`：每帳號 DM 策略。
- `channels.zalo.accounts.<id>.allowFrom`：每帳號 allowlist。
- `channels.zalo.accounts.<id>.groupPolicy`：每帳號群組策略。
- `channels.zalo.accounts.<id>.groupAllowFrom`：每帳號群組發送者 allowlist。
- `channels.zalo.accounts.<id>.webhookUrl`：每帳號 webhook URL。
- `channels.zalo.accounts.<id>.webhookSecret`：每帳號 webhook secret。
- `channels.zalo.accounts.<id>.webhookPath`：每帳號 webhook 路徑。
- `channels.zalo.accounts.<id>.proxy`：每帳號代理 URL。
