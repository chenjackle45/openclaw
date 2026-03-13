---
summary: "Exec 核准、允許列表和 sandbox 逃脫提示"
read_when:
  - 配置 exec 核准或允許列表
  - 在 macOS app 中實現 exec 核准 UX
  - 審視 sandbox 逃脫提示和含義
title: "Exec Approvals（Exec 核准）"
---

# Exec approvals

Exec 核准是 **companion app／node host guardrail**，用於讓沙箱化 agent 在真實主機上執行命令（`gateway` 或 `node`）。把它想像成一個安全互鎖：只有當原則 + 允許列表 +（選擇性）使用者核准都同意時，命令才被允許。Exec 核准是 **在工具原則和提升閘門之外**（除非提升設定為 `full`，這會跳過核准）。
有效原則是 `tools.exec.*` 和核准預設值中**更嚴格**的；如果核准欄位被省略，則使用 `tools.exec` 值。

如果 companion app UI **不可用**，任何需要提示的請求都由 **ask fallback** 解決（預設：拒絕）。

## 它適用於哪些地方

Exec 核准在執行主機上本機強制：

- **gateway host** → gateway machine 上的 `openclaw` 進程
- **node host** → node runner（macOS companion app 或無頭 node host）

信任模型注意：

- Gateway 認證的呼叫者是該 Gateway 的信任運營者。
- 配對的 nodes 將該信任運營者能力擴展到 node host。
- Exec 核准降低意外執行風險，但不是每個使用者的認證邊界。
- 已核准的 node 主機執行繫結規範執行 context：規範 cwd、確切的 argv、env 繫結（如果存在）和 pinned executable path（如適用）。
- 對於 shell 指令碼和直接解釋器／runtime 檔案呼叫，OpenClaw 也嘗試繫結一個具體的本機檔案運算元。如果該繫結檔案在核准後但在執行前改變，執行會被拒絕而不是執行漂移 content。
- 此檔案繫結是有意最佳努力的，而不是每個解釋器／runtime 載入器路徑的完整語義模型。如果核准 mode 無法識別確切一個具體本機檔案來繫結，它會拒絕發行核准備份執行，而不是假裝完整覆蓋。

macOS 分割：

- **node host service** 透過本機 IPC 轉發 `system.run` 到 **macOS app**。
- **macOS app** 強制核准 + 在 UI context 中執行命令。

## 設定和儲存

核准位於執行主機上的本機 JSON 檔案：

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

## 原則旋鈕

### 安全性 (`exec.security`)

- **deny**: 阻止所有主機 exec 請求。
- **allowlist**: 僅允許允許列表中的命令。
- **full**: 允許一切（等同於提升）。

### 詢問 (`exec.ask`)

- **off**: 永遠不提示。
- **on-miss**: 僅當允許列表不匹配時提示。
- **always**: 在每個命令上提示。

### 詢問回退 (`askFallback`)

如果需要提示但無法連接 UI，回退決定：

- **deny**: 阻止。
- **allowlist**: 僅在允許列表匹配時允許。
- **full**: 允許。

## 允許列表（per agent）

允許列表是 **per agent**。如果存在多個 agents，在 macOS app 中切換你正在編輯的 agent。模式是 **不區分大小寫的 glob 相符**。
模式應解析為 **二進位路徑**（basename 項只是被忽略）。
舊版 `agents.default` 項在載入時會遷移到 `agents.main`。

範例：

- `~/Projects/**/bin/peekaboo`
- `~/.local/bin/*`
- `/opt/homebrew/bin/rg`

每個允許列表項目追蹤：

- **id** 用於 UI 身份的穩定 UUID（選擇性）
- **last used** 時間戳
- **last used command**
- **last resolved path**

## 自動允許 skill CLIs

當 **Auto-allow skill CLIs** 啟用時，已知 skills 引用的可執行檔會在 nodes（macOS node 或無頭 node host）上被視為允許列表。這使用 `skills.bins`（透過 Gateway RPC）來擷取 skill bin 列表。如果你想要嚴格手動允許列表，則停用此功能。

重要信任注意：

