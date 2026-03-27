---
title: "OpenShell（OpenShell）"
summary: "使用 OpenShell 作為 OpenClaw 代理的託管沙箱後端"
read_when:
  - 您想要雲端託管沙箱而不是本地 Docker
  - 您正在設定 OpenShell 外掛程式
  - 您需要在 mirror 和 remote workspace modes 之間選擇
---

# OpenShell

OpenShell 是 OpenClaw 的託管沙箱後端。OpenClaw 不是在本地執行 Docker
容器，而是將沙箱生命週期委託給 `openshell` CLI，
它使用基於 SSH 的命令執行來配置遠端環境。

OpenShell 外掛程式重用與通用 [SSH backend](/zh-Hant/gateway/sandboxing#ssh-backend) 相同的核心 SSH 傳輸和遠端檔案系統
橋接。它增加 OpenShell 特定的生命週期（`sandbox create/get/delete`、`sandbox ssh-config`）
和可選的 `mirror` workspace mode。

## 先決條件

- `openshell` CLI 已安裝並在 `PATH` 中（或通過
  `plugins.entries.openshell.config.command` 設定自訂路徑）
- 具有沙箱訪問的 OpenShell 帳戶
- OpenClaw Gateway 在主機上執行

## 快速開始

1. 啟用外掛程式並設定沙箱後端：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        backend: "openshell",
        scope: "session",
        workspaceAccess: "rw",
      },
    },
  },
  plugins: {
    entries: {
      openshell: {
        enabled: true,
        config: {
          from: "openclaw",
          mode: "remote",
        },
      },
    },
  },
}
```

2. 重新啟動 Gateway。在下一個 agent turn，OpenClaw 建立 OpenShell
   沙箱並通過它路由 tool 執行。

3. 驗證：

```bash
openclaw sandbox list
openclaw sandbox explain
```

## Workspace modes

使用 OpenShell 時，這是最重要的決定。

### `mirror`

當您想要 **本地 workspace 保持規範** 時，使用 `plugins.entries.openshell.config.mode: "mirror"`。

行為：

- 在 `exec` 前，OpenClaw 將本地 workspace 同步到 OpenShell 沙箱中。
- 在 `exec` 後，OpenClaw 將遠端 workspace 同步回本地 workspace。
- File tools 仍通過沙箱橋接運作，但本地 workspace
  在 turns 之間保持是事實來源。

最適合：

- 您在 OpenClaw 外本地編輯檔案，並希望這些更改在
  沙箱中自動可見。
- 您希望 OpenShell 沙箱盡可能表現得像 Docker 後端。
- 您希望主機 workspace 在每次 exec turn 後反映沙箱寫入。

權衡：在每次 exec 前後進行額外同步成本。

### `remote`

當您想要 **OpenShell workspace 成為規範** 時，使用 `plugins.entries.openshell.config.mode: "remote"`。

行為：

- 當沙箱首次建立時，OpenClaw 一次從
  本地 workspace 播種遠端 workspace。
- 在那之後，`exec`、`read`、`write`、`edit` 和 `apply_patch` 運作
  直接針對遠端 OpenShell workspace。
- OpenClaw 不會將遠端更改同步回本地 workspace。
- Prompt-time media reads 仍然有效，因為 file 和 media tools 通過
  沙箱橋接讀取。

最適合：

- 沙箱應主要存在於遠端。
- 您想要較低的 per-turn 同步開銷。
- 您不希望主機本地編輯在沒有提示的情況下覆蓋遠端沙箱狀態。

重要：如果您在初始播種後在 OpenClaw 外的主機上編輯檔案，
遠端沙箱不會看到那些更改。使用
`openclaw sandbox recreate` 重新播種。

### 選擇 mode

|                    | `mirror`             | `remote`             |
| ------------------ | -------------------- | -------------------- |
| **規範 workspace** | 本地主機             | 遠端 OpenShell       |
| **同步方向**       | 雙向（每 exec）      | 一次播種             |
| **Per-turn 開銷**  | 更高（上傳 + 下載）  | 更低（直接遠端操作） |
| **本地編輯可見？** | 是，在下一個 exec 上 | 否，直到 recreate    |
| **最適合**         | 開發工作流           | 長執行代理、CI       |

## 設定參考

所有 OpenShell 設定位於 `plugins.entries.openshell.config` 下：

| 金鑰                      | 類型                     | 預設值        | 說明                                               |
| ------------------------- | ------------------------ | ------------- | -------------------------------------------------- |
| `mode`                    | `"mirror"` 或 `"remote"` | `"mirror"`    | Workspace 同步 mode                                |
| `command`                 | `string`                 | `"openshell"` | `openshell` CLI 的路徑或名稱                       |
| `from`                    | `string`                 | `"openclaw"`  | 首次建立的沙箱來源                                 |
| `gateway`                 | `string`                 | —             | OpenShell gateway 名稱（`--gateway`）              |
| `gatewayEndpoint`         | `string`                 | —             | OpenShell gateway 端點 URL（`--gateway-endpoint`） |
| `policy`                  | `string`                 | —             | OpenShell policy ID 進行沙箱建立                   |
| `providers`               | `string[]`               | `[]`          | 建立沙箱時附加的提供者名稱                         |
| `gpu`                     | `boolean`                | `false`       | 請求 GPU 資源                                      |
| `autoProviders`           | `boolean`                | `true`        | 在沙箱建立期間傳遞 `--auto-providers`              |
| `remoteWorkspaceDir`      | `string`                 | `"/sandbox"`  | 沙箱內的主要可寫 workspace                         |
| `remoteAgentWorkspaceDir` | `string`                 | `"/agent"`    | Agent workspace 掛載路徑（供唯讀訪問）             |
| `timeoutSeconds`          | `number`                 | `120`         | `openshell` CLI 操作的逾時                         |

Sandbox 層級設定（`mode`、`scope`、`workspaceAccess`）在
`agents.defaults.sandbox` 下設定，如任何後端。參見
[Sandboxing](/zh-Hant/gateway/sandboxing) 以了解完整矩陣。

## 範例

### 最小遠端設定

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        backend: "openshell",
      },
    },
  },
  plugins: {
    entries: {
      openshell: {
        enabled: true,
        config: {
          from: "openclaw",
          mode: "remote",
        },
      },
    },
  },
}
```

