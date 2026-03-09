---
summary: "模型認證：OAuth、API keys 與 setup-token"
read_when:
  - 除錯模型認證或 OAuth 過期問題時
  - 記錄認證或憑證儲存方式時
title: "Authentication（認證）"
---

# 認證 (Authentication)

OpenClaw 支援模型供應商的 OAuth 與 API Keys。對於長期運行的 Gateway 主機，API Keys 通常是最可預測的選項。當供應商帳號模式支援訂閱/OAuth 流程時，也可以使用。

請參閱 [/concepts/oauth](/zh-Hant/concepts/oauth) 了解完整的 OAuth 流程與儲存佈局。
關於基於 SecretRef 的認證（`env`/`file`/`exec` 供應商），請參閱 [Secrets Management](/zh-Hant/gateway/secrets)。
關於 `models status --probe` 使用的憑證資格/原因代碼規則，請參閱
[Auth Credential Semantics](/zh-Hant/auth-credential-semantics)。

## 推薦設定（API key，適用任何供應商）

若您運行長期 Gateway，請從選定供應商的 API key 開始。
對於 Anthropic，API key 認證是安全的路徑，建議優先使用，而非訂閱 setup-token 認證。

1. 在供應商控制台建立 API key。
2. 將其放在 **gateway host**（運行 `openclaw gateway` 的機器）上。

```bash
export <PROVIDER>_API_KEY="..."
openclaw models status
```

3. 若 Gateway 在 systemd/launchd 下運行，建議將 key 放在
   `~/.openclaw/.env` 中讓 Daemon 讀取：

```bash
cat >> ~/.openclaw/.env <<'EOF'
<PROVIDER>_API_KEY=...
EOF
```

然後重啟 Daemon（或重啟您的 Gateway 程序）並重新檢查：

```bash
openclaw models status
openclaw doctor
```

若您不想自行管理環境變數，Onboarding 精靈可以為 Daemon 儲存 API keys：`openclaw onboard`。

請參閱 [Help](/zh-Hant/help) 了解環境變數繼承（`env.shellEnv`、`~/.openclaw/.env`、systemd/launchd）的詳細說明。

## Anthropic：setup-token（訂閱驗證）

若您使用 Claude 訂閱，支援 setup-token 流程。在 **gateway host** 上執行：

```bash
claude setup-token
```

然後將其貼上至 OpenClaw：

```bash
openclaw models auth setup-token --provider anthropic
```

若 Token 是在另一台機器上建立的，請手動貼上：

```bash
openclaw models auth paste-token --provider anthropic
```

若您看到如下的 Anthropic 錯誤：

```
This credential is only authorized for use with Claude Code and cannot be used for other API requests.
```

…請改用 Anthropic API key。

<Warning>
Anthropic setup-token 支援僅為技術相容性。Anthropic 過去曾封鎖在 Claude Code 以外使用訂閱的情況。只有在您決定接受政策風險時才使用，並自行確認 Anthropic 目前的條款。
</Warning>

手動輸入 Token（任何供應商；寫入 `auth-profiles.json` + 更新設定）：

```bash
openclaw models auth paste-token --provider anthropic
openclaw models auth paste-token --provider openrouter
```

Auth profile refs 也支援靜態憑證：

- `api_key` 憑證可使用 `keyRef: { source, provider, id }`
- `token` 憑證可使用 `tokenRef: { source, provider, id }`

自動化友善檢查（過期/遺失時退出 `1`，即將過期時退出 `2`）：

```bash
openclaw models status --check
```

選用的維運腳本（systemd/Termux）記錄於此：
[/automation/auth-monitoring](/zh-Hant/automation/auth-monitoring)

> `claude setup-token` 需要互動式 TTY。

## 檢查模型認證狀態

```bash
openclaw models status
openclaw doctor
```

## API key 輪換行為（Gateway）

部分供應商支援在 API 呼叫遇到速率限制時，用備用 key 重試請求。

- 優先順序：
  - `OPENCLAW_LIVE_<PROVIDER>_KEY`（單一覆蓋）
  - `<PROVIDER>_API_KEYS`
  - `<PROVIDER>_API_KEY`
  - `<PROVIDER>_API_KEY_*`
- Google 供應商還包含 `GOOGLE_API_KEY` 作為額外的 fallback。
- 相同的 key 清單在使用前會先去重複。
- OpenClaw 僅對速率限制錯誤（例如 `429`、`rate_limit`、`quota`、`resource exhausted`）重試下一個 key。
- 非速率限制錯誤不會使用備用 key 重試。
- 若所有 key 都失敗，返回最後一次嘗試的最終錯誤。

## 控制使用的憑證

### Per-session（聊天指令）

使用 `/model <alias-or-id>@<profileId>` 為目前 Session 固定特定的供應商憑證（Profile ID 範例：`anthropic:default`、`anthropic:work`）。

使用 `/model`（或 `/model list`）進行精簡選擇；使用 `/model status` 查看完整檢視（候選者 + 下一個使用的 Auth Profile，以及設定好的 Provider Endpoint 詳細資訊）。

### Per-agent（CLI 覆蓋）

為 Agent 設定顯式的 Auth Profile 順序覆蓋（儲存在該 Agent 的 `auth-profiles.json` 中）：

```bash
openclaw models auth order get --provider anthropic
openclaw models auth order set --provider anthropic anthropic:default
openclaw models auth order clear --provider anthropic
```

使用 `--agent <id>` 鎖定特定 Agent；省略則使用設定的預設 Agent。

## 故障排除

### "No credentials found"

若遺失 Anthropic Token Profile，請在 **gateway host** 上執行 `claude setup-token`，然後重新檢查：

```bash
openclaw models status
```

### Token 即將過期/已過期

執行 `openclaw models status` 確認哪個 Profile 即將過期。若 Profile 遺失，重新執行 `claude setup-token` 並再次貼上 Token。

## 需求

- Anthropic 訂閱帳號（用於 `claude setup-token`）
- 已安裝 Claude Code CLI（可使用 `claude` 指令）
