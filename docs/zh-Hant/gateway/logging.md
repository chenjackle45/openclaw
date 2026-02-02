---
title: "日誌"
summary: "Logging surfaces, file logs, WS log styles, 與 console formatting"
read_when:
  - 變更 Log 輸出或格式時
  - 除錯 CLI 或 Gateway 輸出時
---

# 日誌 (Logging)

關於使用者面向的概觀 (CLI + Control UI + Config)，參閱 [/logging](/logging)。

OpenClaw 有兩個 Log “Surfaces”：

- **Console output** (您在終端機 / Debug UI 看到的)。
- **File logs** (JSON lines) 由 Gateway Logger 寫入。

## File-based Logger

- 預設滾動日誌檔位於 `/tmp/openclaw/` 下 (每天一個檔案)：`openclaw-YYYY-MM-DD.log`
  - 日期使用 Gateway Host 的本地時區。
- Log 檔案路徑與等級可透過 `~/.openclaw/openclaw.json` 設定：
  - `logging.file`
  - `logging.level`

檔案格式為每行一個 JSON 物件。

Control UI 的 Logs 分頁透過 Gateway (`logs.tail`) 追蹤此檔案。CLI 也可以做同樣的事：

```bash
openclaw logs --follow
```

**Verbose vs. Log Levels**

- **File logs** 僅由 `logging.level` 控制。
- `--verbose` 僅影響 **Console verbosity** (以及 WS log style)；它 **不會** 同步提高 File Log Level。
- 要在 File Logs 中擷取 verbose-only 細節，將 `logging.level` 設定為 `debug` 或 `trace`。

## Console Capture

CLI 擷取 `console.log/info/warn/error/debug/trace` 並將它們寫入 File Logs，同時仍輸出至 stdout/stderr。

您可以獨立調整 Console Verbosity：

- `logging.consoleLevel` (預設 `info`)
- `logging.consoleStyle` (`pretty` | `compact` | `json`)

## Tool Summary Redaction (工具摘要遮蔽)

詳細的 Tool Summaries (例如 `🛠️ Exec: ...`) 可以在輸出至 Console Stream 之前遮蔽機密 Tokens。這是 **Tools-only** 且不會變更 File Logs。

- `logging.redactSensitive`: `off` | `tools` (預設: `tools`)
- `logging.redactPatterns`: Regex 字串陣列 (覆蓋預設值)
  - 使用原始 Regex 字串 (自動 `gi`)，或若需自訂 Flags 則使用 `/pattern/flags`。
  - 相符項目透過保留前 6 + 後 4 字元 (長度 >= 18) 進行遮蔽，否則為 `***`。
  - 預設值涵蓋常見的 Key Assignments, CLI Flags, JSON Fields, Bearer Headers, PEM Blocks, 以及熱門 Token 前綴。

## Gateway WebSocket Logs

Gateway 以兩種模式印出 WebSocket 協定日誌：

- **Normal mode (無 `--verbose`)**: 僅印出“有趣”的 RPC 結果：
  - 錯誤 (`ok=false`)
  - 慢速呼叫 (預設門檻: `>= 50ms`)
  - 解析錯誤
- **Verbose mode (`--verbose`)**: 印出所有 WS 請求/回應流量。

### WS Log Style

`openclaw gateway` 支援 Per-gateway 的樣式切換：

- `--ws-log auto` (預設): Normal Mode 最佳化；Verbose Mode 使用 Compact Output
- `--ws-log compact`: Verbose 時使用 Compact Output (成對的 Request/Response)
- `--ws-log full`: Verbose 時使用 Full Per-frame Output
- `--compact`: `--ws-log compact` 的別名

範例:

```bash
# 最佳化 (僅錯誤/慢速)
openclaw gateway

# 顯示所有 WS 流量 (成對)
openclaw gateway --verbose --ws-log compact

# 顯示所有 WS 流量 (完整 Meta)
openclaw gateway --verbose --ws-log full
```

## Console Formatting (Subsystem Logging)

Console Formatter 具 **TTY 感知能力 (TTY-aware)** 並印出一致、帶前綴的行。Subsystem Loggers 讓輸出保持分組且可掃描。

行為:

- 每行皆有 **Subsystem prefixes** (例如 `[gateway]`, `[canvas]`, `[tailscale]`)
- **Subsystem colors** (每個 Subsystem 穩定) 加上 Level Coloring
- **當輸出是 TTY 或環境看起來像 Rich Terminal 時上色** (`TERM`/`COLORTERM`/`TERM_PROGRAM`)，尊重 `NO_COLOR`
- **縮短 Subsystem prefixes**: 丟棄開頭的 `gateway/` + `channels/`，保留最後 2 個區段 (例如 `whatsapp/outbound`)
- **Sub-loggers by subsystem** (自動 Prefix + Structured Field `{ subsystem }`)
- **`logRaw()`** 用於 QR/UX 輸出 (無 Prefix，無 Formatting)
- **Console styles** (例如 `pretty | compact | json`)
- **Console log level** 獨立於 File Log Level (當 `logging.level` 設定為 `debug`/`trace` 時 File 保持完整細節)
- **WhatsApp message bodies** 在 `debug` 等級記錄 (使用 `--verbose` 查看)

這讓既有的 File Logs 保持穩定，同時讓互動式輸出易於掃描。
