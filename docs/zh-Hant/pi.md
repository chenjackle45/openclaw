---
title: "Pi Integration Architecture（Pi 整合架構）"
summary: "OpenClaw 嵌入式 Pi 代理整合的架構和會話生命週期"
read_when:
  - 瞭解 OpenClaw 中 Pi SDK 整合設計
  - 修改代理會話生命週期、工具或 Pi 提供商連接
---

# Pi 整合架構

本文件描述 OpenClaw 如何與 [pi-coding-agent](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) 及其兄弟套件（`pi-ai`、`pi-agent-core`、`pi-tui`）整合以支援其 AI 代理能力。

## 概述

OpenClaw 使用 pi SDK 將 AI 編碼代理嵌入到其訊息網關架構中。OpenClaw 不是生成 pi 作為子進程或使用 RPC 模式，而是直接導入並透過 `createAgentSession()` 實例化 pi 的 `AgentSession`。此嵌入式方法提供：

- 對會話生命週期和事件處理的完全控制
- 自訂工具注入（訊息、沙盒、頻道特定操作）
- 系統提示詞按頻道/上下文自訂
- 具有分支/壓縮支援的會話持續性
- 具有容錯轉移的多帳戶認證檔案輪換
- 提供商不知道的模型交換

## 套件相依性

```json
{
  "@mariozechner/pi-agent-core": "0.49.3",
  "@mariozechner/pi-ai": "0.49.3",
  "@mariozechner/pi-coding-agent": "0.49.3",
  "@mariozechner/pi-tui": "0.49.3"
}
```

| 套件              | 目的                                                                                       |
| ----------------- | ------------------------------------------------------------------------------------------ |
| `pi-ai`           | 核心 LLM 抽象：`Model`、`streamSimple`、訊息類型、提供商 API                               |
| `pi-agent-core`   | 代理迴圈、工具執行、`AgentMessage` 類型                                                    |
| `pi-coding-agent` | 高階 SDK：`createAgentSession`、`SessionManager`、`AuthStorage`、`ModelRegistry`、內建工具 |
| `pi-tui`          | 終端機 UI 元件（在 OpenClaw 的本地 TUI 模式中使用）                                        |

## 檔案結構

