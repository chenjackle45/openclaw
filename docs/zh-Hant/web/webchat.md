---
summary: "環迴 WebChat 靜態主機和閘道 WS 用於聊天 UI"
read_when:
  - 偵錯或配置 WebChat 存取
title: "WebChat"
---

# WebChat（閘道 WebSocket UI）

狀態：macOS/iOS SwiftUI 聊天 UI 直接與閘道 WebSocket 通訊。

## 它是什麼

- 閘道的原生聊天 UI（沒有嵌入式瀏覽器，也沒有本機靜態伺服器）。
- 使用與其他通道相同的工作階段和路由規則。
- 確定性路由：回覆始終回到 WebChat。

## 快速開始

1. 啟動閘道。
2. 開啟 WebChat UI（macOS/iOS 應用）或 Control UI 聊天標籤。
3. 確保配置了閘道驗證（預設為必須，即使在環迴上也是如此）。

## 運作方式（行為）

- UI 連接到閘道 WebSocket 並使用 `chat.history`、`chat.send` 和 `chat.inject`。
- `chat.history` 有界限以保證穩定性：閘道可能會截斷長文字欄位、省略繁重中繼資料，並將超大項目替換為 `[chat.history omitted: message too large]`。
- `chat.inject` 直接將助手備註附加到謄本並將其廣播到 UI（不執行代理）。
- 中止的執行可以在 UI 中保持部分助手輸出可見。
- 當存在緩衝輸出時，閘道將中止的部分助手文本持久化到謄本歷史記錄中，並使用中止中繼資料標記這些項目。
- 歷史記錄始終從閘道擷取（無本機檔案監視）。
- 如果閘道無法到達，WebChat 是唯讀的。

## Control UI 代理工具面板

- Control UI `/agents` 工具面板透過 `tools.catalog` 擷取運行時目錄，並將每個工具標籤為 `core` 或 `plugin:<id>`（以及 `optional` 用於選用外掛工具）。
- 如果 `tools.catalog` 不可用，面板會回退到內建靜態清單。
- 面板編輯設定檔和覆蓋設定，但有效運行時存取仍遵循原則優先級（`allow`/`deny`、每個代理以及供應商/通道覆蓋）。

## 遠端使用

- 遠端模式透過 SSH/Tailscale 建立閘道 WebSocket 通道。
- 您不需要執行單獨的 WebChat 伺服器。

## 設定參考（WebChat）

完整設定：[設定](/zh-Hant/gateway/configuration)

通道選項：

- 沒有專用的 `webchat.*` 區塊。WebChat 使用閘道端點 + 以下驗證設定。

相關全域選項：

- `gateway.port`、`gateway.bind`：WebSocket 主機/埠。
- `gateway.auth.mode`、`gateway.auth.token`、`gateway.auth.password`：WebSocket 驗證（令牌/密碼）。
- `gateway.auth.mode: "trusted-proxy"`：瀏覽器客戶端的反向代理驗證（請參閱 [Trusted Proxy Auth](/zh-Hant/gateway/trusted-proxy-auth)）。
- `gateway.remote.url`、`gateway.remote.token`、`gateway.remote.password`：遠端閘道目標。
- `session.*`：工作階段儲存和主要金鑰預設值。
