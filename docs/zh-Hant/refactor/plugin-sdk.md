---
summary: "Plugin SDK 架構和實作計畫"
read_when:
  - 開發 OpenClaw 外掛程式
  - 貢獻外掛程式改進
  - 理解外掛程式系統架構
title: "Plugin SDK Refactor（Plugin SDK 重構）"
---

# Plugin SDK 架構

## 概述

Plugin SDK 提供基礎架構讓外掛程式與 Gateway 和 Agent 互動。

## 核心元件

1. **套接字和 WebSocket**：與 Gateway 通訊
2. **工具和命令**：註冊外掛程式提供的工具
3. **設定架構**：透過 JSON Schema 驗證設定
4. **記憶體和會話**：存取會話狀態和記憶體
5. **事件和掛接**：訂閱 Gateway 事件

## 外掛程式清單

詳見 [Plugin Manifest](/zh-Hant/plugins/manifest) 了解清單要求和結構描述。

## 新增外掛程式

詳見 [Plugins](/zh-Hant/tools/plugin) 了解完整外掛程式開發指南。
