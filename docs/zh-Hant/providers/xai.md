---
summary: "在 OpenClaw 中使用 xAI Grok 模型"
read_when:
  - You want to use Grok models in OpenClaw
  - You are configuring xAI auth or model ids
title: "xAI"
---

# xAI

OpenClaw 附帶一個用於 Grok 模型的綑綁 `xai` 提供者外掛。

## 設定

1. 在 xAI 控制台中建立 API 金鑰。
2. 設定 `XAI_API_KEY`，或執行：

```bash
openclaw onboard --auth-choice xai-api-key
```

3. 選擇一個模型，例如：

```json5
{
  agents: { defaults: { model: { primary: "xai/grok-4" } } },
}
```

## 目前綑綁的模型目錄

OpenClaw 現在包含這些 xAI 模型族開箱即用：

- `grok-4`、`grok-4-0709`
- `grok-4-fast-reasoning`、`grok-4-fast-non-reasoning`
- `grok-4-1-fast-reasoning`、`grok-4-1-fast-non-reasoning`
- `grok-4.20-reasoning`、`grok-4.20-non-reasoning`
- `grok-code-fast-1`

外掛在遵循相同 API 形狀時也會向前解析新的 `grok-4*` 和 `grok-code-fast*` ID。

## 網頁搜尋

綑綁的 `grok` 網頁搜尋提供者也使用 `XAI_API_KEY`：

```bash
openclaw config set tools.web.search.provider grok
```

## 已知限制

- 驗證目前僅限 API 金鑰。OpenClaw 中還沒有 xAI OAuth / 裝置代碼流程。
- `grok-4.20-multi-agent-experimental-beta-0304` 在正常 xAI 提供者路徑上不支援，因為它需要與標準 OpenClaw xAI 傳輸不同的上游 API 表面。
- 本機 xAI 伺服器端工具（如 `x_search` 和 `code_execution`）在綑綁外掛中還不是第一級模型提供者功能。

## 筆記

- OpenClaw 在共享執行者路徑上自動應用 xAI 特定的工具架構和工具呼叫相容性修復。
- 如需較廣泛的提供者概述，請參閱 [模型提供者](/zh-Hant/providers/index)。
