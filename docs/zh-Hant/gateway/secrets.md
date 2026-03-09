---
summary: "密鑰管理：SecretRef 規約、執行環境快照行為與安全的單向清理"
read_when:
  - 為供應商憑證和 `auth-profiles.json` refs 設定 SecretRef 時
  - 在生產環境中安全地操作密鑰重新載入、稽核、設定和套用時
  - 了解啟動 fail-fast、非活躍介面篩選與上次已知良好行為時
title: "Secrets Management（密鑰管理）"
---

# 密鑰管理

OpenClaw 支援附加式 SecretRef，讓支援的憑證無需以明文儲存在設定中。

明文仍然有效。SecretRef 是每個憑證的選用功能。

## 目標與執行環境模型

密鑰被解析到記憶體中的執行環境快照。

- 解析在啟動時急切進行，而非在請求路徑上延遲執行。
- 當有效活躍的 SecretRef 無法解析時，啟動會 fail-fast。
- 重新載入使用原子交換：完全成功，或保留上次已知良好的快照。
- 執行環境請求只從活躍的記憶體快照讀取。

這讓密鑰供應商中斷不影響熱請求路徑。

## 活躍介面篩選

SecretRef 只在有效活躍的介面上驗證。

- 啟用的介面：未解析的 refs 會封鎖啟動/重新載入。
- 非活躍介面：未解析的 refs 不封鎖啟動/重新載入。
- 非活躍 refs 以代碼 `SECRETS_REF_IGNORED_INACTIVE_SURFACE` 發出非致命性診斷。

非活躍介面範例：

- 停用的頻道/帳號項目。
- 沒有任何已啟用帳號繼承的頂層頻道憑證。
- 停用的工具/功能介面。
- 未被 `tools.web.search.provider` 選取的 web 搜尋供應商特定 keys。
  在自動模式（未設定供應商）下，供應商特定 keys 也對供應商自動偵測活躍。
- 當以下任一為真時，`gateway.remote.token` / `gateway.remote.password` SecretRef 是活躍的（當 `gateway.remote.enabled` 不為 `false` 時）：
  - `gateway.mode=remote`
  - 設定了 `gateway.remote.url`
  - `gateway.tailscale.mode` 為 `serve` 或 `funnel`
    在沒有這些遠端介面的本地模式中：
  - 當 token 認證可以勝出且未設定 env/auth token 時，`gateway.remote.token` 是活躍的。
  - 只有當 password 認證可以勝出且未設定 env/auth password 時，`gateway.remote.password` 才活躍。
- 當設定了 `OPENCLAW_GATEWAY_TOKEN`（或 `CLAWDBOT_GATEWAY_TOKEN`）時，`gateway.auth.token` SecretRef 在啟動認證解析中是非活躍的，因為 env token 輸入對該執行環境勝出。

## Gateway 認證介面診斷

當 SecretRef 設定在 `gateway.auth.token`、`gateway.auth.password`、
`gateway.remote.token` 或 `gateway.remote.password` 上時，gateway 啟動/重新載入會明確記錄介面狀態：

- `active`：SecretRef 是有效認證介面的一部分且必須解析。
- `inactive`：SecretRef 在此執行環境中被忽略，因為另一個認證介面勝出，或遠端認證已停用/未活躍。

這些項目以 `SECRETS_GATEWAY_AUTH_SURFACE` 記錄，並包含活躍介面政策使用的原因，讓您可以看到憑證被視為活躍或非活躍的原因。

## Onboarding 引用預檢

當 onboarding 以互動模式執行且您選擇 SecretRef 儲存時，OpenClaw 在儲存前執行預檢驗證：

- Env refs：驗證 env 變數名稱並確認在 onboarding 期間可見非空值。
- Provider refs（`file` 或 `exec`）：驗證供應商選擇、解析 `id` 並檢查解析值類型。
- Quickstart 重複使用路徑：當 `gateway.auth.token` 已是 SecretRef 時，onboarding 在 probe/dashboard bootstrap 前解析它（對 `env`、`file` 和 `exec` refs），使用相同的 fail-fast 閘道。

若驗證失敗，onboarding 顯示錯誤並讓您重試。

## SecretRef 規約

在任何地方使用一種物件格式：

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
- `id` 必須是絕對 JSON pointer（`/...`）
- 段落中的 RFC6901 跳脫：`~` => `~0`，`/` => `~1`

### `source: "exec"`

```json5
{ source: "exec", provider: "vault", id: "providers/openai/apiKey" }
```

驗證：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須符合 `^[A-Za-z0-9][A-Za-z0-9._:/-]{0,255}$`

