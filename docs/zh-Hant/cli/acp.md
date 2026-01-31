---
title: "acp(Agent 控制協定)"
summary: "執行用於 IDE 整合的 ACP 橋接器"
read_when:
  - 正在設定基於 ACP 的 IDE 整合時
  - 正在偵錯 ACP 會話至 Gateway 的路由問題時
---

# `openclaw acp`

執行 ACP (Agent Client Protocol) 橋接器以與 OpenClaw Gateway 進行通訊。

此指令會透過標準輸入輸出 (stdio) 與 IDE 進行 ACP 通訊，並透過 WebSocket 將提示轉發至 Gateway。它負責將 ACP 會話映射至 Gateway 的會話金鑰。

## 使用範例

```bash
# 執行 ACP 橋接器
openclaw acp

# 連接至遠端 Gateway
openclaw acp --url wss://gateway-host:18789 --token <權杖>

# 附加至既存的會話金鑰
openclaw acp --session agent:main:main

# 透過標籤附加（該標籤必須已存在）
openclaw acp --session-label "support inbox"

# 在首次提示前重設會話金鑰
openclaw acp --session agent:main:main --reset-session
```

## ACP 客戶端 (偵錯用)

使用內建的 ACP 客戶端在不依賴 IDE 的情況下檢查橋接器是否正常。
它會啟動 ACP 橋接器並允許您互動式地輸入提示。

```bash
openclaw acp client

# 指向遠端 Gateway
openclaw acp client --server-args --url wss://gateway-host:18789 --token <權杖>

# 覆寫伺服器指令（預設：openclaw）
openclaw acp client --server "node" --server-args openclaw.mjs acp --url ws://127.0.0.1:19001
```

## 使用情境

當 IDE（或其他客戶端）支援 Agent Client Protocol 且您希望由它來驅動 OpenClaw Gateway 會話時，請使用 ACP。

1. 確保 Gateway 正在運行（本地或遠端）。
2. 配置 Gateway 目標（透過 config 或旗標）。
3.這定您的 IDE 透過 stdio 執行 `openclaw acp`。

配置範例（持久化）：

```bash
openclaw config set gateway.remote.url wss://gateway-host:18789
openclaw config set gateway.remote.token <權杖>
```

直接執行範例（不寫入配置）：

```bash
openclaw acp --url wss://gateway-host:18789 --token <權杖>
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

## Zed 編輯器設定

在 `~/.config/zed/settings.json` 中新增自定義 ACP Agent（或使用 Zed 的設定介面）：

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
        "--url", "wss://gateway-host:18789",
        "--token", "<權杖>",
        "--session", "agent:design:main"
      ],
      "env": {}
    }
  }
}
```

在 Zed 中，開啟 Agent 面板並選擇「OpenClaw ACP」即可開始對話。

## 會話映射 (Session mapping)

預設情況下，ACP 會話會獲得一個帶有 `acp:` 前綴的獨立 Gateway 會話金鑰。
若要重複使用已知的會話，請傳遞會話金鑰或標籤：

- `--session <key>`：使用特定的 Gateway 會話金鑰。
- `--session-label <label>`：透過標籤解析現有會話。
- `--reset-session`：為該金鑰產生一個全新的會話 ID（金鑰相同，但對話紀錄為新）。

若您的 ACP 客戶端支援中繼資料 (metadata)，您可以針對個別會話進行覆寫：

```json
{
  "_meta": {
    "sessionKey": "agent:main:main",
    "sessionLabel": "support inbox",
    "resetSession": true
  }
}
```

更多會話金鑰資訊請參考 [/concepts/session](/concepts/session)。

## 參數選項

- `--url <url>`：Gateway WebSocket URL（預設使用配置中的 gateway.remote.url）。
- `--token <token>`：Gateway 認證權杖。
- `--password <password>`：Gateway 認證密碼。
- `--session <key>`：預設會話金鑰。
- `--session-label <label>`：預設解析的會話標籤。
- `--require-existing`：若會話金鑰/標籤不存在則失敗。
- `--reset-session`：首次使用前重設會話金鑰。
- `--no-prefix-cwd`：不要在提示前加上工作目錄路徑。
- `--verbose, -v`：將詳細日誌輸出至 stderr。

### `acp client` 選項

- `--cwd <dir>`：ACP 會話的工作目錄。
- `--server <command>`：ACP 伺服器指令（預設：`openclaw`）。
- `--server-args <args...>`：傳遞給 ACP 伺服器的額外參數。
- `--server-verbose`：啟用 ACP 伺服器的詳細日誌。
- `--verbose, -v`：詳細的客戶端日誌。
