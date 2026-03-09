---
summary: "Hooks：指令與生命週期事件的事件驅動自動化"
read_when:
  - 您想要針對 /new、/reset、/stop 和 Agent 生命週期事件的事件驅動自動化時
  - 您想要建立、安裝或偵錯 Hooks 時
title: "Hooks（事件鉤子）"
---

# Hooks

Hooks 提供一個可擴充的事件驅動系統，用於自動化 Agent 指令和事件的回應動作。Hooks 從目錄自動探索，並可透過 CLI 指令管理，類似於 OpenClaw 中技能的運作方式。

## 入門導引

Hooks 是當某件事發生時執行的小腳本。有兩種類型：

- **Hooks**（本頁）：當 Agent 事件觸發時在 Gateway 內部執行，例如 `/new`、`/reset`、`/stop` 或生命週期事件。
- **Webhooks**：外部 HTTP webhooks，讓其他系統觸發 OpenClaw 中的工作。見 [Webhook Hooks](/zh-Hant/automation/webhook) 或使用 `openclaw webhooks` 取得 Gmail 輔助指令。

Hooks 也可以打包在插件中；見 [插件](/zh-Hant/tools/plugin#plugin-hooks)。

常見用途：

- 重置會話時儲存記憶快照
- 保持指令稽核軌跡以供疑難排解或合規
- 會話開始或結束時觸發後續自動化
- 在事件觸發時將檔案寫入 Agent 工作區或呼叫外部 API

只要能寫一個小型 TypeScript 函式，就能寫一個 Hook。Hooks 自動探索，並透過 CLI 啟用或停用。

## 概述

Hooks 系統讓您可以：

- 發出 `/new` 時將會話上下文儲存到記憶
- 記錄所有指令以供稽核
- 在 Agent 生命週期事件上觸發自訂自動化
- 無需修改核心程式碼即可擴充 OpenClaw 的行為

## 快速開始

### 內建 Hooks

OpenClaw 隨附四個自動探索的內建 Hooks：

- **💾 session-memory**：在您發出 `/new` 時將會話上下文儲存到 Agent 工作區（預設 `~/.openclaw/workspace/memory/`）
- **📎 bootstrap-extra-files**：在 `agent:bootstrap` 期間從已設定的 glob/路徑模式注入額外的工作區 bootstrap 檔案
- **📝 command-logger**：將所有指令事件記錄到 `~/.openclaw/logs/commands.log`
- **🚀 boot-md**：Gateway 啟動時執行 `BOOT.md`（需要啟用內部 hooks）

列出可用 hooks：

```bash
openclaw hooks list
```

啟用 hook：

```bash
openclaw hooks enable session-memory
```

查看 hook 狀態：

```bash
openclaw hooks check
```

取得詳細資訊：

```bash
openclaw hooks info session-memory
```

### 引導設定

在引導設定（`openclaw onboard`）期間，系統會提示您啟用建議的 hooks。精靈自動探索符合條件的 hooks 並呈現供選擇。

## Hook 探索

Hooks 自動從三個目錄探索（優先順序由高到低）：

1. **工作區 hooks**：`<workspace>/hooks/`（每 Agent，最高優先順序）
2. **受管理 hooks**：`~/.openclaw/hooks/`（使用者安裝，跨工作區共用）
3. **內建 hooks**：`<openclaw>/dist/hooks/bundled/`（隨 OpenClaw 附帶）

受管理的 hook 目錄可以是**單一 hook** 或 **hook 套件**（套件目錄）。

每個 hook 是一個包含以下內容的目錄：

```
my-hook/
├── HOOK.md          # 元資料 + 文件
└── handler.ts       # 處理器實作
```

## Hook 套件（npm/封存檔）

Hook 套件是標準 npm 套件，透過 `package.json` 中的 `openclaw.hooks` 匯出一或多個 hooks。使用以下方式安裝：

```bash
openclaw hooks install <path-or-spec>
```

Npm 規格僅限於登錄（套件名稱 + 選填的精確版本或 dist-tag）。
Git/URL/file 規格和 semver 範圍會被拒絕。

裸規格和 `@latest` 保持在穩定軌道上。若 npm 解析其中之一為預發佈版，
OpenClaw 會停止並要求您明確選擇加入，例如使用 `@beta`/`@rc` 或精確的預發佈版本。

範例 `package.json`：

```json
{
  "name": "@acme/my-hooks",
  "version": "0.1.0",
  "openclaw": {
    "hooks": ["./hooks/my-hook", "./hooks/other-hook"]
  }
}
```

每個項目指向包含 `HOOK.md` 和 `handler.ts`（或 `index.ts`）的 hook 目錄。
Hook 套件可附帶依賴項；它們將安裝在 `~/.openclaw/hooks/<id>` 下。
每個 `openclaw.hooks` 項目在符號連結解析後必須保持在套件目錄內；超出範圍的項目會被拒絕。

安全注意事項：`openclaw hooks install` 使用 `npm install --ignore-scripts` 安裝依賴項
（無生命週期腳本）。保持 hook 套件依賴樹為「純 JS/TS」，避免依賴 `postinstall` 建置的套件。

## Hook 結構

### HOOK.md 格式

`HOOK.md` 檔案在 YAML frontmatter 中包含元資料，加上 Markdown 文件：

```markdown
---
name: my-hook
description: "Short description of what this hook does"
homepage: https://docs.openclaw.ai/automation/hooks#my-hook
metadata:
  { "openclaw": { "emoji": "🔗", "events": ["command:new"], "requires": { "bins": ["node"] } } }
---

# My Hook

Detailed documentation goes here...

## What It Does

- Listens for `/new` commands
- Performs some action
- Logs the result

## Requirements

- Node.js must be installed

## Configuration

No configuration needed.
```

### 元資料欄位

`metadata.openclaw` 物件支援：

- **`emoji`**：CLI 顯示表情符號（例如 `"💾"`）
- **`events`**：要監聽的事件陣列（例如 `["command:new", "command:reset"]`）
- **`export`**：要使用的具名匯出（預設為 `"default"`）
- **`homepage`**：文件 URL
- **`requires`**：選填需求
  - **`bins`**：PATH 上所需的執行檔（例如 `["git", "node"]`）
  - **`anyBins`**：至少一個這些執行檔必須存在
  - **`env`**：所需的環境變數
  - **`config`**：所需的設定路徑（例如 `["workspace.dir"]`）
  - **`os`**：所需的平台（例如 `["darwin", "linux"]`）
- **`always`**：繞過資格檢查（布林值）
- **`install`**：安裝方法（對內建 hooks：`[{"id":"bundled","kind":"bundled"}]`）

### 處理器實作

`handler.ts` 檔案匯出一個 `HookHandler` 函式：

```typescript
const myHandler = async (event) => {
  // Only trigger on 'new' command
  if (event.type !== "command" || event.action !== "new") {
    return;
  }

  console.log(`[my-hook] New command triggered`);
  console.log(`  Session: ${event.sessionKey}`);
  console.log(`  Timestamp: ${event.timestamp.toISOString()}`);

  // Your custom logic here

  // Optionally send message to user
  event.messages.push("✨ My hook executed!");
};

export default myHandler;
```

#### 事件上下文

每個事件包含：

```typescript
{
  type: 'command' | 'session' | 'agent' | 'gateway' | 'message',
  action: string,              // 例如 'new', 'reset', 'stop', 'received', 'sent'
  sessionKey: string,          // 會話識別碼
  timestamp: Date,             // 事件發生時間
  messages: string[],          // 在此推送訊息以傳送給使用者
  context: {
    // 指令事件：
    sessionEntry?: SessionEntry,
    sessionId?: string,
    sessionFile?: string,
    commandSource?: string,    // 例如 'whatsapp', 'telegram'
    senderId?: string,
    workspaceDir?: string,
    bootstrapFiles?: WorkspaceBootstrapFile[],
    cfg?: OpenClawConfig,
    // 訊息事件（完整詳情見「訊息事件」章節）：
    from?: string,             // message:received
    to?: string,               // message:sent
    content?: string,
    channelId?: string,
    success?: boolean,         // message:sent
  }
}
```

## 事件類型

### 指令事件

Agent 指令發出時觸發：

- **`command`**：所有指令事件（通用監聽器）
- **`command:new`**：發出 `/new` 指令時
- **`command:reset`**：發出 `/reset` 指令時
- **`command:stop`**：發出 `/stop` 指令時

### 會話事件

- **`session:compact:before`**：壓縮摘要歷史記錄之前
- **`session:compact:after`**：壓縮完成後，含摘要元資料

內部 hook 酬載以 `type: "session"` 搭配 `action: "compact:before"` / `action: "compact:after"` 發出；監聽器使用上述組合鍵訂閱。
特定處理器註冊使用字面鍵格式 `${type}:${action}`。對這些事件，註冊 `session:compact:before` 和 `session:compact:after`。

### Agent 事件

- **`agent:bootstrap`**：工作區 bootstrap 檔案注入之前（hooks 可修改 `context.bootstrapFiles`）

### Gateway 事件

Gateway 啟動時觸發：

- **`gateway:startup`**：頻道啟動且 hooks 載入後

### 訊息事件

訊息接收或傳送時觸發：

- **`message`**：所有訊息事件（通用監聽器）
- **`message:received`**：從任何頻道收到入站訊息時。在處理早期觸發，媒體解析前。內容可能包含尚未處理的媒體附件原始佔位符，例如 `<media:audio>`。
- **`message:transcribed`**：訊息已完全處理（包括音訊轉錄和連結解析）時。此時 `transcript` 包含音訊訊息的完整逐字稿文字。需要存取轉錄音訊內容時使用此 hook。
- **`message:preprocessed`**：所有媒體 + 連結解析完成後對每則訊息觸發，讓 hooks 在 Agent 看到之前存取完整豐富化的內容（逐字稿、圖片說明、連結摘要）。
- **`message:sent`**：出站訊息成功傳送時

#### 訊息事件上下文

訊息事件包含豐富的訊息上下文：

```typescript
// message:received 上下文
{
  from: string,           // 傳送者識別碼（電話號碼、使用者 ID 等）
  content: string,        // 訊息內容
  timestamp?: number,     // 接收時的 Unix 時間戳記
  channelId: string,      // 頻道（例如 "whatsapp", "telegram", "discord"）
  accountId?: string,     // 多帳號設定的提供者帳號 ID
  conversationId?: string, // 聊天/對話 ID
  messageId?: string,     // 來自提供者的訊息 ID
  metadata?: {            // 額外的提供者特定資料
    to?: string,
    provider?: string,
    surface?: string,
    threadId?: string,
    senderId?: string,
    senderName?: string,
    senderUsername?: string,
    senderE164?: string,
  }
}

// message:sent 上下文
{
  to: string,             // 收件人識別碼
  content: string,        // 已傳送的訊息內容
  success: boolean,       // 傳送是否成功
  error?: string,         // 傳送失敗時的錯誤訊息
  channelId: string,      // 頻道（例如 "whatsapp", "telegram", "discord"）
  accountId?: string,     // 提供者帳號 ID
  conversationId?: string, // 聊天/對話 ID
  messageId?: string,     // 提供者回傳的訊息 ID
  isGroup?: boolean,      // 此出站訊息是否屬於群組/頻道上下文
  groupId?: string,       // 群組/頻道識別碼，用於與 message:received 關聯
}

// message:transcribed 上下文
{
  body?: string,          // 豐富化前的原始入站內容
  bodyForAgent?: string,  // Agent 可見的豐富化內容
  transcript: string,     // 音訊逐字稿文字
  channelId: string,      // 頻道（例如 "telegram", "whatsapp"）
  conversationId?: string,
  messageId?: string,
}

// message:preprocessed 上下文
{
  body?: string,          // 原始入站內容
  bodyForAgent?: string,  // 媒體/連結解析後的最終豐富化內容
  transcript?: string,    // 有音訊時的逐字稿
  channelId: string,      // 頻道（例如 "telegram", "whatsapp"）
  conversationId?: string,
  messageId?: string,
  isGroup?: boolean,
  groupId?: string,
}
```

#### 範例：訊息記錄器 Hook

```typescript
const isMessageReceivedEvent = (event: { type: string; action: string }) =>
  event.type === "message" && event.action === "received";
const isMessageSentEvent = (event: { type: string; action: string }) =>
  event.type === "message" && event.action === "sent";

const handler = async (event) => {
  if (isMessageReceivedEvent(event as { type: string; action: string })) {
    console.log(`[message-logger] Received from ${event.context.from}: ${event.context.content}`);
  } else if (isMessageSentEvent(event as { type: string; action: string })) {
    console.log(`[message-logger] Sent to ${event.context.to}: ${event.context.content}`);
  }
};

export default handler;
```

### 工具結果 Hooks（插件 API）

這些 hooks 不是事件串流監聽器；它們讓插件在 OpenClaw 持久化之前同步調整工具結果。

- **`tool_result_persist`**：在工具結果寫入會話逐字稿之前轉換它們。必須同步；回傳更新後的工具結果酬載，或 `undefined` 以保持原樣。見 [Agent 迴圈](/zh-Hant/concepts/agent-loop)。

### 插件 Hook 事件

透過插件 hook 執行器公開的壓縮生命週期 hooks：

- **`before_compaction`**：壓縮前執行，含計數/Token 元資料
- **`after_compaction`**：壓縮後執行，含壓縮摘要元資料

### 未來事件

計劃中的事件類型：

- **`session:start`**：新會話開始時
- **`session:end`**：會話結束時
- **`agent:error`**：Agent 遇到錯誤時

## 建立自訂 Hooks

### 1. 選擇位置

- **工作區 hooks**（`<workspace>/hooks/`）：每 Agent，最高優先順序
- **受管理 hooks**（`~/.openclaw/hooks/`）：跨工作區共用

### 2. 建立目錄結構

```bash
mkdir -p ~/.openclaw/hooks/my-hook
cd ~/.openclaw/hooks/my-hook
```

### 3. 建立 HOOK.md

```markdown
---
name: my-hook
description: "Does something useful"
metadata: { "openclaw": { "emoji": "🎯", "events": ["command:new"] } }
---

# My Custom Hook

This hook does something useful when you issue `/new`.
```

### 4. 建立 handler.ts

```typescript
const handler = async (event) => {
  if (event.type !== "command" || event.action !== "new") {
    return;
  }

  console.log("[my-hook] Running!");
  // Your logic here
};

export default handler;
```

### 5. 啟用並測試

```bash
# 確認 hook 已被探索
openclaw hooks list

# 啟用它
openclaw hooks enable my-hook

# 重啟您的 gateway 程序（macOS 上重啟選單列 app，或重啟您的開發程序）

# 觸發事件
# 透過您的訊息頻道傳送 /new
```

## 設定

### 新設定格式（建議）

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "session-memory": { "enabled": true },
        "command-logger": { "enabled": false }
      }
    }
  }
}
```

### 每個 Hook 的設定

Hooks 可以有自訂設定：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "my-hook": {
          "enabled": true,
          "env": {
            "MY_CUSTOM_VAR": "value"
          }
        }
      }
    }
  }
}
```

