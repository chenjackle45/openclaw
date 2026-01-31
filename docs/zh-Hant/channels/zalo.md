---
title: "Zalo(Zalo Bot API)"
summary: "Zalo 機器人支援狀態、功能與設定"
read_when:
  - 處理 Zalo 功能或 Webhook 時
---
# Zalo (Bot API)

狀態：實驗性功能。目前僅支援私訊對話；群組功能根據 Zalo 文件說明為「即將推出」。

## 安裝插件
此插件不隨核心程式綑綁，需單獨安裝：
```bash
openclaw plugins install @openclaw/zalo
```

## 快速設定（初學者）
1. 安裝 Zalo 插件。
2. 在 [Zalo Bot Platform](https://bot.zaloplatforms.com) 建立機器人並取得 **機器人令牌 (Bot Token)**。
3. 在設定或環境變數 `ZALO_BOT_TOKEN` 中配置令牌。
4. 重啟 Gateway。
5. 私訊存取預設為配對模式，初次聯繫時請核准配對碼。

## 基本設定範例
```json5
{
  channels: {
    zalo: {
      enabled: true,
      botToken: "12345689:abc-xyz",
      dmPolicy: "pairing"
    }
  }
}
```

## 運作行為
- **回覆路由**：回覆會自動導回發送訊息的 Zalo 聊天視窗。
- **輪詢與 Webhook**：預設使用長輪詢 (Long-polling)，若有公開 HTTPS 網址可切換至 Webhook 模式。
- **字數限制**：出站文字每塊上限為 **2000 字元**（Zalo API 限制）。

## 存取控制 (DMs)
- **配對模式**：未知發送者會收到配對碼，需執行 `openclaw pairing approve zalo <代碼>` 核准。
- **允許清單**：可在 `allowFrom` 中使用數字使用者 ID 進行過濾（Zalo 不支援使用者名稱搜尋）。

## 功能概覽
- ✅ 私訊、媒體（圖片）支援
- ❌ 群組、表情回饋、執行緒、原生指令
- ⚠️ 串流回應（因字數限制而預設停用）