- 這是一個 **隱含便利允許列表**，與手動路徑允許列表項目分開。
- 它適用於 Gateway 和 node 在同一信任邊界的信任運營者環境。
- 如果需要嚴格明確信任，保持 `autoAllowSkills: false` 並僅使用手動路徑允許列表項目。

## 安全 bins（stdin 僅限）

`tools.exec.safeBins` 定義一個小型 **stdin 僅限** 二進位檔列表（例如 `jq`），這些可以在允許列表 mode 中執行，**無需**明確允許列表項目。安全 bins 拒絕位置檔案 args 和類路徑 tokens，因此它們只能在傳入串流上運作。
將此視為串流過濾器的狹窄快速路徑，而不是通用信任列表。
**不要**將解釋器或 runtime 二進位檔（例如 `python3`、`node`、`ruby`、`bash`、`sh`、`zsh`）新增到 `safeBins`。
如果命令可以評估程式碼、執行子命令或按設計讀取檔案，則偏好明確允許列表項目並保持核准提示啟用。
自訂安全 bins 必須在 `tools.exec.safeBinProfiles.<bin>` 中定義明確的 profile。
驗證完全取決於 argv 形狀（無主機檔案系統存在檢查），這防止了允許／拒絕差異的檔案存在 oracle 行為。
預設安全 bins 拒絕檔案導向選項（例如 `sort -o`、`sort --output`、`sort --files0-from`、`sort --compress-program`、`sort --random-source`、`sort --temporary-directory`／`-T`、`wc --files0-from`、`jq -f/--from-file`、`grep -f/--file`）。
安全 bins 也為會破壞 stdin 僅限行為的選項強制明確每二進位旗標原則（例如 `sort -o/--output/--compress-program` 和 grep 遞迴旗標）。
長選項在安全 bin mode 中驗證失敗關閉：未知旗標和模糊縮寫被拒絕。
由安全 bin profile 拒絕的旗標：

<!-- SAFE_BIN_DENIED_FLAGS:START -->

- `grep`: `--dereference-recursive`, `--directories`, `--exclude-from`, `--file`, `--recursive`, `-R`, `-d`, `-f`, `-r`
- `jq`: `--argfile`, `--from-file`, `--library-path`, `--rawfile`, `--slurpfile`, `-L`, `-f`
- `sort`: `--compress-program`, `--files0-from`, `--output`, `--random-source`, `--temporary-directory`, `-T`, `-o`
- `wc`: `--files0-from`
<!-- SAFE_BIN_DENIED_FLAGS:END -->

安全 bins 也強制 argv tokens 在執行時被視為 **literal text**（stdin 僅限段落沒有 globbing 和沒有 `$VARS` 擴展），所以 `*` 或 `$HOME/...` 的模式無法被用來 smuggle 檔案讀取。
安全 bins 也必須從信任二進位目錄解析（系統預設值加上選擇性 `tools.exec.safeBinTrustedDirs`）。`PATH` 項目永遠不會自動信任。
預設信任安全 bin 目錄有意最小化：`/bin`, `/usr/bin`。
如果安全 bin 可執行檔位於套件管理器／使用者路徑中（例如 `/opt/homebrew/bin`、`/usr/local/bin`、`/opt/local/bin`、`/snap/bin`），明確新增到 `tools.exec.safeBinTrustedDirs`。
Shell 鏈接和重新導向在允許列表 mode 中不自動允許。

