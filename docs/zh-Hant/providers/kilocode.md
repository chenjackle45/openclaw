---
summary: "使用 Kilo Gateway 的統一 API 在 OpenClaw 中存取多個模型"
read_when:
  - You want a single API key for many LLMs
  - You want to run models via Kilo Gateway in OpenClaw
title: "Kilo Gateway（Kilo Gateway）"
---

# Kilo Gateway

Kilo Gateway 提供一個**統一 API**，在單一端點和 API 鑰後方將請求路由到許多模型。它是 OpenAI 相容的，因此大多數 OpenAI SDK 可透過切換基底 URL 運作。

## 取得 API 鑰

1. 前往 [app.kilo.ai](https://app.kilo.ai)
2. 登入或建立帳戶
3. 導覽至 API 鑰並生成新鑰

## CLI 設定

```bash
openclaw onboard --kilocode-api-key <key>
```

或設定環境變數：

```bash
export KILOCODE_API_KEY="your-api-key"
```

## 設定片段

```json5
{
  env: { KILOCODE_API_KEY: "sk-..." },
  agents: {
    defaults: {
      model: { primary: "kilocode/anthropic/claude-opus-4.6" },
    },
  },
}
```

## 公開模型參考

內建 Kilo Gateway 目錄目前公開這些模型參考：

- `kilocode/anthropic/claude-opus-4.6`（預設）
- `kilocode/z-ai/glm-5:free`
- `kilocode/minimax/minimax-m2.5:free`
- `kilocode/anthropic/claude-sonnet-4.5`
- `kilocode/openai/gpt-5.2`
- `kilocode/google/gemini-3-pro-preview`
- `kilocode/google/gemini-3-flash-preview`
- `kilocode/x-ai/grok-code-fast-1`
- `kilocode/moonshotai/kimi-k2.5`

## 註記

- 模型參考是 `kilocode/<provider>/<model>`（例如 `kilocode/anthropic/claude-opus-4.6`）。
- 預設模型：`kilocode/anthropic/claude-opus-4.6`
- 基底 URL：`https://api.kilo.ai/api/gateway/`
- 如需更多模型 / 提供者選項，見 [/concepts/model-providers](/zh-Hant/concepts/model-providers)。
- Kilo Gateway 在底層使用 Bearer 令牌與 API 鑰。
