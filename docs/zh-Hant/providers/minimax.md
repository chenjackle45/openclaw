---
title: "minimax(MiniMax)"
summary: "在 OpenClaw 中使用 MiniMax M2.1"
read_when:
  - 想要在 OpenClaw 中使用 MiniMax 模型時
  - 需要 MiniMax 設定指南時
---

# MiniMax

MiniMax 是一間打造 **M2/M2.1** 模型系列的 AI 公司。目前針對編碼優化的版本是 **MiniMax M2.1**（2025 年 12 月 23 日發佈），專為真實世界的複雜任務而建置。

來源：[MiniMax M2.1 發佈說明](https://www.minimax.io/news/minimax-m21)

## 模型概覽 (M2.1)

MiniMax 強調 M2.1 的以下改進：

- 更強的 **多語言編碼能力** (Rust, Java, Go, C++, Kotlin, Objective-C, TS/JS)。
- 更好的 **Web/App 開發** 與美學輸出品質（包含原生行動端）。
- 改進針對辦公室風格工作流程的 **複合指令** 處理能力，建立在交錯思考與整合約束執行之上。
- **更簡潔的回覆**，具備更低的 Token 使用量與更快的迭代週期。
- 更強的 **工具/Agent 框架** 相容性與上下文管理 (Claude Code, Droid/Factory AI, Cline, Kilo Code, Roo Code, BlackBox)。
- 更高品質的 **對話與技術寫作** 輸出。

## MiniMax M2.1 vs MiniMax M2.1 Lightning

- **速度：** Lightning 是 MiniMax 定價文件中的「快速」變體。
- **成本：** 定價顯示輸入成本相同，但 Lightning 的輸出成本較高。
- **Coding Plan路由：** Lightning 後端無法直接在 MiniMax Coding Plan 中使用。MiniMax 會自動將大多數請求路由至 Lightning，但在流量尖峰時會回退至正規 M2.1 後端。

## 選擇設定方式

### MiniMax M2.1 — 推薦

**適用於：** 使用 Anthropic 相容 API 的託管 MiniMax 服務。

透過 CLI 配置：
- 執行 `openclaw configure`
- 選擇 **Model/auth**
- 選擇 **MiniMax M2.1**

```json5
{
  env: { MINIMAX_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "minimax/MiniMax-M2.1" } } },
  models: {
    mode: "merge",
    providers: {
      minimax: {
        baseUrl: "https://api.minimax.io/anthropic",
        apiKey: "${MINIMAX_API_KEY}",
        api: "anthropic-messages",
        models: [
          {
            id: "MiniMax-M2.1",
            name: "MiniMax M2.1",
            reasoning: false,
            input: ["text"],
            cost: { input: 15, output: 60, cacheRead: 2, cacheWrite: 10 },
            contextWindow: 200000,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

### MiniMax M2.1 作為備援（Opus 為主）

**適用於：** 保持 Opus 4.5 為主要模型，故障時切換至 MiniMax M2.1。

```json5
{
  env: { MINIMAX_API_KEY: "sk-..." },
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-5": { alias: "opus" },
        "minimax/MiniMax-M2.1": { alias: "minimax" }
      },
      model: {
        primary: "anthropic/claude-opus-4-5",
        fallbacks: ["minimax/MiniMax-M2.1"]
      }
    }
  }
}
```

### 選用：透過 LM Studio 本地運行 (手動)

**適用於：** 使用 LM Studio 進行本地推論。
我們在強大的硬體（如桌機/伺服器）上使用 LM Studio 本地伺服器運行 MiniMax M2.1 時看到了不錯的結果。

透過 `openclaw.json` 手動配置：

```json5
{
  agents: {
    defaults: {
      model: { primary: "lmstudio/minimax-m2.1-gs32" },
      models: { "lmstudio/minimax-m2.1-gs32": { alias: "Minimax" } }
    }
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
            id: "minimax-m2.1-gs32",
            name: "MiniMax M2.1 GS32",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 196608,
            maxTokens: 8192
          }
        ]
      }
    }
  }
}
```

## 透過 `openclaw configure` 配置

使用互動式配置嚮導來設定 MiniMax，無需編輯 JSON：

1) 執行 `openclaw configure`。
2) 選擇 **Model/auth**。
3) 選擇 **MiniMax M2.1**。
4) 提示時選擇您的預設模型。

## 配置選項

- `models.providers.minimax.baseUrl`: 建議使用 `https://api.minimax.io/anthropic` (Anthropic 相容)；`https://api.minimax.io/v1` 為選用（OpenAI 相容負載）。
- `models.providers.minimax.api`: 建議使用 `anthropic-messages`；`openai-completions` 為選用（OpenAI 相容負載）。
- `models.providers.minimax.apiKey`: MiniMax API 金鑰 (`MINIMAX_API_KEY`)。
- `models.providers.minimax.models`: 定義 `id`, `name`, `reasoning`, `contextWindow`, `maxTokens`, `cost`。
- `agents.defaults.models`: 為您想要列入允許清單的模型設定別名。
- `models.mode`: 若想將 MiniMax 與內建模型並存，請保留 `merge`。

## 注意事項

- 模型引用格式為 `minimax/<model>`。
- Coding Plan 使用量 API：`https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains`（需要 Coding Plan 金鑰）。
- 若需精確追蹤成本，請更新 `models.json` 中的價格數值。
- MiniMax Coding Plan 推薦連結（9折優惠）：https://platform.minimax.io/subscribe/coding-plan?code=DbXJTRClnb&source=link
- 供應商規則請參閱 [/concepts/model-providers](/concepts/model-providers)。
- 使用 `openclaw models list` 與 `openclaw models set minimax/MiniMax-M2.1` 進行切換。

## 故障排除

### “Unknown model: minimax/MiniMax-M2.1”

這通常表示 **MiniMax 供應商未配置**（無供應商項目且未找到 MiniMax 認證設定檔/環境變數金鑰）。此偵測問題的修正包含在 **2026.1.12** 版本（撰寫本文時尚未發佈）。修正方法：
- 升級至 **2026.1.12**（或從源碼 `main` 運行），然後重啟 Gateway。
- 執行 `openclaw configure` 並選擇 **MiniMax M2.1**，或
- 手動新增 `models.providers.minimax`區塊，或
- 設定 `MINIMAX_API_KEY`（或 MiniMax 認證設定檔），以便注入該供應商。

請確保模型 ID 是**區分大小寫**的：
- `minimax/MiniMax-M2.1`
- `minimax/MiniMax-M2.1-lightning`

然後再次檢查：
```bash
openclaw models list
```
