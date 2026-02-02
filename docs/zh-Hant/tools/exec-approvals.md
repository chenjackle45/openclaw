---
summary: "Exec approvals, allowlists, and sandbox escape prompts"
read_when:
  - Configuring exec approvals or allowlists
  - Implementing exec approval UX in the macOS app
  - Reviewing sandbox escape prompts and implications
title: "Exec Approvals"
---

# Exec approvals

Exec 核准是 **companion app / node host 防護欄**，用於讓沙盒化的 Agent 在真實 host（`gateway` 或 `node`）執行
指令。把它想成像安全聯鎖：
只有當策略 + allowlist + （選用）使用者核准都同意時，才允許指令。
Exec 核准是**額外的**到工具策略和提權門（除非提權設定為 `full`，其跳過核准）。
有效策略是 `tools.exec.*` 和核准預設的**較嚴格者**；如果核准欄位被省略，會使用 `tools.exec` 值。

如果 companion app UI **不可用**，任何需要提示的要求
由 **ask fallback** 解析（預設：deny）。

## 應用位置

Exec 核准在執行 host 上本地強制執行：

- **gateway host** → gateway 機器上的 `openclaw` 進程
- **node host** → node 執行器（macOS companion app 或 headless node host）

macOS 分割：

- **node host 服務**轉發 `system.run` 到**macOS app** over local IPC。
- **macOS app** 強制核准 + 在 UI 内容中執行指令。

## 設定和儲存

核准位於執行 host 上的本地 JSON 檔案：

`~/.openclaw/exec-approvals.json`

範例 schema：

```json
{
  "version": 1,
  "socket": {
    "path": "~/.openclaw/exec-approvals.sock",
    "token": "base64url-token"
  },
  "defaults": {
    "security": "deny",
    "ask": "on-miss",
    "askFallback": "deny",
    "autoAllowSkills": false
  },
  "agents": {
    "main": {
      "security": "allowlist",
      "ask": "on-miss",
      "askFallback": "deny",
      "autoAllowSkills": true,
      "allowlist": [
        {
          "id": "B0C8C0B3-2C2D-4F8A-9A3C-5A4B3C2D1E0F",
          "pattern": "~/Projects/**/bin/rg",
          "lastUsedAt": 1737150000000,
          "lastUsedCommand": "rg -n TODO",
          "lastResolvedPath": "/Users/user/Projects/.../bin/rg"
        }
      ]
    }
  }
}
```

## 策略旋鈕

### Security (`exec.security`)

- **deny**：封鎖所有 host exec 要求。
- **allowlist**：只允許 allowlist 的指令。
- **full**：允許所有（相當於提權）。

### Ask (`exec.ask`)

- **off**：永不提示。
- **on-miss**：僅當 allowlist 不符時提示。
- **always**：針對每個指令提示。

### Ask fallback (`askFallback`)

如果需要提示但無 UI 可達，fallback 決定：

- **deny**：封鎖。
- **allowlist**：只在 allowlist 符合時允許。
- **full**：允許。

## Allowlist（per agent）

Allowlist 是 **per agent**。如果多個 agent 存在，在 macOS app 中切換編輯的 agent。Pattern 是 **case-insensitive glob match**。
Pattern 應解析為**二進位路徑**（僅限基名稱的項目會被忽略）。
舊版 `agents.default` 項目在載入時會遷移到 `agents.main`。

範例：

- `~/Projects/**/bin/bird`
- `~/.local/bin/*`
- `/opt/homebrew/bin/rg`

每個 allowlist 項目會追蹤：

- **id** 用於 UI 身份的穩定 UUID（選用）
- **last used** 時間戳
- **last used command**
- **last resolved path**

## 自動允許 skill CLIs

當**自動允許 skill CLIs** 啟用時，已知 skill 參考的執行檔
會在節點上被視為 allowlist（macOS node 或 headless node host）。這使用
透過 Gateway RPC `skills.bins` 取得 skill bin 清單。如果想要嚴格的手動 allowlist，請停用。

## Safe bins（stdin 專用）

`tools.exec.safeBins` 定義一個小型**stdin 專用** 二進位檔案清單（例如 `jq`）
可以在 allowlist 模式中執行**而不需**明確 allowlist 項目。Safe bins 拒絕
位置檔案 args 和類似路徑的權杖，所以它們只能在傳入串流上操作。
Shell chaining 和重定向在 allowlist 模式中不會自動允許。

