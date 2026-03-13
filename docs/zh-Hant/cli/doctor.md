---
summary: "`openclaw doctor` CLI 參考（健康檢查與引導式修復）"
read_when:
  - 遇到連線或認證問題並想要獲取引導式修復時
  - 在更新系統後想要執行完整性檢查時
title: "doctor（健康檢查與修復）"
---

# `openclaw doctor`

針對 Gateway 與頻道的健康檢查以及快速修復工具。

相關資訊：

- 故障排除指南：[故障排除](/zh-Hant/gateway/troubleshooting)
- 安全性審查：[安全性](/zh-Hant/gateway/security)

## 指令範例

```bash
openclaw doctor
openclaw doctor --repair
openclaw doctor --deep
```

注意事項：

- 互動式提示（例如 Keychain/OAuth 修復）僅在 stdin 為 TTY 且 **未** 設定 `--non-interactive` 時才會執行。無頭執行（排程、Telegram、無終端機）會略過提示。
- `--fix`（`--repair` 的別名）會在執行前將設定備份至 `~/.openclaw/openclaw.json.bak`，並刪除未知的設定鑰匙，列出每項移除。
- 狀態完整性檢查現在會偵測會話目錄中的孤立轉錄檔案，並可將其存檔為 `.deleted.<timestamp>` 以安全地回收空間。
- Doctor 也掃描 `~/.openclaw/cron/jobs.json`（或 `cron.store`）以尋找舊版排程任務形狀，並可在排程器必須在執行時自動正規化它們之前，原位重寫它們。
- Doctor 包含記憶體搜尋就緒檢查，當嵌入憑證遺失時可建議 `openclaw configure --section model`。
- 如果沙盒模式已啟用但 Docker 不可用，Doctor 會報告高訊號警告並提供補救措施（`install Docker` 或 `openclaw config set agents.defaults.sandbox.mode off`）。

## macOS：`launchctl` 環境變數覆寫

如果您先前曾執行過 `launchctl setenv OPENCLAW_GATEWAY_TOKEN ...`（或 `...PASSWORD`），該值會覆寫您的設定檔並可能導致持續的「未授權」錯誤。

```bash
launchctl getenv OPENCLAW_GATEWAY_TOKEN
launchctl getenv OPENCLAW_GATEWAY_PASSWORD

launchctl unsetenv OPENCLAW_GATEWAY_TOKEN
launchctl unsetenv OPENCLAW_GATEWAY_PASSWORD
```
