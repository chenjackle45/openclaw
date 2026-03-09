---
title: "WhatsApp"
summary: "WhatsApp（網頁頻道）整合：登入、收件匣、回覆、媒體和操作"
read_when:
  - 處理 WhatsApp/網頁頻道行為或收件匣路由
---

# WhatsApp（網頁頻道）

狀態：透過 WhatsApp Web（Baileys）已可正式使用。Gateway 擁有連結的工作階段。

<CardGroup cols={3}>
  <Card title="Pairing（配對）" icon="link" href="/zh-Hant/channels/pairing">
    未知發送者的預設 DM 政策為配對。
  </Card>
  <Card title="Channel troubleshooting（頻道疑難排解）" icon="wrench" href="/zh-Hant/channels/troubleshooting">
    跨頻道診斷與修復手冊。
  </Card>
  <Card title="Gateway configuration（Gateway 設定）" icon="settings" href="/zh-Hant/gateway/configuration">
    完整的頻道設定模式與範例。
  </Card>
</CardGroup>

## 快速設定

<Steps>
  <Step title="設定 WhatsApp 存取政策">

```json5
{
  channels: {
    whatsapp: {
      dmPolicy: "pairing",
      allowFrom: ["+15551234567"],
      groupPolicy: "allowlist",
      groupAllowFrom: ["+15551234567"],
    },
  },
}
```

  </Step>

  <Step title="連結 WhatsApp（QR）">

```bash
openclaw channels login --channel whatsapp
```

    針對特定帳號：

```bash
openclaw channels login --channel whatsapp --account work
```

  </Step>

  <Step title="啟動 gateway">

```bash
openclaw gateway
```

  </Step>

  <Step title="核准第一個配對請求（使用配對模式時）">

```bash
openclaw pairing list whatsapp
openclaw pairing approve whatsapp <CODE>
```

    配對請求 1 小時後過期。每個頻道最多保留 3 個待處理請求。

  </Step>
</Steps>

<Note>
OpenClaw 建議盡可能在獨立號碼上執行 WhatsApp。（頻道 metadata 和上線流程針對該設定最佳化，但個人號碼設定也受支援。）
</Note>

## 部署模式

<AccordionGroup>
  <Accordion title="專用號碼（建議）">
    這是最乾淨的操作模式：

    - OpenClaw 的獨立 WhatsApp 身份
    - 更清晰的 DM allowlist 和路由邊界
    - 降低自我聊天混淆的可能性

    最小政策模式：

    ```json5
    {
      channels: {
        whatsapp: {
          dmPolicy: "allowlist",
          allowFrom: ["+15551234567"],
        },
      },
    }
    ```

  </Accordion>

  <Accordion title="個人號碼備用">
    上線支援個人號碼模式並寫入適合自我聊天的基準設定：

    - `dmPolicy: "allowlist"`
    - `allowFrom` 包含你的個人號碼
    - `selfChatMode: true`

    在執行時，自我聊天保護根據連結的自身號碼和 `allowFrom` 作用。

  </Accordion>

  <Accordion title="WhatsApp Web 頻道範圍">
    目前 OpenClaw 頻道架構中的訊息平台頻道是基於 WhatsApp Web（`Baileys`）的。

    內建聊天頻道登錄中沒有單獨的 Twilio WhatsApp 訊息頻道。

  </Accordion>
</AccordionGroup>

## 執行時模型

- Gateway 擁有 WhatsApp socket 和重連迴圈。
- 出站傳送需要目標帳號有活動的 WhatsApp 監聽器。
- 狀態和廣播聊天被忽略（`@status`、`@broadcast`）。
- 直接聊天使用 DM 工作階段規則（`session.dmScope`；預設 `main` 將 DM 合併到 agent 主要工作階段）。
- 群組工作階段隔離（`agent:<agentId>:whatsapp:group:<jid>`）。

## 存取控制與啟動

