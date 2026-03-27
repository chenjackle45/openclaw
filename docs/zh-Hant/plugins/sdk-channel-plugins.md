---
title: "Building Channel Plugins（建置 Channel 外掛）"
sidebarTitle: "Channel 外掛"
summary: "Step-by-step guide to building a messaging channel plugin for OpenClaw（為 OpenClaw 建置傳訊頻道外掛的逐步指南）"
read_when:
  - 你正在建置新的傳訊頻道外掛
  - 你想連接 OpenClaw 到傳訊平台
  - 你需要理解 ChannelPlugin adapter 介面
---

# Building Channel Plugins

本指南通過構建 channel 外掛來連接 OpenClaw 與傳訊平台。完成後，你會得到一個具有 DM 安全性、配對、回覆執行緒與出站傳訊的運作中頻道。

<Info>
  如果你從未建置過任何 OpenClaw 外掛，請先閱讀 [入門指南](/zh-Hant/plugins/building-plugins)，以了解基本的套件結構與 manifest 設定。
</Info>

## Channel 外掛如何運作

Channel 外掛不需要自己的 send／edit／react 工具。OpenClaw 在核心中保留一個共享 `message` 工具。你的外掛擁有：

- **Config** — account 解析與 setup 精靈
- **Security** — DM 策略與 allowlists
- **Pairing** — DM 批准 flow
- **Outbound** — 傳送文字、media 與 polls 到平台
- **Threading** — 回覆如何執行線

核心擁有共享 message 工具、prompt 配線、工作階段簿記與分派。

## 逐步指南

