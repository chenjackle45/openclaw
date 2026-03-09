---
summary: "節點的位置指令（location.get）、權限模式及 Android 前景行為"
read_when:
  - 新增位置節點支援或權限 UI
  - 設計 Android 位置權限或前景行為
title: "Location Command（位置指令）"
---

# 位置指令（節點）

## TL;DR

- `location.get` 是節點指令（透過 `node.invoke`）。
- 預設關閉。
- Android 應用程式設定使用選擇器：Off / While Using。
- 獨立開關：精確位置。

## 為什麼使用選擇器（而非單純開關）

OS 權限是多層級的。我們可以在 App 中公開選擇器，但 OS 仍決定實際授予的權限。

- iOS/macOS 可能在系統提示/設定中公開 **While Using** 或 **Always**。
- Android 應用程式目前僅支援前景位置。
- 精確位置是獨立的授予（iOS 14+「Precise」，Android「fine」vs「coarse」）。

UI 中的選擇器驅動我們請求的模式；實際授予位於 OS 設定中。

## 設定模型

各節點裝置：

- `location.enabledMode`：`off | whileUsing`
- `location.preciseEnabled`：bool

UI 行為：

- 選擇 `whileUsing` 請求前景權限。
- 若 OS 拒絕請求的層級，回退至最高授予層級並顯示狀態。

## 權限對應（node.permissions）

選用。macOS 節點透過權限對應回報 `location`；iOS/Android 可能省略。

## 指令：`location.get`

透過 `node.invoke` 呼叫。

參數（建議）：

```json
{
  "timeoutMs": 10000,
  "maxAgeMs": 15000,
  "desiredAccuracy": "coarse|balanced|precise"
}
```

回應酬載：

```json
{
  "lat": 48.20849,
  "lon": 16.37208,
  "accuracyMeters": 12.5,
  "altitudeMeters": 182.0,
  "speedMps": 0.0,
  "headingDeg": 270.0,
  "timestamp": "2026-01-03T12:34:56.000Z",
  "isPrecise": true,
  "source": "gps|wifi|cell|unknown"
}
```

錯誤（穩定代碼）：

- `LOCATION_DISABLED`：選擇器已關閉。
- `LOCATION_PERMISSION_REQUIRED`：請求模式缺少權限。
- `LOCATION_BACKGROUND_UNAVAILABLE`：App 在背景但僅允許 While Using。
- `LOCATION_TIMEOUT`：未在時間內取得定位。
- `LOCATION_UNAVAILABLE`：系統故障／無提供商。

## 背景行為

- Android App 在背景時拒絕 `location.get`。
- 在 Android 上請求位置時請保持 OpenClaw 開啟。
- 其他節點平台行為可能不同。

## 模型／工具整合

- 工具介面：`nodes` 工具新增 `location_get` 動作（需要節點）。
- CLI：`openclaw nodes location get --node <id>`。
- Agent 指導：僅在使用者啟用位置且了解範圍時才呼叫。

## UX 文案（建議）

- Off：「位置分享已停用。」
- While Using：「僅在 OpenClaw 開啟時。」
- Precise：「使用精確 GPS 位置。關閉以分享近似位置。」
