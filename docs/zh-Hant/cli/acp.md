---
summary: "執行用於 IDE 整合的 ACP 橋接器"
read_when:
  - 正在設定基於 ACP 的 IDE 整合時
  - 正在偵錯 ACP 會話至 Gateway 的路由問題時
title: "acp（Agent Client Protocol 橋接器）"
---

# acp

執行 [Agent Client Protocol (ACP)](https://agentclientprotocol.com/) 橋接器以與 OpenClaw Gateway 進行通訊。

此指令會透過 stdio 與 IDE 進行 ACP 通訊，並透過 WebSocket 將提示轉發至 Gateway。它負責將 ACP 會話映射至 Gateway 的會話金鑰。

## Usage

```bash
openclaw acp

# 遠端 Gateway
openclaw acp --url wss://gateway-host:18789 --token <token>

# 遠端 Gateway（從檔案讀取 token）
openclaw acp --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token

# 附加至既存的會話金鑰
openclaw acp --session agent:main:main

# 透過標籤附加（該標籤必須已存在）
openclaw acp --session-label "support inbox"

# 在首次提示前重設會話金鑰
openclaw acp --session agent:main:main --reset-session
```

## ACP 客戶端（偵錯用）

使用內建的 ACP 客戶端在不依賴 IDE 的情況下檢查橋接器是否正常。
它會啟動 ACP 橋接器並允許您互動式地輸入提示。

```bash
openclaw acp client

# 將啟動的橋接器指向遠端 Gateway
openclaw acp client --server-args --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token

# 覆寫伺服器指令（預設：openclaw）
openclaw acp client --server "node" --server-args openclaw.mjs acp --url ws://127.0.0.1:19001
```

Permission model（客戶端偵錯模式）：

- 自動核准是基於白名單的，且僅適用於受信任的核心工具 ID。
- `read` 的自動核准範圍限於當前工作目錄（設定了 `--cwd` 時使用該目錄）。
- 未知／非核心工具名稱、超出範圍的讀取操作，以及危險工具始終需要明確的提示核准。
- 伺服器提供的 `toolCall.kind` 被視為不受信任的中繼資料（而非授權來源）。

## 使用情境

當 IDE（或其他客戶端）支援 Agent Client Protocol 且您希望由它來驅動 OpenClaw Gateway 會話時，請使用 ACP。

1. 確保 Gateway 正在運行（本地或遠端）。
2. 配置 Gateway 目標（透過 config 或旗標）。
3. 將您的 IDE 設定為透過 stdio 執行 `openclaw acp`。

配置範例（持久化）：

```bash
openclaw config set gateway.remote.url wss://gateway-host:18789
openclaw config set gateway.remote.token <token>
```

直接執行範例（不寫入配置）：

```bash
openclaw acp --url wss://gateway-host:18789 --token <token>
# 建議使用此方式以確保本地進程安全
openclaw acp --url wss://gateway-host:18789 --token-file ~/.openclaw/gateway.token
```

## 選擇 Agent

ACP 不會直接選擇 Agent，而是透過 Gateway 會話金鑰進行路由。

使用包含 Agent 範圍的會話金鑰來指定特定的 Agent：

```bash
openclaw acp --session agent:main:main
openclaw acp --session agent:design:main
openclaw acp --session agent:qa:bug-123
```

每個 ACP 會話會對應至單一 Gateway 會話金鑰。一個 Agent 可以擁有多個會話；除非您覆寫了金鑰或標籤，否則 ACP 會預設使用獨立的 `acp:<uuid>` 會話。

## 透過 `acpx` 使用（Codex、Claude 及其他 ACP 客戶端）

如果您想讓 Codex 或 Claude Code 等 coding agent 透過 ACP 與您的 OpenClaw bot 通訊，請使用 `acpx` 及其內建的 `openclaw` 目標。

典型流程：

1. 啟動 Gateway 並確保 ACP 橋接器可以連線到它。
2. 將 `acpx openclaw` 指向 `openclaw acp`。
3. 指定您希望 coding agent 使用的 OpenClaw 會話金鑰。

範例：

```bash
# 向預設的 OpenClaw ACP 會話發送一次性請求
acpx openclaw exec "Summarize the active OpenClaw session state."

# 建立持久命名會話以進行多輪對話
acpx openclaw sessions ensure --name codex-bridge
acpx openclaw -s codex-bridge --cwd /path/to/repo \
  "Ask my OpenClaw work agent for recent context relevant to this repo."
```

如果您希望 `acpx openclaw` 每次都指向特定的 Gateway 和會話金鑰，請在 `~/.acpx/config.json` 中覆寫 `openclaw` agent 指令：

```json
{
  "agents": {
    "openclaw": {
      "command": "env OPENCLAW_HIDE_BANNER=1 OPENCLAW_SUPPRESS_NOTES=1 openclaw acp --url ws://127.0.0.1:18789 --token-file ~/.openclaw/gateway.token --session agent:main:main"
    }
  }
}
```

如果您使用的是本地 OpenClaw 的 repo checkout，請使用直接的 CLI 入口點而非開發執行器，以保持 ACP 串流的清潔。例如：

```bash
env OPENCLAW_HIDE_BANNER=1 OPENCLAW_SUPPRESS_NOTES=1 node openclaw.mjs acp ...
```

這是讓 Codex、Claude Code 或其他支援 ACP 的客戶端從 OpenClaw agent 取得情境資訊的最簡便方式，無需抓取終端機畫面。

## Zed 編輯器設定

在 `~/.config/zed/settings.json` 中新增自訂 ACP Agent（或使用 Zed 的設定介面）：

```json
{
  "agent_servers": {
    "OpenClaw ACP": {
      "type": "custom",
      "command": "openclaw",
      "args": ["acp"],
      "env": {}
    }
  }
}
```

若要指定特定 Gateway 或 Agent：

```json
{
  "agent_servers": {
    "OpenClaw ACP": {
      "type": "custom",
      "command": "openclaw",
      "args": [
        "acp",
        "--url",
        "wss://gateway-host:18789",
        "--token",
        "<token>",
        "--session",
        "agent:design:main"
      ],
      "env": {}
    }
  }
}
```

在 Zed 中，開啟 Agent 面板並選擇「OpenClaw ACP」即可開始對話。

## Session 映射

預設情況下，ACP 會話會獲得一個帶有 `acp:` 前綴的獨立 Gateway 會話金鑰。
若要重複使用已知的會話，請傳遞會話金鑰或標籤：

- `--session <key>`：使用特定的 Gateway 會話金鑰。
- `--session-label <label>`：透過標籤解析現有會話。
- `--reset-session`：為該金鑰產生一個全新的會話 ID（金鑰相同，但對話紀錄為新）。

若您的 ACP 客戶端支援中繼資料，您可以針對個別會話進行覆寫：

```json
{
  "_meta": {
    "sessionKey": "agent:main:main",
    "sessionLabel": "support inbox",
    "resetSession": true
  }
}
```

更多會話金鑰資訊請參考 [/concepts/session](/zh-Hant/concepts/session)。

## 選項

- `--url <url>`：Gateway WebSocket URL（設定時預設使用 gateway.remote.url）。
- `--token <token>`：Gateway 認證 token。
- `--token-file <path>`：從檔案讀取 Gateway 認證 token。
- `--password <password>`：Gateway 認證密碼。
- `--password-file <path>`：從檔案讀取 Gateway 認證密碼。
- `--session <key>`：預設會話金鑰。
- `--session-label <label>`：預設解析的會話標籤。
- `--require-existing`：若會話金鑰/標籤不存在則失敗。
- `--reset-session`：首次使用前重設會話金鑰。
- `--no-prefix-cwd`：不要在提示前加上工作目錄路徑。
- `--verbose, -v`：將詳細日誌輸出至 stderr。

安全性注意事項：

- `--token` 和 `--password` 在某些系統上可能會在本地進程列表中可見。
- 建議優先使用 `--token-file`/`--password-file` 或環境變數（`OPENCLAW_GATEWAY_TOKEN`、`OPENCLAW_GATEWAY_PASSWORD`）。
- Gateway 認證解析遵循其他 Gateway 客戶端共用的規範：
  - 本地模式：env（`OPENCLAW_GATEWAY_*`）-> `gateway.auth.*` -> 當 `gateway.auth.*` 未設定時回退至 `gateway.remote.*`
  - 遠端模式：`gateway.remote.*` 按遠端優先規則進行 env/config 回退
  - `--url` 為覆寫安全項目，不會重複使用隱含的 config/env 憑證；請明確傳遞 `--token`/`--password`（或其檔案變體）
- ACP 執行時後端子進程會接收 `OPENCLAW_SHELL=acp`，可用於特定 shell/profile 規則。
- `openclaw acp client` 會在啟動的橋接器進程上設定 `OPENCLAW_SHELL=acp-client`。

### `acp client` 選項

- `--cwd <dir>`：ACP 會話的工作目錄。
- `--server <command>`：ACP 伺服器指令（預設：`openclaw`）。
- `--server-args <args...>`：傳遞給 ACP 伺服器的額外參數。
- `--server-verbose`：啟用 ACP 伺服器的詳細日誌。
- `--verbose, -v`：詳細的客戶端日誌。
