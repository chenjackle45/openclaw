---
title: "相機擷取"
summary: "Agent 使用的相機擷取功能（iOS/Android 節點及 macOS App）：拍照（jpg）及短片（mp4）"
read_when:
  - 在 iOS 節點或 macOS 上新增或修改相機擷取功能時
  - 擴展 Agent 可存取的 MEDIA 暫存檔工作流時
---

# 相機擷取（Agent）

OpenClaw 支援 Agent 工作流的**相機擷取**功能：

- **iOS 節點**（透由 Gateway 配對）：透過 `node.invoke` 擷取**照片**（`jpg`）或**短片**（`mp4`，含選用音訊）。
- **Android 節點**（透由 Gateway 配對）：透過 `node.invoke` 擷取**照片**（`jpg`）或**短片**（`mp4`，含選用音訊）。
- **macOS App**（透由 Gateway 配對）：透過 `node.invoke` 擷取**照片**（`jpg`）或**短片**（`mp4`，含選用音訊）。

所有相機存取都受到**使用者控制的設定**保護。

## iOS 節點

### 使用者設定（預設開啟）

- iOS 設定分頁 → **Camera** → **Allow Camera**（`camera.enabled`）
  - 預設：**開啟**（缺少的金鑰視為已啟用）。
  - 關閉時：`camera.*` 指令回傳 `CAMERA_DISABLED`。

### 指令（透由 Gateway `node.invoke`）

- `camera.list`
  - 回應酬載：
    - `devices`：`{ id, name, position, deviceType }` 陣列

- `camera.snap`
  - 參數：
    - `facing`：`front|back`（預設：`front`）
    - `maxWidth`：數字（選用；iOS 節點預設 `1600`）
    - `quality`：`0..1`（選用；預設 `0.9`）
    - `format`：目前為 `jpg`
    - `delayMs`：數字（選用；預設 `0`）
    - `deviceId`：字串（選用；來自 `camera.list`）
  - 回應酬載：
    - `format: "jpg"`
    - `base64: "<...>"`
    - `width`、`height`
  - 酬載保護：照片會重新壓縮以保持 base64 酬載在 5 MB 以下。

- `camera.clip`
  - 參數：
    - `facing`：`front|back`（預設：`front`）
    - `durationMs`：數字（預設 `3000`，上限 `60000`）
    - `includeAudio`：布林值（預設 `true`）
    - `format`：目前為 `mp4`
    - `deviceId`：字串（選用；來自 `camera.list`）
  - 回應酬載：
    - `format: "mp4"`
    - `base64: "<...>"`
    - `durationMs`
    - `hasAudio`

### 前台要求

如同 `canvas.*`，iOS 節點僅允許在**前台**執行 `camera.*` 指令。背景呼叫回傳 `NODE_BACKGROUND_UNAVAILABLE`。

### CLI 輔助工具（暫存檔 + MEDIA）

最簡單的方式是透由 CLI 輔助工具，它將解碼的媒體寫入暫存檔並列印 `MEDIA:<path>`。

範例：

```bash
openclaw nodes camera snap --node <id>               # 預設：同時拍前後（2 個 MEDIA 行）
openclaw nodes camera snap --node <id> --facing front
openclaw nodes camera clip --node <id> --duration 3000
openclaw nodes camera clip --node <id> --no-audio
```

注意：

- `nodes camera snap` 預設為**同時拍前後**以提供 Agent 兩個視圖。
- 輸出檔為暫存檔（在 OS 暫存目錄中），除非您建構自己的包裝程式。

## Android 節點

### 使用者設定（預設開啟）

- Android 設定工作表 → **Camera** → **Allow Camera**（`camera.enabled`）
  - 預設：**開啟**（缺少的金鑰視為已啟用）。
  - 關閉時：`camera.*` 指令回傳 `CAMERA_DISABLED`。

### 權限

- Android 需要執行時期權限：
  - `CAMERA`：用於 `camera.snap` 及 `camera.clip`。
  - `RECORD_AUDIO`：用於 `camera.clip` 且 `includeAudio=true` 時。

若權限缺失，App 會在可能時提示；若被拒絕，`camera.*` 請求會失敗並出現 `*_PERMISSION_REQUIRED` 錯誤。

### 前台要求

如同 `canvas.*`，Android 節點僅允許在**前台**執行 `camera.*` 指令。背景呼叫回傳 `NODE_BACKGROUND_UNAVAILABLE`。

### 酬載保護

照片會重新壓縮以保持 base64 酬載在 5 MB 以下。

## macOS App

### 使用者設定（預設關閉）

macOS 伴隨 App 公開一個核取方塊：

- **Settings → General → Allow Camera**（`openclaw.cameraEnabled`）
  - 預設：**關閉**
  - 關閉時：相機請求回傳「Camera disabled by user」。

### CLI 輔助工具（node invoke）

使用主要 `openclaw` CLI 在 macOS 節點上呼叫相機指令。

範例：

```bash
openclaw nodes camera list --node <id>            # 列出相機 id
openclaw nodes camera snap --node <id>            # 列印 MEDIA:<path>
openclaw nodes camera snap --node <id> --max-width 1280
openclaw nodes camera snap --node <id> --delay-ms 2000
openclaw nodes camera snap --node <id> --device-id <id>
openclaw nodes camera clip --node <id> --duration 10s          # 列印 MEDIA:<path>
openclaw nodes camera clip --node <id> --duration-ms 3000      # 列印 MEDIA:<path>（舊版旗標）
openclaw nodes camera clip --node <id> --device-id <id>
openclaw nodes camera clip --node <id> --no-audio
```

注意：

- `openclaw nodes camera snap` 預設 `maxWidth=1600`，除非覆蓋。
- 在 macOS 上，`camera.snap` 在暖機/曝光穩定後等待 `delayMs`（預設 2000ms）後才擷取。
- 照片酬載會重新壓縮以保持 base64 在 5 MB 以下。

## 安全性 + 實作限制

- 相機和麥克風存取會觸發常見的 OS 權限提示（並需要 Info.plist 中的使用說明字串）。
- 影片片段上限（目前 `<= 60s`）以避免 node 酬載過大（base64 開銷 + 訊息限制）。

## macOS 螢幕影片（OS 層級）

若要_螢幕_影片（非相機），使用 macOS 伴隨 App：

```bash
openclaw nodes screen record --node <id> --duration 10s --fps 15   # 列印 MEDIA:<path>
```

注意：

- 需要 macOS **螢幕錄製**權限（TCC）。
