---
title: "Plugins(外掛)"
summary: "OpenClaw plugins/extensions：發現、設定和安全性"
read_when:
  - 新增或修改 plugins/extensions
  - 記錄外掛安裝或載入規則
---
# Plugins (Extensions)(外掛（擴充功能）)

## 快速入門（對外掛不熟悉？）

外掛只是一個**小型程式碼模組**，使用額外功能（指令、工具和 Gateway RPC）擴充 OpenClaw。

大多數時候，當您想要核心 OpenClaw 中尚未內建的功能（或您想將可選功能排除在主安裝之外）時，您將使用外掛。

快速路徑：

1) 查看已載入的內容：

```bash
openclaw plugins list
```

2) 安裝官方外掛（範例：Voice Call）：

```bash
openclaw plugins install @openclaw/voice-call
```

3) 重新啟動 Gateway，然後在 `plugins.entries.<id>.config` 下設定。

請參閱 [Voice Call](/plugins/voice-call) 以取得具體範例外掛。

## 可用外掛（官方）

- Microsoft Teams 自 2026.1.15 起僅為外掛；如果您使用 Teams，請安裝 `@openclaw/msteams`。
- Memory (Core) — 捆綁的記憶體搜尋外掛（透過 `plugins.slots.memory` 預設啟用）
- Memory (LanceDB) — 捆綁的長期記憶體外掛（auto-recall/capture；設定 `plugins.slots.memory = "memory-lancedb"`）
- [Voice Call](/plugins/voice-call) — `@openclaw/voice-call`
- [Zalo Personal](/plugins/zalouser) — `@openclaw/zalouser`
- [Matrix](/channels/matrix) — `@openclaw/matrix`
- [Nostr](/channels/nostr) — `@openclaw/nostr`
- [Zalo](/channels/zalo) — `@openclaw/zalo`
- [Microsoft Teams](/channels/msteams) — `@openclaw/msteams`
- Google Antigravity OAuth (provider auth) — 捆綁為 `google-antigravity-auth`（預設停用）
- Gemini CLI OAuth (provider auth) — 捆綁為 `google-gemini-cli-auth`（預設停用）
- Qwen OAuth (provider auth) — 捆綁為 `qwen-portal-auth`（預設停用）
- Copilot Proxy (provider auth) — 本地 VS Code Copilot Proxy bridge；不同於內建 `github-copilot` 裝置登入（捆綁，預設停用）

OpenClaw 外掛是透過 jiti 在 runtime 載入的 **TypeScript 模組**。**設定驗證不執行外掛程式碼**；它改用外掛 manifest 和 JSON Schema。請參閱 [Plugin manifest](/plugins/manifest)。

外掛可以註冊：

- Gateway RPC methods
- Gateway HTTP handlers
- Agent tools
- CLI commands
- Background services
- 可選設定驗證
- **Skills**（透過在外掛 manifest 中列出 `skills` 目錄）
- **Auto-reply commands**（無需調用 AI agent 即可執行）

外掛與 Gateway **在行程內**執行，因此將它們視為受信任的程式碼。
工具撰寫指南：[Plugin agent tools](/plugins/agent-tools)。

## Runtime helpers

外掛可以透過 `api.runtime` 存取選定的核心 helpers。對於電話 TTS：

```ts
const result = await api.runtime.tts.textToSpeechTelephony({
  text: "Hello from OpenClaw",
  cfg: api.config,
});
```

注意事項：
- 使用核心 `messages.tts` 設定（OpenAI 或 ElevenLabs）。
- 返回 PCM 音訊緩衝區 + 取樣率。外掛必須為供應商重新取樣/編碼。
- Edge TTS 不支援電話。

## 發現與優先順序

OpenClaw 按順序掃描：

1) 設定路徑
- `plugins.load.paths`（檔案或目錄）

2) 工作區擴充功能
- `<workspace>/.openclaw/extensions/*.ts`
- `<workspace>/.openclaw/extensions/*/index.ts`

3) 全域擴充功能
- `~/.openclaw/extensions/*.ts`
- `~/.openclaw/extensions/*/index.ts`

4) 捆綁擴充功能（與 OpenClaw 一起提供，**預設停用**）
- `<openclaw>/extensions/*`

捆綁外掛必須透過 `plugins.entries.<id>.enabled` 或 `openclaw plugins enable <id>` 明確啟用。安裝的外掛預設啟用，但可以以相同方式停用。