<Tabs>
  <Tab title="DM 政策">
    `channels.whatsapp.dmPolicy` 控制直接聊天存取：

    - `pairing`（預設）
    - `allowlist`
    - `open`（需要 `allowFrom` 包含 `"*"`）
    - `disabled`

    `allowFrom` 接受 E.164 格式號碼（內部正規化）。

    多帳號覆蓋：`channels.whatsapp.accounts.<id>.dmPolicy`（和 `allowFrom`）對該帳號優先於頻道層級預設。

    執行時行為細節：

    - 配對在頻道允許儲存中持久化，並與設定的 `allowFrom` 合併
    - 若未設定 allowlist，連結的自身號碼預設被允許
    - 出站 `fromMe` DM 永遠不會自動配對

  </Tab>

  <Tab title="群組政策 + allowlist">
    群組存取有兩層：

    1. **群組成員資格 allowlist**（`channels.whatsapp.groups`）
       - 若省略 `groups`，所有群組都有資格
       - 若存在 `groups`，它作為群組 allowlist（允許 `"*"`）

    2. **群組發送者政策**（`channels.whatsapp.groupPolicy` + `groupAllowFrom`）
       - `open`：繞過發送者 allowlist
       - `allowlist`：發送者必須符合 `groupAllowFrom`（或 `*`）
       - `disabled`：封鎖所有群組入站

    發送者 allowlist 備用：

    - 若未設定 `groupAllowFrom`，執行時在可用時退回到 `allowFrom`
    - 發送者 allowlist 在 mention/回覆啟動前評估

    注意：若完全沒有 `channels.whatsapp` 區塊，執行時群組政策備用為 `allowlist`（記錄警告），即使設定了 `channels.defaults.groupPolicy`。

  </Tab>

  <Tab title="Mentions + /activation">
    群組回覆預設需要 mention。

    Mention 偵測包括：

    - bot 身份的明確 WhatsApp mention
    - 設定的 mention 正規表達式模式（`agents.list[].groupChat.mentionPatterns`，備用 `messages.groupChat.mentionPatterns`）
    - 隱式回覆 bot 偵測（回覆發送者匹配 bot 身份）

    安全注意：

    - 引用/回覆只滿足 mention 閘道；它**不**授予發送者授權
    - 搭配 `groupPolicy: "allowlist"` 時，非 allowlist 發送者即使回覆 allowlist 用戶的訊息仍然被封鎖

    工作階段層級啟動指令：

    - `/activation mention`
    - `/activation always`

    `activation` 更新工作階段狀態（非全域設定）。它受擁有者控制。

  </Tab>
</Tabs>

## 個人號碼和自我聊天行為

當連結的自身號碼也出現在 `allowFrom` 中時，WhatsApp 自我聊天保護會啟動：

- 跳過自我聊天回合的已讀回執
- 忽略否則會 ping 你自己的 mention-JID 自動觸發行為
- 若未設定 `messages.responsePrefix`，自我聊天回覆預設為 `[{identity.name}]` 或 `[openclaw]`

## 訊息正規化和上下文

<AccordionGroup>
  <Accordion title="入站封包 + 回覆上下文">
    入站 WhatsApp 訊息被包裝在共享的入站封包中。

    若存在引用回覆，上下文以此形式附加：

    ```text
    [Replying to <sender> id:<stanzaId>]
    <quoted body or media placeholder>
    [/Replying]
    ```

    回覆 metadata 欄位在可用時也會填充（`ReplyToId`、`ReplyToBody`、`ReplyToSender`、發送者 JID/E.164）。

  </Accordion>

  <Accordion title="媒體佔位符和位置/聯絡人提取">
    僅媒體的入站訊息使用佔位符正規化，例如：

    - `<media:image>`
    - `<media:video>`
    - `<media:audio>`
    - `<media:document>`
    - `<media:sticker>`

    位置和聯絡人 payload 在路由前正規化為文字上下文。

  </Accordion>

  <Accordion title="待處理群組歷史注入">
    對於群組，未處理的訊息可以緩衝並在 bot 最終被觸發時作為上下文注入。

    - 預設限制：`50`
    - 設定：`channels.whatsapp.historyLimit`
    - 備用：`messages.groupChat.historyLimit`
    - `0` 停用

    注入標記：

    - `[Chat messages since your last reply - for context]`
    - `[Current message - respond to this]`

  </Accordion>

  <Accordion title="已讀回執">
    已讀回執對接受的入站 WhatsApp 訊息預設啟用。

    全域停用：

    ```json5
    {
      channels: {
        whatsapp: {
          sendReadReceipts: false,
        },
      },
    }
    ```

    每帳號覆蓋：

    ```json5
    {
      channels: {
        whatsapp: {
          accounts: {
            work: {
              sendReadReceipts: false,
            },
          },
        },
      },
    }
    ```

    即使全域啟用，自我聊天回合也跳過已讀回執。

  </Accordion>
</AccordionGroup>

## 傳遞、分塊和媒體

<AccordionGroup>
  <Accordion title="文字分塊">
    - 預設區塊限制：`channels.whatsapp.textChunkLimit = 4000`
    - `channels.whatsapp.chunkMode = "length" | "newline"`
    - `newline` 模式偏好段落邊界（空行），然後退回到長度安全分塊
  </Accordion>

  <Accordion title="出站媒體行為">
    - 支援圖片、影片、音訊（PTT 語音筆記）和文件 payload
    - `audio/ogg` 被改寫為 `audio/ogg; codecs=opus` 以兼容語音筆記
    - 透過影片傳送的 `gifPlayback: true` 支援動態 GIF 播放
    - 傳送多媒體回覆 payload 時，說明套用到第一個媒體項目
    - 媒體來源可以是 HTTP(S)、`file://` 或本地路徑
  </Accordion>

  <Accordion title="媒體大小限制和備用行為">
    - 入站媒體儲存上限：`channels.whatsapp.mediaMaxMb`（預設 `50`）
    - 出站媒體傳送上限：`channels.whatsapp.mediaMaxMb`（預設 `50`）
    - 每帳號覆蓋使用 `channels.whatsapp.accounts.<accountId>.mediaMaxMb`
    - 圖片自動最佳化（調整大小/品質調整）以符合限制
    - 媒體傳送失敗時，第一個項目備用發送文字警告而非靜默丟棄回應
  </Accordion>
