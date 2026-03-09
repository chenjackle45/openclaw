---
summary: "Exec approvals、allowlists 及沙箱逃脫提示"
read_when:
  - 設定 exec approvals 或 allowlists
  - 在 macOS app 中實作 exec approval UX
  - 審查沙箱逃脫提示及其含義
title: "Exec Approvals（執行審批）"
---

# Exec approvals

Exec approvals 是**companion app / 節點主機護欄**，用於讓沙箱化 agent 在真實主機（`gateway` 或 `node`）上執行命令。把它想成一個安全互鎖：只有當政策 + allowlist + （選用）使用者審批全部同意時，命令才被允許。Exec approvals 是工具政策和提升閘控（除非提升設定為 `full`，這會跳過 approvals）的**補充**。有效政策是 `tools.exec.*` 和 approvals 預設值中**較嚴格**的那個；若省略 approvals 欄位，則使用 `tools.exec` 值。

若 companion app UI **不可用**，任何需要提示的請求都由 **ask fallback** 解決（預設：拒絕）。

## 適用範圍

Exec approvals 在執行主機本地執行：

- **gateway 主機** → gateway 機器上的 `openclaw` 程序
- **節點主機** → 節點執行器（macOS companion app 或 headless 節點主機）

信任模型注意：

- Gateway 已驗證的呼叫者對該 Gateway 而言是受信任的操作者。
- 已配對的節點將該受信任的操作者能力延伸至節點主機。
- Exec approvals 降低意外執行風險，但不是每個使用者的驗證邊界。
- 已審批的節點主機執行也會綁定正規執行 context：正規 cwd、在適用時固定的可執行路徑，以及 interpreter 式指令碼操作數。若已綁定的指令碼在審批後但執行前發生變更，執行被拒絕而非執行漂移的內容。

macOS 分工：

- **節點主機服務**透過本地 IPC 將 `system.run` 轉發至 **macOS app**。
- **macOS app** 在 UI context 中執行 approvals + 執行命令。

## 設定和儲存

Approvals 儲存在執行主機的本地 JSON 檔案中：

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

## 政策設定

### Security（`exec.security`）

- **deny**：封鎖所有 host exec 請求。
- **allowlist**：僅允許 allowlisted 命令。
- **full**：允許所有（等同於提升）。

### Ask（`exec.ask`）

- **off**：永不提示。
- **on-miss**：僅在 allowlist 不符時提示。
- **always**：每個命令都提示。

### Ask fallback（`askFallback`）

若需要提示但無 UI 可達，fallback 決定：

- **deny**：封鎖。
- **allowlist**：僅在 allowlist 符合時允許。
- **full**：允許。

## Allowlist（每個 agent）

Allowlists 是**每個 agent** 的。若有多個 agent，在 macOS app 中切換你正在編輯的 agent。模式是**不區分大小寫的 glob 比對**。模式應解析為**二進位路徑**（僅基本名稱的項目被忽略）。舊版 `agents.default` 項目在載入時遷移至 `agents.main`。

範例：

- `~/Projects/**/bin/peekaboo`
- `~/.local/bin/*`
- `/opt/homebrew/bin/rg`

每個 allowlist 項目追蹤：

- **id** 用於 UI 識別的穩定 UUID（選用）
- **最後使用**時間戳記
- **最後使用的命令**
- **最後解析的路徑**

## 自動允許 skill CLI

啟用 **Auto-allow skill CLIs** 時，已知 skills 所引用的可執行檔在節點（macOS 節點或 headless 節點主機）上被視為 allowlisted。這使用 Gateway RPC 上的 `skills.bins` 獲取 skill bin 清單。若你需要嚴格的手動 allowlists，停用此功能。

重要信任注意：

- 這是一個**隱式便利 allowlist**，與手動路徑 allowlist 項目分開。
- 它適用於 Gateway 和節點在同一信任邊界內的受信任操作者環境。
- 若你需要嚴格的明確信任，保持 `autoAllowSkills: false` 並僅使用手動路徑 allowlist 項目。

## Safe bins（僅 stdin）

`tools.exec.safeBins` 定義一小份**僅限 stdin** 的二進位清單（例如 `jq`），可在 allowlist 模式下**不需要**明確 allowlist 項目執行。Safe bins 拒絕位置檔案引數和路徑式 token，因此它們只能操作傳入串流。將其視為串流過濾器的狹窄快速路徑，而非通用信任清單。**不要**將 interpreter 或 runtime 二進位（例如 `python3`、`node`、`ruby`、`bash`、`sh`、`zsh`）新增至 `safeBins`。若命令可以評估程式碼、執行子命令或設計上讀取檔案，優先使用明確的 allowlist 項目並保持 approval 提示啟用。自訂 safe bins 必須在 `tools.exec.safeBinProfiles.<bin>` 中定義明確的 profile。驗證僅從 argv 形狀確定性地進行（不檢查主機檔案系統存在），這防止了 allow/deny 差異的檔案存在 oracle 行為。對預設 safe bins 拒絕以檔案為導向的選項（例如 `sort -o`、`sort --output`、`sort --files0-from`、`sort --compress-program`、`sort --random-source`、`sort --temporary-directory`/`-T`、`wc --files0-from`、`jq -f/--from-file`、`grep -f/--file`）。Safe bins 也為破壞僅 stdin 行為的選項執行明確的每個二進位旗標政策（例如 `sort -o/--output/--compress-program` 和 grep 遞迴旗標）。在 safe-bin 模式下，長選項以失敗關閉方式驗證：未知旗標和模糊縮寫被拒絕。Safe-bin profile 拒絕的旗標：

