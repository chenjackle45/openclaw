---
title: "authentication(Authentication)"
summary: "模型認證: OAuth, API keys, 與 setup-token"
read_when:
  - 除錯模型認證或 OAuth 過期問題時
  - 記錄認證或憑證儲存方式時
---

# 認證 (Authentication)

OpenClaw 支援模型供應商的 OAuth 與 API Keys。對於 Anthropic 帳號，我們建議使用 **API key**。對於 Claude 訂閱存取，請使用由 `claude setup-token` 建立的長效 Token。

請參閱 [/concepts/oauth](/concepts/oauth) 了解完整的 OAuth 流程與儲存佈局。

## 推薦的 Anthropic 設定 (API key)

若您直接使用 Anthropic，請使用 API key。

1) 在 Anthropic Console 建立一組 API key。
2) 將其放在 **gateway host** (運行 `openclaw gateway` 的機器) 上。

```bash
export ANTHROPIC_API_KEY="..."
openclaw models status
```

3) 若 Gateway 在 systemd/launchd 下運行，建議將 Key 放在 `~/.openclaw/.env` 中讓 Daemon 讀取：

```bash
cat >> ~/.openclaw/.env <<'EOF'
ANTHROPIC_API_KEY=...
EOF
```

然後重啟 Daemon (或重啟您的 Gateway 程序) 並重新檢查：

```bash
openclaw models status
openclaw doctor
```

若您不想自行管理環境變數，Onboarding 精靈可以為 Daemon 儲存 API keys：`openclaw onboard`。

詳情請參閱 [Help](/help) 關於環境變數繼承 (`env.shellEnv`, `~/.openclaw/.env`, systemd/launchd) 的說明。

## Anthropic: setup-token (訂閱驗證)

對於 Anthropic，推薦的路徑是 **API key**。若您使用的是 Claude 訂閱，也支援 setup-token 流程。在 **gateway host** 上執行：

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

手動輸入 Token (任何供應商；寫入 `auth-profiles.json` + 更新設定)：

```bash
openclaw models auth paste-token --provider anthropic
openclaw models auth paste-token --provider openrouter
```

自動化友善檢查 (過期/遺失時退出 `1`，即將過期時退出 `2`)：

```bash
openclaw models status --check
```

選用的維運腳本 (systemd/Termux) 記錄於此：
[/automation/auth-monitoring](/automation/auth-monitoring)

> `claude setup-token` 需要互動式 TTY。

## 檢查模型認證狀態

```bash
openclaw models status
openclaw doctor
```

## 控制使用的憑證

### Per-session (聊天指令)

使用 `/model <alias-or-id>@<profileId>` 為目前 Session 固定特定的供應商憑證 (Profile ID 範例: `anthropic:default`, `anthropic:work`)。

使用 `/model` (或 `/model list`) 進行精簡選擇；使用 `/model status` 查看完整檢視 (候選者 + 下一個使用的 Auth Profile，以及設定好的 Provider Endpoint 詳細資訊)。

### Per-agent (CLI 覆蓋)

為 Agent 設定顯式的 Auth Profile 順序覆蓋 (儲存在該 Agent 的 `auth-profiles.json` 中)：

```bash
openclaw models auth order get --provider anthropic
openclaw models auth order set --provider anthropic anthropic:default
openclaw models auth order clear --provider anthropic
```

使用 `--agent <id>`鎖定特定 Agent；省略則使用設定的預設 Agent。

## 故障排除

### “No credentials found” (找不到憑證)

若遺失 Anthropic Token Profile，請在 **gateway host** 上執行 `claude setup-token`，然後重新檢查：

```bash
openclaw models status
```

### Token 即將過期/已過期

執行 `openclaw models status` 確認哪個 Profile 即將過期。若 Profile 遺失，重新執行 `claude setup-token` 並再次貼上 Token。

## 需求

- Claude Max 或 Pro 訂閱 (用於 `claude setup-token`)
- 已安裝 Claude Code CLI (可使用 `claude` 指令)