當每個頂層段滿足允許列表時允許 Shell 鏈接（`&&`、`||`、`;`）（包括安全 bins 或 skill 自動允許）。重新導向在允許列表 mode 中保持不支援。
命令替換（`$()`／backticks）在允許列表解析期間被拒絕，包括在雙引號內；如果需要 literal `$()` 文字，使用單引號。
在 macOS companion app 核准上，包含 shell 控制或擴展語法的原始 shell 文字（`&&`、`||`、`;`、`|`、`` ` ``、`$`、`<`、`>`、`(`、`)`）被視為允許列表遺漏，除非 shell 二進位檔本身被允許列表。
對於 shell wrappers（`bash|sh|zsh ... -c/-lc`），request 範圍的 env 覆蓋被減少到小的明確允許列表（`TERM`、`LANG`、`LC_*`、`COLORTERM`、`NO_COLOR`、`FORCE_COLOR`）。
對於允許始終決定在允許列表 mode 中，已知 dispatch wrappers（`env`、`nice`、`nohup`、`stdbuf`、`timeout`）持久化內部可執行路徑而不是 wrapper 路徑。Shell 多路分配器（`busybox`、`toybox`）也被展開以用於 shell applets（`sh`、`ash` 等），因此內部可執行檔被持久化而不是多路分配器二進位檔。如果 wrapper 或多路分配器無法安全展開，沒有允許列表項目被自動持久化。

預設安全 bins: `jq`, `cut`, `uniq`, `head`, `tail`, `tr`, `wc`。

`grep` 和 `sort` 不在預設列表中。如果選擇加入，為其非 stdin 工作流保持明確允許列表項目。
對於 safe bin mode 中的 `grep`，用 `-e`／`--regexp` 提供模式；位置模式形式被拒絕，因此檔案運算元無法被 smuggle 為模糊位置。

### 安全 bins 與 allowlist

| 主題     | `tools.exec.safeBins`                         | Allowlist（`exec-approvals.json`）       |
| -------- | --------------------------------------------- | ---------------------------------------- |
| 目標     | 自動允許狹窄 stdin 過濾器                     | 明確信任特定可執行檔                     |
| 比對型態 | 可執行名稱 + safe bin argv 原則               | 已解析可執行路徑 glob 模式               |
| 引數範圍 | 由 safe bin profile 和 literal token 規則限制 | 僅路徑相符；引數否則由你負責             |
| 典型範例 | `jq`, `head`, `tail`, `wc`                    | `python3`, `node`, `ffmpeg`, custom CLIs |
| 最佳使用 | 管道中的低風險文字轉換                        | 任何具有更廣泛行為或副作用的工具         |

配置位置：

- `safeBins` 來自配置（`tools.exec.safeBins` 或 per agent `agents.list[].tools.exec.safeBins`）。
- `safeBinTrustedDirs` 來自配置（`tools.exec.safeBinTrustedDirs` 或 per agent `agents.list[].tools.exec.safeBinTrustedDirs`）。
- `safeBinProfiles` 來自配置（`tools.exec.safeBinProfiles` 或 per agent `agents.list[].tools.exec.safeBinProfiles`）。Per agent profile 鍵覆蓋全域鍵。
- allowlist 項目位於主機本機 `~/.openclaw/exec-approvals.json` 下的 `agents.<id>.allowlist` 下（或透過 Control UI／`openclaw approvals allowlist ...`）。
- `openclaw security audit` 在解釋器／runtime bins 出現在 `safeBins` 中但沒有明確 profiles 時發出警告，帶有 `tools.exec.safe_bins_interpreter_unprofiled`。
- `openclaw doctor --fix` 可以如 `{}`（審視並在之後收緊）scaffold 遺漏的自訂 `safeBinProfiles.<bin>` 項目。解釋器／runtime bins 不會自動 scaffold。

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

使用 **Control UI → Nodes → Exec approvals** 卡來編輯預設值、per agent 覆蓋和允許列表。選擇 scope（預設值或 agent），調整原則，新增／移除允許列表模式，然後 **Save**。UI 針對每個模式顯示 **last used** 元資料，以便你可以保持列表整潔。

目標選擇器選擇 **Gateway**（本機核准）或 **Node**。Nodes 必須告知 `system.execApprovals.get/set`（macOS app 或無頭 node host）。
如果 node 還未告知 exec 核准，直接編輯其本機 `~/.openclaw/exec-approvals.json`。

CLI: `openclaw approvals` 支援 gateway 或 node 編輯（見 [Approvals CLI](/zh-Hant/cli/approvals)）。

## 核准流程

當需要提示時，gateway 廣播 `exec.approval.requested` 到運營者用戶端。Control UI 和 macOS app 透過 `exec.approval.resolve` 解決它，然後 gateway 轉發已核准的請求到 node host。

對於 `host=node`，核准請求包括規範的 `systemRunPlan` payload。Gateway 在轉發已核准的 `system.run` 請求時使用該計畫作為授權的命令／cwd／session context。

## 解釋器／runtime 命令

核准備份解釋器／runtime 執行有意是保守的：

- 確切的 argv／cwd／env context 總是被繫結。
- 直接 shell 指令碼和直接 runtime 檔案形式是最佳努力繫結到一個具體本機檔案快照。
- 如果 OpenClaw 無法為解釋器／runtime 命令識別確切一個具體本機檔案（例如套件指令碼、eval 形式、runtime 特定載入器鏈或模糊多檔案形式），核准備份執行被拒絕，而不是聲稱它沒有的語義覆蓋。
- 對於那些工作流程，偏好沙箱化、單獨主機邊界或明確信任允許列表／full 工作流程，其中運營者接受更廣泛的 runtime 語義。

當需要核准時，exec 工具立即傳回核准 id。使用該 id 關聯稍後的系統事件（`Exec finished`／`Exec denied`）。如果沒有決定在逾時前到達，請求被視為核准逾時並表示為拒絕理由。

確認對話包括：

- command + args
- cwd
- agent id
- resolved executable path
- host + policy metadata

操作：

- **Allow once** → 現在執行
- **Always allow** → 新增到允許列表 + 執行
- **Deny** → 阻止

## 向 chat 頻道轉發核准

你可以將 exec 核准提示轉發到任何 chat 頻道（包括 plugin 頻道）並使用 `/approve` 核准它們。這使用正常的出站傳遞管道。

配置：

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

在 chat 中回覆：

```
/approve <id> allow-once
/approve <id> allow-always
/approve <id> deny
```

### 內建 chat 核准用戶端

Discord 和 Telegram 也可以充當明確的 exec 核准用戶端，具有頻道特定配置。

- Discord: `channels.discord.execApprovals.*`
- Telegram: `channels.telegram.execApprovals.*`

這些用戶端是選擇加入的。如果頻道未啟用 exec 核准，OpenClaw 不會僅因為 conversation 在那裡就將該頻道視為核准表面。

共用行為：

- 僅設定的核准者可以核准或拒絕
- 請求者不需要是核准者
- 當頻道傳遞啟用時，核准提示包括命令文字
- 如果沒有運營者 UI 或設定的核准用戶端可以接受請求，提示回退到 `askFallback`

Telegram 預設為核准者 DMs（`target: "dm"`）。當你想讓核准提示也出現在原始 Telegram chat／topic 中時，可以切換到 `channel` 或 `both`。對於 Telegram 論壇主題，OpenClaw 為核准提示和核准後的後續操作保留主題。

見：

- [Discord](/zh-Hant/channels/discord#exec-approvals-in-discord)
- [Telegram](/zh-Hant/channels/telegram#exec-approvals-in-telegram)

### macOS IPC 流程

```
Gateway -> Node Service (WS)
                 |  IPC (UDS + token + HMAC + TTL)
                 v
             Mac App (UI + approvals + system.run)
