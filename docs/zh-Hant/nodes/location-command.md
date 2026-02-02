---
title: "位置指令"
summary: "節點的位置指令（location.get）、權限模式及背景行為"
read_when:
  - 新增位置節點支援或權限 UI 時
  - 設計背景位置及推送流程時
---

# 位置指令（節點）

## TL;DR

- `location.get` 是節點指令（透由 `node.invoke`）。
- 預設關閉。
- 設定使用選擇器：Off / While Using / Always。
- 獨立開關：精確位置。

## 為什麼使用選擇器（非僅開關）

OS 權限多層級。我們可在 App 中公開選擇器，但 OS 仍決定實際授予。

- iOS/macOS：使用者可在系統提示/設定中選擇 **While Using** 或 **Always**。App 可請求升級，但 OS 可能需要設定。
- Android：背景位置是單獨權限；在 Android 10+ 上經常需要設定流程。
- 精確位置是單獨授予（iOS 14+ 「Precise」，Android 「fine」 vs 「coarse」）。

UI 中的選擇器驅動我們的請求模式；實際授予位於 OS 設定中。

## 設定模型

各節點裝置：

- `location.enabledMode`：`off | whileUsing | always`
- `location.preciseEnabled`：bool

UI 行為：

- 選擇 `whileUsing` 請求前台權限。
- 選擇 `always` 先確保 `whileUsing`，接著請求背景（或在需要時將使用者發送至設定）。
- 若 OS 拒絕請求的級別，回退到最高授予級別並顯示狀態。

## 權限對應（node.permissions）

選用。macOS 節點透由權限對應報告 `location`；iOS/Android 可能省略。

## 指令：`location.get`

透由 `node.invoke` 呼叫。

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

- `LOCATION_DISABLED`：選擇器關閉。
- `LOCATION_PERMISSION_REQUIRED`：請求模式缺少權限。
- `LOCATION_BACKGROUND_UNAVAILABLE`：App 背景但僅允許 While Using。
- `LOCATION_TIMEOUT`：未在時間內修復。
- `LOCATION_UNAVAILABLE`：系統故障 / 無提供者。

## 背景行為（未來）

目標：模型可請求位置即使節點背景，但僅在：

- 使用者選擇 **Always**。
- OS 授予背景位置。
- App 獲准在背景執行位置（iOS 背景模式 / Android 前台服務或特殊允許）。

推送觸發流程（未來）：

1. Gateway 傳送推送至節點（靜默推送或 FCM 資料）。
2. 節點短暫喚醒並從裝置請求位置。
3. 節點轉發酬載至 Gateway。

注意：

- iOS：Always 權限 + 背景位置模式需。靜默推送可能被限制；預期間歇式失敗。
- Android：背景位置可能需要前台服務；否則，預期拒絕。

## 模型/工具整合

- 工具介面：`nodes` 工具新增 `location_get` 動作（需要節點）。
- CLI：`openclaw nodes location get --node <id>`。
- Agent 指導：僅在使用者啟用位置且理解範圍時呼叫。

## UX 複製（建議）

- Off：「位置共享已停用。」
- While Using：「僅當 OpenClaw 開啟時。」
- Always：「允許背景位置。需要系統權限。」
- Precise：「使用精確 GPS 位置。關閉以分享近似位置。」
