---
title: "Location command(位置指令)"
summary: "節點的位置指令 (location.get)、權限模式以及背景執行行為說明"
read_when:
  - 新增位置節點支援或權限 UI 時
  - 設計背景位置追蹤與推送流程時
---

# 位置指令 (Location Command)

## 核心重點 (TL;DR)
- `location.get` 是一個節點指令（透由 `node.invoke` 呼叫）。
- 預設為**關閉**。
- 設定選項包含：關閉 (Off) / 使用期間 (While Using) / 始終允許 (Always)。
- 提供獨立的「精確位置 (Precise Location)」開關。

## 權限選擇機制
作業系統的權限具備多個層級。雖然我們在 App 內提供選擇器，但最終決定權仍在作業系統手中。
- **iOS/macOS**：使用者可在系統彈出視窗或「設定」中選擇「使用期間」或「始終」。
- **Android**：背景位置是一項獨立權限；在 Android 10+ 版本通常需要引導使用者進入「設定」頁面手動開啟。
- **精確位置**：這是一項額外授權（iOS 稱為「精確」，Android 則區分為「精確 (fine)」與「概略 (coarse)」）。

## 設定模型
每個節點裝置具備：
- `location.enabledMode`：`off | whileUsing | always`
- `location.preciseEnabled`：布林值

**UI 行為設計**：
- 選擇 `whileUsing` 會請求前台權限。
- 選擇 `always` 會先確認已取得 `whileUsing` 權限，接著請求背景權限（或導向系統設定）。
- 若作業系統駁回請求，則自動回退至已獲得的最高層級並顯示狀態。

## 指令格式：`location.get`

**請求參數範例**：
```json
{
  "timeoutMs": 10000,         // 逾時時間
  "maxAgeMs": 15000,          // 最大資料年齡（快取）
  "desiredAccuracy": "precise" // 期望精確度
}
```

**回應酬載範例**：
```json
{
  "lat": 48.20849,            // 緯度
  "lon": 16.37208,            // 經度
  "accuracyMeters": 12.5,     // 精確度（公尺）
  "timestamp": "2026-01-03T12:34:56.000Z",
  "isPrecise": true,          // 是否為精確位置
  "source": "gps"             // 來源：gps|wifi|cell|unknown
}
```

## 錯誤代碼
- `LOCATION_DISABLED`：使用者已在設定中關閉此功能。
- `LOCATION_PERMISSION_REQUIRED`：缺少所選模式對應的系統權限。
- `LOCATION_BACKGROUND_UNAVAILABLE`：App 處於背景，但僅獲得「使用期間」權限。
- `LOCATION_TIMEOUT`：無法在指定時間內獲取位置定點。

## 背景執行行為
目標：即使節點處於背景狀態，模型仍能請求位置。需符合以下條件：
- 使用者選擇了 **始終 (Always)**。
- 作業系統授權了背景位置存取。
- App 獲准在背景執行位置服務（iOS 的背景模式或 Android 的前台服務）。

## 介面文字建議 (UX Copy)
- **關閉**：「位置共享已停用。」
- **使用期間**：「僅在 OpenClaw 開啟時分享。」
- **始終**：「允許背景位置共享。需要系統權限。」
- **精確**：「使用精確 GPS 位置。關閉則分享概略位置。」
