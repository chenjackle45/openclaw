---
title: "Hooks"
summary: "Hooks：指令和生命週期事件的事件驅動自動化"
read_when:
  - 您想要 /new、/reset、/stop 和 agent 生命週期事件的事件驅動自動化
  - 您想要建置、安裝或除錯 hooks
---
# Hooks

Hooks 提供可擴充的事件驅動系統，用於自動化響應 agent 指令和事件的操作。Hooks 會從目錄自動發現，並且可以透過 CLI 指令管理，類似於 OpenClaw 中 skills 的工作方式。

## 入門導向

Hooks 是在發生某事時執行的小型腳本。有兩種類型：

- **Hooks**（本頁）：當 agent 事件觸發時在 Gateway 內執行，如 `/new`、`/reset`、`/stop` 或生命週期事件。
- **Webhooks**：外部 HTTP webhooks，讓其他系統觸發 OpenClaw 中的工作。請參閱 [Webhook Hooks](/automation/webhook) 或使用 `openclaw webhooks` 取得 Gmail helper 指令。

Hooks 也可以捆綁在外掛內；請參閱 [Plugins](/plugin#plugin-hooks)。

常見用途：
- 當您重置會話時儲存記憶體快照
- 保留指令的審計追蹤以進行疑難排解或合規性
- 當會話開始或結束時觸發後續自動化
- 在事件觸發時將檔案寫入 agent 工作區或呼叫外部 APIs

如果您可以編寫小型 TypeScript 函式，您就可以編寫 hook。Hooks 會自動發現，您可以透過 CLI 啟用或停用它們。

## 概述

hooks 系統允許您：
- 當發出 `/new` 時將會話上下文儲存到記憶體
- 記錄所有指令以進行審計
- 在 agent 生命週期事件上觸發自訂自動化
- 在不修改核心程式碼的情況下擴充 OpenClaw 的行為

## 開始使用

### 捆綁的 Hooks

OpenClaw 附帶四個自動發現的捆綁 hooks：

- **💾 session-memory**：當您發出 `/new` 時，將會話上下文儲存到您的 agent 工作區（預設 `~/.openclaw/workspace/memory/`）
- **📝 command-logger**：將所有指令事件記錄到 `~/.openclaw/logs/commands.log`
- **🚀 boot-md**：當 gateway 啟動時執行 `BOOT.md`（需要啟用內部 hooks）
- **😈 soul-evil**：在清除視窗期間或透過隨機機率將注入的 `SOUL.md` 內容替換為 `SOUL_EVIL.md`

列出可用的 hooks：

```bash
openclaw hooks list
```

啟用 hook：

```bash
openclaw hooks enable session-memory
```

檢查 hook 狀態：

```bash
openclaw hooks check
```

取得詳細資訊：

```bash
openclaw hooks info session-memory
```

### Onboarding

在 onboarding（`openclaw onboard`）期間，系統會提示您啟用建議的 hooks。精靈會自動發現符合資格的 hooks 並呈現它們以供選擇。

## Hook 發現

Hooks 從三個目錄自動發現（按優先順序）：

1. **工作區 hooks**：`<workspace>/hooks/`（per-agent，最高優先順序）
2. **Managed hooks**：`~/.openclaw/hooks/`（使用者安裝，跨工作區共享）
3. **捆綁 hooks**：`<openclaw>/dist/hooks/bundled/`（與 OpenClaw 一起提供）

Managed hook 目錄可以是**單一 hook** 或 **hook pack**（package 目錄）。

每個 hook 是一個包含以下內容的目錄：

```
my-hook/
├── HOOK.md          # Metadata + 文件
└── handler.ts       # Handler 實作
```

## Hook Packs（npm/archives）

Hook packs 是標準 npm 套件，透過 `package.json` 中的 `openclaw.hooks` 匯出一個或多個 hooks。使用以下方式安裝它們：

```bash
openclaw hooks install <path-or-spec>
```

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

每個條目指向包含 `HOOK.md` 和 `handler.ts`（或 `index.ts`）的 hook 目錄。
Hook packs 可以提供依賴項；它們將安裝在 `~/.openclaw/hooks/<id>` 下。

## Hook 結構

### HOOK.md 格式

`HOOK.md` 檔案在 YAML frontmatter 中包含 metadata 加上 Markdown 文件：

```markdown
---
name: my-hook
description: "Short description of what this hook does"
homepage: https://docs.openclaw.ai/hooks#my-hook
metadata: {"openclaw":{"emoji":"🔗","events":["command:new"],"requires":{"bins":["node"]}}}
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

### Metadata 欄位

`metadata.openclaw` 物件支援：

- **`emoji`**：CLI 的顯示 emoji（例如，`"💾"`）
- **`events`**：要監聽的事件陣列（例如，`["command:new", "command:reset"]`）
- **`export`**：要使用的命名匯出（預設為 `"default"`）
- **`homepage`**：文件 URL
- **`requires`**：可選要求
  - **`bins`**：PATH 上所需的二進位檔案（例如，`["git", "node"]`）
  - **`anyBins`**：這些二進位檔案中必須至少存在一個
  - **`env`**：所需環境變數
  - **`config`**：所需設定路徑（例如，`["workspace.dir"]`）
  - **`os`**：所需平台（例如，`["darwin", "linux"]`）
- **`always`**：繞過資格檢查（布林值）
- **`install`**：安裝方法（對於捆綁 hooks：`[{"id":"bundled","kind":"bundled"}]`）

### Handler 實作

`handler.ts` 檔案匯出 `HookHandler` 函式：

```typescript
import type { HookHandler } from '../../src/hooks/hooks.js';

const myHandler: HookHandler = async (event) => {
  // Only trigger on 'new' command
  if (event.type !== 'command' || event.action !== 'new') {
    return;
  }

  console.log(`[my-hook] New command triggered`);
  console.log(`  Session: ${event.sessionKey}`);
  console.log(`  Timestamp: ${event.timestamp.toISOString()}`);

  // Your custom logic here

  // Optionally send message to user
  event.messages.push('✨ My hook executed!');
};

export default myHandler;
```

#### 事件上下文

每個事件包括：

```typescript
{
  type: 'command' | 'session' | 'agent' | 'gateway',
  action: string,              // 例如，'new', 'reset', 'stop'
  sessionKey: string,          // Session 識別符
  timestamp: Date,             // 事件發生時
  messages: string[],          // 在此處推送訊息以發送給使用者
  context: {
    sessionEntry?: SessionEntry,
    sessionId?: string,
    sessionFile?: string,
    commandSource?: string,    // 例如，'whatsapp', 'telegram'
    senderId?: string,
    workspaceDir?: string,
    bootstrapFiles?: WorkspaceBootstrapFile[],
    cfg?: OpenClawConfig
  }
}
```

## 事件類型

### 指令事件

在發出 agent 指令時觸發：

- **`command`**：所有指令事件（一般監聽器）
- **`command:new`**：當發出 `/new` 指令時
- **`command:reset`**：當發出 `/reset` 指令時
- **`command:stop`**：當發出 `/stop` 指令時

### Agent 事件

- **`agent:bootstrap`**：在注入工作區 bootstrap 檔案之前（hooks 可以改變 `context.bootstrapFiles`）

### Gateway 事件

當 gateway 啟動時觸發：

- **`gateway:startup`**：在頻道啟動和 hooks 載入之後

### Tool Result Hooks（外掛 API）

這些 hooks 不是事件流監聽器；它們讓外掛在 OpenClaw 持久化工具結果之前同步調整工具結果。

- **`tool_result_persist`**：在工具結果寫入會話記錄之前轉換它們。必須是同步的；返回更新的工具結果 payload 或 `undefined` 以保持原樣。請參閱 [Agent Loop](/concepts/agent-loop)。

### 未來事件

計畫的事件類型：

- **`session:start`**：當新會話開始時
- **`session:end`**：當會話結束時
- **`agent:error`**：當 agent 遇到錯誤時
- **`message:sent`**：當發送訊息時
- **`message:received`**：當接收訊息時

## 建立自訂 Hooks

### 1. 選擇位置

- **工作區 hooks**（`<workspace>/hooks/`）：Per-agent，最高優先順序
- **Managed hooks**（`~/.openclaw/hooks/`）：跨工作區共享

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
metadata: {"openclaw":{"emoji":"🎯","events":["command:new"]}}
---

# My Custom Hook

This hook does something useful when you issue `/new`.
```

### 4. 建立 handler.ts

```typescript
import type { HookHandler } from '../../src/hooks/hooks.js';

const handler: HookHandler = async (event) => {
  if (event.type !== 'command' || event.action !== 'new') {
    return;
  }

  console.log('[my-hook] Running!');
  // Your logic here
};

export default handler;
```

### 5. 啟用和測試

```bash
# 驗證 hook 已發現
openclaw hooks list

# 啟用它
openclaw hooks enable my-hook

# 重新啟動您的 gateway 處理程序（macOS 上的選單列 app 重新啟動，或重新啟動您的 dev 處理程序）

# 觸發事件
# 透過您的訊息頻道發送 /new
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

### Per-Hook 設定

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

### Extra 目錄

從其他目錄載入 hooks：

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

### 舊版設定格式（仍支援）

舊設定格式仍可用於向後相容性：

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

**遷移**：對新 hooks 使用新的基於發現的系統。舊版 handlers 在基於目錄的 hooks 之後載入。

## CLI 指令

### 列出 Hooks

```bash
# 列出所有 hooks
openclaw hooks list

# 僅顯示符合資格的 hooks
openclaw hooks list --eligible

# 詳細輸出（顯示缺少的要求）
openclaw hooks list --verbose

# JSON 輸出
openclaw hooks list --json
```

### Hook 資訊

```bash
# 顯示關於 hook 的詳細資訊
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

## 捆綁 Hooks

### session-memory

當您發出 `/new` 時，將會話上下文儲存到記憶體。

**事件**：`command:new`

**要求**：必須設定 `workspace.dir`

**輸出**：`<workspace>/memory/YYYY-MM-DD-slug.md`（預設為 `~/.openclaw/workspace`）

**它的作用**：
1. 使用 pre-reset 會話條目來定位正確的記錄
2. 提取對話的最後 15 行
3. 使用 LLM 生成描述性檔名 slug
4. 將會話 metadata 儲存到dated memory 檔案

**範例輸出**：

```markdown
# Session: 2026-01-16 14:30:00 UTC

- **Session Key**: agent:main:main
- **Session ID**: abc123def456
- **Source**: telegram
```

**檔名範例**：
- `2026-01-16-vendor-pitch.md`
- `2026-01-16-api-design.md`
- `2026-01-16-1430.md`（如果 slug 生成失敗，則為回退時間戳）

**啟用**：

```bash
openclaw hooks enable session-memory
```

### command-logger

將所有指令事件記錄到集中審計檔案。

**事件**：`command`

**要求**：無

**輸出**：`~/.openclaw/logs/commands.log`

**它的作用**：
1. 捕獲事件詳細資訊（指令操作、時間戳、會話鍵、發送者 ID、來源）
2. 以 JSONL 格式追加到日誌檔案
3. 在背景中靜默執行

**範例日誌條目**：

```jsonl
{"timestamp":"2026-01-16T14:30:00.000Z","action":"new","sessionKey":"agent:main:main","senderId":"+1234567890","source":"telegram"}
{"timestamp":"2026-01-16T15:45:22.000Z","action":"stop","sessionKey":"agent:main:main","senderId":"user@example.com","source":"whatsapp"}
```

**查看日誌**：

```bash
# 查看最近的指令
tail -n 20 ~/.openclaw/logs/commands.log

# 使用 jq 美化列印
cat ~/.openclaw/logs/commands.log | jq .

# 按操作過濾
grep '"action":"new"' ~/.openclaw/logs/commands.log | jq .
```

**啟用**：

```bash
openclaw hooks enable command-logger
```

### soul-evil

在清除視窗期間或透過隨機機率將注入的 `SOUL.md` 內容替換為 `SOUL_EVIL.md`。

**事件**：`agent:bootstrap`

**文件**：[SOUL Evil Hook](/hooks/soul-evil)

**輸出**：未寫入檔案；swap 僅在記憶體中發生。

**啟用**：

```bash
openclaw hooks enable soul-evil
```

**設定**：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "soul-evil": {
          "enabled": true,
          "file": "SOUL_EVIL.md",
          "chance": 0.1,
          "purge": { "at": "21:00", "duration": "15m" }
        }
      }
    }
  }
}
```

### boot-md

當 gateway 啟動時執行 `BOOT.md`（在頻道啟動之後）。
必須啟用內部 hooks 才能執行此操作。

**事件**：`gateway:startup`

**要求**：必須設定 `workspace.dir`

**它的作用**：
1. 從您的工作區讀取 `BOOT.md`
2. 透過 agent runner 執行指令
3. 透過訊息工具發送任何請求的出站訊息

**啟用**：

```bash
openclaw hooks enable boot-md
```

## 最佳實踐

### 保持 Handlers 快速

Hooks 在指令處理期間執行。保持它們輕量級：

```typescript
// ✓ 好 - async 工作，立即返回
const handler: HookHandler = async (event) => {
  void processInBackground(event); // Fire and forget
};

