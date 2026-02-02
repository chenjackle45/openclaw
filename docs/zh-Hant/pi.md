---
title: "Pi 整合架構"
---

# Pi 整合架構

本文檔描述 OpenClaw 如何與 [pi-coding-agent](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) 及其相關套件（`pi-ai`、`pi-agent-core`、`pi-tui`）整合，以驅動其 AI 代理功能。

## 概覽

OpenClaw 使用 pi SDK 將 AI 編碼代理嵌入其訊息閘道架構中。OpenClaw 不是將 pi 作為子程序執行或使用 RPC 模式，而是直接透過 `createAgentSession()` 匯入和實例化 pi 的 `AgentSession`。這種嵌入式方法提供以下優勢：

- 完全控制會話生命週期和事件處理
- 自訂工具注入（訊息、沙盒、通道特定的操作）
- 根據通道／上下文自訂系統提示
- 支援分支和壓縮的會話持久化
- 多帳戶驗證設定檔輪換與故障轉移
- 無關廠商的模型切換

## 套件依賴

```json
{
  "@mariozechner/pi-agent-core": "0.49.3",
  "@mariozechner/pi-ai": "0.49.3",
  "@mariozechner/pi-coding-agent": "0.49.3",
  "@mariozechner/pi-tui": "0.49.3"
}
```

| 套件              | 用途                                                                      |
| ----------------- | ------------------------------------------------------------------------- |
| `pi-ai`           | 核心 LLM 抽象：`Model`、`streamSimple`、訊息類型、提供商 API             |
| `pi-agent-core`   | 代理循環、工具執行、`AgentMessage` 類型                                  |
| `pi-coding-agent` | 高層級 SDK：`createAgentSession`、`SessionManager`、`AuthStorage` 等     |
| `pi-tui`          | 終端機 UI 元件（用於 OpenClaw 本地 TUI 模式）                            |

## 文件結構