```
src/agents/
├── pi-embedded-runner.ts          # 從 pi-embedded-runner/ 重新匯出
├── pi-embedded-runner/
│   ├── run.ts                     # 主入口：runEmbeddedPiAgent()
│   ├── run/
│   │   ├── attempt.ts             # 單一嘗試邏輯，帶會話設定
│   │   ├── params.ts              # RunEmbeddedPiAgentParams 類型
│   │   ├── payloads.ts            # 從運行結果構建回應負載
│   │   ├── images.ts              # 視覺模型影像注入
│   │   └── types.ts               # EmbeddedRunAttemptResult
│   ├── abort.ts                   # 中止錯誤偵測
│   ├── cache-ttl.ts               # 上下文修剪的快取 TTL 追蹤
│   ├── compact.ts                 # 手動/自動壓縮邏輯
│   ├── extensions.ts              # 為嵌入式運行加載 pi 延伸
│   ├── extra-params.ts            # 提供商特定流參數
│   ├── google.ts                  # Google/Gemini 轉向順序修復
│   ├── history.ts                 # 歷史限制（DM vs 群組）
│   ├── lanes.ts                   # 會話/全域命令通道
│   ├── logger.ts                  # 子系統記錄器
│   ├── model.ts                   # 通過 ModelRegistry 解析模型
│   ├── runs.ts                    # 活躍運行追蹤、中止、隊列
│   ├── sandbox-info.ts            # 系統提示詞的沙盒資訊
│   ├── session-manager-cache.ts   # SessionManager 實例快取
│   ├── session-manager-init.ts    # 會話檔案初始化
│   ├── system-prompt.ts           # 系統提示詞構建器
│   ├── tool-split.ts              # 將工具分為 builtIn vs 自訂
│   ├── types.ts                   # EmbeddedPiAgentMeta、EmbeddedPiRunResult
│   └── utils.ts                   # ThinkLevel 映射、錯誤描述
├── pi-embedded-subscribe.ts       # 會話事件訂閱/分派
├── pi-embedded-subscribe.types.ts # SubscribeEmbeddedPiSessionParams
├── pi-embedded-subscribe.handlers.ts # 事件處理程式工廠
├── pi-embedded-subscribe.handlers.lifecycle.ts
├── pi-embedded-subscribe.handlers.types.ts
├── pi-embedded-block-chunker.ts   # 串流塊回覆分塊
├── pi-embedded-messaging.ts       # 訊息工具傳送追蹤
├── pi-embedded-helpers.ts         # 錯誤分類、轉向驗證
├── pi-embedded-helpers/           # 幫助程式模組
├── pi-embedded-utils.ts           # 格式化實用程式
├── pi-tools.ts                    # createOpenClawCodingTools()
├── pi-tools.abort.ts              # 工具的 AbortSignal 包裝
├── pi-tools.policy.ts             # 工具許可清單/拒絕清單原則
├── pi-tools.read.ts               # 讀取工具自訂
├── pi-tools.schema.ts             # 工具架構規範化
├── pi-tools.types.ts              # AnyAgentTool 類型別名
├── pi-tool-definition-adapter.ts  # AgentTool -> ToolDefinition 適配器
├── pi-settings.ts                 # 設定覆蓋
├── pi-extensions/                 # 自訂 pi 延伸
│   ├── compaction-safeguard.ts    # 保護延伸
│   ├── compaction-safeguard-runtime.ts
│   ├── context-pruning.ts         # 快取 TTL 上下文修剪延伸
│   └── context-pruning/
├── model-auth.ts                  # 認證檔案解析
├── auth-profiles.ts               # 檔案儲存、冷卻、容錯轉移
├── model-selection.ts             # 預設模型解析
├── models-config.ts               # models.json 生成
├── model-catalog.ts               # 模型目錄快取
├── context-window-guard.ts        # 上下文視窗驗證
├── failover-error.ts              # FailoverError 類別
├── defaults.ts                    # DEFAULT_PROVIDER、DEFAULT_MODEL
├── system-prompt.ts               # buildAgentSystemPrompt()
├── system-prompt-params.ts        # 系統提示詞參數解析
├── system-prompt-report.ts        # 調試報告生成
├── tool-summaries.ts              # 工具描述摘要
├── tool-policy.ts                 # 工具原則解析
├── transcript-policy.ts           # 文字稿驗證原則
├── skills.ts                      # 技能快照/提示詞構建
├── skills/                        # 技能子系統
├── sandbox.ts                     # 沙盒上下文解析
├── sandbox/                       # 沙盒子系統
├── channel-tools.ts               # 頻道特定工具注入
├── openclaw-tools.ts              # OpenClaw 特定工具
├── bash-tools.ts                  # exec/process 工具
├── apply-patch.ts                 # apply_patch 工具（OpenAI）
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

## 核心整合流

### 1. 執行嵌入式代理

主入口點是 `pi-embedded-runner/run.ts` 中的 `runEmbeddedPiAgent()`：

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

在 `runEmbeddedAttempt()`（由 `runEmbeddedPiAgent()` 呼叫）內，使用 pi SDK：

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

- `message_start` / `message_end` / `message_update`（串流文本/思考）
- `tool_execution_start` / `tool_execution_update` / `tool_execution_end`
- `turn_start` / `turn_end`
- `agent_start` / `agent_end`
- `auto_compaction_start` / `auto_compaction_end`

### 4. 提示詞

設定後，會話被提示：

```typescript
await session.prompt(effectivePrompt, { images: imageResult.images });
```

SDK 處理完整代理迴圈：傳送到 LLM、執行工具呼叫、串流回應。

影像注入是提示詞本地的：OpenClaw 從當前提示詞加載影像參考，並僅為該轉向通過 `images` 傳遞。它不會重新掃描舊版歷史轉向以重新注入影像負載。

## 工具架構

### 工具管道

1. **基本工具**：pi 的 `codingTools`（read、bash、edit、write）
2. **自訂替換**：OpenClaw 使用 `exec`/`process` 替換 bash，為沙盒自訂 read/edit/write
3. **OpenClaw 工具**：訊息、瀏覽器、畫布、會話、cron、網關等
4. **頻道工具**：Discord/Telegram/Slack/WhatsApp 特定操作工具
5. **原則篩選**：工具按檔案、提供商、代理、群組、沙盒原則篩選
6. **架構規範化**：為 Gemini/OpenAI 怪癖清理架構
7. **AbortSignal 包裝**：包裝工具以尊重中止信號

### 工具定義適配器

pi-agent-core 的 `AgentTool` 具有與 pi-coding-agent 的 `ToolDefinition` 不同的 `execute` 簽章。`pi-tool-definition-adapter.ts` 中的適配器橋接：

```typescript
export function toToolDefinitions(tools: AnyAgentTool[]): ToolDefinition[] {
  return tools.map((tool) => ({
    name: tool.name,
    label: tool.label ?? name,
    description: tool.description ?? "",
    parameters: tool.parameters,
    execute: async (toolCallId, params, onUpdate, _ctx, signal) => {
      // pi-coding-agent 簽章與 pi-agent-core 不同
      return await tool.execute(toolCallId, params, signal, onUpdate);
    },
  }));
}
```

### 工具分割策略

`splitSdkTools()` 通過 `customTools` 傳遞所有工具：

```typescript
export function splitSdkTools(options: { tools: AnyAgentTool[]; sandboxEnabled: boolean }) {
  return {
    builtInTools: [], // 空。我們覆蓋所有
    customTools: toToolDefinitions(options.tools),
  };
}
```

這確保 OpenClaw 的原則篩選、沙盒整合和延伸工具集在提供商間保持一致。

## 系統提示詞構造

系統提示詞在 `buildAgentSystemPrompt()`（`system-prompt.ts`）中構建。它組裝一個完整提示詞，包含工具、工具呼叫風格、安全護欄、OpenClaw CLI 參考、技能、文件、工作區、沙盒、訊息、回覆標籤、語音、無聲回覆、心跳、運行時元數據、加記憶體和反應（啟用時）、加選擇性上下文檔案和額外系統提示詞內容。對子代理使用的最小提示詞模式調整部分。

提示詞在會話建立後通過 `applySystemPromptOverrideToSession()` 應用：

```typescript
const systemPromptOverride = createSystemPromptOverride(appendPrompt);
applySystemPromptOverrideToSession(session, systemPromptOverride);
```

## 會話管理

### 會話檔案

會話是具有樹結構（id/parentId 連結）的 JSONL 檔案。Pi 的 `SessionManager` 處理持續性：

```typescript
const sessionManager = SessionManager.open(params.sessionFile);
```

OpenClaw 用 `guardSessionManager()` 包裝此以確保工具結果安全。

### 會話快取

`session-manager-cache.ts` 快取 SessionManager 實例以避免重複檔案解析：

```typescript
await prewarmSessionFile(params.sessionFile);
sessionManager = SessionManager.open(params.sessionFile);
trackSessionManagerAccess(params.sessionFile);
```

### 歷史限制

`limitHistoryTurns()` 根據頻道類型（DM vs 群組）修剪對話歷史。

### 壓縮

自動壓縮在上下文溢位時觸發。`compactEmbeddedPiSessionDirect()` 處理手動壓縮：

```typescript
const compactResult = await compactEmbeddedPiSessionDirect({
  sessionId, sessionFile, provider, model, ...
});
```

## 認證和模型解析

### 認證檔案

OpenClaw 維護認證檔案儲存，每個提供商有多個 API 金鑰：

```typescript
const authStore = ensureAuthProfileStore(agentDir, { allowKeychainPrompt: false });
const profileOrder = resolveAuthProfileOrder({ cfg, store: authStore, provider, preferredProfile });
```

檔案在失敗時帶冷卻追蹤輪換：

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

### 容錯轉移

`FailoverError` 在配置時觸發模型降級：

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

## Pi 延伸

OpenClaw 加載自訂 pi 延伸以實現專門行為：

### 壓縮保護

`src/agents/pi-extensions/compaction-safeguard.ts` 添加壓縮護欄，包括自適應 token 預算加工具失敗和檔案操作摘要：

```typescript
if (resolveCompactionMode(params.cfg) === "safeguard") {
  setCompactionSafeguardRuntime(params.sessionManager, { maxHistoryShare });
  paths.push(resolvePiExtensionPath("compaction-safeguard"));
}
```

### 上下文修剪

`src/agents/pi-extensions/context-pruning.ts` 實作快取 TTL 基礎上下文修剪：

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

## 串流和塊回覆

### 塊分塊

`EmbeddedBlockChunker` 管理串流文本到離散回覆塊：

```typescript
const blockChunker = blockChunking ? new EmbeddedBlockChunker(blockChunking) : null;
```

### 思考/最終標籤剝離

串流輸出被處理以剝離 `<think>`/`<thinking>` 塊和提取 `<final>` 內容：

```typescript
const stripBlockTags = (text: string, state: { thinking: boolean; final: boolean }) => {
  // 剝離 <think>...</think> 內容
  // 如果 enforceFinalTag，只返回 <final>...</final> 內容
};
```

### 回覆指示

回覆指示如 `[[media:url]]`、`[[voice]]`、`[[reply:id]]` 被解析和提取：

```typescript
const { text: cleanedText, mediaUrls, audioAsVoice, replyToId } = consumeReplyDirectives(chunk);
```

## 錯誤處理

### 錯誤分類

`pi-embedded-helpers.ts` 分類錯誤以適當處理：

```typescript
isContextOverflowError(errorText)     // 上下文太大
isCompactionFailureError(errorText)   // 壓縮失敗
isAuthAssistantError(lastAssistant)   // 認證失敗
isRateLimitAssistantError(...)        // 速率限制
isFailoverAssistantError(...)         // 應該容錯轉移
classifyFailoverReason(errorText)     // "auth" | "rate_limit" | "quota" | "timeout" | ...
```

### 思考層級降級

如果思考層級不受支援，它會降級：

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

啟用沙盒模式後，工具和路徑受限：

```typescript
const sandbox = await resolveSandboxContext({
  config: params.config,
  sessionKey: sandboxSessionKey,
  workspaceDir: resolvedWorkspace,
});

