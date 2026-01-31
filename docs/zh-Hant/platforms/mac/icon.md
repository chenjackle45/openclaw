---
title: "icon(Menu Bar Icon States)"
summary: "OpenClaw macOS 選單列圖示的狀態與動畫"
read_when:
  - 變更選單列圖示行為時
---

# 選單列圖示狀態

作者: steipete · 更新: 2025-12-06 · 範圍: macOS 應用程式 (`apps/macos`)

- **閒置 (Idle):** 正常圖示動畫（眨眼、偶爾擺動）。
- **暫停 (Paused):** 狀態項目使用 `appearsDisabled`；無動作。
- **語音觸發 (Voice trigger - big ears):** 當聽到喚醒詞時，語音喚醒偵測器呼叫 `AppState.triggerVoiceEars(ttl: nil)`，在擷取語句期間保持 `earBoostActive=true`。耳朵放大 (1.9x)，出現圓形耳洞以增加識別度，靜默 1 秒後透過 `stopVoiceEars()` 恢復。僅由應用程式內的語音管道觸發。
- **工作中 (Working - Agent running):** `AppState.isWorking=true` 驅動「尾巴/腿部快速移動」微動畫：更快的腿部擺動與些微位移，表示工作正在進行中。目前在 WebChat Agent 運行期間切換；當您連接其他長時間任務時，請加入相同的切換。

## 接線點 (Wiring points)

- 語音喚醒：runtime/tester 在觸發時呼叫 `AppState.triggerVoiceEars(ttl: nil)`，並在靜默 1 秒後呼叫 `stopVoiceEars()` 以配合擷取視窗。
- Agent 活動：在工作期間設定 `AppStateStore.shared.setWorking(true/false)`（WebChat Agent 呼叫已完成）。保持跨度簡短並在 `defer` 區塊中重置，以避免動畫卡住。

## 形狀與尺寸

- 基礎圖示繪製於 `CritterIconRenderer.makeIcon(blink:legWiggle:earWiggle:earScale:earHoles:)`。
- 耳朵縮放預設為 `1.0`；語音增強設定 `earScale=1.9` 並切換 `earHoles=true`，不改變整體框架（18×18 pt 模板影像渲染至 36×36 px Retina backing store）。
- 快速移動使用高達 ~1.0 的腿部擺動與些微水平抖動；這是對現有閒置擺動的疊加。

## 行為注意事項

- 耳朵/工作中狀態無外部 CLI/Broker 切換；請保持在應用程式內部訊號以避免意外閃爍。
- 保持 TTL 簡短 (<10s)，以便在工作卡住時圖示能快速恢復基準線。