### 額外目錄

從額外目錄載入 hooks：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "load": {
        "extraDirs": ["/path/to/more/hooks"]
      }
    }
  }
}
```

### 舊版設定格式（仍受支援）

舊版設定格式仍可向後相容使用：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "handlers": [
        {
          "event": "command:new",
          "module": "./hooks/handlers/my-handler.ts",
          "export": "default"
        }
      ]
    }
  }
}
```

注意：`module` 必須是工作區相對路徑。拒絕絕對路徑和工作區外的路徑穿越。

**遷移**：新 hooks 使用新的探索機制。舊版處理器在目錄式 hooks 之後載入。

## CLI 指令

### 列出 Hooks

```bash
# 列出所有 hooks
openclaw hooks list

# 只顯示符合條件的 hooks
openclaw hooks list --eligible

# 詳細輸出（顯示缺少的需求）
openclaw hooks list --verbose

# JSON 輸出
openclaw hooks list --json
```

### Hook 資訊

```bash
# 顯示 hook 的詳細資訊
openclaw hooks info session-memory

# JSON 輸出
openclaw hooks info session-memory --json
```

### 檢查資格

```bash
# 顯示資格摘要
openclaw hooks check

# JSON 輸出
openclaw hooks check --json
```

### 啟用/停用

```bash
# 啟用 hook
openclaw hooks enable session-memory

# 停用 hook
openclaw hooks disable command-logger
```

