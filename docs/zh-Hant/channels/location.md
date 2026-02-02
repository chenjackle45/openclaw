---
summary: "Inbound channel location parsing (Telegram + WhatsApp) and context fields"
read_when:
  - Adding or modifying channel location parsing
  - Using location context fields in agent prompts or tools
title: "Channel Location Parsing"
---

# 頻道位置解析

OpenClaw 將共享位置從聊天頻道正規化為：

- 附加至入站正文的易讀文字，以及
- 自動回覆上下文負載中的結構化欄位。

目前支援：

- **Telegram**（位置圖釘 + 地點 + 即時位置）
- **WhatsApp**（locationMessage + liveLocationMessage）
- **Matrix**（具有 `geo_uri` 的 `m.location`）

## 文字格式

位置呈現為沒有方括號的友好行：

- 圖釘：
  - `📍 48.858844, 2.294351 ±12m`
- 具名地點：
  - `📍 Eiffel Tower — Champ de Mars, Paris (48.858844, 2.294351 ±12m)`
- 即時分享：
  - `🛰 Live location: 48.858844, 2.294351 ±12m`

如果頻道包含標題/註解，它會附加在下一行：

```
📍 48.858844, 2.294351 ±12m
Meet here
```

## 上下文欄位

當位置存在時，這些欄位被新增到 `ctx`：

- `LocationLat`（數字）
- `LocationLon`（數字）
- `LocationAccuracy`（數字，公尺；選用）
- `LocationName`（字串；選用）
- `LocationAddress`（字串；選用）
- `LocationSource`（`pin | place | live`）
- `LocationIsLive`（布林值）

## 頻道注意事項

- **Telegram**：地點映射到 `LocationName/LocationAddress`；即時位置使用 `live_period`。
- **WhatsApp**：`locationMessage.comment` 和 `liveLocationMessage.caption` 被附加為標題行。
- **Matrix**：`geo_uri` 被解析為圖釘位置；高度被忽略且 `LocationIsLive` 始終為 false。
