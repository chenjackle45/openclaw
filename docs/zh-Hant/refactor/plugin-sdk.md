---
title: "Plugin SDK(外掛 SDK 重構)"
summary: "計畫：為所有訊息連接器提供一個乾淨的外掛 SDK + runtime"
read_when:
  - 定義或重構外掛架構
  - 將頻道連接器遷移到外掛 SDK/runtime
---
# Plugin SDK + Runtime Refactor Plan(外掛 SDK + Runtime 重構計畫)

目標：每個訊息連接器都是使用一個穩定 API 的外掛（捆綁或外部）。
沒有外掛直接從 `src/**` 匯入。所有依賴項都透過 SDK 或 runtime。

## 為什麼現在
- 當前連接器混合模式：直接核心匯入、僅 dist 橋接器和自訂 helpers。
- 這使升級變得脆弱，並阻止乾淨的外部外掛介面。

## 目標架構（兩層）

### 1) Plugin SDK（編譯時、穩定、可發布）
範圍：類型、helpers 和設定實用程式。無 runtime 狀態，無副作用。

內容（範例）：
- 類型：`ChannelPlugin`、adapters、`ChannelMeta`、`ChannelCapabilities`、`ChannelDirectoryEntry`。
- 設定 helpers：`buildChannelConfigSchema`、`setAccountEnabledInConfigSection`、`deleteAccountFromConfigSection`、`applyAccountNameToChannelSection`。
- 配對 helpers：`PAIRING_APPROVED_MESSAGE`、`formatPairingApproveHint`。
- Onboarding helpers：`promptChannelAccessConfig`、`addWildcardAllowFrom`、onboarding 類型。
- 工具參數 helpers：`createActionGate`、`readStringParam`、`readNumberParam`、`readReactionParams`、`jsonResult`。
- 文件連結 helper：`formatDocsLink`。

交付：
- 發布為 `openclaw/plugin-sdk`（或從核心下 `openclaw/plugin-sdk` 匯出）。
- 具有明確穩定性保證的 Semver。

### 2) Plugin Runtime（執行介面，注入）
範圍：一切觸及核心 runtime 行為的內容。
透過 `OpenClawPluginApi.runtime` 存取，因此外掛從不匯入 `src/**`。

提議的介面（最小但完整）：
```ts
export type PluginRuntime = {
  channel: {
    text: {
      chunkMarkdownText(text: string, limit: number): string[];
      resolveTextChunkLimit(cfg: OpenClawConfig, channel: string, accountId?: string): number;
      hasControlCommand(text: string, cfg: OpenClawConfig): boolean;
    };
    reply: {
      dispatchReplyWithBufferedBlockDispatcher(params: {
        ctx: unknown;
        cfg: unknown;
        dispatcherOptions: {
          deliver: (payload: { text?: string; mediaUrls?: string[]; mediaUrl?: string }) =>
            void | Promise<void>;
          onError?: (err: unknown, info: { kind: string }) => void;
        };
      }): Promise<void>;
      createReplyDispatcherWithTyping?: unknown; // adapter for Teams-style flows
    };
    routing: {
      resolveAgentRoute(params: {
        cfg: unknown;
        channel: string;
        accountId: string;
        peer: { kind: "dm" | "group" | "channel"; id: string };
      }): { sessionKey: string; accountId: string };
    };
    pairing: {
      buildPairingReply(params: { channel: string; idLine: string; code: string }): string;
      readAllowFromStore(channel: string): Promise<string[]>;
      upsertPairingRequest(params: {
        channel: string;
        id: string;
        meta?: { name?: string };
      }): Promise<{ code: string; created: boolean }>;
    };
    media: {
      fetchRemoteMedia(params: { url: string }): Promise<{ buffer: Buffer; contentType?: string }>;
      saveMediaBuffer(
        buffer: Uint8Array,
        contentType: string | undefined,
        direction: "inbound" | "outbound",
        maxBytes: number,
      ): Promise<{ path: string; contentType?: string }>;
    };
    mentions: {
      buildMentionRegexes(cfg: OpenClawConfig, agentId?: string): RegExp[];
      matchesMentionPatterns(text: string, regexes: RegExp[]): boolean;
    };
    groups: {
      resolveGroupPolicy(cfg: OpenClawConfig, channel: string, accountId: string, groupId: string): {
        allowlistEnabled: boolean;
        allowed: boolean;
        groupConfig?: unknown;
        defaultConfig?: unknown;
      };
      resolveRequireMention(
        cfg: OpenClawConfig,
        channel: string,
        accountId: string,
        groupId: string,
        override?: boolean,
      ): boolean;
    };
    debounce: {
      createInboundDebouncer<T>(opts: {
        debounceMs: number;
        buildKey: (v: T) => string | null;
        shouldDebounce: (v: T) => boolean;
        onFlush: (entries: T[]) => Promise<void>;
        onError?: (err: unknown) => void;
      }): { push: (v: T) => void; flush: () => Promise<void> };
      resolveInboundDebounceMs(cfg: OpenClawConfig, channel: string): number;
    };
    commands: {
      resolveCommandAuthorizedFromAuthorizers(params: {
        useAccessGroups: boolean;
        authorizers: Array<{ configured: boolean; allowed: boolean }>;
      }): boolean;
    };
  };
  logging: {
    shouldLogVerbose(): boolean;
    getChildLogger(name: string): PluginLogger;
  };
  state: {
    resolveStateDir(cfg: OpenClawConfig): string;
  };
};
```

