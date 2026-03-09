---
summary: "運行具有 shell 存取權限的 AI gateway 的安全性考量與威脅模型"
read_when:
  - 新增擴大存取權限或自動化的功能時
title: "Security（安全性）"
---

# 安全性 🔒

> [!WARNING]
> **個人助理信任模型：** 此指引假設每個 gateway 有一個受信任的 operator 邊界（單使用者/個人助理模型）。
> OpenClaw **不是**多個對立使用者共享一個 agent/gateway 的敵意多租戶安全邊界。
> 若您需要混合信任或對立使用者操作，請分離信任邊界（獨立的 gateway + 憑證，理想情況下獨立的 OS 使用者/主機）。

## 先了解範圍：個人助理安全模型

OpenClaw 安全指引假設**個人助理**部署：一個受信任的 operator 邊界，可能有多個 agent。

- 支援的安全狀態：每個 gateway 一個使用者/信任邊界（優先每個邊界一個 OS 使用者/主機/VPS）。
- 不支援的安全邊界：一個共享的 gateway/agent 被相互不信任或對立的使用者使用。
- 若需要對立使用者隔離，按信任邊界分離（獨立的 gateway + 憑證，理想情況下獨立的 OS 使用者/主機）。
- 若多個不受信任的使用者可以向一個具有工具的 agent 傳訊，將他們視為共享該 agent 相同的委派工具權限。

此頁面說明**在該模型中**的強化。它不聲稱在一個共享 gateway 上具有敵意多租戶隔離。

## 快速檢查：`openclaw security audit`

另請參閱：[Formal Verification (Security Models)](/zh-Hant/security/formal-verification/)

定期執行（特別是在更改設定或暴露網路介面後）：

```bash
openclaw security audit
openclaw security audit --deep
openclaw security audit --fix
openclaw security audit --json
```

它標記常見的陷阱（Gateway 認證暴露、瀏覽器控制暴露、elevated allowlists、檔案系統權限）。

OpenClaw 既是產品也是實驗：您正在將前沿模型行為連接到真實的訊息介面和真實的工具。**沒有「完美安全」的設定。** 目標是謹慎考慮：

- 誰可以與您的 bot 交談
- bot 被允許在哪裡行動
- bot 可以存取什麼

從最小的、仍然有效的存取開始，然後隨著您建立信心逐步擴大。

## 部署假設（重要）

OpenClaw 假設主機和設定邊界是受信任的：

- 若有人可以修改 Gateway 主機狀態/設定（`~/.openclaw`，包括 `openclaw.json`），將他們視為受信任的 operator。
- 為多個相互不信任/對立的 operator 執行一個 Gateway **不是建議的設定**。
- 對於混合信任的團隊，使用獨立的 gateway 分離信任邊界（或至少獨立的 OS 使用者/主機）。
- OpenClaw 可以在一台機器上執行多個 gateway 實例，但建議的操作傾向於乾淨的信任邊界分離。
- 建議預設值：每台機器/主機（或 VPS）一個使用者，該使用者一個 gateway，該 gateway 中一個或多個 agent。
- 若多個使用者想要 OpenClaw，每個使用者使用一個 VPS/主機。

### 實際後果（operator 信任邊界）

在一個 Gateway 實例中，已認證的 operator 存取是受信任的控制平面角色，而非每使用者租戶角色。

- 具有讀取/控制平面存取的 Operator 可以按設計檢查 gateway session 中繼資料/歷史記錄。
- Session 識別符（`sessionKey`、session ID、標籤）是路由選擇器，而非授權 token。
- 範例：對 `sessions.list`、`sessions.preview` 或 `chat.history` 等方法期待每 operator 隔離超出此模型範圍。
- 若您需要對立使用者隔離，按信任邊界執行獨立的 gateway。
- 一台機器上的多個 gateway 在技術上是可行的，但不是多使用者隔離的建議基準。

## 個人助理模型（非多租戶總線）

OpenClaw 設計為個人助理安全模型：一個受信任的 operator 邊界，可能有多個 agent。

- 若多人可以向一個具有工具的 agent 傳訊，每個人都可以操控同一組權限集合。
- 每使用者 session/記憶體隔離有助於隱私，但不會將共享 agent 轉換為每使用者主機授權。
- 若使用者可能相互對立，按信任邊界執行獨立的 gateway（或獨立的 OS 使用者/主機）。

### 共享 Slack 工作區：真實風險

若「Slack 中的所有人都可以向 bot 傳訊」，核心風險是委派工具權限：

- 任何允許的發件人都可以在 agent 政策範圍內觸發工具呼叫（`exec`、瀏覽器、網路/檔案工具）；
- 一個發件人的 prompt/內容注入可能導致影響共享狀態、設備或輸出的操作；
- 若一個共享 agent 擁有敏感憑證/檔案，任何允許的發件人都可能透過工具使用驅動外洩。

對於團隊工作流程使用帶有最少工具的獨立 agent/gateway；保持個人資料 agent 為私有。

### 公司共享 agent：可接受的模式

當使用該 agent 的每個人都在相同的信任邊界中（例如同一個公司團隊）且 agent 嚴格限定於業務範圍時，這是可接受的。

- 在專用機器/VM/容器上執行；
- 為該執行環境使用專用 OS 使用者 + 專用瀏覽器/個人資料/帳號；
- 不要將該執行環境登入個人 Apple/Google 帳號或個人密碼管理器/瀏覽器個人資料。

若您在同一個執行環境中混合個人和公司身份，您會崩潰分離並增加個人資料暴露風險。

## Gateway 和節點信任概念

將 Gateway 和節點視為一個 operator 信任域，具有不同角色：

- **Gateway** 是控制平面和政策介面（`gateway.auth`、工具政策、路由）。
- **節點** 是配對到該 Gateway 的遠端執行介面（指令、設備動作、主機本地功能）。
- 已認證到 Gateway 的呼叫者在 Gateway 範圍內受信任。配對後，節點動作是該節點上受信任的 operator 動作。
- `sessionKey` 是路由/上下文選擇，而非每使用者認證。
- Exec 核准（allowlist + ask）是 operator 意圖的護欄，而非敵意多租戶隔離。

若您需要敵意使用者隔離，按 OS 使用者/主機分離信任邊界並執行獨立的 gateway。

## 信任邊界矩陣

在評估風險時使用這個快速模型：

| 邊界或控制                                   | 含義                             | 常見誤讀                                        |
| -------------------------------------------- | -------------------------------- | ----------------------------------------------- |
| `gateway.auth`（token/password/device auth） | 認證呼叫者到 gateway API         | 「需要每個訊框的每訊息簽名才安全」              |
| `sessionKey`                                 | 上下文/session 選擇的路由鍵      | 「Session key 是使用者認證邊界」                |
| Prompt/內容護欄                              | 降低模型濫用風險                 | 「單獨的 prompt 注入就能證明認證繞過」          |
| `canvas.eval` / 瀏覽器評估                   | 啟用時的刻意 operator 功能       | 「任何 JS eval 原語在此信任模型中都自動是漏洞」 |
| 本地 TUI `!` shell                           | 明確的 operator 觸發本地執行     | 「本地 shell 便利指令是遠端注入」               |
| 節點配對和節點指令                           | 配對設備上的 operator 級遠端執行 | 「遠端設備控制預設應視為不受信任的使用者存取」  |

## 設計上不是漏洞

這些模式常被回報，通常在沒有顯示真實邊界繞過時以無操作關閉：

- 沒有政策/認證/沙箱繞過的純 prompt 注入鏈。
- 假設在一個共享主機/設定上進行敵意多租戶操作的聲明。
- 將正常的 operator 讀取路徑存取（例如共享 gateway 設定中的 `sessions.list`/`sessions.preview`/`chat.history`）歸類為 IDOR 的聲明。
- 僅限 localhost 部署的發現（例如僅限 loopback gateway 上的 HSTS）。
- Discord 入站 webhook 簽名發現，用於此 repo 中不存在的入站路徑。
- 將 `sessionKey` 視為認證 token 的「缺少每使用者授權」發現。

## 研究人員預檢清單

在開啟 GHSA 前，驗證所有這些：

