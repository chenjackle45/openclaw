---
title: "Volcengine (Doubao)（Volcengine (Doubao)）"
summary: "Volcano Engine 設定 (Doubao 模型、通用 + 編碼端點)"
read_when:
  - You want to use Volcano Engine or Doubao models with OpenClaw
  - You need the Volcengine API key setup
---

# Volcengine (Doubao)

Volcengine 提供者可存取 Doubao 模型和託管在 Volcano Engine 上的第三方模型，具有用於通用和編碼工作負載的單獨端點。

- 提供者：`volcengine`（通用）+ `volcengine-plan`（編碼）
- 驗證：`VOLCANO_ENGINE_API_KEY`
- API：OpenAI 相容

## 快速開始

1. 設定 API 金鑰：

```bash
openclaw onboard --auth-choice volcengine-api-key
```

2. 設定預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "volcengine-plan/ark-code-latest" },
    },
  },
}
```

## 非互動式範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice volcengine-api-key \
  --volcengine-api-key "$VOLCANO_ENGINE_API_KEY"
```

## 提供者和端點

| 提供者            | 端點                                      | 使用案例 |
| ----------------- | ----------------------------------------- | -------- |
| `volcengine`      | `ark.cn-beijing.volces.com/api/v3`        | 通用模型 |
| `volcengine-plan` | `ark.cn-beijing.volces.com/api/coding/v3` | 編碼模型 |

兩個提供者都從單一 API 金鑰設定。設定會自動註冊兩者。

## 可用的模型

- **doubao-seed-1-8** - Doubao Seed 1.8（通用、預設）
- **doubao-seed-code-preview** - Doubao 編碼模型
- **ark-code-latest** - 編碼計畫預設
- **Kimi K2.5** - 透過 Volcano Engine 的 Moonshot AI
- **GLM-4.7** - 透過 Volcano Engine 的 GLM
- **DeepSeek V3.2** - 透過 Volcano Engine 的 DeepSeek

大多數模型支援文字 + 影像輸入。上下文視窗範圍從 128K 到 256K 權杖。

## 環境注意
