---
title: "Zalo Personal"
summary: "透過 zca-cli (QR 登入) 的 Zalo 個人帳號支援、功能與設定"
read_when:
  - 為 OpenClaw 設定 Zalo 個人帳號時
  - 偵錯 Zalo 個人帳號登入或訊息流程時
---

# Zalo 個人帳號（非官方）

狀態：實驗性功能。此整合透過 `zca-cli` 自動化操作 **Zalo 個人帳號**。

> **警告：** 這是一個非官方的整合方式，可能會導致帳號被停權或封禁。請自行承擔使用風險。

## 安裝插件

Zalo Personal 不隨核心安裝綑綁。

- 透過 CLI 安裝：`openclaw plugins install @openclaw/zalouser`
- 或從原始簽出：`openclaw plugins install ./extensions/zalouser`
- 詳情：[插件](/plugin)

## 先決條件：zca-cli

Gateway 機器必須在 `PATH` 中載有 `zca` 執行檔。

- 驗證：`zca --version`
- 如果缺少，安裝 zca-cli（見 `extensions/zalouser/README.md` 或上游 zca-cli 文件）。

## 快速設定（初學者）

1. 安裝插件（見上）。
2. 登入（QR，在 Gateway 機器上）：
   - `openclaw channels login --channel zalouser`
   - 使用 Zalo 手機應用程式掃描終端機中的 QR 碼。
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

4. 重啟 Gateway（或完成入門）。
5. DM 存取預設為配對；初次聯繫時核准配對碼。

## 這是什麼

- 使用 `zca listen` 接收入站訊息。
- 使用 `zca msg ...` 發送回覆（文字/媒體/連結）。
- 為「個人帳號」使用案例設計，其中 Zalo Bot API 不可用。

## 命名

頻道 ID 為 `zalouser` 以明確表示這自動化一個 **Zalo 個人使用者帳號**（非官方）。我們保留 `zalo` 以供潛在未來的官方 Zalo API 整合。

## 尋找 ID（目錄）

使用目錄 CLI 發現對等方/群組及其 ID：

```bash
openclaw directory self --channel zalouser
openclaw directory peers list --channel zalouser --query "name"
openclaw directory groups list --channel zalouser --query "work"
```

## 限制

- 外發文字分塊至約 2000 字元（Zalo 用戶端限制）。
- 預設停用串流。

## 存取控制（DM）

`channels.zalouser.dmPolicy` 支援：`pairing | allowlist | open | disabled`（預設：`pairing`）。
`channels.zalouser.allowFrom` 接受使用者 ID 或名稱。精靈在可用時透過 `zca friend find` 將名稱解析為 ID。

核准方式：

- `openclaw pairing list zalouser`
- `openclaw pairing approve zalouser <code>`

## 群組存取（可選）

- 預設：`channels.zalouser.groupPolicy = "open"`（允許群組）。使用 `channels.defaults.groupPolicy` 在未設定時覆寫預設值。
- 使用以下方式限制至允許清單：
  - `channels.zalouser.groupPolicy = "allowlist"`
  - `channels.zalouser.groups`（鍵為群組 ID 或名稱）
- 阻止所有群組：`channels.zalouser.groupPolicy = "disabled"`。
- 設定精靈可以提示群組允許清單。
- 啟動時，OpenClaw 將允許清單中的群組/使用者名稱解析為 ID 並記錄映射；未解析的條目保持原樣。

範例：

```json5
{
  channels: {
    zalouser: {
      groupPolicy: "allowlist",
      groups: {
        "123456789": { allow: true },
        "Work Chat": { allow: true },
      },
    },
  },
}
```

## 多帳戶

帳戶對應至 zca 設定檔。範例：

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

## 疑難排解

**`zca` 未找到：**

- 安裝 zca-cli 並確保它在 Gateway 程序的 `PATH` 上。

**登入不堅持：**

- `openclaw channels status --probe`
- 重新登入：`openclaw channels logout --channel zalouser && openclaw channels login --channel zalouser`