每個外掛必須在其根目錄中包含 `openclaw.plugin.json` 檔案。如果路徑指向檔案，則外掛根目錄是檔案的目錄，並且必須包含 manifest。

如果多個外掛解析為相同的 id，則上述順序中的第一個匹配獲勝，較低優先順序的副本將被忽略。

### Package packs

外掛目錄可能包含具有 `openclaw.extensions` 的 `package.json`：

```json
{
  "name": "my-pack",
  "openclaw": {
    "extensions": ["./src/safety.ts", "./src/tools.ts"]
  }
}
```

每個條目都成為一個外掛。如果 pack 列出多個擴充功能，則外掛 id 變為 `name/<fileBase>`。

如果您的外掛導入 npm deps，請在該目錄中安裝它們，以便 `node_modules` 可用（`npm install` / `pnpm install`）。

### 頻道目錄 metadata

頻道外掛可以透過 `openclaw.channel` 公告 onboarding metadata，並透過 `openclaw.install` 提供安裝提示。這使核心目錄無資料。

範例：

```json
{
  "name": "@openclaw/nextcloud-talk",
  "openclaw": {
    "extensions": ["./index.ts"],
    "channel": {
      "id": "nextcloud-talk",
      "label": "Nextcloud Talk",
      "selectionLabel": "Nextcloud Talk (self-hosted)",
      "docsPath": "/channels/nextcloud-talk",
      "docsLabel": "nextcloud-talk",
      "blurb": "Self-hosted chat via Nextcloud Talk webhook bots.",
      "order": 65,
      "aliases": ["nc-talk", "nc"]
    },
    "install": {
      "npmSpec": "@openclaw/nextcloud-talk",
      "localPath": "extensions/nextcloud-talk",
      "defaultChoice": "npm"
    }
  }
}
```

OpenClaw 還可以合併**外部頻道目錄**（例如，MPM 註冊表匯出）。在以下位置之一放置 JSON 檔案：
- `~/.openclaw/mpm/plugins.json`
- `~/.openclaw/mpm/catalog.json`
- `~/.openclaw/plugins/catalog.json`

或將 `OPENCLAW_PLUGIN_CATALOG_PATHS`（或 `OPENCLAW_MPM_CATALOG_PATHS`）指向一個或多個 JSON 檔案（逗號/分號/`PATH` 分隔）。每個檔案應包含 `{ "entries": [ { "name": "@scope/pkg", "openclaw": { "channel": {...}, "install": {...} } } ] }`。

## 外掛 IDs

預設外掛 ids：

- Package packs：`package.json` `name`
- 獨立檔案：檔案基本名稱（`~/.../voice-call.ts` → `voice-call`）

如果外掛匯出 `id`，OpenClaw 使用它，但在它與設定的 id 不匹配時發出警告。

## 設定

```json5
{
  plugins: {
    enabled: true,
    allow: ["voice-call"],
    deny: ["untrusted-plugin"],
    load: { paths: ["~/Projects/oss/voice-call-extension"] },
    entries: {
      "voice-call": { enabled: true, config: { provider: "twilio" } }
    }
  }
}
```

欄位：
- `enabled`：主切換（預設：true）
- `allow`：允許清單（可選）
- `deny`：拒絕清單（可選；deny 獲勝）
- `load.paths`：額外的外掛檔案/目錄
- `entries.<id>`：每個外掛的切換 + 設定

設定變更**需要 gateway 重新啟動**。

驗證規則（嚴格）：
- `entries`、`allow`、`deny` 或 `slots` 中的未知外掛 ids 是**錯誤**。
- 未知的 `channels.<id>` 鍵是**錯誤**，除非外掛 manifest 宣告頻道 id。
- 外掛設定使用嵌入在 `openclaw.plugin.json`（`configSchema`）中的 JSON Schema 進行驗證。
- 如果外掛停用，則保留其設定並發出**警告**。

## 外掛插槽（獨佔類別）

某些外掛類別是**獨佔的**（一次僅一個活躍）。使用 `plugins.slots` 選擇哪個外掛擁有插槽：

```json5
{
  plugins: {
    slots: {
      memory: "memory-core" // 或 "none" 以停用記憶體外掛
    }
  }
}
```

如果多個外掛宣告 `kind: "memory"`，則僅載入選定的外掛。其他外掛將被停用並提供診斷。

## 控制 UI（schema + 標籤）

控制 UI 使用 `config.schema`（JSON Schema + `uiHints`）來呈現更好的表單。

OpenClaw 根據發現的外掛在 runtime 增強 `uiHints`：

