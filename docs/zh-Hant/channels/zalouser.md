---
title: "Zalo Personal"
summary: "透過 zca-cli (QR 登入) 的 Zalo 個人帳號支援、功能與設定"
read_when:
  - 為 OpenClaw 設定 Zalo 個人帳號時
---

# Zalo Personal（非官方）

狀態：實驗性。此整合透過 OpenClaw 內建的原生 `zca-js` 自動化**個人 Zalo 帳號**。

> **警告：** 這是非官方整合，可能導致帳號暫停/封禁。使用風險自負。

## 需要外掛程式

Zalo Personal 以外掛程式形式發布，未隨核心安裝捆綁。

- 透過 CLI 安裝：`openclaw plugins install @openclaw/zalouser`
- 或從原始碼 checkout：`openclaw plugins install ./extensions/zalouser`
- 詳情：[Plugins](/zh-Hant/tools/plugin)

不需要外部的 `zca`/`openzca` CLI 執行檔。

## 快速設定（初學者）

1. 安裝外掛程式（見上方）。
2. 登入（QR，在 Gateway 機器上）：
   - `openclaw channels login --channel zalouser`
   - 用 Zalo 手機 app 掃描 QR 碼。
3. 啟用頻道：

```json5
{
  channels: {
    zalouser: {
      enabled: true,
      dmPolicy: "pairing",
    },
  },
}
```

4. 重啟 Gateway（或完成上線）。
5. DM 存取預設為配對；第一次聯絡時核准配對碼。

## 這是什麼

- 完全透過 `zca-js` 在進程中執行。
- 使用原生事件監聽器接收入站訊息。
- 直接透過 JS API 傳送回覆（文字/媒體/連結）。
- 專為 Zalo Bot API 不可用的「個人帳號」使用案例設計。

## 命名

頻道 ID 為 `zalouser`，以明確這是自動化的**個人 Zalo 用戶帳號**（非官方）。`zalo` 保留給潛在的未來官方 Zalo API 整合。

## 查找 ID（目錄）

使用目錄 CLI 發現 peer/群組及其 ID：

```bash
openclaw directory self --channel zalouser
openclaw directory peers list --channel zalouser --query "name"
openclaw directory groups list --channel zalouser --query "work"
```

## 限制

- 出站文字分塊為約 2000 個字元（Zalo 用戶端限制）。
- 串流預設封鎖。

## 存取控制（DM）

`channels.zalouser.dmPolicy` 支援：`pairing | allowlist | open | disabled`（預設：`pairing`）。

`channels.zalouser.allowFrom` 接受用戶 ID 或名稱。在上線過程中，名稱使用外掛程式的進程中聯絡人查詢解析為 ID。

透過以下核准：

- `openclaw pairing list zalouser`
- `openclaw pairing approve zalouser <code>`

## 群組存取（選用）

- 預設：`channels.zalouser.groupPolicy = "open"`（允許群組）。使用 `channels.defaults.groupPolicy` 在未設定時覆蓋預設。
- 使用以下限制為 allowlist：
  - `channels.zalouser.groupPolicy = "allowlist"`
  - `channels.zalouser.groups`（鍵為群組 ID 或名稱；控制哪些群組被允許）
  - `channels.zalouser.groupAllowFrom`（控制允許的群組中哪些發送者可以觸發 bot）
- 封鎖所有群組：`channels.zalouser.groupPolicy = "disabled"`。
- 設定精靈可以提示輸入群組 allowlist。
- 啟動時，OpenClaw 將 allowlist 中的群組/用戶名稱解析為 ID 並記錄對應；未解析的條目保留原樣。
- 若未設定 `groupAllowFrom`，執行時退回到 `allowFrom` 進行群組發送者檢查。
- 發送者檢查適用於普通群組訊息和控制指令（例如 `/new`、`/reset`）。

範例：

```json5
{
  channels: {
    zalouser: {
      groupPolicy: "allowlist",
      groupAllowFrom: ["1471383327500481391"],
      groups: {
        "123456789": { allow: true },
        "Work Chat": { allow: true },
      },
    },
  },
}
```

### 群組 mention 閘道

- `channels.zalouser.groups.<group>.requireMention` 控制群組回覆是否需要 mention。
- 解析順序：確切的群組 id/名稱 -> 正規化的群組 slug -> `*` -> 預設（`true`）。
- 這適用於 allowlist 群組和開放群組模式。
- 授權的控制指令（例如 `/new`）可以繞過 mention 閘道。
- 當群組訊息因需要 mention 而被跳過時，OpenClaw 將其儲存為待處理的群組歷史，並在下一個處理的群組訊息中包含它。
- 群組歷史限制預設為 `messages.groupChat.historyLimit`（備用 `50`）。你可以使用 `channels.zalouser.historyLimit` 按帳號覆蓋。

範例：

```json5
{
  channels: {
    zalouser: {
      groupPolicy: "allowlist",
      groups: {
        "*": { allow: true, requireMention: true },
        "Work Chat": { allow: true, requireMention: false },
      },
    },
  },
}
```

## 多帳號

帳號對應到 OpenClaw 狀態中的 `zalouser` 設定檔。範例：

```json5
{
  channels: {
    zalouser: {
      enabled: true,
      defaultAccount: "default",
      accounts: {
        work: { enabled: true, profile: "work" },
      },
    },
  },
}
```

## Typing、reactions 和傳遞確認

- OpenClaw 在傳送回覆前發送 typing 事件（盡力而為）。
- `zalouser` 在頻道動作中支援訊息 reaction 動作 `react`。
  - 使用 `remove: true` 從訊息移除特定 reaction 表情符號。
  - Reaction 語義：[Reactions](/zh-Hant/tools/reactions)
- 對於包含事件 metadata 的入站訊息，OpenClaw 傳送已接收 + 已查看確認（盡力而為）。

## 疑難排解

**登入不持久：**

- `openclaw channels status --probe`
- 重新登入：`openclaw channels logout --channel zalouser && openclaw channels login --channel zalouser`

**Allowlist/群組名稱未解析：**

- 在 `allowFrom`/`groupAllowFrom`/`groups` 中使用數字 ID，或確切的好友/群組名稱。

**從舊版 CLI 設定升級：**

- 移除任何舊版外部 `zca` 進程的假設。
- 頻道現在完全在 OpenClaw 中執行，無需外部 CLI 執行檔。
