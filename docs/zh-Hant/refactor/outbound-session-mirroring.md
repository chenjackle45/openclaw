---
title: "Outbound Session Mirroring Refactor(出站會話鏡像重構)"
description: "追蹤出站會話鏡像重構注意事項、決策、測試和待辦項目。"
---

# Outbound Session Mirroring Refactor (Issue #1520)(出站會話鏡像重構（Issue #1520）)

## 狀態
- 進行中。
- 核心 + 外掛頻道路由已針對出站鏡像更新。
- Gateway send 現在在省略 sessionKey 時導出目標會話。

## 背景
出站發送被鏡像到*當前*代理會話（工具會話鍵）而不是目標頻道會話。入站路由使用 channel/peer 會話鍵，因此出站回應落在錯誤的會話中，首次聯繫目標通常缺少會話條目。

## 目標
- 將出站訊息鏡像到目標頻道會話鍵。
- 缺少時在出站上建立會話條目。
- 保持 thread/topic範圍與入站會話鍵對齊。
- 涵蓋核心頻道加上捆綁擴充。

## 實作摘要
- 新的出站會話路由 helper：
  - `src/infra/outbound/outbound-session.ts`
  - `resolveOutboundSessionRoute` 使用 `buildAgentSessionKey`（dmScope + identityLinks）建構目標 sessionKey。
  - `ensureOutboundSessionEntry` 透過 `recordSessionMetaFromInbound` 寫入最小 `MsgContext`。
- `runMessageAction`（send）導出目標 sessionKey 並將其傳遞給 `executeSendAction` 以進行鏡像。
- `message-tool` 不再直接鏡像；它僅從當前會話鍵解析 agentId。
- 外掛 send 路徑使用導出的 sessionKey 透過 `appendAssistantMessageToSessionTranscript` 鏡像。
- Gateway send 在未提供時導出目標會話鍵（預設代理），並確保會話條目。

## Thread/Topic 處理
- Slack：replyTo/threadId -> `resolveThreadSessionKeys`（後綴）。
- Discord：threadId/replyTo -> `resolveThreadSessionKeys`，`useSuffix=false` 以匹配入站（thread channel id 已經範圍會話）。
- Telegram：topic IDs 透過 `buildTelegramGroupPeerId` 對應到 `chatId:topic:<id>`。

## 涵蓋的擴充
- Matrix、MS Teams、Mattermost、BlueBubbles、Nextcloud Talk、Zalo、Zalo Personal、Nostr、Tlon。
- 注意事項：
  - Mattermost 目標現在剝離 `@` 以進行 DM 會話鍵路由。
  - Zalo Personal 對 1:1 目標使用 DM peer kind（僅當 `group:` 存在時為群組）。
  - BlueBubbles 群組目標剝離 `chat_*` 前綴以匹配入站會話鍵。
  - Slack 自動thread 鏡像不區分大小寫地匹配頻道 ids。
  - Gateway send 在鏡像前將提供的會話鍵小寫。

## 決策
- **Gateway send 會話導出**：如果提供 `sessionKey`，使用它。如果省略，從目標 + 預設代理導出 sessionKey 並在那裡鏡像。
- **會話條目建立**：始終使用 `recordSessionMetaFromInbound`，`Provider/From/To/ChatType/AccountId/Originating*` 與入站格式對齊。
- **目標正規化**：出站路由在可用時使用已解析目標（post `resolveChannelTarget`）。
- **會話鍵大小寫**：在寫入和遷移期間將會話鍵規範化為小寫。

## 新增/更新的測試
- `src/infra/outbound/outbound-session.test.ts`
  - Slack thread 會話鍵。
  - Telegram topic 會話鍵。
  - 具有 Discord 的 dmScope identityLinks。
- `src/agents/tools/message-tool.test.ts`
  - 從會話鍵導出 agentId（沒有傳遞 sessionKey）。
- `src/gateway/server-methods/send.test.ts`
  - 省略時導出會話鍵並建立會話條目。

## 待辦項目 / 後續行動
- Voice-call 外掛使用自訂 `voice:<phone>` 會話鍵。此處未標準化出站對應；如果 message-tool 應支援 voice-call 發送，請新增明確對應。
- 確認是否有任何外部外掛使用超出捆綁集的非標準 `From/To` 格式。

## 觸及的檔案
- `src/infra/outbound/outbound-session.ts`
- `src/infra/outbound/outbound-send-service.ts`
- `src/infra/outbound/message-action-runner.ts`
- `src/agents/tools/message-tool.ts`
- `src/gateway/server-methods/send.ts`
- 測試：
  - `src/infra/outbound/outbound-session.test.ts`
  - `src/agents/tools/message-tool.test.ts`
  - `src/gateway/server-methods/send.test.ts`