<!-- SAFE_BIN_DENIED_FLAGS:START -->

- `grep`：`--dereference-recursive`、`--directories`、`--exclude-from`、`--file`、`--recursive`、`-R`、`-d`、`-f`、`-r`
- `jq`：`--argfile`、`--from-file`、`--library-path`、`--rawfile`、`--slurpfile`、`-L`、`-f`
- `sort`：`--compress-program`、`--files0-from`、`--output`、`--random-source`、`--temporary-directory`、`-T`、`-o`
- `wc`：`--files0-from`
<!-- SAFE_BIN_DENIED_FLAGS:END -->

Safe bins 也在執行時將 argv token 強制視為**純文字**（不展開 glob，不展開 `$VARS`）用於僅 stdin 的區段，因此 `*` 或 `$HOME/...` 等模式無法用於暗中讀取檔案。Safe bins 也必須從受信任的二進位目錄解析（系統預設加上選用的 `tools.exec.safeBinTrustedDirs`）。`PATH` 項目從不自動受信任。預設受信任的 safe-bin 目錄刻意最小化：`/bin`、`/usr/bin`。若你的 safe-bin 可執行檔位於套件管理器/使用者路徑（例如 `/opt/homebrew/bin`、`/usr/local/bin`、`/opt/local/bin`、`/snap/bin`），明確新增它們至 `tools.exec.safeBinTrustedDirs`。Allowlist 模式不自動允許 shell 鏈和重新導向。

