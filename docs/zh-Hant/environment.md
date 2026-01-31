---
title: "Environment(環境變數)"
summary: "OpenClaw 載入環境變數的位置與優先順序"
read_when:
  - 您需要知道哪些環境變數被載入，以及順序為何
  - 您正在除錯 Gateway 中缺少的 API 金鑰
  - 您正在記錄供應商認證或部署環境
---
# Environment variables(環境變數)

OpenClaw 從多個來源提取環境變數。規則是**永遠不覆蓋現有值**。

## 優先順序（高 → 低）

1) **程序環境**（Gateway 程序已從父 shell/daemon 獲得的內容）。
2) **當前工作目錄中的 `.env`**（dotenv 預設；不覆蓋）。
3) **全域 `.env`** 位於 `~/.openclaw/.env`（即 `$OPENCLAW_STATE_DIR/.env`；不覆蓋）。
4) **設定 `env` 區塊** 在 `~/.openclaw/openclaw.json` 中（僅在缺少時套用）。
5) **選用的登入 shell 匯入**（`env.shellEnv.enabled` 或 `OPENCLAW_LOAD_SHELL_ENV=1`），僅對缺少的預期金鑰套用。

如果設定檔完全缺少，則跳過步驟 4；如果已啟用，shell 匯入仍會執行。

## 設定 `env` 區塊

兩種等效的方式來設定行內環境變數（兩者都不覆蓋）：

```json5
{
  env: {
    OPENROUTER_API_KEY: "sk-or-...",
    vars: {
      GROQ_API_KEY: "gsk-..."
    }
  }
}
```

## Shell env 匯入

`env.shellEnv` 執行您的登入 shell 並僅匯入**缺少**的預期金鑰：

```json5
{
  env: {
    shellEnv: {
      enabled: true,
      timeoutMs: 15000
    }
  }
}
```

環境變數等效項：
- `OPENCLAW_LOAD_SHELL_ENV=1`
- `OPENCLAW_SHELL_ENV_TIMEOUT_MS=15000`

## 設定中的環境變數替換

您可以使用 `${VAR_NAME}` 語法在設定字串值中直接引用環境變數：

```json5
{
  models: {
    providers: {
      "vercel-gateway": {
        apiKey: "${VERCEL_GATEWAY_API_KEY}"
      }
    }
  }
}
```

請參閱 [Configuration: Env var substitution](/gateway/configuration#env-var-substitution-in-config) 以取得完整詳情。

## 相關

- [Gateway 設定](/gateway/configuration)
- [FAQ: env vars and .env loading](/help/faq#env-vars-and-env-loading)
- [Models 概覽](/concepts/models)