## 內建 Hook 參考

### session-memory

在您發出 `/new` 時將會話上下文儲存到記憶。

**事件**：`command:new`

**需求**：必須設定 `workspace.dir`

**輸出**：`<workspace>/memory/YYYY-MM-DD-slug.md`（預設 `~/.openclaw/workspace`）

**功能說明**：

1. 使用重置前的會話記錄找到正確的逐字稿
2. 擷取最後 15 行對話
3. 使用 LLM 生成描述性的檔案名稱 slug
4. 將會話元資料儲存到有日期的記憶檔案

**輸出範例**：

```markdown
# Session: 2026-01-16 14:30:00 UTC

- **Session Key**: agent:main:main
- **Session ID**: abc123def456
- **Source**: telegram
```

**檔案名稱範例**：

- `2026-01-16-vendor-pitch.md`
- `2026-01-16-api-design.md`
- `2026-01-16-1430.md`（slug 生成失敗時的回退時間戳記）

**啟用**：

```bash
openclaw hooks enable session-memory
```

### bootstrap-extra-files

在 `agent:bootstrap` 期間注入額外的 bootstrap 檔案（例如 monorepo 本地的 `AGENTS.md` / `TOOLS.md`）。

**事件**：`agent:bootstrap`

**需求**：必須設定 `workspace.dir`

