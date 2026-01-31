---
title: "Nostr(Nostr 插件)"
summary: "透過 NIP-04 加密訊息的 Nostr 私訊頻道"
read_when:
  - 您想讓 OpenClaw 接收來自 Nostr 的私訊時
  - 您正在設定去中心化訊息功能時
---
# Nostr (插件)

**狀態**：選配插件 (預設停用)。

Nostr 是一個去中心化的社交網路協定。此頻道讓 OpenClaw 能透過 NIP-04 協定接收與回應加密私訊 (DMs)。

## 安裝方式
您可以透過 `openclaw onboard` 入門精靈安裝，或手動執行：
```bash
openclaw plugins install @openclaw/nostr
```

## 快速設定
1. 生成 Nostr 金鑰對（取得 `nsec` 私鑰）。
2. 在設定中加入私鑰：
```json
{
  "channels": {
    "nostr": {
      "privateKey": "${NOSTR_PRIVATE_KEY}",
      "relays": ["wss://relay.damus.io", "wss://nos.lol"]
    }
  }
}
```
3. 重啟 Gateway。

## 個人資料元數據 (Profile metadata)
您可以設定機器人在 Nostr 網路上的顯示名稱、頭像、簡介等（遵循 NIP-01 規範）。這些資訊可以從控制 UI 或設定檔中調整。

## 存取控制
- **配對模式 (pairing)**：預設模式，未知發送者會收到配對碼。
- **允許清單 (allowlist)**：僅允許 `allowFrom` 中指定的公鑰發送訊息。
- **開放模式 (open)**：接收所有人的訊息（需設定 `allowFrom: ["*"]`）。

## 中繼站 (Relays)
建議使用 2-3 個中繼站以確保連線冗餘。您可以手動新增您信任的中繼站網址。

## 目前支援的規範 (NIPs)
- ✅ NIP-01: 基礎事件格式與個人資料
- ✅ NIP-04: 加密私訊
- ⏳ NIP-17: 禮物包裝私訊 (計劃中)

## 限制
- 僅限私訊（無群組功能）。
- 目前不支持媒體附件。
