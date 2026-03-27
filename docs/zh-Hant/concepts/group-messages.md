---
summary: "WhatsApp 群組訊息處理的行為和配置（mentionPatterns 跨表面共享）"
read_when:
  - 變更群組訊息規則或提及
title: "Group Messages（群組訊息）"
sidebarTitle: "群組訊息"
---

# 群組訊息（WhatsApp web 頻道）

目標：讓 Clawd 坐在 WhatsApp 群組中，僅當被 ping 時喚醒，並將該執行緒與個人 DM 工作階段分開。

備註：`agents.list[].groupChat.mentionPatterns` 現在由 Telegram／Discord／Slack／iMessage 也使用；本文件專注 WhatsApp 專用行為。對多代理設置，按代理設定 `agents.list[].groupChat.mentionPatterns`（或使用 `messages.groupChat.mentionPatterns` 作為全域回退）。

## 目前實現 (2025-12-03)

- 啟用模式：`mention`（預設）或 `always`。`mention` 需要 ping（真實 WhatsApp @-mentions 透過 `mentionedJids`、安全正則表達式模式或 bot 的 E.164 在文字任何地方）。`always` 在每個訊息喚醒代理但應僅在能新增有意義價值時回覆；否則回傳無聲令杖 `NO_REPLY`。預設可在設定中設定（`channels.whatsapp.groups`）並按群組透過 `/activation` 覆蓋。當 `channels.whatsapp.groups` 被設定，它也充當群組允許清單（包括 `"*"` 允許所有）。
- 群組原則：`channels.whatsapp.groupPolicy` 控制群組訊息是否被接受（`open|disabled|allowlist`）。`allowlist` 使用 `channels.whatsapp.groupAllowFrom`（回退：明確 `channels.whatsapp.allowFrom`）。預設是 `allowlist`（阻止直到你新增寄件者）。
- 按群組工作階段：工作階段鍵看起來像 `agent:<agentId>:whatsapp:group:<jid>`，所以命令如 `/verbose on` 或 `/think high`（以獨立訊息傳送）範圍限於該群組；個人 DM 狀態未被觸及。心跳被跳過群組執行緒。
- 上下文注入：**待決專用**群組訊息（預設 50）*未*觸發執行被前綴在 `[Chat messages since your last reply - for context]` 下，觸發線在 `[Current message - respond to this]` 下。已在工作階段中的訊息不被重新注入。
- 寄件者表面化：每個群組批次現在以 `[from: Sender Name (+E164)]` 結束，所以 Pi 知道誰在說話。
- 短暫的／只檢視一次：我們在提取文字／提及前解開那些，所以 ping 在它們內部仍觸發。
- 群組系統提示：新群組工作階段首次輪（以及每當 `/activation` 變更模式時）我們注入短線到系統提示如 `You are replying inside the WhatsApp group "<subject>". Group members: Alice (+44...), Bob (+43...), … Activation: trigger-only … Address the specific sender noted in the message context.` 如果中繼資料不可用我們仍告訴代理這是群組聊天。

## 配置示例（WhatsApp）

新增 `groupChat` 區塊到 `~/.openclaw/openclaw.json` 所以顯示名稱 ping 運作，即使 WhatsApp 從文字本體中移除視覺 `@`：

```json5
{
  channels: {
    whatsapp: {
      groups: {
        "*": { requireMention: true },
      },
    },
  },
  agents: {
    list: [
      {
        id: "main",
        groupChat: {
          historyLimit: 50,
          mentionPatterns: ["@?openclaw", "\\+?15555550123"],
        },
      },
    ],
  },
}
```

備註：

- 正則表達式不分大小寫，使用與其他設定正則表達式表面相同的安全正則表達式護欄；無效模式和不安全的嵌套重複被忽略。
- WhatsApp 仍透過 `mentionedJids` 在某人輕敲聯絡人時傳送規範提及，所以號碼回退很少需要但是有用的安全網。

### 啟用命令（擁有者專用）

使用群組聊天命令：

- `/activation mention`
- `/activation always`

僅擁有者號碼（自 `channels.whatsapp.allowFrom`，或 bot 自身 E.164 未設定時）可變更此。以獨立訊息傳送 `/status` 在群組中看目前啟用模式。

## 如何使用

1. 新增你的 WhatsApp 帳戶（執行 OpenClaw 的）到群組。
2. 說 `@openclaw …`（或包含號碼）。僅允許清單寄件者可觸發它，除非你設定 `groupPolicy: "open"`。
3. 代理提示包括最近群組上下文加上末尾 `[from: …]` 標記，所以它可定址右邊人。
4. 工作階段層級指令（`/verbose on`、`/think high`、`/new` 或 `/reset`、`/compact`）僅套用該群組工作階段；以獨立訊息傳送它們所以它們註冊。你的個人 DM 工作階段保持獨立。

## 測試／驗證

- 手動冒煙：
  - 在群組傳送 `@openclaw` ping，確認參考寄件者名稱的回覆。
  - 傳送第二個 ping，驗證歷史區塊被包括，然後在下一輪清除。
- 檢查 gateway 日誌（使用 `--verbose` 執行）看 `inbound web message` 條目顯示 `from: <groupJid>` 和 `[from: …]` 後綴。

## 已知考慮

- 心跳被故意跳過群組以避免吵鬧廣播。
- 回聲抑制使用組合批次字串；如果你傳送相同文字兩次無提及，僅首次取得回覆。
- 工作階段存儲條目將出現為 `agent:<agentId>:whatsapp:group:<jid>` 在工作階段存儲（預設 `~/.openclaw/agents/<agentId>/sessions/sessions.json`）；缺失條目意味著群組尚未觸發執行。
- 群組中的輸入指示器遵循 `agents.defaults.typingMode`（預設：`message` 未提及時）。
