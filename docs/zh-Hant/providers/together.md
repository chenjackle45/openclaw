---
summary: "Together AI 設定（認證 + 模型選擇）"
read_when:
  - You want to use Together AI with OpenClaw
  - You need the API key env var or CLI auth choice
title: "Together AI（Together AI）"
---

# Together AI

[Together AI](https://together.ai) 透過統一 API 提供存取主要開源模型，包括 Llama、DeepSeek、Kimi 和更多。

- 提供者：`together`
- 認證：`TOGETHER_API_KEY`
- API：OpenAI 相容

## 快速開始

1. 設定 API 鑰（建議：為 Gateway 儲存）：

```bash
openclaw onboard --auth-choice together-api-key
```

2. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "together/moonshotai/Kimi-K2.5" },
    },
  },
}
```

## 非互動範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice together-api-key \
  --together-api-key "$TOGETHER_API_KEY"
```

這將設定 `together/moonshotai/Kimi-K2.5` 作為預設模型。

## 環境註記

如果 Gateway 作為守護程式執行（launchd / systemd），確保 `TOGETHER_API_KEY`
對該程序可用（例如，在 `~/.openclaw/.env` 或透過
`env.shellEnv`）。

## 可用模型

Together AI 提供許多熱門開源模型的存取：

- **GLM 4.7 Fp8** - 具有 200K 內容視窗的預設模型
- **Llama 3.3 70B Instruct Turbo** - 快速、有效率的指令遵循
- **Llama 4 Scout** - 具有影像理解的視覺模型
- **Llama 4 Maverick** - 進階視覺和推理
- **DeepSeek V3.1** - 強大的編碼和推理模型
- **DeepSeek R1** - 進階推理模型
- **Kimi K2 Instruct** - 高性能模型，具有 262K 內容視窗

所有模型支援標準聊天完成並與 OpenAI API 相容。
