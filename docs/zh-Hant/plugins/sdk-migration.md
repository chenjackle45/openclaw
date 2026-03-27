---
title: "Plugin SDK Migration（外掛程式 SDK 遷移）"
sidebarTitle: "遷移至 SDK"
summary: "從舊版向後相容性層遷移至現代外掛程式 SDK"
read_when:
  - 看到 OPENCLAW_PLUGIN_SDK_COMPAT_DEPRECATED 警告時
  - 看到 OPENCLAW_EXTENSION_API_DEPRECATED 警告時
  - 更新外掛程式至現代外掛程式架構時
  - 維護外部 OpenClaw 外掛程式時
---

# 外掛程式 SDK 遷移

OpenClaw 已從寬泛的向後相容性層移動至具有聚焦、文件化匯入的現代外掛程式架構。若您的外掛程式是在新架構之前建立的，此指南可幫助您進行遷移。

## 正在變更的內容

舊外掛程式系統提供了兩個寬泛的表面，讓外掛程式可以從單一進入點匯入它們需要的任何內容：

- **`openclaw/plugin-sdk/compat`** — 單一匯入，重新匯出幾十個幫手。它被引入以在建構新外掛程式架構時保持較舊掛鉤型外掛程式的執行。
- **`openclaw/extension-api`** — 一個橋接器，給外掛程式直接存取主機側幫手（如內嵌代理程式執行器）的權限。

兩個表面現在都**已棄用**。它們在執行時仍有效，但新外掛程式不得使用它們，現有外掛程式應在下一個主要版本將其移除之前進行遷移。

<Warning>
  向後相容性層將在未來主要版本中移除。仍然從這些表面匯入的外掛程式會在這種情況下中斷。
</Warning>

## 為什麼這改變了

舊方法造成了問題：

- **啟動速度慢** — 匯入一個幫手會載入幾十個無關的模組
- **循環相依性** — 寬泛的重新匯出使得易於建立匯入迴圈
- **不清楚的 API 表面** — 無法判斷哪些匯出是穩定的 vs 內部的

現代外掛程式 SDK 修復了這個問題：每個匯入路徑（`openclaw/plugin-sdk/<subpath>`）是一個小的、自包含的模組，具有清楚的目的和文件化的約定。

## 如何遷移

<Steps>
  <Step title="找到已棄用的匯入">
    搜尋您的外掛程式以尋找來自任一已棄用表面的匯入：

    ```bash
    grep -r "plugin-sdk/compat" my-plugin/
    grep -r "openclaw/extension-api" my-plugin/
    ```

  </Step>

  <Step title="替換為聚焦的匯入">
    舊表面的每個匯出都對應到特定的現代匯入路徑：

    ```typescript
    // 之前（已棄用的向後相容性層）
    import {
      createChannelReplyPipeline,
      createPluginRuntimeStore,
      resolveControlCommandGate,
    } from "openclaw/plugin-sdk/compat";

    // 之後（現代聚焦的匯入）
    import { createChannelReplyPipeline } from "openclaw/plugin-sdk/channel-reply-pipeline";
    import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";
    import { resolveControlCommandGate } from "openclaw/plugin-sdk/command-auth";
    ```

    對於主機側幫手，使用注入的外掛程式執行時，而不是直接匯入：

    ```typescript
    // 之前（已棄用的 extension-api 橋接器）
    import { runEmbeddedPiAgent } from "openclaw/extension-api";
    const result = await runEmbeddedPiAgent({ sessionId, prompt });

    // 之後（注入的執行時）
    const result = await api.runtime.agent.runEmbeddedPiAgent({ sessionId, prompt });
    ```

    相同的模式適用於其他舊版橋接器幫手：

    | 舊匯入 | 現代等價物 |
    | --- | --- |
    | `resolveAgentDir` | `api.runtime.agent.resolveAgentDir` |
    | `resolveAgentWorkspaceDir` | `api.runtime.agent.resolveAgentWorkspaceDir` |
    | `resolveAgentIdentity` | `api.runtime.agent.resolveAgentIdentity` |
    | `resolveThinkingDefault` | `api.runtime.agent.resolveThinkingDefault` |
    | `resolveAgentTimeoutMs` | `api.runtime.agent.resolveAgentTimeoutMs` |
    | `ensureAgentWorkspace` | `api.runtime.agent.ensureAgentWorkspace` |
    | 工作階段存儲幫手 | `api.runtime.agent.session.*` |

  </Step>

  <Step title="建置並測試">
    ```bash
    pnpm build
    pnpm test -- my-plugin/
    ```
  </Step>