<Steps>
  <Step title="套件與 manifest">
    建立標準外掛檔案。`package.json` 中的 `channel` 欄位是使其成為 channel 外掛的原因：

    <CodeGroup>
    ```json package.json
    {
      "name": "@myorg/openclaw-acme-chat",
      "version": "1.0.0",
      "type": "module",
      "openclaw": {
        "extensions": ["./index.ts"],
        "setupEntry": "./setup-entry.ts",
        "channel": {
          "id": "acme-chat",
          "label": "Acme Chat",
          "blurb": "連接 OpenClaw 到 Acme Chat。"
        }
      }
    }
    ```

    ```json openclaw.plugin.json
    {
      "id": "acme-chat",
      "kind": "channel",
      "channels": ["acme-chat"],
      "name": "Acme Chat",
      "description": "Acme Chat channel 外掛",
      "configSchema": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "acme-chat": {
            "type": "object",
            "properties": {
              "token": { "type": "string" },
              "allowFrom": {
                "type": "array",
                "items": { "type": "string" }
              }
            }
          }
        }
      }
    }
    ```
    </CodeGroup>

  </Step>

  <Step title="建置 channel 外掛物件">
    `ChannelPlugin` 介面有許多可選 adapter 介面。從最少的開始 — `id` 與 `setup` — 並根據需要加入 adapters。

    建立 `src/channel.ts`：

    ```typescript src/channel.ts
    import {
      createChatChannelPlugin,
      createChannelPluginBase,
    } from "openclaw/plugin-sdk/core";
    import type { OpenClawConfig } from "openclaw/plugin-sdk/core";
    import { acmeChatApi } from "./client.js"; // 你的平台 API 用戶端

    type ResolvedAccount = {
      accountId: string | null;
      token: string;
      allowFrom: string[];
      dmPolicy: string | undefined;
    };

    function resolveAccount(
      cfg: OpenClawConfig,
      accountId?: string | null,
    ): ResolvedAccount {
      const section = (cfg.channels as Record<string, any>)?.["acme-chat"];
      const token = section?.token;
      if (!token) throw new Error("acme-chat: token is required");
      return {
        accountId: accountId ?? null,
        token,
        allowFrom: section?.allowFrom ?? [],
        dmPolicy: section?.dmSecurity,
      };
    }

    export const acmeChatPlugin = createChatChannelPlugin<ResolvedAccount>({
      base: createChannelPluginBase({
        id: "acme-chat",
        setup: {
          resolveAccount,
          inspectAccount(cfg, accountId) {
            const section =
              (cfg.channels as Record<string, any>)?.["acme-chat"];
            return {
              enabled: Boolean(section?.token),
              configured: Boolean(section?.token),
              tokenStatus: section?.token ? "available" : "missing",
            };
          },
        },
      }),

      // DM 安全性：誰可以訊息傳送給 bot
      security: {
        dm: {
          channelKey: "acme-chat",
          resolvePolicy: (account) => account.dmPolicy,
          resolveAllowFrom: (account) => account.allowFrom,
          defaultPolicy: "allowlist",
        },
      },

      // 配對：新 DM 聯絡人的批准 flow
      pairing: {
        text: {
          idLabel: "Acme Chat 使用者名稱",
          message: "傳送此代碼以驗證你的身分：",
          notify: async ({ target, code }) => {
            await acmeChatApi.sendDm(target, `Pairing code: ${code}`);
          },
        },
      },

      // 執行緒：回覆如何遞送
      threading: { topLevelReplyToMode: "reply" },

      // 出站：傳送訊息到平台
      outbound: {
        attachedResults: {
          sendText: async (params) => {
            const result = await acmeChatApi.sendMessage(
              params.to,
              params.text,
            );
            return { messageId: result.id };
          },
        },
        base: {
          sendMedia: async (params) => {
            await acmeChatApi.sendFile(params.to, params.filePath);
          },
        },
      },
    });
    ```

    <Accordion title="createChatChannelPlugin 為你做什麼">
      不是手動實作低階 adapter 介面，你傳遞宣告式選項，builder 會合成它們：

      | 選項 | 配線內容 |
      | --- | --- |
      | `security.dm` | 從 config 欄位的範疇 DM 安全性解析器 |
      | `pairing.text` | 基於文字的 DM 配對 flow 搭配代碼交換 |
      | `threading` | 回覆轉模式解析器（固定、account-scoped 或自訂） |
      | `outbound.attachedResults` | 傳回結果中繼資料的傳送函式（訊息 ID） |

      如果需要完整控制，你也可以傳遞原始 adapter 物件代替宣告式選項。
    </Accordion>

  </Step>

  <Step title="配線進入點">
    建立 `index.ts`：

    ```typescript index.ts
    import { defineChannelPluginEntry } from "openclaw/plugin-sdk/core";
    import { acmeChatPlugin } from "./src/channel.js";

    export default defineChannelPluginEntry({
      id: "acme-chat",
      name: "Acme Chat",
      description: "Acme Chat channel 外掛",
      plugin: acmeChatPlugin,
      registerFull(api) {
        api.registerCli(
          ({ program }) => {
            program
              .command("acme-chat")
              .description("Acme Chat 管理");
          },
          { commands: ["acme-chat"] },
        );
      },
    });
    ```

    `defineChannelPluginEntry` 自動處理 setup／full 註冊分割。參考 [進入點](/zh-Hant/plugins/sdk-entrypoints#definechannelpluginentry) 取得所有選項。

  </Step>

  <Step title="加入 setup entry">
    建立 `setup-entry.ts` 以在 onboarding 期間進行輕量級載入：

    ```typescript setup-entry.ts
    import { defineSetupPluginEntry } from "openclaw/plugin-sdk/core";
    import { acmeChatPlugin } from "./src/channel.js";

    export default defineSetupPluginEntry(acmeChatPlugin);
    ```

    當頻道已禁用或未設定時，OpenClaw 載入這個代替完整 entry。它避免在 setup flows 期間拉入重型 runtime 代碼。參考 [Setup 與 Config](/zh-Hant/plugins/sdk-setup#setup-entry) 取得詳細資訊。

  </Step>

  <Step title="處理入站訊息">
    你的外掛需要從平台接收訊息並轉發到 OpenClaw。典型模式是驗證請求的 webhook 並透過 channel 的 inbound handler 分派：

    ```typescript
    registerFull(api) {
      api.registerHttpRoute({
        path: "/acme-chat/webhook",
        auth: "plugin", // plugin 管理的 auth（自己驗證簽名）
        handler: async (req, res) => {
          const event = parseWebhookPayload(req);

          // 你的 inbound handler 分派訊息到 OpenClaw。
          // 精確的配線取決於你的平台 SDK —
          // 參考 extensions/msteams 或 extensions/googlechat 中的真實範例。
          await handleAcmeChatInbound(api, event);

          res.statusCode = 200;
          res.end("ok");
          return true;
        },
      });
    }
    ```

    <Note>
      Inbound 訊息處理是 channel 特定的。每個 channel 外掛擁有自己的 inbound pipeline。查看捆綁 channel 外掛（例如 `extensions/msteams`、`extensions/googlechat`）以取得真實模式。
    </Note>

  </Step>

  <Step title="測試">
    在 `src/channel.test.ts` 中寫入共置測試：

    ```typescript src/channel.test.ts
    import { describe, it, expect } from "vitest";
    import { acmeChatPlugin } from "./channel.js";

    describe("acme-chat plugin", () => {
      it("resolves account from config", () => {
        const cfg = {
          channels: {
            "acme-chat": { token: "test-token", allowFrom: ["user1"] },
          },
        } as any;
        const account = acmeChatPlugin.setup!.resolveAccount(cfg, undefined);
        expect(account.token).toBe("test-token");
      });

      it("inspects account without materializing secrets", () => {
        const cfg = {
          channels: { "acme-chat": { token: "test-token" } },
        } as any;
        const result = acmeChatPlugin.setup!.inspectAccount!(cfg, undefined);
        expect(result.configured).toBe(true);
        expect(result.tokenStatus).toBe("available");
      });

      it("reports missing config", () => {
        const cfg = { channels: {} } as any;
        const result = acmeChatPlugin.setup!.inspectAccount!(cfg, undefined);
        expect(result.configured).toBe(false);
      });
    });
    ```

    ```bash
    pnpm test -- extensions/acme-chat/
    ```

    針對共享測試輔助函式，參考 [Testing](/zh-Hant/plugins/sdk-testing)。

  </Step>
</Steps>

## 檔案結構

```
extensions/acme-chat/
├── package.json              # openclaw.channel 中繼資料
├── openclaw.plugin.json      # Manifest 搭配 config schema
├── index.ts                  # defineChannelPluginEntry
├── setup-entry.ts            # defineSetupPluginEntry
├── api.ts                    # 公開 export（可選）
├── runtime-api.ts            # 內部 runtime export（可選）
└── src/
    ├── channel.ts            # ChannelPlugin via createChatChannelPlugin
    ├── channel.test.ts       # 測試
    ├── client.ts             # 平台 API 用戶端
    └── runtime.ts            # Runtime store（如果需要）
```

## 進階主題

<CardGroup cols={2}>
  <Card title="執行緒選項" icon="git-branch" href="/zh-Hant/plugins/sdk-entrypoints#registration-mode">
    固定、account-scoped 或自訂回覆模式
  </Card>
  <Card title="訊息工具整合" icon="puzzle" href="/zh-Hant/plugins/architecture#channel-plugins-and-the-shared-message-tool">
    describeMessageTool 與 action 發現
  </Card>
  <Card title="Target 解析" icon="crosshair" href="/zh-Hant/plugins/architecture#channel-target-resolution">
    inferTargetChatType、looksLikeId、resolveTarget
  </Card>
  <Card title="Runtime 輔助函式" icon="settings" href="/zh-Hant/plugins/sdk-runtime">
    TTS、STT、media、subagent via api.runtime
  </Card>
</CardGroup>

## 後續步驟

- [Provider 外掛](/zh-Hant/plugins/sdk-provider-plugins) — 如果外掛也提供模型
- [SDK 概述](/zh-Hant/plugins/sdk-overview) — 完整 subpath import 參考
- [SDK 測試](/zh-Hant/plugins/sdk-testing) — 測試工具與合約測試
- [Plugin Manifest](/zh-Hant/plugins/manifest) — 完整 manifest schema
