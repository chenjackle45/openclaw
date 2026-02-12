---
summary: "網路中樞：Gateway 介面、配對、發現和安全"
read_when:
  - 你需要網路架構 + 安全概述
  - 你正在調試本機與 tailnet 存取或配對
  - 你想要網路文件的規範清單
title: "Network（網路）"
---

# 網路中樞

此中樞連結核心文件，說明 OpenClaw 如何在 localhost、LAN 和 tailnet 上連接、配對和保護裝置。

## 核心模型

- [Gateway 架構](/zh-Hant/concepts/architecture)
- [Gateway 協議](/zh-Hant/gateway/protocol)
- [Gateway 執行手冊](/zh-Hant/gateway)
- [Web 介面 + 繫結模式](/zh-Hant/web)

## 配對和身分

- [配對概述（DM + 節點）](/zh-Hant/channels/pairing)
- [Gateway 所有節點配對](/zh-Hant/gateway/pairing)
- [裝置 CLI（配對 + 標記旋轉）](/zh-Hant/cli/devices)
- [配對 CLI（DM 核准）](/zh-Hant/cli/pairing)

本機信任：

- 本機連接（迴圈或 Gateway 主機自己的 tailnet 位址）可以自動核准以配對以保持同主機 UX 順利。
- 非本機 tailnet/LAN 用戶端仍需要明確的配對核准。

## 發現和傳輸

- [發現和傳輸](/zh-Hant/gateway/discovery)
- [Bonjour / mDNS](/zh-Hant/gateway/bonjour)
- [遠端存取（SSH）](/zh-Hant/gateway/remote)
- [Tailscale](/zh-Hant/gateway/tailscale)

## 節點和傳輸

- [節點概述](/zh-Hant/nodes)
- [橋接協議（舊版節點）](/zh-Hant/gateway/bridge-protocol)
- [節點執行手冊：iOS](/zh-Hant/platforms/ios)
- [節點執行手冊：Android](/zh-Hant/platforms/android)

## 安全

- [安全概述](/zh-Hant/gateway/security)
- [Gateway 設定參考](/zh-Hant/gateway/configuration)
- [疑難排解](/zh-Hant/gateway/troubleshooting)
- [醫生](/zh-Hant/gateway/doctor)
