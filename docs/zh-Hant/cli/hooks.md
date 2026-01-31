---
title: "hooks(鉤子管理)"
summary: "`openclaw hooks` CLI 參考（Agent 鉤子管理）"
read_when:
  - 想要管理 Agent 鉤子時
  - 想要安裝或更新鉤子時
---

# `openclaw hooks`

管理 Agent 鉤子 (Agent hooks)。這些是針對 `/new`、`/reset` 指令以及 Gateway 啟動等事件觸發的自動化功能。

相關資訊：
- 鉤子概念導覽：[鉤子 (Hooks)](/hooks)
- 外掛中的鉤子：[外掛系統](/plugin#plugin-hooks)

## 列出所有鉤子

```bash
openclaw hooks list
```

列出從工作區、受管目錄及內建目錄中發現的所有鉤子。

**參數選項**：
- `--eligible`：僅顯示符合執行條件（依賴項已滿足）的鉤子。
- `--json`：以 JSON 格式輸出。
- `-v, --verbose`：顯示詳細資訊，包含缺少的配置或依賴需求。

**輸出範例**：

```
Hooks (4/4 ready)

Ready:
  🚀 boot-md ✓ - 在 Gateway 啟動時執行 BOOT.md
  📝 command-logger ✓ - 將所有指令事件記錄至集中式的審查檔案
  💾 session-memory ✓ - 當執行 /new 指令時，將會話上下文存入記憶體
  😈 soul-evil ✓ - 在肅清期間或隨機切換注入的 SOUL 內容
```

## 獲取鉤子詳細資訊

```bash
openclaw hooks info <名稱>
```

顯示特定鉤子的詳細資訊。

**範例**：

```bash
openclaw hooks info session-memory
```

## 檢查鉤子可用性狀態

```bash
openclaw hooks check
```

顯示鉤子可用性狀態的摘要（就緒 vs 未就緒的數量）。

## 啟用鉤子

```bash
openclaw hooks enable <名稱>
```

透過將特定鉤子加入您的配置檔案 (`~/.openclaw/config.json`) 來啟用它。

**注意**：由外掛管理的鉤子在 `openclaw hooks list` 中會顯示為 `plugin:<ID>`，這類鉤子無法在此處單獨設定。請改為啟用/停用對應的外掛。

**指令範例**：

```bash
openclaw hooks enable session-memory
```

**執行動作**：
- 檢查鉤子是否存在且符合執行條件。
- 將配置中的 `hooks.internal.entries.<名稱>.enabled` 設定為 `true`。
- 儲存配置至磁碟。

**啟用後**：
- **必須重啟 Gateway** 才能使變更生效（macOS 上請由選單列選單點選重啟，或在開發環境重新啟動 Gateway 進程）。

## 停用鉤子

```bash
openclaw hooks disable <名稱>
```

透過更新配置檔案來停用特定的鉤子。停用後同樣需要重啟 Gateway。

## 安裝鉤子

```bash
openclaw hooks install <路徑或規格>
```

從本地資料夾、壓縮檔或 npm 安裝鉤子包 (Hook pack)。

**參數選項**：
- `-l, --link`：連結本地目錄而非複製檔案（這會將該路徑加入 `hooks.internal.load.extraDirs`）。

**支援格式**：`.zip`, `.tgz`, `.tar.gz`, `.tar`

**範例**：

```bash
# 從本地目錄安裝
openclaw hooks install ./my-hook-pack

# 從 NPM 套件安裝
openclaw hooks install @openclaw/my-hook-pack

# 連結本地目錄而不複製檔案
openclaw hooks install -l ./my-hook-pack
```

## 更新鉤子

```bash
openclaw hooks update <ID>
openclaw hooks update --all
```

更新已安裝的鉤子包（僅支援透過 npm 安裝的項目）。

## 內建鉤子說明

### session-memory
當您執行 `/new` 時，將會話上下文儲存至記憶體。
- **輸出路徑**：`~/.openclaw/workspace/memory/YYYY-MM-DD-標題.md`
- **文件連結**：[session-memory 說明](/hooks#session-memory)

### command-logger
將所有指令事件記錄至集中式的審查檔案。
- **輸出路徑**：`~/.openclaw/logs/commands.log`
- **查看日誌範例**：`tail -n 20 ~/.openclaw/logs/commands.log`
- **文件連結**：[command-logger 說明](/hooks#command-logger)

### soul-evil
在特定視窗期間或隨機機會下，將注入的 `SOUL.md` 內容替換為 `SOUL_EVIL.md`。
- **文件連結**：[SOUL Evil 鉤子](/hooks/soul-evil)

### boot-md
在 Gateway 啟動（且頻道啟動後）時執行 `BOOT.md`。
- **事件觸發點**：`gateway:startup`
- **文件連結**：[boot-md 說明](/hooks#boot-md)
