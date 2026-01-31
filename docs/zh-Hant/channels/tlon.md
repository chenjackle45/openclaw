---
title: "Tlon(Tlon/Urbit)"
summary: "Tlon/Urbit 支援狀態、功能與設定"
read_when:
  - 處理 Tlon/Urbit 頻道功能時
---
# Tlon (插件)

Tlon 是一個建構在 Urbit 之上的去中心化通訊軟體。OpenClaw 透過連接至您的 Urbit ship，可以回應私訊 (DMs) 與群組對話訊息。

狀態：透過插件支援。支援私訊、群組標註、執行緒回覆。多媒體內容目前僅支援以 URL 形式附加在文字後方，不支持原生上傳、表情回饋或投票。

## 安裝插件
此插件不隨核心程式綑綁，需單獨裝：
```bash
openclaw plugins install @openclaw/tlon
```

## 快速設定
1. 安裝 Tlon 插件。
2. 準備好您的 ship 網址與登入代碼。
3. 在 `channels.tlon` 中進行設定。
4. 重啟 Gateway。
5. 對機器人發送私訊，或在群組中標註它。

## 基本設定範例
```json5
{
  channels: {
    tlon: {
      enabled: true,
      ship: "~sampel-palnet",
      url: "https://your-ship-host",
      code: "lidlut-tabwed-pillex-ridrup"
    }
  }
}
```

## 群組頻道
- **自動探索**：預設啟用，機器人會自動尋找可用的頻道。
- **固定頻道**：您可以在 `groupChannels` 中手動指定頻道路徑。

## 存取控制
- **私訊允許清單**：在 `dmAllowlist` 中指定允許對話的 ship。
- **群組授權**：可在 `authorization` 欄位中針對不同頻道設定 `restricted`（限制成員）或 `open`（開放）模式。

## 備註
- 群組回覆需要有 @標註（即 `~您的機器人ship名稱`）才會觸發。
- 如果入站訊息位於執行緒中，OpenClaw 會在同一個執行緒中進行回應。
