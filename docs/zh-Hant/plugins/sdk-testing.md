---
title: "Plugin Testing（Plugin 測試）"
sidebarTitle: "測試"
summary: "Testing utilities and patterns for OpenClaw plugins（OpenClaw 外掛的測試工具與模式）"
read_when:
  - 你正在為外掛寫測試
  - 你需要 plugin SDK 的測試工具
  - 你想理解捆綁外掛的合約測試
---

# Plugin Testing

OpenClaw 外掛的測試工具、模式與 lint 強制的參考。

<Tip>
  **在找測試範例？** How-to 指南包括完整測試範例：[Channel plugin 測試](/zh-Hant/plugins/sdk-channel-plugins#step-6-test) 與 [Provider plugin 測試](/zh-Hant/plugins/sdk-provider-plugins#step-6-test)。
</Tip>

## 測試工具

**Import：** `openclaw/plugin-sdk/testing`

testing subpath 為外掛作者匯出一個窄的輔助函式集：

```typescript
import {
  installCommonResolveTargetErrorCases,
  shouldAckReaction,
  removeAckReactionAfterReply,
} from "openclaw/plugin-sdk/testing";
```

### 可用匯出

| Export                                 | 目的                                 |
| -------------------------------------- | ------------------------------------ |
| `installCommonResolveTargetErrorCases` | Target 解析錯誤處理的共享測試案例    |
| `shouldAckReaction`                    | 檢查 channel 是否應加入 ack reaction |
| `removeAckReactionAfterReply`          | 回覆遞送後移除 ack reaction          |

### 型別

testing subpath 也重新匯出測試檔案中有用的型別：

```typescript
import type {
  ChannelAccountSnapshot,
  ChannelGatewayContext,
  OpenClawConfig,
  PluginRuntime,
  RuntimeEnv,
  MockFn,
} from "openclaw/plugin-sdk/testing";
```

## 測試 target 解析

使用 `installCommonResolveTargetErrorCases` 為 channel target 解析加入標準錯誤案例：

```typescript
import { describe } from "vitest";
import { installCommonResolveTargetErrorCases } from "openclaw/plugin-sdk/testing";

describe("my-channel target 解析", () => {
  installCommonResolveTargetErrorCases({
    resolveTarget: ({ to, mode, allowFrom }) => {
      // 你的 channel target 解析邏輯
      return myChannelResolveTarget({ to, mode, allowFrom });
    },
    implicitAllowFrom: ["user1", "user2"],
  });

  // 加入 channel 特定測試案例
  it("should resolve @username 目標", () => {
    // ...
  });
});
```

## 測試模式

### 單元測試 channel 外掛

```typescript
import { describe, it, expect, vi } from "vitest";

describe("my-channel plugin", () => {
  it("should resolve account from config", () => {
    const cfg = {
      channels: {
        "my-channel": {
          token: "test-token",
          allowFrom: ["user1"],
        },
      },
    };

    const account = myPlugin.setup.resolveAccount(cfg, undefined);
    expect(account.token).toBe("test-token");
  });

  it("should inspect account without materializing secrets", () => {
    const cfg = {
      channels: {
        "my-channel": { token: "test-token" },
      },
    };

    const inspection = myPlugin.setup.inspectAccount(cfg, undefined);
    expect(inspection.configured).toBe(true);
    expect(inspection.tokenStatus).toBe("available");
    // 沒有暴露 token 值
    expect(inspection).not.toHaveProperty("token");
  });
});
```

### 單元測試 provider 外掛

```typescript
import { describe, it, expect } from "vitest";

describe("my-provider plugin", () => {
  it("should resolve dynamic models", () => {
    const model = myProvider.resolveDynamicModel({
      modelId: "custom-model-v2",
      // ... context
    });

    expect(model.id).toBe("custom-model-v2");
    expect(model.provider).toBe("my-provider");
    expect(model.api).toBe("openai-completions");
  });

  it("should return catalog when API key is available", async () => {
    const result = await myProvider.catalog.run({
      resolveProviderApiKey: () => ({ apiKey: "test-key" }),
      // ... context
    });

    expect(result?.provider?.models).toHaveLength(2);
  });
});
```

### Mock plugin runtime

針對使用 `createPluginRuntimeStore` 的代碼，在測試中 mock runtime：

```typescript
import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";
import type { PluginRuntime } from "openclaw/plugin-sdk/runtime-store";

const store = createPluginRuntimeStore<PluginRuntime>("test runtime not set");

// 在測試設定中
const mockRuntime = {
  agent: {
    resolveAgentDir: vi.fn().mockReturnValue("/tmp/agent"),
    // ... 其他 mocks
  },
  config: {
    loadConfig: vi.fn(),
    writeConfigFile: vi.fn(),
  },
  // ... 其他 namespaces
} as unknown as PluginRuntime;

store.setRuntime(mockRuntime);

// 測試後
store.clearRuntime();
```

### 使用每個實例的 stubs 測試

優先使用每個實例的 stubs 而不是原型突變：

```typescript
// 偏好：每個實例的 stub
const client = new MyChannelClient();
client.sendMessage = vi.fn().mockResolvedValue({ id: "msg-1" });

// 避免：原型突變
// MyChannelClient.prototype.sendMessage = vi.fn();
```

## 合約測試（in-repo 外掛）

捆綁外掛有合約測試，驗證註冊所有權：

```bash
pnpm test -- src/plugins/contracts/
```

這些測試聲稱：

- 哪些外掛註冊哪些 provider
- 哪些外掛註冊哪些語音 provider
- 註冊形狀正確性
- Runtime 合約相容性

### 執行範疇測試

針對特定外掛：

```bash
pnpm test -- extensions/my-channel/
```

僅合約測試：

```bash
pnpm test -- src/plugins/contracts/shape.contract.test.ts
pnpm test -- src/plugins/contracts/auth.contract.test.ts
pnpm test -- src/plugins/contracts/runtime.contract.test.ts
```

## Lint 強制（in-repo 外掛）

針對 in-repo 外掛，三個規則由 `pnpm check` 強制：

1. **沒有一元根 imports** -- 拒絕 `openclaw/plugin-sdk` 根 barrel
2. **沒有直接 `src/` imports** -- 外掛無法直接 import `../../src/`
3. **沒有自我 imports** -- 外掛無法 import 自己的 `plugin-sdk/<name>` subpath

外部外掛不受這些 lint 規則約束，但遵循相同模式是推薦的。

## 測試配置

OpenClaw 使用 Vitest 搭配 V8 覆蓋閾值。針對外掛測試：

```bash
# 執行所有測試
pnpm test

# 執行特定外掛測試
pnpm test -- extensions/my-channel/src/channel.test.ts

# 執行搭配特定測試名稱篩選
pnpm test -- extensions/my-channel/ -t "resolves account"

# 執行搭配覆蓋
pnpm test:coverage
```

如果本地執行造成記憶體壓力：

```bash
OPENCLAW_TEST_PROFILE=low OPENCLAW_TEST_SERIAL_GATEWAY=1 pnpm test
```

## 相關

- [SDK 概述](/zh-Hant/plugins/sdk-overview) -- import 慣例
- [SDK Channel 外掛](/zh-Hant/plugins/sdk-channel-plugins) -- channel 外掛介面
- [SDK Provider 外掛](/zh-Hant/plugins/sdk-provider-plugins) -- provider 外掛 hooks
- [建置外掛](/zh-Hant/plugins/building-plugins) -- 入門指南