```
src/agents/
├── pi-embedded-runner.ts          # 從 pi-embedded-runner/ 重新匯出
├── pi-embedded-runner/
│   ├── run.ts                     # 主入口：runEmbeddedPiAgent()
│   ├── run/
│   │   ├── attempt.ts             # 單次嘗試邏輯與會話設置
│   │   ├── params.ts              # RunEmbeddedPiAgentParams 類型
│   │   ├── payloads.ts            # 從執行結果構建回應載荷
│   │   ├── images.ts              # 視覺模型影像注入
│   │   └── types.ts               # EmbeddedRunAttemptResult
│   ├── abort.ts                   # 中止錯誤偵測
│   ├── cache-ttl.ts               # 用於上下文修剪的快取 TTL 追蹤
│   ├── compact.ts                 # 手動／自動壓縮邏輯
│   ├── extensions.ts              # 載入嵌入式執行的 pi 擴充功能
│   ├── extra-params.ts            # 廠商特定的串流參數
│   ├── google.ts                  # Google/Gemini 輪次排序修正
│   ├── history.ts                 # 歷史限制（DM vs 群組）
│   ├── lanes.ts                   # 會話／全域指令通道
│   ├── logger.ts                  # 子系統日誌程式
│   ├── model.ts                   # 透過 ModelRegistry 的模型解析
│   ├── runs.ts                    # 主動執行追蹤、中止、佇列
│   ├── sandbox-info.ts            # 系統提示的沙盒資訊
│   ├── session-manager-cache.ts   # SessionManager 實例快取
│   ├── session-manager-init.ts    # 會話檔案初始化
│   ├── system-prompt.ts           # 系統提示構建器
│   ├── tool-split.ts              # 將工具分割為內建與自訂
│   ├── types.ts                   # EmbeddedPiAgentMeta、EmbeddedPiRunResult
│   └── utils.ts                   # ThinkLevel 對應、錯誤描述
├── pi-embedded-subscribe.ts       # 會話事件訂閱／分發
├── pi-embedded-subscribe.types.ts # SubscribeEmbeddedPiSessionParams
├── pi-embedded-subscribe.handlers.ts # 事件處理器工廠
├── pi-embedded-subscribe.handlers.lifecycle.ts
├── pi-embedded-subscribe.handlers.types.ts
├── pi-embedded-block-chunker.ts   # 串流區塊回應分塊
├── pi-embedded-messaging.ts       # 訊息工具已傳送追蹤
├── pi-embedded-helpers.ts         # 錯誤分類、輪次驗證
├── pi-embedded-helpers/           # 輔助模組
├── pi-embedded-utils.ts           # 格式化工具
├── pi-tools.ts                    # createOpenClawCodingTools()
├── pi-tools.abort.ts              # 工具 AbortSignal 包裝
├── pi-tools.policy.ts             # 工具允許列表／拒絕列表原則
├── pi-tools.read.ts               # 讀取工具自訂
├── pi-tools.schema.ts             # 工具模式標準化
├── pi-tools.types.ts              # AnyAgentTool 類型別名
├── pi-tool-definition-adapter.ts  # AgentTool → ToolDefinition 轉接器
├── pi-settings.ts                 # 設定覆蓋
├── pi-extensions/                 # 自訂 pi 擴充功能
│   ├── compaction-safeguard.ts    # 保護擴充功能
│   ├── compaction-safeguard-runtime.ts
│   ├── context-pruning.ts         # 快取 TTL 上下文修剪擴充功能
│   └── context-pruning/
├── model-auth.ts                  # 驗證設定檔解析
├── auth-profiles.ts               # 設定檔存放區、冷卻時間、故障轉移
├── model-selection.ts             # 預設模型解析
├── models-config.ts               # models.json 生成
├── model-catalog.ts               # 模型目錄快取
├── context-window-guard.ts        # 上下文視窗驗證
├── failover-error.ts              # FailoverError 類別
├── defaults.ts                    # DEFAULT_PROVIDER、DEFAULT_MODEL
├── system-prompt.ts               # buildAgentSystemPrompt()
├── system-prompt-params.ts        # 系統提示參數解析
├── system-prompt-report.ts        # 除錯報告生成
├── tool-summaries.ts              # 工具描述摘要
├── tool-policy.ts                 # 工具原則解析
├── transcript-policy.ts           # 謄本驗證原則
├── skills.ts                      # 技能快照／提示構建
├── skills/                        # 技能子系統
├── sandbox.ts                     # 沙盒上下文解析
├── sandbox/                       # 沙盒子系統
├── channel-tools.ts               # 通道特定工具注入
├── openclaw-tools.ts              # OpenClaw 特定工具
├── bash-tools.ts                  # exec/process 工具
├── apply-patch.ts                 # apply_patch 工具 (OpenAI)
├── tools/                         # 個別工具實作
│   ├── browser-tool.ts
│   ├── canvas-tool.ts
│   ├── cron-tool.ts
│   ├── discord-actions*.ts
│   ├── gateway-tool.ts
│   ├── image-tool.ts
│   ├── message-tool.ts
│   ├── nodes-tool.ts
│   ├── session*.ts
│   ├── slack-actions.ts
│   ├── telegram-actions.ts
│   ├── web-*.ts
│   └── whatsapp-actions.ts
└── ...
```

## 核心整合流程

### 1. 執行嵌入式代理

主入口是 `pi-embedded-runner/run.ts` 中的 `runEmbeddedPiAgent()`：

```typescript
import { runEmbeddedPiAgent } from "./agents/pi-embedded-runner.js";

const result = await runEmbeddedPiAgent({
  sessionId: "user-123",
  sessionKey: "main:whatsapp:+1234567890",
  sessionFile: "/path/to/session.jsonl",
  workspaceDir: "/path/to/workspace",
  config: openclawConfig,
  prompt: "Hello, how are you?",
  provider: "anthropic",
  model: "claude-sonnet-4-20250514",
  timeoutMs: 120_000,
  runId: "run-abc",
  onBlockReply: async (payload) => {
    await sendToChannel(payload.text, payload.mediaUrls);
  },
});
```

### 2. 會話建立

在 `runEmbeddedAttempt()` 內（由 `runEmbeddedPiAgent()` 呼叫），使用 pi SDK：

```typescript
import {
  createAgentSession,
  DefaultResourceLoader,
  SessionManager,
  SettingsManager,
} from "@mariozechner/pi-coding-agent";

const resourceLoader = new DefaultResourceLoader({
  cwd: resolvedWorkspace,
  agentDir,
  settingsManager,
  additionalExtensionPaths,
});
await resourceLoader.reload();

const { session } = await createAgentSession({
  cwd: resolvedWorkspace,
  agentDir,
  authStorage: params.authStorage,
  modelRegistry: params.modelRegistry,
  model: params.model,
  thinkingLevel: mapThinkingLevel(params.thinkLevel),
  tools: builtInTools,
  customTools: allCustomTools,
  sessionManager,
  settingsManager,
  resourceLoader,
});

applySystemPromptOverrideToSession(session, systemPromptOverride);
```