if (sandboxRoot) {
  // 使用沙盒化讀/編輯/寫工具
  // Exec 在容器中執行
  // 瀏覽器使用橋接 URL
}
```

## 提供商特定處理

### Anthropic

- 拒絕魔法字符串清理
- 連續角色轉向驗證
- Claude Code 參數相容性

### Google/Gemini

- 轉向順序修復（`applyGoogleTurnOrderingFix`）
- 工具架構清理（`sanitizeToolsForGoogle`）
- 會話歷史清理（`sanitizeSessionHistory`）

### OpenAI

- Codex 模型的 `apply_patch` 工具
- 思考層級降級處理

## TUI 整合

OpenClaw 也有直接使用 pi-tui 元件的本地 TUI 模式：

```typescript
// src/tui/tui.ts
import { ... } from "@mariozechner/pi-tui";
```

這提供了類似 pi 原生模式的互動式終端機體驗。

## Pi CLI 的關鍵差異

| 方面       | Pi CLI                  | OpenClaw 嵌入式                                                                                 |
| ---------- | ----------------------- | ----------------------------------------------------------------------------------------------- |
| 調用       | `pi` 命令 / RPC         | SDK 通過 `createAgentSession()`                                                                 |
| 工具       | 預設編碼工具            | 自訂 OpenClaw 工具套件                                                                          |
| 系統提示詞 | AGENTS.md + 提示詞      | 按頻道/上下文動態                                                                               |
| 會話儲存   | `~/.pi/agent/sessions/` | `~/.openclaw/agents/<agentId>/sessions/`（或 `$OPENCLAW_STATE_DIR/agents/<agentId>/sessions/`） |
| 認證       | 單一認證                | 具有輪換的多檔案                                                                                |
| 延伸       | 從磁碟加載              | 程式設計加磁碟路徑                                                                              |
| 事件處理   | TUI 呈現                | 回呼基礎（onBlockReply 等）                                                                     |

## 未來考慮

潛在重做的領域：

1. **工具簽章對齊**：目前在 pi-agent-core 和 pi-coding-agent 簽章間調整
2. **會話管理器包裝**：`guardSessionManager` 添加安全性但增加複雜性
3. **延伸加載**：可以更直接地使用 pi 的 `ResourceLoader`
4. **串流處理程式複雜性**：`subscribeEmbeddedPiSession` 已變大
5. **提供商怪癖**：許多提供商特定代碼路徑 pi 可能能夠處理

## 測試

Pi 整合涵蓋範圍跨越這些套件：

- `src/agents/pi-*.test.ts`
- `src/agents/pi-auth-json.test.ts`
- `src/agents/pi-embedded-*.test.ts`
- `src/agents/pi-embedded-helpers*.test.ts`
- `src/agents/pi-embedded-runner*.test.ts`
- `src/agents/pi-embedded-runner/**/*.test.ts`
- `src/agents/pi-embedded-subscribe*.test.ts`
- `src/agents/pi-tools*.test.ts`
- `src/agents/pi-tool-definition-adapter*.test.ts`
- `src/agents/pi-settings.test.ts`
- `src/agents/pi-extensions/**/*.test.ts`

即時/選擇加入：

- `src/agents/pi-embedded-runner-extraparams.live.test.ts`（啟用 `OPENCLAW_LIVE_TEST=1`）

有關當前運行命令，請查看 [Pi 開發工作流](/zh-Hant/pi-dev)。
