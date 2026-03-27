---
title: "Plugin SDK Overview（Plugin SDK 概述）"
sidebarTitle: "SDK 概述"
summary: "Import map, registration API reference, and SDK architecture（Import 對應表、註冊 API 參考與 SDK 架構）"
read_when:
  - 你需要知道應該從哪個 SDK subpath import
  - 你想參考 OpenClawPluginApi 上所有的註冊方法
  - 你正在查詢特定的 SDK 匯出
---

# Plugin SDK Overview

Plugin SDK 是外掛與核心之間的類型合約。本頁是以下內容的參考指南：**應該 import 什麼** 以及 **可以註冊什麼**。

<Tip>
  **在找實作指南？**
  - 第一次做外掛？從 [入門指南](/zh-Hant/plugins/building-plugins) 開始
  - Channel 外掛？參考 [Channel 外掛](/zh-Hant/plugins/sdk-channel-plugins)
  - Provider 外掛？參考 [Provider 外掛](/zh-Hant/plugins/sdk-provider-plugins)
</Tip>

## Import 慣例

一律從具體 subpath import：

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { defineChannelPluginEntry } from "openclaw/plugin-sdk/core";
```

每個 subpath 都是小型、自包含的模組。這樣可以保持啟動速度快，並防止循環依賴問題。

## Subpath 參考

最常見的 subpath，按用途分組。完整的 100+ subpath 清單在 `scripts/lib/plugin-sdk-entrypoints.json`。

### Plugin entry

| Subpath                   | 主要 Export                                                                                                                            |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `plugin-sdk/plugin-entry` | `definePluginEntry`                                                                                                                    |
| `plugin-sdk/core`         | `defineChannelPluginEntry`, `createChatChannelPlugin`, `createChannelPluginBase`, `defineSetupPluginEntry`, `buildChannelConfigSchema` |

<AccordionGroup>
  <Accordion title="Channel subpath">
    | Subpath | 主要 Export |
    | --- | --- |
    | `plugin-sdk/channel-setup` | `createOptionalChannelSetupSurface` |
    | `plugin-sdk/channel-pairing` | `createChannelPairingController` |
    | `plugin-sdk/channel-reply-pipeline` | `createChannelReplyPipeline` |
    | `plugin-sdk/channel-config-helpers` | `createHybridChannelConfigAdapter` |
    | `plugin-sdk/channel-config-schema` | Channel config schema 類型 |
    | `plugin-sdk/channel-policy` | `resolveChannelGroupRequireMention` |
    | `plugin-sdk/channel-lifecycle` | `createAccountStatusSink` |
    | `plugin-sdk/channel-inbound` | Debounce、mention matching、envelope 輔助函式 |
    | `plugin-sdk/channel-send-result` | Reply result 類型 |
    | `plugin-sdk/channel-actions` | `createMessageToolButtonsSchema`, `createMessageToolCardSchema` |
    | `plugin-sdk/channel-targets` | Target 解析／匹配輔助函式 |
    | `plugin-sdk/channel-contract` | Channel contract 類型 |
    | `plugin-sdk/channel-feedback` | Feedback／reaction 配線 |
  </Accordion>

  <Accordion title="Provider subpath">
    | Subpath | 主要 Export |
    | --- | --- |
    | `plugin-sdk/provider-auth` | `createProviderApiKeyAuthMethod`, `ensureApiKeyFromOptionEnvOrPrompt`, `upsertAuthProfile` |
    | `plugin-sdk/provider-models` | `normalizeModelCompat` |
    | `plugin-sdk/provider-catalog` | Catalog type 重新 export |
    | `plugin-sdk/provider-usage` | `fetchClaudeUsage` 及類似函式 |
    | `plugin-sdk/provider-stream` | Stream wrapper 類型 |
    | `plugin-sdk/provider-onboard` | Onboarding config patch 輔助函式 |
  </Accordion>

  <Accordion title="Auth and security subpath">
    | Subpath | 主要 Export |
    | --- | --- |
    | `plugin-sdk/command-auth` | `resolveControlCommandGate` |
    | `plugin-sdk/allow-from` | `formatAllowFromLowercase` |
    | `plugin-sdk/secret-input` | Secret input 解析輔助函式 |
    | `plugin-sdk/webhook-ingress` | Webhook request／target 輔助函式 |
  </Accordion>

  <Accordion title="Runtime and storage subpath">
    | Subpath | 主要 Export |
    | --- | --- |
    | `plugin-sdk/runtime-store` | `createPluginRuntimeStore` |
    | `plugin-sdk/config-runtime` | Config 載入／寫入輔助函式 |
    | `plugin-sdk/infra-runtime` | System event／heartbeat 輔助函式 |
    | `plugin-sdk/agent-runtime` | Agent 目錄／身分／工作區輔助函式 |
    | `plugin-sdk/directory-runtime` | Config 支持的 directory 查詢／去重 |
    | `plugin-sdk/keyed-async-queue` | `KeyedAsyncQueue` |
  </Accordion>

  <Accordion title="Capability and testing subpath">
    | Subpath | 主要 Export |
    | --- | --- |
    | `plugin-sdk/image-generation` | Image generation provider 類型 |
    | `plugin-sdk/media-understanding` | Media understanding provider 類型 |
    | `plugin-sdk/speech` | Speech provider 類型 |
    | `plugin-sdk/testing` | `installCommonResolveTargetErrorCases`, `shouldAckReaction` |
  </Accordion>
</AccordionGroup>

## 註冊 API

`register(api)` 回調函式收到 `OpenClawPluginApi` 物件，提供這些方法：

### 能力註冊

| 方法                                          | 註冊內容             |
| --------------------------------------------- | -------------------- |
| `api.registerProvider(...)`                   | 文字推理（LLM）      |
| `api.registerChannel(...)`                    | 傳訊頻道             |
| `api.registerSpeechProvider(...)`             | 文字轉語音／語音合成 |
| `api.registerMediaUnderstandingProvider(...)` | 圖片／音訊／影片分析 |
| `api.registerImageGenerationProvider(...)`    | 圖像生成             |
| `api.registerWebSearchProvider(...)`          | 網路搜尋             |

### 工具與命令

| 方法                            | 註冊內容                                   |
| ------------------------------- | ------------------------------------------ |
| `api.registerTool(tool, opts?)` | Agent 工具（必須或 `{ optional: true }` ） |
| `api.registerCommand(def)`      | 自訂命令（繞過 LLM）                       |

### 基礎設施

| 方法                                           | 註冊內容            |
| ---------------------------------------------- | ------------------- |
| `api.registerHook(events, handler, opts?)`     | Event hook          |
| `api.registerHttpRoute(params)`                | Gateway HTTP 端點   |
| `api.registerGatewayMethod(name, handler)`     | Gateway RPC 方法    |
| `api.registerCli(registrar, opts?)`            | CLI 子命令          |
| `api.registerService(service)`                 | 背景服務            |
| `api.registerInteractiveHandler(registration)` | Interactive handler |

### 獨佔插槽

| 方法                                       | 註冊內容                             |
| ------------------------------------------ | ------------------------------------ |
| `api.registerContextEngine(id, factory)`   | Context engine（一次只能有一個有效） |
| `api.registerMemoryPromptSection(builder)` | Memory prompt section builder        |

### 事件與生命週期

| 方法                                         | 功能                      |
| -------------------------------------------- | ------------------------- |
| `api.on(hookName, handler, opts?)`           | 類型化生命週期 hook       |
| `api.onConversationBindingResolved(handler)` | Conversation binding 回調 |

### API 物件欄位

| 欄位                     | 型別                      | 說明                                                |
| ------------------------ | ------------------------- | --------------------------------------------------- |
| `api.id`                 | `string`                  | 外掛 id                                             |
| `api.name`               | `string`                  | 顯示名稱                                            |
| `api.version`            | `string?`                 | 外掛版本（可選）                                    |
| `api.description`        | `string?`                 | 外掛說明（可選）                                    |
| `api.source`             | `string`                  | 外掛來源路徑                                        |
| `api.rootDir`            | `string?`                 | 外掛根目錄（可選）                                  |
| `api.config`             | `OpenClawConfig`          | 目前 config 快照                                    |
| `api.pluginConfig`       | `Record<string, unknown>` | 外掛特定 config，來自 `plugins.entries.<id>.config` |
| `api.runtime`            | `PluginRuntime`           | [Runtime 輔助函式](/zh-Hant/plugins/sdk-runtime)    |
| `api.logger`             | `PluginLogger`            | 範疇化 logger（`debug`, `info`, `warn`, `error`）   |
| `api.registrationMode`   | `PluginRegistrationMode`  | `"full"`, `"setup-only"`, 或 `"setup-runtime"`      |
| `api.resolvePath(input)` | `(string) => string`      | 解析相對於外掛根的路徑                              |

## 內部模組慣例

在你的外掛內，使用本地 barrel 檔案供內部 import：

```
my-plugin/
  api.ts            # 為外部消費者匯出的公開 export
  runtime-api.ts    # 僅限內部的 runtime export
  index.ts          # 外掛進入點
  setup-entry.ts    # 輕量級僅 setup 進入點（可選）
```

<Warning>
  絕對不要從生產代碼中透過 `openclaw/plugin-sdk/<your-plugin>` import 你自己的外掛。改為透過 `./api.ts` 或 `./runtime-api.ts` 路由內部 import。SDK 路徑僅作為外部合約。
</Warning>

## 相關

- [Entry Points](/zh-Hant/plugins/sdk-entrypoints) — `definePluginEntry` 和 `defineChannelPluginEntry` 選項
- [Runtime 輔助函式](/zh-Hant/plugins/sdk-runtime) — 完整 `api.runtime` namespace 參考
- [Setup 與 Config](/zh-Hant/plugins/sdk-setup) — 打包、manifests、config schemas
- [Testing](/zh-Hant/plugins/sdk-testing) — 測試工具與 lint 規則
- [SDK 遷移](/zh-Hant/plugins/sdk-migration) — 從舊有介面遷移
- [外掛內部](/zh-Hant/plugins/architecture) — 深度架構與能力模型
