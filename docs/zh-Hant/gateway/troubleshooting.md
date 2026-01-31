---
title: "troubleshooting(Troubleshooting 🔧)"
summary: "OpenClaw 常見故障的快速排除指南"
read_when:
  - 調查執行時期問題或失敗時
---

# 疑難排解 (Troubleshooting 🔧)

當 OpenClaw 運作不正常時，這裡是修復方法。

若您只想快速分類，請從 FAQ 的 [First 60 seconds](/help/faq#first-60-seconds-if-somethings-broken) 開始。本頁面將更深入探討執行時期失敗與診斷。

供應商專屬捷徑: [/channels/troubleshooting](/channels/troubleshooting)

## 狀態與診斷 (Status & Diagnostics)

快速檢傷分類指令 (依序):

| 指令 | 告訴您什麼 | 何時使用 |
|---|---|---|
| `openclaw status` | 本地摘要: OS + Update, Gateway Reachability/Mode, Service, Agents/Sessions, Provider Config State | 第一步檢查，快速概覽 |
| `openclaw status --all` | 完整本地診斷 (唯讀, 可貼上, 相對安全) 含 Log Tail | 當您需要分享除錯報告時 |
| `openclaw status --deep` | 執行 Gateway Health Checks (含 Provider Probes; 需要 Gateway 可達) | 當 “Configured” 不代表 “Working” 時 |
| `openclaw gateway probe` | Gateway Discovery + Reachability (Local + Remote Targets) | 當您懷疑 Probe 到錯誤的 Gateway 時 |
| `openclaw channels status --probe` | 詢問運行中的 Gateway 關於 Channel Status (並可選性地 Probe) | 當 Gateway 可達但 Channels 行為異常時 |
| `openclaw gateway status` | Supervisor State (launchd/systemd/schtasks), Runtime PID/Exit, Last Gateway Error | 當 Service “看起來已載入” 但什麼都沒運行時 |
| `openclaw logs --follow` | Live Logs (執行時期問題的最佳訊號) | 當您需要實際的失敗原因時 |

**分享輸出:** 偏好使用 `openclaw status --all` (它會遮蔽 Tokens)。若您貼上 `openclaw status`，請考慮先設定 `OPENCLAW_SHOW_SECRETS=0` (Token 預覽)。

參閱: [Health checks](/gateway/health) 與 [Logging](/logging)。

## 常見問題 (Common Issues)

### No API key found for provider "anthropic"

這表示 **Agent 的 Auth Store 是空的** 或缺少 Anthropic 憑證。
Auth 是 **Per Agent** 的，因此新 Agent 不會繼承 Main Agent 的 Keys。

修復選項:
- 重新執行 Onboarding 並為該 Agent 選擇 **Anthropic**。
- 或在 **Gateway Host** 上貼上 Setup-token:
  ```bash
  openclaw models auth setup-token --provider anthropic
  ```
- 或從 Main Agent Dir 複製 `auth-profiles.json` 到新 Agent Dir。

驗證:
```bash
openclaw models status
```

### OAuth token refresh failed (Anthropic Claude subscription)

這表示儲存的 Anthropic OAuth Token 已過期且重新整理失敗。
若您使用的是 Claude 訂閱 (無 API Key)，最可靠的修復是切換到 **Claude Code setup-token** 並在 **Gateway Host** 上貼上它。

**推薦 (setup-token):**

```bash
# 在 Gateway Host 上運行 (貼上 setup-token)
openclaw models auth setup-token --provider anthropic
openclaw models status
```

若您在別處產生 Token:

```bash
openclaw models auth paste-token --provider anthropic
openclaw models status
```

更多細節: [Anthropic](/providers/anthropic) 與 [OAuth](/concepts/oauth)。

### Control UI fails on HTTP ("device identity required" / "connect failed")

若您透過純 HTTP (例如 `http://<lan-ip>:18789/` 或 `http://<tailscale-ip>:18789/`) 開啟 Dashboard，瀏覽器會在 **非安全環境 (Non-secure context)** 運行並封鎖 WebCrypto，因此無法產生 Device Identity。

**修復:**
- 偏好透過 [Tailscale Serve](/gateway/tailscale) 使用 HTTPS。
- 或在 Gateway Host 本地開啟: `http://127.0.0.1:18789/`。
- 若必須停留在 HTTP，啟用 `gateway.controlUi.allowInsecureAuth: true` 並使用 Gateway Token (Token-only; 無 Device Identity/Pairing)。參閱 [Control UI](/web/control-ui#insecure-http)。

### CI Secrets Scan Failed

這表示 `detect-secrets` 發現了不在 Baseline 中的新候選者。
遵循 [Secret scanning](/gateway/security#secret-scanning-detect-secrets)。

### Service Installed but Nothing is Running

若 Gateway Service 已安裝但 Process 立即退出，Service 可能顯示“已載入”但實際上無事發生。

**檢查:**
```bash
openclaw gateway status
openclaw doctor
```

Doctor/Service 會顯示 Runtime State (PID/Last Exit) 與 Log 提示。

**Logs:**
- 偏好: `openclaw logs --follow`
- File Logs (總是): `/tmp/openclaw/openclaw-YYYY-MM-DD.log` (或您設定的 `logging.file`)
- macOS LaunchAgent (若安裝): `$OPENCLAW_STATE_DIR/logs/gateway.log` 與 `gateway.err.log`
- Linux systemd (若安裝): `journalctl --user -u openclaw-gateway[-<profile>].service -n 200 --no-pager`
- Windows: `schtasks /Query /TN "OpenClaw Gateway (<profile>)" /V /FO LIST`

**啟用更多 Logging:**
- 增加 File Log Detail (Persisted JSONL):
  ```json
  { "logging": { "level": "debug" } }
  ```
- 增加 Console Verbosity (TTY Output Only):
  ```json
  { "logging": { "consoleLevel": "debug", "consoleStyle": "pretty" } }
  ```
- 快速提示: `--verbose` 僅影響 **Console** 輸出。File Logs 仍由 `logging.level` 控制。

參閱 [/logging](/logging) 取得完整格式、設定與存取概覽。

### "Gateway start blocked: set gateway.mode=local"

這表示 Config 存在但 `gateway.mode` 未設定 (或非 `local`)，因此 Gateway 拒絕啟動。

**修復 (推薦):**
- 運行 Wizard 並設定 Gateway Run Mode 為 **Local**:
  ```bash
  openclaw configure
  ```
- 或直接設定:
  ```bash
  openclaw config set gateway.mode local
  ```

**若您原本打算運行 Remote Gateway:**
- 設定 Remote URL 並保持 `gateway.mode=remote`:
  ```bash
  openclaw config set gateway.mode remote
  openclaw config set gateway.remote.url "wss://gateway.example.com"
  ```

**Ad-hoc/Dev Only:** 傳遞 `--allow-unconfigured` 以在無 `gateway.mode=local` 下啟動 Gateway。

**還沒有 Config File?** 運行 `openclaw setup` 建立初始 Config，然後重新運行 Gateway。

### Service Environment (PATH + runtime)

Gateway Service 運行時使用 **極簡 PATH** 以避免 Shell/Manager 殘留：
- macOS: `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`
- Linux: `/usr/local/bin`, `/usr/bin`, `/bin`

這刻意排除了 Version Managers (nvm/fnm/volta/asdf) 與 Package Managers (pnpm/npm)，因為 Service 不會載入您的 Shell Init。Runtime Variables 如 `DISPLAY` 應位於 `~/.openclaw/.env` (Gateway 會早期載入)。
在 `host=gateway` 上運行的 Exec 會將您的 Login-shell `PATH` 合併入 Exec Environment，因此遺失工具通常表示您的 Shell Init 未匯出它們 (或設定 `tools.exec.pathPrepend`)。參閱 [/tools/exec](/tools/exec)。

WhatsApp + Telegram Channels 需要 **Node**；不支援 Bun。若您的 Service 是用 Bun 或 Version-managed Node Path 安裝，運行 `openclaw doctor` 遷移至 System Node Install。

### Skill missing API key in sandbox

**症狀:** Skill 在 Host 上運作正常但在 Sandbox 中因缺少 API Key 而失敗。

**原因:** 沙盒化的 Exec 在 Docker 內運行，**不** 繼承 Host `process.env`。

**修復:**
- 設定 `agents.defaults.sandbox.docker.env` (或 Per-agent `agents.list[].sandbox.docker.env`)
- 或將 Key bake 進您的自訂 Sandbox Image
- 然後運行 `openclaw sandbox recreate --agent <id>` (或 `--all`)

### Service Running but Port Not Listening

若 Service 報告 **Running** 但 Gateway Port 沒有監聽，Gateway 可能拒絕綁定。

**這裡 "Running" 的意思**
- `Runtime: running` 表示您的 Supervisor (launchd/systemd/schtasks) 認為 Process 活著。
- `RPC probe` 表示 CLI 實際上能連線至 Gateway WebSocket 並呼叫 `status`。
- 總是信任 `Probe target:` + `Config (service):` 作為 “我們實際上試了什麼？” 的依據。

**檢查:**
- `gateway.mode` 對於 `openclaw gateway` 和 Service 必須是 `local`。
- 若您設定 `gateway.mode=remote`，**CLI 預設** 為 Remote URL。Service 可能仍在本地運行，但您的 CLI 可能 Probe 到錯誤的地方。使用 `openclaw gateway status` 查看 Service 解析的 Port + Probe Target (或傳遞 `--url`)。
- `openclaw gateway status` 與 `openclaw doctor` 當 Service 看似運行但 Port 關閉時，會從 logs 浮現 **Last Gateway Error**。
- Non-loopback Binds (`lan`/`tailnet`/`custom`, 或 Loopback 不可用時的 `auto`) 需要 Auth:
  `gateway.auth.token` (或 `OPENCLAW_GATEWAY_TOKEN`)。
- `gateway.remote.token` 僅供 Remote CLI Calls 使用；它 **不** 啟用 Local Auth。
- `gateway.token` 被忽略；請使用 `gateway.auth.token`。

**若 `openclaw gateway status` 顯示 Config Mismatch**
- `Config (cli): ...` 與 `Config (service): ...` 通常應相符。
- 若不符，您幾乎肯定是在編輯一個 Config 但 Service 運行另一個。
- 修復: 從您希望 Service 使用的相同 `--profile` / `OPENCLAW_STATE_DIR` 重新運行 `openclaw gateway install --force`。

**若 `openclaw gateway status` 報告 Service Config Issues**
- Supervisor Config (launchd/systemd/schtasks) 缺少目前的 Defaults。
- 修復: 運行 `openclaw doctor` 更新它 (或 `openclaw gateway install --force` 進行完整重寫)。

**若 `Last gateway error:` 提及 “refusing to bind … without auth”**
- 您將 `gateway.bind` 設定為非 Loopback 模式 (`lan`/`tailnet`/`custom`, 或 Loopback 不可用時的 `auto`) 但未設定 Auth。
- 修復: 設定 `gateway.auth.mode` + `gateway.auth.token` (或匯出 `OPENCLAW_GATEWAY_TOKEN`) 並重啟 Service。

**若 `openclaw gateway status` 說 `bind=tailnet` 但未發現 Tailnet Interface**
- Gateway 嘗試綁定至 Tailscale IP (100.64.0.0/10) 但 Host 上未偵測到。
- 修復: 在該機器上啟動 Tailscale (或將 `gateway.bind` 變更為 `loopback`/`lan`)。

**若 `Probe note:` 說 Probe 使用 Loopback**
- 對於 `bind=lan` 這是預期的: Gateway 監聽 `0.0.0.0` (所有介面)，Loopback 仍應可本地連線。
- 對於 Remote Clients，使用真實 LAN IP (非 `0.0.0.0`) 加上 Port，並確保 Auth 已設定。

### Address Already in Use (Port 18789)

這表示有東西已在監聽 Gateway Port。

**檢查:**
```bash
openclaw gateway status
```

它會顯示 Listener(s) 與可能原因 (Gateway Already Running, SSH Tunnel)。
若需要，停止 Service 或選擇不同的 Port。

### Extra Workspace Folders Detected

若您從舊版安裝升級，硬碟上可能仍有 `~/openclaw`。
多個 Workspace 目錄可能導致混淆的 Auth 或 State Drift，因為只有一個 Workspace 是活躍的。

**修復:** 保持單一活躍 Workspace 並封存/移除其餘。參閱 [Agent workspace](/concepts/agent-workspace#extra-workspace-folders)。

### Main chat running in a sandbox workspace

症狀: `pwd` 或 File Tools 顯示 `~/.openclaw/sandboxes/...` 即使您預期是 Host Workspace。

**原因:** `agents.defaults.sandbox.mode: "non-main"` 基於 `session.mainKey` (預設 `"main"`)。
Group/Channel Sessions 使用自己的 Keys，因此被視為 Non-main 並獲得 Sandbox Workspaces。

**修復選項:**
- 若您希望 Agent 使用 Host Workspace: 設定 `agents.list[].sandbox.mode: "off"`。
- 若您希望在 Sandbox 內存取 Host Workspace: 為該 Agent 設定 `workspaceAccess: "rw"`。

### "Agent was aborted"

Agent 在回應中途被中斷。

**原因:**
- 使用者發送 `stop`, `abort`, `esc`, `wait`, 或 `exit`
- 超過 Timeout
- Process Crashed

**修復:** 直接發送另一則訊息。Session 會繼續。

### "Agent failed before reply: Unknown model: anthropic/claude-haiku-3-5"

OpenClaw 刻意拒絕 **較舊/不安全模型** (特別是那些較易受 Prompt Injection 攻擊的)。若您看到此錯誤，表示該 Model Name 已不再支援。

**修復:**
- 選擇該供應商的 **最新** 模型並更新您的 Config 或 Model Alias。
- 若不確定哪些模型可用，運行 `openclaw models list` 或 `openclaw models scan` 並選擇支援的。
- 檢查 Gateway Logs 以取得詳細失敗原因。

參閱: [Models CLI](/cli/models) 與 [Model providers](/concepts/model-providers)。

### Messages Not Triggering

**檢查 1:** 發送者是否在 Allowlist 中？
```bash
openclaw status
```
在輸出中尋找 `AllowFrom: ...`。

**檢查 2:** 對於群組聊天，是否需要 Mention？
```bash
# 訊息必須符合 mentionPatterns 或 Explicit Mentions；預設值位於 Channel Groups/Guilds。
# Multi-agent: `agents.list[].groupChat.mentionPatterns` 覆蓋 Global Patterns。
grep -n "agents\\|groupChat\\|mentionPatterns\\|channels\\.whatsapp\\.groups\\|channels\\.telegram\\.groups\\|channels\\.imessage\\.groups\\|channels\\.discord\\.guilds" \
  "${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
```

**檢查 3:** 檢查 Logs
```bash
openclaw logs --follow
# 或若您想要快速過濾:
tail -f "$(ls -t /tmp/openclaw/openclaw-*.log | head -1)" | grep "blocked\\|skip\\|unauthorized"
```

### Pairing Code Not Arriving

若 `dmPolicy` 為 `pairing`，未知發送者應收到代碼且其訊息在核准前被忽略。

**檢查 1:** 是否已有 Pending Request 在等待？
```bash
openclaw pairing list <channel>
```

Pending DM Pairing Requests 預設上限為 **每 Channel 3 個**。若清單已滿，新請求不會產生代碼直到有一個被核准或過期。

**檢查 2:** 請求是否已建立但未發送回覆？
```bash
openclaw logs --follow | grep "pairing request"
```

**檢查 3:** 確認該 Channel 的 `dmPolicy` 不是 `open`/`allowlist`。

### Image + Mention Not Working

已知問題: 當您發送僅含 Mention (無其他文字) 的圖片時，WhatsApp 有時不包含 Mention Metadata。

**暫時解法:** 在圖片加上一些文字與 Mention:
- ❌ `@openclaw` + image
- ✅ `@openclaw check this` + image

### Session Not Resuming

**檢查 1:** Session 檔案是否存在？
```bash
ls -la ~/.openclaw/agents/<agentId>/sessions/
```

**檢查 2:** Reset Window 是否太短？
```json
{
  "session": {
    "reset": {
      "mode": "daily",
      "atHour": 4,
      "idleMinutes": 10080  // 7 days
    }
  }
}
```

**檢查 3:** 是否有人發送 `/new`, `/reset`, 或 Reset Trigger？

### Agent Timing Out

預設 Timeout 為 30 分鐘。對於長時間任務：

```json
{
  "reply": {
    "timeoutSeconds": 3600  // 1 hour
  }
}
```

或使用 `process` 工具將長時間指令背景化。

### WhatsApp Disconnected

```bash
# 檢查本地狀態 (Creds, Sessions, Queued Events)
openclaw status
# Probe 運行中的 Gateway + Channels (WA connect + Telegram + Discord APIs)
openclaw status --deep

# 查看最近的 Connection Events
openclaw logs --limit 200 | grep "connection\\|disconnect\\|logout"
```

**修復:** 通常在 Gateway 運行後會自動重連。若卡住，重啟 Gateway Process (無論您如何監督它)，或手動以 Verbose 運行：

```bash
openclaw gateway --verbose
```

若您被登出 / Unlinked:

```bash
openclaw channels logout
trash "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/credentials" # 若 logout 無法乾淨移除所有東西
openclaw channels login --verbose       # 重新掃描 QR
```

### Media Send Failing

**檢查 1:** File Path 是否有效？
```bash
ls -la /path/to/your/image.jpg
```

**檢查 2:** 是否太大？
- Images: max 6MB
- Audio/Video: max 16MB
- Documents: max 100MB

**檢查 3:** 檢查 Media Logs
```bash
grep "media\\|fetch\\|download" "$(ls -t /tmp/openclaw/openclaw-*.log | head -1)" | tail -20
```

### High Memory Usage

OpenClaw 將對話歷史保留在記憶體中。

**修復:** 定期重啟或設定 Session Limits:
```json
{
  "session": {
    "historyLimit": 100  // 保留的最大訊息數
  }
}
```

## 常見疑難排解 (Common troubleshooting)

### “Gateway won’t start — configuration invalid”

OpenClaw 現在當 Config 包含未知 Keys, Malformed Values, 或 Invalid Types 時拒絕啟動。
這是為了安全性而故意設計的。

使用 Doctor 修復它:
```bash
openclaw doctor
openclaw doctor --fix
```

註記:
- `openclaw doctor` 報告每個無效項目。
- `openclaw doctor --fix` 套用 Migrations/Repairs 並重寫 Config。
- 診斷指令如 `openclaw logs`, `openclaw health`, `openclaw status`, `openclaw gateway status`, 與 `openclaw gateway probe` 即使 Config 無效仍可運行。

### “All models failed” — 我該先檢查什麼？

- **憑證 (Credentials)** 是否存在於嘗試的 Provider(s) (Auth Profiles + Env Vars)。
- **模型路由 (Model routing)**: 確認 `agents.defaults.model.primary` 與 Fallbacks 是您可存取的模型。
- **Gateway Logs** 於 `/tmp/openclaw/…` 查看確切的 Provider Error。
- **Model Status**: 使用 `/model status` (Chat) 或 `openclaw models status` (CLI)。

### 我在用個人 WhatsApp 號碼運行 — 為何 Self-chat 很怪？

啟用 Self-chat Mode 並將您的號碼加入 Allowlist:

```json5
{
  channels: {
    whatsapp: {
      selfChatMode: true,
      dmPolicy: "allowlist",
      allowFrom: ["+15555550123"]
    }
  }
}
```

參閱 [WhatsApp setup](/channels/whatsapp)。

### WhatsApp 把我登出了。如何重新 Auth？

再次運行 Login 指令並掃描 QR Code:

```bash
openclaw channels login
```

### Build errors on `main` — 標準修復路徑為何？

1) `git pull origin main && pnpm install`
2) `openclaw doctor`
3) 檢查 GitHub Issues 或 Discord
4) 暫時解法: Check out 較舊的 Commit

