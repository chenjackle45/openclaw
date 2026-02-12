---
summary: "瀏覽器自動化的手動登入及 X/Twitter 發文"
read_when:
  - You need to log into sites for browser automation
  - You want to post updates to X/Twitter
title: "Browser Login（瀏覽器登入）"
---

# 瀏覽器登入及 X/Twitter 發文

## 手動登入（推薦）

當網站需要登入時，請在**主機** 瀏覽器設定檔（OpenClaw 瀏覽器）**手動登入**。

**不要**將認證資訊提供給模型。自動登入經常會觸發反機器人防護，可能導致帳戶被鎖定。

返回主要瀏覽器文件：[Browser](/zh-Hant/tools/browser)。

## 使用哪個 Chrome 設定檔？

OpenClaw 控制一個**專用 Chrome 設定檔**（名稱為 `openclaw`，UI 帶有橙色色調）。這與日常瀏覽器設定檔不同。

兩種簡單方式來存取它：

1. **要求代理開啟瀏覽器**，然後自己登入。
2. **透過 CLI 開啟**：

```bash
openclaw browser start
openclaw browser open https://x.com
```

如果有多個設定檔，傳遞 `--browser-profile <name>`（預設為 `openclaw`）。

## X/Twitter：推薦流程

- **讀取/搜尋/執行緒**：使用**主機** 瀏覽器（手動登入）。
- **發文更新**：使用**主機** 瀏覽器（手動登入）。

## 沙箱化及主機瀏覽器存取

沙箱化瀏覽器工作階段**更可能**觸發機器人偵測。針對 X/Twitter（及其他嚴格網站），優先選擇**主機** 瀏覽器。

如果代理已沙箱化，瀏覽器工具預設為沙箱。若要允許主機控制：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        browser: {
          allowHostControl: true,
        },
      },
    },
  },
}
```

接著指定主機瀏覽器：

```bash
openclaw browser open https://x.com --browser-profile openclaw --target host
```

或為發文更新的代理停用沙箱化。
