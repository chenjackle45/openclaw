---
summary: "`openclaw hooks` CLI 參考（Agent hooks 管理）"
read_when:
  - 想要管理 Agent hooks 時
  - 想要安裝或更新 hooks 時
title: "hooks（Hook 管理）"
---

# `openclaw hooks`

管理 Agent hooks（針對 `/new`、`/reset` 等指令及 Gateway 啟動事件的事件驅動自動化）。

相關資訊：

- Hooks：[Hooks](/zh-Hant/automation/hooks)
- Plugin hooks：[Plugins](/zh-Hant/tools/plugin#plugin-hooks)

## 列出所有 Hooks

```bash
openclaw hooks list
```

列出從工作區、受管目錄及內建目錄中發現的所有 hooks。

**選項：**

- `--eligible`：僅顯示符合條件的 hooks（需求已滿足）
- `--json`：以 JSON 格式輸出
- `-v, --verbose`：顯示詳細資訊，包含缺少的需求

**輸出範例：**

```
Hooks (4/4 ready)

Ready:
  🚀 boot-md ✓ - Run BOOT.md on gateway startup
  📎 bootstrap-extra-files ✓ - Inject extra workspace bootstrap files during agent bootstrap
  📝 command-logger ✓ - Log all command events to a centralized audit file
  💾 session-memory ✓ - Save session context to memory when /new command is issued
```

**範例（詳細模式）：**

```bash
openclaw hooks list --verbose
```

顯示不符合條件的 hooks 的缺少需求。

**範例（JSON）：**

```bash
openclaw hooks list --json
```

返回結構化 JSON 供程式化使用。

## 查看 Hook 資訊

```bash
openclaw hooks info <name>
```

顯示特定 hook 的詳細資訊。

**參數：**

- `<name>`：Hook 名稱（例如 `session-memory`）

**選項：**

- `--json`：以 JSON 格式輸出

**範例：**

```bash
openclaw hooks info session-memory
```

**輸出：**

```
💾 session-memory ✓ Ready

Save session context to memory when /new command is issued

Details:
  Source: openclaw-bundled
  Path: /path/to/openclaw/hooks/bundled/session-memory/HOOK.md
  Handler: /path/to/openclaw/hooks/bundled/session-memory/handler.ts
  Homepage: https://docs.openclaw.ai/automation/hooks#session-memory
  Events: command:new

Requirements:
  Config: ✓ workspace.dir
```

## 檢查 Hooks 可用性

```bash
openclaw hooks check
```

顯示 hook 可用性狀態摘要（就緒 vs. 未就緒的數量）。

**選項：**

- `--json`：以 JSON 格式輸出

**輸出範例：**

```
Hooks Status

Total hooks: 4
Ready: 4
Not ready: 0
```

## 啟用 Hook

```bash
openclaw hooks enable <name>
```

透過將特定 hook 加入您的 config（`~/.openclaw/config.json`）來啟用它。

**注意：** 由 plugins 管理的 hooks 在 `openclaw hooks list` 中會顯示 `plugin:<id>`，
無法在此處啟用/停用。請改為啟用/停用對應的 plugin。

**參數：**

- `<name>`：Hook 名稱（例如 `session-memory`）

**範例：**

```bash
openclaw hooks enable session-memory
```

**輸出：**

```
✓ Enabled hook: 💾 session-memory
```

**執行動作：**

- 檢查 hook 是否存在且符合條件
- 在 config 中將 `hooks.internal.entries.<name>.enabled` 更新為 `true`
- 儲存 config 至磁碟

**啟用後：**

- 重新啟動 gateway 使 hooks 重新載入（macOS 上請透過選單列 App 重新啟動，或在開發環境重新啟動 gateway 進程）。

## 停用 Hook

```bash
openclaw hooks disable <name>
```

透過更新 config 停用特定 hook。

**參數：**

- `<name>`：Hook 名稱（例如 `command-logger`）

**範例：**

```bash
openclaw hooks disable command-logger
```

**輸出：**

```
⏸ Disabled hook: 📝 command-logger
```

**停用後：**

- 重新啟動 gateway 使 hooks 重新載入

## 安裝 Hooks

```bash
openclaw hooks install <path-or-spec>
openclaw hooks install <npm-spec> --pin
```

從本地資料夾/封存檔或 npm 安裝 hook pack。

npm specs 僅限**registry**（套件名稱 + 可選的**確切版本**或
**dist-tag**）。Git/URL/file specs 和 semver ranges 均被拒絕。依賴安裝使用 `--ignore-scripts` 以確保安全。

bare specs 和 `@latest` 保持在穩定軌道。若 npm 將其中任一解析為預發布版本，OpenClaw 會停止並要求您使用預發布標籤（如 `@beta`/`@rc`）或確切的預發布版本明確選擇。

**執行動作：**

- 將 hook pack 複製至 `~/.openclaw/hooks/<id>`
- 在 `hooks.internal.entries.*` 中啟用已安裝的 hooks
- 在 `hooks.internal.installs` 下記錄安裝

**選項：**

- `-l, --link`：連結本地目錄而非複製（將其加入 `hooks.internal.load.extraDirs`）
- `--pin`：以確切解析的 `name@version` 記錄 npm 安裝至 `hooks.internal.installs`

**支援的封存格式：** `.zip`、`.tgz`、`.tar.gz`、`.tar`

**範例：**

```bash
# 本地目錄
openclaw hooks install ./my-hook-pack

# 本地封存檔
openclaw hooks install ./my-hook-pack.zip

# NPM 套件
openclaw hooks install @openclaw/my-hook-pack

# 連結本地目錄而不複製
openclaw hooks install -l ./my-hook-pack
```

## 更新 Hooks

```bash
openclaw hooks update <id>
openclaw hooks update --all
```

更新已安裝的 hook packs（僅限 npm 安裝）。

**選項：**

- `--all`：更新所有已追蹤的 hook packs
- `--dry-run`：顯示將會變更的內容而不實際寫入

當存在已儲存的完整性雜湊且取得的 artifact 雜湊發生變化時，
OpenClaw 會印出警告並在繼續前要求確認。在 CI/非互動式執行中使用
全域 `--yes` 以略過提示。

## 內建 Hooks

### session-memory

當您執行 `/new` 時，將會話情境儲存至記憶體。

**啟用：**

```bash
openclaw hooks enable session-memory
```

**輸出：** `~/.openclaw/workspace/memory/YYYY-MM-DD-slug.md`

**參閱：** [session-memory 說明](/zh-Hant/automation/hooks#session-memory)

### bootstrap-extra-files

在 `agent:bootstrap` 期間注入額外的啟動檔案（例如 monorepo 本地的 `AGENTS.md` / `TOOLS.md`）。

**啟用：**

```bash
openclaw hooks enable bootstrap-extra-files
```

**參閱：** [bootstrap-extra-files 說明](/zh-Hant/automation/hooks#bootstrap-extra-files)

### command-logger

將所有指令事件記錄至集中式稽核檔案。

**啟用：**

```bash
openclaw hooks enable command-logger
```

**輸出：** `~/.openclaw/logs/commands.log`

**查看日誌：**

```bash
# 最近的指令
tail -n 20 ~/.openclaw/logs/commands.log

# 格式化輸出
cat ~/.openclaw/logs/commands.log | jq .

# 依動作篩選
grep '"action":"new"' ~/.openclaw/logs/commands.log | jq .
```

**參閱：** [command-logger 說明](/zh-Hant/automation/hooks#command-logger)

### boot-md

在 gateway 啟動時（頻道啟動後）執行 `BOOT.md`。

**事件**：`gateway:startup`

**啟用**：

```bash
openclaw hooks enable boot-md
```

**參閱：** [boot-md 說明](/zh-Hant/automation/hooks#boot-md)
