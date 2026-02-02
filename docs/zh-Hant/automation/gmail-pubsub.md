---
title: "Gmail Pub/Sub"
summary: "Gmail Pub/Sub 推送經由 gogcli 接入 OpenClaw Webhook"
read_when:
  - 將 Gmail 收件匣觸發器接入 OpenClaw 時
  - 為 Agent 喚醒設定 Pub/Sub 推送時
---

# Gmail Pub/Sub -> OpenClaw

目標：Gmail watch -> Pub/Sub push -> `gog gmail watch serve` -> OpenClaw Webhook。

## 前置條件

- `gcloud` 已安裝且已登入（[安裝指南](https://docs.cloud.google.com/sdk/docs/install-sdk)）。
- `gog` (gogcli) 已安裝且授權給 Gmail 帳戶（[gogcli.sh](https://gogcli.sh/)）。
- OpenClaw Hooks 已啟用（見 [Webhooks](/automation/webhook)）。
- `tailscale` 已登入（[tailscale.com](https://tailscale.com/)）。支援的設定使用 Tailscale Funnel 作為公開 HTTPS 端點。
  其他隧道服務可以工作，但自行管理/不支援，需要手動接線。
  現在，Tailscale 是我們支援的內容。

範例 Hook 配置（啟用 Gmail 預設映射）：

```json5
{
  hooks: {
    enabled: true,
    token: "OPENCLAW_HOOK_TOKEN",
    path: "/hooks",
    presets: ["gmail"],
  },
}
```

若要將 Gmail 摘要投遞到聊天介面，請使用映射覆寫預設設定，該映射設定 `deliver` + 選用的 `channel`/`to`：

```json5
{
  hooks: {
    enabled: true,
    token: "OPENCLAW_HOOK_TOKEN",
    presets: ["gmail"],
    mappings: [
      {
        match: { path: "gmail" },
        action: "agent",
        wakeMode: "now",
        name: "Gmail",
        sessionKey: "hook:gmail:{{messages[0].id}}",
        messageTemplate: "New email from {{messages[0].from}}\nSubject: {{messages[0].subject}}\n{{messages[0].snippet}}\n{{messages[0].body}}",
        model: "openai/gpt-5.2-mini",
        deliver: true,
        channel: "last",
        // to: "+15551234567"
      },
    ],
  },
}
```

若您想要固定頻道，設定 `channel` + `to`。否則 `channel: "last"` 使用最後投遞路由（回退到 WhatsApp）。

若要為 Gmail 執行強制更便宜的模型，請在映射中設定 `model`（`provider/model` 或別名）。若您強制執行 `agents.defaults.models`，請將其包含在其中。

若要專門為 Gmail Hooks 設定預設模型和思考等級，請在設定中加入 `hooks.gmail.model` / `hooks.gmail.thinking`：

```json5
{
  hooks: {
    gmail: {
      model: "openrouter/meta-llama/llama-3.3-70b-instruct:free",
      thinking: "off",
    },
  },
}
```

備註：

- 映射中的各 Hook `model`/`thinking` 仍然覆寫這些預設。
- 回退順序：`hooks.gmail.model` → `agents.defaults.model.fallbacks` → primary (auth/rate-limit/timeouts)。
- 若設定了 `agents.defaults.models`，Gmail 模型必須在允許清單中。
- Gmail Hook 內容預設使用外部內容安全邊界進行包裝。
  若要禁用（危險），設定 `hooks.gmail.allowUnsafeExternalContent: true`。

若要進一步自訂 Payload 處理，請在設定中加入 `hooks.mappings` 或 JS/TS 轉換模組，位於 `hooks.transformsDir` 下（見 [Webhooks](/automation/webhook)）。

## 精靈（推薦）

使用 OpenClaw 助手將所有內容接線（在 macOS 上透過 brew 安裝 deps）：

```bash
openclaw webhooks gmail setup \
  --account openclaw@gmail.com
```

預設：

- 使用 Tailscale Funnel 作為公開推送端點。
- 寫入 `hooks.gmail` 設定供 `openclaw webhooks gmail run` 使用。
- 啟用 Gmail Hook 預設（`hooks.presets: ["gmail"]`）。

路徑備註：當啟用 `tailscale.mode` 時，OpenClaw 自動將 `hooks.gmail.serve.path` 設為 `/` 並將公開路徑保持在 `hooks.gmail.tailscale.path`（預設 `/gmail-pubsub`），因為 Tailscale 在代理前會移除設定路徑前綴。
若您需要後端接收前綴路徑，設定 `hooks.gmail.tailscale.target`（或 `--tailscale-target`）為完整 URL，例如 `http://127.0.0.1:8788/gmail-pubsub` 並符合 `hooks.gmail.serve.path`。

想要自訂端點？使用 `--push-endpoint <url>` 或 `--tailscale off`。

平台備註：在 macOS 上，精靈透過 Homebrew 安裝 `gcloud`、`gogcli` 和 `tailscale`；在 Linux 上先手動安裝它們。

Gateway 自動啟動（推薦）：

- 當 `hooks.enabled=true` 且設定了 `hooks.gmail.account` 時，Gateway 在啟動時啟動 `gog gmail watch serve` 並自動續訂監看。
- 設定 `OPENCLAW_SKIP_GMAIL_WATCHER=1` 以選擇不參與（若您自行執行守護程式很有用）。
- 不要同時執行手動守護程式，否則會遇到 `listen tcp 127.0.0.1:8788: bind: address already in use`。

手動守護程式（啟動 `gog gmail watch serve` + 自動續訂）：

```bash
openclaw webhooks gmail run
```

## 一次性設定

1. 選擇 GCP 專案 **擁有 `gog` 使用的 OAuth 客戶端**。

```bash
gcloud auth login
gcloud config set project <project-id>
```

備註：Gmail 監看要求 Pub/Sub 主題位於與 OAuth 客戶端相同的專案中。

2. 啟用 API：

```bash
gcloud services enable gmail.googleapis.com pubsub.googleapis.com
```

3. 建立主題：

```bash
gcloud pubsub topics create gog-gmail-watch
```

4. 允許 Gmail 推送發佈：

```bash
gcloud pubsub topics add-iam-policy-binding gog-gmail-watch \
  --member=serviceAccount:gmail-api-push@system.gserviceaccount.com \
  --role=roles/pubsub.publisher
```

## 啟動監看

```bash
gog gmail watch start \
  --account openclaw@gmail.com \
  --label INBOX \
  --topic projects/<project-id>/topics/gog-gmail-watch
```

從輸出中儲存 `history_id`（用於除錯）。

## 執行推送處理器

本地範例（共享 Token 認證）：

```bash
gog gmail watch serve \
  --account openclaw@gmail.com \
  --bind 127.0.0.1 \
  --port 8788 \
  --path /gmail-pubsub \
  --token <shared> \
  --hook-url http://127.0.0.1:18789/hooks/gmail \
  --hook-token OPENCLAW_HOOK_TOKEN \
  --include-body \
  --max-bytes 20000
```

備註：

- `--token` 保護推送端點（`x-gog-token` 或 `?token=`）。
- `--hook-url` 指向 OpenClaw `/hooks/gmail`（已映射；隔離執行 + 摘要至主會話）。
- `--include-body` 和 `--max-bytes` 控制傳送給 OpenClaw 的 Body 片段。

推薦：`openclaw webhooks gmail run` 包裝相同的流程並自動續訂監看。

## 公開處理器（進階、不支援）

若您需要非 Tailscale 隧道，手動接線並在推送訂閱中使用公開 URL（不支援、無保障）：

```bash
cloudflared tunnel --url http://127.0.0.1:8788 --no-autoupdate
```

使用產生的 URL 作為推送端點：

```bash
gcloud pubsub subscriptions create gog-gmail-watch-push \
  --topic gog-gmail-watch \
  --push-endpoint "https://<public-url>/gmail-pubsub?token=<shared>"
```

生產：使用穩定的 HTTPS 端點並設定 Pub/Sub OIDC JWT，然後執行：

```bash
gog gmail watch serve --verify-oidc --oidc-email <svc@...>
```

## 測試

傳送訊息到受監看的收件匣：

```bash
gog gmail send \
  --account openclaw@gmail.com \
  --to openclaw@gmail.com \
  --subject "watch test" \
  --body "ping"
```

檢查監看狀態和歷史：

```bash
gog gmail watch status --account openclaw@gmail.com
gog gmail history --account openclaw@gmail.com --since <historyId>
```

## 故障排除

- `Invalid topicName`：專案不符（主題不在 OAuth 客戶端專案中）。
- `User not authorized`：主題上遺失 `roles/pubsub.publisher`。
- 空訊息：Gmail 推送僅提供 `historyId`；透過 `gog gmail history` 擷取。

## 清理

```bash
gog gmail watch stop --account openclaw@gmail.com
gcloud pubsub subscriptions delete gog-gmail-watch-push
gcloud pubsub topics delete gog-gmail-watch
```
