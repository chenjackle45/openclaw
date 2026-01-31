---
title: "devices(裝置管理)"
summary: "`openclaw devices` CLI 參考（裝置配對、權杖輪換與撤銷）"
read_when:
  - 正在核准裝置配對請求時
  - 需要輪換或撤銷裝置權杖 (Tokens) 時
---

# `openclaw devices`

管理裝置配對請求以及裝置網域權杖。

## 指令說明

### `openclaw devices list`

列出待處理的配對請求以及已配對的裝置。

```bash
openclaw devices list
openclaw devices list --json
```

### `openclaw devices approve <請求ID>`

核准待處理的裝置配對請求。

```bash
openclaw devices approve <requestId>
```

### `openclaw devices reject <請求ID>`

拒絕待處理的裝置配對請求。

```bash
openclaw devices reject <requestId>
```

### `openclaw devices rotate --device <ID> --role <角色> [--scope <範圍...>]`

為特定角色輪換裝置權杖（可選用更新其權限範圍）。

```bash
openclaw devices rotate --device <deviceId> --role operator --scope operator.read --scope operator.write
```

### `openclaw devices revoke --device <ID> --role <角色>`

撤銷特定角色的裝置權杖。

```bash
openclaw devices revoke --device <deviceId> --role node
```

## 常用選項

- `--url <url>`：Gateway 的 WebSocket URL（預設為配置中的 `gateway.remote.url`）。
- `--token <token>`：Gateway 權杖（若有需要）。
- `--password <password>`：Gateway 密碼（密碼認證）。
- `--timeout <ms>`：RPC 超時設定。
- `--json`：JSON 格式輸出（建議用於腳本處理）。

## 注意事項

- **安全建議**：權杖輪換會回傳新的權杖（機密資料），請將其視為金鑰妥善保管。
- **權限要求**：執行這些指令需要具備 `operator.pairing` 或 `operator.admin` 權限範圍。
