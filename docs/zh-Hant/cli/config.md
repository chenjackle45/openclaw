---
title: "config(配置管理)"
summary: "`openclaw config` CLI 參考（獲取、設定或移除配置值）"
read_when:
  - 想要以非互動方式讀取或編輯配置時
---

# `openclaw config`

配置協助工具：透過路徑獲取、設定或移除配置值。若不帶子指令執行，則會啟動配置嚮導（等同於執行 `openclaw configure`）。

## 指令範例

```bash
# 獲取瀏覽器執行路徑
openclaw config get browser.executablePath

# 設定瀏覽器執行路徑
openclaw config set browser.executablePath "/usr/bin/google-chrome"

# 設定 Agent 預設心跳間隔
openclaw config set agents.defaults.heartbeat.every "2h"

# 為第一個 Agent 設定指定的執行節點
openclaw config set agents.list[0].tools.exec.node "node-id-or-name"

# 移除網頁搜尋的 API 金鑰
openclaw config unset tools.web.search.apiKey
```

## 路徑語法 (Paths)

路徑支援點號 (dot) 或中括號 (bracket) 記法：

```bash
openclaw config get agents.defaults.workspace
openclaw config get agents.list[0].id
```

使用 Agent 列表的索引值來指定特定的 Agent：

```bash
# 先列出所有 Agent
openclaw config get agents.list

# 設定列表中的第二位 Agent 的執行節點
openclaw config set agents.list[1].tools.exec.node "node-id-or-name"
```

## 數值解析 (Values)

數值在可能的情況下會被解析為 JSON5；否則將視為純字串。
使用 `--json` 旗標可強制要求進行 JSON5 解析。

```bash
# 字串範例
openclaw config set agents.defaults.heartbeat.every "0m"

# 數字與數組範例（使用 --json）
openclaw config set gateway.port 19001 --json
openclaw config set channels.whatsapp.groups '["*"]' --json
```

**注意**：編輯完成後，請務必重啟 Gateway 以套用變更。