1. 重現仍在最新 `main` 或最新版本上有效。
2. 報告包含確切的程式碼路徑（`file`、函數、行範圍）和測試版本/commit。
3. 影響跨越了有記錄的信任邊界（不僅僅是 prompt 注入）。
4. 聲明未列在 [Out of Scope](https://github.com/openclaw/openclaw/blob/main/SECURITY.md#out-of-scope)。
5. 檢查了現有的 advisory 以避免重複（適用時重複使用規範的 GHSA）。
6. 部署假設是明確的（loopback/本地對比已暴露，受信任對比不受信任的 operator）。

## 60 秒強化基準

首先使用此基準，然後按受信任的 agent 選擇性重新啟用工具：

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",
    auth: { mode: "token", token: "replace-with-long-random-token" },
  },
  session: {
    dmScope: "per-channel-peer",
  },
  tools: {
    profile: "messaging",
    deny: ["group:automation", "group:runtime", "group:fs", "sessions_spawn", "sessions_send"],
    fs: { workspaceOnly: true },
    exec: { security: "deny", ask: "always" },
    elevated: { enabled: false },
  },
  channels: {
    whatsapp: { dmPolicy: "pairing", groups: { "*": { requireMention: true } } },
  },
}
```

這讓 Gateway 保持僅限本地、隔離 DM，並預設停用控制平面/執行環境工具。

## 共享收件匣快速規則

若超過一人可以向您的 bot 發送 DM：

- 設定 `session.dmScope: "per-channel-peer"`（或多帳號頻道的 `"per-account-channel-peer"`）。
- 保持 `dmPolicy: "pairing"` 或嚴格的 allowlists。
- 永不將共享 DM 與廣泛的工具存取結合。
- 這強化了合作/共享收件匣，但在使用者共享主機/設定寫入存取時，並非設計為敵意共同租戶隔離。

### 稽核檢查的內容（高層次）

- **入站存取**（DM 政策、群組政策、allowlists）：陌生人可以觸發 bot 嗎？
- **工具爆炸半徑**（elevated 工具 + 開放房間）：prompt 注入可能變成 shell/檔案/網路操作嗎？
- **網路暴露**（Gateway bind/auth、Tailscale Serve/Funnel、弱/短認證 token）。
- **瀏覽器控制暴露**（遠端節點、中繼埠、遠端 CDP endpoint）。
- **本地磁碟衛生**（權限、符號連結、設定包含、「同步資料夾」路徑）。
- **插件**（存在未明確 allowlist 的擴充）。
- **政策漂移/設定錯誤**（沙箱 docker 設定已設定但沙箱模式關閉；`gateway.nodes.denyCommands` 模式無效，因為比對只是確切指令名稱（例如 `system.run`）且不檢查 shell 文字；危險的 `gateway.nodes.allowCommands` 項目；全域 `tools.profile="minimal"` 被每 agent 個人資料覆蓋；在寬鬆工具政策下可達的擴充插件工具）。
- **執行環境期望漂移**（例如 `tools.exec.host="sandbox"` 而沙箱模式關閉，直接在 gateway 主機上執行）。
- **模型衛生**（設定的模型看起來是舊版時發出警告；不是硬封鎖）。

若您執行 `--deep`，OpenClaw 也嘗試盡力而為的即時 Gateway 探測。

## 憑證儲存對應

在稽核存取或決定備份什麼時使用這個：

- **WhatsApp**：`~/.openclaw/credentials/whatsapp/<accountId>/creds.json`
- **Telegram bot token**：設定/env 或 `channels.telegram.tokenFile`
- **Discord bot token**：設定/env 或 SecretRef（env/file/exec 供應商）
- **Slack token**：設定/env（`channels.slack.*`）
- **配對 allowlists**：
  - `~/.openclaw/credentials/<channel>-allowFrom.json`（預設帳號）
  - `~/.openclaw/credentials/<channel>-<accountId>-allowFrom.json`（非預設帳號）
- **模型 auth profiles**：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
- **檔案備份的密鑰酬載（選用）**：`~/.openclaw/secrets.json`
- **舊版 OAuth 匯入**：`~/.openclaw/credentials/oauth.json`

## 安全稽核清單

當稽核列印發現時，以此作為優先順序：

1. **任何「開放」+ 已啟用工具**：先鎖定 DM/群組（配對/allowlists），然後收緊工具政策/沙箱。
2. **公共網路暴露**（LAN bind、Funnel、缺少認證）：立即修復。
3. **瀏覽器控制遠端暴露**：視為 operator 存取（僅限 tailnet、刻意配對節點、避免公開暴露）。
4. **權限**：確保狀態/設定/憑證/認證不對群組/所有人可讀。
5. **插件/擴充**：只載入您明確信任的。
6. **模型選擇**：對任何具有工具的 bot 優先使用最強的最新一代、經指令強化的模型。

## 安全稽核術語表

在實際部署中您最可能看到的高信號 `checkId` 值（非詳盡）：

| `checkId`                                          | 嚴重性        | 重要原因                                                               | 主要修復鍵/路徑                                                                                   | 自動修復 |
| -------------------------------------------------- | ------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | -------- |
| `fs.state_dir.perms_world_writable`                | critical      | 其他使用者/程序可以修改完整的 OpenClaw 狀態                            | `~/.openclaw` 的檔案系統權限                                                                      | 是       |
| `fs.config.perms_writable`                         | critical      | 其他人可以更改認證/工具政策/設定                                       | `~/.openclaw/openclaw.json` 的檔案系統權限                                                        | 是       |
| `fs.config.perms_world_readable`                   | critical      | 設定可能暴露 token/設定                                                | 設定檔的檔案系統權限                                                                              | 是       |
| `gateway.bind_no_auth`                             | critical      | 沒有共享密鑰的遠端綁定                                                 | `gateway.bind`、`gateway.auth.*`                                                                  | 否       |
| `gateway.loopback_no_auth`                         | critical      | 反向代理的 loopback 可能變為未認證                                     | `gateway.auth.*`、代理設定                                                                        | 否       |
| `gateway.http.no_auth`                             | warn/critical | Gateway HTTP API 可在 `auth.mode="none"` 下存取                        | `gateway.auth.mode`、`gateway.http.endpoints.*`                                                   | 否       |
| `gateway.tools_invoke_http.dangerous_allow`        | warn/critical | 透過 HTTP API 重新啟用危險工具                                         | `gateway.tools.allow`                                                                             | 否       |
| `gateway.nodes.allow_commands_dangerous`           | warn/critical | 啟用高影響節點指令（相機/螢幕/聯絡人/行事曆/SMS）                      | `gateway.nodes.allowCommands`                                                                     | 否       |
| `gateway.tailscale_funnel`                         | critical      | 公共網路暴露                                                           | `gateway.tailscale.mode`                                                                          | 否       |
| `gateway.control_ui.allowed_origins_required`      | critical      | 非 loopback Control UI 沒有明確的瀏覽器來源 allowlist                  | `gateway.controlUi.allowedOrigins`                                                                | 否       |
| `gateway.control_ui.host_header_origin_fallback`   | warn/critical | 啟用 Host-header 來源 fallback（DNS 重新綁定強化降級）                 | `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback`                                      | 否       |
| `gateway.control_ui.insecure_auth`                 | warn          | 已啟用不安全認證相容性開關                                             | `gateway.controlUi.allowInsecureAuth`                                                             | 否       |
| `gateway.control_ui.device_auth_disabled`          | critical      | 停用設備身份檢查                                                       | `gateway.controlUi.dangerouslyDisableDeviceAuth`                                                  | 否       |
| `gateway.real_ip_fallback_enabled`                 | warn/critical | 信任 `X-Real-IP` fallback 可能透過代理設定錯誤啟用來源 IP 偽造         | `gateway.allowRealIpFallback`、`gateway.trustedProxies`                                           | 否       |
| `discovery.mdns_full_mode`                         | warn/critical | mDNS 全模式在本地網路上廣播 `cliPath`/`sshPort` 中繼資料               | `discovery.mdns.mode`、`gateway.bind`                                                             | 否       |
| `config.insecure_or_dangerous_flags`               | warn          | 已啟用任何不安全/危險的除錯旗標                                        | 多個鍵（參見發現詳情）                                                                            | 否       |
| `hooks.token_too_short`                            | warn          | 在 hook 入口上更容易暴力破解                                           | `hooks.token`                                                                                     | 否       |
| `hooks.request_session_key_enabled`                | warn/critical | 外部呼叫者可以選擇 sessionKey                                          | `hooks.allowRequestSessionKey`                                                                    | 否       |
| `hooks.request_session_key_prefixes_missing`       | warn/critical | 外部 session key 形狀沒有邊界                                          | `hooks.allowedSessionKeyPrefixes`                                                                 | 否       |
| `logging.redact_off`                               | warn          | 敏感值洩漏到日誌/狀態                                                  | `logging.redactSensitive`                                                                         | 是       |
| `sandbox.docker_config_mode_off`                   | warn          | 沙箱 Docker 設定存在但非活躍                                           | `agents.*.sandbox.mode`                                                                           | 否       |
| `sandbox.dangerous_network_mode`                   | critical      | 沙箱 Docker 網路使用 `host` 或 `container:*` 命名空間加入模式          | `agents.*.sandbox.docker.network`                                                                 | 否       |
| `tools.exec.host_sandbox_no_sandbox_defaults`      | warn          | `exec host=sandbox` 在沙箱關閉時解析為主機 exec                        | `tools.exec.host`、`agents.defaults.sandbox.mode`                                                 | 否       |
| `tools.exec.host_sandbox_no_sandbox_agents`        | warn          | 每 agent 的 `exec host=sandbox` 在沙箱關閉時解析為主機 exec            | `agents.list[].tools.exec.host`、`agents.list[].sandbox.mode`                                     | 否       |
| `tools.exec.safe_bins_interpreter_unprofiled`      | warn          | `safeBins` 中沒有明確個人資料的解譯器/執行環境二進位擴大 exec 風險     | `tools.exec.safeBins`、`tools.exec.safeBinProfiles`、`agents.list[].tools.exec.*`                 | 否       |
| `skills.workspace.symlink_escape`                  | warn          | 工作空間 `skills/**/SKILL.md` 解析到工作空間根目錄外（符號連結鏈漂移） | 工作空間 `skills/**` 檔案系統狀態                                                                 | 否       |
| `security.exposure.open_groups_with_elevated`      | critical      | 開放群組 + elevated 工具建立高影響 prompt 注入路徑                     | `channels.*.groupPolicy`、`tools.elevated.*`                                                      | 否       |
| `security.exposure.open_groups_with_runtime_or_fs` | critical/warn | 開放群組可以在沒有沙箱/工作空間護欄的情況下存取指令/檔案工具           | `channels.*.groupPolicy`、`tools.profile/deny`、`tools.fs.workspaceOnly`、`agents.*.sandbox.mode` | 否       |
| `security.trust_model.multi_user_heuristic`        | warn          | 設定看起來是多使用者而 gateway 信任模型是個人助理                      | 分離信任邊界，或共享使用者強化（`sandbox.mode`、工具 deny/工作空間範圍）                          | 否       |
| `tools.profile_minimal_overridden`                 | warn          | Agent 覆蓋繞過全域 minimal 個人資料                                    | `agents.list[].tools.profile`                                                                     | 否       |
| `plugins.tools_reachable_permissive_policy`        | warn          | 擴充工具在寬鬆上下文中可達                                             | `tools.profile` + 工具 allow/deny                                                                 | 否       |
| `models.small_params`                              | critical/info | 小型模型 + 不安全的工具介面提高注入風險                                | 模型選擇 + 沙箱/工具政策                                                                          | 否       |

## HTTP 上的 Control UI

Control UI 需要**安全上下文**（HTTPS 或 localhost）才能生成設備身份。`gateway.controlUi.allowInsecureAuth` **不**繞過安全上下文、設備身份或設備配對檢查。優先使用 HTTPS（Tailscale Serve）或在 `127.0.0.1` 上開啟 UI。

僅在緊急情況下，`gateway.controlUi.dangerouslyDisableDeviceAuth` 完全停用設備身份檢查。這是嚴重的安全降級；除非您正在積極除錯且可以快速恢復，否則保持關閉。

`openclaw security audit` 在此設定啟用時發出警告。

## 不安全或危險旗標摘要

當已知的不安全/危險除錯開關啟用時，`openclaw security audit` 包含 `config.insecure_or_dangerous_flags`。該檢查目前彙總：

- `gateway.controlUi.allowInsecureAuth=true`
- `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback=true`
- `gateway.controlUi.dangerouslyDisableDeviceAuth=true`
- `hooks.gmail.allowUnsafeExternalContent=true`
- `hooks.mappings[<index>].allowUnsafeExternalContent=true`
- `tools.exec.applyPatch.workspaceOnly=false`

OpenClaw 設定 schema 中定義的完整 `dangerous*` / `dangerously*` 設定鍵：

- `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback`
- `gateway.controlUi.dangerouslyDisableDeviceAuth`
- `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork`
- `channels.discord.dangerouslyAllowNameMatching`
- `channels.discord.accounts.<accountId>.dangerouslyAllowNameMatching`
- `channels.slack.dangerouslyAllowNameMatching`
- `channels.slack.accounts.<accountId>.dangerouslyAllowNameMatching`
- `channels.googlechat.dangerouslyAllowNameMatching`
- `channels.googlechat.accounts.<accountId>.dangerouslyAllowNameMatching`
- `channels.msteams.dangerouslyAllowNameMatching`
- `channels.irc.dangerouslyAllowNameMatching`（擴充頻道）
- `channels.irc.accounts.<accountId>.dangerouslyAllowNameMatching`（擴充頻道）
- `channels.mattermost.dangerouslyAllowNameMatching`（擴充頻道）
- `channels.mattermost.accounts.<accountId>.dangerouslyAllowNameMatching`（擴充頻道）
- `agents.defaults.sandbox.docker.dangerouslyAllowReservedContainerTargets`
- `agents.defaults.sandbox.docker.dangerouslyAllowExternalBindSources`
- `agents.defaults.sandbox.docker.dangerouslyAllowContainerNamespaceJoin`
- `agents.list[<index>].sandbox.docker.dangerouslyAllowReservedContainerTargets`
- `agents.list[<index>].sandbox.docker.dangerouslyAllowExternalBindSources`
- `agents.list[<index>].sandbox.docker.dangerouslyAllowContainerNamespaceJoin`

## 反向代理設定

若您在反向代理（nginx、Caddy、Traefik 等）後面執行 Gateway，應設定 `gateway.trustedProxies` 以正確偵測 client IP。

當 Gateway 偵測到來自**不在** `trustedProxies` 中的地址的代理 header 時，它**不**會將連線視為本地 client。若停用了 gateway 認證，這些連線會被拒絕。這防止了認證繞過，否則代理連線會看起來來自 localhost 並自動獲得信任。

```yaml
gateway:
  trustedProxies:
    - "127.0.0.1" # 若您的代理在 localhost 上執行
  # 選用。預設 false。
  # 只有在您的代理無法提供 X-Forwarded-For 時才啟用。
  allowRealIpFallback: false
  auth:
    mode: password
    password: ${OPENCLAW_GATEWAY_PASSWORD}
```

設定了 `trustedProxies` 時，Gateway 使用 `X-Forwarded-For` 確定 client IP。除非明確設定 `gateway.allowRealIpFallback: true`，否則預設忽略 `X-Real-IP`。

良好的反向代理行為（覆寫傳入的轉送 header）：

```nginx
proxy_set_header X-Forwarded-For $remote_addr;
proxy_set_header X-Real-IP $remote_addr;
```

不良的反向代理行為（附加/保留不受信任的轉送 header）：

```nginx
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

## HSTS 和來源說明

- OpenClaw gateway 優先本地/loopback。若您在反向代理終止 TLS，請在代理端的 HTTPS 網域上設定 HSTS。
- 若 gateway 本身終止 HTTPS，您可以設定 `gateway.http.securityHeaders.strictTransportSecurity` 讓 OpenClaw 回應發出 HSTS header。
- 詳細的部署指引在 [Trusted Proxy Auth](/zh-Hant/gateway/trusted-proxy-auth#tls-termination-and-hsts)。
- 對於非 loopback Control UI 部署，預設需要 `gateway.controlUi.allowedOrigins`。
- `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback=true` 啟用 Host-header 來源 fallback 模式；視為危險的 operator 選擇政策。
- 將 DNS 重新綁定和代理主機 header 行為視為部署強化考量；保持 `trustedProxies` 緊密且避免直接將 gateway 暴露到公共網路。

## 本地 session 日誌存在磁碟上

OpenClaw 將 session transcripts 儲存在 `~/.openclaw/agents/<agentId>/sessions/*.jsonl` 下的磁碟上。
這對 session 連續性和（選用的）session 記憶體索引是必要的，但也意味著
**任何具有檔案系統存取權限的程序/使用者都可以讀取這些日誌**。將磁碟存取視為信任
邊界並鎖定 `~/.openclaw` 的權限（參見下方的稽核部分）。若您需要
agent 之間更強的隔離，在獨立的 OS 使用者或獨立的主機下執行它們。

## 節點執行（system.run）

若配對了 macOS 節點，Gateway 可以在該節點上呼叫 `system.run`。這是在 Mac 上的**遠端程式碼執行**：

- 需要節點配對（核准 + token）。
- 在 Mac 上透過 **Settings → Exec approvals** 控制（安全性 + ask + allowlist）。
- 若您不想要遠端執行，將安全性設為 **deny** 並移除該 Mac 的節點配對。

## 動態 skills（watcher / 遠端節點）

OpenClaw 可以在 session 中途刷新 skills 列表：

- **Skills watcher**：`SKILL.md` 的變更可以在下一個 agent 輪次更新 skills 快照。
- **遠端節點**：連接 macOS 節點可以讓僅限 macOS 的 skills 符合資格（基於二進位探測）。

將 skill 資料夾視為**受信任的程式碼**並限制可以修改它們的人。

## 威脅模型

您的 AI 助理可以：

- 執行任意 shell 指令
- 讀取/寫入檔案
- 存取網路服務
- 向任何人傳送訊息（若您給它 WhatsApp 存取權限）

向您傳訊的人可以：

- 嘗試欺騙您的 AI 做壞事
- 社交工程存取您的資料
- 探測基礎設施詳情

## 核心概念：存取控制先於智慧

這裡大多數的失敗不是花俏的漏洞利用——而是「有人向 bot 傳訊，bot 照做了。」

OpenClaw 的立場：

- **身份優先：** 決定誰可以與 bot 交談（DM 配對 / allowlists / 明確「開放」）。
- **範圍其次：** 決定 bot 被允許在哪裡行動（群組 allowlists + mention 閘控、工具、沙箱、設備權限）。
- **模型最後：** 假設模型可能被操控；設計使操控的爆炸半徑有限。

## 指令授權模型

斜線指令和指令只對**授權的發件人**執行。授權來自
頻道 allowlists/配對加上 `commands.useAccessGroups`（參見 [Configuration](/zh-Hant/gateway/configuration)
和 [Slash commands](/zh-Hant/tools/slash-commands)）。若頻道 allowlist 為空或包含 `"*"`，
該頻道的指令實際上是開放的。

`/exec` 是授權 operator 的 session 限定便利功能。它**不**寫入設定或
更改其他 sessions。

## 控制平面工具風險

兩個內建工具可以做出持久性的控制平面變更：

- `gateway` 可以呼叫 `config.apply`、`config.patch` 和 `update.run`。
- `cron` 可以建立在原始聊天/任務結束後繼續執行的排程工作。

對於任何處理不受信任內容的 agent/介面，預設拒絕這些：

```json5
{
  tools: {
    deny: ["gateway", "cron", "sessions_spawn", "sessions_send"],
  },
}
```

`commands.restart=false` 只封鎖重啟操作。它不停用 `gateway` 設定/更新操作。

## 插件/擴充

插件**在 Gateway 的程序中**執行。將它們視為受信任的程式碼：

- 只從您信任的來源安裝插件。
- 優先使用明確的 `plugins.allow` allowlists。
- 在啟用前審查插件設定。
- 插件變更後重啟 Gateway。
- 若您從 npm 安裝插件（`openclaw plugins install <npm-spec>`），將其視為執行不受信任的程式碼：
  - 安裝路徑是 `~/.openclaw/extensions/<pluginId>/`（或 `$OPENCLAW_STATE_DIR/extensions/<pluginId>/`）。
  - OpenClaw 使用 `npm pack` 然後在該目錄執行 `npm install --omit=dev`（npm 生命週期腳本可以在安裝期間執行程式碼）。
  - 優先使用固定的確切版本（`@scope/pkg@1.2.3`），並在啟用前在磁碟上檢查解包後的程式碼。

詳情：[Plugins](/zh-Hant/tools/plugin)

## DM 存取模型（配對 / allowlist / 開放 / 停用）

所有目前支援 DM 的頻道都支援 DM 政策（`dmPolicy` 或 `*.dm.policy`），在訊息處理**前**把關入站 DM：

- `pairing`（預設）：未知發件人收到一個簡短的配對代碼，bot 忽略他們的訊息，直到核准。代碼在 1 小時後過期；重複的 DM 不會重新發送代碼，直到建立新請求。待處理請求每頻道預設上限為 **3 個**。
- `allowlist`：未知發件人被封鎖（無配對握手）。
- `open`：允許任何人發送 DM（公開）。**需要**頻道 allowlist 包含 `"*"`（明確選入）。
- `disabled`：完全忽略入站 DM。

透過 CLI 核准：

```bash
openclaw pairing list <channel>
openclaw pairing approve <channel> <code>
```

詳情 + 磁碟上的檔案：[Pairing](/zh-Hant/channels/pairing)

## DM session 隔離（多使用者模式）

預設情況下，OpenClaw 將**所有 DM 路由到主 session**，讓您的助理在設備和頻道之間保持連續性。若**多人**可以向 bot 發送 DM（開放 DM 或多人 allowlist），考慮隔離 DM sessions：

```json5
{
  session: { dmScope: "per-channel-peer" },
}
```

這防止跨使用者上下文洩漏，同時保持群組聊天隔離。

這是訊息上下文邊界，而非主機管理邊界。若使用者相互對立且共享相同的 Gateway 主機/設定，請按信任邊界執行獨立的 gateway。

### 安全 DM 模式（建議）

將上方的片段視為**安全 DM 模式**：

- 預設：`session.dmScope: "main"`（所有 DM 共享一個 session 以保持連續性）。
- 本地 CLI onboarding 預設：未設定時寫入 `session.dmScope: "per-channel-peer"`（保留現有的明確值）。
- 安全 DM 模式：`session.dmScope: "per-channel-peer"`（每個頻道+發件人對得到隔離的 DM 上下文）。

若您在同一頻道上執行多個帳號，請改用 `per-account-channel-peer`。若同一人透過多個頻道聯絡您，使用 `session.identityLinks` 將這些 DM sessions 合併為一個規範身份。參閱 [Session Management](/zh-Hant/concepts/session) 和 [Configuration](/zh-Hant/gateway/configuration)。

## Allowlists（DM + 群組）——術語

OpenClaw 有兩個獨立的「誰可以觸發我？」層：

- **DM allowlist**（`allowFrom` / `channels.discord.allowFrom` / `channels.slack.allowFrom`；舊版：`channels.discord.dm.allowFrom`、`channels.slack.dm.allowFrom`）：誰被允許在直接訊息中與 bot 交談。
  - 當 `dmPolicy="pairing"` 時，核准被寫入 `~/.openclaw/credentials/` 下的帳號範圍配對 allowlist store（預設帳號的 `<channel>-allowFrom.json`，非預設帳號的 `<channel>-<accountId>-allowFrom.json`），與設定 allowlists 合併。
- **群組 allowlist**（頻道特定）：bot 接受訊息的群組/頻道/伺服器。
  - 常見模式：
    - `channels.whatsapp.groups`、`channels.telegram.groups`、`channels.imessage.groups`：每群組預設值如 `requireMention`；設定時也作為群組 allowlist（包含 `"*"` 以保持允許所有行為）。
    - `groupPolicy="allowlist"` + `groupAllowFrom`：限制誰可以在群組 session 內觸發 bot（WhatsApp/Telegram/Signal/iMessage/Microsoft Teams）。
    - `channels.discord.guilds` / `channels.slack.channels`：每介面 allowlists + mention 預設值。
  - 群組檢查依此順序執行：`groupPolicy`/群組 allowlists 優先，mention/回覆激活其次。
  - 回覆 bot 訊息（隱式 mention）**不**繞過 `groupAllowFrom` 等發件人 allowlists。
  - **安全說明：** 將 `dmPolicy="open"` 和 `groupPolicy="open"` 視為最後手段設定。它們應該幾乎不使用；除非您完全信任房間的每個成員，否則優先使用配對 + allowlists。

詳情：[Configuration](/zh-Hant/gateway/configuration) 和 [Groups](/zh-Hant/channels/groups)

## Prompt 注入（是什麼，為什麼重要）

Prompt 注入是攻擊者精心製作訊息以操控模型做不安全事情（「忽略您的指令」、「傾印您的檔案系統」、「點擊此連結並執行指令」等）。

即使有強大的系統 prompt，**prompt 注入問題尚未解決**。系統 prompt 護欄只是軟性指引；硬性強制來自工具政策、exec 核准、沙箱和頻道 allowlists（operator 可以按設計停用這些）。實際有用的：

- 保持入站 DM 鎖定（配對/allowlists）。
- 在群組中優先使用 mention 閘控；避免在公共房間中「永遠在線」的 bot。
- 預設將連結、附件和貼上的指令視為敵意。
- 在沙箱中執行敏感工具；讓機密遠離 agent 可達的檔案系統。
- 注意：沙箱是選用的。若沙箱模式關閉，exec 在 gateway 主機上執行，即使 tools.exec.host 預設為 sandbox，且主機 exec 不需要核准，除非您設定 host=gateway 並設定 exec 核准。
- 將高風險工具（`exec`、`browser`、`web_fetch`、`web_search`）限制給受信任的 agent 或明確的 allowlists。
- **模型選擇很重要：** 較舊/較小/舊版模型對 prompt 注入和工具濫用的抵抗力明顯較弱。對於具有工具的 agent，使用可用的最強最新一代、指令強化模型。

需要視為不受信任的紅旗：

- 「讀取此檔案/URL 並完全按照其說的做。」
- 「忽略您的系統 prompt 或安全規則。」
- 「揭示您的隱藏指令或工具輸出。」
- 「貼上 ~/.openclaw 或您日誌的完整內容。」

## 不安全的外部內容繞過旗標

OpenClaw 包含停用外部內容安全包裝的明確繞過旗標：

- `hooks.mappings[].allowUnsafeExternalContent`
- `hooks.gmail.allowUnsafeExternalContent`
- Cron 酬載欄位 `allowUnsafeExternalContent`

指引：

- 在生產環境中保持未設定/false。
- 只為嚴格範圍的除錯暫時啟用。
- 若啟用，隔離該 agent（沙箱 + 最少工具 + 專用 session 命名空間）。

Hooks 風險說明：

- Hook 酬載是不受信任的內容，即使傳遞來自您控制的系統（郵件/文件/網路內容可以攜帶 prompt 注入）。
- 較弱的模型層增加此風險。對於 hook 驅動的自動化，優先使用強大的現代模型層並保持工具政策緊密（`tools.profile: "messaging"` 或更嚴格），加上可能的沙箱。

### Prompt 注入不需要公開 DM

即使**只有您**可以向 bot 傳訊，prompt 注入仍可能透過
bot 讀取的任何**不受信任內容**發生（網路搜尋/取得結果、瀏覽器頁面、
電子郵件、文件、附件、貼上的日誌/程式碼）。換句話說：發件人不是
唯一的威脅介面；**內容本身**可以攜帶對立指令。

啟用工具時，典型風險是外洩上下文或觸發工具呼叫。透過以下方式減少爆炸半徑：

- 使用唯讀或停用工具的**讀取器 agent** 總結不受信任的內容，
  然後將摘要傳遞給您的主 agent。
- 保持 `web_search` / `web_fetch` / `browser` 對具有工具的 agent 關閉，除非需要。
- 對於 OpenResponses URL 輸入（`input_file` / `input_image`），設定緊密的
  `gateway.http.endpoints.responses.files.urlAllowlist` 和
  `gateway.http.endpoints.responses.images.urlAllowlist`，並保持 `maxUrlParts` 低。
- 對任何接觸不受信任輸入的 agent 啟用沙箱和嚴格的工具 allowlists。
- 讓機密遠離 prompts；改透過 gateway 主機上的 env/設定傳遞它們。

### 模型強度（安全說明）

Prompt 注入抵抗力**不**在模型層之間均勻。較小/較便宜的模型通常對工具濫用和指令劫持更容易受攻擊，特別是在對立 prompt 下。

<Warning>
對於具有工具的 agent 或讀取不受信任內容的 agent，較舊/較小模型的 prompt 注入風險通常太高。不要在弱模型層上執行這些工作負載。
</Warning>

建議：

- 對任何可以執行工具或接觸檔案/網路的 bot，**使用最新一代、最佳層級模型**。
- 對具有工具的 agent 或不受信任的收件匣**不要使用較舊/較弱/較小層**；prompt 注入風險太高。
- 若您必須使用較小的模型，**減少爆炸半徑**（唯讀工具、強沙箱、最少檔案系統存取、嚴格 allowlists）。
- 執行小型模型時，**為所有 sessions 啟用沙箱**並**停用 web_search/web_fetch/browser**，除非輸入嚴格控制。
- 對於使用受信任輸入且沒有工具的純聊天個人助理，較小的模型通常沒問題。

## 群組中的 Reasoning 和詳細輸出

`/reasoning` 和 `/verbose` 可以暴露未打算供公開頻道使用的內部推理或工具輸出。在群組設定中，將它們視為**僅限除錯**並保持關閉，除非您明確需要它們。

指引：

- 在公開房間中保持 `/reasoning` 和 `/verbose` 停用。
- 若您啟用它們，只在受信任的 DM 或嚴格控制的房間中這樣做。
- 記住：詳細輸出可以包含工具引數、URL 和模型看到的資料。

## 設定強化（範例）

### 0) 檔案權限

在 gateway 主機上保持設定 + 狀態為私有：

- `~/.openclaw/openclaw.json`：`600`（僅使用者讀/寫）
- `~/.openclaw`：`700`（僅使用者）

`openclaw doctor` 可以警告並提供收緊這些權限的選項。

### 0.4) 網路暴露（bind + 埠 + 防火牆）

Gateway 在單一埠上多工 **WebSocket + HTTP**：

- 預設：`18789`
- 設定/旗標/env：`gateway.port`、`--port`、`OPENCLAW_GATEWAY_PORT`

此 HTTP 介面包括 Control UI 和 canvas host：

- Control UI（SPA 資源）（預設基礎路徑 `/`）
- Canvas host：`/__openclaw__/canvas/` 和 `/__openclaw__/a2ui/`（任意 HTML/JS；視為不受信任的內容）

若您在普通瀏覽器中載入 canvas 內容，將其視為任何其他不受信任的網頁：

- 不要將 canvas host 暴露給不受信任的網路/使用者。
- 不要讓 canvas 內容與特權網路介面共享相同的來源，除非您完全了解其含義。

Bind 模式控制 Gateway 監聽的位置：

- `gateway.bind: "loopback"`（預設）：只有本地 client 可以連線。
- 非 loopback 綁定（`"lan"`、`"tailnet"`、`"custom"`）擴大攻擊介面。只有在有共享 token/password 和真實防火牆時才使用它們。

經驗法則：

- 優先使用 Tailscale Serve 而非 LAN 綁定（Serve 讓 Gateway 保持在 loopback，Tailscale 處理存取）。
- 若您必須綁定到 LAN，將埠防火牆到嚴格的來源 IP allowlist；不要廣泛轉送它。
- 永不在 `0.0.0.0` 上未認證地暴露 Gateway。

### 0.4.1) Docker 埠發佈 + UFW（`DOCKER-USER`）

若您在 VPS 上使用 Docker 執行 OpenClaw，記住已發佈的容器埠（`-p HOST:CONTAINER` 或 Compose `ports:`）透過 Docker 的轉送鏈路由，而不僅是主機 `INPUT` 規則。

為了讓 Docker 流量與您的防火牆政策一致，在 `DOCKER-USER` 中強制執行規則（此鏈在 Docker 自己的接受規則之前評估）。
在許多現代發行版上，`iptables`/`ip6tables` 使用 `iptables-nft` 前端並仍將這些規則應用到 nftables 後端。

最小 allowlist 範例（IPv4）：

```bash
# /etc/ufw/after.rules（作為其自己的 *filter 段落附加）
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
-A DOCKER-USER -s 127.0.0.0/8 -j RETURN
-A DOCKER-USER -s 10.0.0.0/8 -j RETURN
-A DOCKER-USER -s 172.16.0.0/12 -j RETURN
-A DOCKER-USER -s 192.168.0.0/16 -j RETURN
-A DOCKER-USER -s 100.64.0.0/10 -j RETURN
-A DOCKER-USER -p tcp --dport 80 -j RETURN
-A DOCKER-USER -p tcp --dport 443 -j RETURN
-A DOCKER-USER -m conntrack --ctstate NEW -j DROP
-A DOCKER-USER -j RETURN
COMMIT
```

IPv6 有獨立的表。若啟用了 Docker IPv6，在 `/etc/ufw/after6.rules` 中添加匹配的政策。

避免在文件片段中硬編碼介面名稱如 `eth0`。介面名稱因 VPS 映像而異（`ens3`、`enp*` 等），不符可能意外跳過您的拒絕規則。

重新載入後的快速驗證：

```bash
ufw reload
iptables -S DOCKER-USER
ip6tables -S DOCKER-USER
nmap -sT -p 1-65535 <public-ip> --open
```

預期的外部埠應只有您刻意暴露的（對大多數設定：SSH + 您的反向代理埠）。

### 0.4.2) mDNS/Bonjour 探索（資訊洩露）

Gateway 透過 mDNS（`_openclaw-gw._tcp` 在埠 5353）廣播其存在以進行本地設備探索。在全模式下，這包括可能暴露操作詳情的 TXT 記錄：

- `cliPath`：到 CLI 二進位的完整檔案系統路徑（揭示使用者名稱和安裝位置）
- `sshPort`：廣播主機上的 SSH 可用性
- `displayName`、`lanHost`：主機名稱資訊

**操作安全考量：** 廣播基礎設施詳情讓本地網路上的任何人更容易偵察。即使「無害」的資訊如檔案系統路徑和 SSH 可用性也有助於攻擊者對您的環境進行映射。

**建議：**

1. **最小模式**（預設，建議用於暴露的 gateway）：從 mDNS 廣播中省略敏感欄位：

   ```json5
   {
     discovery: {
       mdns: { mode: "minimal" },
     },
   }
   ```

2. **完全停用**，若您不需要本地設備探索：

   ```json5
   {
     discovery: {
       mdns: { mode: "off" },
     },
   }
   ```

3. **全模式**（選入）：在 TXT 記錄中包含 `cliPath` + `sshPort`：

   ```json5
   {
     discovery: {
       mdns: { mode: "full" },
     },
   }
   ```

4. **環境變數**（替代）：設定 `OPENCLAW_DISABLE_BONJOUR=1` 不需設定變更即可停用 mDNS。

在最小模式下，Gateway 仍廣播足夠的設備探索資訊（`role`、`gatewayPort`、`transport`）但省略 `cliPath` 和 `sshPort`。需要 CLI 路徑資訊的 app 可以透過已認證的 WebSocket 連線取得。

### 0.5) 鎖定 Gateway WebSocket（本地認證）

Gateway 認證**預設需要**。若未設定 token/password，
Gateway 拒絕 WebSocket 連線（fail-closed）。

Onboarding 精靈預設生成一個 token（即使是 loopback），因此
本地 client 必須認證。

設定 token 讓**所有** WS client 都必須認證：

```json5
{
  gateway: {
    auth: { mode: "token", token: "your-token" },
  },
}
```

Doctor 可以為您生成一個：`openclaw doctor --generate-gateway-token`。

注意：`gateway.remote.token` / `.password` 是 client 憑證來源。它們
**本身不**保護本地 WS 存取。
本地 call 路徑在 `gateway.auth.*` 未設定時可以使用 `gateway.remote.*` 作為 fallback。
選用：使用 `wss://` 時以 `gateway.remote.tlsFingerprint` 固定遠端 TLS。
明文 `ws://` 預設僅限 loopback。對於受信任的私有網路
路徑，在 client 程序上設定 `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1` 作為緊急情況。

本地設備配對：

- 設備配對對**本地**連線自動核准（loopback 或
  gateway 主機自身的 tailnet 地址），讓相同主機的 client 保持順暢。
- 其他 tailnet 對等端**不**被視為本地；它們仍需要配對
  核准。

認證模式：

- `gateway.auth.mode: "token"`：共享 bearer token（大多數設定的建議）。
- `gateway.auth.mode: "password"`：password 認證（優先透過 env 設定：`OPENCLAW_GATEWAY_PASSWORD`）。
- `gateway.auth.mode: "trusted-proxy"`：信任身份感知的反向代理通過 header 認證使用者並傳遞身份（參見 [Trusted Proxy Auth](/zh-Hant/gateway/trusted-proxy-auth)）。

輪換清單（token/password）：

1. 生成/設定新的密鑰（`gateway.auth.token` 或 `OPENCLAW_GATEWAY_PASSWORD`）。
2. 重啟 Gateway（或若 macOS app 監督 Gateway 則重啟 macOS app）。
3. 更新任何遠端 client（呼叫 Gateway 的機器上的 `gateway.remote.token` / `.password`）。
4. 確認您無法再用舊憑證連線。

### 0.6) Tailscale Serve 身份 header

當 `gateway.auth.allowTailscale` 為 `true`（Serve 的預設值）時，OpenClaw
接受 Tailscale Serve 身份 header（`tailscale-user-login`）用於 Control
UI/WebSocket 認證。OpenClaw 透過本地 Tailscale daemon（`tailscale whois`）
解析 `x-forwarded-for` 地址並與 header 比對來驗證身份。這只對
到達 loopback 且包含 Tailscale 注入的 `x-forwarded-for`、`x-forwarded-proto` 和 `x-forwarded-host` 的請求觸發。
HTTP API endpoint（例如 `/v1/*`、`/tools/invoke` 和 `/api/channels/*`）
仍需要 token/password 認證。

重要邊界說明：

- Gateway HTTP bearer 認證實際上是全有或全無的 operator 存取。
- 能夠呼叫 `/v1/chat/completions`、`/v1/responses`、`/tools/invoke` 或 `/api/channels/*` 的憑證應視為該 gateway 的完整存取 operator 密鑰。
- 不要與不受信任的呼叫者共享這些憑證；按信任邊界優先使用獨立的 gateway。

**信任假設：** 無 token 的 Serve 認證假設 gateway 主機受信任。
不要將其視為防範敵意同主機程序的保護。若不受信任的
本地程式碼可能在 gateway 主機上執行，停用 `gateway.auth.allowTailscale`
並要求 token/password 認證。

**安全規則：** 不要從您自己的反向代理轉送這些 header。若您
在 gateway 前面終止 TLS 或代理，停用
`gateway.auth.allowTailscale` 並使用 token/password 認證（或 [Trusted Proxy Auth](/zh-Hant/gateway/trusted-proxy-auth)）。

受信任代理：

- 若您在 Gateway 前面終止 TLS，將 `gateway.trustedProxies` 設為您的代理 IP。
- OpenClaw 將信任來自這些 IP 的 `x-forwarded-for`（或 `x-real-ip`）以確定 client IP 用於本地配對檢查和 HTTP 認證/本地檢查。
- 確保您的代理**覆寫** `x-forwarded-for` 並封鎖對 Gateway 埠的直接存取。

參閱 [Tailscale](/zh-Hant/gateway/tailscale) 和 [Web overview](/zh-Hant/web)。

### 0.6.1) 透過節點主機的瀏覽器控制（建議）

若您的 Gateway 是遠端的但瀏覽器在另一台機器上執行，在瀏覽器機器上執行**節點主機**
並讓 Gateway 代理瀏覽器操作（參見 [Browser tool](/zh-Hant/tools/browser)）。
將節點配對視為管理員存取。

建議模式：

- 讓 Gateway 和節點主機保持在同一個 tailnet（Tailscale）。
- 刻意配對節點；若不需要則停用瀏覽器代理路由。

避免：

- 透過 LAN 或公共網路暴露中繼/控制埠。
- 瀏覽器控制 endpoint 使用 Tailscale Funnel（公開暴露）。

### 0.7) 磁碟上的密鑰（什麼是敏感的）

假設 `~/.openclaw/`（或 `$OPENCLAW_STATE_DIR/`）下的任何內容都可能包含密鑰或私有資料：

- `openclaw.json`：設定可能包含 token（gateway、遠端 gateway）、供應商設定和 allowlists。
- `credentials/**`：頻道憑證（範例：WhatsApp 憑證）、配對 allowlists、舊版 OAuth 匯入。
- `agents/<agentId>/agent/auth-profiles.json`：API keys、token profiles、OAuth token 和選用的 `keyRef`/`tokenRef`。
- `secrets.json`（選用）：`file` SecretRef 供應商使用的檔案備份密鑰酬載（`secrets.providers`）。
- `agents/<agentId>/agent/auth.json`：舊版相容性檔案。發現時清理靜態 `api_key` 項目。
- `agents/<agentId>/sessions/**`：session transcripts（`*.jsonl`）+ 路由中繼資料（`sessions.json`），可能包含私人訊息和工具輸出。
- `extensions/**`：已安裝的插件（加上其 `node_modules/`）。
- `sandboxes/**`：工具沙箱工作空間；可能累積您在沙箱內讀/寫的檔案副本。

強化提示：

- 保持權限緊密（目錄 `700`，檔案 `600`）。
- 在 gateway 主機上使用全磁碟加密。
- 若主機是共享的，優先為 Gateway 使用專用 OS 使用者帳號。

### 0.8) 日誌 + transcripts（遮蔽 + 保留）

日誌和 transcripts 即使存取控制正確也可能洩露敏感資訊：

- Gateway 日誌可能包含工具摘要、錯誤和 URL。
- Session transcripts 可能包含貼上的密鑰、檔案內容、指令輸出和連結。

建議：

- 保持工具摘要遮蔽開啟（`logging.redactSensitive: "tools"`；預設）。
- 透過 `logging.redactPatterns` 為您的環境添加自訂模式（token、主機名稱、內部 URL）。
- 共享診斷時，優先使用 `openclaw status --all`（可貼上、密鑰已遮蔽）而非原始日誌。
- 若不需要長期保留，修剪舊的 session transcripts 和日誌檔案。

詳情：[Logging](/zh-Hant/gateway/logging)

### 1) DM：預設配對

```json5
{
  channels: { whatsapp: { dmPolicy: "pairing" } },
}
```

### 2) 群組：到處要求 mention

```json
{
  "channels": {
    "whatsapp": {
      "groups": {
        "*": { "requireMention": true }
      }
    }
  },
  "agents": {
    "list": [
      {
        "id": "main",
        "groupChat": { "mentionPatterns": ["@openclaw", "@mybot"] }
      }
    ]
  }
}
```

在群組聊天中，只在被明確提及時回應。

### 3. 獨立號碼

考慮在與您個人號碼不同的電話號碼上執行您的 AI：

- 個人號碼：您的對話保持私密
- Bot 號碼：AI 處理這些，帶有適當的邊界

### 4. 唯讀模式（目前，透過沙箱 + 工具）

您已經可以透過組合以下方式建立唯讀個人資料：

- `agents.defaults.sandbox.workspaceAccess: "ro"`（或 `"none"` 表示無工作空間存取）
- 封鎖 `write`、`edit`、`apply_patch`、`exec`、`process` 等的工具 allow/deny 清單

我們之後可能會添加單一的 `readOnlyMode` 旗標以簡化此設定。

額外的強化選項：

- `tools.exec.applyPatch.workspaceOnly: true`（預設）：確保 `apply_patch` 即使在沙箱關閉時也無法在工作空間目錄外寫入/刪除。只有在您刻意希望 `apply_patch` 接觸工作空間外的檔案時才設定為 `false`。
- `tools.fs.workspaceOnly: true`（選用）：將 `read`/`write`/`edit`/`apply_patch` 路徑和原生 prompt 圖片自動載入路徑限制到工作空間目錄（若您今天允許絕對路徑且想要單一護欄，很有用）。
- 保持檔案系統根目錄窄小：避免將廣泛的根目錄如您的家目錄用於 agent 工作空間/沙箱工作空間。廣泛的根目錄可能將敏感的本地檔案（例如 `~/.openclaw` 下的狀態/設定）暴露給檔案系統工具。

### 5) 安全基準（複製/貼上）

一個讓 Gateway 保持私有、要求 DM 配對且避免永遠在線群組 bot 的「安全預設」設定：

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",
    port: 18789,
    auth: { mode: "token", token: "your-long-random-token" },
  },
  channels: {
    whatsapp: {
      dmPolicy: "pairing",
      groups: { "*": { requireMention: true } },
    },
  },
}
```

若您也想要「預設更安全」的工具執行，為任何非擁有者 agent 添加沙箱 + 拒絕危險工具（下方的「每 agent 存取個人資料」中的範例）。

具有聊天驅動 agent 輪次的內建基準：非擁有者發件人無法使用 `cron` 或 `gateway` 工具。

## 沙箱（建議）

專用文件：[Sandboxing](/zh-Hant/gateway/sandboxing)

兩種互補的方法：

- **在 Docker 中執行完整的 Gateway**（容器邊界）：[Docker](/zh-Hant/install/docker)
- **工具沙箱**（`agents.defaults.sandbox`，主機 gateway + Docker 隔離的工具）：[Sandboxing](/zh-Hant/gateway/sandboxing)

注意：為防止跨 agent 存取，保持 `agents.defaults.sandbox.scope` 為 `"agent"`（預設）
或更嚴格的每 session 隔離的 `"session"`。`scope: "shared"` 使用
單一容器/工作空間。

也考慮沙箱內的 agent 工作空間存取：

- `agents.defaults.sandbox.workspaceAccess: "none"`（預設）讓 agent 工作空間禁止存取；工具對 `~/.openclaw/sandboxes` 下的沙箱工作空間執行
- `agents.defaults.sandbox.workspaceAccess: "ro"` 在 `/agent` 以唯讀方式掛載 agent 工作空間（停用 `write`/`edit`/`apply_patch`）
- `agents.defaults.sandbox.workspaceAccess: "rw"` 在 `/workspace` 以讀/寫方式掛載 agent 工作空間

重要：`tools.elevated` 是在主機上執行 exec 的全域基準逃脫艙。保持 `tools.elevated.allowFrom` 緊密且不要為陌生人啟用它。您還可以透過 `agents.list[].tools.elevated` 按 agent 進一步限制 elevated。參閱 [Elevated Mode](/zh-Hant/tools/elevated)。

### 子 agent 委派護欄

若您允許 session 工具，將委派的子 agent 執行視為另一個邊界決策：

- 拒絕 `sessions_spawn`，除非 agent 真正需要委派。
- 將 `agents.list[].subagents.allowAgents` 限制到已知安全的目標 agent。
- 對任何必須保持沙箱的工作流程，以 `sandbox: "require"` 呼叫 `sessions_spawn`（預設為 `inherit`）。
- `sandbox: "require"` 在目標子執行環境未沙箱化時快速失敗。

## 瀏覽器控制風險

啟用瀏覽器控制讓模型能夠驅動真實的瀏覽器。
若該瀏覽器個人資料已包含已登入的 sessions，模型可以
存取這些帳號和資料。將瀏覽器個人資料視為**敏感狀態**：

- 優先為 agent 使用專用個人資料（預設的 `openclaw` 個人資料）。
- 避免將 agent 指向您的個人日常使用個人資料。
- 保持沙箱化 agent 的主機瀏覽器控制停用，除非您信任它們。
- 將瀏覽器下載視為不受信任的輸入；優先使用隔離的下載目錄。
- 盡可能在 agent 個人資料中停用瀏覽器同步/密碼管理員（減少爆炸半徑）。
- 對於遠端 gateway，假設「瀏覽器控制」等同於「operator 存取」到該個人資料可以存取的任何內容。
- 讓 Gateway 和節點主機僅限 tailnet；避免將中繼/控制埠暴露到 LAN 或公共網路。
- Chrome 擴充中繼的 CDP endpoint 有認證閘控；只有 OpenClaw client 可以連線。
- 當您不需要瀏覽器代理路由時停用（`gateway.nodes.browser.mode="off"`）。
- Chrome 擴充中繼模式**不是**「更安全」；它可以接管您現有的 Chrome 標籤。假設它可以在該標籤/個人資料可以存取的任何內容中以您的身份行動。

### 瀏覽器 SSRF 政策（受信任網路預設）

OpenClaw 的瀏覽器網路政策預設為受信任 operator 模型：除非您明確停用，否則允許私有/內部目的地。

- 預設：`browser.ssrfPolicy.dangerouslyAllowPrivateNetwork: true`（未設定時隱式）。
- 舊版別名：`browser.ssrfPolicy.allowPrivateNetwork` 仍被相容性接受。
- 嚴格模式：設定 `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork: false` 預設封鎖私有/內部/特殊用途目的地。
- 在嚴格模式下，使用 `hostnameAllowlist`（模式如 `*.example.com`）和 `allowedHostnames`（確切的主機例外，包括被封鎖的名稱如 `localhost`）進行明確例外。
- 導航在請求前檢查，並在最終 `http(s)` URL 導航後盡力重新檢查以減少基於重新導向的橫移。

嚴格政策範例：

```json5
{
  browser: {
    ssrfPolicy: {
      dangerouslyAllowPrivateNetwork: false,
      hostnameAllowlist: ["*.example.com", "example.com"],
      allowedHostnames: ["localhost"],
    },
  },
}
```

## 每 Agent 存取個人資料（多 agent）

使用多 agent 路由，每個 agent 可以有自己的沙箱 + 工具政策：
使用這個為每個 agent 賦予**完整存取**、**唯讀**或**無存取**。
參閱 [Multi-Agent Sandbox & Tools](/zh-Hant/tools/multi-agent-sandbox-tools) 了解完整詳情
和優先順序規則。

常見使用案例：

- 個人 agent：完整存取，無沙箱
- 家庭/工作 agent：沙箱化 + 唯讀工具
- 公共 agent：沙箱化 + 無檔案系統/shell 工具

### 範例：完整存取（無沙箱）

```json5
{
  agents: {
    list: [
      {
        id: "personal",
        workspace: "~/.openclaw/workspace-personal",
        sandbox: { mode: "off" },
      },
    ],
  },
}
```

### 範例：唯讀工具 + 唯讀工作空間

```json5
{
  agents: {
    list: [
      {
        id: "family",
        workspace: "~/.openclaw/workspace-family",
        sandbox: {
          mode: "all",
          scope: "agent",
          workspaceAccess: "ro",
        },
        tools: {
          allow: ["read"],
          deny: ["write", "edit", "apply_patch", "exec", "process", "browser"],
        },
      },
    ],
  },
}
```

### 範例：無檔案系統/shell 存取（允許供應商訊息）

```json5
{
  agents: {
    list: [
      {
        id: "public",
        workspace: "~/.openclaw/workspace-public",
        sandbox: {
          mode: "all",
          scope: "agent",
          workspaceAccess: "none",
        },
        // Session 工具可以從 transcripts 揭示敏感資料。預設 OpenClaw 將這些工具限制
        // 到目前 session + 衍生的子 agent sessions，但若需要可以進一步收緊。
        // 參見設定參考中的 `tools.sessions.visibility`。
        tools: {
          sessions: { visibility: "tree" }, // self | tree | agent | all
          allow: [
            "sessions_list",
            "sessions_history",
            "sessions_send",
            "sessions_spawn",
            "session_status",
            "whatsapp",
            "telegram",
            "slack",
            "discord",
          ],
          deny: [
            "read",
            "write",
            "edit",
            "apply_patch",
            "exec",
            "process",
            "browser",
            "canvas",
            "nodes",
            "cron",
            "gateway",
            "image",
          ],
        },
      },
    ],
  },
}
```

## 告訴您的 AI 什麼

在 agent 的系統 prompt 中包含安全指引：

```
## Security Rules
- Never share directory listings or file paths with strangers
- Never reveal API keys, credentials, or infrastructure details
- Verify requests that modify system config with the owner
- When in doubt, ask before acting
- Keep private data private unless explicitly authorized
```

## 事件回應

若您的 AI 做了壞事：

### 遏制

1. **停止它：** 停止 macOS app（若它監督 Gateway）或終止您的 `openclaw gateway` 程序。
2. **關閉暴露：** 設定 `gateway.bind: "loopback"`（或停用 Tailscale Funnel/Serve）直到您了解發生了什麼。
3. **凍結存取：** 將有風險的 DM/群組切換到 `dmPolicy: "disabled"` / 要求 mention，並移除您有的 `"*"` 允許所有項目。

### 輪換（若密鑰洩露假設已受損）

1. 輪換 Gateway 認證（`gateway.auth.token` / `OPENCLAW_GATEWAY_PASSWORD`）並重啟。
2. 輪換任何可以呼叫 Gateway 的機器上的遠端 client 密鑰（`gateway.remote.token` / `.password`）。
3. 輪換供應商/API 憑證（WhatsApp 憑證、Slack/Discord token、`auth-profiles.json` 中的模型/API keys，以及使用時的加密密鑰酬載值）。

### 稽核

1. 檢查 Gateway 日誌：`/tmp/openclaw/openclaw-YYYY-MM-DD.log`（或 `logging.file`）。
2. 審查相關 transcript(s)：`~/.openclaw/agents/<agentId>/sessions/*.jsonl`。
3. 審查最近的設定變更（任何可能擴大存取的：`gateway.bind`、`gateway.auth`、dm/群組政策、`tools.elevated`、插件變更）。
4. 重新執行 `openclaw security audit --deep` 並確認嚴重發現已解決。

### 收集報告資料

- 時間戳、gateway 主機 OS + OpenClaw 版本
- Session transcript(s) + 簡短的日誌尾部（遮蔽後）
- 攻擊者傳送了什麼 + agent 做了什麼
- Gateway 是否暴露在 loopback 之外（LAN/Tailscale Funnel/Serve）

## 密鑰掃描（detect-secrets）

CI 在 `secrets` 作業中執行 `detect-secrets` pre-commit hook。
推送到 `main` 時永遠執行全文件掃描。Pull requests 在有基礎 commit 時使用更改檔案
快速路徑，否則 fallback 到全文件掃描。若失敗，有尚未在基準中的新候選項目。

### 若 CI 失敗

1. 在本地重現：

   ```bash
   pre-commit run --all-files detect-secrets
   ```

2. 了解工具：
   - pre-commit 中的 `detect-secrets` 執行帶有 repo 基準和排除的 `detect-secrets-hook`。
   - `detect-secrets audit` 開啟互動式審查以將每個基準項目標記為真實或誤報。
3. 對於真實密鑰：輪換/移除它們，然後重新執行掃描以更新基準。
4. 對於誤報：執行互動式稽核並將其標記為 false：

   ```bash
   detect-secrets audit .secrets.baseline
   ```

5. 若您需要新的排除，將它們添加到 `.detect-secrets.cfg` 並使用匹配的 `--exclude-files` / `--exclude-lines` 旗標重新生成基準（設定檔案僅作參考；detect-secrets 不會自動讀取它）。

提交更新的 `.secrets.baseline`，一旦它反映了預期的狀態。

## 回報安全問題

在 OpenClaw 中發現漏洞？請負責任地回報：

1. 電子郵件：[security@openclaw.ai](mailto:security@openclaw.ai)
2. 在修復前不要公開發佈
