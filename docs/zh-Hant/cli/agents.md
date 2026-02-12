---
title: "agents（Agent 管理）"
summary: "`openclaw agents` CLI 參考（列表、新增、刪除與身分設定）"
read_when:
  - 想要使用多個隔離的 Agent（包含獨立工作區、路由與認證）時
---

# `openclaw agents`

管理隔離的 Agent（包含工作區、認證與路由）。

相關資訊：

- 多 Agent 路由導覽：[多 Agent 路由 (Multi-Agent Routing)](/zh-Hant/concepts/multi-agent)
- Agent 工作區說明：[Agent 工作區 (Agent workspace)](/zh-Hant/concepts/agent-workspace)

## 指令範例

```bash
# 列出目前的 Agent
openclaw agents list

# 新增一個名為 work 的 Agent 並指定其工作區路徑
openclaw agents add work --workspace ~/.openclaw/workspace-work

# 從工作區目錄的描述檔讀取並設定身分
openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity

# 手動設定特定 Agent 的名稱、Emoji 與頭像
openclaw agents set-identity --agent main --name "小助" --emoji "🦞" --avatar avatars/openclaw.png

# 刪除特定的 Agent
openclaw agents delete work
```

## 身分識別檔案 (Identity files)

每個 Agent 的工作區根目錄可以包含一個 `IDENTITY.md` 檔案：

- 預設路徑：`~/.openclaw/workspace/IDENTITY.md`
- `set-identity --from-identity`：從工作區根目錄（或指定的 `--identity-file`）讀取資訊。

頭像路徑將相對於工作區根目錄進行解析。

## 設定身分 (Set identity)

`set-identity` 指令會將欄位寫入配置檔案的 `agents.list[].identity` 中：

- `name`：顯示名稱。
- `theme`：主題描述。
- `emoji`：代表表情符號。
- `avatar`：頭像（支援工作區相對路徑、http(s) 網址或 Data URI）。

從 `IDENTITY.md` 載入：

```bash
openclaw agents set-identity --workspace ~/.openclaw/workspace --from-identity
```

手動覆寫特定欄位：

```bash
openclaw agents set-identity --agent main --name "OpenClaw" --emoji "🦞" --avatar avatars/openclaw.png
```

配置範例：

```json5
{
  agents: {
    list: [
      {
        id: "main",
        identity: {
          name: "OpenClaw",
          theme: "太空龍蝦",
          emoji: "🦞",
          avatar: "avatars/openclaw.png",
        },
      },
    ],
  },
}
```
