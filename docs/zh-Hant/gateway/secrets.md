---
summary: "密鑰管理：SecretRef 合約、運行時快照行為，以及安全的單向清理"
read_when:
  - 為提供商憑證和 `auth-profiles.json` refs 配置 SecretRef
  - 在生產環境中安全地操作密鑰重新加載、稽核、設定和應用
  - 瞭解啟動快速失敗、非活躍表面篩選和上次已知良好行為
title: "Secrets Management（密鑰管理）"
---

# 密鑰管理

OpenClaw 支援附加式 SecretRef，使受支援的認證不需要以純文本方式存儲在設定中。

純文本仍然可用。SecretRef 是按憑證可選的。

## 目標和運行時模型

密鑰被解析為記憶體中的運行時快照。

- 解析在啟用期間是主動的，而不是在請求路徑上懶加載。
- 當有效的活躍 SecretRef 無法解析時，啟動會快速失敗。
- 重新加載使用原子交換：完全成功或保持上次已知良好的快照。
- 運行時請求僅從活躍的記憶體中快照讀取。

這保持密鑰提供商中斷遠離熱請求路徑。

## 活躍表面篩選

SecretRef 僅在有效的活躍表面上驗證。

- 啟用的表面：未解析的 ref 阻止啟動/重新加載。
- 非活躍表面：未解析的 ref 不會阻止啟動/重新加載。
- 非活躍 ref 發出代碼為 `SECRETS_REF_IGNORED_INACTIVE_SURFACE` 的非致命診斷。

非活躍表面的例子：

- 禁用的頻道/帳戶項目。
- 沒有啟用帳戶繼承的頂級頻道認證。
- 禁用的工具/功能表面。
- 未由 `tools.web.search.provider` 選擇的網路搜尋提供商特定金鑰。
  在自動模式（提供商未設定）下，提供商特定金鑰也對提供商自動偵測活躍。
- `gateway.remote.token` / `gateway.remote.password` SecretRef 在以下情況下活躍（當 `gateway.remote.enabled` 不是 `false` 時）：
  - `gateway.mode=remote`
  - `gateway.remote.url` 已配置
  - `gateway.tailscale.mode` 是 `serve` 或 `funnel`
    在沒有這些遠端表面的本地模式下：
  - `gateway.remote.token` 在令牌認證可以獲勝且未配置 env/auth 令牌時活躍。
  - `gateway.remote.password` 僅在密碼認證可以獲勝且未配置 env/auth 密碼時活躍。

## 網關認證表面診斷

在 `gateway.auth.password`、`gateway.remote.token` 或 `gateway.remote.password` 上配置 SecretRef 時，網關啟動/重新加載會明確記錄表面狀態：

- `active`：SecretRef 是有效認證表面的一部分，必須解析。
- `inactive`：因為另一個認證表面獲勝或遠端認證禁用/不活躍，此運行時忽略 SecretRef。

這些項目用 `SECRETS_GATEWAY_AUTH_SURFACE` 記錄，並包含活躍表面原則使用的原因，所以你可以看到為什麼認證被視為活躍或非活躍。

## 入職參考預檢

當入職以互動模式運行且你選擇 SecretRef 儲存時，OpenClaw 在保存前運行預檢驗證：

- Env refs：驗證 env 變數名稱並確認在入職期間可見非空值。
- 提供商 refs（`file` 或 `exec`）：驗證提供商選擇、解析 `id` 並檢查解析值類型。

如果驗證失敗，入職會顯示錯誤並讓你重試。

## SecretRef 合約

在任何地方使用一個物件形狀：

```json5
{ source: "env" | "file" | "exec", provider: "default", id: "..." }
```

### `source: "env"`

```json5
{ source: "env", provider: "default", id: "OPENAI_API_KEY" }
```

驗證：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須符合 `^[A-Z][A-Z0-9_]{0,127}$`

### `source: "file"`

```json5
{ source: "file", provider: "filemain", id: "/providers/openai/apiKey" }
```

驗證：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須是絕對 JSON 指針（`/...`）
- RFC6901 段轉義：`~` => `~0`，`/` => `~1`

### `source: "exec"`

```json5
{ source: "exec", provider: "vault", id: "providers/openai/apiKey" }
```

驗證：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須符合 `^[A-Za-z0-9][A-Za-z0-9._:/-]{0,255}$`

## 提供商配置

在 `secrets.providers` 下定義提供商：

```json5
{
  secrets: {
    providers: {
      default: { source: "env" },
      filemain: {
        source: "file",
        path: "~/.openclaw/secrets.json",
        mode: "json", // or "singleValue"
      },
      vault: {
        source: "exec",
        command: "/usr/local/bin/openclaw-vault-resolver",
        args: ["--profile", "prod"],
        passEnv: ["PATH", "VAULT_ADDR"],
        jsonOnly: true,
      },
    },
    defaults: {
      env: "default",
      file: "filemain",
      exec: "vault",
    },
    resolution: {
      maxProviderConcurrency: 4,
      maxRefsPerProvider: 512,
      maxBatchBytes: 262144,
    },
  },
}
```