### 3. 事件訂閱

`subscribeEmbeddedPiSession()` 訂閱 pi 的 `AgentSession` 事件：

```typescript
const subscription = subscribeEmbeddedPiSession({
  session: activeSession,
  runId: params.runId,
  verboseLevel: params.verboseLevel,
  reasoningMode: params.reasoningLevel,
  toolResultFormat: params.toolResultFormat,
  onToolResult: params.onToolResult,
  onReasoningStream: params.onReasoningStream,
  onBlockReply: params.onBlockReply,
  onPartialReply: params.onPartialReply,
  onAgentEvent: params.onAgentEvent,
});
```

處理的事件包括：

- `message_start` / `message_end` / `message_update`（串流文字／思考過程）
- `tool_execution_start` / `tool_execution_update` / `tool_execution_end`
- `turn_start` / `turn_end`
- `agent_start` / `agent_end`
- `auto_compaction_start` / `auto_compaction_end`

### 4. 提示

設置完成後，會話被提示：

```typescript
await session.prompt(effectivePrompt, { images: imageResult.images });
```

SDK 處理完整的代理循環：發送至 LLM、執行工具呼叫、串流回應。

## 工具架構

### 工具管線

1. **基礎工具**：pi 的 `codingTools`（read、bash、edit、write）
2. **自訂替代**：OpenClaw 用 `exec`／`process` 替代 bash，為沙盒自訂 read/edit/write
3. **OpenClaw 工具**：訊息、瀏覽器、畫布、會話、cron、閘道等
4. **通道工具**：Discord/Telegram/Slack/WhatsApp 特定的操作工具
5. **原則篩選**：根據設定檔、提供商、代理、群組、沙盒原則篩選工具
6. **模式標準化**：為 Gemini/OpenAI 怪癖清理模式
7. **AbortSignal 包裝**：包裝工具以遵守中止信號

### 工具定義轉接器

pi-agent-core 的 `AgentTool` 與 pi-coding-agent 的 `ToolDefinition` 具有不同的 `execute` 簽章。`pi-tool-definition-adapter.ts` 中的轉接器橋接這個問題：

```typescript
export function toToolDefinitions(tools: AnyAgentTool[]): ToolDefinition[] {
  return tools.map((tool) => ({
    name: tool.name,
    label: tool.label ?? name,
    description: tool.description ?? "",
    parameters: tool.parameters,
    execute: async (toolCallId, params, onUpdate, _ctx, signal) => {
      // pi-coding-agent 簽章不同於 pi-agent-core
      return await tool.execute(toolCallId, params, signal, onUpdate);
    },
  }));
}
```

### 工具分割策略

`splitSdkTools()` 透過 `customTools` 傳遞所有工具：

```typescript
export function splitSdkTools(options: { tools: AnyAgentTool[]; sandboxEnabled: boolean }) {
  return {
    builtInTools: [], // 空白。我們覆蓋一切
    customTools: toToolDefinitions(options.tools),
  };
}
```

這確保 OpenClaw 的原則篩選、沙盒整合和擴展工具集在所有提供商間保持一致。

## 系統提示構建

系統提示在 `buildAgentSystemPrompt()`（`system-prompt.ts`）中構建。它組合完整提示，包含工具、工具呼叫風格、安全防護、OpenClaw CLI 參考、技能、文檔、工作區、沙盒、訊息、回覆標籤、語音、靜默回覆、心跳、執行時中繼資料，加上記憶和反應（啟用時），以及選擇性的上下文檔案和額外系統提示內容。章節針對子代理使用的最小提示模式進行修整。

提示透過 `applySystemPromptOverrideToSession()` 在會話建立後應用：

```typescript
const systemPromptOverride = createSystemPromptOverride(appendPrompt);
applySystemPromptOverrideToSession(session, systemPromptOverride);
```

## 會話管理

### 會話檔案

會話是具有樹狀結構（id/parentId 連結）的 JSONL 檔案。Pi 的 `SessionManager` 處理持久化：

```typescript
const sessionManager = SessionManager.open(params.sessionFile);
```

OpenClaw 使用 `guardSessionManager()` 包裝此項，以確保工具結果安全。

### 會話快取

`session-manager-cache.ts` 快取 SessionManager 實例，以避免重複的檔案解析：

```typescript
await prewarmSessionFile(params.sessionFile);
sessionManager = SessionManager.open(params.sessionFile);
trackSessionManagerAccess(params.sessionFile);
```

