---
title: "Google (Gemini)（Google (Gemini)）"
summary: "Google Gemini 設定 (API 金鑰 + OAuth、影像生成、媒體理解、網頁搜尋)"
read_when:
  - You want to use Google Gemini models with OpenClaw
  - You need the API key or OAuth auth flow
---

# Google (Gemini)

Google 外掛提供透過 Google AI Studio 的 Gemini 模型存取，加上影像生成、媒體理解 (影像 / 音訊 / 影片) 和透過 Gemini Grounding 的網頁搜尋。

- 提供者：`google`
- 驗證：`GEMINI_API_KEY` 或 `GOOGLE_API_KEY`
- API：Google Gemini API
- 替代提供者：`google-gemini-cli` (OAuth)

## 快速開始

1. 設定 API 金鑰：

```bash
openclaw onboard --auth-choice google-api-key
```

2. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "google/gemini-3.1-pro-preview" },
    },
  },
}
```

## 非互動式範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice google-api-key \
  --gemini-api-key "$GEMINI_API_KEY"
```

## OAuth (Gemini CLI)

替代提供者 `google-gemini-cli` 使用 PKCE OAuth 而不是 API 金鑰。這是一個非官方整合；一些使用者報告帳戶限制。使用風險自負。

環境變數：

- `OPENCLAW_GEMINI_OAUTH_CLIENT_ID`
- `OPENCLAW_GEMINI_OAUTH_CLIENT_SECRET`

(或 `GEMINI_CLI_*` 變數。)

## 功能

| 功能                 | 支援             |
| -------------------- | ---------------- |
| 聊天完成             | 是               |
| 影像生成             | 是               |
| 影像理解             | 是               |
| 音訊轉錄             | 是               |
| 影片理解             | 是               |
| 網頁搜尋 (Grounding) | 是               |
| 思考 / 推理          | 是 (Gemini 3.1+) |

## 環境注意

如果閘道作為守護程式執行 (launchd/systemd)，請確保 `GEMINI_API_KEY` 對該程式可用（例如，在 `~/.openclaw/.env` 或透過 `env.shellEnv`）。
