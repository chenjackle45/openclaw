---
summary: "OpenClaw 支援的模型提供者（LLM）"
read_when:
  - You want to choose a model provider
  - You want quick setup examples for LLM auth + model selection
title: "Model Provider Quickstart（模型提供者快速開始）"
---

# 模型提供者

OpenClaw 可以使用許多 LLM 提供者。選擇一個，認證，然後將預設模型設定為 `provider/model`。

## 快速開始（兩步）

1. 使用提供者認證（通常透過 `openclaw onboard`）。
2. 設定預設模型：

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

## 支援的提供者（入門集）

- [OpenAI（API + Codex）](/zh-Hant/providers/openai)
- [Anthropic（API + Claude Code CLI）](/zh-Hant/providers/anthropic)
- [OpenRouter](/zh-Hant/providers/openrouter)
- [Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
- [Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)
- [Moonshot AI（Kimi + Kimi Coding）](/zh-Hant/providers/moonshot)
- [Mistral](/zh-Hant/providers/mistral)
- [Synthetic](/zh-Hant/providers/synthetic)
- [OpenCode Zen](/zh-Hant/providers/opencode)
- [Z.AI](/zh-Hant/providers/zai)
- [GLM 模型](/zh-Hant/providers/glm)
- [MiniMax](/zh-Hant/providers/minimax)
- [Venice（Venice AI）](/zh-Hant/providers/venice)
- [Amazon Bedrock](/zh-Hant/providers/bedrock)
- [Qianfan](/zh-Hant/providers/qianfan)

如需完整提供者目錄（xAI、Groq、Mistral 等）和進階設定，見 [模型提供者](/zh-Hant/concepts/model-providers)。