// ✗ 壞 - 阻止指令處理
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
    console.error('[my-handler] Failed:', err instanceof Error ? err.message : String(err));
    // Don't throw - let other handlers run
  }
};
```

### 儘早過濾事件

如果事件不相關，則儘早返回：

```typescript
const handler: HookHandler = async (event) => {
  // Only handle 'new' commands
  if (event.type !== 'command' || event.action !== 'new') {
    return;
  }

  // Your logic here
};
```

### 使用特定事件鍵

盡可能在 metadata 中指定精確事件：

```yaml
metadata: {"openclaw":{"events":["command:new"]}}  # 特定
```

而不是：

```yaml
metadata: {"openclaw":{"events":["command"]}}      # 一般 - 更多開銷
```

## 除錯

### 啟用 Hook 記錄

Gateway 在啟動時記錄 hook 載入：

```
Registered hook: session-memory -> command:new
Registered hook: command-logger -> command
Registered hook: boot-md -> gateway:startup
```

### 檢查發現

列出所有發現的 hooks：

```bash
openclaw hooks list --verbose
```

### 檢查註冊

在您的 handler 中，記錄它何時被呼叫：

```typescript
const handler: HookHandler = async (event) => {
  console.log('[my-handler] Triggered:', event.type, event.action);
  // Your logic
};
```

### 驗證資格

檢查為什麼 hook 不符合資格：

```bash
openclaw hooks info my-hook
```

在輸出中尋找缺少的要求。

## 測試

### Gateway 日誌

監視 gateway 日誌以查看 hook 執行：

```bash
# macOS
./scripts/clawlog.sh -f

