---
title: "health(macOS Health Checks)"
summary: "macOS 應用程式如何回報 Gateway/Baileys 健康狀態"
read_when:
  - 除錯 macOS 應用程式健康指標時
---

# macOS 上的健康檢查

如何從選單列應用程式查看已連結 Channel 的健康狀態。

## 選單列 (Menu bar)
- 狀態圓點現在反映 Baileys 健康狀態：
  - 綠燈：已連結 + Socket 最近已開啟。
  - 橘燈：連線中/重試中。
  - 紅燈：已登出或探測失敗。
- 第二行文字顯示 "linked · auth 12m" 或顯示失敗原因。
- "Run Health Check" 選單項目可觸發隨選探測 (on-demand probe)。

## 設定 (Settings)
- General 頁籤新增了 Health 卡片，顯示：已連結認證時間 (linked auth age)、工作階段儲存路徑/數量、上次檢查時間、上次錯誤/狀態碼，以及 Run Health Check / Reveal Logs 按鈕。
- 使用快取的快照，以便 UI 能瞬間載入並在離線時優雅降級。
- **Channels 頁籤** 顯示 Channel 狀態 + WhatsApp/Telegram 控制項（登入 QR、登出、探測、上次斷線/錯誤）。

## 探測運作原理
- 應用程式每約 60 秒及隨選時透過 `ShellExecutor` 執行 `openclaw health --json`。探測會載入憑證並回報狀態，而不發送訊息。
- 分別快取上次良好的快照與上次錯誤，以避免閃爍；顯示各別的時間戳記。

## 有疑問時
- 您仍可使用 [Gateway health](/gateway/health) 中的 CLI 流程 (`openclaw status`, `openclaw status --deep`, `openclaw health --json`)，並 tail `/tmp/openclaw/openclaw-*.log` 查看 `web-heartbeat` / `web-reconnect` 相關日誌。
