---
title: "index(指令總覽)"
summary: "OpenClaw CLI 參考手冊，包含 `openclaw` 指令、子指令及選項說明"
read_when:
  - 新增或修改 CLI 指令或選項時
  - 記錄新的指令介面時
---

# 指令參考 (CLI reference)

本頁面說明目前的 CLI 行為。若指令有所變更，請務必更新此文件。

## 指令頁面

- [`setup`](/cli/setup) (環境初始化)
- [`onboard`](/cli/onboard) (新手引導)
- [`configure`](/cli/configure) (互動式配置)
- [`config`](/cli/config) (配置管理)
- [`doctor`](/cli/doctor) (健康檢查與修復)
- [`dashboard`](/cli/dashboard) (控制中心)
- [`reset`](/cli/reset) (重設狀態)
- [`uninstall`](/cli/uninstall) (解除安裝)
- [`update`](/cli/update) (系統更新)
- [`message`](/cli/message) (訊息操作)
- [`agent`](/cli/agent) (直連 Agent)
- [`agents`](/cli/agents) (Agent 管理)
- [`acp`](/cli/acp) (ACP 橋接)
- [`status`](/cli/status) (狀態盤查)
- [`health`](/cli/health) (健康度)
- [`sessions`](/cli/sessions) (會話管理)
- [`gateway`](/cli/gateway) (Gateway 服務)
- [`logs`](/cli/logs) (日誌查看)
- [`system`](/cli/system) (系統事件)
- [`models`](/cli/models) (模型配置)
- [`memory`](/cli/memory) (記憶體搜尋)
- [`nodes`](/cli/nodes) (節點列表)
- [`devices`](/cli/devices) (裝置列表)
- [`node`](/cli/node) (節點操作)
- [`approvals`](/cli/approvals) (核准管理)
- [`sandbox`](/cli/sandbox) (沙盒管理)
- [`tui`](/cli/tui) (終端機介面)
- [`browser`](/cli/browser) (瀏覽器控制)
- [`cron`](/cli/cron) (排程管理)
- [`dns`](/cli/dns) (DNS 配置)
- [`docs`](/cli/docs) (文件閱讀)
- [`hooks`](/cli/hooks) (鉤子管理)
- [`webhooks`](/cli/webhooks) (Webhooks 管理)
- [`pairing`](/cli/pairing) (裝置配對)
- [`plugins`](/cli/plugins) (外掛管理)
- [`channels`](/cli/channels) (聊天頻道)
- [`security`](/cli/security) (安全性審查)
- [`skills`](/cli/skills) (技能管理)
- [`voicecall`](/cli/voicecall) (語音通話外掛)

## 全域旗標 (Global flags)

- `--dev`：將狀態隔離於 `~/.openclaw-dev` 下，並切換至開發預設埠位。
- `--profile <名稱>`：將狀態隔離於 `~/.openclaw-<名稱>` 下。
- `--no-color`：停用 ANSI 色彩。
- `--update`：`openclaw update` 的簡寫（僅限源碼安裝版）。
- `-V`, `--version`, `-v`：列印版本資訊並退出。

## 輸出樣式 (Output styling)

- ANSI 色彩與進度指示僅在 TTY 會話中呈現。
- 在支援的終端機中，OSC-8 超連結將以「可點擊連結」呈現；否則會退回純文字 URL。
- 使用 `--json`（或部分支援出的 `--plain`）可停用樣式以獲得乾淨的輸出內容。
- `--no-color` 或設定環境變數 `NO_COLOR=1` 可停用色彩。
- 耗時較長的指令會顯示進度指示器。

## 色彩調色盤 (Color palette)

OpenClaw 採用「龍蝦調色盤 (Lobster palette)」進行 CLI 輸出。

- `accent` (#FF5A2D)：標題、標籤、主要強調內容。
- `accentBright` (#FF7A3D)：指令名稱、重點。
- `accentDim` (#D14A22)：次要強調內容。
- `info` (#FF8A5B)：資訊類數值。
- `success` (#2FBF71)：成功狀態。
- `warn` (#FFB020)：警告、退回機制、提醒。
- `error` (#E23D2D)：錯誤、失敗。
- `muted` (#8B7F77)：取消強調、元資料。

## 指令樹 (Command tree)

```
openclaw [--dev] [--profile <名稱>] <指令>
  setup (初始化)
  onboard (新手引導)
  configure (配置嚮導)
  config (配置管理)
    get / set / unset
  doctor (疑難排解)
  security (安全審查)
    audit
  reset (重設)
  uninstall (解除安裝)
  update (更新)
  channels (頻道管理)
    list / status / logs / add / remove / login / logout
  skills (技能管理)
    list / info / check
  plugins (外掛管理)
    list / info / install / enable / disable / doctor
  memory (記憶體)
    status / index / search
  message (訊息)
  agent (執行 Agent)
  agents (Agent 管理)
    list / add / delete
  acp (ACP 橋接)
  status (狀態)
  health (健康)
  sessions (會話列表)
  gateway (Gateway 管理)
    call / health / status / probe / discover / install / uninstall / start / stop / restart / run
  logs (查看日誌)
  system (系統操作)
    event / heartbeat / presence
  models (模型配置)
    list / status / set / set-image / aliases / fallbacks / scan / auth
  sandbox (沙盒管理)
  cron (排程)
  nodes (節點發現)
  devices (裝置發現)
  node (節點控制)
  approvals (執行核准)
  browser (瀏覽器自動化)
  hooks (鉤子)
  webhooks (網路鉤子)
  pairing (配對)
  docs (文件)
  dns (廣域發現)
  tui (TUI 介面)
```

## 常見區域說明

### 安全性 (Security)
- `openclaw security audit`：審查配置與本地狀態中常見的安全漏洞。
- `--fix` 旗標：可自動收緊權限設定。

### 外掛 (Plugins)
- `openclaw plugins list`：發現可用外掛。
- 大多數外掛變更後需要重啟 Gateway。

### 記憶體 (Memory)
- 針對 `MEMORY.md` 與 `memory/*.md` 進行向量搜尋。
- `openclaw memory index`：重新建立記憶體檔案索引。

### 聊天斜線指令
聊天訊息支援 `/...` 指令形式。請參閱 [斜線指令指南](/tools/slash-commands)。
- `/status`：快速診斷。
- `/config`：持久化配置變更。
