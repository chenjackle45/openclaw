---
title: "Plugin Runtime Helpers（Plugin Runtime 輔助函式）"
sidebarTitle: "Runtime 輔助函式"
summary: "api.runtime -- the injected runtime helpers available to plugins（可用於外掛的注入 runtime 輔助函式）"
read_when:
  - 你需要從外掛呼叫核心輔助函式（TTS、STT、圖像生成、網路搜尋、subagent）
  - 你想理解 api.runtime 公開的內容
  - 你正在從外掛代碼存取 config、agent 或 media 輔助函式
---

# Plugin Runtime Helpers

在註冊期間注入每個外掛的 `api.runtime` 物件的參考。使用這些輔助函式，而不是直接 import 主機內部。

<Tip>
  **在找實作指南？** 參考 [Channel 外掛](/zh-Hant/plugins/sdk-channel-plugins) 或 [Provider 外掛](/zh-Hant/plugins/sdk-provider-plugins)，他們有逐步指南，展示這些輔助函式的實際使用。
</Tip>

```typescript
register(api) {
  const runtime = api.runtime;
}
```

## Runtime namespace

### `api.runtime.agent`

Agent 身分、目錄與工作階段管理。

```typescript
// 解析 agent 的工作目錄
const agentDir = api.runtime.agent.resolveAgentDir(cfg);

// 解析 agent 工作區
const workspaceDir = api.runtime.agent.resolveAgentWorkspaceDir(cfg);

// 取得 agent 身分
const identity = api.runtime.agent.resolveAgentIdentity(cfg);

// 取得預設 thinking 等級
const thinking = api.runtime.agent.resolveThinkingDefault(cfg, provider, model);

// 取得 agent 逾時
const timeoutMs = api.runtime.agent.resolveAgentTimeoutMs(cfg);

// 確保工作區存在
await api.runtime.agent.ensureAgentWorkspace(cfg);

// 執行嵌入式 Pi agent
const agentDir = api.runtime.agent.resolveAgentDir(cfg);
const result = await api.runtime.agent.runEmbeddedPiAgent({
  sessionId: "my-plugin:task-1",
  runId: crypto.randomUUID(),
  sessionFile: path.join(agentDir, "sessions", "my-plugin-task-1.jsonl"),
  workspaceDir: api.runtime.agent.resolveAgentWorkspaceDir(cfg),
  prompt: "總結最新的變更",
  timeoutMs: api.runtime.agent.resolveAgentTimeoutMs(cfg),
});
```

**Session store 輔助函式** 在 `api.runtime.agent.session` 下：

```typescript
const storePath = api.runtime.agent.session.resolveStorePath(cfg);
const store = api.runtime.agent.session.loadSessionStore(cfg);
await api.runtime.agent.session.saveSessionStore(cfg, store);
const filePath = api.runtime.agent.session.resolveSessionFilePath(cfg, sessionId);
```

### `api.runtime.agent.defaults`

預設模型與 provider 常數：

```typescript
const model = api.runtime.agent.defaults.model; // 例如 "anthropic/claude-sonnet-4-6"
const provider = api.runtime.agent.defaults.provider; // 例如 "anthropic"
```

### `api.runtime.subagent`

啟動與管理背景 subagent 執行。

```typescript
// 啟動 subagent 執行
const { runId } = await api.runtime.subagent.run({
  sessionKey: "agent:main:subagent:search-helper",
  message: "將此查詢擴展為專注的後續搜尋。",
  provider: "openai", // 可選覆蓋
  model: "gpt-4.1-mini", // 可選覆蓋
  deliver: false,
});

// 等待完成
const result = await api.runtime.subagent.waitForRun({ runId, timeoutMs: 30000 });

// 讀取工作階段訊息
const { messages } = await api.runtime.subagent.getSessionMessages({
  sessionKey: "agent:main:subagent:search-helper",
  limit: 10,
});

// 刪除工作階段
await api.runtime.subagent.deleteSession({
  sessionKey: "agent:main:subagent:search-helper",
});
```

<Warning>
  模型覆蓋（`provider`/`model`）需要操作者透過 config 中的 `plugins.entries.<id>.subagent.allowModelOverride: true` 選擇加入。不受信任的外掛仍可執行 subagent，但覆蓋請求會被拒絕。
</Warning>

### `api.runtime.tts`

文字轉語音合成。

```typescript
// 標準 TTS
const clip = await api.runtime.tts.textToSpeech({
  text: "Hello from OpenClaw",
  cfg: api.config,
});

// 電話優化 TTS
const telephonyClip = await api.runtime.tts.textToSpeechTelephony({
  text: "Hello from OpenClaw",
  cfg: api.config,
});

// 列出可用語音
const voices = await api.runtime.tts.listVoices({
  provider: "elevenlabs",
  cfg: api.config,
});
```

使用核心 `messages.tts` 設定與 provider 選擇。傳回 PCM audio buffer + sample rate。

### `api.runtime.mediaUnderstanding`

影像、音訊與影片分析。

```typescript
// 描述影像
const image = await api.runtime.mediaUnderstanding.describeImageFile({
  filePath: "/tmp/inbound-photo.jpg",
  cfg: api.config,
  agentDir: "/tmp/agent",
});

// 轉錄音訊
const { text } = await api.runtime.mediaUnderstanding.transcribeAudioFile({
  filePath: "/tmp/inbound-audio.ogg",
  cfg: api.config,
  mime: "audio/ogg", // 可選，當無法推斷 MIME 時使用
});

// 描述影片
const video = await api.runtime.mediaUnderstanding.describeVideoFile({
  filePath: "/tmp/inbound-video.mp4",
  cfg: api.config,
});

// 泛用檔案分析
const result = await api.runtime.mediaUnderstanding.runFile({
  filePath: "/tmp/inbound-file.pdf",
  cfg: api.config,
});
```