```

安全注意：

- Unix socket mode `0600`，token 儲存在 `exec-approvals.json`。
- 相同 UID 對等檢查。
- Challenge／response（nonce + HMAC token + request hash） + 短 TTL。

## 系統事件

Exec 生命週期表示為系統訊息：

- `Exec running`（僅當命令超過執行中通知閾值時）
- `Exec finished`
- `Exec denied`

這些在 node 報告事件後發佈到 agent 的 session。
Gateway 主機 exec 核准在命令完成時發出相同的生命週期事件（以及可選地當執行長於閾值時）。
核准閘門的 execs 重用核准 id 作為這些訊息中的 `runId`，以便輕鬆關聯。

## 含義

- **full** 是強大的；在可能時偏好允許列表。
- **ask** 保持你在循環中，同時仍然允許快速核准。
- Per agent 允許列表防止一個 agent 的核准洩漏到其他人中。
- 核准僅適用於來自 **授權寄件者** 的主機 exec 請求。未授權的寄件者無法發行 `/exec`。
- `/exec security=full` 是授權運營者的 session 級便利，並按設計跳過核准。
  要硬阻止主機 exec，設定核准安全為 `deny` 或透過工具原則拒絕 `exec` 工具。

相關：

- [Exec tool](/zh-Hant/tools/exec)
- [Elevated mode](/zh-Hant/tools/elevated)
- [Skills](/zh-Hant/tools/skills)
