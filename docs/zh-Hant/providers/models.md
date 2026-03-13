---
summary: "OpenClaw 支援的模型提供者（LLM）"
read_when:
  - 你想選擇一個模型提供者
  - 你需要 LLM 驗證與模型選擇的快速設定範例
title: "Model Provider Quickstart（模型提供者快速開始）"
---

# 模型提供者

OpenClaw 可以使用許多 LLM 提供者。選擇一個，進行驗證，然後將預設模型設定為 \`provider/model\`。

## 快速開始（兩個步驟）

1. 使用提供者進行驗證（通常透過 \`openclaw onboard\`）。
2. 設定預設模型：

\`\`\`json5
{
agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
\`\`\`

## 支援的提供者（入門組合）

- [OpenAI (API + Codex)](/zh-Hant/providers/openai)
- [Anthropic (API + Claude Code CLI)](/zh-Hant/providers/anthropic)
- [OpenRouter](/zh-Hant/providers/openrouter)
- [Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
- [Cloudflare AI Gateway](/zh-Hant/providers/cloudflare-ai-gateway)
- [Moonshot AI (Kimi + Kimi Coding)](/zh-Hant/providers/moonshot)
- [Mistral](/zh-Hant/providers/mistral)
- [Synthetic](/zh-Hant/providers/synthetic)
- [OpenCode (Zen + Go)](/zh-Hant/providers/opencode)
- [Z.AI](/zh-Hant/providers/zai)
- [GLM 模型](/zh-Hant/providers/glm)
- [MiniMax](/zh-Hant/providers/minimax)
- [Venice (Venice AI)](/zh-Hant/providers/venice)
- [Amazon Bedrock](/zh-Hant/providers/bedrock)
- [Qianfan](/zh-Hant/providers/qianfan)

有關完整提供者目錄（xAI、Groq、Mistral 等）與進階設定，
見 [Model providers](/zh-Hant/concepts/model-providers)。