**輸出**：不寫入任何檔案；bootstrap 上下文僅在記憶體中修改。

**設定**：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "bootstrap-extra-files": {
          "enabled": true,
          "paths": ["packages/*/AGENTS.md", "packages/*/TOOLS.md"]
        }
      }
    }
  }
}
```

**注意事項**：

- 路徑相對於工作區解析。
- 檔案必須保持在工作區內（realpath 檢查）。
- 只載入已識別的 bootstrap 基礎名稱。
- 子 Agent 允許清單被保留（僅 `AGENTS.md` 和 `TOOLS.md`）。

**啟用**：

```bash
openclaw hooks enable bootstrap-extra-files
```

### command-logger

將所有指令事件記錄到集中式稽核檔案。

**事件**：`command`

**需求**：無

**輸出**：`~/.openclaw/logs/commands.log`

**功能說明**：

1. 擷取事件詳情（指令動作、時間戳記、會話金鑰、傳送者 ID、來源）
2. 以 JSONL 格式追加到日誌檔案
3. 在背景靜默執行

**範例日誌記錄**：

```jsonl
{"timestamp":"2026-01-16T14:30:00.000Z","action":"new","sessionKey":"agent:main:main","senderId":"+1234567890","source":"telegram"}
{"timestamp":"2026-01-16T15:45:22.000Z","action":"stop","sessionKey":"agent:main:main","senderId":"user@example.com","source":"whatsapp"}
```

**查看日誌**：

```bash
# 查看最近的指令
tail -n 20 ~/.openclaw/logs/commands.log

