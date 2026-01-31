---
title: "child-process(Gateway Lifecycle)"
summary: "macOS 上 Gateway 的生命週期 (launchd)"
read_when:
  - 整合 macOS 應用程式與 Gateway 生命週期時
---

# macOS 上 Gateway 的生命週期

預設情況下，macOS 應用程式 **透過 launchd 管理 Gateway**，且**不會**將 Gateway 作為子行程 (child process) 啟動。它首先嘗試連接配置通訊埠上已在運行的 Gateway；若無法連接，則透過外部 `openclaw` CLI（無嵌入式運行時）啟用 launchd 服務。這提供了可靠的登入時自動啟動與崩潰重啟功能。

子行程模式 (由應用程式直接啟動 Gateway) 目前 **已不使用**。
若您需要與 UI 更緊密的耦合，請在終端機中手動運行 Gateway。

## 預設行為 (launchd)

- 應用程式安裝標籤為 `bot.molt.gateway` 的使用者層級 LaunchAgent
  （若使用 `--profile`/`OPENCLAW_PROFILE` 則為 `bot.molt.<profile>`；支援舊版 `com.openclaw.*`）。
- 當 Local 模式啟用時，應用程式確保 LaunchAgent 已載入，並在需要時啟動 Gateway。
- 日誌寫入至 launchd gateway日誌路徑（可於 Debug Settings 查看）。

常見指令：

```bash
launchctl kickstart -k gui/$UID/bot.molt.gateway
launchctl bootout gui/$UID/bot.molt.gateway
```

當運行具名設定檔時，請將標籤替換為 `bot.molt.<profile>`。

## 未簽署的開發建置

`scripts/restart-mac.sh --no-sign` 適用於當您沒有簽章金鑰時的快速本地建置。為防止 launchd 指向未簽署的中繼二進位檔 (relay binary)，它會：

- 寫入 `~/.openclaw/disable-launchagent`。

已簽署的 `scripts/restart-mac.sh` 運行會在標記存在時清除此覆蓋。手動重置：

```bash
rm ~/.openclaw/disable-launchagent
```

## Attach-only 模式

若要強制 macOS 應用程式 **永不安裝或管理 launchd**，請使用 `--attach-only` (或 `--no-launchd`) 啟動它。這會設定 `~/.openclaw/disable-launchagent`，因此應用程式僅會連接至已在運行的 Gateway。您也可以在 Debug Settings 中切換相同的行為。

## Remote 模式

Remote 模式從不啟動本地 Gateway。應用程式使用 SSH 通道連接至遠端主機，並透過該通道進行通訊。

## 為何我們偏好 launchd

- 登入時自動啟動。
- 內建重啟/KeepAlive 語意。
- 可預測的日誌與監督。

若未來再次需要真正的子行程模式，應將其記錄為獨立、明確的僅供開發使用 (dev-only) 的模式。
