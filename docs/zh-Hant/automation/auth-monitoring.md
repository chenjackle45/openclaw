---
title: "認證監控 (Auth Monitoring)"
summary: "監控模型供應商的 OAuth 過期狀態"
read_when:
  - 設定認證過期監控或告警時
  - 自動化檢查 Claude Code / Codex 的 OAuth 重新整理狀態時
---
# 認證監控 (Auth Monitoring)

OpenClaw 透過 `openclaw models status` 暴露 OAuth 的有效性狀態。建議使用此指令進行自動化與告警；腳本部分則是針對手機工作流研發的選用附加功能。

## 推薦做法：CLI 檢查（具備移植性）

```bash
openclaw models status --check
```

結束狀態碼 (Exit codes)：
- `0`：正常 (OK)
- `1`：憑證已過期或缺失
- `2`：即將過期（24 小時內）

此指令適用於 Cron 或 Systemd，且不需要額外的輔助腳本。

## 選用腳本（運維 / 手機工作流）

這些腳本位於 `scripts/` 目錄中，屬於**選配功能**。它們假設您可以透過 SSH 存取 Gateway 主機，並已針對 Systemd 與 Termux 進行優化。

- `scripts/claude-auth-status.sh`：目前以 `openclaw models status --json` 作為權威資料來源。
- `scripts/auth-monitor.sh`：Cron/Systemd 定時器目標；用於發送告警（透過 ntfy 或手機）。
- `scripts/systemd/openclaw-auth-monitor.{service,timer}`：Systemd 使用者定時器。
- `scripts/mobile-reauth.sh`：引導式的 SSH 重新認證流程。
- `scripts/termux-quick-auth.sh`：點擊小工具即可查看狀態並開啟認證網址。
- `scripts/termux-auth-widget.sh`：完整的小工具引導流程。
- `scripts/termux-sync-widget.sh`：同步 Claude Code 憑證至 OpenClaw。

如果您不需要手機端的自動化或 Systemd 定時器，可以忽略這些腳本。
