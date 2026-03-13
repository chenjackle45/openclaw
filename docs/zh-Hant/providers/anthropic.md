---
summary: "透過 API 密鑰或 setup-token 在 OpenClaw 中使用 Anthropic Claude"
read_when:
  - 你想在 OpenClaw 中使用 Anthropic 模型
  - 你想使用 setup-token 而非 API 密鑰
title: "Anthropic"
---

# Anthropic (Claude)

Anthropic 建立了 **Claude** 模型系列，並透過 API 提供存取。在 OpenClaw 中，你可以使用 API 密鑰或 **setup-token** 進行驗證。

## 選項 A：Anthropic API 密鑰

**最適合：**標準 API 存取與按使用量計費。
在 Anthropic Console 中建立你的 API 密鑰。

### CLI 設定

\`\`\`bash
openclaw onboard

# 選擇：Anthropic API key

# 或非互動式

openclaw onboard --anthropic-api-key "$ANTHROPIC_API_KEY"
\`\`\`

### 設定片段

\`\`\`json5
{
env: { ANTHROPIC_API_KEY: "sk-ant-..." },
agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
\`\`\`

## 思考預設值（Claude 4.6）

- Anthropic Claude 4.6 模型在未設定明確思考級別時，在 OpenClaw 中預設使用 `adaptive` 思考。
- 你可以按訊息覆蓋設定（`/think:<level>`）或在模型參數中設定：
  `agents.defaults.models["anthropic/<model>"].params.thinking`。
- 相關 Anthropic 文件：
  - [Adaptive thinking](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)
  - [Extended thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)

## 快速模式（Anthropic API）

OpenClaw 的共用 `/fast` 切換也支援直接 Anthropic API 密鑰流量。

- `/fast on` 對應至 `service_tier: "auto"`
- `/fast off` 對應至 `service_tier: "standard_only"`
- 設定預設值：

\`\`\`json5
{
agents: {
defaults: {
models: {
"anthropic/claude-sonnet-4-5": {
params: { fastMode: true },
},
},
},
},
}
\`\`\`

重要限制：

- 這**僅限 API 密鑰**。Anthropic setup-token / OAuth 驗證不支援 OpenClaw 快速模式層級注入。
- OpenClaw 僅為直接 \`api.anthropic.com\` 請求注入 Anthropic 服務層級。如果你透過 proxy 或 gateway 路由 \`anthropic/\*\`，\`/fast\` 會保持 \`service_tier\` 不變。
- Anthropic 在響應中的 \`usage.service_tier\` 下報告有效層級。在沒有優先層容量的帳戶中，\`service_tier: "auto"\` 可能仍會解析為 \`standard\`。

## 提示快取（Anthropic API）

OpenClaw 支援 Anthropic 的提示快取功能。這**僅限 API**；訂閱驗證不支援快取設定。

### 設定

在你的模型設定中使用 \`cacheRetention\` 參數：

| 值        | 快取持續時間 | 描述                     |
| --------- | ------------ | ------------------------ |
| \`none\`  | 無快取       | 停用提示快取             |
| \`short\` | 5 分鐘       | API 金鑰驗證的預設值     |
| \`long\`  | 1 小時       | 擴展快取（需要測試旗標） |

\`\`\`json5
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
\`\`\`

### 預設值

使用 Anthropic API 密鑰驗證時，OpenClaw 會自動為所有 Anthropic 模型套用 \`cacheRetention: "short"\`（5 分鐘快取）。你可以在設定中明確設定 \`cacheRetention\` 來覆蓋此設定。

### 各 Agent 的 cacheRetention 覆蓋

使用模型級參數作為基準，然後透過 \`agents.list[].params\` 覆蓋特定 Agent。

\`\`\`json5
{
agents: {
defaults: {
model: { primary: "anthropic/claude-opus-4-6" },
models: {
"anthropic/claude-opus-4-6": {
params: { cacheRetention: "long" }, // 大多數 Agent 的基準
},
},
},
list: [
{ id: "research", default: true },
{ id: "alerts", params: { cacheRetention: "none" } }, // 僅此 Agent 的覆蓋
],
},
}
\`\`\`

快取相關參數的設定合併順序：

1. \`agents.defaults.models["provider/model"].params\`
2. \`agents.list[].params\`（匹配 \`id\`，按鍵覆蓋）

這讓一個 Agent 可以保持長期快取，而同一模型上的另一個 Agent 可以停用快取，以避免突發/低重用流量的寫入成本。

### Bedrock Claude 注意事項

- Bedrock 上的 Anthropic Claude 模型（\`amazon-bedrock/_anthropic.claude_\`）在設定時可接受 \`cacheRetention\` 傳遞。
- 非 Anthropic Bedrock 模型在執行時被強制設定為 \`cacheRetention: "none"\`。
- Anthropic API 密鑰智慧預設值也會在未設定明確值時為 Claude-on-Bedrock 模型參考注入 \`cacheRetention: "short"\`。

### 舊版參數

舊版 \`cacheControlTtl\` 參數仍受支援以保持向後相容性：

- \`"5m"\` 對應至 \`short\`
- \`"1h"\` 對應至 \`long\`

我們建議遷移至新的 \`cacheRetention\` 參數。

OpenClaw 為 Anthropic API 請求包含 \`extended-cache-ttl-2025-04-11\` 測試旗標；如果你覆蓋提供者標頭，請保持它（見 [/gateway/configuration](/zh-Hant/gateway/configuration)）。

## 1M 上下文視窗（Anthropic 測試版）

Anthropic 的 1M 上下文視窗處於測試版門控中。在 OpenClaw 中，為支援的 Opus/Sonnet 模型按模型啟用它，使用 \`params.context1m: true\`。

\`\`\`json5
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
\`\`\`

OpenClaw 將其對應至 Anthropic 請求上的 \`anthropic-beta: context-1m-2025-08-07\`。

這只在 \`params.context1m\` 對該模型明確設定為 \`true\` 時啟動。

要求：Anthropic 必須允許該憑證的長上下文使用（通常是 API 密鑰計費，或啟用額外使用的訂閱帳戶）。否則 Anthropic 會回傳：
\`HTTP 429: rate_limit_error: Extra usage is required for long context requests\`。

注意：Anthropic 目前在使用 OAuth/訂閱令牌（\`sk-ant-oat-_\`）時拒絕 \`context-1m-_\` 測試版請求。OpenClaw 會自動跳過 OAuth 驗證的 context1m 測試版標頭，並保持必要的 OAuth 測試版。

## 選項 B：Claude setup-token

**最適合：**使用你的 Claude 訂閱。

### 從何處取得 setup-token

Setup-token 由 **Claude Code CLI** 建立，而非 Anthropic Console。你可以在**任何機器**上執行此操作：

\`\`\`bash
claude setup-token
\`\`\`

將令牌貼到 OpenClaw 中（精靈：**Anthropic token (paste setup-token)**），或在 gateway 主機上執行：

\`\`\`bash
openclaw models auth setup-token --provider anthropic
\`\`\`

如果你在不同機器上產生令牌，請貼入它：

\`\`\`bash
openclaw models auth paste-token --provider anthropic
\`\`\`

### CLI 設定（setup-token）

\`\`\`bash

# 在上線期間貼上 setup-token

openclaw onboard --auth-choice setup-token
\`\`\`

### 設定片段（setup-token）

\`\`\`json5
{
agents: { defaults: { model: { primary: "anthropic/claude-opus-4-6" } } },
}
\`\`\`

## 注意事項

- 使用 \`claude setup-token\` 產生 setup-token 並貼入，或在 gateway 主機上執行 \`openclaw models auth setup-token\`。
- 如果你在 Claude 訂閱上看到「OAuth token refresh failed …」，請使用 setup-token 重新驗證。見 [/gateway/troubleshooting#oauth-token-refresh-failed-anthropic-claude-subscription](/zh-Hant/gateway/troubleshooting#oauth-token-refresh-failed-anthropic-claude-subscription)。
- 驗證詳情與重用規則在 [/concepts/oauth](/zh-Hant/concepts/oauth) 中。

## 疑難解除

**401 錯誤 / 令牌突然無效**

- Claude 訂閱驗證可能過期或被撤銷。重新執行 \`claude setup-token\`
  並將其貼到 **gateway 主機**。
- 如果 Claude CLI 登入在不同機器上，在 gateway 主機上使用
  \`openclaw models auth paste-token --provider anthropic\`。

**未找到提供者「anthropic」的 API 密鑰**

- 驗證是**按 Agent**。新 Agent 不會繼承主 Agent 的密鑰。
- 為該 Agent 重新執行上線，或在 gateway 主機上貼入 setup-token / API 密鑰，然後用 \`openclaw models status\` 驗證。

**找不到組態檔 \`anthropic:default\` 的憑證**

- 執行 \`openclaw models status\` 以查看哪個驗證組態檔處於作用中。
- 重新執行上線，或為該組態檔貼入 setup-token / API 密鑰。

**沒有可用的驗證組態檔（全部在冷卻/無法使用）**

- 檢查 \`openclaw models status --json\` 中的 \`auth.unusableProfiles\`。
- 新增另一個 Anthropic 組態檔或等待冷卻。

更多內容：[/gateway/troubleshooting](/zh-Hant/gateway/troubleshooting) 與 [/help/faq](/zh-Hant/help/faq)。
