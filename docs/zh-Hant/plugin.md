---
summary: "OpenClaw plugins/extensions：探索、設定和安全"
read_when:
  - 新增或修改 plugins/extensions
  - 記錄 plugin 安裝或載入規則
title: "Plugins（外掛）"
---

# Plugins (Extensions)

## 快速上手（不熟悉 plugins？）

Plugin 就是一個**小型程式碼模組**，為 OpenClaw 擴充額外功能（命令、工具和 Gateway RPC）。

大多數情況下，當你想要一個尚未內建於核心 OpenClaw 的功能時（或想將可選功能排除在主要安裝之外）才會使用 plugins。

快速路徑：

1. 查看已載入的項目：

```bash
openclaw plugins list
```

2. 安裝官方 plugin（範例：Voice Call）：

```bash
openclaw plugins install @openclaw/voice-call
```

Npm 規格僅限**登錄中心**（套件名稱 + 可選的**確切版本**或 **dist-tag**）。Git/URL/檔案規格和 semver 範圍會被拒絕。

裸規格和 `@latest` 保持在穩定版本軌道。若 npm 將兩者解析為預先發布版本，OpenClaw 會停止並要求你以預先發布 tag（例如 `@beta`/`@rc`）或確切的預先發布版本明確選擇加入。

3. 重啟 Gateway，然後在 `plugins.entries.<id>.config` 下設定。

請參閱 [Voice Call](/zh-Hant/plugins/voice-call) 了解具體的範例 plugin。
尋找第三方列表？請參閱 [Community plugins](/zh-Hant/plugins/community)。

## 可用 plugins（官方）

- Microsoft Teams 自 2026.1.15 起僅作為 plugin；若你使用 Teams，請安裝 `@openclaw/msteams`。
- Memory（Core）— 附帶的記憶體搜尋 plugin（透過 `plugins.slots.memory` 預設啟用）
- Memory（LanceDB）— 附帶的長期記憶體 plugin（自動回憶/擷取；設定 `plugins.slots.memory = "memory-lancedb"`）
- [Voice Call](/zh-Hant/plugins/voice-call) — `@openclaw/voice-call`
- [Zalo Personal](/zh-Hant/plugins/zalouser) — `@openclaw/zalouser`
- [Matrix](/zh-Hant/channels/matrix) — `@openclaw/matrix`
- [Nostr](/zh-Hant/channels/nostr) — `@openclaw/nostr`
- [Zalo](/zh-Hant/channels/zalo) — `@openclaw/zalo`
- [Microsoft Teams](/zh-Hant/channels/msteams) — `@openclaw/msteams`
- Google Antigravity OAuth（提供者認證）— 作為 `google-antigravity-auth` 附帶（預設停用）
- Gemini CLI OAuth（提供者認證）— 作為 `google-gemini-cli-auth` 附帶（預設停用）
- Qwen OAuth（提供者認證）— 作為 `qwen-portal-auth` 附帶（預設停用）
- Copilot Proxy（提供者認證）— 本地 VS Code Copilot Proxy bridge；與內建的 `github-copilot` 裝置登入不同（附帶，預設停用）

OpenClaw plugins 是透過 jiti 在執行期載入的 **TypeScript 模組**。**設定驗證不執行 plugin 程式碼**；它使用 plugin manifest 和 JSON Schema。請參閱 [Plugin manifest](/zh-Hant/plugins/manifest)。

Plugins 可以註冊：

- Gateway RPC 方法
- Gateway HTTP 路由
- Agent 工具
- CLI 命令
- 背景服務
- Context 引擎
- 可選的設定驗證
- **Skills**（在 plugin manifest 中列出 `skills` 目錄）
- **自動回覆命令**（無需呼叫 AI agent 即可執行）

Plugins 與 Gateway **在同一行程中**執行，因此將其視為受信任的程式碼。工具撰寫指南：[Plugin agent tools](/zh-Hant/plugins/agent-tools)。

## 執行期輔助工具

Plugins 可以透過 `api.runtime` 存取部分核心輔助工具。對於電話語音 TTS：

```ts
const result = await api.runtime.tts.textToSpeechTelephony({
  text: "Hello from OpenClaw",
  cfg: api.config,
});
```