# 其他平台
tail -f ~/.openclaw/gateway.log
```

### 直接測試 Hooks

隔離測試您的 handlers：

```typescript
import { test } from 'vitest';
import { createHookEvent } from './src/hooks/hooks.js';
import myHandler from './hooks/my-hook/handler.js';

test('my handler works', async () => {
  const event = createHookEvent('command', 'new', 'test-session', {
    foo: 'bar'
  });

  await myHandler(event);

  // Assert side effects
});
```

## 架構

### 核心元件

- **`src/hooks/types.ts`**：型別定義
- **`src/hooks/workspace.ts`**：目錄掃描和載入
- **`src/hooks/frontmatter.ts`**：HOOK.md metadata 解析
- **`src/hooks/config.ts`**：資格檢查
- **`src/hooks/hooks-status.ts`**：狀態報告
- **`src/hooks/loader.ts`**：動態模組載入器
- **`src/cli/hooks-cli.ts`**：CLI 指令
- **`src/gateway/server-startup.ts`**：在 gateway 啟動時載入 hooks
- **`src/auto-reply/reply/commands-core.ts`**：觸發指令事件

### 發現流程

```
Gateway startup
    ↓
Scan directories (workspace → managed → bundled)
    ↓
Parse HOOK.md files
    ↓
Check eligibility (bins, env, config, os)
    ↓
