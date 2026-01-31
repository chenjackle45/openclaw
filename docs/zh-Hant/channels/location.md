---
title: "Location(位置解析)"
summary: "入站頻道位置解析（Telegram 與 WhatsApp）與上下文欄位"
read_when:
  - 新增或修改頻道位置解析邏輯時
  - 在代理提示詞或工具中使用位置上下文欄位時
---
# Channel Location Parsing（頻道位置解析）

OpenClaw 會將聊天頻道中分享的位置資訊正規化為：
- 附加在入站訊息正文中的易讀文字。
- 自動回覆上下文 (Context) 負載中的結構化欄位。

## 目前支援的平台
- **Telegram**（定位圖釘、地點與即時位置）
- **WhatsApp**（位置訊息與即時位置訊息）
- **Matrix**（帶有 `geo_uri` 的 `m.location`）

## 文字格式
位置會渲染為不含方括號的友好行文字：
- **一般定位**：`📍 48.858844, 2.294351 ±12m`
- **具名地點**：`📍 Eiffel Tower — Champ de Mars, Paris (48.858844, 2.294351 ±12m)`
- **即時分享**：`🛰 即時位置: 48.858844, 2.294351 ±12m`

如果頻道包含說明/註解，會顯示在下一行：
```
📍 48.858844, 2.294351 ±12m
在這邊見面
```

## 上下文欄位 (Context fields)
當訊息包含位置時，以下欄位會被加入 `ctx` 中：
- `LocationLat` (緯度，數字)
- `LocationLon` (經度，數字)
- `LocationAccuracy` (精確度，公尺；選配)
- `LocationName` (地點名稱；選配)
- `LocationAddress` (地址；選配)
- `LocationSource` (來源類型：`pin | place | live`)
- `LocationIsLive` (布林值，是否為即時位置)

## 平台備註
- **Telegram**：地點會映射到 `LocationName/LocationAddress`；即時位置使用 `live_period`。
- **WhatsApp**：`locationMessage.comment` 和 `liveLocationMessage.caption` 會被視為說明行附加。
- **Matrix**：`geo_uri` 會被解析為定位圖釘；高度資訊會被忽略且 `LocationIsLive` 恆為 false。