- 為 `plugins.entries.<id>` / `.enabled` / `.config` 新增每個外掛標籤
- 在以下位置合併可選的外掛提供的設定欄位提示：
  `plugins.entries.<id>.config.<field>`

如果您希望外掛設定欄位顯示良好的標籤/佔位符（並將秘密標記為敏感），請在外掛 manifest 中與 JSON Schema 一起提供 `uiHints`。

範例：

```json
{
  "id": "my-plugin",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "apiKey": { "type": "string" },
      "region": { "type": "string" }
    }
  },
  "uiHints": {
    "apiKey": { "label": "API Key", "sensitive": true },
    "region": { "label": "Region", "placeholder": "us-east-1" }
  }
}
```

## CLI

```bash
openclaw plugins list
openclaw plugins info <id>
openclaw plugins install <path>                 # 將本地檔案/目錄複製到 ~/.openclaw/extensions/<id>
openclaw plugins install ./extensions/voice-call # 相對路徑 ok
openclaw plugins install ./plugin.tgz           # 從本地 tarball 安裝
openclaw plugins install ./plugin.zip           # 從本地 zip 安裝
openclaw plugins install -l ./extensions/voice-call # 連結（無複製）用於 dev
openclaw plugins install @openclaw/voice-call # 從 npm 安裝
openclaw plugins update <id>
openclaw plugins update --all
openclaw plugins enable <id>
openclaw plugins disable <id>
openclaw plugins doctor
```

`plugins update` 僅適用於在 `plugins.installs` 下追蹤的 npm 安裝。

外掛還可以註冊自己的頂級指令（範例：`openclaw voicecall`）。

## 外掛 API（概述）

外掛匯出以下任一項：

- 函式：`(api) => { ... }`
- 物件：`{ id, name, configSchema, register(api) { ... } }`

## 外掛 hooks

外掛可以提供 hooks 並在 runtime 註冊它們。這讓外掛可以捆綁事件驅動的自動化，而無需單獨的 hook pack 安裝。

### 範例

```
import { registerPluginHooksFromDir } from "openclaw/plugin-sdk";

export default function register(api) {
  registerPluginHooksFromDir(api, "./hooks");
}
```

注意事項：
- Hook 目錄遵循正常的 hook 結構（`HOOK.md` + `handler.ts`）。
- Hook 資格規則仍然適用（OS/bins/env/config 要求）。
- 外掛管理的 hooks 在 `openclaw hooks list` 中顯示為 `plugin:<id>`。
- 您無法透過 `openclaw hooks` 啟用/停用外掛管理的 hooks；改為啟用/停用外掛。

## Provider 外掛（模型認證）

外掛可以註冊**模型 provider 認證**流程，以便使用者可以在 OpenClaw 內執行 OAuth 或 API 金鑰設定（無需外部腳本）。

透過 `api.registerProvider(...)` 註冊 provider。每個 provider 公開一個或多個認證方法（OAuth、API 金鑰、裝置碼等）。這些方法驅動：

- `openclaw models auth login --provider <id> [--method <id>]`

範例：

```ts
api.registerProvider({
  id: "acme",
  label: "AcmeAI",
  auth: [
    {
      id: "oauth",
      label: "OAuth",
      kind: "oauth",
      run: async (ctx) => {
        // 執行 OAuth 流程並返回認證設定檔。
        return {
          profiles: [
            {
              profileId: "acme:default",
              credential: {
                type: "oauth",
                provider: "acme",
                access: "...",
                refresh: "...",
                expires: Date.now() + 3600 * 1000,
              },
            },
          ],
          defaultModel: "acme/opus-1",
        };
      },
    },
  ],
});
```

注意事項：
- `run` 接收具有 `prompter`、`runtime`、`openUrl` 和 `oauth.createVpsAwareHandlers` helpers 的 `ProviderAuthContext`。
- 當您需要新增預設模型或 provider 設定時，返回 `configPatch`。
- 返回 `defaultModel`，以便 `--set-default` 可以更新 agent 預設值。

### 註冊訊息頻道

外掛可以註冊行為類似內建頻道（WhatsApp、Telegram 等）的**頻道外掛**。頻道設定位於 `channels.<id>` 下，並由您的頻道外掛程式碼進行驗證。