### npm install fails (allow-build-scripts / missing tar or yargs)。現在怎辦？

若您從原始碼運行，使用 Repo 的 Package Manager: **pnpm** (偏好)。
Repo 宣告 `packageManager: "pnpm@…"`.

典型復原:
```bash
git status   # 確保您在 Repo Root
pnpm install
pnpm build
openclaw doctor
openclaw gateway restart
```

原因: pnpm 是此 Repo 設定的 Package Manager。

### 我如何在 Git Installs 與 npm Installs 之間切換？

使用 **Website Installer** 並以 Flag 選擇安裝方式。它會就地升級並重寫 Gateway Service 指向新安裝。

切換 **至 Git Install**:
```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --install-method git --no-onboard
```

切換 **至 npm Global**:
```bash
curl -fsSL https://openclaw.bot/install.sh | bash
```

註記:
- Git Flow 僅當 Repo 是乾淨時才 Rebase。先 Commit 或 Stash 變更。
- 切換後，運行:
  ```bash
  openclaw doctor
  openclaw gateway restart
  ```

### Telegram Block Streaming 沒把文字切分在 Tool Calls 之間。為什麼？

Block Streaming 僅發送 **完整的 Text Blocks**。只看到單一訊息的常見原因:
- `agents.defaults.blockStreamingDefault` 仍為 `"off"`。
- `channels.telegram.blockStreaming` 設為 `false`。
- `channels.telegram.streamMode` 是 `partial` 或 `block` **且 Draft Streaming 活躍中** (Private Chat + Topics)。該情況下 Draft Streaming 停用 Block Streaming。
- 您的 `minChars` / Coalesce Settings 太高，因此 Chunks 被合併。
- 模型發出一個巨大的 Text Block (無 Mid-reply Flush Points)。

