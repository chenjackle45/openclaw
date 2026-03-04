---
summary: "Zalo Personal plugin: QR login + messaging via native zca-js (plugin install + channel config + tool)"
read_when:
  - You want Zalo Personal (unofficial) support in OpenClaw
  - You are configuring or developing the zalouser plugin
title: "Zalo Personal Plugin（Zalo 個人外掛程式）"
---

# Zalo 個人（外掛）

OpenClaw 透過外掛支援 Zalo Personal，使用原生 `zca-js` 來自動化普通 Zalo 使用者帳戶。

> **警告：** 非官方自動化可能導致帳戶暫停/禁用。自行承擔風險。

## 命名

通道 ID 是 `zalouser`，以明確此自動化一個**個人 Zalo 使用者帳戶**（非官方）。我們保留 `zalo` 作為潛在的未來官方 Zalo API 整合。

## 執行位置

此外掛在**閘道程序內**執行。

如果你使用遠端閘道，在**執行閘道的機器上**安裝/設定它，然後重新啟動閘道。

不需要外部 `zca`/`openzca` CLI 二進位檔。

## 安裝

### 選項 A：從 npm 安裝

```bash
openclaw plugins install @openclaw/zalouser
```

之後重新啟動閘道。

### 選項 B：從本機資料夾安裝（開發）

```bash
openclaw plugins install ./extensions/zalouser
cd ./extensions/zalouser && pnpm install
```

之後重新啟動閘道。

## 設定

通道設定位於 `channels.zalouser`（不是 `plugins.entries.*`）：

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

## CLI

```bash
openclaw channels login --channel zalouser
openclaw channels logout --channel zalouser
openclaw channels status --probe
openclaw message send --channel zalouser --target <threadId> --message "Hello from OpenClaw"
openclaw directory peers list --channel zalouser --query "name"
```

## 代理工具

工具名稱：`zalouser`

操作：`send`、`image`、`link`、`friends`、`groups`、`me`、`status`

通道訊息操作也支援 `react` 以用於訊息反應。
