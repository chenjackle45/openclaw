---
title: "Slash commands(斜線指令)"
summary: "斜線指令：文字型 vs 原生型、配置選項與支援的指令清單"
read_when:
  - 使用或配置聊天指令時
  - 偵錯指令路由或權限問題時
---

# 斜線指令 (Slash commands)

所有指令皆由 Gateway 處理。大部分指令必須作為以 `/` 開頭的**獨立訊息**發送。
宿主機專用的 Bash 指令使用 `! <指令>`（別名為 `/bash <指令>`）。

系統分為兩大類：
- **指令 (Commands)**：獨立的 `/...` 訊息（如 `/help`, `/status`）。
- **指示語 (Directives)**：如 `/think`, `/verbose`, `/model` 等。
  - 指示語在傳送給模型前會被過濾。
  - **指令訊息**：若訊息僅包含指示語，則會持久化至該會話。
  - **內嵌提示**：若混合了一般文字，則僅作為本次執行的臨時提示。

## 配置說明

```json5
{
  commands: {
    native: "auto",      // 是否註冊平台原生指令（如 Discord/Telegram）
    text: true,          // 是否啟用一般文字訊息中的 / 指令解析
    bash: false,         // 是否啟用 ! <指令>
    config: false,       // 是否啟用 /config 修改配置
    useAccessGroups: true // 是否強制執行權限群組檢查
  }
}
```

## 指令清單 (部分摘要)

- `/help` / `/commands`：顯示幫助。
- `/status`：查看當前系統狀態與模型配額。
- `/skill <名稱> [輸入]`：手動執行特定技能。
- `/config show|get|set`：查看或動態修改 `openclaw.json`（僅限擁有者）。
- `/model <名稱>`：切換當前會話使用的模型（別名：`/m`）。
- `/think <等級>`：調整思考深度（off/low/medium/high/xhigh）。
- `/verbose on|off`：開啟詳細日誌（別名：`/v`）。
- `/usage off|tokens|cost`：控制每條回應後的 Token 消耗與成本顯示。
- `/reset` / `/new`：重設當前會話。
- `/stop`：中止正在執行的 Agent。

## 使用注意事項
- **權限控制**：指示語與敏感指令僅對**授權發送者**生效。
- **快速路徑**：純指令訊息會繞過訊息佇列與模型，即時執行。
- **技能指令**：設定為 `user-invocable` 的技能會自動對應為斜線指令。名稱會經過標準化（a-z0-9_）。
- **模型選擇**：`/model` 會彈出數字選單，方便快速切換不同供應商的模型。
- **安全性**：`/reasoning` 與 `/verbose` 可能會暴露內部工具的輸出，在群組聊天中建議保持關閉。