注意事項：
- Runtime 是存取核心行為的唯一方式。
- SDK 故意小且穩定。
- 每個 runtime 方法對應到現有核心實作（無重複）。

## 遷移計畫（分階段、安全）

### 第 0 階段：架構
- 引入 `openclaw/plugin-sdk`。
- 向 `OpenClawPluginApi` 新增 `api.runtime`，具有上述介面。
- 在過渡視窗期間維護現有匯入（棄用警告）。

### 第 1 階段：橋接器清理（低風險）
- 用 `api.runtime` 取代每個擴充的 `core-bridge.ts`。
- 首先遷移 BlueBubbles、Zalo、Zalo Personal（已接近）。
- 移除重複的橋接器程式碼。

### 第 2 階段：輕量直接匯入外掛
- 將 Matrix 遷移到 SDK + runtime。
- 驗證 onboarding、directory、群組提及邏輯。

### 第 3 階段：重量直接匯入外掛
- 遷移 MS Teams（最大的 runtime helpers 集）。
- 確保 reply/typing 語意與當前行為匹配。

### 第 4 階段：iMessage 外掛化
- 將 iMessage 移動到 `extensions/imessage`。
- 用 `api.runtime` 取代直接核心呼叫。
- 保持設定鍵、CLI 行為和文件完整。

### 第 5 階段：強制執行
- 新增 lint 規則 / CI 檢查：`extensions/**` 不從 `src/**` 匯入。
- 新增外掛 SDK/版本相容性檢查（runtime + SDK semver）。

## 相容性和版本控制
- SDK：semver、已發布、已記錄的變更。
- Runtime：每個核心發布版本化。新增 `api.runtime.version`。
- 外掛宣告所需的 runtime 範圍（例如，`openclawRuntime: ">=2026.2.0"`）。

## 測試策略
- Adapter 層級單元測試（使用真實核心實作執行的 runtime 函式）。
- 每個外掛的 golden 測試：確保無行為偏移（路由、配對、允許清單、提及門控）。
- CI 中使用的單一端到端外掛範例（install + run + smoke）。

## 開放問題
- SDK 類型託管位置：單獨套件還是核心匯出？
- Runtime 類型分發：在 SDK 中（僅類型）還是在核心中？
- 如何公開捆綁 vs 外部外掛的文件連結？
- 我們是否允許在過渡期間對儲存庫內外掛進行有限的直接核心匯入？

## 成功標準
- 所有頻道連接器都是使用 SDK + runtime 的外掛。
- `extensions/**` 不從 `src/**` 匯入。
- 新的連接器範本僅依賴 SDK + runtime。
- 外部外掛可以在沒有核心來源存取的情況下開發和更新。

相關文件：[Plugins](/plugin)、[Channels](/channels/index)、[Configuration](/gateway/configuration)。
