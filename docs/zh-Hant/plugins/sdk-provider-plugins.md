---
title: "Building Provider Plugins（建置 Provider 外掛）"
sidebarTitle: "Provider 外掛"
summary: "Step-by-step guide to building a model provider plugin for OpenClaw（為 OpenClaw 建置模型 provider 外掛的逐步指南）"
read_when:
  - 你正在建置新的模型 provider 外掛
  - 你想加入 OpenAI 相容代理或自訂 LLM 到 OpenClaw
  - 你需要理解 provider auth、catalogs 與 runtime hooks
---

# Building Provider Plugins

本指南通過構建 provider 外掛來為 OpenClaw 添加模型 provider（LLM）。完成後，你會得到一個具有模型目錄、API key auth 與動態模型解析的 provider。

<Info>
  如果你從未建置過任何 OpenClaw 外掛，請先閱讀 [入門指南](/zh-Hant/plugins/building-plugins)，以了解基本的套件結構與 manifest 設定。
</Info>

## 逐步指南

<Steps>
  <Step title="套件與 manifest">
    <CodeGroup>
    ```json package.json
    {
      "name": "@myorg/openclaw-acme-ai",
      "version": "1.0.0",
      "type": "module",
      "openclaw": {
        "extensions": ["./index.ts"],
        "providers": ["acme-ai"]
      }
    }
    ```

    ```json openclaw.plugin.json
    {
      "id": "acme-ai",
      "name": "Acme AI",
      "description": "Acme AI 模型 provider",
      "providers": ["acme-ai"],
      "providerAuthEnvVars": {
        "acme-ai": ["ACME_AI_API_KEY"]
      },
      "providerAuthChoices": [
        {
          "provider": "acme-ai",
          "method": "api-key",
          "choiceId": "acme-ai-api-key",
          "choiceLabel": "Acme AI API key",
          "groupId": "acme-ai",
          "groupLabel": "Acme AI",
          "cliFlag": "--acme-ai-api-key",
          "cliOption": "--acme-ai-api-key <key>",
          "cliDescription": "Acme AI API key"
        }
      ],
      "configSchema": {
        "type": "object",
        "additionalProperties": false
      }
    }
    ```
    </CodeGroup>

    Manifest 宣告 `providerAuthEnvVars`，使 OpenClaw 可以在不載入外掛 runtime 的情況下偵測認證。

  </Step>

  <Step title="註冊 provider">
    最小的 provider 需要 `id`、`label`、`auth` 與 `catalog`：

    ```typescript index.ts
    import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
    import { createProviderApiKeyAuthMethod } from "openclaw/plugin-sdk/provider-auth";

    export default definePluginEntry({
      id: "acme-ai",
      name: "Acme AI",
      description: "Acme AI 模型 provider",
      register(api) {
        api.registerProvider({
          id: "acme-ai",
          label: "Acme AI",
          docsPath: "/providers/acme-ai",
          envVars: ["ACME_AI_API_KEY"],

          auth: [
            createProviderApiKeyAuthMethod({
              providerId: "acme-ai",
              methodId: "api-key",
              label: "Acme AI API key",
              hint: "API key 來自你的 Acme AI 儀表板",
              optionKey: "acmeAiApiKey",
              flagName: "--acme-ai-api-key",
              envVar: "ACME_AI_API_KEY",
              promptMessage: "輸入你的 Acme AI API key",
              defaultModel: "acme-ai/acme-large",
            }),
          ],

          catalog: {
            order: "simple",
            run: async (ctx) => {
              const apiKey =
                ctx.resolveProviderApiKey("acme-ai").apiKey;
              if (!apiKey) return null;
              return {
                provider: {
                  baseUrl: "https://api.acme-ai.com/v1",
                  apiKey,
                  api: "openai-completions",
                  models: [
                    {
                      id: "acme-large",
                      name: "Acme Large",
                      reasoning: true,
                      input: ["text", "image"],
                      cost: { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
                      contextWindow: 200000,
                      maxTokens: 32768,
                    },
                    {
                      id: "acme-small",
                      name: "Acme Small",
                      reasoning: false,
                      input: ["text"],
                      cost: { input: 1, output: 5, cacheRead: 0.1, cacheWrite: 1.25 },
                      contextWindow: 128000,
                      maxTokens: 8192,
                    },
                  ],
                },
              };
            },
          },
        });
      },
    });
    ```

    這是一個可以運作的 provider。使用者現在可以執行 `openclaw onboard --acme-ai-api-key <key>` 並選擇 `acme-ai/acme-large` 作為他們的模型。

    對於只註冊一個文字 provider 搭配 API-key auth 與單一 catalog-based runtime 的捆綁 provider，優先使用較窄的 `defineSingleProviderPluginEntry(...)` 輔助函式：

    ```typescript
    import { defineSingleProviderPluginEntry } from "openclaw/plugin-sdk/provider-entry";

    export default defineSingleProviderPluginEntry({
      id: "acme-ai",
      name: "Acme AI",
      description: "Acme AI 模型 provider",
      provider: {
        label: "Acme AI",
        docsPath: "/providers/acme-ai",
        auth: [
          {
            methodId: "api-key",
            label: "Acme AI API key",
            hint: "API key 來自你的 Acme AI 儀表板",
            optionKey: "acmeAiApiKey",
            flagName: "--acme-ai-api-key",
            envVar: "ACME_AI_API_KEY",
            promptMessage: "輸入你的 Acme AI API key",
            defaultModel: "acme-ai/acme-large",
          },
        ],
        catalog: {
          buildProvider: () => ({
            api: "openai-completions",
            baseUrl: "https://api.acme-ai.com/v1",
            models: [{ id: "acme-large", name: "Acme Large" }],
          }),
        },
      },
    });
    ```

    如果 auth flow 還需要在 onboarding 期間修補 `models.providers.*`、aliases 與 agent 預設模型，使用來自 `openclaw/plugin-sdk/provider-onboard` 的預設輔助函式。最窄的輔助函式為 `createDefaultModelPresetAppliers(...)`、`createDefaultModelsPresetAppliers(...)` 與 `createModelCatalogPresetAppliers(...)`。

  </Step>

  <Step title="加入動態模型解析">
    如果你的 provider 接受任意模型 ID（如代理或路由），加入 `resolveDynamicModel`：

    ```typescript
    api.registerProvider({
      // ... 上面的 id、label、auth、catalog

      resolveDynamicModel: (ctx) => ({
        id: ctx.modelId,
        name: ctx.modelId,
        provider: "acme-ai",
        api: "openai-completions",
        baseUrl: "https://api.acme-ai.com/v1",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 8192,
      }),
    });
    ```

    如果解析需要網路呼叫，使用 `prepareDynamicModel` 進行非同步預熱 — `resolveDynamicModel` 會在它完成後再次執行。

  </Step>

  <Step title="加入 runtime hooks（視需要）">
    大多數 provider 只需要 `catalog` + `resolveDynamicModel`。根據 provider 的需求逐步加入 hooks。

    <Tabs>
      <Tab title="Token exchange">
        針對在每次推理呼叫之前需要 token exchange 的 provider：

        ```typescript
        prepareRuntimeAuth: async (ctx) => {
          const exchanged = await exchangeToken(ctx.apiKey);
          return {
            apiKey: exchanged.token,
            baseUrl: exchanged.baseUrl,
            expiresAt: exchanged.expiresAt,
          };
        },
        ```
      </Tab>
      <Tab title="自訂標頭">
        針對需要自訂請求標頭或請求內容修改的 provider：

        ```typescript
        // wrapStreamFn 從 ctx.streamFn 傳回派生的 StreamFn
        wrapStreamFn: (ctx) => {
          if (!ctx.streamFn) return undefined;
          const inner = ctx.streamFn;
          return async (params) => {
            params.headers = {
              ...params.headers,
              "X-Acme-Version": "2",
            };
            return inner(params);
          };
        },
        ```
      </Tab>
      <Tab title="使用情況與帳單">
        針對公開使用情況／帳單資料的 provider：

        ```typescript
        resolveUsageAuth: async (ctx) => {
          const auth = await ctx.resolveOAuthToken();
          return auth ? { token: auth.token } : null;
        },
        fetchUsageSnapshot: async (ctx) => {
          return await fetchAcmeUsage(ctx.token, ctx.timeoutMs);
        },
        ```
      </Tab>
    </Tabs>

    <Accordion title="所有可用的 provider hook">
      OpenClaw 按此順序呼叫 hooks。大多數 provider 只使用 2-3 個：

      | # | Hook | 使用時機 |
      | --- | --- | --- |
      | 1 | `catalog` | 模型目錄或基礎 URL 預設值 |
      | 2 | `resolveDynamicModel` | 接受任意上游模型 ID |
      | 3 | `prepareDynamicModel` | 解析前非同步中繼資料取得 |
      | 4 | `normalizeResolvedModel` | 執行器前的傳輸重寫 |
      | 5 | `capabilities` | Transcript／工具設定中繼資料（資料，非可呼叫） |
      | 6 | `prepareExtraParams` | 預設請求參數 |
      | 7 | `wrapStreamFn` | 自訂標頭／請求內容包裝器 |
      | 8 | `formatApiKey` | 自訂 runtime token 形狀 |
      | 9 | `refreshOAuth` | 自訂 OAuth 重新整理 |
      | 10 | `buildAuthDoctorHint` | Auth 修復指導 |
      | 11 | `isCacheTtlEligible` | Prompt cache TTL 控制 |
      | 12 | `buildMissingAuthMessage` | 自訂 missing-auth 提示 |
      | 13 | `suppressBuiltInModel` | 隱藏過時上游列 |
      | 14 | `augmentModelCatalog` | 合成前向相容列 |
      | 15 | `isBinaryThinking` | Binary thinking 開/關 |
      | 16 | `supportsXHighThinking` | `xhigh` reasoning 支持 |
      | 17 | `resolveDefaultThinkingLevel` | 預設 `/think` 策略 |
      | 18 | `isModernModelRef` | Live／smoke 模型匹配 |
      | 19 | `prepareRuntimeAuth` | 推理前的 token exchange |
      | 20 | `resolveUsageAuth` | 自訂使用情況認證解析 |
      | 21 | `fetchUsageSnapshot` | 自訂使用情況端點 |
      | 22 | `onModelSelected` | 後選擇回調（例如遙測） |

      如需詳細說明與真實範例，參考 [內部：Provider Runtime Hooks](/zh-Hant/plugins/architecture#provider-runtime-hooks)。
    </Accordion>

  </Step>

  <Step title="加入額外能力（可選）">
    Provider 外掛可以與文字推理一併註冊語音、media understanding、影像生成與網路搜尋：

    ```typescript
    register(api) {
      api.registerProvider({ id: "acme-ai", /* ... */ });

      api.registerSpeechProvider({
        id: "acme-ai",
        label: "Acme Speech",
        isConfigured: ({ config }) => Boolean(config.messages?.tts),
        synthesize: async (req) => ({
          audioBuffer: Buffer.from(/* PCM 資料 */),
          outputFormat: "mp3",
          fileExtension: ".mp3",
          voiceCompatible: false,
        }),
      });

      api.registerMediaUnderstandingProvider({
        id: "acme-ai",
        capabilities: ["image", "audio"],
        describeImage: async (req) => ({ text: "一張照片..." }),
        transcribeAudio: async (req) => ({ text: "Transcript..." }),
      });

      api.registerImageGenerationProvider({
        id: "acme-ai",
        label: "Acme Images",
        generate: async (req) => ({ /* 圖像結果 */ }),
      });
    }
    ```

    OpenClaw 將此分類為 **hybrid-capability** 外掛。這是公司外掛的推薦模式（每家供應商一個外掛）。參考 [內部：能力所有權](/zh-Hant/plugins/architecture#capability-ownership-model)。

  </Step>

  <Step title="測試">
    ```typescript src/provider.test.ts
    import { describe, it, expect } from "vitest";
    // 從 index.ts 或專用檔案匯出你的 provider config 物件
    import { acmeProvider } from "./provider.js";

    describe("acme-ai provider", () => {
      it("resolves dynamic models", () => {
        const model = acmeProvider.resolveDynamicModel!({
          modelId: "acme-beta-v3",
        } as any);
        expect(model.id).toBe("acme-beta-v3");
        expect(model.provider).toBe("acme-ai");
      });

      it("returns catalog when key is available", async () => {
        const result = await acmeProvider.catalog!.run({
          resolveProviderApiKey: () => ({ apiKey: "test-key" }),
        } as any);
        expect(result?.provider?.models).toHaveLength(2);
      });

      it("returns null catalog when no key", async () => {
        const result = await acmeProvider.catalog!.run({
          resolveProviderApiKey: () => ({ apiKey: undefined }),
        } as any);
        expect(result).toBeNull();
      });
    });
    ```

  </Step>
</Steps>

## 檔案結構

```
extensions/acme-ai/
├── package.json              # openclaw.providers 中繼資料
├── openclaw.plugin.json      # Manifest 搭配 providerAuthEnvVars
├── index.ts                  # definePluginEntry + registerProvider
└── src/
    ├── provider.test.ts      # 測試
    └── usage.ts              # 使用情況端點（可選）
```

## Catalog order 參考

`catalog.order` 控制你的 catalog 何時與內建 provider 合併：

| Order     | 何時       | 使用情況                           |
| --------- | ---------- | ---------------------------------- |
| `simple`  | 第一遍     | 純 API-key provider                |
| `profile` | 簡單後     | Gated 於 auth profiles 的 provider |
| `paired`  | Profile 後 | 合成多個相關項目                   |
| `late`    | 最後一遍   | 覆蓋現有 provider（碰撞時勝出）    |

## 後續步驟

- [Channel 外掛](/zh-Hant/plugins/sdk-channel-plugins) — 如果外掛也提供 channel
- [SDK Runtime](/zh-Hant/plugins/sdk-runtime) — `api.runtime` 輔助函式（TTS、搜尋、subagent）
- [SDK 概述](/zh-Hant/plugins/sdk-overview) — 完整 subpath import 參考
- [外掛內部](/zh-Hant/plugins/architecture#provider-runtime-hooks) — hook 詳細說明與捆綁範例
