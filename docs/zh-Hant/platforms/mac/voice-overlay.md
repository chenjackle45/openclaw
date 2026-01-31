---
title: "voice-overlay(Voice Overlay Lifecycle)"
summary: "當喚醒詞與按鍵通話重疊時的語音覆蓋生命週期"
read_when:
  - 調整語音覆蓋行為時
---

# 語音覆蓋生命週期 (macOS)

對象：macOS 應用程式貢獻者。目標：保持語音覆蓋在喚醒詞與按鍵通話重疊時的可預測性。

### 目前意圖 (Current intent)

- 若覆蓋介面已因喚醒詞而顯示，且使用者按下熱鍵，熱鍵工作階段會 *接收 (adopt)* 現有文字而非重置它。覆蓋介面在熱鍵按住期間保持顯示。當使用者釋放時：若有已修剪的文字則發送，否則關閉。
- 喚醒詞本身仍會在靜默後自動發送；按鍵通話在釋放時立即發送。

### 已實作 (2025年12月9日)

- 覆蓋工作階段現在帶有一個 Token 供每次擷取使用 (喚醒詞或按鍵通話)。當 Token 不符時，部分/最終/發送/關閉/音量更新會被丟棄，避免過期的回呼。
- 按鍵通話會接收任何可見的覆蓋文字作為前綴（因此在喚醒覆蓋顯示時按下熱鍵會保留文字並附加新語音）。它會等待最多 1.5 秒以取得最終轉錄，否則退回至目前文字。
- 鈴聲/覆蓋日誌在 `voicewake.overlay`, `voicewake.ptt`, 與 `voicewake.chime` 類別中以 `info` 層級發出（工作階段開始、部分、最終、發送、關閉、鈴聲原因）。

### 下一步

1. **VoiceSessionCoordinator (actor)**
   - 一次擁有一個 `VoiceSession`。
   - API (基於 Token): `beginWakeCapture`, `beginPushToTalk`, `updatePartial`, `endCapture`, `cancel`, `applyCooldown`。
   - 丟棄帶有過期 Token 的回呼（防止舊的辨識器重新開啟覆蓋）。
2. **VoiceSession (model)**
   - 欄位: `token`, `source` (wakeWord|pushToTalk), committed/volatile text, chime flags, timers (auto-send, idle), `overlayMode` (display|editing|sending), cooldown deadline。
3. **Overlay binding**
   - `VoiceSessionPublisher` (`ObservableObject`) 將活動工作階段鏡像至 SwiftUI。
   - `VoiceWakeOverlayView` 僅透過 Publisher 渲染；從不直接變更全域單例。
   - 覆蓋使用者動作 (`sendNow`, `dismiss`, `edit`) 帶著工作階段 Token 回呼至協調器。
4. **統一發送路徑**
   - 在 `endCapture` 時：若修剪後的文字為空 → 關閉；否則 `performSend(session:)`（播放一次發送鈴聲，轉發，關閉）。
   - 按鍵通話：無延遲；喚醒詞：可選的自動發送延遲。
   - 在按鍵通話結束後對喚醒運行時套用短暫冷卻，以免喚醒詞立即重新觸發。
5. **Logging**
   - 協調器在子系統 `bot.molt`，類別 `voicewake.overlay` 與 `voicewake.chime` 發出 `.info` 日誌。
   - 關鍵事件: `session_started`, `adopted_by_push_to_talk`, `partial`, `finalized`, `send`, `dismiss`, `cancel`, `cooldown`.

### 除錯檢查清單

- 在重現黏滯覆蓋 (sticky overlay) 時串流日誌：

  ```bash
  sudo log stream --predicate 'subsystem == "bot.molt" AND category CONTAINS "voicewake"' --level info --style compact
  ```

- 驗證只有一個活動工作階段 Token；過期的回呼應被協調器丟棄。
- 確保按鍵通話釋放時總是使用活動 Token 呼叫 `endCapture`；若文字為空，預期 `dismiss` 且不播放鈴聲或發送。

### 遷移步驟 (建議)

1. 新增 `VoiceSessionCoordinator`, `VoiceSession`, 與 `VoiceSessionPublisher`。
2. 重構 `VoiceWakeRuntime` 以建立/更新/結束工作階段，而非直接接觸 `VoiceWakeOverlayController`。
3. 重構 `VoicePushToTalk` 以接收現有工作階段並在釋放時呼叫 `endCapture`；套用執行時冷卻。
4. 將 `VoiceWakeOverlayController` 連接至 Publisher；移除來自 runtime/PTT 的直接呼叫。
5. 新增工作階段接收、冷卻與空文字關閉的整合測試。
