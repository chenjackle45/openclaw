---
summary: "在 OpenClaw 中使用 MiniMax M2.5"
read_when:
  - 你想在 OpenClaw 中使用 MiniMax 模型
  - 你需要 MiniMax 設定指南
title: "MiniMax"
---

# MiniMax

MiniMax 是一家建構 **M2/M2.5** 模型系列的 AI 公司。目前以程式碼為重點的版本是 **MiniMax M2.5**（2025 年 12 月 23 日），專為現實世界的複雜任務所建構。

來源：[MiniMax M2.5 release note](https://www.minimax.io/news/minimax-m25)

## 模型概覽（M2.5）

MiniMax 在 M2.5 中重點介紹以下改進：

- 更強的**多語言程式碼**（Rust、Java、Go、C++、Kotlin、Objective-C、TS/JS）。
- 更好的 **web/app 開發**和美觀輸出品質（包含原生行動端）。
- 改進的**複合指令**處理，用於辦公室風格工作流，建立在交錯 thinking 和整合限制執行之上。
- **更簡潔的回應**，token 用量更低，迭代循環更快。
- 更強的**工具/agent 框架**相容性和 context 管理（Claude Code、Droid/Factory AI、Cline、Kilo Code、Roo Code、BlackBox）。
- 更高品質的**對話和技術寫作**輸出。

## MiniMax M2.5 vs MiniMax M2.5 Highspeed

- **速度：** `MiniMax-M2.5-highspeed` 是 MiniMax 文件中的官方快速層。
- **成本：** MiniMax 定價列出相同的輸入成本和 highspeed 更高的輸出成本。
- **目前的模型 ID：** 使用 `MiniMax-M2.5` 或 `MiniMax-M2.5-highspeed`。

## 選擇設定方式

### MiniMax OAuth（Coding Plan）— 推薦

**最適合：** 透過 OAuth 使用 MiniMax Coding Plan 快速設定，不需要 API 金鑰。

啟用已附帶的 OAuth plugin 並進行認證：

```bash
openclaw plugins enable minimax-portal-auth  # skip if already loaded.
openclaw gateway restart  # restart if gateway is already running
openclaw onboard --auth-choice minimax-portal
```

系統將提示你選擇端點：

- **Global** - 國際使用者（`api.minimax.io`）
- **CN** - 中國使用者（`api.minimaxi.com`）

詳情請參閱 [MiniMax OAuth plugin README](https://github.com/openclaw/openclaw/tree/main/extensions/minimax-portal-auth)。

### MiniMax M2.5（API 金鑰）

**最適合：** 使用 Anthropic 相容 API 的託管 MiniMax。

透過 CLI 設定：

- 執行 `openclaw configure`
- 選擇 **Model/auth**
- 選擇 **MiniMax M2.5**

```json5
{
  env: { MINIMAX_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "minimax/MiniMax-M2.5" } } },
  models: {
    mode: "merge",
    providers: {
      minimax: {
        baseUrl: "https://api.minimax.io/anthropic",
        apiKey: "${MINIMAX_API_KEY}",
        api: "anthropic-messages",
        models: [
          {
            id: "MiniMax-M2.5",
            name: "MiniMax M2.5",
            reasoning: true,
            input: ["text"],
            cost: { input: 0.3, output: 1.2, cacheRead: 0.03, cacheWrite: 0.12 },
            contextWindow: 200000,
            maxTokens: 8192,
          },
          {
            id: "MiniMax-M2.5-highspeed",
            name: "MiniMax M2.5 Highspeed",
            reasoning: true,
            input: ["text"],
            cost: { input: 0.3, output: 1.2, cacheRead: 0.03, cacheWrite: 0.12 },
            contextWindow: 200000,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

### MiniMax M2.5 作為備用（範例）

**最適合：** 保持最強的最新世代模型為主要，備用至 MiniMax M2.5。
以下範例使用 Opus 作為具體的主要模型；請替換為你偏好的最新世代主要模型。

```json5
{
  env: { MINIMAX_API_KEY: "sk-..." },
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": { alias: "primary" },
        "minimax/MiniMax-M2.5": { alias: "minimax" },
      },
      model: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: ["minimax/MiniMax-M2.5"],
      },
    },
  },
}
```

### 可選：透過 LM Studio 本地執行（手動）

**最適合：** 使用 LM Studio 進行本地推論。
我們在強大硬體（例如桌機/伺服器）上使用 LM Studio 的本地伺服器，看到了 MiniMax M2.5 的優異效果。

透過 `openclaw.json` 手動設定：

```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/minimax-m2.5-gs32" },
      models: { "lmstudio/minimax-m2.5-gs32": { alias: "Minimax" } },
    },
  },
  models: {
    mode: "merge",
    providers: {
      lmstudio: {
        baseUrl: "http://127.0.0.1:1234/v1",
        apiKey: "lmstudio",
        api: "openai-responses",
        models: [
          {
            id: "minimax-m2.5-gs32",
            name: "MiniMax M2.5 GS32",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 196608,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
}
```

## 透過 `openclaw configure` 設定

使用互動式設定精靈無需編輯 JSON 即可設定 MiniMax：

1. 執行 `openclaw configure`。
2. 選擇 **Model/auth**。
3. 選擇 **MiniMax M2.5**。
4. 在提示時選擇你的預設模型。

## 設定選項

- `models.providers.minimax.baseUrl`：優先使用 `https://api.minimax.io/anthropic`（Anthropic 相容）；`https://api.minimax.io/v1` 可選用於 OpenAI 相容 payload。
- `models.providers.minimax.api`：優先使用 `anthropic-messages`；`openai-completions` 可選用於 OpenAI 相容 payload。
- `models.providers.minimax.apiKey`：MiniMax API 金鑰（`MINIMAX_API_KEY`）。
- `models.providers.minimax.models`：定義 `id`、`name`、`reasoning`、`contextWindow`、`maxTokens`、`cost`。
- `agents.defaults.models`：為你想在允許清單中的模型設定別名。
- `models.mode`：若你想在內建模型旁邊新增 MiniMax，請保持 `merge`。

## 注意事項

- 模型 ref 格式為 `minimax/<model>`。
- 推薦的模型 ID：`MiniMax-M2.5` 和 `MiniMax-M2.5-highspeed`。
- Coding Plan 用量 API：`https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains`（需要 coding plan 金鑰）。
- 若你需要精確的成本追蹤，請更新 `models.json` 中的定價值。
- MiniMax Coding Plan 推薦連結（9 折）：[https://platform.minimax.io/subscribe/coding-plan?code=DbXJTRClnb&source=link](https://platform.minimax.io/subscribe/coding-plan?code=DbXJTRClnb&source=link)
- 請參閱 [/concepts/model-providers](/zh-Hant/concepts/model-providers) 了解提供者規則。
- 使用 `openclaw models list` 和 `openclaw models set minimax/MiniMax-M2.5` 切換。

## 疑難排解

### "Unknown model: minimax/MiniMax-M2.5"

這通常表示 **MiniMax 提供者未設定**（無提供者條目，且未找到 MiniMax 認證設定檔/env 金鑰）。在撰寫本文時，**2026.1.12**（尚未發布）中有針對此偵測的修正。修正方式：

- 升級至 **2026.1.12**（或從原始碼 `main` 執行），然後重啟 gateway。
- 執行 `openclaw configure` 並選擇 **MiniMax M2.5**，或
- 手動新增 `models.providers.minimax` 區塊，或
- 設定 `MINIMAX_API_KEY`（或 MiniMax 認證設定檔），以便注入提供者。

確保模型 id **區分大小寫**：

- `minimax/MiniMax-M2.5`
- `minimax/MiniMax-M2.5-highspeed`

然後以以下命令重新確認：

```bash
openclaw models list
```
