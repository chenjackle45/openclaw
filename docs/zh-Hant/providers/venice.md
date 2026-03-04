---
summary: "在 OpenClaw 中使用 Venice AI 隱私優先模型"
read_when:
  - You want privacy-focused inference in OpenClaw
  - You want Venice AI setup guidance
title: "Venice AI（Venice AI）"
---

# Venice AI（Venice 亮點）

**Venice** 是我們的亮點 Venice 設定，用於隱私優先推理，可選擇匿名存取專有模型。

Venice AI 提供隱私優先的 AI 推理，支援無審查模型，以及透過其匿名代理存取主要專有模型。所有推理預設都是隱私的 — 不訓練您的資料，無日誌記錄。

## 為什麼 Venice 在 OpenClaw

- **私人推理**用於開源模型（無日誌）。
- **無審查模型**當需要時。
- **匿名存取**專有模型（Opus/GPT/Gemini）當品質很重要時。
- OpenAI 相容 `/v1` 端點。

## 隱私模式

Venice 提供兩個隱私層級 — 理解這一點是選擇模型的關鍵：

| 模式     | 描述                                                                              | 模型                                        |
| -------- | --------------------------------------------------------------------------------- | ------------------------------------------- |
| **私人** | 完全隱私。提示 / 回應**永遠不被存儲或記錄**。暫時的。                             | Llama、Qwen、DeepSeek、Venice Uncensored 等 |
| **匿名** | 透過 Venice 代理，去除中繼資料。底層提供者（OpenAI、Anthropic）見到匿名化的請求。 | Claude、GPT、Gemini、Grok、Kimi、MiniMax    |

詳見文件頁面的完整內容...（篇幅限制，僅展示開頭結構）
