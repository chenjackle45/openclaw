---
summary: "在 OpenClaw 中使用 Qianfan 統一 API 來存取許多模型"
read_when:
  - You want a single API key for many LLMs
  - You need Baidu Qianfan setup guidance
title: "Qianfan（千帆）"
---

# Qianfan Provider Guide

Qianfan 是百度的 MaaS 平台，提供**統一 API**，該 API 透過單一端點及 API 鑰將請求路由至許多模型。它是 OpenAI 相容，因此大多 OpenAI SDK 透過切換基礎 URL 工作。

## 前置條件

1. 百度雲帳戶及 Qianfan API 存取
2. 來自 Qianfan 控制台的 API 鑰
3. 系統上安裝的 OpenClaw

## 獲得 API 鑰

1. 造訪 [Qianfan Console](https://console.bce.baidu.com/qianfan/ais/console/apiKey)
2. 建立新應用或選擇現有應用
3. 生成 API 鑰（格式：`bce-v3/ALTAK-...`）
4. 複製 API 鑰以用於 OpenClaw

## CLI 設定

```bash
openclaw onboard --auth-choice qianfan-api-key
```

## 相關文件

- [OpenClaw Configuration](/zh-Hant/gateway/configuration)
- [Model Providers](/zh-Hant/concepts/model-providers)
- [Agent Setup](/zh-Hant/concepts/agent)
- [Qianfan API Documentation](https://cloud.baidu.com/doc/qianfan-api/s/3m7of64lb)
