---
summary: "節點配對、前景需求、權限和工具失敗的疑難排解"
read_when:
  - 節點已連接但 camera/canvas/screen/exec 工具失敗
  - 你需要節點配對與核准的思維模型
title: "Node Troubleshooting（節點疑難排解）"
---

# 節點疑難排解

在節點在狀態中可見但節點工具失敗時使用此頁面。

## 命令梯隊

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

然後執行節點特定檢查：

```bash
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
openclaw approvals get --node <idOrNameOrIp>
```

健康信號：

- 節點已連接並為角色 `node` 配對。
- `nodes describe` 包含你正在呼叫的能力。
- Exec 核准顯示預期的模式/白名單。

## 前景需求

`canvas.*`、`camera.*` 和 `screen.*` 在 iOS/Android 節點上僅為前景。

快速檢查和修復：

```bash
openclaw nodes describe --node <idOrNameOrIp>
openclaw nodes canvas snapshot --node <idOrNameOrIp>
openclaw logs --follow
```

如果你看到 `NODE_BACKGROUND_UNAVAILABLE`，將節點應用帶到前景並重試。

## 權限矩陣

| 能力                         | iOS                        | Android                      | macOS 節點應用             | 典型失敗代碼                   |
| ---------------------------- | -------------------------- | ---------------------------- | -------------------------- | ------------------------------ |
| `camera.snap`, `camera.clip` | 相機（+ 剪輯音訊的麥克風） | 相機（+ 剪輯音訊的麥克風）   | 相機（+ 剪輯音訊的麥克風） | `*_PERMISSION_REQUIRED`        |
| `screen.record`              | 螢幕錄製（+ 選用麥克風）   | 螢幕擷取提示（+ 選用麥克風） | 螢幕錄製                   | `*_PERMISSION_REQUIRED`        |
| `location.get`               | 使用中或總是（依模式）     | 前景/背景位置基於模式        | 位置權限                   | `LOCATION_PERMISSION_REQUIRED` |
| `system.run`                 | n/a（節點主機路徑）        | n/a（節點主機路徑）          | Exec 核准必需              | `SYSTEM_RUN_DENIED`            |

## 配對與核准

這些是不同的閘門：

1. **裝置配對**：此節點可以連接到 gateway 嗎？
2. **Exec 核准**：此節點可以執行特定 shell 命令嗎？

快速檢查：

```bash
openclaw devices list
openclaw nodes status
openclaw approvals get --node <idOrNameOrIp>
openclaw approvals allowlist add --node <idOrNameOrIp> "/usr/bin/uname"
```

如果配對缺失，首先核准節點裝置。
如果配對良好但 `system.run` 失敗，修復 exec 核准/白名單。

## 常見節點錯誤代碼

- `NODE_BACKGROUND_UNAVAILABLE` → 應用在背景中；將其帶到前景。
- `CAMERA_DISABLED` → 相機切換在節點設定中被禁用。
- `*_PERMISSION_REQUIRED` → OS 權限缺失/被拒。
- `LOCATION_DISABLED` → 位置模式已關閉。
- `LOCATION_PERMISSION_REQUIRED` → 請求的位置模式未被授予。
- `LOCATION_BACKGROUND_UNAVAILABLE` → 應用在背景中但只有「使用中」權限存在。
- `SYSTEM_RUN_DENIED: approval required` → exec 請求需要明確核准。
- `SYSTEM_RUN_DENIED: allowlist miss` → 命令被白名單模式阻止。
  在 Windows 節點主機上，shell 包裝器形式如 `cmd.exe /c ...` 在白名單模式中被視為白名單未命中，除非通過詢問流程核准。

## 快速恢復迴圈

```bash
openclaw nodes status
openclaw nodes describe --node <idOrNameOrIp>
openclaw approvals get --node <idOrNameOrIp>
openclaw logs --follow
```

如果仍然被卡住：

- 重新核准裝置配對。
- 重新開啟節點應用（前景）。
- 重新授予 OS 權限。
- 重新建立/調整 exec 核准策略。

相關：

- [/zh-Hant/nodes](/zh-Hant/nodes)
- [/zh-Hant/nodes/camera](/zh-Hant/nodes/camera)
- [/zh-Hant/nodes/location-command](/zh-Hant/nodes/location-command)
- [/zh-Hant/tools/exec-approvals](/zh-Hant/tools/exec-approvals)
- [/zh-Hant/gateway/pairing](/zh-Hant/gateway/pairing)
