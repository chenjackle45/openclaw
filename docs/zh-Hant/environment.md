---
summary: "OpenClaw 載入環境變數的位置及優先順序"
read_when:
  - 需要了解哪些環境變數被載入及順序時
  - 正在偵錯 Gateway 中遺失的 API key 時
  - 正在記錄提供者認證或部署環境時
title: "Environment Variables（環境變數）"
---

# 環境變數

OpenClaw 從多個來源提取環境變數。規則是**永不覆蓋現有值**。

## 優先順序（高 → 低）

1. **程序環境**（Gateway 程序已從父 shell/daemon 取得的內容）。
2. **目前工作目錄中的 `.env`**（dotenv 預設；不覆蓋）。
3. **全域 `.env`** 位於 `~/.openclaw/.env`（即 `$OPENCLAW_STATE_DIR/.env`；不覆蓋）。
4. **設定 `env` 區塊**位於 `~/.openclaw/openclaw.json`（僅在缺少時套用）。
5. **選用的登入 shell 匯入**（`env.shellEnv.enabled` 或 `OPENCLAW_LOAD_SHELL_ENV=1`），僅對缺少的預期金鑰套用。

如果設定檔完全遺失，步驟 4 會被跳過；如果啟用，shell 匯入仍然執行。

## 設定 `env` 區塊

兩種等效的設定內嵌環境變數方式（均不覆蓋）：

```json5
{
  env: {
    OPENROUTER_API_KEY: "sk-or-...",
    vars: {
      GROQ_API_KEY: "gsk-...",
    },
  },
}
```

## Shell env 匯入

`env.shellEnv` 執行您的登入 shell 並僅匯入**缺少的**預期金鑰：

```json5
{
  env: {
    shellEnv: {
      enabled: true,
      timeoutMs: 15000,
    },
  },
}
```

等效的環境變數：

- `OPENCLAW_LOAD_SHELL_ENV=1`
- `OPENCLAW_SHELL_ENV_TIMEOUT_MS=15000`

## 執行階段注入的環境變數

OpenClaw 也會將上下文標記注入衍生的子程序：

- `OPENCLAW_SHELL=exec`：為透過 `exec` 工具執行的命令設定。
- `OPENCLAW_SHELL=acp`：為 ACP 執行階段後端程序衍生（例如 `acpx`）設定。
- `OPENCLAW_SHELL=acp-client`：在 `openclaw acp client` 衍生 ACP bridge 程序時設定。
- `OPENCLAW_SHELL=tui-local`：為本地 TUI `!` shell 命令設定。

這些是執行階段標記（不需要使用者設定）。可在 shell/設定檔邏輯中用於套用特定情境的規則。

## UI 環境變數

- `OPENCLAW_THEME=light`：當您的終端機有淺色背景時，強制使用淺色 TUI 調色盤。
- `OPENCLAW_THEME=dark`：強制使用深色 TUI 調色盤。
- `COLORFGBG`：如果您的終端機匯出它，OpenClaw 使用背景顏色提示自動選擇 TUI 調色盤。

## 設定中的環境變數替換

您可以在設定字串值中使用 `${VAR_NAME}` 語法直接引用環境變數：

```json5
{
  models: {
    providers: {
      "vercel-gateway": {
        apiKey: "${VERCEL_GATEWAY_API_KEY}",
      },
    },
  },
}
```

詳見[設定：環境變數替換](/zh-Hant/gateway/configuration#env-var-substitution-in-config)。

## Secret refs vs `${ENV}` 字串

OpenClaw 支援兩種 env 驅動的模式：

- 設定值中的 `${VAR}` 字串替換。
- SecretRef 物件（`{ source: "env", provider: "default", id: "VAR" }`），用於支援 secrets references 的欄位。

兩者都在啟動時從程序 env 解析。SecretRef 詳情記錄在[Secrets 管理](/zh-Hant/gateway/secrets)中。

## 路徑相關環境變數

| 變數                   | 用途                                                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `OPENCLAW_HOME`        | 覆蓋所有內部路徑解析使用的主目錄（`~/.openclaw/`、agent 目錄、會話、憑證）。在以專用服務使用者身分執行 OpenClaw 時很有用。 |
| `OPENCLAW_STATE_DIR`   | 覆蓋狀態目錄（預設 `~/.openclaw`）。                                                                                       |
| `OPENCLAW_CONFIG_PATH` | 覆蓋設定檔路徑（預設 `~/.openclaw/openclaw.json`）。                                                                       |

## 日誌記錄

| 變數                 | 用途                                                                                                                                    |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `OPENCLAW_LOG_LEVEL` | 覆蓋檔案和主控台的日誌層級（例如 `debug`、`trace`）。優先於設定中的 `logging.level` 和 `logging.consoleLevel`。無效值被忽略並發出警告。 |

### `OPENCLAW_HOME`

設定後，`OPENCLAW_HOME` 取代所有內部路徑解析的系統主目錄（`$HOME` / `os.homedir()`）。這使無頭服務帳號能夠完全隔離檔案系統。

**優先順序：**`OPENCLAW_HOME` > `$HOME` > `USERPROFILE` > `os.homedir()`

**範例**（macOS LaunchDaemon）：

```xml
<key>EnvironmentVariables</key>
<dict>
  <key>OPENCLAW_HOME</key>
  <string>/Users/kira</string>
</dict>
```

`OPENCLAW_HOME` 也可以設定為波浪號路徑（例如 `~/svc`），在使用前使用 `$HOME` 展開。

## 相關

- [Gateway 設定](/zh-Hant/gateway/configuration)
- [FAQ：環境變數和 .env 載入](/zh-Hant/help/faq#env-vars-and-env-loading)
- [模型概覽](/zh-Hant/concepts/models)