注意事項：

- 使用核心 `messages.tts` 設定（OpenAI 或 ElevenLabs）。
- 回傳 PCM 音訊緩衝區 + 取樣率。Plugins 必須為提供者重新取樣/編碼。
- 電話不支援 Edge TTS。

對於 STT/轉錄，plugins 可以呼叫：

```ts
const { text } = await api.runtime.stt.transcribeAudioFile({
  filePath: "/tmp/inbound-audio.ogg",
  cfg: api.config,
  // Optional when MIME cannot be inferred reliably:
  mime: "audio/ogg",
});
```

注意事項：

- 使用核心媒體理解音訊設定（`tools.media.audio`）和提供者備用順序。
- 當未產生轉錄輸出時回傳 `{ text: undefined }`（例如跳過/不支援的輸入）。

## Gateway HTTP 路由

Plugins 可以使用 `api.registerHttpRoute(...)` 公開 HTTP 端點。

```ts
api.registerHttpRoute({
  path: "/acme/webhook",
  auth: "plugin",
  match: "exact",
  handler: async (_req, res) => {
    res.statusCode = 200;
    res.end("ok");
    return true;
  },
});
```

路由欄位：

- `path`：gateway HTTP 伺服器下的路由路徑。
- `auth`：必填。使用 `"gateway"` 要求正常的 gateway 認證，或使用 `"plugin"` 用於 plugin 管理的認證/webhook 驗證。
- `match`：可選。`"exact"`（預設）或 `"prefix"`。
- `replaceExisting`：可選。允許同一 plugin 替換其自己的現有路由註冊。
- `handler`：當路由處理了請求時回傳 `true`。

注意事項：

- `api.registerHttpHandler(...)` 已棄用。請使用 `api.registerHttpRoute(...)`。
- Plugin 路由必須明確宣告 `auth`。
- 確切的 `path + match` 衝突會被拒絕，除非 `replaceExisting: true`，且一個 plugin 無法替換另一個 plugin 的路由。
- 具有不同 `auth` 等級的重疊路由會被拒絕。僅在相同的 auth 等級上保持 `exact`/`prefix` 備用鏈。

## Plugin SDK 匯入路徑

撰寫 plugins 時請使用 SDK 子路徑而非整體的 `openclaw/plugin-sdk` 匯入：

- `openclaw/plugin-sdk/core` 用於通用 plugin API、提供者認證類型和共用輔助工具。
- `openclaw/plugin-sdk/compat` 用於需要比 `core` 更廣泛共用執行期輔助工具的附帶/內部 plugin 程式碼。
- `openclaw/plugin-sdk/telegram` 用於 Telegram 頻道 plugins。
- `openclaw/plugin-sdk/discord` 用於 Discord 頻道 plugins。
- `openclaw/plugin-sdk/slack` 用於 Slack 頻道 plugins。
- `openclaw/plugin-sdk/signal` 用於 Signal 頻道 plugins。
- `openclaw/plugin-sdk/imessage` 用於 iMessage 頻道 plugins。
- `openclaw/plugin-sdk/whatsapp` 用於 WhatsApp 頻道 plugins。
- `openclaw/plugin-sdk/line` 用於 LINE 頻道 plugins。
- `openclaw/plugin-sdk/msteams` 用於附帶的 Microsoft Teams plugin 介面。
- 附帶的 extension 特定子路徑也可用：
  `openclaw/plugin-sdk/acpx`、`openclaw/plugin-sdk/bluebubbles`、
  `openclaw/plugin-sdk/copilot-proxy`、`openclaw/plugin-sdk/device-pair`、
  `openclaw/plugin-sdk/diagnostics-otel`、`openclaw/plugin-sdk/diffs`、
  `openclaw/plugin-sdk/feishu`、
  `openclaw/plugin-sdk/google-gemini-cli-auth`、`openclaw/plugin-sdk/googlechat`、
  `openclaw/plugin-sdk/irc`、`openclaw/plugin-sdk/llm-task`、
  `openclaw/plugin-sdk/lobster`、`openclaw/plugin-sdk/matrix`、
  `openclaw/plugin-sdk/mattermost`、`openclaw/plugin-sdk/memory-core`、
  `openclaw/plugin-sdk/memory-lancedb`、
  `openclaw/plugin-sdk/minimax-portal-auth`、
  `openclaw/plugin-sdk/nextcloud-talk`、`openclaw/plugin-sdk/nostr`、
  `openclaw/plugin-sdk/open-prose`、`openclaw/plugin-sdk/phone-control`、
  `openclaw/plugin-sdk/qwen-portal-auth`、`openclaw/plugin-sdk/synology-chat`、
  `openclaw/plugin-sdk/talk-voice`、`openclaw/plugin-sdk/test-utils`、
  `openclaw/plugin-sdk/thread-ownership`、`openclaw/plugin-sdk/tlon`、
  `openclaw/plugin-sdk/twitch`、`openclaw/plugin-sdk/voice-call`、
  `openclaw/plugin-sdk/zalo` 和 `openclaw/plugin-sdk/zalouser`。

