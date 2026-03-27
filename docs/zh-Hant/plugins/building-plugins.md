---
title: "Building Plugins（建構外掛程式）"
sidebarTitle: "開始使用"
summary: "幾分鐘內建立您的第一個 OpenClaw 外掛程式"
read_when:
  - 想要建立新的 OpenClaw 外掛程式時
  - 需要外掛程式開發的快速入門時
  - 新增頻道、提供商、工具或其他功能至 OpenClaw 時
---

# 建構外掛程式

外掛程式擴展 OpenClaw 的新功能：頻道、模型提供商、語音、圖片生成、網路搜尋、代理程式工具或任何組合。

您不需要將外掛程式新增至 OpenClaw 儲存庫。發佈至 [ClawHub](/zh-Hant/tools/clawhub) 或 npm，使用者使用 `openclaw plugins install <package-name>` 進行安裝。OpenClaw 會先嘗試 ClawHub，然後自動回退至 npm。

## 先決條件

- Node >= 22 和套件管理員（npm 或 pnpm）
- 熟悉 TypeScript（ESM）
- 若是在儲存庫內的外掛程式：已複製儲存庫並執行過 `pnpm install`

## 什麼類型的外掛程式？

<CardGroup cols={3}>
  <Card title="頻道外掛程式" icon="messages-square" href="/zh-Hant/plugins/sdk-channel-plugins">
    將 OpenClaw 連接至訊息平台（Discord、IRC 等）
  </Card>
  <Card title="提供商外掛程式" icon="cpu" href="/zh-Hant/plugins/sdk-provider-plugins">
    新增模型提供商（LLM、proxy 或自訂端點）
  </Card>
  <Card title="工具 / 掛鉤外掛程式" icon="wrench">
    註冊代理程式工具、事件掛鉤或服務 — 繼續下面
  </Card>
</CardGroup>

## 快速入門：工具外掛程式

此逐步解說建立一個最小外掛程式，該外掛程式註冊代理程式工具。頻道和提供商外掛程式有上面連結的專用指南。

<Steps>
  <Step title="建立套件和清單">
    <CodeGroup>
    ```json package.json
    {
      "name": "@myorg/openclaw-my-plugin",
      "version": "1.0.0",
      "type": "module",
      "openclaw": {
        "extensions": ["./index.ts"]
      }
    }
    ```

    ```json openclaw.plugin.json
    {
      "id": "my-plugin",
      "name": "My Plugin",
      "description": "Adds a custom tool to OpenClaw",
      "configSchema": {
        "type": "object",
        "additionalProperties": false
      }
    }
    ```
    </CodeGroup>

    每個外掛程式都需要清單，即使沒有設定。關於完整結構描述，請參閱 [Manifest](/zh-Hant/plugins/manifest)。

  </Step>

  <Step title="撰寫進入點">

    ```typescript
    // index.ts
    import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
    import { Type } from "@sinclair/typebox";

    export default definePluginEntry({
      id: "my-plugin",
      name: "My Plugin",
      description: "Adds a custom tool to OpenClaw",
      register(api) {
        api.registerTool({
          name: "my_tool",
          description: "Do a thing",
          parameters: Type.Object({ input: Type.String() }),
          async execute(_id, params) {
            return { content: [{ type: "text", text: `Got: ${params.input}` }] };
          },
        });
      },
    });
    ```

    `definePluginEntry` 用於非頻道外掛程式。對於頻道，使用 `defineChannelPluginEntry` — 請參閱 [Channel Plugins](/zh-Hant/plugins/sdk-channel-plugins)。有關完整進入點選項，請參閱 [Entry Points](/zh-Hant/plugins/sdk-entrypoints)。

  </Step>

  <Step title="測試和發佈">

    **外部外掛程式：** 發佈至 [ClawHub](/zh-Hant/tools/clawhub) 或 npm，然後安裝：

    ```bash
    openclaw plugins install @myorg/openclaw-my-plugin
    ```

    OpenClaw 會先檢查 ClawHub，然後回退至 npm。

    **在儲存庫內的外掛程式：** 放在 `extensions/` 下 — 自動發現。

    ```bash
    pnpm test -- extensions/my-plugin/
    ```

  </Step>
</Steps>

## 外掛程式功能

單一外掛程式可透過 `api` 物件註冊任意數量的功能：

