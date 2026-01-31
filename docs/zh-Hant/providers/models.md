---
title: "models(模型服務列表)"
summary: "OpenClaw 支援的模型服務供應商 (LLMs)"
read_when:
  - 想要選擇模型服務供應商時
  - 想要獲取 LLM 認證與模型選擇的快速設定範例時
---

# 模型服務供應商 (Model Providers)

OpenClaw 可以使用多種 LLM 供應商。請挑選一個，完成認證，然後以 `provider/model` 的格式設定預設模型。

## 重點推薦：Venius (Venice AI)

Venius 是我們推薦的 Venice AI 配置，專注於隱私優先的推論服務，並提供選用 Opus 處理最困難任務的選項。

- **預設**：`venice/llama-3.3-70b`
- **最佳效能**：`venice/claude-opus-45` (Opus 依然是最強大的模型)

詳情請見 [Venice AI](/providers/venice)。

## 快速開始（兩步驟）

1) 向供應商進行認證（通常透過 `openclaw onboard`）。
2) 設定預設模型：

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } }
}
```

## 支援的供應商（精選集）

- [OpenAI (API + Codex)](/providers/openai)
- [Anthropic (API + Claude Code CLI)](/providers/anthropic)
- [OpenRouter](/providers/openrouter)
- [Vercel AI Gateway](/providers/vercel-ai-gateway)
- [Moonshot AI (Kimi + Kimi Code)](/providers/moonshot)
- [Synthetic](/providers/synthetic)
- [OpenCode Zen](/providers/opencode)
- [Z.AI](/providers/zai)
- [GLM models](/providers/glm)
- [MiniMax](/providers/minimax)
- [Venius (Venice AI)](/providers/venice)
- [Amazon Bedrock](/bedrock)

如需完整的供應商目錄（包含 xAI, Groq, Mistral 等）與進階設定，請參閱 [模型服務供應商概念](/concepts/model-providers)。