### Env 提供商

- 通過 `allowlist` 選擇性許可清單。
- 缺少/空的 env 值導致解析失敗。

### 檔案提供商

- 從 `path` 讀取本地檔案。
- `mode: "json"` 期望 JSON 物件負載並將 `id` 解析為指針。
- `mode: "singleValue"` 期望 ref id `"value"` 並返回檔案內容。
- 路徑必須通過所有權/權限檢查。
- Windows 失敗關閉注意：如果路徑的 ACL 驗證不可用，解析失敗。僅對信任的路徑，在該提供商上設定 `allowInsecurePath: true` 以繞過路徑安全檢查。

### Exec 提供商

- 執行配置的絕對二進制路徑，不使用 shell。
- 預設情況下，`command` 必須指向常規檔案（不是符號連結）。
- 設定 `allowSymlinkCommand: true` 以允許符號連結命令路徑（例如 Homebrew shims）。OpenClaw 驗證解析的目標路徑。
- 將 `allowSymlinkCommand` 與 `trustedDirs` 配對用於套件管理器路徑（例如 `["/opt/homebrew"]`）。
- 支援超時、無輸出超時、輸出位元組限制、env 許可清單和信任的目錄。
- Windows 失敗關閉注意：如果命令路徑的 ACL 驗證不可用，解析失敗。僅對信任的路徑，在該提供商上設定 `allowInsecurePath: true` 以繞過路徑安全檢查。

請求負載（stdin）：

```json
{ "protocolVersion": 1, "provider": "vault", "ids": ["providers/openai/apiKey"] }
```

回應負載（stdout）：

```json
{ "protocolVersion": 1, "values": { "providers/openai/apiKey": "sk-..." } }
```

選擇性每個 id 錯誤：

```json
{
  "protocolVersion": 1,
  "values": {},
  "errors": { "providers/openai/apiKey": { "message": "not found" } }
}
```

## Exec 整合示例

### 1Password CLI

```json5
{
  secrets: {
    providers: {
      onepassword_openai: {
        source: "exec",
        command: "/opt/homebrew/bin/op",
        allowSymlinkCommand: true, // required for Homebrew symlinked binaries
        trustedDirs: ["/opt/homebrew"],
        args: ["read", "op://Personal/OpenClaw QA API Key/password"],
        passEnv: ["HOME"],
        jsonOnly: false,
      },
    },
  },
  models: {
    providers: {
      openai: {
        baseUrl: "https://api.openai.com/v1",
        models: [{ id: "gpt-5", name: "gpt-5" }],
        apiKey: { source: "exec", provider: "onepassword_openai", id: "value" },
      },
    },
  },
}
```

### HashiCorp Vault CLI

```json5
{
  secrets: {
    providers: {
      vault_openai: {
        source: "exec",
        command: "/opt/homebrew/bin/vault",
        allowSymlinkCommand: true, // required for Homebrew symlinked binaries
        trustedDirs: ["/opt/homebrew"],
        args: ["kv", "get", "-field=OPENAI_API_KEY", "secret/openclaw"],
        passEnv: ["VAULT_ADDR", "VAULT_TOKEN"],
        jsonOnly: false,
      },
    },
  },
  models: {
    providers: {
      openai: {
        baseUrl: "https://api.openai.com/v1",
        models: [{ id: "gpt-5", name: "gpt-5" }],
        apiKey: { source: "exec", provider: "vault_openai", id: "value" },
      },
    },
  },
}
```

### `sops`

```json5
{
  secrets: {
    providers: {
      sops_openai: {
        source: "exec",
        command: "/opt/homebrew/bin/sops",
        allowSymlinkCommand: true, // required for Homebrew symlinked binaries
        trustedDirs: ["/opt/homebrew"],
        args: ["-d", "--extract", '["providers"]["openai"]["apiKey"]', "/path/to/secrets.enc.json"],
        passEnv: ["SOPS_AGE_KEY_FILE"],
        jsonOnly: false,
      },
    },
  },
  models: {
    providers: {
      openai: {
        baseUrl: "https://api.openai.com/v1",
        models: [{ id: "gpt-5", name: "gpt-5" }],
        apiKey: { source: "exec", provider: "sops_openai", id: "value" },
      },
    },
  },
}
```

## 支援的認證表面

規範的支援和不支援的認證列在：

- [SecretRef 認證表面](/zh-Hant/reference/secretref-credential-surface)

運行時鑄造或輪轉認證和 OAuth 刷新材料有意從唯讀 SecretRef 解析中排除。

## 必需行為和優先級

