---
summary: "LLM 認證 + 模型選擇的快速設定範例"
read_when:
  - 想要選擇模型服務供應商時
  - 想要獲取 LLM 認證與模型選擇的快速設定範例時
title: "Model Provider Quickstart（模型提供者快速開始）"
---

# 模型服務供應商 (Model Providers)

OpenClaw 可以使用多種 LLM 供應商。請挑選一個，完成認證，然後以 `provider/model` 的格式設定預設模型。

## 重點推薦：Venice (Venice AI)

Venice 是我們推薦的 Venice AI 設置，提供隱私優先推論與選用 Opus 處理最困難任務的選項。

- **預設**：`venice/llama-3.3-70b`
- **最佳效能**：`venice/claude-opus-45`（Opus 依然是最強大的）

詳情請見 [Venice AI](/zh-Hant/providers/venice)。

## 快速開始（兩步驟）

1. 向供應商進行認證（通常透過 `openclaw onboard`）。
2. 設定預設模型：

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } },
}
```

## 支援的供應商（精選集）

- [OpenAI (API + Codex)](/zh-Hant/providers/openai)
- [Anthropic (API + Claude Code CLI)](/zh-Hant/providers/anthropic)
- [OpenRouter](/zh-Hant/providers/openrouter)
- [Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
- [Moonshot AI (Kimi + Kimi Coding)](/zh-Hant/providers/moonshot)
- [Synthetic](/zh-Hant/providers/synthetic)
- [OpenCode Zen](/zh-Hant/providers/opencode)
- [Z.AI](/zh-Hant/providers/zai)
- [GLM models](/zh-Hant/providers/glm)
- [MiniMax](/zh-Hant/providers/minimax)
- [Venice (Venice AI)](/zh-Hant/providers/venice)
- [Amazon Bedrock](/zh-Hant/bedrock)

如需完整的供應商目錄（包含 xAI, Groq, Mistral 等）與進階設定，請參閱 [模型服務供應商概念](/zh-Hant/concepts/model-providers)。
