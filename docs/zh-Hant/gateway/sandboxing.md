---
title: "sandboxing(Sandboxing)"
summary: "OpenClaw Sandboxing 如何運作: Modes, Scopes, Workspace Access, 與 Images"
read_when: "您想要 Sandboxing 的專門解釋或需要調整 agents.defaults.sandbox 時。"
status: active
---

# 沙盒化 (Sandboxing)

OpenClaw 可以 **在 Docker 容器內運行工具** 以減少爆炸半徑 (Blast Radius)。
這是 **選用** 的，並由組態控制 (`agents.defaults.sandbox` 或 `agents.list[].sandbox`)。若 Sandboxing 關閉，工具會在主機上運行。
Gateway 留在主機上；啟用時，工具執行會在隔離的 Sandbox 中運行。

這不是完美的安全性邊界，但當模型做出愚蠢行為時，它能實質限制 Filesystem 與 Process Access。

## 什麼會被沙盒化
- 工具執行 (`exec`, `read`, `write`, `edit`, `apply_patch`, `process` 等)。
- 選用的 Sandboxed Browser (`agents.defaults.sandbox.browser`)。
  - 預設情況下，當 Browser Tool 需要時，Sandbox Browser 會自動啟動 (確保 CDP 可達)。
    透過 `agents.defaults.sandbox.browser.autoStart` 與 `agents.defaults.sandbox.browser.autoStartTimeoutMs` 設定。
  - `agents.defaults.sandbox.browser.allowHostControl` 讓沙盒化的 Sessions 顯式目標主機瀏覽器。
  - 選用的 Allowlists 用於 控管 `target: "custom"`: `allowedControlUrls`, `allowedControlHosts`, `allowedControlPorts`。

不被沙盒化：
- Gateway Process 本身。
- 任何顯式允許在主機上運行的工具 (例如 `tools.elevated`)。
  - **Elevated Exec 在主機上運行並繞過 Sandboxing。**
  - 若 Sandboxing 關閉，`tools.elevated` 不會改變執行 (已在主機上)。參閱 [Elevated Mode](/tools/elevated)。

## 模式 (Modes)
`agents.defaults.sandbox.mode` 控制 **何時** 使用 Sandboxing：
- `"off"`: 不沙盒化。
- `"non-main"`: 僅沙盒化 **Non-main** Sessions (若您想要正常聊天在主機上，這是預設值)。
- `"all"`: 每個 Session 都在 Sandbox 中運行。
註記: `"non-main"` 是基於 `session.mainKey` (預設 `"main"`)，而非 Agent ID。
Group/Channel Sessions 使用其自己的 Keys，因此它們算作 Non-main 且會被沙盒化。

## 範圍 (Scope)
`agents.defaults.sandbox.scope` 控制 **建立多少個容器**：
- `"session"` (預設): 每個 Session 一個容器。
- `"agent"`: 每個 Agent 一個容器。
- `"shared"`: 所有 Sandboxed Sessions 共用一個容器。

## Workspace 存取 (Workspace Access)
`agents.defaults.sandbox.workspaceAccess` 控制 **Sandbox 能看到什麼**：
- `"none"` (預設): 工具看到位於 `~/.openclaw/sandboxes` 下的 Sandbox Workspace。
- `"ro"`: 將 Agent Workspace 以唯讀掛載至 `/agent` (停用 `write`/`edit`/`apply_patch`)。
- `"rw"`: 將 Agent Workspace 以讀寫掛載至 `/workspace`。

Inbound Media 會被複製到主動 Sandbox Workspace (`media/inbound/*`)。
Skills 註記: `read` 工具是 Sandbox-rooted。設定 `workspaceAccess: "none"` 時，OpenClaw 將合格的 Skills 鏡像至 Sandbox Workspace (`.../skills`) 以便讀取。設定 `"rw"` 時，Workspace Skills 可從 `/workspace/skills` 讀取。

## 自訂 Bind Mounts
`agents.defaults.sandbox.docker.binds` 將額外的主機目錄掛載至容器中。
格式: `host:container:mode` (例如 `"/home/user/source:/source:rw"`)。

Global 與 Per-agent Binds 會被 **合併** (非取代)。在 `scope: "shared"` 下，Per-agent Binds 被忽略。

範例 (唯讀 Source + Docker Socket):

