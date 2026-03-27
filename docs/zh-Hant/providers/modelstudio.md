---
title: "Model Studio（Model Studio）"
summary: "Alibaba Cloud Model Studio 設定 (Coding Plan、雙地區端點)"
read_when:
  - You want to use Alibaba Cloud Model Studio with OpenClaw
  - You need the API key env var for Model Studio
---

# Model Studio (Alibaba Cloud)

Model Studio 提供者可存取 Alibaba Cloud Coding Plan 模型，包括平台上託管的 Qwen 和第三方模型。

- 提供者：`modelstudio`
- 驗證：`MODELSTUDIO_API_KEY`
- API：OpenAI 相容

## 快速開始

1. 設定 API 金鑰：

```bash
openclaw onboard --auth-choice modelstudio-api-key
```

2. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "modelstudio/qwen3.5-plus" },
    },
  },
}
```

## 地區端點

Model Studio 有兩個基於地區的端點：

| 地區      | 端點                                 |
| --------- | ------------------------------------ |
| 中國 (CN) | `coding.dashscope.aliyuncs.com`      |
| 全球      | `coding-intl.dashscope.aliyuncs.com` |

提供者會根據驗證選擇自動選擇（全球為 `modelstudio-api-key`，中國為 `modelstudio-api-key-cn`）。您可以在設定中使用自訂 `baseUrl` 覆蓋。

## 可用的模型

- **qwen3.5-plus**（預設）- Qwen 3.5 Plus
- **qwen3-max** - Qwen 3 Max
- **qwen3-coder** 系列 - Qwen 編碼模型
- **GLM-5**、**GLM-4.7** - 透過 Alibaba 的 GLM 模型
- **Kimi K2.5** - 透過 Alibaba 的 Moonshot AI
- **MiniMax-M2.5** - 透過 Alibaba 的 MiniMax

大多數模型支援影像輸入。上下文視窗範圍從 200K 到 1M 權杖。

## 環境注意

如果閘道作為守護程式執行 (launchd/systemd)，請確保 `MODELSTUDIO_API_KEY` 對該程式可用（例如，在 `~/.openclaw/.env` 或透過 `env.shellEnv`）。