相容性注意事項：

- `openclaw/plugin-sdk` 對現有外部 plugins 仍然受支援。
- 新的和已遷移的附帶 plugins 應使用頻道或 extension 特定的子路徑；對通用介面使用 `core`，僅在需要更廣泛的共用輔助工具時使用 `compat`。

## 唯讀頻道檢查

若你的 plugin 註冊了頻道，建議在 `resolveAccount(...)` 旁邊實作 `plugin.config.inspectAccount(cfg, accountId)`。

原因：

- `resolveAccount(...)` 是執行期路徑。允許假設憑證已完全實體化，並且在缺少必要密鑰時可以快速失敗。
- 唯讀命令路徑（例如 `openclaw status`、`openclaw status --all`、`openclaw channels status`、`openclaw channels resolve` 以及 doctor/config 修復流程）不應需要實體化執行期憑證才能描述設定。

推薦的 `inspectAccount(...)` 行為：

- 僅回傳描述性帳戶狀態。
- 保留 `enabled` 和 `configured`。
- 在相關時包含憑證來源/狀態欄位，例如：
  - `tokenSource`、`tokenStatus`
  - `botTokenSource`、`botTokenStatus`
  - `appTokenSource`、`appTokenStatus`
  - `signingSecretSource`、`signingSecretStatus`
- 你不需要回傳原始 token 值只是為了回報唯讀可用性。回傳 `tokenStatus: "available"`（和相符的來源欄位）對於狀態類命令已足夠。
- 當憑證透過 SecretRef 設定但在目前的命令路徑中不可用時，使用 `configured_unavailable`。

這讓唯讀命令可以回報「已設定但在此命令路徑中不可用」，而非崩潰或錯誤回報帳戶未設定。

效能注意事項：

- Plugin 探索和 manifest 元資料使用短暫的行程內快取，以減少突發的啟動/重新載入工作。
- 設定 `OPENCLAW_DISABLE_PLUGIN_DISCOVERY_CACHE=1` 或 `OPENCLAW_DISABLE_PLUGIN_MANIFEST_CACHE=1` 可停用這些快取。
- 使用 `OPENCLAW_PLUGIN_DISCOVERY_CACHE_MS` 和 `OPENCLAW_PLUGIN_MANIFEST_CACHE_MS` 調整快取視窗。

## 探索與優先順序

OpenClaw 按順序掃描：

1. 設定路徑

- `plugins.load.paths`（檔案或目錄）

2. 工作區 extensions

- `<workspace>/.openclaw/extensions/*.ts`
- `<workspace>/.openclaw/extensions/*/index.ts`

3. 全域 extensions

- `~/.openclaw/extensions/*.ts`
- `~/.openclaw/extensions/*/index.ts`

4. 附帶的 extensions（隨 OpenClaw 附帶，大多數預設停用）

- `<openclaw>/extensions/*`

大多數附帶的 plugins 必須透過 `plugins.entries.<id>.enabled` 或 `openclaw plugins enable <id>` 明確啟用。

預設啟用的附帶 plugin 例外：

- `device-pair`
- `phone-control`
- `talk-voice`
- 活躍的記憶體插槽 plugin（預設插槽：`memory-core`）

已安裝的 plugins 預設啟用，但可以以相同方式停用。

加固注意事項：