```json5
{
  agents: {
    defaults: {
      sandbox: {
        docker: {
          binds: [
            "/home/user/source:/source:ro",
            "/var/run/docker.sock:/var/run/docker.sock"
          ]
        }
      }
    },
    list: [
      {
        id: "build",
        sandbox: {
          docker: {
            binds: ["/mnt/cache:/cache:rw"]
          }
        }
      }
    ]
  }
}
```

安全性註記:
- Binds 繞過 Sandbox Filesystem：它們以您設定的任何模式 (`:ro` 或 `:rw`) 暴露 Host Paths。
- 機密掛載 (例如 `docker.sock`, Secrets, SSH Keys) 除非絕對必要，否則應設為 `:ro`。
- 若您僅需 Workspace 的 Read Access，請結合 `workspaceAccess: "ro"`；Bind Modes 保持獨立。
- 參閱 [Sandbox vs Tool Policy vs Elevated](/gateway/sandbox-vs-tool-policy-vs-elevated) 以了解 Binds 如何與 Tool Policy 及 Elevated Exec 互動。

## Images + Setup
預設 Image: `openclaw-sandbox:bookworm-slim`

建置一次:
```bash
scripts/sandbox-setup.sh
```

註記: 預設 Image **不** 包含 Node。若 Skill 需要 Node (或其他 Runtimes)，請自行 bake 自訂 Image 或透過 `sandbox.docker.setupCommand` 安裝 (需要 Network Egress + Writable Root + Root User)。

Sandboxed Browser Image:
```bash
scripts/sandbox-browser-setup.sh
```

預設情況下，Sandbox 容器以 **無網路 (No Network)** 運行。
透過 `agents.defaults.sandbox.docker.network` 覆蓋。

Docker 安裝與容器化 Gateway 位於此處：
[Docker](/install/docker)

## setupCommand (一次性容器設定)
`setupCommand` 在 Sandbox 容器建立後運行 **一次** (非每次執行)。
它透過 `sh -lc` 在容器內執行。

路徑:
- Global: `agents.defaults.sandbox.docker.setupCommand`
- Per-agent: `agents.list[].sandbox.docker.setupCommand`


常見陷阱:
- 預設 `docker.network` 為 `"none"` (無 Egress)，因此 Package 安裝會失敗。
- `readOnlyRoot: true` 阻止寫入；設定 `readOnlyRoot: false` 或 bake 自訂 Image。
- `user` 必須為 Root 以進行 Package 安裝 (省略 `user` 或設定 `user: "0:0"`)。
- Sandbox Exec **不** 繼承 Host `process.env`。使用 `agents.defaults.sandbox.docker.env` (或自訂 Image) 來設定 Skill API Keys。

## Tool Policy + Escape Hatches
Tool Allow/Deny Policies 仍在 Sandbox 規則之前適用。若工具在 Global 或 Per-agent 被拒絕，Sandboxing 不會將其帶回。

`tools.elevated` 是顯式的 Escape Hatch，在主機上運行 `exec`。
`/exec` 指令僅適用於授權發送者並 Per Session 持久化；要硬性停用 `exec`，使用 Tool Policy Deny (參閱 [Sandbox vs Tool Policy vs Elevated](/gateway/sandbox-vs-tool-policy-vs-elevated))。

除錯:
- 使用 `openclaw sandbox explain` 檢查有效的 Sandbox Mode, Tool Policy, 與 Fix-it Config Keys。
- 參閱 [Sandbox vs Tool Policy vs Elevated](/gateway/sandbox-vs-tool-policy-vs-elevated) 以了解“為何這被阻擋？”的心智模型。
保持它鎖定。

## Multi-agent Overrides
每個 Agent 可以覆蓋 Sandbox + Tools:
`agents.list[].sandbox` 與 `agents.list[].tools` (加上 `agents.list[].tools.sandbox.tools` 用於 Sandbox Tool Policy)。
參閱 [Multi-Agent Sandbox & Tools](/multi-agent-sandbox-tools) 了解優先順序。

## 最小啟用範例
```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",
        scope: "session",
        workspaceAccess: "none"
      }
    }
  }
}
```

## 相關文件
- [Sandbox Configuration](/gateway/configuration#agentsdefaults-sandbox)
- [Multi-Agent Sandbox & Tools](/multi-agent-sandbox-tools)
- [Security](/gateway/security)
