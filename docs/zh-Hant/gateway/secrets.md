---
summary: "機密管理：SecretRef 合約、執行期快照行為，以及安全的單向清除機制"
read_when:
  - 為 Provider 憑證及 `auth-profiles.json` 引用設定 SecretRef
  - 在正式環境中安全地執行機密重新載入、稽核、設定及套用操作
  - 了解啟動快速失敗、非活躍介面過濾，以及最後已知良好行為
title: "Secrets Management（機密管理）"
---

# 機密管理

OpenClaw 支援可加性 SecretRef，使受支援的憑證無需以明文形式儲存於設定中。

明文仍可使用。SecretRef 對每個憑證而言是選擇性啟用的。

## 目標與執行期模型

機密會被解析為記憶體中的執行期快照。

- 解析在啟用期間是急切（eager）的，而非在請求路徑上懶惰（lazy）執行。
- 當有效活躍的 SecretRef 無法解析時，啟動會快速失敗。
- 重新載入使用原子性交換：完全成功，否則保留最後已知良好的快照。
- 執行期請求僅從活躍的記憶體快照讀取。
- 對外傳送路徑（例如 Discord 回覆/執行緒傳送以及 Telegram 動作發送）也從活躍快照讀取，不會在每次傳送時重新解析 SecretRef。

這使機密 Provider 的中斷不會影響熱路徑請求。

## 活躍介面過濾

SecretRef 僅在有效活躍的介面上進行驗證。

- 已啟用介面：未解析的引用會阻擋啟動/重新載入。
- 非活躍介面：未解析的引用不會阻擋啟動/重新載入。
- 非活躍引用會以 `SECRETS_REF_IGNORED_INACTIVE_SURFACE` 代碼發出非致命性診斷訊息。

非活躍介面範例：

- 已停用的 Channel/帳號條目。
- 沒有任何已啟用帳號繼承的頂層 Channel 憑證。
- 已停用的工具/功能介面。
- 未被 `tools.web.search.provider` 選取的網路搜尋 Provider 特定金鑰。
  在自動模式（Provider 未設定）中，金鑰依優先順序被查詢以自動偵測 Provider，直到某一個解析成功。
  選定後，未被選取的 Provider 金鑰會被視為非活躍，直到被選取為止。
- `gateway.remote.token` / `gateway.remote.password` SecretRef 在以下任一條件成立時為活躍：
  - `gateway.mode=remote`
  - `gateway.remote.url` 已設定
  - `gateway.tailscale.mode` 為 `serve` 或 `funnel`
  - 在本地模式且不具備上述遠端介面時：
    - `gateway.remote.token` 在 Token 驗證可勝出且未設定環境/Auth Token 時為活躍。
    - `gateway.remote.password` 僅在密碼驗證可勝出且未設定環境/Auth 密碼時為活躍。
- `gateway.auth.token` SecretRef 在設定了 `OPENCLAW_GATEWAY_TOKEN`（或 `CLAWDBOT_GATEWAY_TOKEN`）時，對啟動驗證解析而言是非活躍的，因為環境 Token 輸入在該執行期中優先。

## Gateway 驗證介面診斷

當 `gateway.auth.token`、`gateway.auth.password`、`gateway.remote.token` 或 `gateway.remote.password` 上設定了 SecretRef 時，Gateway 啟動/重新載入會明確記錄介面狀態：

- `active`：SecretRef 是有效驗證介面的一部分，必須能夠解析。
- `inactive`：SecretRef 在此執行期被忽略，因為另一個驗證介面優先，或遠端驗證已停用/不活躍。

這些條目以 `SECRETS_GATEWAY_AUTH_SURFACE` 記錄，並包含活躍介面策略使用的原因，讓您了解為何某個憑證被視為活躍或非活躍。

## 引導程序（Onboarding）參考預檢

當 Onboarding 在互動模式下執行且您選擇 SecretRef 儲存時，OpenClaw 會在儲存前執行預檢驗證：

- Env 引用：驗證環境變數名稱，並確認在 Onboarding 期間可看到非空值。
- Provider 引用（`file` 或 `exec`）：驗證 Provider 選取、解析 `id`，並檢查已解析的值類型。
- 快速啟動重用路徑：當 `gateway.auth.token` 已經是 SecretRef 時，Onboarding 會在探針/儀表板啟動前（對 `env`、`file` 和 `exec` 引用）使用相同的快速失敗閘道解析它。

如果驗證失敗，Onboarding 會顯示錯誤並讓您重試。

## SecretRef 合約

在所有地方使用同一個物件形狀：

```json5
{ source: "env" | "file" | "exec", provider: "default", id: "..." }
```

### `source: "env"`

```json5
{ source: "env", provider: "default", id: "OPENAI_API_KEY" }
```

