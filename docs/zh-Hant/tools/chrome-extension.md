---
title: "Chrome extension(Chrome 擴充功能)"
summary: "Chrome 擴充功能：讓 OpenClaw 控制您現有的 Chrome 分頁"
read_when:
  - 想要讓 Agent 控制現有的 Chrome 分頁時
  - 需要透過 Tailscale 實作遠端 Gateway 與本地瀏覽器自動化時
  - 想要瞭解「接管瀏覽器」的安全影響時
---

# Chrome 擴充功能 (瀏覽器轉發器)

OpenClaw Chrome 擴充功能允許 Agent 控制您**現有的 Chrome 分頁**（即您日常使用的 Chrome 視窗），而非啟動一個獨立受管的 `openclaw` 設定檔。

手動附加與分離操作僅需透過一個 **Chrome 工具列按鈕**即可完成。

## 運作架構
系統由三部分組成：
- **瀏覽器控制服務**：Agent 呼叫的 API（位於 Gateway 或 Node）。
- **本地轉發伺服器 (Relay)**：連接控制伺服器與擴充功能的橋樑（預設為 `18792` 埠）。
- **Chrome MV3 擴充功能**：透由 `chrome.debugger` API 將 CDP 訊息傳遞至轉發器。

## 安裝與載入 (未封裝套件)

1. **安裝至本地路徑**：
   ```bash
   openclaw browser extension install
   ```
2. **獲取安裝路徑**：
   ```bash
   openclaw browser extension path
   ```
3. **在 Chrome 中載入**：
   - 前往 `chrome://extensions`。
   - 開啟「開發者模式」。
   - 點擊「載入未封裝項目」並選擇上述路徑。
4. **釘選擴充功能**。

## 使用方式
OpenClaw 內建了一個名為 `chrome` 的瀏覽器設定檔，預設指向該轉發器。
- **CLI**：`openclaw browser --browser-profile chrome tabs`
- **Agent 工具**：呼叫 `browser` 工具時指定 `profile="chrome"`。

## 附加與分離 (工具列按鈕)
- 開啟您想要交給 OpenClaw 控制的分頁。
- 點擊擴充功能圖示。圖示顯示 `ON` 表示已連線。
- 再次點擊即可中斷連線。

## 遠端 Gateway (搭配 Node Host)
若您的 Gateway 執行於遠端伺服器，請在執行 Chrome 的本地電腦開啟一個 **Node Host**。Gateway 會將指令路由至該節點，而擴充功能則與本地節點進行通訊。

## 安全性警告 (必讀)
這是一個強大但也具備風險的功能。請將其視為「把手放在模型面前讓它操作您的瀏覽器」。
- **無隔離性**：如果您附加了日常使用的分頁，模型將獲得該帳號登入狀態的完整存取權限。
- **建議做法**：建議為轉發器使用一個專屬的 Chrome 設定檔，與個人分頁區隔。
- **網路安全**：確保 Gateway 與 Node 端點僅限於 Tailscale 私有網路存取。
