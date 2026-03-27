---
summary: "DeepSeek 設定 (驗證 + 模型選擇)"
read_when:
  - You want to use DeepSeek with OpenClaw
  - You need the API key env var or CLI auth choice
title: "DeepSeek（DeepSeek）"
---

# DeepSeek

[DeepSeek](https://www.deepseek.com) 提供強大的 AI 模型，具備 OpenAI 相容 API。

- 提供者：`deepseek`
- 驗證：`DEEPSEEK_API_KEY`
- API：OpenAI 相容

## 快速開始

設定 API 金鑰（建議：為閘道儲存）：

```bash
openclaw onboard --auth-choice deepseek-api-key
```

這會提示您輸入 API 金鑰，並將 `deepseek/deepseek-chat` 設定為預設模型。

## 非互動式範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice deepseek-api-key \
  --deepseek-api-key "$DEEPSEEK_API_KEY" \
  --skip-health \
  --accept-risk
```

## 環境注意

如果閘道作為守護程式執行 (launchd/systemd)，請確保 `DEEPSEEK_API_KEY` 對該程式可用（例如，在 `~/.openclaw/.env` 或透過 `env.shellEnv`）。

## 可用的模型

| 模型 ID             | 名稱                     | 類型 | 上下文 |
| ------------------- | ------------------------ | ---- | ------ |
| `deepseek-chat`     | DeepSeek Chat (V3.2)     | 通用 | 128K   |
| `deepseek-reasoner` | DeepSeek Reasoner (V3.2) | 推理 | 128K   |

- **deepseek-chat** 對應於非思考模式中的 DeepSeek-V3.2。
- **deepseek-reasoner** 對應於具有思維鏈推理的思考模式中的 DeepSeek-V3.2。

在 [platform.deepseek.com](https://platform.deepseek.com/api_keys) 取得您的 API 金鑰。
