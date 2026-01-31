---
title: "Nextcloud talk(Nextcloud Talk 插件)"
summary: "Nextcloud Talk 支援狀態、功能與設定"
read_when:
  - 處理 Nextcloud Talk 頻道功能時
---
# Nextcloud Talk (插件)

狀態：透過插件（Webhook 機器人）支援。支援私訊、聊天室、表情回饋與 Markdown 訊息。

## 安裝插件
此插件不隨核心程式綑綁，需單獨安裝：
```bash
openclaw plugins install @openclaw/nextcloud-talk
```

## 快速設定（初學者）
1. 安裝插件。
2. 在您的 Nextcloud 伺服器上建立機器人：
   ```bash
   ./occ talk:bot:install "OpenClaw" "<共享金鑰>" "<webhook-url>" --feature reaction
   ```
3. 在目標聊天室的設定中啟用此機器人。
4. 設定 OpenClaw 的 `baseUrl` 與 `botSecret`。
5. 啟動 Gateway。

## 備註
- **私訊限制**：機器人無法主動發起私訊，使用者必須先對機器人發送訊息。
- **媒體支援**：機器人 API 目前不支援媒體上傳，多媒體內容會以 URL 形式發送。
- **認證建議**：建議設定 `apiUser` 與 `apiPassword` 以輔助私訊與房間的自動辨識。

## 存取控制
- **私訊**：預設使用配對模式。核准指令：`openclaw pairing approve nextcloud-talk <代碼>`。
- **房間**：預設使用允許清單 (`allowlist`)。

## 功能概覽
- ✅ 私訊、房間、表情回饋
- ❌ 執行緒 (Threads)、原生指令
- ⚠️ 媒體檔案僅支援 URL
