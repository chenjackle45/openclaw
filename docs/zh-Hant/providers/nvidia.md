---
summary: "在 OpenClaw 中使用 NVIDIA 的 OpenAI 相容 API"
read_when:
  - You want to use NVIDIA models in OpenClaw
  - You need NVIDIA_API_KEY setup
title: "NVIDIA"
---

# NVIDIA

NVIDIA 提供 OpenAI 相容 API 在 `https://integrate.api.nvidia.com/v1` 用於 Nemotron 和 NeMo 模型。使用來自 [NVIDIA NGC](https://catalog.ngc.nvidia.com/) 的 API 鑰進行認證。

## CLI 設定

一次匯出鑰，然後執行上線並設定 NVIDIA 模型：

```bash
export NVIDIA_API_KEY="nvapi-..."
openclaw onboard --auth-choice skip
openclaw models set nvidia/nvidia/llama-3.1-nemotron-70b-instruct
```

如果仍傳遞 `--token`，記住它會進入 shell 歷史和 `ps` 輸出；儘可能偏好環境變數。

## 設定片段

```json5
{
  env: { NVIDIA_API_KEY: "nvapi-..." },
  models: {
    providers: {
      nvidia: {
        baseUrl: "https://integrate.api.nvidia.com/v1",
        api: "openai-completions",
      },
    },
  },
  agents: {
    defaults: {
      model: { primary: "nvidia/nvidia/llama-3.1-nemotron-70b-instruct" },
    },
  },
}
```

## 模型 ID

- `nvidia/llama-3.1-nemotron-70b-instruct`（預設）
- `meta/llama-3.3-70b-instruct`
- `nvidia/mistral-nemo-minitron-8b-8k-instruct`

## 註記

- OpenAI 相容 `/v1` 端點；使用來自 NVIDIA NGC 的 API 鑰。
- 當設定 `NVIDIA_API_KEY` 時提供者自動啟用；使用靜態預設值（131,072 令牌內容視窗，4,096 最大令牌）。
