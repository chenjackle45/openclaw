---
title: "browser(瀏覽器控制)"
summary: "`openclaw browser` CLI 參考（配置檔、標籤頁、動作與擴充功能中繼機制）"
read_when:
  - 使用 `openclaw browser` 並需要常見任務的範例時
  - 想要透過節點主機控制另一台機器上的瀏覽器時
  - 想要使用 Chrome 擴充功能中繼機制（透過工具列按鈕附加/分離）時
---

# `openclaw browser`

管理 OpenClaw 的瀏覽器控制伺服器，並執行瀏覽器動作（標籤頁管理、快照、截圖、導覽、點擊、輸入等）。

相關資訊：
- 瀏覽器工具與 API：[瀏覽器工具 (Browser tool)](/tools/browser)
- Chrome 擴充功能中繼：[Chrome 擴充功能 (Chrome extension)](/tools/chrome-extension)

## 常用旗標

- `--url <網址>`：Gateway 服務的 WebSocket URL。
- `--token <權杖>`：Gateway 權杖。
- `--timeout <ms>`：請求超時設定。
- `--browser-profile <名稱>`：選擇瀏覽器配置檔（預設使用配置中的設定）。
- `--json`：機器可讀輸出。

## 快速開始 (本地模式)

```bash
# 查看指定配置檔的標籤頁
openclaw browser --browser-profile chrome tabs

# 啟動特定配置檔的瀏覽器執行實例
openclaw browser --browser-profile openclaw start

# 開啟特定網址
openclaw browser --browser-profile openclaw open https://example.com

# 獲取當前網頁快照
openclaw browser --browser-profile openclaw snapshot
```

## 配置檔 (Profiles)

配置檔是具名的瀏覽器路由設定。實務上：
- `openclaw`：啟動/附加至由 OpenClaw 專門管理的 Chrome 實例（具備隔離的使用者資料目錄）。
- `chrome`：透過 Chrome 擴充功能中繼機制控制您既有的 Chrome 標籤頁。

```bash
# 列出配置檔
openclaw browser profiles

# 建立配置檔
openclaw browser create-profile --name work --color "#FF5A36"

# 刪除配置檔
openclaw browser delete-profile --name work
```

## 標籤頁管理 (Tabs)

```bash
# 列出所有標籤頁
openclaw browser tabs

# 開啟新網址
openclaw browser open https://docs.openclaw.ai

# 聚焦或關閉特定標籤頁
openclaw browser focus <目標ID>
openclaw browser close <目標ID>
```

## 快照 / 截圖 / 自動化動作

```bash
# 獲取網頁快照
openclaw browser snapshot

# 截圖
openclaw browser screenshot

# 導覽、點擊或在特定元素輸入文字
openclaw browser navigate https://example.com
openclaw browser click <元素引用>
openclaw browser type <元素引用> "hello"
```

## Chrome 擴充功能中繼 (手動附加)

此模式允許 Agent 控制您手動附加的現有 Chrome 標籤頁（系統不會自動附加）。

安裝擴充功能：

```bash
# 將未打包的擴充功能安裝至穩定路徑
openclaw browser extension install

# 查看安裝目錄
openclaw browser extension path
```

接著在 Chrome 開啟 `chrome://extensions` → 啟用「開發者模式」 → 點擊「載入未打包外掛」 → 選擇上述路徑。

詳細指南：[Chrome 擴充功能](/tools/chrome-extension)

## 遠端瀏覽器控制 (節點主機代理)

若 Gateway 與瀏覽器運行在不同機器上，請在安裝有瀏覽器的機器上執行**節點主機 (node host)**。Gateway 會將瀏覽器動作代理至該節點。

配置說明：
- 使用 `gateway.nodes.browser.mode` 控制自動路由。
- 使用 `gateway.nodes.browser.node` 指定特定節點。

安全性與遠端設定：[瀏覽器工具](/tools/browser), [遠端存取](/gateway/remote), [Tailscale](/gateway/tailscale), [安全性](/gateway/security)