# 使用 jq 美化輸出
cat ~/.openclaw/logs/commands.log | jq .

# 依動作篩選
grep '"action":"new"' ~/.openclaw/logs/commands.log | jq .
```

**啟用**：

```bash
openclaw hooks enable command-logger
```

### boot-md

Gateway 啟動時（頻道啟動後）執行 `BOOT.md`。
必須啟用內部 hooks 才能執行。

**事件**：`gateway:startup`

**需求**：必須設定 `workspace.dir`

**功能說明**：

1. 從您的工作區讀取 `BOOT.md`
2. 透過 agent runner 執行其中的指示
3. 透過訊息工具傳送任何請求的出站訊息

**啟用**：

```bash
openclaw hooks enable boot-md
```

## 最佳實踐

### 保持處理器快速

Hooks 在指令處理期間執行。保持輕量：

```typescript
// ✓ 好的 - 非同步工作，立即回傳
const handler: HookHandler = async (event) => {
  void processInBackground(event); // Fire and forget
};

// ✗ 不好的 - 阻塞指令處理
const handler: HookHandler = async (event) => {
  await slowDatabaseQuery(event);
  await evenSlowerAPICall(event);
};
```

### 優雅地處理錯誤

始終包裝有風險的操作：

```typescript
const handler: HookHandler = async (event) => {
  try {
    await riskyOperation(event);
  } catch (err) {
    console.error("[my-handler] Failed:", err instanceof Error ? err.message : String(err));
    // 不要拋出 - 讓其他處理器繼續執行
  }
};
```

### 盡早篩選事件

若事件不相關則提早回傳：

```typescript
const handler: HookHandler = async (event) => {
  // 只處理 'new' 指令
  if (event.type !== "command" || event.action !== "new") {
    return;
  }

  // 您的邏輯在此
};
```

### 使用特定的事件鍵

盡可能在元資料中指定精確的事件：

```yaml
metadata: { "openclaw": { "events": ["command:new"] } } # 特定
```

而非：

```yaml
metadata: { "openclaw": { "events": ["command"] } } # 通用 - 較多負荷
```

## 偵錯

### 啟用 Hook 記錄

Gateway 在啟動時記錄 hook 載入：

```
Registered hook: session-memory -> command:new
Registered hook: bootstrap-extra-files -> agent:bootstrap
Registered hook: command-logger -> command
Registered hook: boot-md -> gateway:startup
```

### 檢查探索

列出所有已探索的 hooks：

```bash
openclaw hooks list --verbose
```

### 檢查註冊

在您的處理器中，記錄它被呼叫的時機：

```typescript
const handler: HookHandler = async (event) => {
  console.log("[my-handler] Triggered:", event.type, event.action);
  // 您的邏輯
};
```

### 確認資格

確認 hook 不符合資格的原因：

```bash
openclaw hooks info my-hook
```

查看輸出中缺少的需求。

## 測試

### Gateway 日誌

監控 gateway 日誌查看 hook 執行情況：

```bash
# macOS
./scripts/clawlog.sh -f

