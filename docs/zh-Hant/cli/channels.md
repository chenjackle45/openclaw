---
summary: "`openclaw channels` CLI 參考（帳戶管理、狀態查看、登入/登出與日誌）"
read_when:
  - 想要新增或移除頻道帳戶（WhatsApp、Telegram、Discord、Google Chat、Slack、Mattermost（插件）、Signal、iMessage）時
  - 想要檢查頻道狀態或追蹤頻道日誌時
title: "channels（聊天頻道）"
---

# `openclaw channels`

管理聊天頻道帳戶及其在 Gateway 上的運行狀態。

相關資訊：

- 頻道指南：[Channels](/zh-Hant/channels/index)
- Gateway 配置：[Configuration](/zh-Hant/gateway/configuration)

## 常見指令

```bash
openclaw channels list
openclaw channels status
openclaw channels capabilities
openclaw channels capabilities --channel discord --target channel:123
openclaw channels resolve --channel slack "#general" "@jane"
openclaw channels logs --channel all
```

## 新增與移除帳戶

```bash
openclaw channels add --channel telegram --token <bot-token>
openclaw channels remove --channel telegram --delete
```

提示：執行 `openclaw channels add --help` 可查看各個頻道的專屬參數（如 token、app token、signal-cli 路徑等）。

當您執行不帶旗標的 `openclaw channels add` 時，互動式精靈可能會提示：

- 每個選定頻道的帳戶 ID
- 這些帳戶的可選顯示名稱
- `現在將已配置的頻道帳戶綁定至 Agent？`

若您確認立即綁定，精靈會詢問哪個 Agent 應擁有每個配置的頻道帳戶，並寫入帳戶範圍的路由綁定。

您也可以稍後使用 `openclaw agents bindings`、`openclaw agents bind` 和 `openclaw agents unbind` 管理相同的路由規則（請參閱 [agents](/zh-Hant/cli/agents)）。

當您向仍使用單帳戶頂層設定（尚無 `channels.<channel>.accounts` 條目）的頻道新增非預設帳戶時，OpenClaw 會將帳戶範圍的單帳戶頂層值移入 `channels.<channel>.accounts.default`，然後再寫入新帳戶。這樣可在移至多帳戶結構的同時保留原始帳戶行為。

路由行為保持一致：

- 現有的僅頻道綁定（無 `accountId`）繼續匹配預設帳戶。
- 在非互動模式中，`channels add` 不會自動建立或重寫綁定。
- 互動式設定可選擇性地新增帳戶範圍的綁定。

若您的設定已處於混合狀態（存在命名帳戶，缺少 `default`，且頂層單帳戶值仍設定），請執行 `openclaw doctor --fix` 將帳戶範圍值移入 `accounts.default`。

## 登入與登出（互動式）

```bash
openclaw channels login --channel whatsapp
openclaw channels logout --channel whatsapp
```

## 疑難排解

- 執行 `openclaw status --deep` 以進行全面探測。
- 使用 `openclaw doctor` 獲取引導式修復建議。
- `openclaw channels list` 顯示 `Claude: HTTP 403 ... user:profile` → usage snapshot 需要 `user:profile` 範圍。請使用 `--no-usage`，或提供 claude.ai session key（`CLAUDE_WEB_SESSION_KEY` / `CLAUDE_WEB_COOKIE`），或透過 Claude Code CLI 重新認證。
- 當 Gateway 無法連線時，`openclaw channels status` 會回退至僅基於設定的摘要。若支援的頻道憑證是透過 SecretRef 配置但在當前指令路徑中無法使用，它會將該帳戶報告為已配置但帶有降級說明，而非顯示為未配置。

## 功能探測

取得供應商功能提示（可用時的 intents/scopes）及靜態功能支援：

```bash
openclaw channels capabilities
openclaw channels capabilities --channel discord --target channel:123
```

注意事項：

- `--channel` 為選用參數；若省略則會列出所有頻道（包含擴充功能）。
- `--target` 接受 `channel:<id>` 或原始數字頻道 ID，且僅適用於 Discord。
- 探測因供應商而異：Discord intents + 可選頻道權限；Slack bot + user scopes；Telegram bot 旗標 + webhook；Signal daemon 版本；MS Teams app token + Graph roles/scopes（有標注已知者）。沒有探測的頻道會報告 `Probe: unavailable`。

## 名稱解析為 ID

透過供應商目錄將頻道/使用者名稱解析為 ID：

```bash
openclaw channels resolve --channel slack "#general" "@jane"
openclaw channels resolve --channel discord "My Server/#support" "@someone"
openclaw channels resolve --channel matrix "Project Room"
```

注意事項：

- 使用 `--kind user|group|auto` 可強制指定目標類型。
- 當多個條目共用相同名稱時，解析優先匹配活躍的條目。
- `channels resolve` 為唯讀操作。若選定的帳戶是透過 SecretRef 配置但在當前指令路徑中無法使用，指令會返回帶有說明的降級未解析結果，而非中止整個執行。