### 歷史限制

`limitHistoryTurns()` 根據通道類型（DM vs 群組）修整對話歷史。

### 壓縮

自動壓縮在上下文溢位時觸發。`compactEmbeddedPiSessionDirect()` 處理手動壓縮：

```typescript
const compactResult = await compactEmbeddedPiSessionDirect({
  sessionId, sessionFile, provider, model, ...
});
```

## 驗證與模型解析

### 驗證設定檔

OpenClaw 維護驗證設定檔存放區，每個提供商多個 API 金鑰：

```typescript
const authStore = ensureAuthProfileStore(agentDir, { allowKeychainPrompt: false });
const profileOrder = resolveAuthProfileOrder({ cfg, store: authStore, provider, preferredProfile });
```

設定檔在故障時輪換，並追蹤冷卻時間：

```typescript
await markAuthProfileFailure({ store, profileId, reason, cfg, agentDir });
const rotated = await advanceAuthProfile();
```

### 模型解析

```typescript
import { resolveModel } from "./pi-embedded-runner/model.js";

const { model, error, authStorage, modelRegistry } = resolveModel(
  provider,
  modelId,
  agentDir,
  config,
);

// 使用 pi 的 ModelRegistry 和 AuthStorage
authStorage.setRuntimeApiKey(model.provider, apiKeyInfo.apiKey);
```

### 故障轉移

`FailoverError` 在設定故障轉移時觸發模型後援：

```typescript
if (fallbackConfigured && isFailoverErrorMessage(errorText)) {
  throw new FailoverError(errorText, {
    reason: promptFailoverReason ?? "unknown",
    provider,
    model: modelId,
    profileId,
    status: resolveFailoverStatus(promptFailoverReason),
  });
}
```

## Pi 擴充功能

OpenClaw 載入自訂 pi 擴充功能以實現專門行為：

### 壓縮保護

`pi-extensions/compaction-safeguard.ts` 新增壓縮防護，包括自適應令牌預算及工具失敗和檔案操作摘要：

```typescript
if (resolveCompactionMode(params.cfg) === "safeguard") {
  setCompactionSafeguardRuntime(params.sessionManager, { maxHistoryShare });
  paths.push(resolvePiExtensionPath("compaction-safeguard"));
}
```

### 上下文修剪

`pi-extensions/context-pruning.ts` 實現基於快取 TTL 的上下文修剪：

```typescript
if (cfg?.agents?.defaults?.contextPruning?.mode === "cache-ttl") {
  setContextPruningRuntime(params.sessionManager, {
    settings,
    contextWindowTokens,
    isToolPrunable,
    lastCacheTouchAt,
  });
  paths.push(resolvePiExtensionPath("context-pruning"));
}
```

## 串流與區塊回應

### 區塊分塊

`EmbeddedBlockChunker` 管理將串流文字分段為離散回應區塊：

```typescript
const blockChunker = blockChunking ? new EmbeddedBlockChunker(blockChunking) : null;
```

### 思考／最終標籤剝離

串流輸出經過處理以剝離 `<think>`／`<thinking>` 區塊並提取 `<final>` 內容：

```typescript
const stripBlockTags = (text: string, state: { thinking: boolean; final: boolean }) => {
  // 剝離 <think>...</think> 內容
  // 如果 enforceFinalTag，僅傳回 <final>...</final> 內容
};
```

### 回覆指令

回覆指令如 `[[media:url]]`、`[[voice]]`、`[[reply:id]]` 被解析並提取：

```typescript
const { text: cleanedText, mediaUrls, audioAsVoice, replyToId } = consumeReplyDirectives(chunk);
```

## 錯誤處理

### 錯誤分類

`pi-embedded-helpers.ts` 分類錯誤以進行適當處理：

```typescript
isContextOverflowError(errorText)     // 上下文太大
isCompactionFailureError(errorText)   // 壓縮失敗
isAuthAssistantError(lastAssistant)   // 驗證失敗
isRateLimitAssistantError(...)        // 速率限制
isFailoverAssistantError(...)         // 應故障轉移
classifyFailoverReason(errorText)     // "auth" | "rate_limit" | "quota" | "timeout" | ...
```

### 思考等級後援

如果不支援思考等級，它將後援：

```typescript
const fallbackThinking = pickFallbackThinkingLevel({
  message: errorText,
  attempted: attemptedThinking,
});
if (fallbackThinking) {
  thinkLevel = fallbackThinking;
  continue;
}
```