</Steps>

## 匯入路徑參考

<Accordion title="完整匯入路徑表">
  | 匯入路徑 | 目的 | 主要匯出 |
  | --- | --- | --- |
  | `plugin-sdk/plugin-entry` | 規範外掛程式進入點幫手 | `definePluginEntry` |
  | `plugin-sdk/core` | 頻道進入點定義、頻道構建器、基本型別 | `defineChannelPluginEntry`、`createChatChannelPlugin` |
  | `plugin-sdk/channel-setup` | 設定精靈適配器 | `createOptionalChannelSetupSurface` |
  | `plugin-sdk/channel-pairing` | DM 配對基元 | `createChannelPairingController` |
  | `plugin-sdk/channel-reply-pipeline` | 回應前綴 + 輸入連接 | `createChannelReplyPipeline` |
  | `plugin-sdk/channel-config-helpers` | 設定適配器工廠 | `createHybridChannelConfigAdapter` |
  | `plugin-sdk/channel-config-schema` | 設定結構描述構建器 | 頻道設定結構描述型別 |
  | `plugin-sdk/channel-policy` | 群組/DM 政策解析 | `resolveChannelGroupRequireMention` |
  | `plugin-sdk/channel-lifecycle` | 帳戶狀態追蹤 | `createAccountStatusSink` |
  | `plugin-sdk/channel-runtime` | 執行時連接幫手 | 頻道執行時工具 |
  | `plugin-sdk/channel-send-result` | 發送結果型別 | 回應結果型別 |
  | `plugin-sdk/runtime-store` | 持久外掛程式儲存體 | `createPluginRuntimeStore` |
  | `plugin-sdk/allow-from` | 允許清單格式化 | `formatAllowFromLowercase` |
  | `plugin-sdk/allowlist-resolution` | 允許清單輸入對應 | `mapAllowlistResolutionInputs` |
  | `plugin-sdk/command-auth` | 指令限制 | `resolveControlCommandGate` |
  | `plugin-sdk/secret-input` | 祕密輸入解析 | 祕密輸入幫手 |
  | `plugin-sdk/webhook-ingress` | Webhook 要求幫手 | Webhook 目標工具 |
  | `plugin-sdk/reply-payload` | 訊息回應型別 | 回應承載型別 |
  | `plugin-sdk/provider-onboard` | 提供商上線修補 | 上線設定幫手 |
  | `plugin-sdk/keyed-async-queue` | 有序非同步佇列 | `KeyedAsyncQueue` |
  | `plugin-sdk/testing` | 測試工具 | 測試幫手和模擬 |
</Accordion>

使用最窄的匯入來符合該工作。若您找不到匯出，檢查 `src/plugin-sdk/` 的來源或在 Discord 中提問。

## 移除時間表

| 時機               | 發生的情況                                         |
| ------------------ | -------------------------------------------------- |
| **現在**           | 已棄用的表面發出執行時警告                         |
| **下一個主要版本** | 已棄用的表面將被移除；仍然使用它們的外掛程式將失敗 |

所有核心外掛程式都已遷移。外部外掛程式應在下一個主要版本前進行遷移。

## 暫時抑制警告

在遷移時設定這些環境變數：

```bash
OPENCLAW_SUPPRESS_PLUGIN_SDK_COMPAT_WARNING=1 openclaw gateway run
OPENCLAW_SUPPRESS_EXTENSION_API_WARNING=1 openclaw gateway run
```

這是臨時避難所，不是永久解決方案。

## 相關主題

- [開始使用](/zh-Hant/plugins/building-plugins) — 建構您的第一個外掛程式
- [SDK 概觀](/zh-Hant/plugins/sdk-overview) — 完整 subpath 匯入參考
- [頻道外掛程式](/zh-Hant/plugins/sdk-channel-plugins) — 建構頻道外掛程式
- [提供商外掛程式](/zh-Hant/plugins/sdk-provider-plugins) — 建構提供商外掛程式
- [外掛程式內部結構](/zh-Hant/plugins/architecture) — 架構深度潛水
- [外掛程式清單](/zh-Hant/plugins/manifest) — 清單結構描述參考
