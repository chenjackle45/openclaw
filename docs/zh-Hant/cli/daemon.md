---
summary: "CLI 參考用於 `openclaw daemon`（Gateway 服務管理的舊版別名）"
read_when:
  - 您在指令碼中仍使用 `openclaw daemon ...`
  - 您需要服務生命週期命令（安裝/啟動/停止/重新啟動/狀態）
title: "daemon"
---

# `openclaw daemon`

Gateway 服務管理命令的舊版別名。

`openclaw daemon ...` 對應到與 `openclaw gateway ...` 服務命令相同的服務控制表面。

## 使用方式

```bash
openclaw daemon status
openclaw daemon install
openclaw daemon start
openclaw daemon stop
openclaw daemon restart
openclaw daemon uninstall
```

## 子命令

- `status`：顯示服務安裝狀態並探測 Gateway 健康
- `install`：安裝服務（`launchd`/`systemd`/`schtasks`）
- `uninstall`：移除服務
- `start`：啟動服務
- `stop`：停止服務
- `restart`：重新啟動服務

## 常見選項

- `status`：`--url`、`--token`、`--password`、`--timeout`、`--no-probe`、`--deep`、`--json`
- `install`：`--port`、`--runtime <node|bun>`、`--token`、`--force`、`--json`
- 生命週期（`uninstall|start|stop|restart`）：`--json`

## 偏好

使用 [`openclaw gateway`](/zh-Hant/cli/gateway) 以取得當前文件和範例。
