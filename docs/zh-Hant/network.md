---
title: "Network(網路中心)"
summary: "網路中心：gateway 介面、配對、發現與安全性"
read_when:
  - 您需要網路架構 + 安全性概覽
  - 您正在除錯本地 vs tailnet 存取或配對
  - 您想要網路文件的權威清單
---
# Network hub(網路中心)

此中心連結 OpenClaw 如何連線、配對和保護
跨 localhost、LAN 和 tailnet 的裝置的核心文件。

## 核心模型

- [Gateway 架構](/concepts/architecture)
- [Gateway 協定](/gateway/protocol)
- [Gateway 運行手冊](/gateway)
- [Web 介面 + 綁定模式](/web)

## 配對 + 身份

- [配對概覽 (DM + nodes)](/start/pairing)
- [Gateway 擁有的節點配對](/gateway/pairing)
- [Devices CLI（配對 + 權杖輪換)](/cli/devices)
- [Pairing CLI (DM 核准)](/cli/pairing)

本地信任：
- 本地連線（loopback 或 gateway 主機自己的 tailnet 位址）可以
  自動核准配對以保持同主機 UX 的順暢。
- 非本地 tailnet/LAN 客戶端仍需要明確的配對核准。

## 發現 + 傳輸

- [Discovery & transports](/gateway/discovery)
- [Bonjour / mDNS](/gateway/bonjour)
- [遠端存取 (SSH)](/gateway/remote)
- [Tailscale](/gateway/tailscale)

## 節點 + 傳輸

- [節點概覽](/nodes)
- [Bridge 協定（舊版節點)](/gateway/bridge-protocol)
- [節點運行手冊：iOS](/platforms/ios)
- [節點運行手冊：Android](/platforms/android)

## 安全性

- [安全性概覽](/gateway/security)
- [Gateway 設定參考](/gateway/configuration)
- [疑難排解](/gateway/troubleshooting)
- [Doctor](/gateway/doctor)
