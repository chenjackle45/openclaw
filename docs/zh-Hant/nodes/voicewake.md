---
title: "語音喚醒"
summary: "全域語音喚醒詞（Gateway 所有）及其如何跨節點同步"
read_when:
  - 變更語音喚醒詞行為或預設值時
  - 新增需要喚醒詞同步的新節點平台時
---

# 語音喚醒（全域喚醒詞）

OpenClaw 將**喚醒詞作為單一全域列表**由 **Gateway** 所有。

- **無各節點自訂喚醒詞**。
- **任何節點/App UI 可編輯**清單；變更由 Gateway 持久化並廣播給所有人。
- 各裝置仍保持自己的**語音喚醒啟用/停用**開關（本地 UX + 權限不同）。

## 儲存（Gateway 主機）

喚醒詞儲存在 Gateway 機器上：

- `~/.openclaw/settings/voicewake.json`

形狀：

```json
{ "triggers": ["openclaw", "claude", "computer"], "updatedAtMs": 1730000000000 }
```

## 協定

### 方法

- `voicewake.get` → `{ triggers: string[] }`
- `voicewake.set` 搭配參數 `{ triggers: string[] }` → `{ triggers: string[] }`

注意：

- 觸發器被正規化（修剪、空白被丟棄）。空列表回退到預設值。
- 限制為安全強制執行（計數/長度上限）。

### 事件

- `voicewake.changed` 酬載 `{ triggers: string[] }`

誰接收它：

- 所有 WebSocket 用戶端（macOS App、WebChat 等）
- 所有連線節點（iOS/Android），也在節點連線時作為初始「目前狀態」推送。

## 用戶端行為

### macOS App

- 使用全域列表限制 `VoiceWakeRuntime` 觸發器。
- 編輯聲音喚醒設定中的「觸發詞」呼叫 `voicewake.set`，接著依賴廣播保持其他用戶端同步。

### iOS 節點

- 使用全域列表用於 `VoiceWakeManager` 觸發偵測。
- 編輯設定中的喚醒詞呼叫 `voicewake.set`（透由 Gateway WS）並也保持本地喚醒詞偵測反應。

### Android 節點

- 在設定中公開喚醒詞編輯器。
- 透由 Gateway WS 呼叫 `voicewake.set` 以便編輯於所處同步。
