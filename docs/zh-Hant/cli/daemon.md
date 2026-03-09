---
summary: "`openclaw daemon` CLI 參考（Gateway 服務管理的舊版別名）"
read_when:
  - 您在腳本中仍使用 `openclaw daemon ...`
  - 您需要服務生命週期指令（安裝/啟動/停止/重新啟動/狀態）
title: "daemon（舊版 Gateway 服務別名）"
---

# `openclaw daemon`

Gateway 服務管理指令的舊版別名。

`openclaw daemon ...` 對應到與 `openclaw gateway ...` 服務指令相同的服務控制介面。

## 使用方式

```bash
openclaw daemon status
openclaw daemon install
openclaw daemon start
openclaw daemon stop
openclaw daemon restart
openclaw daemon uninstall
```

## 子指令

- `status`：顯示服務安裝狀態並探測 Gateway 健康狀況
- `install`：安裝服務（`launchd`/`systemd`/`schtasks`）
- `uninstall`：移除服務
- `start`：啟動服務
- `stop`：停止服務
- `restart`：重新啟動服務

## 常見選項

- `status`：`--url`、`--token`、`--password`、`--timeout`、`--no-probe`、`--deep`、`--json`
- `install`：`--port`、`--runtime <node|bun>`、`--token`、`--force`、`--json`
- 生命週期（`uninstall|start|stop|restart`）：`--json`

注意事項：

- `status` 會在可能時解析配置的認證 SecretRefs 以進行探測認證。
- 在 Linux systemd 安裝中，`status` 的 token 漂移檢查包含 `Environment=` 和 `EnvironmentFile=` 兩種 unit 來源。
- 當 token 認證需要 token 且 `gateway.auth.token` 是 SecretRef 管理的，`install` 會驗證 SecretRef 是否可解析，但不會將解析後的 token 儲存至服務環境中繼資料。
- 若 token 認證需要 token 且配置的 token SecretRef 未解析，安裝會快速失敗。
- 若 `gateway.auth.token` 和 `gateway.auth.password` 均已配置，且 `gateway.auth.mode` 未設定，安裝會被阻止直到明確設定 mode 為止。

## 建議使用

請改用 [`openclaw gateway`](/zh-Hant/cli/gateway) 以取得最新文件和範例。
