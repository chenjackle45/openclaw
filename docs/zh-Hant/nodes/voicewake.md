---
title: "Voicewake(語音喚醒詞)"
summary: "全域語音喚醒詞（由 Gateway 掌控）以及如何在節點間進行同步"
read_when:
  - 變更語音喚醒詞行為或預設值時
  - 新增需要同步喚醒詞的節點平台時
---

# 語音喚醒詞 (Voice Wake)

OpenClaw 將**喚醒詞設定視為一個全域列表**，並由 **Gateway** 統一管理。

- **不支援個別節點的自訂喚醒詞**：所有節點使用同一組清單。
- **隨處編輯，全域同步**：任何節點或 App 介面都可以編輯清單；變更後由 Gateway 持久化儲存，並廣播給所有連線中的節點。
- **個別開關**：每個裝置仍可獨立控制是否開啟「語音喚醒」功能（基於各自的系統權限與使用者偏好）。

## 儲存路徑 (Gateway 主機)

喚醒詞儲存在 Gateway 機器上的以下位置：
- `~/.openclaw/settings/voicewake.json`

資料格式範例：
```json
{ 
  "triggers": ["openclaw", "claude", "computer"], 
  "updatedAtMs": 1730000000000 
}
```

## 通訊協定 (Protocol)

### 呼叫方法
- `voicewake.get`：獲取目前的觸發詞列表。
- `voicewake.set { triggers: string[] }`：更新觸發詞列表。

注意：觸發詞會進行標準化處理（修剪空白、移除空項目）。若列表為空則會自動回退至系統預設值。

### 事件通知
- `voicewake.changed`：當列表變更時發送。

接收對象：
- 所有 WebSocket 客戶端（macOS App、網頁聊天室等）。
- 所有連線中的節點（iOS/Android），此外節點在初次連線時也會收到一份目前的狀態快照。

## 各平台行為

### macOS 應用程式
- 使用全域清單來過濾 `VoiceWakeRuntime` 的觸發行為。
- 在設定中編輯「觸發詞」會呼叫 `voicewake.set`。

### iOS 節點
- 使用全域清單進行 `VoiceWakeManager` 的觸發偵測。
- 在設定中編輯喚醒詞會透過 Gateway WebSocket 呼叫 `voicewake.set`，並同步更新本地偵測邏輯。

### Android 節點
- 在設定頁面中提供喚醒詞編輯器。
- 同樣透過 Gateway WebSocket 存取 `voicewake.set`，確保編輯內容能同步至各處。
