---
summary: "攝影機擷取（iOS 節點 + macOS App）用於 Agent 使用：照片（jpg）和短影片剪輯（mp4）"
read_when:
  - 在 iOS 節點或 macOS 上新增或修改攝影機擷取
  - 擴充 Agent 可存取的 MEDIA 暫存檔案工作流程
title: "Camera Capture（攝影機擷取）"
---

# 攝影機擷取（Agent）

OpenClaw 支援 Agent 工作流程的**攝影機擷取**：

- **iOS 節點**（透過 Gateway 配對）：透過 `node.invoke` 擷取**照片**（`jpg`）或**短影片剪輯**（`mp4`，可選音訊）。
- **Android 節點**（透過 Gateway 配對）：透過 `node.invoke` 擷取**照片**（`jpg`）或**短影片剪輯**（`mp4`，可選音訊）。
- **macOS App**（透過 Gateway 的節點）：透過 `node.invoke` 擷取**照片**（`jpg`）或**短影片剪輯**（`mp4`，可選音訊）。

所有攝影機存取都在**使用者控制的設定**後面。

## iOS 節點

### 使用者設定（預設開啟）

- iOS 設定標籤 → **攝影機** → **允許攝影機**（`camera.enabled`）
  - 預設：**開啟**（遺漏的鍵被視為啟用）。
  - 關閉時：`camera.*` 命令傳回 `CAMERA_DISABLED`。

### 命令（透過 Gateway `node.invoke`）

- `camera.list`
  - 回應有效負載：
    - `devices`：`{ id, name, position, deviceType }` 陣列

- `camera.snap`
  - 參數：
    - `facing`：`front|back`（預設：`front`）
    - `maxWidth`：數字（選擇性；iOS 節點預設 `1600`）
    - `quality`：`0..1`（選擇性；預設 `0.9`）
    - `format`：目前 `jpg`
    - `delayMs`：數字（選擇性；預設 `0`）
    - `deviceId`：字串（選擇性；來自 `camera.list`）
  - 回應有效負載：
    - `format: "jpg"`
    - `base64: "<...>"`
    - `width`、`height`
  - 有效負載守衛：照片被重新壓縮以保持 base64 有效負載在 5 MB 以下。

- `camera.clip`
  - 參數：
    - `facing`：`front|back`（預設：`front`）
    - `durationMs`：數字（預設 `3000`，上限 `60000`）
    - `includeAudio`：布林值（預設 `true`）
    - `format`：目前 `mp4`
    - `deviceId`：字串（選擇性；來自 `camera.list`）
  - 回應有效負載：
    - `format: "mp4"`
    - `base64: "<...>"`
    - `durationMs`
    - `hasAudio`

### 前景要求

如同 `canvas.*`，iOS 節點僅允許**前景**中的 `camera.*` 命令。後台呼叫傳回 `NODE_BACKGROUND_UNAVAILABLE`。

### CLI 輔助程式（暫存檔案 + MEDIA）

取得附件的最簡單方式是透過 CLI 輔助程式，它將已解碼的媒體寫入暫存檔案並列印 `MEDIA:<path>`。

範例：

```bash
openclaw nodes camera snap --node <id>               # 預設：前後兩個（2 MEDIA 行）
openclaw nodes camera snap --node <id> --facing front
openclaw nodes camera clip --node <id> --duration 3000
openclaw nodes camera clip --node <id> --no-audio
```

注意事項：

- `nodes camera snap` 預設為**兩個**面以給予 Agent 兩個檢視。
- 輸出檔案是暫存的（在作業系統暫存目錄中），除非你建置自己的包裝程式。