當無產出時傳回 `{ text: undefined }`（例如跳過的輸入）。

<Info>
  `api.runtime.stt.transcribeAudioFile(...)` 作為相容別名保留，對應 `api.runtime.mediaUnderstanding.transcribeAudioFile(...)`。
</Info>

### `api.runtime.imageGeneration`

影像生成。

```typescript
const result = await api.runtime.imageGeneration.generate({
  prompt: "一個機器人繪製日落",
  cfg: api.config,
});

const providers = api.runtime.imageGeneration.listProviders({ cfg: api.config });
```

### `api.runtime.webSearch`

網路搜尋。

```typescript
const providers = api.runtime.webSearch.listProviders({ config: api.config });

const result = await api.runtime.webSearch.search({
  config: api.config,
  args: { query: "OpenClaw plugin SDK", count: 5 },
});
```

### `api.runtime.media`

低階 media 工具。

```typescript
const webMedia = await api.runtime.media.loadWebMedia(url);
const mime = await api.runtime.media.detectMime(buffer);
const kind = api.runtime.media.mediaKindFromMime("image/jpeg"); // "image"
const isVoice = api.runtime.media.isVoiceCompatibleAudio(filePath);
const metadata = await api.runtime.media.getImageMetadata(filePath);
const resized = await api.runtime.media.resizeToJpeg(buffer, { maxWidth: 800 });
```

### `api.runtime.config`

Config 載入與寫入。

```typescript
const cfg = await api.runtime.config.loadConfig();
await api.runtime.config.writeConfigFile(cfg);
```

### `api.runtime.system`

系統級工具。

```typescript
await api.runtime.system.enqueueSystemEvent(event);
api.runtime.system.requestHeartbeatNow();
const output = await api.runtime.system.runCommandWithTimeout(cmd, args, opts);
const hint = api.runtime.system.formatNativeDependencyHint(pkg);
```

### `api.runtime.events`

Event 訂閱。

```typescript
api.runtime.events.onAgentEvent((event) => {
  /* ... */
});
api.runtime.events.onSessionTranscriptUpdate((update) => {
  /* ... */
});
```

### `api.runtime.logging`

記錄。

```typescript
const verbose = api.runtime.logging.shouldLogVerbose();
const childLogger = api.runtime.logging.getChildLogger({ plugin: "my-plugin" }, { level: "debug" });
```

### `api.runtime.modelAuth`

模型與 provider auth 解析。

```typescript
const auth = await api.runtime.modelAuth.getApiKeyForModel({ model, cfg });
const providerAuth = await api.runtime.modelAuth.resolveApiKeyForProvider({
  provider: "openai",
  cfg,
});
```

### `api.runtime.state`

State 目錄解析。

```typescript
const stateDir = api.runtime.state.resolveStateDir();
```

### `api.runtime.tools`

Memory tool factories 與 CLI。

```typescript
const getTool = api.runtime.tools.createMemoryGetTool(/* ... */);
const searchTool = api.runtime.tools.createMemorySearchTool(/* ... */);
api.runtime.tools.registerMemoryCli(/* ... */);
```

### `api.runtime.channel`

Channel 特定 runtime 輔助函式（當 channel 外掛載入時可用）。

## 儲存 runtime 參考

使用 `createPluginRuntimeStore` 來儲存 runtime 參考，供 `register` 回調外使用：

```typescript
import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";
import type { PluginRuntime } from "openclaw/plugin-sdk/runtime-store";

const store = createPluginRuntimeStore<PluginRuntime>("my-plugin runtime 未初始化");

// 在妳的進入點
export default defineChannelPluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "範例",
  plugin: myPlugin,
  setRuntime: store.setRuntime,
});

// 在其他檔案
export function getRuntime() {
  return store.getRuntime(); // 未初始化時拋出
}

export function tryGetRuntime() {
  return store.tryGetRuntime(); // 未初始化時傳回 null
}
```

## 其他頂層 `api` 欄位

除了 `api.runtime`，API 物件也提供：

| 欄位                     | 型別                      | 說明                                                |
| ------------------------ | ------------------------- | --------------------------------------------------- |
| `api.id`                 | `string`                  | 外掛 id                                             |
| `api.name`               | `string`                  | 外掛顯示名稱                                        |
| `api.config`             | `OpenClawConfig`          | 目前 config 快照                                    |
| `api.pluginConfig`       | `Record<string, unknown>` | 外掛特定 config，來自 `plugins.entries.<id>.config` |
| `api.logger`             | `PluginLogger`            | 範疇化 logger（`debug`, `info`, `warn`, `error`）   |
| `api.registrationMode`   | `PluginRegistrationMode`  | `"full"`、`"setup-only"` 或 `"setup-runtime"`       |
| `api.resolvePath(input)` | `(string) => string`      | 解析相對於外掛根的路徑                              |

## 相關

- [SDK 概述](/zh-Hant/plugins/sdk-overview) -- subpath 參考
- [SDK 進入點](/zh-Hant/plugins/sdk-entrypoints) -- `definePluginEntry` 選項
- [外掛內部](/zh-Hant/plugins/architecture) -- 能力模型與註冊表