## 供應商設定

在 `secrets.providers` 下定義供應商：

```json5
{
  secrets: {
    providers: {
      default: { source: "env" },
      filemain: {
        source: "file",
        path: "~/.openclaw/secrets.json",
        mode: "json", // 或 "singleValue"
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

### Env 供應商

- 透過 `allowlist` 的選用 allowlist。
- 遺失/空的 env 值會使解析失敗。

### File 供應商

- 從 `path` 讀取本地檔案。
- `mode: "json"` 預期 JSON 物件酬載並以 pointer 解析 `id`。
- `mode: "singleValue"` 預期 ref id `"value"` 並返回檔案內容。
- 路徑必須通過擁有者/權限檢查。
- Windows fail-closed 注意：若路徑的 ACL 驗證不可用，解析失敗。對於僅受信任的路徑，在該供應商上設定 `allowInsecurePath: true` 以繞過路徑安全檢查。

### Exec 供應商

- 執行設定的絕對二進位路徑，無 shell。
- 預設情況下，`command` 必須指向普通檔案（非符號連結）。
- 設定 `allowSymlinkCommand: true` 允許符號連結指令路徑（例如 Homebrew shims）。OpenClaw 驗證解析後的目標路徑。
- 將 `allowSymlinkCommand` 與 `trustedDirs` 配合使用，用於套件管理器路徑（例如 `["/opt/homebrew"]`）。
- 支援逾時、無輸出逾時、輸出位元組限制、env allowlist 和受信任目錄。
- Windows fail-closed 注意：若指令路徑的 ACL 驗證不可用，解析失敗。對於僅受信任的路徑，在該供應商上設定 `allowInsecurePath: true` 以繞過路徑安全檢查。

請求酬載（stdin）：

```json
{ "protocolVersion": 1, "provider": "vault", "ids": ["providers/openai/apiKey"] }
```

回應酬載（stdout）：

```jsonc
{ "protocolVersion": 1, "values": { "providers/openai/apiKey": "<openai-api-key>" } } // pragma: allowlist secret
```

選用的每個 id 錯誤：

```json
{
  "protocolVersion": 1,
  "values": {},
  "errors": { "providers/openai/apiKey": { "message": "not found" } }
}
```

## Exec 整合範例

### 1Password CLI

```json5
{
  secrets: {
    providers: {
      onepassword_openai: {
        source: "exec",
        command: "/opt/homebrew/bin/op",
        allowSymlinkCommand: true, // Homebrew 符號連結二進位必要
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
        allowSymlinkCommand: true, // Homebrew 符號連結二進位必要
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
        allowSymlinkCommand: true, // Homebrew 符號連結二進位必要
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

## 支援的憑證介面

規範的支援和不支援憑證列在：

- [SecretRef Credential Surface](/zh-Hant/reference/secretref-credential-surface)

執行環境鑄造或輪換的憑證以及 OAuth 刷新材料刻意排除在唯讀 SecretRef 解析之外。

## 必要行為與優先順序

- 沒有 ref 的欄位：不變。
- 有 ref 的欄位：在啟動時的活躍介面上為必要。
- 若明文和 ref 都存在，ref 在支援的優先順序路徑上優先。

警告和稽核訊號：

- `SECRETS_REF_OVERRIDES_PLAINTEXT`（執行環境警告）
- `REF_SHADOWED`（`auth-profiles.json` 憑證優先於 `openclaw.json` refs 時的稽核發現）

Google Chat 相容性行為：

- `serviceAccountRef` 優先於明文 `serviceAccount`。
- 設定了同級 ref 時忽略明文值。

## 啟動觸發器

密鑰啟動在以下時機執行：

- 啟動（預檢加上最終啟動）
- 設定重新載入熱套用路徑
- 設定重新載入重啟檢查路徑
- 透過 `secrets.reload` 手動重新載入

啟動規約：

- 成功時原子交換快照。
- 啟動失敗時中止 gateway 啟動。
- 執行環境重新載入失敗時保留上次已知良好的快照。

## 降級與恢復訊號

當重新載入時啟動在健康狀態後失敗，OpenClaw 進入密鑰降級狀態。

一次性系統事件和日誌代碼：

- `SECRETS_RELOADER_DEGRADED`
- `SECRETS_RELOADER_RECOVERED`

行為：

- 降級：執行環境保留上次已知良好的快照。
- 恢復：在下一次成功啟動後發出一次。
- 已降級時重複失敗記錄警告但不重複發送事件。
- 啟動 fail-fast 不發出降級事件，因為執行環境從未變為活躍。

## 指令路徑解析

指令路徑可以透過 gateway 快照 RPC 選用加入支援的 SecretRef 解析。

有兩種廣泛的行為：

- 嚴格指令路徑（例如 `openclaw memory` 遠端記憶體路徑和 `openclaw qr --remote`）從活躍快照讀取，當需要的 SecretRef 不可用時 fail-fast。
- 唯讀指令路徑（例如 `openclaw status`、`openclaw status --all`、`openclaw channels status`、`openclaw channels resolve` 和唯讀的 doctor/config 修復流程）也優先使用活躍快照，但在指令路徑中目標 SecretRef 不可用時降級而非中止。

唯讀行為：

- 當 gateway 執行中時，這些指令首先從活躍快照讀取。
- 若 gateway 解析不完整或 gateway 不可用，它們嘗試針對特定指令介面的目標本地 fallback。
- 若目標 SecretRef 仍不可用，指令繼續降級的唯讀輸出，並帶有明確的診斷，例如「在此指令路徑中已設定但不可用」。
- 此降級行為僅限於該指令的本地。它不會弱化執行環境啟動、重新載入或 send/auth 路徑。

其他注意事項：

- 後端密鑰輪換後的快照刷新由 `openclaw secrets reload` 處理。
- 這些指令路徑使用的 Gateway RPC 方法：`secrets.resolve`。

## 稽核與設定工作流程

預設的 operator 流程：

```bash
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets audit --check
```

### `secrets audit`

發現項目包括：

- 靜態明文值（`openclaw.json`、`auth-profiles.json`、`.env` 和生成的 `agents/*/agent/models.json`）
- 生成的 `models.json` 項目中的明文敏感供應商 header 殘留
- 未解析的 refs
- 優先順序遮蔽（`auth-profiles.json` 優先於 `openclaw.json` refs）
- 舊版殘留（`auth.json`、OAuth 提醒）

Header 殘留注意事項：

- 敏感供應商 header 偵測基於名稱啟發式（常見的 auth/憑證 header 名稱和片段，例如 `authorization`、`x-api-key`、`token`、`secret`、`password` 和 `credential`）。

### `secrets configure`

互動式輔助工具，可以：

- 首先設定 `secrets.providers`（`env`/`file`/`exec`，新增/編輯/移除）
- 讓您選取 `openclaw.json` 加上一個 agent 範圍的 `auth-profiles.json` 中支援的含密鑰欄位
- 可以直接在目標選擇器中建立新的 `auth-profiles.json` 對應
- 擷取 SecretRef 詳細資訊（`source`、`provider`、`id`）
- 執行預檢解析
- 可以立即套用

實用模式：

- `openclaw secrets configure --providers-only`
- `openclaw secrets configure --skip-provider-setup`
- `openclaw secrets configure --agent <id>`

`configure` 套用預設值：

- 清理 `auth-profiles.json` 中目標供應商的匹配靜態憑證
- 清理 `auth.json` 中舊版靜態 `api_key` 項目
- 清理 `<config-dir>/.env` 中匹配的已知密鑰行

### `secrets apply`

套用已儲存的計畫：

```bash
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
```

如需嚴格目標/路徑規約詳細資訊和確切拒絕規則，請參閱：

- [Secrets Apply Plan Contract](/zh-Hant/gateway/secrets-plan-contract)

## 單向安全政策

OpenClaw 刻意不寫入包含歷史明文密鑰值的回滾備份。

安全模型：

- 預檢必須在寫入模式前成功
- 執行環境啟動在提交前驗證
- apply 使用原子檔案替換更新檔案，失敗時盡力恢復

## 舊版認證相容性注意事項

對於靜態憑證，執行環境不再依賴明文的舊版認證儲存。

- 執行環境憑證來源是解析後的記憶體快照。
- 發現時清理舊版靜態 `api_key` 項目。
- OAuth 相關的相容性行為保持獨立。

## Web UI 注意事項

部分 SecretInput unions 在原始編輯器模式下比在表單模式下更容易設定。

## 相關文件

- CLI 指令：[secrets](/zh-Hant/cli/secrets)
- 計畫規約詳細資訊：[Secrets Apply Plan Contract](/zh-Hant/gateway/secrets-plan-contract)
- 憑證介面：[SecretRef Credential Surface](/zh-Hant/reference/secretref-credential-surface)
- 認證設定：[Authentication](/zh-Hant/gateway/authentication)
- 安全狀態：[Security](/zh-Hant/gateway/security)
- 環境變數優先順序：[Environment Variables](/zh-Hant/help/environment)
