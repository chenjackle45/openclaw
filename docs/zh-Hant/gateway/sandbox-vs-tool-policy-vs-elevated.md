---
title: "sandbox-vs-tool-policy-vs-elevated(Sandbox vs Tool Policy vs Elevated)"
summary: "為何工具被阻擋: Sandbox Runtime, Tool Allow/Deny Policy, 與 Elevated Exec Gates"
read_when: "當您遇到 'Sandbox Jail' 或看到 Tool/Elevated 拒絕，並想要知道確切需要更改的 Config Key 時。"
status: active
---

# Sandbox vs Tool Policy vs Elevated

OpenClaw 有三個相關 (但不同) 的控制：

1. **Sandbox** (`agents.defaults.sandbox.*` / `agents.list[].sandbox.*`) 決定 **工具在哪裡運行** (Docker vs Host)。
2. **Tool policy** (`tools.*`, `tools.sandbox.tools.*`, `agents.list[].tools.*`) 決定 **哪些工具是可用/允許的**。
3. **Elevated** (`tools.elevated.*`, `agents.list[].tools.elevated.*`) 是一個 **Exec-only 的逃生艙 (Escape Hatch)**，用於在沙盒化時在主機上運行。

## 快速除錯

使用 Inspector 查看 OpenClaw *實際上* 在做什麼：

```bash
openclaw sandbox explain
openclaw sandbox explain --session agent:main:main
openclaw sandbox explain --agent work
openclaw sandbox explain --json
```

它印出：
- 有效的 Sandbox Mode/Scope/Workspace Access
- Session 目前是否被沙盒化 (Main vs Non-main)
- 有效的 Sandbox Tool Allow/Deny (以及它來自 Agent/Global/Default 的哪一層)
- Elevated Gates 與 Fix-it Key Paths

## Sandbox: 工具在哪裡運行

Sandboxing 由 `agents.defaults.sandbox.mode` 控制：
- `"off"`: 一切都在主機上運行。
- `"non-main"`: 僅沙盒化 **Non-main** Sessions (Groups/Channels 常見的“意外”)。
- `"all"`: 一切都被沙盒化。

參閱 [Sandboxing](/gateway/sandboxing) 取得完整矩陣 (Scope, Workspace Mounts, Images)。

### Bind Mounts (安全性快速檢查)

- `docker.binds` *刺穿* Sandbox Filesystem：您掛載的任何東西在容器內皆可見，並帶有您設定的模式 (`:ro` 或 `:rw`)。
- 若省略模式，預設為 Read-write；對於 Source/Secrets 優先使用 `:ro`。
- `scope: "shared"` 忽略 Per-agent Binds (僅 Global Binds 適用)。
- 綁定 `/var/run/docker.sock` 實際上是將 Host 控制權交給 Sandbox；僅在有意為之時這樣做。
- Workspace Access (`workspaceAccess: "ro"`/`"rw"`) 獨立於 Bind Modes。

## Tool Policy: 哪些工具存在/可呼叫

兩層很重要：
- **Tool profile**: `tools.profile` 與 `agents.list[].tools.profile` (Base Allowlist)
- **Provider tool profile**: `tools.byProvider[provider].profile` 與 `agents.list[].tools.byProvider[provider].profile`
- **Global/per-agent tool policy**: `tools.allow`/`tools.deny` 與 `agents.list[].tools.allow`/`agents.list[].tools.deny`
- **Provider tool policy**: `tools.byProvider[provider].allow/deny` 與 `agents.list[].tools.byProvider[provider].allow/deny`
- **Sandbox tool policy** (僅當 Sandboxed 時適用): `tools.sandbox.tools.allow`/`tools.sandbox.tools.deny` 與 `agents.list[].tools.sandbox.tools.*`

經驗法則：
- `deny` 總是勝出。
- 若 `allow` 非空，其他一切都被視為阻擋。
- Tool Policy 是硬性停止：`/exec` 不能覆蓋被 Denied 的 `exec` Tool。
- `/exec` 僅變更授權發送者的 Session Defaults；它不授予 Tool Access。
Provider Tool Keys 接受 `provider` (例如 `google-antigravity`) 或 `provider/model` (例如 `openai/gpt-5.2`)。

### Tool Groups (Shorthands)

Tool Policies (Global, Agent, Sandbox) 支援 `group:*` 項目，會擴展為多個 Tools：

```json5
{
  tools: {
    sandbox: {
      tools: {
        allow: ["group:runtime", "group:fs", "group:sessions", "group:memory"]
      }
    }
  }
}
```

可用的 Groups：
- `group:runtime`: `exec`, `bash`, `process`
- `group:fs`: `read`, `write`, `edit`, `apply_patch`
- `group:sessions`: `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn`, `session_status`
- `group:memory`: `memory_search`, `memory_get`
- `group:ui`: `browser`, `canvas`
- `group:automation`: `cron`, `gateway`
- `group:messaging`: `message`
- `group:nodes`: `nodes`
- `group:openclaw`: 所有內建 OpenClaw Tools (排除 Provider Plugins)

## Elevated: Exec-only “Run on Host”

Elevated **不** 授予額外 Tools；它僅影響 `exec`。
- 若您被沙盒化，`/elevated on` (或 `exec` 帶 `elevated: true`) 在主機上運行 (Approvals 可能仍適用)。
- 使用 `/elevated full` 跳過 Session 的 Exec Approvals。
- 若您已經直接運行 (Direct)，Elevated 實際上是 No-op (仍被 Gated)。
- Elevated **不是** Skill-scoped 且 **不** 覆蓋 Tool Allow/Deny。
- `/exec` 與 Elevated 是分開的。它僅調整授權發送者的 Per-session Exec Defaults。

Gates:
- Enablement: `tools.elevated.enabled` (以及選用的 `agents.list[].tools.elevated.enabled`)
- Sender Allowlists: `tools.elevated.allowFrom.<provider>` (以及選用的 `agents.list[].tools.elevated.allowFrom.<provider>`)

參閱 [Elevated Mode](/tools/elevated)。

## 常見 “Sandbox Jail” 修復

### “Tool X blocked by sandbox tool policy”

Fix-it Key (挑一個):
- 停用 Sandbox: `agents.defaults.sandbox.mode=off` (或 Per-agent `agents.list[].sandbox.mode=off`)
- 在 Sandbox 內允許該 Tool:
  - 將其從 `tools.sandbox.tools.deny` (或 Per-agent `agents.list[].tools.sandbox.tools.deny`) 移除
  - 或將其新增至 `tools.sandbox.tools.allow` (或 Per-agent Allow)

### “我以為這是 Main，為何被沙盒化？”

在 `"non-main"` 模式下，Group/Channel Keys *不是* Main。使用 Main Session Key (由 `sandbox explain` 顯示) 或將模式切換至 `"off"`。
