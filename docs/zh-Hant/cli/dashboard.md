---
summary: "`openclaw dashboard` CLI 參考（開啟控制介面）"
read_when:
  - 想要使用目前的 token 開啟控制介面（Control UI）時
  - 想要列印 URL 而不啟動瀏覽器時
title: "dashboard（控制儀表板）"
---

# `openclaw dashboard`

使用目前的認證資訊開啟控制介面（Control UI）。

```bash
openclaw dashboard
openclaw dashboard --no-open
```

注意事項：

- `dashboard` 會在可能時解析配置的 `gateway.auth.token` SecretRefs。
- 對於 SecretRef 管理的 token（已解析或未解析），`dashboard` 會列印/複製/開啟不含 token 的 URL，以避免在終端機輸出、剪貼簿歷史記錄或瀏覽器啟動參數中暴露外部密鑰。
- 若 `gateway.auth.token` 是 SecretRef 管理的但在此指令路徑中未解析，指令會列印不含 token 的 URL 和明確的修復指引，而非嵌入無效的 token 佔位符。
