---
title: "openai(OpenAI)"
summary: "在 OpenClaw 中使用 OpenAI API金鑰或 Codex 訂閱"
read_when:
  - 想要在 OpenClaw 中使用 OpenAI 模型時
  - 想要使用 Codex 訂閱認證而非 API 金鑰時
---

# OpenAI

OpenAI 為 GPT 模型提供了開發者 API。Codex 支援**ChatGPT 登入**（訂閱制存取）或 **API 金鑰**登入（用量計費存取）。Codex 雲端版需要 ChatGPT 登入。

## 選項 A：OpenAI API 金鑰 (OpenAI Platform)

**適用於：** 直接 API 存取與用量計費。
請從 OpenAI 控制台取得您的 API 金鑰。

### CLI 設定方式

```bash
openclaw onboard --auth-choice openai-api-key
# 或者非互動模式
openclaw onboard --openai-api-key "$OPENAI_API_KEY"
```

### 配置範例

```json5
{
  env: { OPENAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "openai/gpt-5.2" } } }
}
```

## 選項 B：OpenAI Code (Codex) 訂閱

**適用於：** 使用 ChatGPT/Codex 訂閱存取而非 API 金鑰。
Codex 雲端版需要 ChatGPT 登入，而 Codex CLI 則支援 ChatGPT 或 API 金鑰登入。

### CLI 設定方式

```bash
# 在嚮導中執行 Codex OAuth
openclaw onboard --auth-choice openai-codex

# 或直接執行 OAuth
openclaw models auth login --provider openai-codex
```

### 配置範例

```json5
{
  agents: { defaults: { model: { primary: "openai-codex/gpt-5.2" } } }
}
```

## 注意事項

- 模型引用始終使用 `provider/model` 格式（請參閱 [/concepts/models](/concepts/models)）。
- 認證細節與重複使用規則請參閱 [/concepts/oauth](/concepts/oauth)。
