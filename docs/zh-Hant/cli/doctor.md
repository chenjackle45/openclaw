---
title: "doctor(健康檢查與修復)"
summary: "`openclaw doctor` CLI 參考（健康檢查與引導式修復）"
read_when:
  - 遇到連線或認證問題並想要獲取引導式修復時
  - 在更新系統後想要執行完整性檢查時
---

# `openclaw doctor`

針對 Gateway 與頻道的健康檢查以及快速修復工具。

相關資訊：
- 故障排除指南：[故障排除 (Troubleshooting)](/gateway/troubleshooting)
- 安全性審查：[安全性 (Security)](/gateway/security)

## 指令範例

```bash
# 執行基礎健康檢查
openclaw doctor

# 執行檢查並嘗試修復發現的問題
openclaw doctor --repair

# 執行深度檢查
openclaw doctor --deep
```

**注意事項**：
- 互動式提示（例如 Keychain 存取或 OAuth 修復）僅在標準終端機 (TTY) 且未設定 `--non-interactive` 時才會執行。無頭環境（如排程任務、Telegram 或非終端機環境）會自動跳過這些提示。
- `--fix`（等同於 `--repair`）在執行前會將目前配置備份至 `~/.openclaw/openclaw.json.bak`，並會移除未知的配置鍵值（會列出每一項變動內容）。

## macOS：`launchctl` 環境變數覆寫問題

如果您先前曾手動執行過 `launchctl setenv OPENCLAW_GATEWAY_TOKEN ...`（或 `...PASSWORD`），該數值會優先於設定檔生效，這可能導致持續出現「未經授權 (Unauthorized)」的錯誤。

```bash
# 查看目前的環境變數
launchctl getenv OPENCLAW_GATEWAY_TOKEN
launchctl getenv OPENCLAW_GATEWAY_PASSWORD

# 清除覆寫的環境變數
launchctl unsetenv OPENCLAW_GATEWAY_TOKEN
launchctl unsetenv OPENCLAW_GATEWAY_PASSWORD
```