驗證規則：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須符合 `^[A-Z][A-Z0-9_]{0,127}$`

### `source: "file"`

```json5
{ source: "file", provider: "filemain", id: "/providers/openai/apiKey" }
```

驗證規則：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須是絕對 JSON 指標（`/...`）
- 區段中的 RFC6901 跳脫：`~` => `~0`，`/` => `~1`

### `source: "exec"`

```json5
{ source: "exec", provider: "vault", id: "providers/openai/apiKey" }
```

驗證規則：

- `provider` 必須符合 `^[a-z][a-z0-9_-]{0,63}$`
- `id` 必須符合 `^[A-Za-z0-9][A-Za-z0-9._:/-]{0,255}$`
- `id` 不得包含以斜線分隔的路徑區段 `.` 或 `..`（例如 `a/../b` 會被拒絕）

## Provider 設定

在 `secrets.providers` 下定義 Provider：

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

### Env Provider

- 可透過 `allowlist` 設定選擇性白名單。
- 遺失/空的環境變數值會導致解析失敗。

### File Provider

- 從 `path` 讀取本機檔案。
- `mode: "json"` 期望 JSON 物件 payload，並以指標解析 `id`。
- `mode: "singleValue"` 期望引用 id 為 `"value"`，並回傳檔案內容。
- 路徑必須通過擁有權/權限檢查。
- Windows 安全關閉注意事項：若某路徑的 ACL 驗證不可用，解析會失敗。僅限受信任路徑，可在該 Provider 上設定 `allowInsecurePath: true` 以跳過路徑安全檢查。

### Exec Provider

- 執行已設定的絕對二進位路徑，不使用 shell。
- 預設情況下，`command` 必須指向一般檔案（非符號連結）。
- 設定 `allowSymlinkCommand: true` 以允許符號連結指令路徑（例如 Homebrew shims）。OpenClaw 會驗證已解析的目標路徑。
- 將 `allowSymlinkCommand` 與 `trustedDirs` 搭配用於套件管理器路徑（例如 `["/opt/homebrew"]`）。
- 支援逾時、無輸出逾時、輸出位元組限制、環境允許清單及受信任目錄。
- Windows 安全關閉注意事項：若指令路徑的 ACL 驗證不可用，解析會失敗。僅限受信任路徑，可在該 Provider 上設定 `allowInsecurePath: true` 以跳過路徑安全檢查。

請求 payload（stdin）：

```json
{ "protocolVersion": 1, "provider": "vault", "ids": ["providers/openai/apiKey"] }
```

回應 payload（stdout）：

```jsonc
{ "protocolVersion": 1, "values": { "providers/openai/apiKey": "<openai-api-key>" } } // pragma: allowlist secret
```

選擇性的每個 id 錯誤：

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

## 受支援的憑證介面

規範性支援及不支援的憑證列表於：

- [SecretRef 憑證介面](/zh-Hant/reference/secretref-credential-surface)

執行期鑄造或輪替憑證以及 OAuth 更新素材，基於設計原因被排除在唯讀 SecretRef 解析之外。

## 必要行為與優先順序

- 不帶引用的欄位：不變。
- 帶有引用的欄位：在啟用期間於活躍介面上為必要。
- 若明文與引用同時存在，在受支援的優先順序路徑上引用優先。

警告與稽核訊號：

- `SECRETS_REF_OVERRIDES_PLAINTEXT`（執行期警告）
- `REF_SHADOWED`（稽核發現，當 `auth-profiles.json` 憑證優先於 `openclaw.json` 引用時）

Google Chat 相容性行為：

- `serviceAccountRef` 優先於明文 `serviceAccount`。
- 當同層引用已設定時，明文值會被忽略。

## 啟用觸發條件

機密啟用在以下時機執行：

- 啟動（預檢加上最終啟用）
- 設定重新載入熱套用路徑
- 設定重新載入重新啟動檢查路徑
- 透過 `secrets.reload` 手動重新載入

啟用合約：

- 成功時以原子方式交換快照。
- 啟動失敗時中止 Gateway 啟動。
- 執行期重新載入失敗時保留最後已知良好的快照。
- 向對外輔助程式/工具呼叫提供明確的每次呼叫 Channel Token 不會觸發 SecretRef 啟用；啟用點保持為啟動、重新載入及明確的 `secrets.reload`。

## 降級與恢復訊號

當健康狀態後的重新載入時啟用失敗時，OpenClaw 進入機密降級狀態。

單次系統事件與日誌代碼：

- `SECRETS_RELOADER_DEGRADED`
- `SECRETS_RELOADER_RECOVERED`

行為：

- 降級：執行期保留最後已知良好的快照。
- 恢復：在下次成功啟用後發出一次。
- 已處於降級狀態的重複失敗會記錄警告，但不會重複發送事件。
- 啟動快速失敗不會發出降級事件，因為執行期從未進入活躍狀態。

