---
summary: "快速頻道層級疑難排解，含各頻道故障特徵與修復方式"
read_when:
  - 頻道傳輸顯示已連線但回覆失敗
  - 需要在查閱完整提供者文件前進行頻道特定檢查
title: "Channel Troubleshooting（頻道疑難排解）"
---

# 頻道疑難排解

當頻道已連線但行為異常時，使用此頁面。

## 指令梯次

依序執行以下指令：

```bash
openclaw status
openclaw gateway status
openclaw logs --follow
openclaw doctor
openclaw channels status --probe
```

健康基準：

- `Runtime: running`
- `RPC probe: ok`
- 頻道探測顯示已連線/就緒

## WhatsApp

### WhatsApp 故障特徵

| 症狀                  | 最快檢查方式                              | 修復方式                             |
| --------------------- | ----------------------------------------- | ------------------------------------ |
| 已連線但無 DM 回覆    | `openclaw pairing list whatsapp`          | 核准發送者或切換 DM 策略/allowlist。 |
| 群組訊息被忽略        | 檢查設定中的 `requireMention` 和提及模式  | 提及 bot 或放寬該群組的提及策略。    |
| 隨機斷線/重新登入迴圈 | `openclaw channels status --probe` + 日誌 | 重新登入並確認憑證目錄狀態正常。     |

完整疑難排解：[/channels/whatsapp#troubleshooting-quick](/zh-Hant/channels/whatsapp#troubleshooting-quick)

## Telegram

### Telegram 故障特徵

| 症狀                          | 最快檢查方式                               | 修復方式                                                            |
| ----------------------------- | ------------------------------------------ | ------------------------------------------------------------------- |
| `/start` 後無可用的回覆流程   | `openclaw pairing list telegram`           | 核准配對或變更 DM 策略。                                            |
| Bot 在線但群組保持靜默        | 確認提及需求和 bot 隱私模式                | 停用群組可見性的隱私模式或提及 bot。                                |
| 傳送失敗並出現網路錯誤        | 檢查日誌中的 Telegram API 呼叫失敗         | 修復連往 `api.telegram.org` 的 DNS/IPv6/代理路由。                  |
| 啟動時 `setMyCommands` 被拒絕 | 檢查日誌中的 `BOT_COMMANDS_TOO_MUCH`       | 減少外掛/技能/自訂 Telegram 指令，或停用原生選單。                  |
| 升級後 allowlist 阻擋自己     | `openclaw security audit` 和設定 allowlist | 執行 `openclaw doctor --fix` 或將 `@username` 替換為數字發送者 ID。 |

完整疑難排解：[/channels/telegram#troubleshooting](/zh-Hant/channels/telegram#troubleshooting)

## Discord

### Discord 故障特徵

| 症狀                    | 最快檢查方式                       | 修復方式                                             |
| ----------------------- | ---------------------------------- | ---------------------------------------------------- |
| Bot 在線但無 guild 回覆 | `openclaw channels status --probe` | 允許 guild/頻道並確認訊息內容 intent。               |
| 群組訊息被忽略          | 檢查日誌中的提及閘控丟棄記錄       | 提及 bot 或設定 guild/頻道 `requireMention: false`。 |
| DM 回覆遺失             | `openclaw pairing list discord`    | 核准 DM 配對或調整 DM 策略。                         |

完整疑難排解：[/channels/discord#troubleshooting](/zh-Hant/channels/discord#troubleshooting)

## Slack

### Slack 故障特徵

| 症狀                       | 最快檢查方式                        | 修復方式                                     |
| -------------------------- | ----------------------------------- | -------------------------------------------- |
| Socket mode 已連線但無回應 | `openclaw channels status --probe`  | 確認 app token + bot token 和所需的 scopes。 |
| DM 被封鎖                  | `openclaw pairing list slack`       | 核准配對或放寬 DM 策略。                     |
| 頻道訊息被忽略             | 檢查 `groupPolicy` 和頻道 allowlist | 允許該頻道或將策略切換為 `open`。            |

完整疑難排解：[/channels/slack#troubleshooting](/zh-Hant/channels/slack#troubleshooting)

## iMessage 和 BlueBubbles

### iMessage 和 BlueBubbles 故障特徵

| 症狀                     | 最快檢查方式                                                            | 修復方式                                     |
| ------------------------ | ----------------------------------------------------------------------- | -------------------------------------------- |
| 無入站事件               | 確認 webhook/伺服器可達性和應用程式權限                                 | 修復 webhook URL 或 BlueBubbles 伺服器狀態。 |
| macOS 上可傳送但無法接收 | 檢查 macOS Messages 自動化的隱私權限                                    | 重新授予 TCC 權限並重啟頻道程序。            |
| DM 發送者被封鎖          | `openclaw pairing list imessage` 或 `openclaw pairing list bluebubbles` | 核准配對或更新 allowlist。                   |

完整疑難排解：

- [/channels/imessage#troubleshooting-macos-privacy-and-security-tcc](/zh-Hant/channels/imessage#troubleshooting-macos-privacy-and-security-tcc)
- [/channels/bluebubbles#troubleshooting](/zh-Hant/channels/bluebubbles#troubleshooting)

## Signal

### Signal 故障特徵

| 症狀                       | 最快檢查方式                       | 修復方式                                      |
| -------------------------- | ---------------------------------- | --------------------------------------------- |
| Daemon 可達但 bot 保持靜默 | `openclaw channels status --probe` | 確認 `signal-cli` daemon URL/帳號和接收模式。 |
| DM 被封鎖                  | `openclaw pairing list signal`     | 核准發送者或調整 DM 策略。                    |
| 群組回覆無法觸發           | 檢查群組 allowlist 和提及模式      | 新增發送者/群組或放寬閘控。                   |

完整疑難排解：[/channels/signal#troubleshooting](/zh-Hant/channels/signal#troubleshooting)

## Matrix

### Matrix 故障特徵

| 症狀                 | 最快檢查方式                       | 修復方式                              |
| -------------------- | ---------------------------------- | ------------------------------------- |
| 已登入但忽略房間訊息 | `openclaw channels status --probe` | 檢查 `groupPolicy` 和房間 allowlist。 |
| DM 未被處理          | `openclaw pairing list matrix`     | 核准發送者或調整 DM 策略。            |
| 加密房間失敗         | 確認加密模組和加密設定             | 啟用加密支援並重新加入/同步房間。     |

完整疑難排解：[/channels/matrix#troubleshooting](/zh-Hant/channels/matrix#troubleshooting)