- 若 `plugins.allow` 為空且非附帶的 plugins 可被探索，OpenClaw 會在啟動時發出帶有 plugin id 和來源的警告。
- 候選路徑在探索准入前會進行安全性檢查。OpenClaw 在以下情況封鎖候選路徑：
  - extension 條目解析到 plugin 根目錄之外（包含符號連結/路徑遍歷逃脫），
  - plugin 根/來源路徑是全域可寫入的，
  - 非附帶 plugins 的路徑所有權可疑（POSIX 所有者既非當前 uid 也非 root）。
- 沒有安裝/載入路徑來源的已載入非附帶 plugins 會發出警告，讓你可以固定信任（`plugins.allow`）或安裝追蹤（`plugins.installs`）。

每個 plugin 必須在其根目錄中包含一個 `openclaw.plugin.json` 檔案。若路徑指向檔案，plugin 根目錄是該檔案的目錄，且必須包含 manifest。

若多個 plugins 解析到相同的 id，上述順序中的第一個匹配優先，較低優先順序的副本會被忽略。

### 套件包

Plugin 目錄可以包含帶有 `openclaw.extensions` 的 `package.json`：

```json
{
  "name": "my-pack",
  "openclaw": {
    "extensions": ["./src/safety.ts", "./src/tools.ts"]
  }
}
```

每個條目成為一個 plugin。若包含多個 extensions，plugin id 變為 `name/<fileBase>`。

若你的 plugin 匯入 npm 相依套件，請在該目錄中安裝它們，使 `node_modules` 可用（`npm install` / `pnpm install`）。

安全護欄：每個 `openclaw.extensions` 條目在符號連結解析後必須保持在 plugin 目錄內。逃脫套件目錄的條目會被拒絕。

安全注意事項：`openclaw plugins install` 以 `npm install --ignore-scripts`（無生命週期腳本）安裝 plugin 相依套件。保持 plugin 相依樹「純 JS/TS」，避免需要 `postinstall` 建構的套件。

### 頻道目錄元資料

頻道 plugins 可以透過 `openclaw.channel` 宣告 onboarding 元資料，透過 `openclaw.install` 宣告安裝提示。這讓核心目錄保持無資料。

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

OpenClaw 也可以合併**外部頻道目錄**（例如 MPM 登錄中心匯出）。將 JSON 檔案放置在以下其中一個位置：

- `~/.openclaw/mpm/plugins.json`
- `~/.openclaw/mpm/catalog.json`
- `~/.openclaw/plugins/catalog.json`

或將 `OPENCLAW_PLUGIN_CATALOG_PATHS`（或 `OPENCLAW_MPM_CATALOG_PATHS`）指向一個或多個 JSON 檔案（以逗號/分號/`PATH` 分隔）。每個檔案應包含 `{ "entries": [ { "name": "@scope/pkg", "openclaw": { "channel": {...}, "install": {...} } } ] }`。

## Plugin ID

預設的 plugin id：

- 套件包：`package.json` `name`
- 獨立檔案：檔案基本名稱（`~/.../voice-call.ts` → `voice-call`）

若 plugin 匯出 `id`，OpenClaw 使用它，但當它與設定的 id 不符時會發出警告。

## 設定

```json5
{
  plugins: {
    enabled: true,
    allow: ["voice-call"],
    deny: ["untrusted-plugin"],
    load: { paths: ["~/Projects/oss/voice-call-extension"] },
    entries: {
      "voice-call": { enabled: true, config: { provider: "twilio" } },
    },
  },
}
```

欄位：

- `enabled`：主要切換（預設：true）
- `allow`：允許清單（可選）
- `deny`：拒絕清單（可選；拒絕優先）
- `load.paths`：額外的 plugin 檔案/目錄
- `slots`：獨佔插槽選擇器，例如 `memory` 和 `contextEngine`
- `entries.<id>`：每個 plugin 的切換 + 設定

設定變更**需要 gateway 重啟**。

驗證規則（嚴格）：

- `entries`、`allow`、`deny` 或 `slots` 中未知的 plugin id 是**錯誤**。
- 未知的 `channels.<id>` 鍵是**錯誤**，除非 plugin manifest 宣告頻道 id。
- Plugin 設定使用嵌入在 `openclaw.plugin.json` 中的 JSON Schema（`configSchema`）進行驗證。
- 若 plugin 被停用，其設定會被保留，並發出**警告**。

