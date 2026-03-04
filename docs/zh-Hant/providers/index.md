---
summary: "OpenClaw 支援的模型提供者（LLM）"
read_when:
  - You want to choose a model provider
  - You need a quick overview of supported LLM backends
title: "Model Providers（模型提供者）"
---

# 模型提供者

OpenClaw 可以使用許多 LLM 提供者。選擇提供者，認證，然後將預設模型設定為 `provider/model`。

尋找聊天頻道文件（WhatsApp/Telegram/Discord/Slack/Mattermost（外掛）/ 等）？見 [頻道](/zh-Hant/channels)。

## 快速開始

1. 使用提供者認證（通常透過 `openclaw onboard`）。
2. 設定預設模型：

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

## 提供者文件

- [Amazon Bedrock](/zh-Hant/providers/bedrock)
- [Anthropic（API + Claude Code CLI）](/zh-Hant/providers/anthropic)
- [Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)
- [GLM 模型](/zh-Hant/providers/glm)
- [Hugging Face（推理）](/zh-Hant/providers/huggingface)
- [Kilocode](/zh-Hant/providers/kilocode)
- [LiteLLM（統一 gateway）](/zh-Hant/providers/litellm)
- [MiniMax](/zh-Hant/providers/minimax)
- [Mistral](/zh-Hant/providers/mistral)
- [Moonshot AI（Kimi + Kimi Coding）](/zh-Hant/providers/moonshot)
- [NVIDIA](/zh-Hant/providers/nvidia)
- [Ollama（本機模型）](/zh-Hant/providers/ollama)
- [OpenAI（API + Codex）](/zh-Hant/providers/openai)
- [OpenCode Zen](/zh-Hant/providers/opencode)
- [OpenRouter](/zh-Hant/providers/openrouter)
- [Qianfan](/zh-Hant/providers/qianfan)
- [Qwen（OAuth）](/zh-Hant/providers/qwen)
- [Together AI](/zh-Hant/providers/together)
- [Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
- [Venice（Venice AI，隱私優先）](/zh-Hant/providers/venice)
- [vLLM（本機模型）](/zh-Hant/providers/vllm)
- [Xiaomi](/zh-Hant/providers/xiaomi)
- [Z.AI](/zh-Hant/providers/zai)

## 轉錄提供者

- [Deepgram（音訊轉錄）](/zh-Hant/providers/deepgram)

## 社群工具

- [Claude Max API Proxy](/zh-Hant/providers/claude-max-api-proxy) - 用於 Claude 訂閱認證的社群代理（使用前驗證 Anthropic 政策 / 條款）

如需完整提供者目錄（xAI、Groq、Mistral 等）和進階設定，見 [模型提供者](/zh-Hant/concepts/model-providers)。
