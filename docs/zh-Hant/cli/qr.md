---
summary: "`openclaw qr` CLI 參考（生成 iOS 配對 QR + 設定碼）"
read_when:
  - 想要快速將 iOS App 與 Gateway 配對時
  - 需要設定碼輸出以供遠端/手動分享時
title: "qr（iOS 配對 QR）"
---

# `openclaw qr`

從您目前的 Gateway 配置生成 iOS 配對 QR 和設定碼。

## 使用方式

```bash
openclaw qr
openclaw qr --setup-code-only
openclaw qr --json
openclaw qr --remote
openclaw qr --url wss://gateway.example/ws --token '<token>'
```

## 選項

- `--remote`：使用 `gateway.remote.url` 加上 config 中的遠端 token/密碼
- `--url <url>`：覆寫 payload 中使用的 Gateway URL
- `--public-url <url>`：覆寫 payload 中使用的公開 URL
- `--token <token>`：覆寫 payload 的 Gateway token
- `--password <password>`：覆寫 payload 的 Gateway 密碼
- `--setup-code-only`：僅列印設定碼
- `--no-ascii`：跳過 ASCII QR 渲染
- `--json`：輸出 JSON（`setupCode`、`gatewayUrl`、`auth`、`urlSource`）

## 注意事項

- `--token` 和 `--password` 互斥。
- 使用 `--remote` 時，若有效的遠端憑證被配置為 SecretRefs 且您未傳遞 `--token` 或 `--password`，指令會從目前的 gateway 快照解析它們。若 gateway 無法使用，指令會快速失敗。
- 不使用 `--remote` 時，在未傳遞 CLI 認證覆寫的情況下，本地 gateway 認證 SecretRefs 會被解析：
  - 當 token 認證可以優先時，`gateway.auth.token` 會被解析（明確的 `gateway.auth.mode="token"` 或推斷模式下無密碼來源優先）。
  - 當密碼認證可以優先時，`gateway.auth.password` 會被解析（明確的 `gateway.auth.mode="password"` 或推斷模式下無認證/env 優先的 token）。
- 若 `gateway.auth.token` 和 `gateway.auth.password` 均已配置（包含 SecretRefs）且 `gateway.auth.mode` 未設定，設定碼解析會失敗，直到明確設定 mode 為止。
- Gateway 版本差異注意：此指令路徑需要支援 `secrets.resolve` 的 gateway；較舊的 gateway 會返回未知方法錯誤。
- 掃描後，請透過以下方式核准裝置配對：
  - `openclaw devices list`
  - `openclaw devices approve <requestId>`