修復清單:
1) 將 Block Streaming Settings 放在 `agents.defaults` 下，而非 Root。
2) 若您想要真的 Multi-message Block Replies，設定 `channels.telegram.streamMode: "off"`。
3) 除錯時使用較小的 Chunk/Coalesce Thresholds。

參閱 [Streaming](/concepts/streaming)。

### Discord 即使 `requireMention: false` 也不在我的 Server 回覆。為什麼？

`requireMention` 僅控制 **通過 Allowlists 後** 的 Mention-gating。
預設 `channels.discord.groupPolicy` 是 **allowlist**，因此 Guilds 必須顯式啟用。
若您設定 `channels.discord.guilds.<guildId>.channels`，僅列出的 Channels 被允許；省略它則允許 Guild 中所有 Channels。

修復清單:
1) 設定 `channels.discord.groupPolicy: "open"` **或** 新增 Guild Allowlist Entry (及選用的 Channel Allowlist)。
2) 在 `channels.discord.guilds.<guildId>.channels` 中使用 **數值 Channel IDs**。
3) 將 `requireMention: false` 放在 `channels.discord.guilds` (Global 或 Per-channel) **之下**。
   Top-level `channels.discord.requireMention` 不是支援的 Key。
4) 確保 Bot 擁有 **Message Content Intent** 與 Channel Permissions。
5) 運行 `openclaw channels status --probe` 取得 Audit Hints。

