---
summary: "`openclaw plugins` CLI 參考（列表、安裝、解除安裝、啟用/停用、診斷）"
read_when:
  - 想要安裝或管理 Gateway 進程內 plugins 時
  - 想要偵錯 plugin 載入失敗時
title: "plugins（Plugin 管理）"
---

# `openclaw plugins`

管理 Gateway plugins/extensions（在進程內載入）。

相關資訊：

- Plugin 系統：[Plugins](/zh-Hant/tools/plugin)
- Plugin manifest + schema：[Plugin manifest](/zh-Hant/plugins/manifest)
- 安全性強化：[Security](/zh-Hant/gateway/security)

## 指令

```bash
openclaw plugins list
openclaw plugins info <id>
openclaw plugins enable <id>
openclaw plugins disable <id>
openclaw plugins uninstall <id>
openclaw plugins doctor
openclaw plugins update <id>
openclaw plugins update --all
```

內建 plugins 隨 OpenClaw 一起發布但預設停用。使用 `plugins enable` 來
啟用它們。

所有 plugins 必須包含一個帶有內聯 JSON Schema 的 `openclaw.plugin.json` 檔案
（`configSchema`，即使為空）。缺少/無效的 manifests 或 schemas 會阻止
plugin 載入並導致 config 驗證失敗。

### 安裝

```bash
openclaw plugins install <path-or-spec>
openclaw plugins install <npm-spec> --pin
```

安全注意事項：將 plugin 安裝視同執行程式碼。建議優先使用固定版本。

npm specs 僅限**registry**（套件名稱 + 可選的**確切版本**或
**dist-tag**）。Git/URL/file specs 和 semver ranges 均被拒絕。依賴安裝使用 `--ignore-scripts` 以確保安全。

bare specs 和 `@latest` 保持在穩定軌道。若 npm 將其中任一解析為預發布版本，OpenClaw 會停止並要求您使用預發布標籤（如 `@beta`/`@rc`）或確切的預發布版本（如
`@1.2.3-beta.4`）明確選擇。

若 bare install spec 匹配到內建 plugin ID（例如 `diffs`），OpenClaw
會直接安裝內建 plugin。若要安裝同名的 npm 套件，
請使用明確的 scoped spec（例如 `@scope/diffs`）。

支援的封存格式：`.zip`、`.tgz`、`.tar.gz`、`.tar`。

使用 `--link` 以避免複製本地目錄（加入至 `plugins.load.paths`）：

```bash
openclaw plugins install -l ./my-plugin
```

使用 `--pin` 於 npm 安裝以將解析後的確切 spec（`name@version`）儲存至
`plugins.installs`，同時保持預設行為未固定。

### 解除安裝

```bash
openclaw plugins uninstall <id>
openclaw plugins uninstall <id> --dry-run
openclaw plugins uninstall <id> --keep-files
```

`uninstall` 從 `plugins.entries`、`plugins.installs`、
plugin 允許清單及適用時的鏈接 `plugins.load.paths` 條目中移除 plugin 記錄。
對於目前啟用的記憶體 plugins，記憶體插槽會重設為 `memory-core`。

預設情況下，解除安裝也會移除目前狀態目錄 extensions 根目錄下的 plugin 安裝目錄（`$OPENCLAW_STATE_DIR/extensions/<id>`）。使用
`--keep-files` 可在磁碟上保留檔案。

`--keep-config` 作為 `--keep-files` 的已棄用別名仍受支援。

### 更新

```bash
openclaw plugins update <id>
openclaw plugins update --all
openclaw plugins update <id> --dry-run
```

更新僅適用於從 npm 安裝的 plugins（追蹤在 `plugins.installs` 中）。

當存在已儲存的完整性雜湊且取得的 artifact 雜湊發生變化時，
OpenClaw 會印出警告並在繼續前要求確認。在 CI/非互動式執行中使用
全域 `--yes` 以略過提示。
