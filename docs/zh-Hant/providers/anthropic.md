---
summary: "在 OpenClaw 中透過 API 鑰或 setup-token 使用 Anthropic Claude"
read_when:
  - You want to use Anthropic models in OpenClaw
  - You want setup-token instead of API keys
title: "Anthropic（Anthropic）"
---

# Anthropic（Claude）

Anthropic 建置 **Claude** 模型族，並透過 API 提供存取。
在 OpenClaw 中，可以使用 API 鑰或**setup-token** 認證。

## 選項 A：Anthropic API 鑰

**最佳用於**：標準 API 存取及按使用量計費。
在 Anthropic Console 建立 API 鑰。

### CLI 設定

```bash
openclaw onboard
# 選擇：Anthropic API 鑰

# 或非互動
openclaw onboard --anthropic-api-key "$ANTHROPIC_API_KEY"
```

### 設定片段

```json5
{
  env: { ANTHROPIC_API_KEY: "sk-ant-..." },
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

## Thinking 預設值（Claude 4.6）

- Anthropic Claude 4.6 模型在 OpenClaw 中當未設定明確的 thinking 層級時，預設為 `adaptive` thinking。
- 可以按訊息覆蓋（`/think:<level>`）或在模型參數：
  `agents.defaults.models["anthropic/<model>"].params.thinking`。
- 相關 Anthropic 文件：
  - [Adaptive thinking](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)
  - [Extended thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)

## 提示快取（Anthropic API）

OpenClaw 支援 Anthropic 提示快取功能。這是 **API 限定**；訂閱認證不遵守快取設定。

### 設定

在模型設定中使用 `cacheRetention` 參數：

| 值      | 快取持續時間 | 描述                       |
| ------- | ------------ | -------------------------- |
| `none`  | 無快取       | 停用提示快取               |
| `short` | 5 分鐘       | API 鑰認證的預設值         |
| `long`  | 1 小時       | 擴展快取（需要 beta 標誌） |

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: { cacheRetention: "long" },
        },
      },
    },
  },
}
```

### 預設值

使用 Anthropic API 鑰認證時，OpenClaw 自動為所有 Anthropic 模型套用 `cacheRetention: "short"`（5 分鐘快取）。可以透過在設定中明確設定 `cacheRetention` 來覆蓋此項。

### 按代理 cacheRetention 覆蓋

使用模型層級參數作為基線，然後透過 `agents.list[].params` 覆蓋特定代理。

```json5
{
  agents: {
    defaults: {
      model: { primary: "anthropic/claude-opus-4-6" },
      models: {
        "anthropic/claude-opus-4-6": {
          params: { cacheRetention: "long" }, // 大多數代理的基線
        },
      },
    },
    list: [
      { id: "research", default: true },
      { id: "alerts", params: { cacheRetention: "none" } }, // 僅覆蓋此代理
    ],
  },
}
```

快取相關參數的設定合併順序：

1. `agents.defaults.models["provider/model"].params`
2. `agents.list[].params`（匹配 `id`，按鍵覆蓋）

這讓一個代理保持長期快取，同時同一模型上的另一個代理停用快取以避免突發／低重用流量的寫入成本。

### Bedrock Claude 註記

- Anthropic Claude 模型在 Bedrock（`amazon-bedrock/*anthropic.claude*`）在設定時接受 `cacheRetention` pass-through。
- 非 Anthropic Bedrock 模型在執行時被強制設定為 `cacheRetention: "none"`。
- Anthropic API 鑰智慧預設值也在未設定明確值時為 Claude-on-Bedrock 模型引用設置 `cacheRetention: "short"`。

### 舊版參數

舊版 `cacheControlTtl` 參數仍支援向後相容：

- `"5m"` 映射至 `short`
- `"1h"` 映射至 `long`

建議遷移至新 `cacheRetention` 參數。

OpenClaw 包含 Anthropic API 請求的 `extended-cache-ttl-2025-04-11` beta 標誌；如果覆蓋提供者標題，請保持它（見 [/gateway/configuration](/zh-Hant/gateway/configuration)）。

## 1M 內容視窗（Anthropic beta）

Anthropic 的 1M 內容視窗是 beta 限制的。在 OpenClaw 中，使用 `params.context1m: true` 為支援的 Opus/Sonnet 模型逐個啟用。

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-6": {
          params: { context1m: true },
        },
      },
    },
  },
}
```

OpenClaw 將此映射到 Anthropic 請求上的 `anthropic-beta: context-1m-2025-08-07`。

這只在 `params.context1m` 為該模型明確設定為 `true` 時啟用。

要求：Anthropic 必須允許該認證上的長內容使用
（通常為 API 鑰計費，或訂閱帳戶啟用額外使用）。否則 Anthropic 回傳：
`HTTP 429: rate_limit_error: Extra usage is required for long context requests`。

註記：Anthropic 目前在使用 OAuth/訂閱令牌（`sk-ant-oat-*`）時拒絕 `context-1m-*` beta 請求。OpenClaw 自動為 OAuth 認證跳過 context1m beta 標題並保持必要的 OAuth beta。

## 選項 B：Claude setup-token

**最佳用於**：使用 Claude 訂閱。

### 何處取得 setup-token

Setup-token 由 **Claude Code CLI** 建立，不是 Anthropic Console。可以在**任何機器**上執行：

```bash
claude setup-token
```

將令牌貼到 OpenClaw（精靈：**Anthropic token (paste setup-token)**），或在 gateway 主機上執行：

```bash
openclaw models auth setup-token --provider anthropic
```

如在不同機器生成令牌，貼它：

```bash
openclaw models auth paste-token --provider anthropic
```

### CLI 設定（setup-token）

```bash
# 在上線期間貼 setup-token
openclaw onboard --auth-choice setup-token
```

### 設定片段（setup-token）

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
```

## 註記

- 用 `claude setup-token` 生成 setup-token 並貼它，或在 gateway 主機上執行 `openclaw models auth setup-token`。
- 若看到 Claude 訂閱上的「OAuth token refresh failed …」，使用 setup-token 重新認證。見 [/gateway/troubleshooting#oauth-token-refresh-failed-anthropic-claude-subscription](/zh-Hant/gateway/troubleshooting#oauth-token-refresh-failed-anthropic-claude-subscription)。
- 認證詳情 + 重用規則在 [/concepts/oauth](/zh-Hant/concepts/oauth)。

## 疑難排解

**401 錯誤 / 令牌突然失效**

- Claude 訂閱認證可過期或被撤銷。重新執行 `claude setup-token`
  並貼它到 **gateway 主機**。
- 如 Claude CLI 登入在不同機器，使用
  `openclaw models auth paste-token --provider anthropic` 在 gateway 主機。

**未找到提供者「anthropic」的 API 鑰**

- 認證是**每個代理**。新代理不繼承主代理的鑰。
- 重新執行該代理的上線，或貼 setup-token / API 鑰在
  gateway 主機，然後用 `openclaw models status` 驗證。

**未找到設定檔 `anthropic:default` 的認證**

- 執行 `openclaw models status` 看啟用哪個認證設定檔。
- 重新執行上線，或為該設定檔貼 setup-token / API 鑰。

**沒有可用認證設定檔（全在冷卻 / 不可用）**

- 檢查 `openclaw models status --json` 用於 `auth.unusableProfiles`。
- 新增另一 Anthropic 設定檔或等待冷卻。

更多：[/gateway/troubleshooting](/zh-Hant/gateway/troubleshooting) 及 [/help/faq](/zh-Hant/help/faq)。
