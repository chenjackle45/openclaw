---
summary: "`openclaw devices` CLI 參考（裝置配對、權杖輪換與撤銷）"
read_when:
  - 正在核准裝置配對請求時
  - 需要輪換或撤銷裝置權杖時
title: "devices（裝置管理）"
---

# `openclaw devices`

管理裝置配對請求以及裝置網域權杖。

## 指令說明

### `openclaw devices list`

列出待處理的配對請求以及已配對的裝置。

```
openclaw devices list
openclaw devices list --json
```

### `openclaw devices remove <deviceId>`

移除一個已配對的裝置。

```
openclaw devices remove <deviceId>
openclaw devices remove <deviceId> --json
```

### `openclaw devices clear --yes [--pending]`

大量清除已配對的裝置。

```
openclaw devices clear --yes
openclaw devices clear --yes --pending
openclaw devices clear --yes --pending --json
```

### `openclaw devices approve [requestId] [--latest]`

核准待處理的裝置配對請求。如果省略 `requestId`，OpenClaw 會自動核准最新的待處理請求。

```
openclaw devices approve
openclaw devices approve <requestId>
openclaw devices approve --latest
```

### `openclaw devices reject <requestId>`

拒絕待處理的裝置配對請求。

```
openclaw devices reject <requestId>
```

### `openclaw devices rotate --device <id> --role <role> [--scope <scope...>]`

為特定角色輪換裝置權杖（可選用更新權限範圍）。

```
openclaw devices rotate --device <deviceId> --role operator --scope operator.read --scope operator.write
```

### `openclaw devices revoke --device <id> --role <role>`

撤銷特定角色的裝置權杖。

```
openclaw devices revoke --device <deviceId> --role node
```

## 常用選項

- `--url <url>`：Gateway 的 WebSocket URL（預設為配置中的 `gateway.remote.url`）。
- `--token <token>`：Gateway 權杖（若有需要）。
- `--password <password>`：Gateway 密碼（密碼認證）。
- `--timeout <ms>`：RPC 超時設定。
- `--json`：JSON 格式輸出（建議用於腳本處理）。

注意：設定 `--url` 時，CLI 不會回退至配置或環境憑證。請明確傳遞 `--token` 或 `--password`。缺少明確憑證會導致錯誤。

## 注意事項

- 權杖輪換會回傳新的權杖（機密資料），請將其視為密鑰妥善保管。
- 這些指令需要 `operator.pairing`（或 `operator.admin`）權限範圍。
- `devices clear` 刻意由 `--yes` 控制。
- 如果配對權限在本地迴環上不可用（且未傳遞明確的 `--url`），列表/核准可使用本地配對回退。

## 權杖偏差恢復檢查清單

當 Control UI 或其他客戶端持續失敗並出現 `AUTH_TOKEN_MISMATCH` 或 `AUTH_DEVICE_TOKEN_MISMATCH` 時，請使用此清單。

1. 確認目前 Gateway 權杖來源：

```bash
openclaw config get gateway.auth.token
```

2. 列出已配對的裝置並識別受影響的裝置 ID：

```bash
openclaw devices list
```

3. 為受影響的裝置輪換 operator 權杖：

```bash
openclaw devices rotate --device <deviceId> --role operator
```

4. 如果輪換不夠，移除過時的配對並重新核准：

```bash
openclaw devices remove <deviceId>
openclaw devices list
openclaw devices approve <requestId>
```

5. 使用目前共用的權杖/密碼重試客戶端連接。

相關連結：

- [Dashboard 認證故障排除](/zh-Hant/web/dashboard#if-you-see-unauthorized-1008)
- [Gateway 故障排除](/zh-Hant/gateway/troubleshooting#dashboard-control-ui-connectivity)