Load handlers from eligible hooks
    ↓
Register handlers for events
```

### 事件流程

```
User sends /new
    ↓
Command validation
    ↓
Create hook event
    ↓
Trigger hook (all registered handlers)
    ↓
Command processing continues
    ↓
Session reset
```

## 疑難排解

### Hook 未發現

1. 檢查目錄結構：
   ```bash
   ls -la ~/.openclaw/hooks/my-hook/
   # 應顯示：HOOK.md, handler.ts
   ```

2. 驗證 HOOK.md 格式：
   ```bash
   cat ~/.openclaw/hooks/my-hook/HOOK.md
   # 應具有帶 name 和 metadata 的 YAML frontmatter
   ```

3. 列出所有發現的 hooks：
   ```bash
   openclaw hooks list
   ```

### Hook 不符合資格

檢查要求：

```bash
openclaw hooks info my-hook
```

尋找缺少的：
- 二進位檔案（檢查 PATH）
- 環境變數
- 設定值
- OS 相容性

### Hook 未執行

1. 驗證 hook 已啟用：
   ```bash
   openclaw hooks list
   # 應在啟用的 hooks 旁顯示 ✓
   ```

2. 重新啟動您的 gateway 處理程序，以便 hooks 重新載入。

3. 檢查 gateway 日誌中的錯誤：
   ```bash
   ./scripts/clawlog.sh | grep hook
   ```

### Handler 錯誤

檢查 TypeScript/import 錯誤：

```bash
# 直接測試 import
node -e "import('./path/to/handler.ts').then(console.log)"
```

## 遷移指南

### 從舊版設定到發現

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
   metadata: {"openclaw":{"emoji":"🎯","events":["command:new"]}}
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

4. 驗證並重新啟動您的 gateway 處理程序：
   ```bash
   openclaw hooks list
   # 應顯示：🎯 my-hook ✓
   ```

**遷移的好處**：
- 自動發現
- CLI 管理
- 資格檢查
- 更好的文件
- 一致的結構

## 另請參閱

- [CLI Reference: hooks](/cli/hooks)
- [Bundled Hooks README](https://github.com/openclaw/openclaw/tree/main/src/hooks/bundled)
- [Webhook Hooks](/automation/webhook)
- [Configuration](/gateway/configuration#hooks)