文件: [Discord](/channels/discord), [Channels troubleshooting](/channels/troubleshooting)。

### Cloud Code Assist API error: invalid tool schema (400)。現在怎辦？

這幾乎總是 **Tool Schema Compatibility** 問題。Cloud Code Assist Endpoint 接受 JSON Schema 的嚴格子集。OpenClaw 在目前的 `main` 中會 Scrub/Normalize Tool Schemas，但修復尚未在上一版 Release 中 (截至 2026/01/13)。

修復清單:
1) **Update OpenClaw**:
   - 若您能從 Source 運行，Pull `main` 並重啟 Gateway。
   - 否則，等待包含 Schema Scrubber 的下一版 Release。
2) 避免不支援的 Keywords 如 `anyOf/oneOf/allOf`, `patternProperties`, `additionalProperties`, `minLength`, `maxLength`, `format` 等。
3) 若您定義 Custom Tools，保持 Top-level Schema 為 `type: "object"` 搭配 `properties` 與簡單 Enums。

參閱 [Tools](/tools) 與 [TypeBox schemas](/concepts/typebox)。

## macOS 特定問題 (macOS Specific Issues)

### App Crashes when Granting Permissions (Speech/Mic)

若您點擊 "Allow" 隱私提示時 App 消失或顯示 "Abort trap 6":

