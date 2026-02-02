---
title: "Nostr"
summary: "透過 NIP-04 加密訊息的 Nostr 私訊頻道"
read_when:
  - 您想讓 OpenClaw 接收來自 Nostr 的私訊時
  - 您正在設定去中心化訊息功能時
---

# Nostr

**狀態：** 選配插件（預設停用）。

Nostr 是一個去中心化社交網路協定。此頻道讓 OpenClaw 能透過 NIP-04 接收與回應加密直接訊息（DM）。

## 隨需安裝

### 入門（推薦）

- 入門精靈（`openclaw onboard`）與 `openclaw channels add` 列出選配頻道插件。
- 選擇 Nostr 會提示您隨需安裝插件。

安裝預設值：

- **開發頻道 + 可用 git 簽出：** 使用本地插件路徑。
- **穩定/測試版：** 從 npm 下載。

您可以始終在提示中覆寫選擇。

### 手動安裝

```bash
openclaw plugins install @openclaw/nostr
```

使用本地簽出（開發工作流程）：

```bash
openclaw plugins install --link <path-to-openclaw>/extensions/nostr
```

安裝或啟用插件後重啟 Gateway。

## 快速設定

1. 生成 Nostr 金鑰對（如果需要）：

```bash
# 使用 nak
nak key generate
```

2. 新增到設定：

```json
{
  "channels": {
    "nostr": {
      "privateKey": "${NOSTR_PRIVATE_KEY}"
    }
  }
}
```

3. 匯出金鑰：

```bash
export NOSTR_PRIVATE_KEY="nsec1..."
```

4. 重啟 Gateway。

## 設定參考

| 金鑰          | 類型     | 預設                                     | 說明                         |
| ------------ | -------- | ------------------------------------------- | ----------------------------------- |
| `privateKey` | 字串   | 必需                                    | `nsec` 或十六進位格式的私鑰 |
| `relays`     | 字串[] | `['wss://relay.damus.io', 'wss://nos.lol']` | 中繼站 URL (WebSocket)              |
| `dmPolicy`   | 字串   | `pairing`                                   | DM 存取策略                    |
| `allowFrom`  | 字串[] | `[]`                                        | 允許的發送者公鑰              |
| `enabled`    | 布林  | `true`                                      | 啟用/停用頻道              |
| `name`       | 字串   | -                                           | 顯示名稱                        |
| `profile`    | 物件   | -                                           | NIP-01 個人資料元資料             |

## 個人資料元資料

個人資料資料發佈為 NIP-01 `kind:0` 事件。您可以從控制 UI（頻道 -> Nostr -> 個人資料）或直接在設定中管理它。

範例：

```json
{
  "channels": {
    "nostr": {
      "privateKey": "${NOSTR_PRIVATE_KEY}",
      "profile": {
        "name": "openclaw",
        "displayName": "OpenClaw",
        "about": "Personal assistant DM bot",
        "picture": "https://example.com/avatar.png",
        "banner": "https://example.com/banner.png",
        "website": "https://example.com",
        "nip05": "openclaw@example.com",
        "lud16": "openclaw@example.com"
      }
    }
  }
}
```

備註：

- 個人資料 URL 必須使用 `https://`。
- 從中繼站匯入合併欄位並保留本地覆寫。

## 存取控制

### DM 策略

- **pairing**（預設）：未知發送者獲得配對碼。
- **allowlist**：僅 `allowFrom` 中的公鑰可以 DM。
- **open**：公開入站 DM（需要 `allowFrom: ["*"]`）。
- **disabled**：忽略入站 DM。

### 允許清單範例

```json
{
  "channels": {
    "nostr": {
      "privateKey": "${NOSTR_PRIVATE_KEY}",
      "dmPolicy": "allowlist",
      "allowFrom": ["npub1abc...", "npub1xyz..."]
    }
  }
}
```

## 金鑰格式

接受的格式：

- **私鑰：** `nsec...` 或 64 字元十六進位
- **公鑰（`allowFrom`）：** `npub...` 或十六進位

## 中繼站

預設值：`relay.damus.io` 和 `nos.lol`。

```json
{
  "channels": {
    "nostr": {
      "privateKey": "${NOSTR_PRIVATE_KEY}",
      "relays": ["wss://relay.damus.io", "wss://relay.primal.net", "wss://nostr.wine"]
    }
  }
}
```

提示：

- 使用 2-3 個中繼站確保冗餘。
- 避免太多中繼站（延遲、重複）。
- 付費中繼站可以改善可靠性。
- 本地中繼站適合測試（`ws://localhost:7777`）。

## 協定支援

| NIP    | 狀態    | 說明                           |
| ------ | --------- | ------------------------------------- |
| NIP-01 | 支援 | 基礎事件格式 + 個人資料元資料 |
| NIP-04 | 支援 | 加密 DM（`kind:4`）              |
| NIP-17 | 計劃中   | 禮物包裝 DM                      |
| NIP-44 | 計劃中   | 版本化加密                  |

## 測試

### 本地中繼站

```bash
# 啟動 strfry
docker run -p 7777:7777 ghcr.io/hoytech/strfry
```

```json
{
  "channels": {
    "nostr": {
      "privateKey": "${NOSTR_PRIVATE_KEY}",
      "relays": ["ws://localhost:7777"]
    }
  }
}
```

### 手動測試

1. 從日誌記下機器人公鑰（npub）。
2. 開啟 Nostr 客戶端（Damus、Amethyst 等）。
3. DM 機器人公鑰。
4. 驗證回應。

## 疑難排解

### 未接收訊息

- 驗證私鑰有效。
- 確保中繼站 URL 可存取且使用 `wss://`（或本地 `ws://`）。
- 確認 `enabled` 不是 `false`。
- 檢查 Gateway 日誌以了解中繼站連線錯誤。

### 未傳送回應

- 檢查中繼站接受寫入。
- 驗證外發連線。
- 注意中繼站速率限制。

### 重複回應

- 使用多個中繼站時預期。
- 訊息由事件 ID 去重複；僅第一次交付觸發回應。

## 安全

- 絕不提交私鑰。
- 為金鑰使用環境變數。
- 對於生產機器人考慮 `allowlist`。

## 限制（MVP）

- 僅直接訊息（無群組聊天）。
- 無媒體附件。
- 僅 NIP-04（計劃 NIP-17 禮物包裝）。
