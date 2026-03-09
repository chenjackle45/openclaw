---
summary: "使用 Kilo Gateway 的統一 API 在 OpenClaw 中存取多個模型"
read_when:
  - 你想要一個能存取多個 LLM 的單一 API 金鑰
  - 你想在 OpenClaw 中透過 Kilo Gateway 執行模型
---

# Kilo Gateway

Kilo Gateway 提供一個**統一 API**，將請求路由到許多模型，只需單一端點和 API 金鑰。它與 OpenAI 相容，因此大多數 OpenAI SDK 只需切換 base URL 即可使用。

## 取得 API 金鑰

1. 前往 [app.kilo.ai](https://app.kilo.ai)
2. 登入或建立帳戶
3. 導覽至 API Keys 並生成新金鑰

## CLI 設定

```bash
openclaw onboard --kilocode-api-key <key>
```

或設定環境變數：

```bash
export KILOCODE_API_KEY="<your-kilocode-api-key>" # pragma: allowlist secret
```

## 設定片段

```json5
{
  env: { KILOCODE_API_KEY: "<your-kilocode-api-key>" }, // pragma: allowlist secret
  agents: {
    defaults: {
      model: { primary: "kilocode/kilo/auto" },
    },
  },
}
```

## 預設模型

預設模型是 `kilocode/kilo/auto`，這是一個根據任務自動選擇最佳底層模型的智慧路由模型：

- 規劃、除錯和 orchestration 任務路由至 Claude Opus
- 程式碼撰寫和探索任務路由至 Claude Sonnet

## 可用模型

OpenClaw 在啟動時從 Kilo Gateway 動態探索可用模型。使用 `/models kilocode` 查看你帳戶可用的完整模型列表。

任何 gateway 上可用的模型都可以使用 `kilocode/` 前綴：

```
kilocode/kilo/auto              (default - smart routing)
kilocode/anthropic/claude-sonnet-4
kilocode/openai/gpt-5.2
kilocode/google/gemini-3-pro-preview
...and many more
```

## 注意事項

- 模型 ref 格式為 `kilocode/<model-id>`（例如，`kilocode/anthropic/claude-sonnet-4`）。
- 預設模型：`kilocode/kilo/auto`
- Base URL：`https://api.kilo.ai/api/gateway/`
- 更多模型/提供者選項，請參閱 [/concepts/model-providers](/zh-Hant/concepts/model-providers)。
- Kilo Gateway 在底層使用帶有你的 API 金鑰的 Bearer token。
