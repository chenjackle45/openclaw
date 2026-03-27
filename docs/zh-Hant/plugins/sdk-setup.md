---
title: "Plugin Setup and Config（Plugin Setup 與 Config）"
sidebarTitle: "Setup 與 Config"
summary: "Setup wizards, setup-entry.ts, config schemas, and package.json metadata（Setup 精靈、setup-entry.ts、config schemas 與 package.json 中繼資料）"
read_when:
  - 你正在為外掛加入 setup 精靈
  - 你需要理解 setup-entry.ts 與 index.ts 的差異
  - 你正在定義外掛 config schemas 或 package.json openclaw 中繼資料
---

# Plugin Setup and Config

Plugin 打包（`package.json` 中繼資料）、manifests（`openclaw.plugin.json`）、setup entries 與 config schemas 的參考。

<Tip>
  **在找實作指南？** How-to 指南在脈絡中涵蓋打包：[Channel 外掛](/zh-Hant/plugins/sdk-channel-plugins#step-1-package-and-manifest) 與 [Provider 外掛](/zh-Hant/plugins/sdk-provider-plugins#step-1-package-and-manifest)。
</Tip>

## 套件中繼資料

你的 `package.json` 需要 `openclaw` 欄位，告訴外掛系統你的外掛提供什麼：

**Channel 外掛：**

```json
{
  "name": "@myorg/openclaw-my-channel",
  "version": "1.0.0",
  "type": "module",
  "openclaw": {
    "extensions": ["./index.ts"],
    "setupEntry": "./setup-entry.ts",
    "channel": {
      "id": "my-channel",
      "label": "My Channel",
      "blurb": "頻道的簡短說明。"
    }
  }
}
```

**Provider 外掛：**

```json
{
  "name": "@myorg/openclaw-my-provider",
  "version": "1.0.0",
  "type": "module",
  "openclaw": {
    "extensions": ["./index.ts"],
    "providers": ["my-provider"]
  }
}
```

### `openclaw` 欄位

| 欄位         | 型別       | 說明                                                                                       |
| ------------ | ---------- | ------------------------------------------------------------------------------------------ |
| `extensions` | `string[]` | Entry point 檔案（相對於套件根）                                                           |
| `setupEntry` | `string`   | 輕量級 setup-only entry（可選）                                                            |
| `channel`    | `object`   | Channel 中繼資料：`id`、`label`、`blurb`、`selectionLabel`、`docsPath`、`order`、`aliases` |
| `providers`  | `string[]` | 此外掛註冊的 provider id                                                                   |
| `install`    | `object`   | Install 提示：`npmSpec`、`localPath`、`defaultChoice`                                      |
| `startup`    | `object`   | Startup 行為旗標                                                                           |

### 延遲完整載入

Channel 外掛可以選擇加入延遲載入：

```json
{
  "openclaw": {
    "extensions": ["./index.ts"],
    "setupEntry": "./setup-entry.ts",
    "startup": {
      "deferConfiguredChannelFullLoadUntilAfterListen": true
    }
  }
}
```

啟用時，OpenClaw 只在監聽前 startup 階段載入 `setupEntry`，即使是已設定的頻道也是如此。完整 entry 在 gateway 開始監聽後載入。

<Warning>
  只在你的 `setupEntry` 註冊 gateway 開始監聽前需要的所有內容時啟用延遲載入（channel 註冊、HTTP routes、gateway 方法）。如果完整 entry 擁有必需的 startup 能力，保持預設行為。
</Warning>

## Plugin manifest

每個原生外掛必須在套件根中運送 `openclaw.plugin.json`。OpenClaw 使用它在不執行外掛代碼的情況下驗證 config。

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "description": "為 OpenClaw 加入我的 Plugin 能力",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "webhookSecret": {
        "type": "string",
        "description": "Webhook 驗證祕密"
      }
    }
  }
}
```

對於 channel 外掛，加入 `kind` 與 `channels`：

```json
{
  "id": "my-channel",
  "kind": "channel",
  "channels": ["my-channel"],
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

即使沒有 config，外掛也必須運送 schema。空 schema 是有效的：

```json
{
  "id": "my-plugin",
  "configSchema": {
    "type": "object",
    "additionalProperties": false
  }
}
```

參考 [Plugin Manifest](/zh-Hant/plugins/manifest)，取得完整 schema 參考。

## Setup entry

`setup-entry.ts` 檔案是 `index.ts` 的輕量級替代方案，OpenClaw 在只需要 setup 介面時載入（onboarding、config 修復、禁用 channel 檢查）。

```typescript
// setup-entry.ts
import { defineSetupPluginEntry } from "openclaw/plugin-sdk/core";
import { myChannelPlugin } from "./src/channel.js";

export default defineSetupPluginEntry(myChannelPlugin);
```

這避免在 setup flows 期間載入重型 runtime 代碼（crypto 庫、CLI 註冊、背景服務）。

**何時 OpenClaw 使用 `setupEntry` 而不是完整 entry：**

- Channel 已禁用但需要 setup／onboarding 介面
- Channel 已啟用但未設定
- 延遲載入已啟用（`deferConfiguredChannelFullLoadUntilAfterListen`）

**`setupEntry` 必須註冊：**

- Channel plugin 物件（透過 `defineSetupPluginEntry`）
- Gateway 監聽前所需的任何 HTTP routes
- Startup 期間需要的任何 gateway 方法

**`setupEntry` 不應包括：**

- CLI 註冊
- 背景服務
- 重型 runtime imports（crypto、SDK）
- 只在 startup 後需要的 gateway 方法

## Config schema

Plugin config 被驗證為你的 manifest 中的 JSON Schema。使用者透過以下方式設定外掛：

```json5
{
  plugins: {
    entries: {
      "my-plugin": {
        config: {
          webhookSecret: "abc123",
        },
      },
    },
  },
}
```

你的外掛在註冊期間收到此 config 作為 `api.pluginConfig`。

針對 channel 特定的 config，改用 channel config 區段：

```json5
{
  channels: {
    "my-channel": {
      token: "bot-token",
      allowFrom: ["user1", "user2"],
    },
  },
}
```

### 建置 channel config schemas

使用 `buildChannelConfigSchema` 從 `openclaw/plugin-sdk/core` 將 Zod schema 轉換為 OpenClaw 驗證的 `ChannelConfigSchema` 包裝器：

```typescript
import { z } from "zod";
import { buildChannelConfigSchema } from "openclaw/plugin-sdk/core";

const accountSchema = z.object({
  token: z.string().optional(),
  allowFrom: z.array(z.string()).optional(),
  accounts: z.object({}).catchall(z.any()).optional(),
  defaultAccount: z.string().optional(),
});

const configSchema = buildChannelConfigSchema(accountSchema);
```

## Setup 精靈

Channel 外掛可以為 `openclaw onboard` 提供互動式 setup 精靈。精靈是 `ChannelPlugin` 上的 `ChannelSetupWizard` 物件：

```typescript
import type { ChannelSetupWizard } from "openclaw/plugin-sdk/channel-setup";

const setupWizard: ChannelSetupWizard = {
  channel: "my-channel",
  status: {
    configuredLabel: "已連線",
    unconfiguredLabel: "未設定",
    resolveConfigured: ({ cfg }) => Boolean((cfg.channels as any)?.["my-channel"]?.token),
  },
  credentials: [
    {
      inputKey: "token",
      providerHint: "my-channel",
      credentialLabel: "Bot token",
      preferredEnvVar: "MY_CHANNEL_BOT_TOKEN",
      envPrompt: "使用 MY_CHANNEL_BOT_TOKEN 從環境？",
      keepPrompt: "保留目前 token？",
      inputPrompt: "輸入你的 bot token：",
      inspect: ({ cfg, accountId }) => {
        const token = (cfg.channels as any)?.["my-channel"]?.token;
        return {
          accountConfigured: Boolean(token),
          hasConfiguredValue: Boolean(token),
        };
      },
    },
  ],
};
```

`ChannelSetupWizard` 型別支援 `credentials`、`textInputs`、`dmPolicy`、`allowFrom`、`groupAccess`、`prepare`、`finalize` 等。參考捆綁外掛（例如 `extensions/discord/src/channel.setup.ts`）以取得完整範例。

針對只需要標準 `note -> prompt -> parse -> merge -> patch` flow 的 DM allowlist prompts，優先使用來自 `openclaw/plugin-sdk/setup` 的共享 setup 輔助函式：`createPromptParsedAllowFromForAccount(...)`、`createTopLevelChannelParsedAllowFromPrompt(...)` 與 `createNestedChannelParsedAllowFromPrompt(...)`。

針對只按標籤、分數與可選額外行變更的 channel setup 狀態塊，優先使用 `openclaw/plugin-sdk/setup` 中的 `createStandardChannelSetupStatus(...)` 而不是在每個外掛中手動推出相同的 `status` 物件。

對於應該只在特定脈絡中出現的可選 setup 介面，使用 `openclaw/plugin-sdk/channel-setup` 中的 `createOptionalChannelSetupSurface`：

```typescript
import { createOptionalChannelSetupSurface } from "openclaw/plugin-sdk/channel-setup";

const setupSurface = createOptionalChannelSetupSurface({
  channel: "my-channel",
  label: "My Channel",
  npmSpec: "@myorg/openclaw-my-channel",
  docsPath: "/channels/my-channel",
});
// 傳回 { setupAdapter, setupWizard }
```

## 發佈與安裝

**外部外掛：** 發佈至 [ClawHub](/zh-Hant/tools/clawhub) 或 npm，然後安裝：

```bash
openclaw plugins install @myorg/openclaw-my-plugin
```

OpenClaw 先嘗試 ClawHub 然後自動回退到 npm。你也可以強制特定來源：

```bash
openclaw plugins install clawhub:@myorg/openclaw-my-plugin   # 僅 ClawHub
openclaw plugins install npm:@myorg/openclaw-my-plugin       # 僅 npm
```

**In-repo 外掛：** 放在 `extensions/` 下，它們在建置期間自動發現。

**使用者可以瀏覽與安裝：**

```bash
openclaw plugins search <query>
openclaw plugins install <package-name>
```

<Info>
  針對 npm 源的 installs，`openclaw plugins install` 執行 `npm install --ignore-scripts`（沒有生命週期指令稿）。保持外掛相依樹為純 JS/TS，避免需要 `postinstall` 建置的套件。
</Info>

## 相關

- [SDK 進入點](/zh-Hant/plugins/sdk-entrypoints) -- `definePluginEntry` 與 `defineChannelPluginEntry`
- [Plugin Manifest](/zh-Hant/plugins/manifest) -- 完整 manifest schema 參考
- [建置外掛](/zh-Hant/plugins/building-plugins) -- 逐步入門指南
