---
summary: "在 OpenClaw 中使用 Anthropic Claude API 金鑰或 Setup-token"
read_when:
  - 想要在 OpenClaw 中使用 Anthropic 模型時
  - 想要使用 Setup-token 而非 API 金鑰時
title: "Anthropic"
---

# Anthropic (Claude)

Anthropic 打造了 **Claude** 模型系列並透過 API 提供存取。
在 OpenClaw 中，您可以使用 API 金鑰或 **Setup-token** 進行認證。

## 選項 A：Anthropic API 金鑰

**適用於：** 標準 API 存取與用量計費。
請在 Anthropic Console 建立您的 API 金鑰。

### CLI 設定方式

```bash
openclaw onboard
# 選擇：Anthropic API key

# 或非互動模式
openclaw onboard --anthropic-api-key "$ANTHROPIC_API_KEY"
```

### 配置範例

```json5
{
  env: { ANTHROPIC_API_KEY: "sk-ant-..." },
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } }
}
```

## 提示快取 (Anthropic API)

OpenClaw 支援 Anthropic 的提示快取功能。此功能**僅適用於 API**；訂閱制認證不支援快取設定。

### 配置

使用模型配置中的 `cacheRetention` 參數：

| 值      | 快取時間   | 說明                                |
| ------- | ---------- | ----------------------------------- |
| `none`  | 不快取     | 停用提示快取                        |
| `short` | 5 分鐘     | API 金鑰認證的預設值                |
| `long`  | 1 小時     | 延長快取（需要 Beta 旗標）          |

```json5
{
  agents: {
    defaults: {
      models: {
        "anthropic/claude-opus-4-5": {
          params: { cacheRetention: "long" },
        },
      },
    },
  },
}
```

### 預設值

使用 Anthropic API 金鑰認證時，OpenClaw 會自動為所有 Anthropic 模型套用 `cacheRetention: "short"`（5 分鐘快取）。您可以在配置中明確設定 `cacheRetention` 來覆寫此設定。

### 舊版參數

舊版的 `cacheControlTtl` 參數仍然支援向後相容性：

- `"5m"` 對應 `short`
- `"1h"` 對應 `long`

建議您遷移至新的 `cacheRetention` 參數。

OpenClaw 包含針對 Anthropic API 請求的 `extended-cache-ttl-2025-04-11` Beta 旗標；若您有覆寫供應商標頭設定，請保留此旗標（請參閱 [/gateway/configuration](/gateway/configuration)）。

## 選項 B：Claude Setup-token

**適用於：** 使用您的 Claude 訂閱。

### 如何取得 Setup-token

Setup-tokens 是由 **Claude Code CLI** 產生的，而非 Anthropic Console。您可以在**任何機器**上執行此指令：

```bash
claude setup-token
```

將產生的 Token 貼入 OpenClaw（在嚮導中選擇：**Anthropic token (paste setup-token)**），或是直接在 Gateway 主機上執行：

```bash
openclaw models auth setup-token --provider anthropic
```

如果您是在不同機器上產生 Token，請使用貼上指令：

```bash
openclaw models auth paste-token --provider anthropic
```

### CLI 設定方式

```bash
# 在新手導覽過程中貼上 setup-token
openclaw onboard --auth-choice setup-token
```

### 配置範例

```json5
{
  agents: { defaults: { model: { primary: "anthropic/claude-opus-4-5" } } }
}
```

## 注意事項

- 使用 `claude setup-token` 產生 Token 並貼上，或在 Gateway 主機上執行 `openclaw models auth setup-token`。
- 若在使用 Claude 訂閱時看到「OAuth token refresh failed …」，請使用 Setup-token 重新認證。詳情參見 [/gateway/troubleshooting#oauth-token-refresh-failed-anthropic-claude-subscription](/gateway/troubleshooting#oauth-token-refresh-failed-anthropic-claude-subscription)。
- 認證細節與重複使用規則請參閱 [/concepts/oauth](/concepts/oauth)。

## 故障排除

**401 錯誤 / Token 突然失效**
- Claude 訂閱認證可能會過期或被撤銷。請重新執行 `claude setup-token` 並將其貼入 **Gateway 主機**。
- 如果 Claude CLI 登入是在不同機器上，請在 Gateway 主機上使用 `openclaw models auth paste-token --provider anthropic`。

**No API key found for provider "anthropic"**
- 認證是**以 Agent 為單位**的。新建立的 Agent 不會繼承主 Agent 的金鑰。
- 請為該 Agent 重新執行 `openboard`，或在 Gateway 主機上貼上 Setup-token / API 金鑰，然後使用 `openclaw models status` 驗證。

**No credentials found for profile `anthropic:default`**
- 執行 `openclaw models status` 查看目前哪個認證設定檔 (Auth Profile) 處於啟用狀態。
- 重新執行 `onboard`，或為該設定檔貼上 Setup-token / API 金鑰。

**No available auth profile (all in cooldown/unavailable)**
- 檢查 `openclaw models status --json` 中的 `auth.unusableProfiles`。
- 新增另一個 Anthropic 設定檔，或等待冷卻時間結束。

更多資訊：[/gateway/troubleshooting](/gateway/troubleshooting) 與 [/help/faq](/help/faq)。
