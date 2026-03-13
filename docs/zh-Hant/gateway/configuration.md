---
summary: "組態概覽：常見任務、快速設定和完整參考的連結"
read_when:
  - 首次設定 OpenClaw
  - 尋找常見組態模式
  - 導航至特定組態部分
title: "Configuration（組態）"
---

# Configuration（組態）

OpenClaw 從 `~/.openclaw/openclaw.json` 讀取選擇性的 <Tooltip tip="JSON5 支援註解和結尾逗號">**JSON5**</Tooltip> 組態。

若檔案遺失，OpenClaw 使用安全預設值。新增組態的常見原因：

- 連接頻道並控制誰可以傳訊機器人
- 設定模型、工具、沙盒或自動化 (cron, hooks)
- 調整會話、媒體、網路或 UI

見 [完整參考](/zh-Hant/gateway/configuration-reference) 以取得所有可用欄位。

<Tip>
**新到組態嗎？** 使用 `openclaw onboard` 進行互動式設定，或查看 [Configuration Examples](/zh-Hant/gateway/configuration-examples) 指南以取得完整複製貼上組態。
</Tip>

## Minimal config（最小組態）

```json5
// ~/.openclaw/openclaw.json
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } },
  channels: { whatsapp: { allowFrom: ["+15555550123"] } },
}
```

## Editing config（編輯組態）