# 其他平台
tail -f ~/.openclaw/gateway.log
```

### 直接測試 Hooks

在隔離環境中測試您的處理器：

```typescript
import { test } from "vitest";
import myHandler from "./hooks/my-hook/handler.js";

test("my handler works", async () => {
  const event = {
    type: "command",
    action: "new",
    sessionKey: "test-session",
    timestamp: new Date(),
    messages: [],
    context: { foo: "bar" },
  };

  await myHandler(event);

  // 斷言副作用
});
```

## 架構

### 核心元件

- **`src/hooks/types.ts`**：型別定義
- **`src/hooks/workspace.ts`**：目錄掃描與載入
- **`src/hooks/frontmatter.ts`**：HOOK.md 元資料解析
- **`src/hooks/config.ts`**：資格檢查
- **`src/hooks/hooks-status.ts`**：狀態回報
- **`src/hooks/loader.ts`**：動態模組載入器
- **`src/cli/hooks-cli.ts`**：CLI 指令
- **`src/gateway/server-startup.ts`**：Gateway 啟動時載入 hooks
- **`src/auto-reply/reply/commands-core.ts`**：觸發指令事件

### 探索流程

```
Gateway 啟動
    ↓
掃描目錄（工作區 → 受管理 → 內建）
    ↓
解析 HOOK.md 檔案
    ↓