- 沒有 ref 的欄位：未更改。
- 有 ref 的欄位：在啟用期間在活躍表面上是必需的。
- 如果純文本和 ref 同時存在，ref 在支援的優先級路徑上優先。

警告和稽核信號：

- `SECRETS_REF_OVERRIDES_PLAINTEXT`（運行時警告）
- `REF_SHADOWED`（當 `auth-profiles.json` 認證優先於 `openclaw.json` ref 時的稽核發現）

Google Chat 相容性行為：

- `serviceAccountRef` 優先於純文本 `serviceAccount`。
- 設定同級 ref 時，純文本值被忽略。

## 啟用觸發器

密鑰啟用在以下情況下執行：

- 啟動（預檢加最終啟用）
- 配置重新加載熱應用路徑
- 配置重新加載重啟檢查路徑
- 通過 `secrets.reload` 手動重新加載

啟用合約：

- 成功原子交換快照。
- 啟動失敗中止網關啟動。
- 運行時重新加載失敗保持上次已知良好的快照。

## 降級和恢復信號

當重新加載時啟用在健康狀態後失敗時，OpenClaw 進入降級密鑰狀態。

一次性系統事件和記錄代碼：

- `SECRETS_RELOADER_DEGRADED`
- `SECRETS_RELOADER_RECOVERED`

行為：

- 降級：運行時保持上次已知良好的快照。
- 恢復：在下一次成功啟用後發出一次。
- 在已降級時重複失敗記錄警告但不傳送事件。
- 啟動快速失敗不發出降級事件，因為運行時未變成活躍。

## 命令路徑解析

選擇加入的認證敏感命令路徑（例如 `openclaw memory` 遠端記憶體路徑和 `openclaw qr --remote`）可以通過網關快照 RPC 解析支援的 SecretRef。

- 當網關執行時，那些命令路徑從活躍快照讀取。
- 如果配置的 SecretRef 是必需的且網關不可用，命令解析會快速失敗並提供可操作的診斷。
- 後端密鑰輪轉後的快照刷新由 `openclaw secrets reload` 處理。
- 這些命令路徑使用的網關 RPC 方法：`secrets.resolve`。

## 稽核和配置工作流

預設操作員流程：

```bash
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets audit --check
```

### `secrets audit`

發現包括：

- 靜止時的純文本值（`openclaw.json`、`auth-profiles.json`、`.env`）
- 未解析的 ref
- 優先級遮蔽（`auth-profiles.json` 優先於 `openclaw.json` ref）
- 舊式殘留（`auth.json`、OAuth 提醒）

### `secrets configure`

互動式輔助工具，可以：

- 首先配置 `secrets.providers`（`env`/`file`/`exec`、新增/編輯/移除）
- 讓你為一個代理範圍選擇 `openclaw.json` 加上 `auth-profiles.json` 中支援的密鑰軸承欄位
- 可以直接在目標選擇器中建立新的 `auth-profiles.json` 映射
- 捕捉 SecretRef 詳細資訊（`source`、`provider`、`id`）
- 執行預檢解析
- 可以立即應用

有用的模式：

- `openclaw secrets configure --providers-only`
- `openclaw secrets configure --skip-provider-setup`
- `openclaw secrets configure --agent <id>`

`configure` 應用預設值：

- 從 `auth-profiles.json` 清除目標提供商的匹配靜態認證
- 從 `auth.json` 清除舊式靜態 `api_key` 項目
- 從 `<config-dir>/.env` 清除匹配的已知密鑰行

### `secrets apply`

應用已保存的計畫：

```bash
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
```

有關嚴格的目標/路徑合約詳細資訊和確切的拒絕規則，請參閱：

- [密鑰應用計畫合約](/zh-Hant/gateway/secrets-plan-contract)

## 單向安全原則

OpenClaw 有意不寫入包含歷史純文本密鑰值的回滾備份。

安全模型：

- 預檢必須在寫入模式前成功
- 運行時啟用在提交前驗證
- 應用使用原子檔案替換和最盡力恢復失敗時更新檔案

## 舊式認證相容性注意事項

對於靜態認證，運行時不再依賴純文本舊式認證儲存。

- 運行時認證來源是解析的記憶體中快照。
- 舊式靜態 `api_key` 項目在發現時被清除。
- OAuth 相關的相容性行為保持分開。

## Web UI 注意

某些 SecretInput 聯合在原始編輯器模式下比在表單模式下更容易配置。

## 相關文件

- CLI 命令：[secrets](/zh-Hant/cli/secrets)
- 計畫合約詳細資訊：[密鑰應用計畫合約](/zh-Hant/gateway/secrets-plan-contract)
- 認證表面：[SecretRef 認證表面](/zh-Hant/reference/secretref-credential-surface)
- 認證設定：[認證](/zh-Hant/gateway/authentication)
- 安全狀態：[安全](/zh-Hant/gateway/security)
- 環境優先級：[環境變數](/zh-Hant/help/environment)