Allowlist 模式中允許 shell 鏈（`&&`、`||`、`;`），當每個頂層區段都滿足 allowlist（包括 safe bins 或 skill 自動允許）時。Allowlist 模式下仍不支援重新導向。在 allowlist 解析期間拒絕命令替換（`$()` / 反引號），包括雙引號內；若需要純文字的 `$()` 文字，使用單引號。在 macOS companion-app approvals 中，包含 shell 控制或展開語法（`&&`、`||`、`;`、`|`、`` ` ``、`$`、`<`、`>`、`(`、`)`）的原始 shell 文字被視為 allowlist 未命中，除非 shell 二進位本身在 allowlist 中。對於 shell 包裝器（`bash|sh|zsh ... -c/-lc`），請求範疇的 env 覆寫縮減為少量明確的 allowlist（`TERM`、`LANG`、`LC_*`、`COLORTERM`、`NO_COLOR`、`FORCE_COLOR`）。對於 allowlist 模式中的始終允許決定，已知的 dispatch 包裝器（`env`、`nice`、`nohup`、`stdbuf`、`timeout`）保留內部可執行路徑而非包裝器路徑。Shell 多路器（`busybox`、`toybox`）對 shell applets（`sh`、`ash` 等）也會解包，因此保留內部可執行路徑而非多路器二進位。若包裝器或多路器無法安全解包，不自動保留任何 allowlist 項目。

預設 safe bins：`jq`、`cut`、`uniq`、`head`、`tail`、`tr`、`wc`。

`grep` 和 `sort` 不在預設清單中。若你選擇加入，為其非 stdin 工作流程保留明確的 allowlist 項目。對於 safe-bin 模式中的 `grep`，以 `-e`/`--regexp` 提供模式；拒絕位置模式形式，以防止檔案操作數被當作模糊位置數混入。

### Safe bins 與 allowlist 比較

| 主題     | `tools.exec.safeBins`                       | Allowlist（`exec-approvals.json`）    |
| -------- | ------------------------------------------- | ------------------------------------- |
| 目標     | 自動允許狹窄的 stdin 過濾器                 | 明確信任特定可執行檔                  |
| 比對類型 | 可執行名稱 + safe-bin argv 政策             | 解析的可執行路徑 glob 模式            |
| 引數範疇 | 受 safe-bin profile 和純文字 token 規則限制 | 僅路徑比對；引數是你的責任            |
| 典型範例 | `jq`、`head`、`tail`、`wc`                  | `python3`、`node`、`ffmpeg`、自訂 CLI |
| 最佳用途 | 管道中的低風險文字轉換                      | 任何具有更廣泛行為或副作用的工具      |

設定位置：

- `safeBins` 來自設定（`tools.exec.safeBins` 或每個 agent 的 `agents.list[].tools.exec.safeBins`）。
- `safeBinTrustedDirs` 來自設定（`tools.exec.safeBinTrustedDirs` 或每個 agent 的 `agents.list[].tools.exec.safeBinTrustedDirs`）。
- `safeBinProfiles` 來自設定（`tools.exec.safeBinProfiles` 或每個 agent 的 `agents.list[].tools.exec.safeBinProfiles`）。每個 agent 的 profile key 覆寫全域 key。
- allowlist 項目儲存在主機本地的 `~/.openclaw/exec-approvals.json` 中的 `agents.<id>.allowlist` 下（或透過 Control UI / `openclaw approvals allowlist ...`）。
- 當 interpreter/runtime bin 出現在 `safeBins` 且無明確 profiles 時，`openclaw security audit` 以 `tools.exec.safe_bins_interpreter_unprofiled` 警告。
- `openclaw doctor --fix` 可以將遺失的自訂 `safeBinProfiles.<bin>` 項目建構為 `{}`（之後審查並收緊）。Interpreter/runtime bin 不會自動建構。

自訂 profile 範例：

```json5
{
  tools: {
    exec: {
      safeBins: ["jq", "myfilter"],
      safeBinProfiles: {
        myfilter: {
          minPositional: 0,
          maxPositional: 0,
          allowedValueFlags: ["-n", "--limit"],
          deniedFlags: ["-f", "--file", "-c", "--command"],
        },
      },
    },
  },
}
```

## Control UI 編輯

使用 **Control UI → Nodes → Exec approvals** 卡片來編輯預設值、每個 agent 的覆寫和 allowlists。選擇範疇（預設值或某個 agent），調整政策，新增/移除 allowlist 模式，然後**儲存**。UI 每個模式顯示**最後使用**元資料，讓你可以保持清單整潔。

目標選擇器選擇 **Gateway**（本地 approvals）或**節點**。節點必須通告 `system.execApprovals.get/set`（macOS app 或 headless 節點主機）。若節點尚未通告 exec approvals，直接編輯其本地 `~/.openclaw/exec-approvals.json`。

CLI：`openclaw approvals` 支援 gateway 或節點編輯（見 [Approvals CLI](/zh-Hant/cli/approvals)）。

## Approval 流程

當需要提示時，gateway 向操作者客戶端廣播 `exec.approval.requested`。Control UI 和 macOS app 透過 `exec.approval.resolve` 解決它，然後 gateway 將已批准的請求轉發至節點主機。

對於 `host=node`，approval 請求包含正規的 `systemRunPlan` payload。Gateway 使用該計劃作為轉發已批准 `system.run` 請求時的權威命令/cwd/session context。

當需要 approvals 時，exec 工具立即回傳一個 approval id。使用該 id 與後續系統事件（`Exec finished` / `Exec denied`）關聯。若在逾時前未做出決定，請求被視為 approval 逾時並作為拒絕原因呈現。

確認對話框包含：

- 命令 + 引數
- cwd
- agent id
- 解析的可執行路徑
- 主機 + 政策元資料

動作：

- **Allow once** → 立即執行
- **Always allow** → 新增至 allowlist + 執行
- **Deny** → 封鎖

## Approval 轉發至聊天頻道

你可以將 exec approval 提示轉發至任何聊天頻道（包括 plugin 頻道），並以 `/approve` 批准它們。這使用正常的對外傳遞管道。

設定：

```json5
{
  approvals: {
    exec: {
      enabled: true,
      mode: "session", // "session" | "targets" | "both"
      agentFilter: ["main"],
      sessionFilter: ["discord"], // 子字串或正則表示式
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

安全注意：

- Unix socket 模式 `0600`，token 儲存在 `exec-approvals.json`。
- 相同 UID 對等檢查。
- 挑戰/回應（nonce + HMAC token + 請求 hash）+ 短 TTL。

## 系統事件

Exec 生命週期以系統訊息呈現：

- `Exec running`（僅在命令超過執行通知閾值時）
- `Exec finished`
- `Exec denied`

這些在節點回報事件後發佈至 agent 的 session。Gateway-host exec approvals 在命令完成時（以及選用地在執行時間超過閾值時）發出相同的生命週期事件。已審批閘控的 exec 在這些訊息中重用 approval id 作為 `runId`，便於關聯。

## 含義

- **full** 功能強大；盡可能優先使用 allowlists。
- **ask** 讓你保持參與，同時仍允許快速審批。
- 每個 agent 的 allowlists 防止一個 agent 的 approvals 洩露至其他 agent。
- Approvals 僅適用於來自**已授權傳送者**的 host exec 請求。未授權的傳送者無法發出 `/exec`。
- `/exec security=full` 是授權操作者的 session 層級便利設定，設計上跳過 approvals。若要強制封鎖 host exec，將 approvals security 設為 `deny` 或透過工具政策拒絕 `exec` 工具。

相關：

- [Exec tool](/zh-Hant/tools/exec)
- [Elevated mode](/zh-Hant/tools/elevated)
- [Skills](/zh-Hant/tools/skills)