## 指令路徑解析

指令路徑可透過 Gateway 快照 RPC 選擇加入受支援的 SecretRef 解析。

有兩種主要行為：

- 嚴格指令路徑（例如 `openclaw memory` 遠端記憶體路徑及 `openclaw qr --remote`）從活躍快照讀取，當必要的 SecretRef 不可用時快速失敗。
- 唯讀指令路徑（例如 `openclaw status`、`openclaw status --all`、`openclaw channels status`、`openclaw channels resolve` 以及唯讀的 doctor/config 修復流程）也優先使用活躍快照，但當目標 SecretRef 在該指令路徑中不可用時，會降級而非中止。

唯讀行為：

- 當 Gateway 正在執行時，這些指令首先從活躍快照讀取。
- 如果 Gateway 解析不完整或 Gateway 不可用，它們會嘗試針對特定指令介面進行本地後備解析。
- 如果目標 SecretRef 仍然不可用，指令會以降級的唯讀輸出繼續執行，並附帶明確的診斷訊息，例如「已設定但在此指令路徑中不可用」。
- 此降級行為僅限於該指令本地。它不會削弱執行期啟動、重新載入或傳送/驗證路徑。

其他注意事項：

- 後端機密輪替後的快照重新整理由 `openclaw secrets reload` 處理。
- 這些指令路徑使用的 Gateway RPC 方法：`secrets.resolve`。

## 稽核與設定工作流程

預設操作員流程：

```bash
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets audit --check
```

### `secrets audit`

發現項目包含：

- 靜態的明文值（`openclaw.json`、`auth-profiles.json`、`.env` 及產生的 `agents/*/agent/models.json`）
- 產生的 `models.json` 條目中的明文敏感 Provider 標頭殘留
- 未解析的引用
- 優先順序遮蔽（`auth-profiles.json` 優先於 `openclaw.json` 引用）
- 舊版殘留（`auth.json`、OAuth 提醒）

標頭殘留注意事項：

- 敏感 Provider 標頭偵測基於名稱啟發式（常見的驗證/憑證標頭名稱及片段，例如 `authorization`、`x-api-key`、`token`、`secret`、`password` 及 `credential`）。

### `secrets configure`

互動式輔助程式，可以：

- 首先設定 `secrets.providers`（`env`/`file`/`exec`，新增/編輯/移除）
- 讓您為一個 Agent 範圍選取 `openclaw.json` 及 `auth-profiles.json` 中受支援的機密欄位
- 可直接在目標選取器中建立新的 `auth-profiles.json` 映射
- 擷取 SecretRef 細節（`source`、`provider`、`id`）
- 執行預檢解析
- 可立即套用

實用模式：

- `openclaw secrets configure --providers-only`
- `openclaw secrets configure --skip-provider-setup`
- `openclaw secrets configure --agent <id>`

`configure` 套用預設值：

- 從 `auth-profiles.json` 中清除目標 Provider 的匹配靜態憑證
- 從 `auth.json` 中清除舊版靜態 `api_key` 條目
- 從 `<config-dir>/.env` 中清除匹配的已知機密行

### `secrets apply`

套用已儲存的計畫：

```bash
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
```

關於嚴格目標/路徑合約細節及確切的拒絕規則，請參閱：

- [Secrets Apply Plan 合約](/zh-Hant/gateway/secrets-plan-contract)

## 單向安全策略

OpenClaw 故意不寫入包含歷史明文機密值的回滾備份。

安全模型：

- 預檢必須在寫入模式前成功
- 執行期啟用在提交前進行驗證
- 套用使用原子性檔案取代更新檔案，失敗時盡力還原

## 舊版驗證相容性注意事項

對於靜態憑證，執行期不再依賴明文舊版驗證儲存。

- 執行期憑證來源是已解析的記憶體快照。
- 發現時舊版靜態 `api_key` 條目會被清除。
- OAuth 相關的相容性行為保持獨立。

## Web UI 注意事項

某些 SecretInput 聯合類型在原始編輯器模式下比在表單模式下更容易設定。

## 相關文件

- CLI 指令：[secrets](/zh-Hant/cli/secrets)
- 計畫合約細節：[Secrets Apply Plan 合約](/zh-Hant/gateway/secrets-plan-contract)
- 憑證介面：[SecretRef 憑證介面](/zh-Hant/reference/secretref-credential-surface)
- 驗證設定：[Authentication（驗證）](/zh-Hant/gateway/authentication)
- 安全態勢：[Security（安全性）](/zh-Hant/gateway/security)
- 環境優先順序：[Environment Variables（環境變數）](/zh-Hant/help/environment)