檢查資格（bins, env, config, os）
    ↓
從符合資格的 hooks 載入處理器
    ↓
為事件註冊處理器
```

### 事件流程

```
使用者傳送 /new
    ↓
指令驗證
    ↓
建立 hook 事件
    ↓
觸發 hook（所有已註冊的處理器）
    ↓
指令處理繼續
    ↓
會話重置
```

## 疑難排解

### Hook 未被探索

1. 確認目錄結構：

   ```bash
   ls -la ~/.openclaw/hooks/my-hook/
   # 應顯示：HOOK.md, handler.ts
   ```

2. 確認 HOOK.md 格式：

   ```bash
   cat ~/.openclaw/hooks/my-hook/HOOK.md
   # 應有包含 name 和 metadata 的 YAML frontmatter
   ```

3. 列出所有已探索的 hooks：

   ```bash
   openclaw hooks list
   ```

### Hook 不符合資格

檢查需求：

```bash
openclaw hooks info my-hook
```

查看缺少的：

- 執行檔（確認 PATH）
- 環境變數
- 設定值
- 作業系統相容性

### Hook 未執行

1. 確認 hook 已啟用：

   ```bash
   openclaw hooks list
   # 應在已啟用的 hooks 旁顯示 ✓
   ```

2. 重啟您的 gateway 程序以重新載入 hooks。

3. 查看 gateway 日誌中的錯誤：

   ```bash
   ./scripts/clawlog.sh | grep hook
   ```

### 處理器錯誤

確認 TypeScript/import 錯誤：

```bash
# 直接測試匯入
node -e "import('./path/to/handler.ts').then(console.log)"
```

## 遷移指南

### 從舊版設定遷移到探索機制

**之前**：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "handlers": [
        {
          "event": "command:new",
          "module": "./hooks/handlers/my-handler.ts"
        }
      ]
    }
  }
}
```

**之後**：

1. 建立 hook 目錄：

   ```bash
   mkdir -p ~/.openclaw/hooks/my-hook
   mv ./hooks/handlers/my-handler.ts ~/.openclaw/hooks/my-hook/handler.ts
   ```

2. 建立 HOOK.md：

   ```markdown
   ---
   name: my-hook
   description: "My custom hook"
   metadata: { "openclaw": { "emoji": "🎯", "events": ["command:new"] } }
   ---

   # My Hook

   Does something useful.
   ```

3. 更新設定：

   ```json
   {
     "hooks": {
       "internal": {
         "enabled": true,
         "entries": {
           "my-hook": { "enabled": true }
         }
       }
     }
   }
   ```

4. 確認並重啟您的 gateway 程序：

   ```bash
   openclaw hooks list
   # 應顯示：🎯 my-hook ✓
   ```

**遷移的優點**：

- 自動探索
- CLI 管理
- 資格檢查
- 更好的文件
- 一致的結構

## 參見

- [CLI 參考：hooks](/zh-Hant/cli/hooks)
- [內建 Hooks README](https://github.com/openclaw/openclaw/tree/main/src/hooks/bundled)
- [Webhook Hooks](/zh-Hant/automation/webhook)
- [設定](/zh-Hant/gateway/configuration#hooks)