<Tabs>
  <Tab title="互動式精靈">
    ```bash
    openclaw onboard       # 完整設定精靈
    openclaw configure     # 組態精靈
    ```
  </Tab>
  <Tab title="CLI（單行）">
    ```bash
    openclaw config get agents.defaults.workspace
    openclaw config set agents.defaults.heartbeat.every "2h"
    openclaw config unset tools.web.search.apiKey
    ```
  </Tab>
  <Tab title="Control UI">
    開啟 [http://127.0.0.1:18789](http://127.0.0.1:18789) 並使用 **Config** 標籤。
    Control UI 從組態 schema 渲染表單，搭配**原始 JSON** 編輯器作為逃生艙。
  </Tab>
  <Tab title="直接編輯">
    直接編輯 `~/.openclaw/openclaw.json`。Gateway 監視檔案並自動應用改變（見 [hot reload](#config-hot-reload)）。
  </Tab>
</Tabs>

## Strict validation（嚴格驗證）

<Warning>
OpenClaw 僅接受完全符合 schema 的組態。未知鑰匙、格式錯誤的類型或無效值導致 Gateway **拒絕啟動**。唯一的根層級例外是 `$schema`（字串），以便編輯器可附加 JSON Schema 元資料。
</Warning>

當驗證失敗時：

- Gateway 不啟動
- 僅允許診斷指令（`openclaw doctor`、`openclaw logs`、`openclaw health`、`openclaw status`）
- 執行 `openclaw doctor` 查看確切問題
- 執行 `openclaw doctor --fix`（或 `--yes`）以應用修復

## Common tasks（常見任務）

<AccordionGroup>
  <Accordion title="設定頻道 (WhatsApp, Telegram, Discord 等)">
    每個頻道在 `channels.<provider>` 下有自己的組態部分。見相關頻道頁面取得設定步驟：

    - [WhatsApp](/zh-Hant/channels/whatsapp) — `channels.whatsapp`
    - [Telegram](/zh-Hant/channels/telegram) — `channels.telegram`
    - [Discord](/zh-Hant/channels/discord) — `channels.discord`
    - [Slack](/zh-Hant/channels/slack) — `channels.slack`
    - [Signal](/zh-Hant/channels/signal) — `channels.signal`
    - [iMessage](/zh-Hant/channels/imessage) — `channels.imessage`
    - [Google Chat](/zh-Hant/channels/googlechat) — `channels.googlechat`
    - [Mattermost](/zh-Hant/channels/mattermost) — `channels.mattermost`
    - [MS Teams](/zh-Hant/channels/msteams) — `channels.msteams`

    所有頻道共享相同 DM 原則模式：

    ```json5
    {
      channels: {
        telegram: {
          enabled: true,
          botToken: "123:abc",
          dmPolicy: "pairing",   // pairing | allowlist | open | disabled
          allowFrom: ["tg:123"], // 僅用於 allowlist/open
        },
      },
    }
    ```

  </Accordion>

  <Accordion title="選擇並組態模型">
    設定主要模型和選擇性備用：

    ```json5
    {
      agents: {
        defaults: {
          model: {
            primary: "anthropic/claude-sonnet-4-5",
            fallbacks: ["openai/gpt-5.2"],
          },
          models: {
            "anthropic/claude-sonnet-4-5": { alias: "Sonnet" },
            "openai/gpt-5.2": { alias: "GPT" },
          },
        },
      },
    }
    ```

    - `agents.defaults.models` 定義模型目錄並充當 `/model` 的 allowlist。
    - 模型參考使用 `provider/model` 格式（例 `anthropic/claude-opus-4-6`）。
    - `agents.defaults.imageMaxDimensionPx` 控制轉錄/工具圖片降尺度（預設 `1200`）；較低值通常降低 screenshot 密集執行的 vision-token 用量。
    - 見 [Models CLI](/zh-Hant/concepts/models) 以在聊天中切換模型，以及 [Model Failover](/zh-Hant/concepts/model-failover) 用於驗證輪換和備用行為。
    - 對於自訂/自架提供商，見參考中的 [Custom providers](/zh-Hant/gateway/configuration-reference#custom-providers-and-base-urls)。

  </Accordion>

  <Accordion title="控制誰可傳訊機器人">
    DM 存取透過 `dmPolicy` 按頻道控制：

    - `"pairing"`（預設）：未知傳送者取得一次性配對代碼以核准
    - `"allowlist"`：僅 `allowFrom` 中的傳送者（或配對允許存儲）
    - `"open"`：允許所有入站 DM（需要 `allowFrom: ["*"]`）
    - `"disabled"`：忽略所有 DM

    對於群組，使用 `groupPolicy` + `groupAllowFrom` 或頻道特定 allowlist。

    見 [完整參考](/zh-Hant/gateway/configuration-reference#dm-and-group-access) 以取得按頻道詳情。

  </Accordion>

  <Accordion title="設定群組聊天提及門控">
    群組訊息預設**需要提及**。按 agent 設定模式：

    ```json5
    {
      agents: {
        list: [
          {
            id: "main",
            groupChat: {
              mentionPatterns: ["@openclaw", "openclaw"],
            },
          },
        ],
      },
      channels: {
        whatsapp: {
          groups: { "*": { requireMention: true } },
        },
      },
    }
    ```

    - **Metadata mentions（元資料提及）**：原生 @-提及 (WhatsApp tap-to-mention, Telegram @bot 等)
    - **Text patterns（文字模式）**：`mentionPatterns` 中的 regex 模式
    - 見 [完整參考](/zh-Hant/gateway/configuration-reference#group-chat-mention-gating) 以取得按頻道覆寫和自聊模式。

  </Accordion>

  <Accordion title="組態會話和重設">
    會話控制對話連續性和隔離：

    ```json5
    {
      session: {
        dmScope: "per-channel-peer",  // 多使用者推薦
        threadBindings: {
          enabled: true,
          idleHours: 24,
          maxAgeHours: 0,
        },
        reset: {
          mode: "daily",
          atHour: 4,
          idleMinutes: 120,
        },
      },
    }
    ```

    - `dmScope`：`main`（共享）| `per-peer` | `per-channel-peer` | `per-account-channel-peer`
    - `threadBindings`：執行緒綁定會話路由的全域預設（Discord 支援 `/focus`、`/unfocus`、`/agents`、`/session idle` 和 `/session max-age`）。
    - 見 [Session Management](/zh-Hant/concepts/session) 以取得作用域、身份連結和發送原則。
    - 見 [完整參考](/zh-Hant/gateway/configuration-reference#session) 以取得所有欄位。

  </Accordion>

  <Accordion title="啟用沙盒">
    在隔離 Docker 容器中執行 agent 會話：

    ```json5
    {
      agents: {
        defaults: {
          sandbox: {
            mode: "non-main",  // off | non-main | all
            scope: "agent",    // session | agent | shared
          },
        },
      },
    }
    ```

    首先建置映像：`scripts/sandbox-setup.sh`

    見 [Sandboxing](/zh-Hant/gateway/sandboxing) 取得完整指南，以及 [完整參考](/zh-Hant/gateway/configuration-reference#sandbox) 取得所有選項。

  </Accordion>

  <Accordion title="為官方 iOS 建置啟用 relay-backed push">
    Relay-backed push 在 `openclaw.json` 中組態。

    在 Gateway 組態中設定：

    ```json5
    {
      gateway: {
        push: {
          apns: {
            relay: {
              baseUrl: "https://relay.example.com",
              // 可選。預設：10000
              timeoutMs: 10000,
            },
          },
        },
      },
    }
    ```

    CLI 等效：

    ```bash
    openclaw config set gateway.push.apns.relay.baseUrl https://relay.example.com
    ```

    這做什麼：

    - 讓 Gateway 透過外部 relay 發送 `push.test`、wake nudges 和 reconnect wakes。
    - 使用由配對 iOS 應用轉寄的註冊作用域發送授權。Gateway 不需要部署寬 relay token。
    - 將每個 relay-backed 註冊綁定到 iOS 應用配對的 Gateway 身份，以便另一 Gateway 無法重用儲存的註冊。
    - 保持本地/手動 iOS 建置在直接 APNs 上。Relay-backed 發送僅適用於透過 relay 註冊的官方分佈建置。
    - 必須符合官方/TestFlight iOS 建置中烤入的 relay base URL，以便註冊和發送流量到達相同 relay 部署。

    端到端流程：

    1. 安裝使用相同 relay base URL 編譯的官方/TestFlight iOS 建置。
    2. 在 Gateway 上組態 `gateway.push.apns.relay.baseUrl`。
    3. 配對 iOS 應用到 Gateway，讓兩節點和操作者會話連接。
    4. iOS 應用獲取 Gateway 身份、使用 App Attest 加上應用收據向 relay 註冊，然後發布 relay-backed `push.apns.register` 負載到配對 Gateway。
    5. Gateway 儲存 relay 處理和發送授權，然後為 `push.test`、wake nudges 和 reconnect wakes 使用它們。

    操作備註：

    - 若切換 iOS 應用到不同 Gateway，重新連接應用使其發布綁定到該 Gateway 的新 relay 註冊。
    - 若發布指向不同 relay 部署的新 iOS 建置，應用刷新其快取 relay 註冊，而非重用舊 relay origin。

    相容性備註：

    - `OPENCLAW_APNS_RELAY_BASE_URL` 和 `OPENCLAW_APNS_RELAY_TIMEOUT_MS` 仍作為臨時 env 覆寫運作。
    - `OPENCLAW_APNS_RELAY_ALLOW_HTTP=true` 仍為 loopback-only 開發逃生艙；不要在組態中持久化 HTTP relay URL。

    見 [iOS App](/zh-Hant/platforms/ios#relay-backed-push-for-official-builds) 以取得端到端流程，以及 [Authentication and trust flow](/zh-Hant/platforms/ios#authentication-and-trust-flow) 以取得 relay 安全模型。

  </Accordion>

  <Accordion title="設定心跳（定期檢查）">
    ```json5
    {
      agents: {
        defaults: {
          heartbeat: {
            every: "30m",
            target: "last",
          },
        },
      },
    }
    ```

    - `every`：時間長度字串（`30m`、`2h`）。設定 `0m` 以停用。
    - `target`：`last` | `whatsapp` | `telegram` | `discord` | `none`
    - `directPolicy`：DM-style 心跳目標的 `allow`（預設）或 `block`
    - 見 [Heartbeat](/zh-Hant/gateway/heartbeat) 以取得完整指南。

  </Accordion>

  <Accordion title="組態 cron 工作">
    ```json5
    {
      cron: {
        enabled: true,
        maxConcurrentRuns: 2,
        sessionRetention: "24h",
        runLog: {
          maxBytes: "2mb",
          keepLines: 2000,
        },
      },
    }
    ```

    - `sessionRetention`：從 `sessions.json` prune 已完成隔離執行會話（預設 `24h`；設定 `false` 以停用）。
    - `runLog`：按大小和保留行 prune `cron/runs/<jobId>.jsonl`。
    - 見 [Cron jobs](/zh-Hant/automation/cron-jobs) 以取得功能概覽和 CLI 範例。

  </Accordion>

  <Accordion title="設定 webhooks (hooks)">
    在 Gateway 上啟用 HTTP webhook 端點：

    ```json5
    {
      hooks: {
        enabled: true,
        token: "shared-secret",
        path: "/hooks",
        defaultSessionKey: "hook:ingress",
        allowRequestSessionKey: false,
        allowedSessionKeyPrefixes: ["hook:"],
        mappings: [
          {
            match: { path: "gmail" },
            action: "agent",
            agentId: "main",
            deliver: true,
          },
        ],
      },
    }
    ```

    安全備註：
    - 將所有 hook/webhook 負載內容視為不受信任的輸入。
    - 保持不安全內容設定停用（`hooks.gmail.allowUnsafeExternalContent`、`hooks.mappings[].allowUnsafeExternalContent`），除非進行緊密作用域調試。
    - 對於 hook-driven agents，偏好強大的現代模型層級和嚴格工具原則（例如僅傳訊加沙盒（可能））。

    見 [完整參考](/zh-Hant/gateway/configuration-reference#hooks) 以取得所有映射選項和 Gmail 整合。

  </Accordion>

  <Accordion title="組態多代理路由">
    執行多個具獨立工作區和會話的隔離 agents：

    ```json5
    {
      agents: {
        list: [
          { id: "home", default: true, workspace: "~/.openclaw/workspace-home" },
          { id: "work", workspace: "~/.openclaw/workspace-work" },
        ],
      },
      bindings: [
        { agentId: "home", match: { channel: "whatsapp", accountId: "personal" } },
        { agentId: "work", match: { channel: "whatsapp", accountId: "biz" } },
      ],
    }
    ```

    見 [Multi-Agent](/zh-Hant/concepts/multi-agent) 和 [完整參考](/zh-Hant/gateway/configuration-reference#multi-agent-routing) 以取得綁定規則和按 agent 存取設定檔。

  </Accordion>

  <Accordion title="將組態分割成多個檔案 ($include)">
    使用 `$include` 組織大型組態：

    ```json5
    // ~/.openclaw/openclaw.json
    {
      gateway: { port: 18789 },
      agents: { $include: "./agents.json5" },
      broadcast: {
        $include: ["./clients/a.json5", "./clients/b.json5"],
      },
    }
    ```

    - **Single file（單一檔案）**：替換包含的物件
    - **Array of files（檔案陣列）**：按順序深度合併（較晚優先）
    - **Sibling keys（同層鑰匙）**：在包含後合併（覆寫包含的值）
    - **Nested includes（嵌套包含）**：支援至 10 層深
    - **Relative paths（相對路徑）**：相對於包含檔案解析
    - **Error handling（錯誤處理）**：遺失檔案、解析錯誤和循環包含的清晰錯誤

  </Accordion>
</AccordionGroup>

## Config hot reload（組態熱重載）

Gateway 監視 `~/.openclaw/openclaw.json` 並自動應用改變 — 大多數設定無需手動重啟。

### Reload modes（重載模式）

| Mode                 | Behavior                                          |
| -------------------- | ------------------------------------------------- |
| **`hybrid`**（預設） | 熱應用安全改變即刻。自動重啟關鍵改變。            |
| **`hot`**            | 僅熱應用安全改變。當需要重啟時記錄警告 — 你處理。 |
| **`restart`**        | 任何組態改變重啟 Gateway，安全或不。              |
| **`off`**            | 停用檔案監視。改變在下次手動重啟時生效。          |

```json5
{
  gateway: {
    reload: { mode: "hybrid", debounceMs: 300 },
  },
}
```

### What hot-applies vs what needs a restart（什麼熱應用，什麼需要重啟）

大多數欄位熱應用無停機。在 `hybrid` 模式，需要重啟改變自動處理。

| Category                          | Fields                                                | Restart needed? |
| --------------------------------- | ----------------------------------------------------- | --------------- |
| Channels（頻道）                  | `channels.*`、`web`（WhatsApp）— 所有內建和擴展頻道   | 否              |
| Agent & models（Agent 和模型）    | `agent`、`agents`、`models`、`routing`                | 否              |
| Automation（自動化）              | `hooks`、`cron`、`agent.heartbeat`                    | 否              |
| Sessions & messages（會話和訊息） | `session`、`messages`                                 | 否              |
| Tools & media（工具和媒體）       | `tools`、`browser`、`skills`、`audio`、`talk`         | 否              |
| UI & misc（UI 和雜項）            | `ui`、`logging`、`identity`、`bindings`               | 否              |
| Gateway server（Gateway 伺服器）  | `gateway.*`（port, bind, auth, tailscale, TLS, HTTP） | **是**          |
| Infrastructure（基礎設施）        | `discovery`、`canvasHost`、`plugins`                  | **是**          |

<Note>
`gateway.reload` 和 `gateway.remote` 為例外 — 改變它們**不**觸發重啟。
</Note>

## Config RPC（程式化更新）

<Note>
控制平面寫 RPC（`config.apply`、`config.patch`、`update.run`）速率限制為每 `deviceId+clientIp` 每 60 秒 **3 個請求**。受限時，RPC 返回 `UNAVAILABLE` 搭配 `retryAfterMs`。
</Note>

<AccordionGroup>
  <Accordion title="config.apply（完全替換）">
    驗證 + 寫入完整組態並在一步驟內重啟 Gateway。

    <Warning>
    `config.apply` 替換**整個組態**。使用 `config.patch` 進行部分更新，或 `openclaw config set` 用於單一鑰匙。
    </Warning>

    參數：

    - `raw`（字串）— 整個組態的 JSON5 負載
    - `baseHash`（可選）— 來自 `config.get` 的組態雜湊（組態存在時必需）
    - `sessionKey`（可選）— 重啟後喚醒 ping 的會話鑰匙
    - `note`（可選）— 重啟 sentinel 的備註
    - `restartDelayMs`（可選）— 重啟前延遲（預設 2000）

    重啟要求在已掛起/飛行中時合併，且 30 秒冷卻適用於重啟週期間。

    ```bash
    openclaw gateway call config.get --params '{}'  # capture payload.hash
    openclaw gateway call config.apply --params '{
      "raw": "{ agents: { defaults: { workspace: \"~/.openclaw/workspace\" } } }",
      "baseHash": "<hash>",
      "sessionKey": "agent:main:whatsapp:dm:+15555550123"
    }'
    ```

  </Accordion>

  <Accordion title="config.patch（部分更新）">
    合併部分更新至現有組態（JSON merge patch 語意）：

    - 物件遞迴合併
    - `null` 刪除鑰匙
    - 陣列替換

    參數：

    - `raw`（字串）— 僅包含要改變鑰匙的 JSON5
    - `baseHash`（必需）— 來自 `config.get` 的組態雜湊
    - `sessionKey`、`note`、`restartDelayMs` — 與 `config.apply` 相同

    重啟行為符合 `config.apply`：合併掛起重啟加 30 秒冷卻於重啟週期間。

    ```bash
    openclaw gateway call config.patch --params '{
      "raw": "{ channels: { telegram: { groups: { \"*\": { requireMention: false } } } } }",
      "baseHash": "<hash>"
    }'
    ```

  </Accordion>
</AccordionGroup>

## Environment variables（環境變數）

OpenClaw 從親進程讀取 env vars 加：

- `.env` 從現行工作目錄（若存在）
- `~/.openclaw/.env`（全域備用）

兩檔都不覆寫現存 env vars。你也可在組態中設定內聯 env vars：

```json5
{
  env: {
    OPENROUTER_API_KEY: "sk-or-...",
    vars: { GROQ_API_KEY: "gsk-..." },
  },
}
```

<Accordion title="Shell env import（可選）">
  若啟用且預期鑰匙未設定，OpenClaw 執行你的登入 shell 並僅匯入遺漏的鑰匙：

```json5
{
  env: {
    shellEnv: { enabled: true, timeoutMs: 15000 },
  },
}
```

Env var 等效：`OPENCLAW_LOAD_SHELL_ENV=1`
</Accordion>

<Accordion title="Env var substitution in config values（組態值中的 Env var 替換）">
  使用 `${VAR_NAME}` 在任何組態字串值中參考 env vars：

```json5
{
  gateway: { auth: { token: "${OPENCLAW_GATEWAY_TOKEN}" } },
  models: { providers: { custom: { apiKey: "${CUSTOM_API_KEY}" } } },
}
```

規則：

- 僅大寫名稱符合：`[A-Z_][A-Z0-9_]*`
- 遺失/空 vars 在載入時拋出錯誤
- 使用 `$${VAR}` 逃離以獲取字面輸出
- 在 `$include` 檔中運作
- 內聯替換：`"${BASE}/v1"` → `"https://api.example.com/v1"`

</Accordion>

<Accordion title="Secret refs（env, file, exec）">
  對於支援 SecretRef 物件的欄位，你可使用：

```json5
{
  models: {
    providers: {
      openai: { apiKey: { source: "env", provider: "default", id: "OPENAI_API_KEY" } },
    },
  },
  skills: {
    entries: {
      "nano-banana-pro": {
        apiKey: {
          source: "file",
          provider: "filemain",
          id: "/skills/entries/nano-banana-pro/apiKey",
        },
      },
    },
  },
  channels: {
    googlechat: {
      serviceAccountRef: {
        source: "exec",
        provider: "vault",
        id: "channels/googlechat/serviceAccount",
      },
    },
  },
}
```

SecretRef 詳情（包括 `env`/`file`/`exec` 的 `secrets.providers`）在 [Secrets Management](/zh-Hant/gateway/secrets) 中。
支援的憑證路徑列在 [SecretRef Credential Surface](/zh-Hant/reference/secretref-credential-surface) 中。
</Accordion>

見 [Environment](/zh-Hant/help/environment) 以取得完整優先順序和來源。

## Full reference（完整參考）

如需完整欄位對欄位參考，見 **[Configuration Reference](/zh-Hant/gateway/configuration-reference)**。

---

_Related: [Configuration Examples](/zh-Hant/gateway/configuration-examples) · [Configuration Reference](/zh-Hant/gateway/configuration-reference) · [Doctor](/zh-Hant/gateway/doctor)_