## Plugin 插槽（獨佔類別）

某些 plugin 類別是**獨佔的**（一次只能有一個活躍）。使用 `plugins.slots` 選擇哪個 plugin 擁有插槽：

```json5
{
  plugins: {
    slots: {
      memory: "memory-core", // or "none" to disable memory plugins
      contextEngine: "legacy", // or a plugin id such as "lossless-claw"
    },
  },
}
```

支援的獨佔插槽：

- `memory`：活躍的記憶體 plugin（`"none"` 停用記憶體 plugins）
- `contextEngine`：活躍的 context 引擎 plugin（`"legacy"` 是內建的預設值）

若多個 plugins 宣告 `kind: "memory"` 或 `kind: "context-engine"`，只有選定的 plugin 載入該插槽。其他的以診斷方式停用。

### Context 引擎 plugins

Context 引擎 plugins 擁有 session context 協調，用於攝取、組裝和壓縮。從你的 plugin 以 `api.registerContextEngine(id, factory)` 註冊它們，然後以 `plugins.slots.contextEngine` 選擇活躍的引擎。

當你的 plugin 需要替換或擴充預設 context 管道而不僅僅是新增記憶體搜尋或 hooks 時，請使用此功能。

## 控制 UI（schema + 標籤）

控制 UI 使用 `config.schema`（JSON Schema + `uiHints`）來渲染更好的表單。

OpenClaw 在執行期根據探索到的 plugins 擴充 `uiHints`：

- 為 `plugins.entries.<id>` / `.enabled` / `.config` 新增每個 plugin 的標籤
- 在以下位置合併可選的 plugin 提供的設定欄位提示：
  `plugins.entries.<id>.config.<field>`

