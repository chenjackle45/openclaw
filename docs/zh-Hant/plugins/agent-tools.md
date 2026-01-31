---
title: "Agent tools(Plugin Agent Tools)"
summary: "在 Plugin 中撰寫 Agent Tools（Schemas、Optional Tools、Allowlists）"
read_when:
  - 您想在 Plugin 中新增新的 Agent Tool
  - 您需要透過 Allowlists 使 Tool 成為 Opt-in
---
# Plugin Agent Tools

OpenClaw Plugins 可以註冊**Agent Tools**（JSON-schema Functions），在 Agent Run 期間向 LLM 公開。Tools 可以是**Required**（始終可用）或**Optional**（Opt-in）。

Agent Tools 在主要 Config 的 `tools` 下設定，或在 `agents.list[].tools` 下 Per-agent 設定。Allowlist/Denylist Policy 控制 Agent 可以呼叫哪些 Tools。

## 基本 Tool

```ts
import { Type } from "@sinclair/typebox";

export default function (api) {
  api.registerTool({
    name: "my_tool",
    description: "Do a thing",
    parameters: Type.Object({
      input: Type.String(),
    }),
    async execute(_id, params) {
      return { content: [{ type: "text", text: params.input }] };
    },
  });
}
```

## Optional Tool（Opt-in）

Optional Tools **永遠不會**自動啟用。使用者必須將它們新增到 Agent Allowlist。

```ts
export default function (api) {
  api.registerTool(
    {
      name: "workflow_tool",
      description: "Run a local workflow",
      parameters: {
        type: "object",
        properties: {
          pipeline: { type: "string" },
        },
        required: ["pipeline"],
      },
      async execute(_id, params) {
        return { content: [{ type: "text", text: params.pipeline }] };
      },
    },
    { optional: true },
  );
}
```

在 `agents.list[].tools.allow`（或 Global `tools.allow`）中啟用 Optional Tools：

```json5
{
  agents: {
    list: [
      {
        id: "main",
        tools: {
          allow: [
            "workflow_tool",  // 特定 Tool 名稱
            "workflow",       // Plugin ID（啟用該 Plugin 的所有 Tools）
            "group:plugins"   // 所有 Plugin Tools
          ]
        }
      }
    ]
  }
}
```

影響 Tool 可用性的其他 Config 設定：
- 僅命名 Plugin Tools 的 Allowlists 被視為 Plugin Opt-ins；除非您也在 Allowlist 中包含 Core Tools 或 Groups，否則 Core Tools 保持啟用。
- `tools.profile` / `agents.list[].tools.profile`（基礎 Allowlist）
- `tools.byProvider` / `agents.list[].tools.byProvider`（Provider-specific Allow/Deny）
- `tools.sandbox.tools.*`（Sandboxed 時的 Sandbox Tool Policy）

## 規則 + 提示

- Tool 名稱**不得**與 Core Tool 名稱衝突；衝突的 Tools 會被略過。
- Allowlists 中使用的 Plugin IDs 不得與 Core Tool 名稱衝突。
- 對於會觸發副作用或需要額外二進位檔案/憑證的 Tools，建議使用 `optional: true`。
