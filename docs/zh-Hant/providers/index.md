---
summary: "代表 OpenClaw 支援的模型提供者（LLM）"
read_when:
  - 想要選擇模型服務供應商時
  - 需要快速瀏覽支援的 LLM 後端時
title: "Model Providers（模型提供者）"
---

# 模型服務供應商 (Model Providers)

OpenClaw 支援多種 LLM 服務供應商。請挑選一個供應商，完成認證，然後以 `provider/model` 的格式設定預設模型。

正在尋找聊天頻道文件（WhatsApp/Telegram/Discord/Slack/Mattermost/等）？請參閱 [聊天頻道 (Channels)](/zh-Hant/channels)。

## 重點推薦：Venice (Venice AI)

Venice 是我們推薦的 Venice AI 設置，提供隱私優先推論與選用 Opus 處理最困難任務的選項。

- **預設**：`venice/llama-3.3-70b`
- **最佳效能**：`venice/claude-opus-45`（Opus 依然是最強大的）

詳情請見 [Venice AI](/zh-Hant/providers/venice)。

## 快速開始

1. 向供應商進行認證（通常透過 `openclaw onboard`）。
2. 設定預設模型：

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } },
}
```

## 供應商文件

- [OpenAI (API + Codex)](/zh-Hant/providers/openai)
- [Anthropic (API + Claude Code CLI)](/zh-Hant/providers/anthropic)
- [Qwen (OAuth)](/zh-Hant/providers/qwen)
- [OpenRouter](/zh-Hant/providers/openrouter)
- [Vercel AI Gateway](/zh-Hant/providers/vercel-ai-gateway)
- [Moonshot AI (Kimi + Kimi Coding)](/zh-Hant/providers/moonshot)
- [OpenCode Zen](/zh-Hant/providers/opencode)
- [Amazon Bedrock](/zh-Hant/bedrock)
- [Z.AI](/zh-Hant/providers/zai)
- [Xiaomi](/zh-Hant/providers/xiaomi)
- [GLM models](/zh-Hant/providers/glm)
- [MiniMax](/zh-Hant/providers/minimax)
- [Venice (Venice AI, 隱私優先)](/zh-Hant/providers/venice)
- [Ollama (本地模型)](/zh-Hant/providers/ollama)

## 語音轉錄供應商

- [Deepgram (音訊轉錄)](/zh-Hant/providers/deepgram)

## 社群工具

- [Claude Max API Proxy](/zh-Hant/providers/claude-max-api-proxy) - 使用 Claude Max/Pro 訂閱作為 OpenAI 相容的 API 端點

如需完整的供應商目錄（包含 xAI, Groq, Mistral 等）與進階設定，請參閱 [模型服務供應商概念](/zh-Hant/concepts/model-providers)。
