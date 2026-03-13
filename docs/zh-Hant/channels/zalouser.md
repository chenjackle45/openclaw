---
summary: "透過原生 zca-js（QR 登入）的 Zalo 個人帳號支援、功能說明與設定方式"
read_when:
  - 為 OpenClaw 設定 Zalo 個人帳號
  - 除錯 Zalo 個人帳號登入或訊息流程
title: "Zalo Personal（Zalo 個人帳號）"
---

# Zalo Personal (unofficial)

狀態：實驗性。此整合透過 OpenClaw 內建的原生 `zca-js` 自動化**個人 Zalo 帳號**。

> **警告：** 這是非官方整合，可能導致帳號被暫停/封禁。請自行承擔風險。

## 需要安裝插件

Zalo Personal 以插件形式提供，不包含在核心安裝中。

- 透過 CLI 安裝：`openclaw plugins install @openclaw/zalouser`
- 或從原始碼 checkout 安裝：`openclaw plugins install ./extensions/zalouser`
- 詳細說明：[插件](/zh-Hant/tools/plugin)

不需要外部 `zca`/`openzca` CLI 二進位檔。

## 快速設定（初學者）

1. 安裝插件（見上方）。
2. 登入（QR 碼，在 Gateway 機器上）：
   - `openclaw channels login --channel zalouser`
   - 使用 Zalo 手機應用程式掃描 QR 碼。
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

4. 重啟 Gateway（或完成引導流程）。
5. 私訊存取預設為配對；首次聯繫時核准配對碼。

## 運作方式

- 完全在程序內透過 `zca-js` 執行。
- 使用原生事件監聽器接收收入訊息。
- 直接透過 JS API 傳送回覆（文字/媒體/連結）。
- 專為 Zalo Bot API 不可用的「個人帳號」使用場景設計。

## 命名說明

頻道 ID 為 `zalouser`，明確表示這是在自動化**個人 Zalo 用戶帳號**（非官方）。我們將 `zalo` 保留給未來可能的官方 Zalo API 整合。

## 尋找 ID（目錄）

使用目錄 CLI 搜尋聯絡人/群組及其 ID：

```bash
openclaw directory self --channel zalouser
openclaw directory peers list --channel zalouser --query "name"
openclaw directory groups list --channel zalouser --query "work"
```

## 限制

- 輸出文字限制約 2000 個字元（Zalo 客戶端限制）。
- 預設封鎖串流。

## 存取控制（私訊）

`channels.zalouser.dmPolicy` 支援：`pairing | allowlist | open | disabled`（預設：`pairing`）。

`channels.zalouser.allowFrom` 接受用戶 ID 或名稱。引導過程中，名稱會使用插件內建的聯絡人查詢解析為 ID。

核准方式：

- `openclaw pairing list zalouser`
- `openclaw pairing approve zalouser <code>`

## 群組存取（選填）

- 預設：`channels.zalouser.groupPolicy = "open"`（允許群組）。使用 `channels.defaults.groupPolicy` 覆寫未設定時的預設值。
- 透過以下設定限制為白名單：
  - `channels.zalouser.groupPolicy = "allowlist"`
  - `channels.zalouser.groups`（金鑰應為穩定的群組 ID；啟動時盡可能將名稱解析為 ID）
  - `channels.zalouser.groupAllowFrom`（控制已允許群組中哪些發送者可以觸發 Bot）
- 封鎖所有群組：`channels.zalouser.groupPolicy = "disabled"`。
- 設定精靈可提示輸入群組白名單。
- 啟動時，OpenClaw 將白名單中的群組/用戶名稱解析為 ID 並記錄映射。
- 群組白名單比對預設僅限 ID。未能解析的名稱在授權時被忽略，除非啟用 `channels.zalouser.dangerouslyAllowNameMatching: true`。
- `channels.zalouser.dangerouslyAllowNameMatching: true` 是緊急相容模式，可重新啟用可變更的群組名稱比對。
- 若未設定 `groupAllowFrom`，執行時備援使用 `allowFrom` 進行群組發送者檢查。
- 發送者檢查適用於一般群組訊息和控制指令（例如 `/new`、`/reset`）。

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

### 群組 Mention 閘門

- `channels.zalouser.groups.<group>.requireMention` 控制群組回覆是否需要 mention。
- 解析順序：確切群組 id/名稱 -> 正規化群組 slug -> `*` -> 預設（`true`）。
- 這適用於白名單群組和開放群組模式。
- 已授權的控制指令（例如 `/new`）可繞過 mention 閘門。
- 當群組訊息因需要 mention 而被略過時，OpenClaw 將其儲存為等待處理的群組記錄，並在下一則已處理的群組訊息時包含它。
- 群組記錄限制預設為 `messages.groupChat.historyLimit`（備援 `50`）。可透過 `channels.zalouser.historyLimit` 按帳號覆寫。

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

帳號映射至 OpenClaw 狀態中的 `zalouser` 設定檔。範例：

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

## 輸入、反應與傳送確認

- OpenClaw 在傳送回覆前傳送輸入中事件（盡力而為）。
- 訊息反應操作 `react` 在 `zalouser` 頻道操作中受支援。
  - 使用 `remove: true` 從訊息中移除特定反應 emoji。
  - 反應語意：[反應](/zh-Hant/tools/reactions)
- 對於包含事件中繼資料的收入訊息，OpenClaw 傳送已傳送 + 已讀確認（盡力而為）。

## 疑難排解

**登入狀態無法保持：**

- `openclaw channels status --probe`
- 重新登入：`openclaw channels logout --channel zalouser && openclaw channels login --channel zalouser`

**白名單/群組名稱未解析：**

- 在 `allowFrom`/`groupAllowFrom`/`groups` 中使用數字 ID，或確切的好友/群組名稱。

**從舊版 CLI 設定升級：**

- 移除任何舊版外部 `zca` 程序假設。
- 頻道現在完全在 OpenClaw 內執行，不需要外部 CLI 二進位檔。