## 沙盒整合

當沙盒模式啟用時，工具和路徑受到限制：

```typescript
const sandbox = await resolveSandboxContext({
  config: params.config,
  sessionKey: sandboxSessionKey,
  workspaceDir: resolvedWorkspace,
});

if (sandboxRoot) {
  // 使用沙盒化 read/edit/write 工具
  // Exec 在容器中執行
  // 瀏覽器使用橋接 URL
}
```

## 廠商特定處理

### Anthropic

- 拒絕魔法字符串清理
- 連續角色的輪次驗證
- Claude Code 參數相容性

### Google/Gemini

- 輪次排序修正（`applyGoogleTurnOrderingFix`）
- 工具模式消毒（`sanitizeToolsForGoogle`）
- 會話歷史消毒（`sanitizeSessionHistory`）

### OpenAI

- 用於 Codex 模型的 `apply_patch` 工具
- 思考等級降級處理

## TUI 整合

OpenClaw 也有本地 TUI 模式，直接使用 pi-tui 元件：

```typescript
// src/tui/tui.ts
import { ... } from "@mariozechner/pi-tui";
```

這提供類似 pi 本地模式的互動式終端機體驗。

## 與 Pi CLI 的主要差異

| 面向            | Pi CLI                  | OpenClaw 嵌入式                                                                   |
| --------------- | ----------------------- | ------------------------------------------------------------------------------- |
| 呼叫方式        | `pi` 指令 / RPC         | 透過 `createAgentSession()` 的 SDK                                              |
| 工具            | 預設編碼工具            | 自訂 OpenClaw 工具套件                                                          |
| 系統提示        | AGENTS.md + 提示        | 依通道／上下文動態設定                                                          |
| 會話存儲        | `~/.pi/agent/sessions/` | `~/.openclaw/agents/<agentId>/sessions/`（或 `$OPENCLAW_STATE_DIR/agents/...`） |
| 驗證            | 單一認證                | 多設定檔與輪換                                                                  |
| 擴充功能        | 從磁碟載入              | 程式化 + 磁碟路徑                                                               |
| 事件處理        | TUI 渲染                | 回呼型（onBlockReply 等）                                                       |

## 未來考慮

可能重新工作的領域：

1. **工具簽章對齊**：目前在 pi-agent-core 和 pi-coding-agent 簽章間轉接
2. **會話管理器包裝**：`guardSessionManager` 新增安全性但增加複雜性
3. **擴充功能載入**：可更直接地使用 pi 的 `ResourceLoader`
4. **串流處理複雜性**：`subscribeEmbeddedPiSession` 已增長很大
5. **廠商怪癖**：許多廠商特定代碼路徑，pi 可能處理

## 測試

所有涵蓋 pi 整合及其擴充功能的現有測試：

