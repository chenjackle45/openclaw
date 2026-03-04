---
summary: "CLI 參考用於 `openclaw qr`（產生 iOS 配對 QR + 設定代碼）"
read_when:
  - 您想快速將 iOS 應用程式與 Gateway 配對
  - 您需要設定代碼輸出用於遠端/手動共享
title: "qr"
---

# `openclaw qr`

從您當前的 Gateway 設定產生 iOS 配對 QR 和設定代碼。

## 使用方式

```bash
openclaw qr
openclaw qr --setup-code-only
openclaw qr --json
openclaw qr --remote
openclaw qr --url wss://gateway.example/ws --token '<token>'
```

## 選項

- `--remote`：使用 `gateway.remote.url` 加上設定中的遠端 Token/密碼
- `--url <url>`：覆蓋負載中使用的 Gateway URL
- `--public-url <url>`：覆蓋負載中使用的公開 URL
- `--token <token>`：覆蓋負載的 Gateway Token
- `--password <password>`：覆蓋負載的 Gateway 密碼
- `--setup-code-only`：僅列印設定代碼
- `--no-ascii`：跳過 ASCII QR 渲染
- `--json`：發出 JSON（`setupCode`、`gatewayUrl`、`auth`、`urlSource`）

## 註

- `--token` 和 `--password` 互相排斥。
- 使用 `--remote`，如果有效的遠端認證配置為 SecretRef，且您不傳遞 `--token` 或 `--password`，命令從活動 Gateway 快照解析它們。如果 Gateway 不可用，命令快速失敗。
- 沒有 `--remote`，本機 `gateway.auth.password` SecretRef 在密碼身份驗證可以贏時解析（明確 `gateway.auth.mode="password"` 或推斷密碼模式，沒有來自 auth/env 的獲勝 Token），且沒有 CLI 身份驗證覆蓋被通過。
- Gateway 版本偏斜注：此命令路徑需要支援 `secrets.resolve` 的 Gateway；舊版 Gateway 返回未知方法錯誤。
- 掃描後，批准裝置配對：
  - `openclaw devices list`
  - `openclaw devices approve <requestId>`
