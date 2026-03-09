---
summary: "`openclaw tui` CLI 參考（連接至 Gateway 的終端機 UI）"
read_when:
  - 想要使用連接至 Gateway 的終端機 UI（適合遠端使用）時
  - 想要從腳本傳遞 url/token/session 時
title: "tui（終端機介面）"
---

# `openclaw tui`

開啟連接至 Gateway 的終端機 UI。

相關資訊：

- TUI 指南：[TUI](/zh-Hant/web/tui)

注意事項：

- `tui` 在可能時解析配置的 gateway 認證 SecretRefs 以進行 token/密碼認證（`env`/`file`/`exec` 供應商）。
- 從已配置的 agent 工作區目錄啟動時，TUI 會自動選擇該 agent 作為會話金鑰預設值（除非 `--session` 明確為 `agent:<id>:...`）。

## 範例

```bash
openclaw tui
openclaw tui --url ws://127.0.0.1:18789 --token <token>
openclaw tui --session main --deliver
# 從 agent 工作區目錄執行時，自動推斷該 agent
openclaw tui --session bugfix
```
