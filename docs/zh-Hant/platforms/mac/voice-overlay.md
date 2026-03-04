---
summary: "喚醒詞和推送對話重疊時的語音覆蓋層生命週期"
read_when:
  - 調整語音覆蓋層行為
title: "Voice Overlay（語音覆蓋層生命週期）"
---

# Voice Overlay 生命週期（macOS）

受眾：macOS 應用開發貢獻者。目標：在喚醒詞和推送對話重疊時保持語音覆蓋層行為可預測。

## 目前意圖

- 如果覆蓋層已經由喚醒詞顯示，而使用者按下快捷鍵，則快捷鍵工作階段會採用現有文本而不是重設它。覆蓋層在按住快捷鍵時保持顯示。當使用者放開時：如果有經過修剪的文本則傳送，否則關閉。
- 喚醒詞單獨仍會在沉默時自動傳送；推送對話在放開時立即傳送。

## 已實現（2025 年 12 月 9 日）

- 覆蓋層工作階段現在為每個擷取（喚醒詞或推送對話）攜帶一個令牌。當令牌不符合時，部分/最終/傳送/關閉/級別更新會被丟棄，避免陳舊回呼。
- 推送對話採用任何可見的覆蓋層文本作為前綴（因此在喚醒覆蓋層啟用時按下快捷鍵會保留文本並附加新語音）。它等待最多 1.5 秒以取得最終謄本，然後回退到目前文本。
- Chime/覆蓋層日誌在 `info` 級別發出，類別為 `voicewake.overlay`、`voicewake.ptt` 和 `voicewake.chime`（工作階段開始、部分、最終、傳送、關閉、chime 原因）。

## 後續步驟

1. **VoiceSessionCoordinator（執行者）**
   - 在任何時刻擁有恰好一個 `VoiceSession`。
   - API（令牌型）：`beginWakeCapture`、`beginPushToTalk`、`updatePartial`、`endCapture`、`cancel`、`applyCooldown`。
   - 丟棄攜帶陳舊令牌的回呼（防止舊辨識器重新開啟覆蓋層）。
2. **VoiceSession（模型）**
   - 欄位：`token`、`source`（wakeWord|pushToTalk）、已承諾/易變文本、chime 旗標、計時器（自動傳送、閒置）、`overlayMode`（display|editing|sending）、冷卻截止時間。
3. **覆蓋層綁定**
   - `VoiceSessionPublisher`（`ObservableObject`）將活動工作階段鏡像到 SwiftUI。
   - `VoiceWakeOverlayView` 只透過發佈者轉譯；它絕不直接更改全域單一體。
   - 覆蓋層使用者操作（`sendNow`、`dismiss`、`edit`）使用工作階段令牌呼叫回座標器。
4. **統一傳送路徑**
   - 在 `endCapture` 上：如果修剪文本為空 → 關閉；否則 `performSend(session:)`（播放傳送 chime 一次、轉發、關閉）。
   - 推送對話：無延遲；喚醒詞：自動傳送可選延遲。
   - 在推送對話完成後對喚醒運行時應用短冷卻，以便喚醒詞不會立即重新觸發。
5. **日誌**
   - 座標器在子系統 `ai.openclaw` 中發出 `.info` 日誌，類別為 `voicewake.overlay` 和 `voicewake.chime`。
   - 關鍵事件：`session_started`、`adopted_by_push_to_talk`、`partial`、`finalized`、`send`、`dismiss`、`cancel`、`cooldown`。

## 偵錯檢查清單

- 在重現黏性覆蓋層時串流日誌：

  ```bash
  sudo log stream --predicate ‘subsystem == "ai.openclaw" AND category CONTAINS "voicewake"’ --level info --style compact
  ```

- 驗證只有一個活動工作階段令牌；陳舊回呼應該由座標器丟棄。
- 確保推送對話版本始終使用活動令牌呼叫 `endCapture`；如果文本為空，期望不帶 chime 或傳送的 `dismiss`。

## 遷移步驟（建議）

1. 新增 `VoiceSessionCoordinator`、`VoiceSession` 和 `VoiceSessionPublisher`。
2. 重構 `VoiceWakeRuntime` 以建立/更新/結束工作階段，而不是直接觸及 `VoiceWakeOverlayController`。
3. 重構 `VoicePushToTalk` 以採用現有工作階段並在版本上呼叫 `endCapture`；應用運行時冷卻。
4. 將 `VoiceWakeOverlayController` 連接到發佈者；移除來自運行時/PTT 的直接呼叫。
5. 為工作階段採用、冷卻和空文本關閉新增整合測試。
