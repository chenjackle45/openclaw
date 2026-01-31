---
title: "Cron add hardening(Cron 新增強化)"
summary: "強化 cron.add 輸入處理、對齊 schemas 並改進 cron UI/agent 工具"
owner: "openclaw"
status: "complete"
last_updated: "2026-01-05"
---

# Cron Add Hardening & Schema Alignment(Cron 新增強化 & Schema 對齊)

## 背景
最近的 gateway 日誌顯示重複的 `cron.add` 失敗，具有無效參數（缺少 `sessionTarget`、`wakeMode`、`payload`，以及格式錯誤的 `schedule`）。這表明至少有一個客戶端（可能是 agent tool call 路徑）正在發送包裝的或部分指定的作業 payloads。另外，TypeScript 中的 cron provider enums、gateway schema、CLI 旗標和 UI 表單類型之間存在偏差，加上 `cron.status` 的 UI 不匹配（期望 `jobCount`，而 gateway 返回 `jobs`）。

## 目標
- 透過正規化常見包裝器 payloads 並推斷缺少的 `kind` 欄位，停止 `cron.add` INVALID_REQUEST 垃圾郵件。
- 在 gateway schema、cron 類型、CLI 文件和 UI 表單之間對齊 cron provider 清單。
- 使 agent cron 工具 schema 明確，以便 LLM 產生正確的作業 payloads。
- 修復 Control UI cron 狀態作業計數顯示。
- 新增測試以涵蓋正規化和工具行為。

## 非目標
- 變更 cron 排程語意或作業執行行為。
- 新增新的排程種類或 cron 運算式解析。
- 超越必要欄位修復的 UI/UX 全面改革。

## 發現（當前差距）
- gateway 中的 `CronPayloadSchema` 排除 `signal` + `imessage`，而 TS 類型包括它們。
- Control UI CronStatus 期望 `jobCount`，但 gateway 返回 `jobs`。
- Agent cron 工具 schema 允許任意 `job` 物件，啟用格式錯誤的輸入。
- Gateway 嚴格驗證 `cron.add` 而無正規化，因此包裝的 payloads 失敗。

## 變更內容

- `cron.add` 和 `cron.update` 現在正規化常見包裝器形狀並推斷缺少的 `kind` 欄位。
- Agent cron 工具 schema 與 gateway schema 匹配，這減少了無效 payloads。
- Provider enums 在 gateway、CLI、UI 和 macOS picker 之間對齊。
- Control UI 使用 gateway 的 `jobs` 計數欄位作為狀態。

## 當前行為

- **正規化：**包裝的 `data`/`job` payloads 被解包裝；`schedule.kind` 和 `payload.kind` 在安全時被推斷。
- **預設：**缺少時為 `wakeMode` 和 `sessionTarget` 套用安全預設。
- **Providers：**Discord/Slack/Signal/iMessage 現在在 CLI/UI 中一致地顯示。

請參閱 [Cron jobs](/automation/cron-jobs) 以取得正規化形狀和範例。

## 驗證

- 監視 gateway 日誌以減少 `cron.add` INVALID_REQUEST 錯誤。
- 確認 Control UI cron 狀態在刷新後顯示作業計數。

## 選用後續行動

- 手動 Control UI smoke：每個 provider 新增一個 cron 作業 + 驗證狀態作業計數。

## 開放問題
- `cron.add` 是否應該接受來自客戶端的明確 `state`（目前被 schema 禁止）？
- 我們是否應該允許 `webchat` 作為明確的傳遞 provider（目前在傳遞解析中過濾）？
