---
summary: "在 OpenClaw 中透過 API 鑰或 Codex 訂閱使用 OpenAI"
read_when:
  - You want to use OpenAI models in OpenClaw
  - You want Codex subscription auth instead of API keys
title: "OpenAI（OpenAI）"
---

# OpenAI

OpenAI 為 GPT 模型提供開發者 API。Codex 支援**ChatGPT 登入**用於訂閱存取或**API 鑰**登入用於按使用量計費。Codex 雲端需要 ChatGPT 登入。OpenAI 明確支援訂閱 OAuth 使用在外部工具 / 工作流程（如 OpenClaw）。

## 選項 A：OpenAI API 鑰（OpenAI 平台）

**最佳用於：** 直接 API 存取和按使用量計費。
從 OpenAI 儀表板取得 API 鑰。

### CLI 設定

```bash
openclaw onboard --auth-choice openai-api-key
# 或非互動
openclaw onboard --openai-api-key "$OPENAI_API_KEY"
```

### 設定片段

```json5
{
  env: { OPENAI_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "openai/gpt-5.2" } } },
}
```

## 選項 B：OpenAI Code（Codex）訂閱

**最佳用於：** 使用 ChatGPT/Codex 訂閱存取而不是 API 鑰。
Codex 雲端需要 ChatGPT 登入，而 Codex CLI 支援 ChatGPT 或 API 鑰登入。

### CLI 設定（Codex OAuth）

```bash
# 在精靈中執行 Codex OAuth
openclaw onboard --auth-choice openai-codex

# 或直接執行 OAuth
openclaw models auth login --provider openai-codex
```

### 設定片段（Codex 訂閱）

```json5
{
  agents: { defaults: { model: { primary: "openai-codex/gpt-5.3-codex" } } },
}
```

## 註記

- 模型參考總是使用 `provider/model`（見 [/concepts/models](/zh-Hant/concepts/models)）。
- 認證詳情 + 重用規則在 [/concepts/oauth](/zh-Hant/concepts/oauth)。
