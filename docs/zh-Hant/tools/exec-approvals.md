---
summary: "Exec approvals、allowlist 及沙箱逃脫提示"
read_when:
  - Configuring exec approvals or allowlists
  - Implementing exec approval UX in the macOS app
  - Reviewing sandbox escape prompts and implications
title: "Exec Approvals（執行許可）"
---

# Exec approvals

Exec approvals 是**配套應用／節點主機護欄**，用於讓沙箱化代理在實際主機（`gateway` 或 `node`）上執行命令。把它當作一個安全互鎖：只有在政策、allowlist 及（可選）使用者許可全都同意時，命令才被允許。
Exec approvals 是**額外的**工具政策及提升的閘控（除非設定了 `elevated: full`，會跳過許可）。
有效政策是 `tools.exec.*` 和 approvals 預設值中**更嚴格的**；如果省略了 approvals 欄位，會使用 `tools.exec` 值。

如果配套應用 UI **不可用**，任何需要提示的請求都由 **ask fallback** 解決（預設：拒絕）。

## 適用的地方

Exec approvals 在執行主機上本地強制執行：

- **gateway host** → gateway 機器上的 `openclaw` 處理程序
- **node host** → node runner（macOS 配套應用或無頭 node host）

macOS 分流：

- **node host service** 透過本地 IPC 將 `system.run` 轉發到 **macOS app**。
- **macOS app** 強制執行許可及在 UI context 中執行命令。

## 設定及儲存

Approvals 存放在執行主機上的本地 JSON 檔案：

`~/.openclaw/exec-approvals.json`

範例架構：

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

## 政策旋鈕

### Security (`exec.security`)

- **deny**：阻止所有主機 exec 請求。
- **allowlist**：僅允許 allowlist 中的命令。
- **full**：允許一切（等同於提升）。

### Ask (`exec.ask`)

- **off**：永不提示。
- **on-miss**：僅當 allowlist 不符合時才提示。
- **always**：每次命令都提示。

### Ask fallback (`askFallback`)

如果需要提示但無法連接到 UI，fallback 決定：

- **deny**：阻止。
- **allowlist**：僅當 allowlist 符合時才允許。
- **full**：允許。

## Allowlist（每個代理）

Allowlist 是**每個代理**的。如果存在多個代理，在 macOS app 中切換要編輯的代理。模式是**不區分大小寫的 glob 符合**。
模式應該解析為**二進位路徑**（僅 basename 的項目被忽略）。
舊版 `agents.default` 項目會在載入時遷移到 `agents.main`。

範例：

- `~/Projects/**/bin/peekaboo`
- `~/.local/bin/*`
- `/opt/homebrew/bin/rg`

每個 allowlist 項目追蹤：

- **id** 用於 UI 識別的穩定 UUID（可選）
- **last used** 時間戳
- **last used command**
- **last resolved path**

## Auto-allow skill CLIs

啟用**Auto-allow skill CLIs** 時，已知技能引用的執行檔在節點上被視為 allowlist（macOS 節點或無頭 node host）。這使用 `skills.bins` 透過 Gateway RPC 取得技能 bin 列表。如果想要嚴格的手動 allowlist，請停用此項。

## Safe bins（stdin-only）

`tools.exec.safeBins` 定義一小列**stdin-only** 二進位檔（例如 `jq`），可以在 allowlist 模式下執行，**無需**明確的 allowlist 項目。Safe bins 拒絕位置檔案引數及類似路徑的符號，因此只能對傳入串流進行操作。
Shell 鏈接及重定向在 allowlist 模式下不會自動允許。

Shell 鏈接（`&&`、`||`、`;`）在每個頂級段都滿足 allowlist 時被允許（包括 safe bins 或技能自動允許）。重定向在 allowlist 模式下仍不支援。
命令替代（`$()`／反引號）在 allowlist 解析期間被拒絕，包括在雙引號內；如果需要字面 `$()` 文字，請使用單引號。

預設 safe bins：`jq`、`grep`、`cut`、`sort`、`uniq`、`head`、`tail`、`tr`、`wc`。

## 控制 UI 編輯

使用 **Control UI → Nodes → Exec approvals** 卡片編輯預設值、每個代理覆蓋及 allowlist。選擇一個範圍（預設或一個代理），調整政策，新增／移除 allowlist 模式，然後**保存**。UI 顯示每個模式的**最後使用**元資料，讓你保持列表整潔。

目標選擇器選擇 **Gateway**（本地許可）或一個 **Node**。節點必須宣傳 `system.execApprovals.get/set`（macOS app 或無頭 node host）。
如果一個節點還沒有宣傳 exec approvals，直接編輯其本地 `~/.openclaw/exec-approvals.json`。

CLI：`openclaw approvals` 支援 gateway 或 node 編輯（見 [Approvals CLI](/zh-Hant/cli/approvals)）。

## 許可流程

需要提示時，gateway 廣播 `exec.approval.requested` 到操作員用戶端。控制 UI 及 macOS app 透過 `exec.approval.resolve` 解決，然後 gateway 轉發已許可的請求到 node host。

需要許可時，exec 工具立即返回一個許可 id。使用該 id 關聯稍後的系統事件（`Exec finished`／`Exec denied`）。如果沒有決定在逾時前到達，請求被視為許可逾時，並作為拒絕原因出現。

確認對話方塊包含：

- 命令及引數
- cwd
- 代理 id
- 解析的執行檔路徑
- host 及政策元資料

動作：

- **Allow once** → 立即執行
- **Always allow** → 新增到 allowlist ＋ 執行
- **Deny** → 阻止

## 許可轉發到聊天頻道

可以將 exec 許可提示轉發到任何聊天頻道（包括外掛頻道），並使用 `/approve` 許可它們。這使用常規出站傳遞管線。

設定：

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

安全注意事項：

- Unix socket 模式 `0600`，token 存放在 `exec-approvals.json`。
- Same-UID peer check。
- Challenge/response（nonce ＋ HMAC token ＋ request hash）＋ 短 TTL。

## 系統事件

Exec 生命週期是作為系統訊息出現的：

- `Exec running`（僅當命令超過執行通知閾值時）
- `Exec finished`
- `Exec denied`

這些在 node 報告事件後發佈到代理的工作階段。
Gateway host exec approvals 在命令完成時（及可選地當執行時間超過閾值時）發出相同的生命週期事件。
許可閘控的 exec 重用許可 id 作為這些訊息中的 `runId` 以便輕鬆關聯。

## 影響

- **full** 很強大；可能的話，優先使用 allowlist。
- **ask** 讓你保持在迴圈中，同時仍允許快速許可。
- 每個代理的 allowlist 防止一個代理的許可洩露到其他代理。
- Approvals 僅適用於來自**已授權寄件者**的主機 exec 請求。未授權的寄件者無法發出 `/exec`。
- `/exec security=full` 是一個工作階段級別的便利，適用於已授權的操作員，根據設計跳過許可。
  若要硬阻止主機 exec，設定 approvals security 為 `deny` 或透過工具政策拒絕 `exec` 工具。

相關：

- [Exec tool](/zh-Hant/tools/exec)
- [Elevated mode](/zh-Hant/tools/elevated)
- [Skills](/zh-Hant/tools/skills)
