---
title: "Browser(瀏覽器管理)"
summary: "整合式瀏覽器控制服務與動作指令說明"
---

# 瀏覽器管理 (Browser)

OpenClaw 可以執行一個**專屬的 Chrome/Brave/Edge/Chromium 設定檔**，並由 Agent 全權控制。這與您的個人瀏覽器完全隔離，由 Gateway 內部的本地控制服務進行管理。

## 核心特色
- **獨立設定檔**：名為 `openclaw` 的獨立瀏覽器，不會干擾您的個人資料。
- **Agent 專屬控制**：Agent 可以安全地開啟分頁、讀取頁面、點擊並輸入文字。
- **多設定檔支援**：可同時管理 `openclaw`、`work`、`remote` 等不同情境的瀏覽器執行。

## 快速啟動
```bash
openclaw browser --browser-profile openclaw status  # 查看狀態
openclaw browser --browser-profile openclaw start   # 啟動瀏覽器
openclaw browser --browser-profile openclaw open https://example.com # 開啟網址
```

## 設定檔：`openclaw` vs `chrome`
- `openclaw`：**受管且隔離**的瀏覽器（無需安裝擴充功能）。
- `chrome`：**系統瀏覽器**的擴充功能轉發（需要安裝並開啟 OpenClaw 擴充功能）。

## 配置說明 (`openclaw.json`)
```json5
{
  browser: {
    enabled: true,
    defaultProfile: "openclaw", // 預設使用的設定檔
    executablePath: "/path/to/browser", // 自訂瀏覽器路徑
    profiles: {
      openclaw: { cdpPort: 18800 },
      remote: { cdpUrl: "http://10.0.0.42:9222" }
    }
  }
}
```

## 本地與遠端控制
- **本地控制**：Gateway 直接啟動本地瀏覽器執行個體。
- **節點代理 (Node Proxy)**：若您在另一台電腦上執行 Node Host，Gateway 可以自動將瀏覽器指令路由至該節點。
- **Browserless**：支援連接至雲端託管的 [Browserless](https://browserless.io) 服務。

## 快照與定位符 (Snapshots & Refs)
OpenClaw 支援兩種 UI 定位風格，避免 Agent 使用脆弱的 CSS 選取器：
1. **AI 快照 (數字標記)**：帶有 `aria-ref="12"` 等編號的文字結構，最適合模型理解。
2. **角色快照 (e12 標記)**：基於 `getByRole` 的穩定標記，適合精確動作。

## CLI 快捷參考
- **導覽**：`openclaw browser open <URL>`, `navigate <URL>`
- **觀察**：`openclaw browser screenshot`, `snapshot`, `console`, `errors`
- **動作**：`click <ref>`, `type <ref> "text"`, `press Enter`, `hover <ref>`
- **狀態**：`cookies`, `storage local set theme dark`, `set geo 25.03 121.56`

## 偵錯流程建議
若 Agent 執行動作失敗（例如：找不到元素）：
1. 執行 `openclaw browser snapshot --interactive` 重新獲取當前頁面結構。
2. 使用 `highlight <ref>` 觀察 Playwright 實際鎖定的是哪個區域。
3. 若頁面行為異常，可使用 `trace start` 錄製完整的 Playwright 追蹤軌跡以供分析。

## 安全性與隱私
- `openclaw` 設定檔可能包含登入後的會話，請視為敏感資料。
- 建議將 Gateway 與瀏覽器節點部署在私有網路中（如 Tailscale）。
- 可透過 `browser.evaluateEnabled=false` 停用在頁面中執行任意 JavaScript 的功能。
