---
title: "Group messages(群組訊息)"
summary: "WhatsApp 群組訊息處理的行為和設定（mentionPatterns 在所有介面間共享）"
read_when:
  - 更改群組訊息規則或提及設定
---
# Group messages（群組訊息，WhatsApp Web 頻道）

目標：讓 Clawd 待在 WhatsApp 群組中，僅在被標記（ping）時喚醒，並保持該討論串與個人 DM 會話分開。

備註：`agents.list[].groupChat.mentionPatterns` 現在也被 Telegram/Discord/Slack/iMessage 使用；本文件側重於 WhatsApp 特有的行為。對於多代理設定，請為每個代理設定 `agents.list[].groupChat.mentionPatterns`（或使用 `messages.groupChat.mentionPatterns` 作為全域回退）。

## 已實作內容 (2025-12-03)
- 啟動模式：`mention`（預設值）或 `always`。`mention` 模式需要標記（透過 `mentionedJids` 進行真正的 WhatsApp @提及、正則表達式模式，或文字中任何地方出現機器人的 E.164 號碼）。`always` 模式會在每條訊息上喚醒代理，但它僅應在可以添加有意義的價值時才回覆；否則它會返回靜默權杖 `NO_REPLY`。預設值可以在設定 (`channels.whatsapp.groups`) 中設定，並透過 `/activation` 按群組覆寫。當設定 `channels.whatsapp.groups` 時，它也會充當群組允許清單（包含 `"*"` 以允許所有群組）。
- 群組原則：`channels.whatsapp.groupPolicy` 控制是否接受群組訊息 (`open|disabled|allowlist`)。`allowlist` 使用 `channels.whatsapp.groupAllowFrom`（回退：明確的 `channels.whatsapp.allowFrom`）。預設值為 `allowlist`（直到您新增發送者前都會被封鎖）。
- 每個群組的會話：會話鍵看起來像 `agent:<agentId>:whatsapp:group:<jid>`，因此 `/verbose on` 或 `/think high` 等命令（作為獨立訊息發送）僅作用於該群組；個人 DM 狀態不會受到影響。群組討論串會跳過心跳 (Heartbeats)。
- 上下文注入：**僅限審核中**的群組訊息（預設 50 條），這些訊息*沒有*觸發運行，會被冠以 `[Chat messages since your last reply - for context]` 前綴，觸發行則放在 `[Current message - respond to this]` 下。已經在會話中的訊息不會被重複注入。
- 發送者顯示：現在每個群組批次都以 `[from: Sender Name (+E164)]` 結尾，以便 Pi 知道是誰在說話。
- 臨時/限觀一次：我們在提取文字/提及之前會先展開這些內容，因此其中的標記（ping）仍會觸發。
- 群組系統提示詞：在新群組會話的第一輪（以及每當 `/activation` 更改模式時），我們會在系統提示詞中注入一段簡短的說明，例如 `You are replying inside the WhatsApp group "<subject>". Group members: Alice (+44...), Bob (+43...), … Activation: trigger-only … Address the specific sender noted in the message context.`。如果元資料不可用，我們仍會告訴代理這是群組聊天。

## 設定範例 (WhatsApp)
將 `groupChat` 區塊新增到 `~/.openclaw/openclaw.json`，以便即使 WhatsApp 在文字正文中裁掉了視覺上的 `@`，顯示名稱標記也能運作：

```json5
{
  channels: {
    whatsapp: {
      groups: {
        "*": { requireMention: true }
      }
    }
  },
  agents: {
    list: [
      {
        id: "main",
        groupChat: {
          historyLimit: 50,
          mentionPatterns: [
            "@?openclaw",
            "\\+?15555550123"
          ]
        }
      }
    ]
  }
}
```

備註：
- 正則表達式不區分大小寫；它們涵蓋了像 `@openclaw` 這樣的顯示名稱標記，以及帶有或不帶有 `+`/空格的原始號碼。
- 當有人點擊聯絡人時，WhatsApp 仍會透過 `mentionedJids` 發送規範的提及，因此號碼回退很少需要，但它是一個有用的安全網。

### 啟動命令（僅限擁有者）

使用群組聊天命令：
- `/activation mention`
- `/activation always`

只有擁有者號碼（來自 `channels.whatsapp.allowFrom`，或未設定時為機器人自己的 E.164）可以更改此設定。在群組中發送 `/status` 作為獨立訊息可查看目前的啟動模式。

## 如何使用
1. 將您的 WhatsApp 帳號（運行 OpenClaw 的帳號）新增到群組中。
2. 說 `@openclaw …`（或包含該號碼）。除非您設定 `groupPolicy: "open"`，否則只有列入允許清單的發送者才能觸發它。
3. 代理提示詞將包含最近的群組上下文以及末尾的 `[from: …]` 標記，以便它能針對正確的人。
4. 會話級別的指令 (`/verbose on`, `/think high`, `/new` 或 `/reset`, `/compact`) 僅適用於該群組的會話；請將它們作為獨立訊息發送以便註冊。您的個人 DM 會話保持獨立。

## 測試 / 驗證
- 手動簡易測試：
  - 在群組中發送一個 `@openclaw` 標記，確認回覆引用了發送者姓名。
  - 發送第二次標記，並驗證歷史區塊已包含在內，然後在下一輪被清除。
- 檢查 Gateway 日誌（使用 `--verbose` 運行）以查看顯示 `from: <groupJid>` 和 `[from: …]` 尾碼的 `inbound web message` 條目。

## 已知注意事項
- 為避免雜訊廣播，群組會特意跳過心跳 (Heartbeats)。
- 回聲抑制使用合併後的批次字串；如果您在沒有提及的情況下兩次發送相同的文字，只有第一次會得到回應。
- 會話儲存條目將以 `agent:<agentId>:whatsapp:group:<jid>` 的形式出現在會話儲存（預設為 `~/.openclaw/agents/<agentId>/sessions/sessions.json`）中；缺少條目僅表示該群組尚未觸發運行。
- 群組中的輸入指示器遵循 `agents.defaults.typingMode`（預設：未提及時為 `message`）。