**修復 1: 重置 TCC Cache**
```bash
tccutil reset All bot.molt.mac.debug
```

**修復 2: 強制新 Bundle ID**
若重置無效，變更 [`scripts/package-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/package-mac-app.sh) 中的 `BUNDLE_ID` (例如新增 `.test` 後綴) 並重新建置。這強制 macOS 將其視為新 App。

### Gateway stuck on "Starting..."

App 連線至 Port `18789` 的 Local Gateway。若卡住:

**修復 1: 停止 Supervisor (偏好)**
若 Gateway 受 launchd 監督，殺死 PID 僅會讓它重生。先停止 Supervisor:
```bash
openclaw gateway status
openclaw gateway stop
# 或: launchctl bootout gui/$UID/bot.molt.gateway (替換為 bot.molt.<profile>; 舊版 com.openclaw.* 仍有效)
```

**修復 2: Port 忙碌 (找出 Listener)**
```bash
lsof -nP -iTCP:18789 -sTCP:LISTEN
```

若它是 Unsupervised Process，先嘗試 Graceful Stop，然後升級手段:
```bash
kill -TERM <PID>
sleep 1
kill -9 <PID> # 最後手段
```

**修復 3: 檢查 CLI Install**
確保 Global `openclaw` CLI 已安裝且符合 App 版本:
```bash
openclaw --version
npm install -g openclaw@<version>
```

## 除錯模式 (Debug Mode)

取得 Verbose Logging:

```bash
# 在 Config 中開啟 Trace Logging:
#   ${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json} -> { logging: { level: "trace" } }
#
# 然後運行 Verbose 指令以將 Debug Output 鏡像至 stdout:
openclaw gateway --verbose
openclaw channels login --verbose
```

## Log 位置 (Log Locations)

| Log | 位置 |
|-----|----------|
| Gateway file logs (structured) | `/tmp/openclaw/openclaw-YYYY-MM-DD.log` (或 `logging.file`) |
| Gateway service logs (supervisor) | macOS: `$OPENCLAW_STATE_DIR/logs/gateway.log` + `gateway.err.log` (預設: `~/.openclaw/logs/...`; profiles 使用 `~/.openclaw-<profile>/logs/...`)<br />Linux: `journalctl --user -u openclaw-gateway[-<profile>].service -n 200 --no-pager`<br />Windows: `schtasks /Query /TN "OpenClaw Gateway (<profile>)" /V /FO LIST` |
| Session files | `$OPENCLAW_STATE_DIR/agents/<agentId>/sessions/` |
| Media cache | `$OPENCLAW_STATE_DIR/media/` |
| Credentials | `$OPENCLAW_STATE_DIR/credentials/` |

## 健康檢查 (Health Check)

```bash
# Supervisor + Probe Target + Config Paths
openclaw gateway status
# 包含 System-level Scans (Legacy/Extra Services, Port Listeners)
openclaw gateway status --deep

# Gateway 是否可達？
openclaw health --json
# 若失敗，以 Connection Details 重跑:
openclaw health --verbose

# 是否有東西在預設 Port 監聽？
lsof -nP -iTCP:18789 -sTCP:LISTEN

# 最近活動 (RPC log tail)
openclaw logs --follow
# 若 RPC 掛了的 Fallback
tail -20 /tmp/openclaw/openclaw-*.log
```

## 重置一切 (Reset Everything)

核選項 (Nuclear Option):

```bash
openclaw gateway stop
# 若您安裝了 Service 且想要乾淨安裝:
# openclaw gateway uninstall

trash "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
openclaw channels login         # 重新配對 WhatsApp
openclaw gateway restart           # 或: openclaw gateway
```

⚠️ 這會遺失所有 Sessions 且需要重新配對 WhatsApp。

## 尋求協助 (Getting Help)

1. 先檢查 Logs: `/tmp/openclaw/` (預設: `openclaw-YYYY-MM-DD.log`, 或您設定的 `logging.file`)
2. 用于 GitHub 搜尋現有 Issues
3. 開啟新 Issue 並附上:
   - OpenClaw Version
   - 相關 Log Snippets
   - 重現步驟 (Steps to reproduce)
   - 您的 Config (遮蔽 Secrets!)

---

*"Have you tried turning it off and on again?"* — 每個 IT 人員說過的話

🦞🔧

### Browser Not Starting (Linux)

若您看到 `"Failed to start Chrome CDP on port 18800"`:

**最可能原因:** Ubuntu 上的 Snap-packaged Chromium。

**快速修復:** 改安裝 Google Chrome:
```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
```

然後在 Config 中設定:
```json
{
  "browser": {
    "executablePath": "/usr/bin/google-chrome-stable"
  }
}
```

**完整指南:** 參閱 [browser-linux-troubleshooting](/tools/browser-linux-troubleshooting)