- `src/agents/pi-embedded-block-chunker.test.ts`
- `src/agents/pi-embedded-helpers.buildbootstrapcontextfiles.test.ts`
- `src/agents/pi-embedded-helpers.classifyfailoverreason.test.ts`
- `src/agents/pi-embedded-helpers.downgradeopenai-reasoning.test.ts`
- `src/agents/pi-embedded-helpers.formatassistanterrortext.test.ts`
- `src/agents/pi-embedded-helpers.formatrawassistanterrorforui.test.ts`
- `src/agents/pi-embedded-helpers.image-dimension-error.test.ts`
- `src/agents/pi-embedded-helpers.image-size-error.test.ts`
- `src/agents/pi-embedded-helpers.isautherrormessage.test.ts`
- `src/agents/pi-embedded-helpers.isbillingerrormessage.test.ts`
- `src/agents/pi-embedded-helpers.iscloudcodeassistformaterror.test.ts`
- `src/agents/pi-embedded-helpers.iscompactionfailureerror.test.ts`
- `src/agents/pi-embedded-helpers.iscontextoverflowerror.test.ts`
- `src/agents/pi-embedded-helpers.isfailovererrormessage.test.ts`
- `src/agents/pi-embedded-helpers.islikelycontextoverflowerror.test.ts`
- `src/agents/pi-embedded-helpers.ismessagingtoolduplicate.test.ts`
- `src/agents/pi-embedded-helpers.messaging-duplicate.test.ts`
- `src/agents/pi-embedded-helpers.normalizetextforcomparison.test.ts`
- `src/agents/pi-embedded-helpers.resolvebootstrapmaxchars.test.ts`
- `src/agents/pi-embedded-helpers.sanitize-session-messages-images.keeps-tool-call-tool-result-ids-unchanged.test.ts`
- `src/agents/pi-embedded-helpers.sanitize-session-messages-images.removes-empty-assistant-text-blocks-but-preserves.test.ts`
- `src/agents/pi-embedded-helpers.sanitizegoogleturnordering.test.ts`
- `src/agents/pi-embedded-helpers.sanitizesessionmessagesimages-thought-signature-stripping.test.ts`
- `src/agents/pi-embedded-helpers.sanitizetoolcallid.test.ts`
- `src/agents/pi-embedded-helpers.sanitizeuserfacingtext.test.ts`
- `src/agents/pi-embedded-helpers.stripthoughtsignatures.test.ts`
- `src/agents/pi-embedded-helpers.validate-turns.test.ts`
- `src/agents/pi-embedded-runner-extraparams.live.test.ts`（即時）
- `src/agents/pi-embedded-runner-extraparams.test.ts`
- `src/agents/pi-embedded-runner.applygoogleturnorderingfix.test.ts`
- `src/agents/pi-embedded-runner.buildembeddedsandboxinfo.test.ts`
- `src/agents/pi-embedded-runner.createsystempromptoverride.test.ts`
- `src/agents/pi-embedded-runner.get-dm-history-limit-from-session-key.falls-back-provider-default-per-dm-not.test.ts`
- `src/agents/pi-embedded-runner.get-dm-history-limit-from-session-key.returns-undefined-sessionkey-is-undefined.test.ts`
- `src/agents/pi-embedded-runner.google-sanitize-thinking.test.ts`
- `src/agents/pi-embedded-runner.guard.test.ts`
- `src/agents/pi-embedded-runner.limithistoryturns.test.ts`
- `src/agents/pi-embedded-runner.resolvesessionagentids.test.ts`
- `src/agents/pi-embedded-runner.run-embedded-pi-agent.auth-profile-rotation.test.ts`
- `src/agents/pi-embedded-runner.sanitize-session-history.test.ts`
- `src/agents/pi-embedded-runner.splitsdktools.test.ts`
- `src/agents/pi-embedded-runner.test.ts`
- `src/agents/pi-embedded-subscribe.code-span-awareness.test.ts`
- `src/agents/pi-embedded-subscribe.reply-tags.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.calls-onblockreplyflush-before-tool-execution-start-preserve.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.does-not-append-text-end-content-is.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.does-not-call-onblockreplyflush-callback-is-not.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.does-not-duplicate-text-end-repeats-full.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.does-not-emit-duplicate-block-replies-text.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.emits-block-replies-text-end-does-not.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.emits-reasoning-as-separate-message-enabled.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.filters-final-suppresses-output-without-start-tag.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.includes-canvas-action-metadata-tool-summaries.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.keeps-assistanttexts-final-answer-block-replies-are.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.keeps-indented-fenced-blocks-intact.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.reopens-fenced-blocks-splitting-inside-them.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.splits-long-single-line-fenced-blocks-reopen.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.streams-soft-chunks-paragraph-preference.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.subscribeembeddedpisession.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.suppresses-message-end-block-replies-message-tool.test.ts`
- `src/agents/pi-embedded-subscribe.subscribe-embedded-pi-session.waits-multiple-compaction-retries-before-resolving.test.ts`
- `src/agents/pi-embedded-subscribe.tools.test.ts`
- `src/agents/pi-embedded-utils.test.ts`
- `src/agents/pi-extensions/compaction-safeguard.test.ts`
- `src/agents/pi-extensions/context-pruning.test.ts`
- `src/agents/pi-settings.test.ts`
- `src/agents/pi-tool-definition-adapter.test.ts`
- `src/agents/pi-tools-agent-config.test.ts`
- `src/agents/pi-tools.create-openclaw-coding-tools.adds-claude-style-aliases-schemas-without-dropping-b.test.ts`
- `src/agents/pi-tools.create-openclaw-coding-tools.adds-claude-style-aliases-schemas-without-dropping-d.test.ts`
- `src/agents/pi-tools.create-openclaw-coding-tools.adds-claude-style-aliases-schemas-without-dropping-f.test.ts`
- `src/agents/pi-tools.create-openclaw-coding-tools.adds-claude-style-aliases-schemas-without-dropping.test.ts`
- `src/agents/pi-tools.policy.test.ts`
- `src/agents/pi-tools.safe-bins.test.ts`
- `src/agents/pi-tools.workspace-paths.test.ts`