```ts
const myChannel = {
  id: "acmechat",
  meta: {
    id: "acmechat",
    label: "AcmeChat",
    selectionLabel: "AcmeChat (API)",
    docsPath: "/channels/acmechat",
    blurb: "demo channel plugin.",
    aliases: ["acme"],
  },
  capabilities: { chatTypes: ["direct"] },
  config: {
    listAccountIds: (cfg) => Object.keys(cfg.channels?.acmechat?.accounts ?? {}),
    resolveAccount: (cfg, accountId) =>
      (cfg.channels?.acmechat?.accounts?.[accountId ?? "default"] ?? { accountId }),
  },
  outbound: {
    deliveryMode: "direct",
    sendText: async () => ({ ok: true }),
  },
};

export default function (api) {
  api.registerChannel({ plugin: myChannel });
}
```

注意事項：
- 將設定放在 `channels.<id>` 下（而不是 `plugins.entries`）。
- `meta.label` 用於 CLI/UI 清單中的標籤。
- `meta.aliases` 為正規化和 CLI 輸入新增備用 ids。
- `meta.preferOver` 列出當兩者都設定時跳過自動啟用的頻道 ids。
- `meta.detailLabel` 和 `meta.systemImage` 讓 UIs 顯示更豐富的頻道標籤/圖示。

### 編寫新的訊息頻道（逐步）

當您想要**新的聊天介面**（「訊息頻道」）而不是模型 provider 時使用此方法。
模型 provider 文件位於 `/providers/*` 下。

1) 選擇 id + 設定形狀
- 所有頻道設定都位於 `channels.<id>` 下。
- 對於多帳戶設定，偏好 `channels.<id>.accounts.<accountId>`。

2) 定義頻道 metadata
- `meta.label`、`meta.selectionLabel`、`meta.docsPath`、`meta.blurb` 控制 CLI/UI 清單。
- `meta.docsPath` 應指向文件頁面，如 `/channels/<id>`。
- `meta.preferOver` 讓外掛替換另一個頻道（自動啟用偏好它）。
- `meta.detailLabel` 和 `meta.systemImage` 由 UIs 用於詳細文字/圖示。

3) 實作所需的 adapters
- `config.listAccountIds` + `config.resolveAccount`
- `capabilities`（聊天類型、媒體、threads 等）
- `outbound.deliveryMode` + `outbound.sendText`（用於基本發送）

4) 根據需要新增可選 adapters
- `setup`（精靈）、`security`（DM 策略）、`status`（健康/診斷）
- `gateway`（start/stop/login）、`mentions`、`threading`、`streaming`
- `actions`（訊息操作）、`commands`（原生指令行為）

5) 在外掛中註冊頻道
- `api.registerChannel({ plugin })`

最小設定範例：

```json5
{
  channels: {
    acmechat: {
      accounts: {
        default: { token: "ACME_TOKEN", enabled: true }
      }
    }
  }
}
```

最小頻道外掛（僅出站）：

```ts
const plugin = {
  id: "acmechat",
  meta: {
    id: "acmechat",
    label: "AcmeChat",
    selectionLabel: "AcmeChat (API)",
    docsPath: "/channels/acmechat",
    blurb: "AcmeChat messaging channel.",
    aliases: ["acme"],
  },
  capab ilities: { chatTypes: ["direct"] },
  config: {
    listAccountIds: (cfg) => Object.keys(cfg.channels?.acmechat?.accounts ?? {}),
    resolveAccount: (cfg, accountId) =>
      (cfg.channels?.acmechat?.accounts?.[accountId ?? "default"] ?? { accountId }),
  },
  outbound: {
    deliveryMode: "direct",
    sendText: async ({ text }) => {
      // 在此處將 `text` 傳遞到您的頻道
      return { ok: true };
    },
  },
};

export default function (api) {
  api.registerChannel({ plugin });
}
```

載入外掛（擴充功能目錄或 `plugins.load.paths`），重新啟動 gateway，然後在您的設定中設定 `channels.<id>`。

### Agent 工具

請參閱專門指南：[Plugin agent tools](/plugins/agent-tools)。

### 註冊 gateway RPC 方法

```ts
export default function (api) {
  api.registerGatewayMethod("myplugin.status", ({ respond }) => {
    respond(true, { ok: true });
  });
}
```

### 註冊 CLI 指令

```ts
export default function (api) {
  api.registerCli(({ program }) => {
    program.command("mycmd").action(() => {
      console.log("Hello");
    });
  }, { commands: ["mycmd"] });
}
```

### 註冊自動回覆指令

外掛可以註冊自訂 slash 指令，**無需調用 AI agent** 即可執行。這對於切換指令、狀態檢查或不需要 LLM 處理的快速操作很有用。