</AccordionGroup>

## 確認 reactions

WhatsApp 透過 `channels.whatsapp.ackReaction` 在入站接受時支援立即的 ack reaction。

```json5
{
  channels: {
    whatsapp: {
      ackReaction: {
        emoji: "👀",
        direct: true,
        group: "mentions", // always | mentions | never
      },
    },
  },
}
```

行為注意：

- 在入站被接受後立即傳送（回覆前）
- 失敗被記錄但不阻止一般回覆傳遞
- 群組模式 `mentions` 在 mention 觸發的回合中 react；群組啟動 `always` 作為此檢查的繞過
- WhatsApp 使用 `channels.whatsapp.ackReaction`（此處不使用舊版 `messages.ackReaction`）

## 多帳號和憑證

<AccordionGroup>
  <Accordion title="帳號選擇和預設">
    - 帳號 ID 來自 `channels.whatsapp.accounts`
    - 預設帳號選擇：若存在 `default`，否則第一個設定的帳號 ID（排序）
    - 帳號 ID 在查詢時內部正規化
  </Accordion>

  <Accordion title="憑證路徑和舊版相容性">
    - 目前驗證路徑：`~/.openclaw/credentials/whatsapp/<accountId>/creds.json`
    - 備份檔案：`creds.json.bak`
    - `~/.openclaw/credentials/` 中的舊版預設驗證仍可識別/遷移用於預設帳號流程
  </Accordion>

  <Accordion title="登出行為">
    `openclaw channels logout --channel whatsapp [--account <id>]` 清除該帳號的 WhatsApp 驗證狀態。

    在舊版驗證目錄中，`oauth.json` 保留，而 Baileys 驗證檔案被移除。

  </Accordion>
</AccordionGroup>

## 工具、動作和設定寫入

- Agent 工具支援包括 WhatsApp reaction 動作（`react`）。
- 動作閘道：
  - `channels.whatsapp.actions.reactions`
  - `channels.whatsapp.actions.polls`
- 頻道發起的設定寫入預設啟用（透過 `channels.whatsapp.configWrites=false` 停用）。

## 疑難排解

<AccordionGroup>
  <Accordion title="未連結（需要 QR）">
    症狀：頻道狀態報告未連結。

    修復：

    ```bash
    openclaw channels login --channel whatsapp
    openclaw channels status
    ```

  </Accordion>

  <Accordion title="已連結但斷開 / 重連迴圈">
    症狀：已連結的帳號反覆斷開或嘗試重連。

    修復：

    ```bash
    openclaw doctor
    openclaw logs --follow
    ```

    若需要，使用 `channels login` 重新連結。

  </Accordion>

  <Accordion title="傳送時沒有活動的監聽器">
    當目標帳號沒有活動的 gateway 監聽器時，出站傳送快速失敗。

    確認 gateway 正在執行且帳號已連結。

  </Accordion>

  <Accordion title="群組訊息意外被忽略">
    依序檢查：

    - `groupPolicy`
    - `groupAllowFrom` / `allowFrom`
    - `groups` allowlist 條目
    - mention 閘道（`requireMention` + mention 模式）
    - `openclaw.json` 中的重複鍵（JSON5）：後面的條目覆蓋前面的，所以每個範圍只保留一個 `groupPolicy`

  </Accordion>

  <Accordion title="Bun 執行時警告">
    WhatsApp gateway 執行時應使用 Node。Bun 被標記為不相容，不適用於穩定的 WhatsApp/Telegram gateway 操作。
  </Accordion>
</AccordionGroup>

## 設定參考指標

主要參考：

- [Configuration reference - WhatsApp](/zh-Hant/gateway/configuration-reference#whatsapp)

WhatsApp 高信號欄位：

- 存取：`dmPolicy`、`allowFrom`、`groupPolicy`、`groupAllowFrom`、`groups`
- 傳遞：`textChunkLimit`、`chunkMode`、`mediaMaxMb`、`sendReadReceipts`、`ackReaction`
- 多帳號：`accounts.<id>.enabled`、`accounts.<id>.authDir`、帳號層級覆蓋
- 操作：`configWrites`、`debounceMs`、`web.enabled`、`web.heartbeatSeconds`、`web.reconnect.*`
- 工作階段行為：`session.dmScope`、`historyLimit`、`dmHistoryLimit`、`dms.<id>.historyLimit`

## 相關

- [Pairing](/zh-Hant/channels/pairing)
- [Channel routing](/zh-Hant/channels/channel-routing)
- [Multi-agent routing](/zh-Hant/concepts/multi-agent)
- [Troubleshooting](/zh-Hant/channels/troubleshooting)
