---
title: "Browser login(瀏覽器登入與 X/Twitter 發文)"
summary: "瀏覽器自動化的手動登入建議以及 X/Twitter 發文工作流"
read_when:
  - 您需要登入網站以進行瀏覽器自動化時
  - 您想要在 X/Twitter 上發布更新時
---

# 瀏覽器登入與 X/Twitter 發文

## 手動登入 (建議做法)

當網站要求登入時，請在**宿主機 (Host)** 的瀏覽器設定檔（即 `openclaw` 瀏覽器）中**手動進行登入**。

**切勿**將您的帳號密碼交給模型。自動登入行為極易觸發網站的防機器人機制，可能導致帳號被鎖定。

## 如何開啟 OpenClaw 專屬瀏覽器？

OpenClaw 控制一個名為 `openclaw` 的獨立 Chrome 設定檔（UI 帶有橘色標記），這與您的日常瀏覽器是分開的。

有兩種簡單的開啟方式：
1. **指示 Agent 開啟瀏覽器**，然後您自己在跳出的視線中登入。
2. **透過 CLI 開啟**：
   ```bash
   openclaw browser start
   openclaw browser open https://x.com
   ```
   若您有多個設定檔，請帶上 `--browser-profile <名稱>` 參數（預設為 `openclaw`）。

## X/Twitter：推薦工作流
- **讀取/搜尋/串貼**：建議使用 **bird** CLI 技能（不透由瀏覽器，更穩定）。
- **發布更新**：使用**宿主機瀏覽器**（手動登入後交由 Agent 操作）。

## 沙盒環境與宿主機瀏覽器存取
沙盒內的瀏覽器會話**極高機率**會觸發機器人檢測。對於 X/Twitter 或其他具備嚴格檢測的網站，請優先選擇**宿主機 (Host)** 瀏覽器。

若 Agent 執行於沙盒中，您需在配置中允許其控制宿主機：
```json5
{
  agents: {
    defaults: {
      sandbox: {
        browser: {
          allowHostControl: true
        }
      }
    }
  }
}
```
接著呼叫工具時指定目標：
```bash
openclaw browser open https://x.com --target host
```
或者，直接針對該特定任務停用沙盒模式。
