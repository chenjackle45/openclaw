---
title: "plugins(外掛管理)"
summary: "`openclaw plugins` CLI 參考（列表、安裝、啟用/停用與診斷）"
read_when:
  - 想要安裝或管理 Gateway 外掛時
  - 想要偵錯外掛加載失敗的問題時
---

# `openclaw plugins`

管理 Gateway 外掛與擴充功能（這些功能會直接在 Gateway 進程中加載）。

相關資訊：
- 外掛系統總覽：[外掛 (Plugins)](/plugin)
- 外掛定義與規格：[外掛清單 (Plugin manifest)](/plugins/manifest)
- 安全性加固：[安全性 (Security)](/gateway/security)

## 指令說明

```bash
# 列出所有外掛
openclaw plugins list

# 查看特定外掛的詳細資訊
openclaw plugins info <外掛ID>

# 啟用或停用外掛
openclaw plugins enable <外掛ID>
openclaw plugins disable <外掛ID>

# 執行外掛系統診斷
openclaw plugins doctor

# 更新外掛（單一或全部）
openclaw plugins update <外掛ID>
openclaw plugins update --all
```

OpenClaw 內建了一些外掛，但預設為停用狀態。請使用 `plugins enable` 來啟用它們。

所有外掛都必須包含一個 `openclaw.plugin.json` 檔案，並定義對應的 JSON Schema (`configSchema`)，即使該 Schema 為空。缺少或無效的資訊清單或 Schema 會導致外掛無法加載，並造成配置驗證失敗。

### 安裝外掛

```bash
openclaw plugins install <路徑或規格>
```

**安全提醒**：安裝外掛等同於執行來源不明的程式碼，建議優先選用已鎖定版本的官方或受信任外掛。

支援格式：`.zip`, `.tgz`, `.tar.gz`, `.tar`。

使用 `--link` 旗標可連結本地目錄而不進行複製（這會將該路徑加入 `plugins.load.paths`）：

```bash
openclaw plugins install -l ./my-plugin
```

### 更新外掛

```bash
# 更新特定外掛
openclaw plugins update <外掛ID>

# 更新所有追蹤的外掛
openclaw plugins update --all

# 執行乾跑 (Dry-run)，僅預覽變更而不寫入
openclaw plugins update <外掛ID> --dry-run
```

**注意**：更新功能僅適用於透過 npm 安裝的外掛（這些外掛被記錄在 `plugins.installs` 中）。
