---
title: "index(Security 🔒)"
summary: "運行具有 Shell 存取權限的 AI Gateway 的安全性考量與威脅模型"
read_when:
  - 新增擴大存取權限或自動化的功能時
---

# 安全性 (Security 🔒)

## 快速檢查：`openclaw security audit`

另請參閱：[形式化驗證 (Security Models)](/security/formal-verification)

請定期執行此指令（特別是在變更 Config 或暴露網路介面後）：

```bash
openclaw security audit
openclaw security audit --deep
openclaw security audit --fix
```

它會檢查：
- 暴露的 Admin Ports
- 弱 Auth Tokens
- 過於寬鬆的 Tool Policies
- 未Sandbox的 Agent 設定
- 暴露於 Logs 的 Secrets
- Docker Socket 權限
- 危險的 Env Vars

## 威脅模型 (Threat model)

OpenClaw 是一個 **Remote Code Execution (RCE) as a Service** 引擎。
它的核心功能是讓 AI 模型在您的機器上執行指令。
安全性模型假設 **AI 模型可能會被入侵** (Prompt Injection, Jailbreaks, Service Provider bugs)。

我們的防禦層級：

1.  **Isolation (Sandbox)**: 限制損害範圍（檔案系統、網路）。
2.  **Policy (Tools)**: 限制能力（禁止危險工具）。
3.  **Human-in-the-loop**: 對於高風險操作強制要求 User Approval。
4.  **Audit**: 記錄所有操作以便事後分析。

### 攻擊向量 1: 遠端 RCE (惡意使用者)
- **情境**：攻擊者 DM 您的機器人或在群組中提及它，誘騙它執行 `rm -rf /` 或竊取 `~/.ssh/id_rsa`。
- **防禦**：
    - **Pairing/Allowlists**: 預設忽略來自未知使用者的訊息。
    - **Session Isolation**: 每個 DM 都有自己的 Sandbox/Workspace。
    - **Group Gating**: 群組需要明確的 Config Allowlist + Mention。

### 攻擊向量 2: 模型越獄 (Jailbreak)
- **情境**：使用者要求合法任務，但模型決定變壞（"Waluigi effect"）或被注入的內容（網頁搜尋結果）劫持以攻擊 Host。
- **防禦**：
    - **Sandboxing**: 即使模型想要 `rm -rf /`，它也只能刪除拋棄式 Sandbox 中的檔案。
    - **Tool Policy**: `exec` 工具被嚴格限制或在 Sandbox 內無特權。
    - **Network Egress Filtering**: Docker Network 設定為 `none` 或特定 Allowlist，防止外洩資料。

### 攻擊向量 3: 本地提權 (Local Privilege Escalation)
- **情境**：受損的 Agent 試圖從 Sandbox 逃逸到 Host。
- **防禦**：
    - **Docker User Namespace**: Sandbox 在容器內以 Root 運行，但在 Host 上對應為非特權使用者。
    - **Mount Restrictions**: Host FS 僅以 Read-only 掛載，或完全不掛載。
    - **Capabilities**: Drop all caps (`CAP_SYS_ADMIN`, `CAP_NET_ADMIN` etc.)。

## 隔離層級 (Isolation Levels)

OpenClaw 支援不同強度的隔離：

### Level 0: Host Execution (Development / Personal)
- **Config**: `sandbox: { mode: "off" }`
- **風險**：極高。模型以您的使用者身分在 Host 上運行。
- **適用於**：受信任的本地開發、個人使用的 Coding Agent（您監控每個操作）。

### Level 1: Containerized Agent (Shared)
- **Config**: `sandbox: { mode: "all", scope: "shared" }`
- **風險**：中等。模型被限制在 Docker Container 內，但所有 Sessions 共用同一個 Container/Filesystem。Session A 可以看見 Session B 的檔案。
- **適用於**：Single-user Deployments，需要持久化 State。

### Level 2: Per-Session Sandboxes (Recommended for Public Bots)
- **Config**: `sandbox: { mode: "all", scope: "session" }`
- **風險**：低。每個 Session 啟動一個全新的、隔離的 Container。Session 結束後資料被銷毀（除非明確持久化）。
- **適用於**：Public DMs, Group Chats, Untrusted Users。

### Level 3: Gvisor / Firecracker (Paranoid)
- **Config**: 使用 `docker.runtime` (例如 `runsc`)。
- **風險**：極低。核心層級隔離。
- **適用於**：Multi-tenant SaaS, High-value Hosts。

## Tool Policy

除了 Sandbox，您可以限制 Agent **可以呼叫什麼工具**。
這在 `tools` (Global) 或 `agents.list[].tools` (Per-agent) 中設定。

```json5
tools: {
  // Allowlist approach (Recommended)
  allow: ["read", "web_search", "sessions_send"],
  
  // Deny specific dangerous tools
  deny: ["exec", "bash", "process", "write", "edit"]
}
```

### 危險工具

- `exec`, `bash`, `process`: 若未 Sandbox，這些是 RCE。即使在 Sandbox 內，它們也允許消耗資源。
- `write`, `edit`: 允許覆蓋檔案。
- `browser`: 消耗大量 RAM/CPU；可能被用來存取本地 Intranet 網站 (SSRF)。
- `gateway`: 允許 Agent 重啟 Gateway 或變更 Config (若啟用)。

## Human-in-the-loop (Approval)

您可以強制特定工具或模式需要 **使用者批准** 才能執行。
目前這是透過 Client-side UI (Dashboard) 或 CLI (`openclaw wait`) 實現的，但在 Gateway 層級：

- **Elevated Exec**: 使用 `tools.elevated.allowFrom` 限制誰可以透過 Chat 請求 Host Exec。
- **Sensitive Actions**: 有些工具會發出 "Confirmation Required" 狀態（未來功能）。

## Secrets Management

- **不要** 將 API Keys 寫入 `openclaw.json`。
- **使用** 環境變數 (`OPENAI_API_KEY`) 或 `.env` 檔案。
- **Logging**: Gateway 會嘗試從 Logs 中遮蔽 Secrets (Redaction)，但不要依賴它。確保 Logs 不會被未授權使用者讀取。
- **Auth Profiles**: 使用 `openclaw auth login` 將 OAuth Tokens 儲存在 `~/.openclaw/agents/<id>/agent/auth-profiles.json`，這比明文 Config 更安全。

## 網路 (Network)

- **Bind Host**: 預設 `127.0.0.1`。若您綁定到 `0.0.0.0`，**必須** 設定 `gateway.auth.token`。
- **Admin RPC**: 預設僅限 Loopback。若要遠端管理，請使用 SSH Tunnel 或 VPN (Tailscale)，不要直接暴露 Admin Port。
- **Webhooks**: 使用隨機路徑與 Secrets (Telegram/Slack 驗證簽章，但路徑隱藏增加了安全性)。

## Docker Socket

若您啟用 Sandbox，Gateway 需要存取 Docker Socket (`/var/run/docker.sock`)。
這賦予 Gateway 對 Host 的 Root 存取權限（透過啟動 Privileged Containers）。
**OpenClaw Gateway 本身應該被視為 Privileged Process。**
不要在不受信任的環境中以 Root 身份運行 Gateway。
盡量以專用使用者 (e.g., `openclaw`) 運行，並僅將該使用者加入 `docker` group。
