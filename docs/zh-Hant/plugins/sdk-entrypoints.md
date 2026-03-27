---
title: "Plugin Entry Points（外掛程式進入點）"
sidebarTitle: "進入點"
summary: "definePluginEntry、defineChannelPluginEntry 和 defineSetupPluginEntry 的參考"
read_when:
  - 需要 definePluginEntry 或 defineChannelPluginEntry 的確切型別簽名時
  - 想要瞭解註冊模式（完整 vs 設定）時
  - 正在查詢進入點選項時
---

# 外掛程式進入點

每個外掛程式匯出預設進入物件。SDK 提供三個幫手來建立它們。

<Tip>
  **正在尋找逐步解說？** 請參閱 [Channel Plugins](/zh-Hant/plugins/sdk-channel-plugins) 或 [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins) 以取得逐步指南。
</Tip>

## `definePluginEntry`

**匯入：** `openclaw/plugin-sdk/plugin-entry`

對於提供商外掛程式、工具外掛程式、掛鉤外掛程式和任何**不是**訊息頻道的東西。

```typescript
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "my-plugin",
  name: "My Plugin",
  description: "Short summary",
  register(api) {
    api.registerProvider({
      /* ... */
    });
    api.registerTool({
      /* ... */
    });
  },
});
```

| 欄位           | 型別                                                             | 必需 | 預設           |
| -------------- | ---------------------------------------------------------------- | ---- | -------------- |
| `id`           | `string`                                                         | 是   | —              |
| `name`         | `string`                                                         | 是   | —              |
| `description`  | `string`                                                         | 是   | —              |
| `kind`         | `string`                                                         | 否   | —              |
| `configSchema` | `OpenClawPluginConfigSchema \| () => OpenClawPluginConfigSchema` | 否   | 空物件結構描述 |
| `register`     | `(api: OpenClawPluginApi) => void`                               | 是   | —              |

- `id` 必須符合您的 `openclaw.plugin.json` 清單。
- `kind` 用於獨佔插槽：`"memory"` 或 `"context-engine"`。
- `configSchema` 可以是用於延遲求值的函式。

## `defineChannelPluginEntry`

**匯入：** `openclaw/plugin-sdk/core`

使用頻道特定連接包裝 `definePluginEntry`。自動呼叫 `api.registerChannel({ plugin })` 並在註冊模式上閘制 `registerFull`。

```typescript
import { defineChannelPluginEntry } from "openclaw/plugin-sdk/core";

export default defineChannelPluginEntry({
  id: "my-channel",
  name: "My Channel",
  description: "Short summary",
  plugin: myChannelPlugin,
  setRuntime: setMyRuntime,
  registerFull(api) {
    api.registerCli(/* ... */);
    api.registerGatewayMethod(/* ... */);
  },
});
```

| 欄位           | 型別                                                             | 必需 | 預設           |
| -------------- | ---------------------------------------------------------------- | ---- | -------------- |
| `id`           | `string`                                                         | 是   | —              |
| `name`         | `string`                                                         | 是   | —              |
| `description`  | `string`                                                         | 是   | —              |
| `plugin`       | `ChannelPlugin`                                                  | 是   | —              |
| `configSchema` | `OpenClawPluginConfigSchema \| () => OpenClawPluginConfigSchema` | 否   | 空物件結構描述 |
| `setRuntime`   | `(runtime: PluginRuntime) => void`                               | 否   | —              |
| `registerFull` | `(api: OpenClawPluginApi) => void`                               | 否   | —              |

- `setRuntime` 在註冊時被呼叫，所以您可以儲存執行時參考（通常透過 `createPluginRuntimeStore`）。
- `registerFull` 僅在 `api.registrationMode === "full"` 時執行。它在設定專用載入時被跳過。

## `defineSetupPluginEntry`

**匯入：** `openclaw/plugin-sdk/core`

對於輕量級 `setup-entry.ts` 檔案。只傳回 `{ plugin }`，無執行時或 CLI 連接。

```typescript
import { defineSetupPluginEntry } from "openclaw/plugin-sdk/core";

export default defineSetupPluginEntry(myChannelPlugin);
```

當頻道被停用、未設定或啟用延遲載入時，OpenClaw 會載入此代替完整進入點。請參閱 [Setup and Config](/zh-Hant/plugins/sdk-setup#setup-entry) 以瞭解何時重要。

## 註冊模式

`api.registrationMode` 告訴您的外掛程式它是如何被載入的：

| 模式              | 時機                     | 要註冊的內容        |
| ----------------- | ------------------------ | ------------------- |
| `"full"`          | 一般 Gateway 啟動        | 所有內容            |
| `"setup-only"`    | 停用/未設定頻道          | 僅限頻道註冊        |
| `"setup-runtime"` | 具有可用執行時的設定流程 | 頻道 + 輕量級執行時 |

`defineChannelPluginEntry` 自動處理此分割。若您直接對頻道使用 `definePluginEntry`，自行檢查模式：

```typescript
register(api) {
  api.registerChannel({ plugin: myPlugin });
  if (api.registrationMode !== "full") return;

  // 重型執行時專用註冊
  api.registerCli(/* ... */);
  api.registerService(/* ... */);
}
```

## 外掛程式形狀

OpenClaw 按其註冊行為分類已載入的外掛程式：

| 形狀                  | 描述                              |
| --------------------- | --------------------------------- |
| **plain-capability**  | 一種功能型別（例如提供商專用）    |
| **hybrid-capability** | 多種功能型別（例如提供商 + 語音） |
| **hook-only**         | 僅掛鉤，無功能                    |
| **non-capability**    | 工具/指令/服務但無功能            |

使用 `openclaw plugins inspect <id>` 查看外掛程式的形狀。

## 相關主題

- [SDK Overview](/zh-Hant/plugins/sdk-overview) — 註冊 API 和 subpath 參考
- [Runtime Helpers](/zh-Hant/plugins/sdk-runtime) — `api.runtime` 和 `createPluginRuntimeStore`
- [Setup and Config](/zh-Hant/plugins/sdk-setup) — 清單、設定進入點、延遲載入
- [Channel Plugins](/zh-Hant/plugins/sdk-channel-plugins) — 建構 `ChannelPlugin` 物件
- [Provider Plugins](/zh-Hant/plugins/sdk-provider-plugins) — 提供商註冊和掛鉤