Shell chaining（`&&`、`||`、`;`）在每個頂層段都滿足 allowlist 時允許
（包括 safe bins 或 skill 自動允許）。重定向在 allowlist 模式中仍不支援。

預設 safe bins：`jq`、`grep`、`cut`、`sort`、`uniq`、`head`、`tail`、`tr`、`wc`。

## 控制 UI 編輯

使用 **Control UI → Nodes → Exec approvals** 卡編輯預設值、per-agent
覆寫和 allowlist。挑選範圍（預設或 agent）、調整策略、
新增/移除 allowlist pattern，然後**儲存**。UI 顯示**最後使用**中繼資料
每個 pattern，讓您可以保持清單整潔。

目標選擇器選擇 **Gateway**（本地核准）或 **Node**。Node
必須公告 `system.execApprovals.get/set`（macOS app 或 headless node host）。
如果節點尚未公告 exec 核准，直接編輯其本地
`~/.openclaw/exec-approvals.json`。

CLI：`openclaw approvals` 支援 gateway 或 node 編輯（見 [Approvals CLI](/cli/approvals)）。

## 核准流程

當需要提示時，gateway 廣播 `exec.approval.requested` 到操作者客戶端。
Control UI 和 macOS app 透過 `exec.approval.resolve` 解析它，然後 gateway 轉發
已核准要求到 node host。

當需要核准時，exec 工具立即回傳核准 ID。使用該 ID 與
後來系統事件（`Exec finished` / `Exec denied`）相關聯。如果沒有決定在
逾時前到達，要求會被視為核准逾時並呈現為拒絕原因。

確認對話包含：

- command + args
- cwd
- agent id
- 解析的執行檔路徑
- host + 策略中繼資料

動作：

- **Allow once** → 現在執行
- **Always allow** → 新增到 allowlist + 執行
- **Deny** → 封鎖

## 核准轉發到聊天 channel

您可以轉發 exec 核准提示到任何聊天 channel（包括外掛 channel）並核准
它們用 `/approve`。這使用正常的出站傳遞管道。

Config：

```json5
{
  approvals: {
    exec: {
      enabled: true,
      mode: "session", // "session" | "targets" | "both"
      agentFilter: ["main"],
      sessionFilter: ["discord"], // substring or regex
      targets: [
        { channel: "slack", to: "U12345678" },
        { channel: "telegram", to: "123456789" },
      ],
    },
  },
}
```

在聊天中回覆：

```
/approve <id> allow-once
/approve <id> allow-always
/approve <id> deny
```

### macOS IPC 流程

```
Gateway -> Node Service (WS)
                 |  IPC (UDS + token + HMAC + TTL)
                 v
             Mac App (UI + approvals + system.run)
```

安全筆記：

- Unix socket 模式 `0600`、權杖存放在 `exec-approvals.json`。
- 相同 UID peer 檢查。
- 挑戰/回應（nonce + HMAC 權杖 + 要求雜湊）+ 短 TTL。

## 系統事件

Exec 生命週期呈現為系統訊息：

- `Exec running`（只有在指令超過執行通知閾值時）
- `Exec finished`
- `Exec denied`

這些會張貼到 agent 的會話，在 node 報告事件後。
Gateway-host exec 核准會在指令完成時發出相同的生命週期事件（以及選用地當執行時間超過閾值時）。
核准限制的 execs 會重用核准 ID 作為這些訊息中的 `runId`，以方便相關聯。

## 含意

- **full** 強大；盡可能偏好 allowlist。
- **ask** 讓您保持迴圈同時仍允許快速核准。
- Per-agent allowlist 防止一個 agent 的核准洩漏到其他。
- 核准只適用於 host exec 要求來自**授權寄件者**。未授權寄件者無法發出 `/exec`。
- `/exec security=full` 是授權操作者的會話層級便利性，設計上跳過核准。
  要硬封鎖 host exec，設定核准 security 為 `deny` 或透過工具策略否定 `exec` 工具。

相關：

- [Exec tool](/tools/exec)
- [Elevated mode](/tools/elevated)
- [Skills](/tools/skills)
