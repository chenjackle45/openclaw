---
title: "tui(終端機介面)"
summary: "`openclaw tui` CLI 參考（連線至 Gateway 的終端機 UI）"
read_when:
  - 想要使用 Gateway 的終端機介面（對遠端連線友善）時
  - 想要從腳本中傳遞 URL、權杖 (Token) 或會話 (Session) 時
---

# `openclaw tui`

開啟連線至 Gateway 的終端機 UI (TUI)。

相關資訊：
- TUI 概念手冊：[TUI 指南](/tui)

## 指令範例

```bash
# 開啟預設的 TUI
openclaw tui

# 指定遠端 URL 與權杖開啟 TUI
openclaw tui --url ws://127.0.0.1:18789 --token <權杖內容>

# 指定會話並啟用回應遞送
openclaw tui --session main --deliver
```
