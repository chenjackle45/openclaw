---
title: "Zalo"
summary: "Zalo 機器人支援狀態、功能與設定"
read_when:
  - 處理 Zalo 功能或 Webhook 時
---

# Zalo (Bot API)

狀態：實驗性功能。僅支援私訊；群組功能根據 Zalo 文件說明為「即將推出」。

## 安裝插件

Zalo 不隨核心安裝綑綁。

- 透過 CLI 安裝：`openclaw plugins install @openclaw/zalo`
- 或在入門期間選擇 **Zalo** 並確認安裝提示
- 詳情：[插件](/plugin)

## 快速設定（初學者）

1. 安裝 Zalo 插件：
   - 從原始簽出：`openclaw plugins install ./extensions/zalo`
   - 從 npm（如果已發佈）：`openclaw plugins install @openclaw/zalo`
   - 或在入門期間選擇 **Zalo** 並確認安裝提示
2. 設定令牌：
   - 環境變數：`ZALO_BOT_TOKEN=...`
   - 或設定：`channels.zalo.botToken: "..."`。
3. 重啟 Gateway（或完成入門）。
4. DM 存取預設為配對；初次聯繫時核准配對碼。

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

Zalo 是一個越南中心的訊息應用程式；其 Bot API 讓 Gateway 為 1:1 對話執行機器人。
它適合支援或通知，您想要確定性的路由回 Zalo。

- Gateway 擁有的 Zalo Bot API 頻道。
- 確定性路由：回覆回到 Zalo；模型從不選擇頻道。
- DM 共享代理的主會話。
- 群組尚不受支援（Zalo 文件指出「即將推出」）。

## 設定（快速路徑）

### 1) 建立機器人令牌（Zalo Bot 平台）

1. 前往 **https://bot.zaloplatforms.com** 並登入。
2. 建立新機器人並設定其設定。
3. 複製機器人令牌（格式：`12345689:abc-xyz`）。

### 2) 設定令牌（環境變數或設定）

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

環境變數選項：`ZALO_BOT_TOKEN=...`（僅預設帳戶）。

多帳戶支援：使用 `channels.zalo.accounts` 與每帳戶令牌和可選的 `name`。

3. 重啟 Gateway。Zalo 在令牌已解析時啟動（環境變數或設定）。
4. DM 存取預設為配對。初次聯繫機器人時核准代碼。

## 運作方式（行為）

- 入站訊息被正規化為共享頻道信封加上媒體佔位符。
- 回覆始終路由回同一個 Zalo 聊天。
- 預設長輪詢；webhook 模式可使用 `channels.zalo.webhookUrl`。

## 限制

- 外發文字分塊至 2000 字元（Zalo API 限制）。
- 媒體下載/上傳由 `channels.zalo.mediaMaxMb` 限制（預設 5）。
- 由於 2000 字元限制使串流用處較少，預設停用串流。

## 存取控制（DM）

### DM 存取

- 預設：`channels.zalo.dmPolicy = "pairing"`。未知發送者收到配對碼；訊息在核准前被忽略（代碼在 1 小時後過期）。
- 核准方式：
  - `openclaw pairing list zalo`
  - `openclaw pairing approve zalo <CODE>`
- 配對是預設令牌交換。詳情：[配對](/start/pairing)
- `channels.zalo.allowFrom` 接受數字使用者 ID（無使用者名稱查詢可用）。

## 長輪詢 vs Webhook

- 預設：長輪詢（不需要公開 URL）。
- Webhook 模式：設定 `channels.zalo.webhookUrl` 和 `channels.zalo.webhookSecret`。
  - Webhook 金鑰必須為 8-256 字元。
  - Webhook URL 必須使用 HTTPS。
  - Zalo 使用 `X-Bot-Api-Secret-Token` 標題發送事件進行驗證。
  - Gateway HTTP 在 `channels.zalo.webhookPath` 處處理 webhook 要求（預設為 webhook URL 路徑）。

**註：** 根據 Zalo API 文件，getUpdates（輪詢）和 webhook 互斥。

## 支援的訊息類型

- **文字訊息**：完整支援，2000 字元分塊。
- **圖片訊息**：下載並處理入站圖片；透過 `sendPhoto` 發送圖片。
- **貼圖**：已記錄但未完全處理（無代理回應）。
- **不支援的類型**：已記錄（例如來自受保護使用者的訊息）。

## 功能

| 特性         | 狀態                         |
| --------------- | ------------------------------ |
| 私訊 | 支援                   |
| 群組          | 即將推出（根據 Zalo 文件） |
| 媒體（圖片）  | 支援                   |
| 表情回饋       | 不支援               |
| 執行緒         | 不支援               |
| 民調           | 不支援               |
| 原生指令 | 不支援               |
| 串流       | 已阻止（2000 字元限制）   |

## 交付目標（CLI/cron）

- 使用聊天 ID 作為目標。
- 範例：`openclaw message send --channel zalo --target 123456789 --message "hi"`。

## 疑難排解

**機器人不回應：**

- 檢查令牌是否有效：`openclaw channels status --probe`
- 驗證發送者已核准（配對或 allowFrom）
- 檢查 Gateway 日誌：`openclaw logs --follow`

**Webhook 未接收事件：**

- 確保 webhook URL 使用 HTTPS
- 驗證金鑰令牌為 8-256 字元
- 確認 Gateway HTTP 端點可在設定路徑上存取
- 檢查 getUpdates 輪詢未執行（互斥）

## 設定參考（Zalo）

完整設定：[設定](/gateway/configuration)

供應商選項：

- `channels.zalo.enabled`：啟用/停用頻道啟動。
- `channels.zalo.botToken`：來自 Zalo Bot 平台的機器人令牌。
- `channels.zalo.tokenFile`：從檔案路徑讀取令牌。
- `channels.zalo.dmPolicy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.zalo.allowFrom`：DM 允許清單（使用者 ID）。`open` 需要 `"*"`。精靈會要求數字 ID。
- `channels.zalo.mediaMaxMb`：入站/外發媒體上限（MB，預設 5）。
- `channels.zalo.webhookUrl`：啟用 webhook 模式（需要 HTTPS）。
- `channels.zalo.webhookSecret`：Webhook 金鑰（8-256 字元）。
- `channels.zalo.webhookPath`：Gateway HTTP 伺服器上的 Webhook 路徑。
- `channels.zalo.proxy`：API 要求的代理 URL。

多帳戶選項：

- `channels.zalo.accounts.<id>.botToken`：每帳戶令牌。
- `channels.zalo.accounts.<id>.tokenFile`：每帳戶令牌檔案。
- `channels.zalo.accounts.<id>.name`：顯示名稱。
- `channels.zalo.accounts.<id>.enabled`：啟用/停用帳戶。
- `channels.zalo.accounts.<id>.dmPolicy`：每帳戶 DM 策略。
- `channels.zalo.accounts.<id>.allowFrom`：每帳戶允許清單。
- `channels.zalo.accounts.<id>.webhookUrl`：每帳戶 webhook URL。
- `channels.zalo.accounts.<id>.webhookSecret`：每帳戶 webhook 金鑰。
- `channels.zalo.accounts.<id>.webhookPath`：每帳戶 webhook 路徑。
- `channels.zalo.accounts.<id>.proxy`：每帳戶代理 URL。
