---
title: "Zalouser(Zalo Personal Plugin)"
summary: "Zalo Personal Plugin：QR 登入 + 透過 zca-cli 訊息傳遞（Plugin 安裝 + Channel Config + CLI + Tool）"
read_when:
  - 您想在 OpenClaw 中使用 Zalo Personal（非官方）支援
  - 您正在設定或開發 zalouser Plugin
---

# Zalo Personal (Plugin)

透過 Plugin 為 OpenClaw 提供 Zalo Personal 支援，使用 `zca-cli` 自動化普通 Zalo 使用者帳號。

> **警告：** 非官方自動化可能導致帳號暫停/封鎖。使用風險自負。

## 命名

Channel ID 是 `zalouser`，以明確表示這是自動化**個人 Zalo 使用者帳號**（非官方）。我們保留 `zalo` 給未來可能的官方 Zalo API 整合。

## 執行位置

此 Plugin 在 **Gateway Process 內執行**。

如果您使用 Remote Gateway，請在**執行 Gateway 的機器**上安裝/設定它，然後重新啟動 Gateway。

## 安裝

### 選項 A：從 npm 安裝

```bash
openclaw plugins install @openclaw/zalouser
```

之後重新啟動 Gateway。

### 選項 B：從 Local 資料夾安裝（開發）

```bash
openclaw plugins install ./extensions/zalouser
cd ./extensions/zalouser && pnpm install
```

之後重新啟動 Gateway。

## 先決條件：zca-cli

Gateway 機器必須在 `PATH` 上有 `zca`：

```bash
zca --version
```

## Config

Channel Config 位於 `channels.zalouser` 下（非 `plugins.entries.*`）：

```json5
{
  channels: {
    zalouser: {
      enabled: true,
      dmPolicy: "pairing"
    }
  }
}
```

## CLI

```bash
openclaw channels login --channel zalouser
openclaw channels logout --channel zalouser
openclaw channels status --probe
openclaw message send --channel zalouser --target <threadId> --message "Hello from OpenClaw"
openclaw directory peers list --channel zalouser --query "name"
```

## Agent Tool

Tool 名稱：`zalouser`

動作：`send`、`image`、`link`、`friends`、`groups`、`me`、`status`