```ts
export default function (api) {
  api.registerCommand({
    name: "mystatus",
    description: "Show plugin status",
    handler: (ctx) => ({
      text: `Plugin is running! Channel: ${ctx.channel}`,
    }),
  });
}
```

指令 handler 上下文：

- `senderId`：發送者的 ID（如果可用）
- `channel`：發送指令的頻道
- `isAuthorizedSender`：發送者是否是授權使用者
- `args`：指令後傳遞的參數（如果 `acceptsArgs: true`）
- `commandBody`：完整指令文字
- `config`：當前 OpenClaw 設定

指令選項：

- `name`：指令名稱（不含前導 `/`）
- `description`：指令清單中顯示的說明文字
- `acceptsArgs`：指令是否接受參數（預設：false）。如果為 false 且提供了參數，則指令將不匹配，訊息將通過其他 handlers
- `requireAuth`：是否需要授權發送者（預設：true）
- `handler`：返回 `{ text: string }` 的函式（可以是 async）

具有授權和參數的範例：

```ts
api.registerCommand({
  name: "setmode",
  description: "Set plugin mode",
  acceptsArgs: true,
  requireAuth: true,
  handler: async (ctx) => {
    const mode = ctx.args?.trim() || "default";
    await saveMode(mode);
    return { text: `Mode set to: ${mode}` };
  },
});
```

注意事項：
- 外掛指令在內建指令和 AI agent **之前**處理
- 指令在所有頻道中全域註冊並工作
- 指令名稱不區分大小寫（`/MyStatus` 匹配 `/mystatus`）
- 指令名稱必須以字母開頭，並且僅包含字母、數字、連字符和底線
- 保留的指令名稱（如 `help`、`status`、`reset` 等）無法被外掛覆蓋
- 跨外掛的重複指令註冊將失敗並顯示診斷錯誤

### 註冊背景服務

```ts
export default function (api) {
  api.registerService({
    id: "my-service",
    start: () => api.logger.info("ready"),
    stop: () => api.logger.info("bye"),
  });
}
```

## 命名慣例

- Gateway methods：`pluginId.action`（範例：`voicecall.status`）
- Tools：`snake_case`（範例：`voice_call`）
- CLI commands：kebab 或 camel，但避免與核心指令衝突

## Skills

外掛可以在 repo 中提供 skill（`skills/<name>/SKILL.md`）。
使用 `plugins.entries.<id>.enabled`（或其他設定門）啟用它，並確保它存在於您的工作區/managed skills 位置。

## 分發（npm）

建議的封裝：

- 主套件：`openclaw`（此 repo）
- 外掛：`@openclaw/*` 下的單獨 npm 套件（範例：`@openclaw/voice-call`）

發布合約：

- 外掛 `package.json` 必須包含具有一個或多個條目檔案的 `openclaw.extensions`。
- 條目檔案可以是 `.js` 或 `.ts`（jiti 在 runtime 載入 TS）。
- `openclaw plugins install <npm-spec>` 使用 `npm pack`，提取到 `~/.openclaw/extensions/<id>/`，並在設定中啟用它。
- 設定鍵穩定性：scoped 套件正規化為 `plugins.entries.*` 的 **unscoped** id。

## 範例外掛：Voice Call

此 repo 包含一個語音呼叫外掛（Twilio 或 log fallback）：

- Source：`extensions/voice-call`
- Skill：`skills/voice-call`
- CLI：`openclaw voicecall start|status`
- Tool：`voice_call`
- RPC：`voicecall.start`、`voicecall.status`
- 設定（twilio）：`provider: "twilio"` + `twilio.accountSid/authToken/from`（可選 `statusCallbackUrl`、`twimlUrl`）
- 設定（dev）：`provider: "log"`（無網路）

請參閱 [Voice Call](/plugins/voice-call) 和 `extensions/voice-call/README.md` 以取得設定和使用。

## 安全注意事項

外掛與 Gateway 在行程內執行。將它們視為受信任的程式碼：

- 僅安裝您信任的外掛。
- 偏好 `plugins.allow` 允許清單。
- 變更後重新啟動 Gateway。

## 測試外掛

外掛可以（並且應該）提供測試：

- In-repo 外掛可以將 Vitest 測試保留在 `src/**` 下（範例：`src/plugins/voice-call.plugin.test.ts`）。
- 單獨發布的外掛應執行自己的 CI（lint/build/test）並驗證 `openclaw.extensions` 指向建置的入口點（`dist/index.js`）。