| 功能           | 註冊方法                                      | 詳細指南                                                                                |
| -------------- | --------------------------------------------- | --------------------------------------------------------------------------------------- |
| 文字推論 (LLM) | `api.registerProvider(...)`                   | [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins)                               |
| 頻道 / 訊息    | `api.registerChannel(...)`                    | [Channel Plugins](/zh-Hant/plugins/sdk-channel-plugins)                                 |
| 語音 (TTS/STT) | `api.registerSpeechProvider(...)`             | [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins#step-5-add-extra-capabilities) |
| 媒體理解       | `api.registerMediaUnderstandingProvider(...)` | [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins#step-5-add-extra-capabilities) |
| 圖片生成       | `api.registerImageGenerationProvider(...)`    | [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins#step-5-add-extra-capabilities) |
| 網路搜尋       | `api.registerWebSearchProvider(...)`          | [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins#step-5-add-extra-capabilities) |
| 代理程式工具   | `api.registerTool(...)`                       | 下方                                                                                    |
| 自訂指令       | `api.registerCommand(...)`                    | [Entry Points](/zh-Hant/plugins/sdk-entrypoints)                                        |
| 事件掛鉤       | `api.registerHook(...)`                       | [Entry Points](/zh-Hant/plugins/sdk-entrypoints)                                        |
| HTTP 路由      | `api.registerHttpRoute(...)`                  | [Internals](/zh-Hant/plugins/architecture#gateway-http-routes)                          |
| CLI 子命令     | `api.registerCli(...)`                        | [Entry Points](/zh-Hant/plugins/sdk-entrypoints)                                        |

有關完整註冊 API，請參閱 [SDK Overview](/zh-Hant/plugins/sdk-overview#registration-api)。

## 註冊代理程式工具

工具是 LLM 可以呼叫的具型別函式。它們可以是必需（始終可用）或選用（使用者選擇加入）：

```typescript
register(api) {
  // Required tool — always available
  api.registerTool({
    name: "my_tool",
    description: "Do a thing",
    parameters: Type.Object({ input: Type.String() }),
    async execute(_id, params) {
      return { content: [{ type: "text", text: params.input }] };
    },
  });

  // Optional tool — user must add to allowlist
  api.registerTool(
    {
      name: "workflow_tool",
      description: "Run a workflow",
      parameters: Type.Object({ pipeline: Type.String() }),
      async execute(_id, params) {
        return { content: [{ type: "text", text: params.pipeline }] };
      },
    },
    { optional: true },
  );
}
```

使用者在設定中啟用選用工具：

```json5
{
  tools: { allow: ["workflow_tool"] },
}
```

- 工具名稱不得與核心工具衝突（衝突會被跳過）
- 對於有副作用或額外二進制需求的工具，使用 `optional: true`
- 使用者可以透過將外掛程式 ID 新增至 `tools.allow` 來啟用外掛程式中的所有工具

## 匯入慣例

始終從專注的 `openclaw/plugin-sdk/<subpath>` 路徑匯入：

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";

// 錯誤：整體根目錄（已棄用，將被移除）
import { ... } from "openclaw/plugin-sdk";
```

有關完整 subpath 參考，請參閱 [SDK Overview](/zh-Hant/plugins/sdk-overview)。

在您的外掛程式內，針對內部匯入使用本地 barrel 檔案（`api.ts`、`runtime-api.ts`）— 永遠不要透過其 SDK 路徑匯入您自己的外掛程式。

## 提交前檢查清單

<Check>**package.json** 有正確的 `openclaw` 中繼資料</Check>
<Check>**openclaw.plugin.json** 清單存在且有效</Check>
<Check>進入點使用 `defineChannelPluginEntry` 或 `definePluginEntry`</Check>
<Check>所有匯入使用聚焦的 `plugin-sdk/<subpath>` 路徑</Check>
<Check>內部匯入使用本地模組，而非 SDK 自匯入</Check>
<Check>測試通過（`pnpm test -- extensions/my-plugin/`）</Check>
<Check>`pnpm check` 通過（在儲存庫內的外掛程式）</Check>

## 後續步驟

<CardGroup cols={2}>
  <Card title="頻道外掛程式" icon="messages-square" href="/zh-Hant/plugins/sdk-channel-plugins">
    建構訊息頻道外掛程式
  </Card>
  <Card title="提供商外掛程式" icon="cpu" href="/zh-Hant/plugins/sdk-provider-plugins">
    建構模型提供商外掛程式
  </Card>
  <Card title="SDK 概觀" icon="book-open" href="/zh-Hant/plugins/sdk-overview">
    匯入對映和註冊 API 參考
  </Card>
  <Card title="執行時幫手" icon="settings" href="/zh-Hant/plugins/sdk-runtime">
    TTS、搜尋、透過 api.runtime 的子代理程式
  </Card>
  <Card title="測試" icon="test-tubes" href="/zh-Hant/plugins/sdk-testing">
    測試工具和模式
  </Card>
  <Card title="外掛程式清單" icon="file-json" href="/zh-Hant/plugins/manifest">
    完整清單結構描述參考
  </Card>
</CardGroup>