### Mirror mode 搭配 GPU

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        backend: "openshell",
        scope: "agent",
        workspaceAccess: "rw",
      },
    },
  },
  plugins: {
    entries: {
      openshell: {
        enabled: true,
        config: {
          from: "openclaw",
          mode: "mirror",
          gpu: true,
          providers: ["openai"],
          timeoutSeconds: 180,
        },
      },
    },
  },
}
```

### Per-agent OpenShell 搭配自訂 gateway

```json5
{
  agents: {
    defaults: {
      sandbox: { mode: "off" },
    },
    list: [
      {
        id: "researcher",
        sandbox: {
          mode: "all",
          backend: "openshell",
          scope: "agent",
          workspaceAccess: "rw",
        },
      },
    ],
  },
  plugins: {
    entries: {
      openshell: {
        enabled: true,
        config: {
          from: "openclaw",
          mode: "remote",
          gateway: "lab",
          gatewayEndpoint: "https://lab.example",
          policy: "strict",
        },
      },
    },
  },
}
```

## 生命週期管理

OpenShell 沙箱通過正常 sandbox CLI 管理：

```bash
# 列出所有 sandbox runtimes（Docker + OpenShell）
openclaw sandbox list

# 檢查有效政策
openclaw sandbox explain

# Recreate（刪除遠端 workspace，在下次使用時重新播種）
openclaw sandbox recreate --all
```

對於 `remote` mode，**recreate 特別重要**：它刪除該範圍的規範
遠端 workspace。下次使用時播種一個新的遠端 workspace，來自
本地 workspace。

對於 `mirror` mode，recreate 主要重置遠端執行環境，因為
本地 workspace 保持規範。

### 何時 recreate

在更改任何這些後 recreate：

- `agents.defaults.sandbox.backend`
- `plugins.entries.openshell.config.from`
- `plugins.entries.openshell.config.mode`
- `plugins.entries.openshell.config.policy`

```bash
openclaw sandbox recreate --all
```

## 當前限制

- OpenShell 後端上不支援 Sandbox browser。
- `sandbox.docker.binds` 不適用於 OpenShell。
- `sandbox.docker.*` 下的 Docker 特定執行時旋鈕僅適用於 Docker
  後端。

## 運作方式

1. OpenClaw 呼叫 `openshell sandbox create`（帶有 `--from`、`--gateway`、
   `--policy`、`--providers`、`--gpu` flags 如配置）。
2. OpenClaw 呼叫 `openshell sandbox ssh-config <name>` 獲取 SSH 連接
   沙箱的詳情。
3. Core 將 SSH 設定寫入臨時檔案並使用相同的遠端檔案系統橋接打開 SSH session，如通用 SSH 後端。
4. 在 `mirror` mode：在 exec 前同步本地到遠端，執行，在 exec 後同步回。
5. 在 `remote` mode：在建立時播種一次，然後直接在遠端
   workspace 上運作。

## 另見

- [Sandboxing](/zh-Hant/gateway/sandboxing) -- modes、scopes 和後端比較
- [Sandbox vs Tool Policy vs Elevated](/zh-Hant/gateway/sandbox-vs-tool-policy-vs-elevated) -- 調試被阻止的 tools
- [Multi-Agent Sandbox and Tools](/zh-Hant/tools/multi-agent-sandbox-tools) -- per-agent 覆蓋
- [Sandbox CLI](/zh-Hant/cli/sandbox) -- `openclaw sandbox` 指令
