---
title: "Flags(診斷標誌)"
summary: "用於針對性除錯日誌的診斷標誌"
read_when:
  - 您需要針對性的除錯日誌而不提高全域日誌層級
  - 您需要捕獲特定子系統的日誌以供支援
---
# Diagnostics Flags(診斷標誌)

診斷標誌讓您能夠啟用針對性的除錯日誌，而無需在所有地方開啟詳細日誌記錄。標誌是選用的，除非子系統檢查它們，否則不會有任何效果。

## 運作方式

- 標誌是字串（不區分大小寫）。
- 您可以在設定中啟用標誌或透過環境變數覆蓋。
- 支援萬用字元：
  - `telegram.*` 符合 `telegram.http`
  - `*` 啟用所有標誌

## 透過設定啟用

```json
{
  "diagnostics": {
    "flags": ["telegram.http"]
  }
}
```

多個標誌：

```json
{
  "diagnostics": {
    "flags": ["telegram.http", "gateway.*"]
  }
}
```

變更標誌後重新啟動 gateway。

## 環境變數覆蓋（一次性）

```bash
OPENCLAW_DIAGNOSTICS=telegram.http,telegram.payload
```

停用所有標誌：

```bash
OPENCLAW_DIAGNOSTICS=0
```

## 日誌去向

標誌將日誌發送到標準診斷日誌檔案。預設為：

```
/tmp/openclaw/openclaw-YYYY-MM-DD.log
```

如果您設定了 `logging.file`，請使用該路徑。日誌為 JSONL 格式（每行一個 JSON 物件）。根據 `logging.redactSensitive` 仍會套用脫敏處理。

## 提取日誌

選擇最新的日誌檔案：

```bash
ls -t /tmp/openclaw/openclaw-*.log | head -n 1
```

篩選 Telegram HTTP 診斷：

```bash
rg "telegram http error" /tmp/openclaw/openclaw-*.log
```

或在重現時追蹤：

```bash
tail -f /tmp/openclaw/openclaw-$(date +%F).log | rg "telegram http error"
```

對於遠端 gateways，您也可以使用 `openclaw logs --follow`（請參閱 [/cli/logs](/cli/logs)）。

## 注意事項

- 如果 `logging.level` 設定高於 `warn`，這些日誌可能會被抑制。預設的 `info` 沒問題。
- 標誌保持啟用是安全的；它們只會影響特定子系統的日誌量。
- 使用 [/logging](/logging) 來變更日誌目的地、層級和脫敏處理。