若你想要你的 plugin 設定欄位顯示良好的標籤/佔位符（並將密鑰標記為敏感），請在 plugin manifest 中的 JSON Schema 旁邊提供 `uiHints`。

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
openclaw plugins install <path>                 # copy a local file/dir into ~/.openclaw/extensions/<id>
openclaw plugins install ./extensions/voice-call # relative path ok
openclaw plugins install ./plugin.tgz           # install from a local tarball
openclaw plugins install ./plugin.zip           # install from a local zip
openclaw plugins install -l ./extensions/voice-call # link (no copy) for dev
openclaw plugins install @openclaw/voice-call # install from npm
openclaw plugins install @openclaw/voice-call --pin # store exact resolved name@version
openclaw plugins update <id>
openclaw plugins update --all
openclaw plugins enable <id>
openclaw plugins disable <id>
openclaw plugins doctor
```

`plugins update` 僅適用於在 `plugins.installs` 下追蹤的 npm 安裝。
若儲存的完整性元資料在更新之間發生變化，OpenClaw 會警告並要求確認（使用全域 `--yes` 略過提示）。

Plugins 也可以註冊自己的頂層命令（範例：`openclaw voicecall`）。

## Plugin API（概覽）

Plugins 匯出以下其中一種：

- 函式：`(api) => { ... }`
- 物件：`{ id, name, configSchema, register(api) { ... } }`

Context 引擎 plugins 也可以註冊執行期擁有的 context 管理器：

```ts
export default function (api) {
  api.registerContextEngine("lossless-claw", () => ({
    info: { id: "lossless-claw", name: "Lossless Claw", ownsCompaction: true },
    async ingest() {
      return { ingested: true };
    },
    async assemble({ messages }) {
      return { messages, estimatedTokens: 0 };
    },
    async compact() {
      return { ok: true, compacted: false };
    },
  }));
}
```

然後在設定中啟用它：

```json5
{
  plugins: {
    slots: {
      contextEngine: "lossless-claw",
    },
  },
}
```

## Plugin hooks

Plugins 可以在執行期註冊 hooks。這讓 plugin 可以附帶事件驅動的自動化，而無需單獨的 hook 套件安裝。

### 範例

```ts
export default function register(api) {
  api.registerHook(
    "command:new",
    async () => {
      // Hook logic here.
    },
    {
      name: "my-plugin.command-new",
      description: "Runs when /new is invoked",
    },
  );
}
```

注意事項：

- 透過 `api.registerHook(...)` 明確註冊 hooks。
- Hook 資格規則仍然適用（OS/bins/env/config 需求）。
- Plugin 管理的 hooks 在 `openclaw hooks list` 中以 `plugin:<id>` 顯示。
- 你無法透過 `openclaw hooks` 啟用/停用 plugin 管理的 hooks；請改為啟用/停用 plugin。

### Agent 生命週期 hooks（`api.on`）

對於類型化的執行期生命週期 hooks，請使用 `api.on(...)`：

```ts
export default function register(api) {
  api.on(
    "before_prompt_build",
    (event, ctx) => {
      return {
        prependSystemContext: "Follow company style guide.",
      };
    },
    { priority: 10 },
  );
}
```

用於 prompt 建構的重要 hooks：

- `before_model_resolve`：在 session 載入前執行（`messages` 不可用）。使用此 hook 確定性地覆寫 `modelOverride` 或 `providerOverride`。
- `before_prompt_build`：在 session 載入後執行（`messages` 可用）。使用此 hook 塑造 prompt 輸入。
- `before_agent_start`：舊版相容性 hook。建議使用以上兩個明確的 hooks。

核心強制的 hook 政策：

- 操作者可以透過 `plugins.entries.<id>.hooks.allowPromptInjection: false` 按 plugin 停用 prompt 修改 hooks。
- 停用後，OpenClaw 封鎖 `before_prompt_build`，並忽略從舊版 `before_agent_start` 回傳的 prompt 修改欄位，同時保留舊版 `modelOverride` 和 `providerOverride`。

`before_prompt_build` 結果欄位：

- `prependContext`：在此次執行的使用者提示前添加文字。最適合用於輪次特定或動態內容。
- `systemPrompt`：完整的 system prompt 覆寫。
- `prependSystemContext`：在目前 system prompt 前添加文字。
- `appendSystemContext`：在目前 system prompt 後附加文字。

嵌入式執行期中的 prompt 建構順序：

1. 將 `prependContext` 套用至使用者提示。
2. 提供時套用 `systemPrompt` 覆寫。
3. 套用 `prependSystemContext + 目前 system prompt + appendSystemContext`。

合併和優先順序注意事項：

- Hook 處理器按優先順序執行（較高的先執行）。
- 對於合併的 context 欄位，值按執行順序串聯。
- `before_prompt_build` 值在舊版 `before_agent_start` 備用值之前套用。

遷移指南：

- 將靜態指南從 `prependContext` 移至 `prependSystemContext`（或 `appendSystemContext`），使提供者可以快取穩定的 system-prefix 內容。
- 對於應與使用者訊息綁定的每輪動態 context，保持使用 `prependContext`。

## 提供者 plugins（模型認證）

Plugins 可以註冊**模型提供者認證**流程，使使用者可以在 OpenClaw 內執行 OAuth 或 API 金鑰設定（無需外部腳本）。

透過 `api.registerProvider(...)` 註冊提供者。每個提供者公開一種或多種認證方法（OAuth、API 金鑰、裝置代碼等）。這些方法支援：

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
        // Run OAuth flow and return auth profiles.
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

- `run` 接收帶有 `prompter`、`runtime`、`openUrl` 和 `oauth.createVpsAwareHandlers` 輔助工具的 `ProviderAuthContext`。
- 當你需要新增預設模型或提供者設定時回傳 `configPatch`。
- 回傳 `defaultModel` 使 `--set-default` 可以更新 agent 預設值。

### 註冊訊息頻道

Plugins 可以註冊**頻道 plugins**，其行為類似內建頻道（WhatsApp、Telegram 等）。頻道設定位於 `channels.<id>` 下，並由你的頻道 plugin 程式碼驗證。

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
      cfg.channels?.acmechat?.accounts?.[accountId ?? "default"] ?? {
        accountId,
      },
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

- 將設定放在 `channels.<id>` 下（而非 `plugins.entries`）。
- `meta.label` 用於 CLI/UI 列表中的標籤。
- `meta.aliases` 為正規化和 CLI 輸入新增替代 id。
- `meta.preferOver` 列出在兩者都設定時跳過自動啟用的頻道 id。
- `meta.detailLabel` 和 `meta.systemImage` 讓 UI 顯示更豐富的頻道標籤/圖示。

### 頻道 onboarding hooks

頻道 plugins 可以在 `plugin.onboarding` 上定義可選的 onboarding hooks：

- `configure(ctx)` 是基準設定流程。
- `configureInteractive(ctx)` 可以完全擁有已設定和未設定狀態的互動設定。
- `configureWhenConfigured(ctx)` 只能覆寫已設定頻道的行為。

精靈中的 hook 優先順序：

1. `configureInteractive`（若存在）
2. `configureWhenConfigured`（僅當頻道狀態已設定時）
3. 備用至 `configure`

Context 詳細資訊：

- `configureInteractive` 和 `configureWhenConfigured` 接收：
  - `configured`（`true` 或 `false`）
  - `label`（提示使用的面向使用者的頻道名稱）
  - 加上共用的 config/runtime/prompter/options 欄位
- 回傳 `"skip"` 保持選擇和帳戶追蹤不變。
- 回傳 `{ cfg, accountId? }` 套用設定更新並記錄帳戶選擇。

### 撰寫新的訊息頻道（逐步）

當你想要一個**新的聊天介面**（「訊息頻道」）而非模型提供者時使用此方法。
模型提供者文件位於 `/providers/*` 下。

1. 選擇 id + 設定形狀

- 所有頻道設定位於 `channels.<id>` 下。
- 對於多帳戶設定，建議使用 `channels.<id>.accounts.<accountId>`。

2. 定義頻道元資料

- `meta.label`、`meta.selectionLabel`、`meta.docsPath`、`meta.blurb` 控制 CLI/UI 列表。
- `meta.docsPath` 應指向 `/channels/<id>` 等文件頁面。
- `meta.preferOver` 讓 plugin 替換另一個頻道（自動啟用建議它）。
- `meta.detailLabel` 和 `meta.systemImage` 由 UI 用於詳細文字/圖示。

3. 實作必要的適配器

- `config.listAccountIds` + `config.resolveAccount`
- `capabilities`（聊天類型、媒體、執行緒等）
- `outbound.deliveryMode` + `outbound.sendText`（用於基本發送）

4. 根據需要新增可選適配器

- `setup`（精靈）、`security`（DM 政策）、`status`（健康/診斷）
- `gateway`（啟動/停止/登入）、`mentions`、`threading`、`streaming`
- `actions`（訊息動作）、`commands`（原生命令行為）

5. 在你的 plugin 中註冊頻道

- `api.registerChannel({ plugin })`

最小設定範例：

```json5
{
  channels: {
    acmechat: {
      accounts: {
        default: { token: "ACME_TOKEN", enabled: true },
      },
    },
  },
}
```

最小頻道 plugin（僅輸出）：

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
  capabilities: { chatTypes: ["direct"] },
  config: {
    listAccountIds: (cfg) => Object.keys(cfg.channels?.acmechat?.accounts ?? {}),
    resolveAccount: (cfg, accountId) =>
      cfg.channels?.acmechat?.accounts?.[accountId ?? "default"] ?? {
        accountId,
      },
  },
  outbound: {
    deliveryMode: "direct",
    sendText: async ({ text }) => {
      // deliver `text` to your channel here
      return { ok: true };
    },
  },
};

export default function (api) {
  api.registerChannel({ plugin });
}
```

載入 plugin（extensions 目錄或 `plugins.load.paths`），重啟 gateway，然後在你的設定中設定 `channels.<id>`。

### Agent 工具

請參閱專用指南：[Plugin agent tools](/zh-Hant/plugins/agent-tools)。

### 註冊 gateway RPC 方法

```ts
export default function (api) {
  api.registerGatewayMethod("myplugin.status", ({ respond }) => {
    respond(true, { ok: true });
  });
}
```

### 註冊 CLI 命令

```ts
export default function (api) {
  api.registerCli(
    ({ program }) => {
      program.command("mycmd").action(() => {
        console.log("Hello");
      });
    },
    { commands: ["mycmd"] },
  );
}
```

### 註冊自動回覆命令

Plugins 可以註冊**無需呼叫 AI agent** 即可執行的自訂斜線命令。這對於切換命令、狀態檢查或不需要 LLM 處理的快速動作非常有用。

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

命令處理器 context：

- `senderId`：發送者的 ID（若可用）
- `channel`：發送命令的頻道
- `isAuthorizedSender`：發送者是否為已授權的使用者
- `args`：命令後傳遞的參數（若 `acceptsArgs: true`）
- `commandBody`：完整的命令文字
- `config`：目前的 OpenClaw 設定

命令選項：

- `name`：命令名稱（不含前導 `/`）
- `nativeNames`：斜線/選單介面的可選原生命令別名。使用 `default` 用於所有原生提供者，或使用提供者特定鍵，例如 `discord`
- `description`：在命令列表中顯示的說明文字
- `acceptsArgs`：命令是否接受參數（預設：false）。若為 false 且提供了參數，命令不會匹配，訊息會傳遞給其他處理器
- `requireAuth`：是否需要已授權的發送者（預設：true）
- `handler`：回傳 `{ text: string }` 的函式（可以是 async）

帶有授權和參數的範例：

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

- Plugin 命令在**內建命令和 AI agent 之前**處理
- 命令全域註冊，在所有頻道中有效
- 命令名稱不區分大小寫（`/MyStatus` 匹配 `/mystatus`）
- 命令名稱必須以字母開頭，且只包含字母、數字、連字號和底線
- 保留的命令名稱（例如 `help`、`status`、`reset` 等）無法被 plugins 覆寫
- 跨 plugins 的重複命令註冊會失敗並產生診斷錯誤

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

- Gateway 方法：`pluginId.action`（範例：`voicecall.status`）
- 工具：`snake_case`（範例：`voice_call`）
- CLI 命令：kebab 或 camel，但避免與核心命令衝突

## Skills

Plugins 可以在 repo 中附帶 skill（`skills/<name>/SKILL.md`）。
以 `plugins.entries.<id>.enabled`（或其他設定閘控）啟用它，並確保它存在於你的工作區/受管 skills 位置。

## 發布（npm）

推薦的套件方式：

- 主套件：`openclaw`（此 repo）
- Plugins：在 `@openclaw/*` 下的獨立 npm 套件（範例：`@openclaw/voice-call`）

發布契約：

- Plugin `package.json` 必須包含帶有一個或多個入口檔案的 `openclaw.extensions`。
- 入口檔案可以是 `.js` 或 `.ts`（jiti 在執行期載入 TS）。
- `openclaw plugins install <npm-spec>` 使用 `npm pack`，解壓縮至 `~/.openclaw/extensions/<id>/`，並在設定中啟用它。
- 設定鍵穩定性：帶作用域的套件被標準化為 **unscoped** id 用於 `plugins.entries.*`。

## 範例 plugin：Voice Call

此 repo 包含一個語音呼叫 plugin（Twilio 或 log 備用）：

- 來源：`extensions/voice-call`
- Skill：`skills/voice-call`
- CLI：`openclaw voicecall start|status`
- 工具：`voice_call`
- RPC：`voicecall.start`、`voicecall.status`
- 設定（twilio）：`provider: "twilio"` + `twilio.accountSid/authToken/from`（可選 `statusCallbackUrl`、`twimlUrl`）
- 設定（dev）：`provider: "log"`（無網路）

請參閱 [Voice Call](/zh-Hant/plugins/voice-call) 和 `extensions/voice-call/README.md` 了解設定和使用方式。

## 安全注意事項

Plugins 與 Gateway 在同一行程中執行。將其視為受信任的程式碼：

- 只安裝你信任的 plugins。
- 建議使用 `plugins.allow` 允許清單。
- 變更後重啟 Gateway。

## 測試 plugins

Plugins 可以（也應該）附帶測試：

- repo 內的 plugins 可以在 `src/**` 下保留 Vitest 測試（範例：`src/plugins/voice-call.plugin.test.ts`）。
- 單獨發布的 plugins 應執行自己的 CI（lint/build/test）並驗證 `openclaw.extensions` 指向已建構的入口點（`dist/index.js`）。
