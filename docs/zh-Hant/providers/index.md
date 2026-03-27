---
summary: "OpenClaw 支援的模型提供者（LLM）"
read_when:
  - 你想選擇一個模型提供者
  - 你需要支援的 LLM 後端的快速概覽
title: "Provider Directory（模型提供者）"
---

# 模型提供者

OpenClaw 可以使用許多 LLM 提供者。選擇一個提供者，進行驗證，然後將預設模型設定為 \`provider/model\`。

尋找聊天頻道文件（WhatsApp/Telegram/Discord/Slack/Mattermost（外掛程式）等）？見 [Channels](/zh-Hant/channels)。

## 快速開始

1. 使用提供者進行驗證（通常透過 \`openclaw onboard\`）。
2. 設定預設模型：

\`\`\`json5
{
agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
\`\`\`

## 提供者文件

- [Amazon Bedrock](/zh-Hant/providers/bedrock)
- [Anthropic (API + Claude Code CLI)](/zh-Hant/providers/anthropic)
- [Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)
- [GLM 模型](/zh-Hant/providers/glm)
- [Hugging Face (Inference)](/zh-Hant/providers/huggingface)
- [Kilocode](/zh-Hant/providers/kilocode)
- [LiteLLM (unified gateway)](/zh-Hant/providers/litellm)
- [MiniMax](/zh-Hant/providers/minimax)
- [Mistral](/zh-Hant/providers/mistral)
- [Moonshot AI (Kimi + Kimi Coding)](/zh-Hant/providers/moonshot)
- [NVIDIA](/zh-Hant/providers/nvidia)
- [Ollama (雲端 + 本機模型)](/zh-Hant/providers/ollama)
- [OpenAI (API + Codex)](/zh-Hant/providers/openai)
- [OpenCode (Zen + Go)](/zh-Hant/providers/opencode)
- [OpenRouter](/zh-Hant/providers/openrouter)
- [Qianfan](/zh-Hant/providers/qianfan)
- [Qwen (OAuth)](/zh-Hant/providers/qwen)
- [Together AI](/zh-Hant/providers/together)
- [Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
- [Venice (Venice AI，注重隱私)](/zh-Hant/providers/venice)
- [vLLM (本機模型)](/zh-Hant/providers/vllm)
- [Xiaomi](/zh-Hant/providers/xiaomi)
- [Z.AI](/zh-Hant/providers/zai)

## 轉錄提供者

- [Deepgram (音訊轉錄)](/zh-Hant/providers/deepgram)

## 社群工具

- [Claude Max API Proxy](/zh-Hant/providers/claude-max-api-proxy) - Claude 訂閱憑證的社群 Proxy（使用前驗證 Anthropic 政策/條款）

有關完整提供者目錄（xAI、Groq、Mistral 等）與進階設定，
見 [Model providers](/zh-Hant/concepts/model-providers)。
