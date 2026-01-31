---
title: "Camera(相機擷取)"
summary: "Agent 使用的相機擷取功能 (iOS/Android 節點與 macOS App)：支援拍照 (jpg) 與短片錄製 (mp4)"
read_when:
  - 正在 iOS 節點或 macOS 上新增或修改相機擷取功能時
  - 擴展 Agent 可存取的 MEDIA 暫存檔工作流時
---

# 相機擷取 (Camera Capture)

OpenClaw 支援用於 Agent 工作流的**相機擷取**功能：

- **iOS 節點**：透過 `node.invoke` 擷取**照片** (`jpg`) 或**短片** (`mp4`，選用音訊)。
- **Android 節點**：透過 `node.invoke` 擷取**照片** (`jpg`) 或**短片** (`mp4`，選用音訊)。
- **macOS App**：透過 `node.invoke` 擷取**照片** (`jpg`) 或**錄製短片**。

所有的相機存取功能都受到**使用者控制的設定**保護。

## iOS 節點

### 使用者設定 (預設開啟)
- iOS 應用程式內的設定分頁 → **Camera** → **Allow Camera** (`camera.enabled`)。
- 當此設定關閉時：執行 `camera.*` 指令將回傳 `CAMERA_DISABLED`。

### 指令 (透由 Gateway `node.invoke`)
- `camera.list`：列出裝置上的相機（ID、名稱、位置）。
- `camera.snap`：拍照。
  - 參數：`facing`（front/back）、`maxWidth`、`quality`、`delayMs`（延遲拍攝）。
  - 安全保護：照片會自動重新壓縮，確保 base64 酬載大小在 5 MB 以內。
- `camera.clip`：錄製短片。
  - 參數：`durationMs`（錄製時長，上限 60 秒）、`includeAudio`（是否包含音訊）。

> [!IMPORTANT]
> **前台執行要求**：iOS 節點僅允許在**前台執行狀態**下呼叫 `camera.*` 指令。若在背景呼叫，將回傳 `NODE_BACKGROUND_UNAVAILABLE`。

### CLI 輔助工具
最簡單的方式是使用 CLI 工具，它會將解碼後的媒體寫入暫存檔並印出 `MEDIA:<路徑>`。

```bash
openclaw nodes camera snap --node <ID>               # 拍照（預設會同時拍前、後鏡頭）
openclaw nodes camera snap --node <ID> --facing front # 只拍前鏡頭
openclaw nodes camera clip --node <ID> --duration 3s   # 錄製 3 秒影片
```

## Android 節點

### 權限要求
Android 系統需要執行期權限：
- `CAMERA`：用於拍照與錄影。
- `RECORD_AUDIO`：用於錄影時包含音訊。

若權限缺失，App 會在可能的情況下彈出通知；若被拒絕，則會回傳 `*_PERMISSION_REQUIRED` 錯誤。

## macOS 應用程式

### 使用者設定 (預設關閉)
macOS 伴隨應用程式提供了一個核取方塊：
- **Settings → General → Allow Camera** (`openclaw.cameraEnabled`)。
- 預設為**關閉**。

### CLI 操作範例
```bash
openclaw nodes camera snap --node <ID> # 拍照
openclaw nodes camera clip --node <ID> --duration 10s # 錄影
```
注意：在 macOS 上，`camera.snap` 在鏡頭啟動與曝光穩定後，預設會等待 2000 毫秒（`delayMs`）才進行拍攝。

## 安全性與實作限制
- 相機與麥克風存取會觸發系統層級的權限請求。
- 影片剪輯長度限制在 **60 秒**以內，以避免 base64 酬載過大（編碼開銷與訊息傳輸限制）。
- 若要錄製**螢幕**影片而非相機影片，請使用 `openclaw nodes screen record`。
