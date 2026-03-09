---
summary: "`openclaw onboard` CLI 參考（互動式新手導覽精靈）"
read_when:
  - 想要針對 gateway、工作區、認證、頻道和技能進行引導式設定時
title: "onboard（新手導覽精靈）"
---

# `openclaw onboard`

互動式新手導覽精靈（本地或遠端 Gateway 設定）。

## 相關指南

- CLI 新手導覽中心：[Onboarding Wizard (CLI)](/zh-Hant/start/wizard)
- 新手導覽總覽：[Onboarding Overview](/zh-Hant/start/onboarding-overview)
- CLI 新手導覽參考：[CLI Onboarding Reference](/zh-Hant/start/wizard-cli-reference)
- CLI 自動化：[CLI Automation](/zh-Hant/start/wizard-cli-automation)
- macOS 新手導覽：[Onboarding (macOS App)](/zh-Hant/start/onboarding)

## 範例

```bash
openclaw onboard
openclaw onboard --flow quickstart
openclaw onboard --flow manual
openclaw onboard --mode remote --remote-url wss://gateway-host:18789
```

若要連線至私有網路的純文字 `ws://` 目標（僅限受信任網路），請在新手導覽進程環境中設定
`OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1`。

非互動式自訂供應商：

```bash
openclaw onboard --non-interactive \
  --auth-choice custom-api-key \
  --custom-base-url "https://llm.example.com/v1" \
  --custom-model-id "foo-large" \
  --custom-api-key "$CUSTOM_API_KEY" \
  --secret-input-mode plaintext \
  --custom-compatibility openai
```

在非互動模式中，`--custom-api-key` 為選用。若省略，新手導覽會檢查 `CUSTOM_API_KEY`。

以 refs 而非明文儲存供應商金鑰：

```bash
openclaw onboard --non-interactive \
  --auth-choice openai-api-key \
  --secret-input-mode ref \
  --accept-risk
```

使用 `--secret-input-mode ref` 時，新手導覽會寫入 env 支援的 refs 而非明文金鑰值。
對於認證設定檔支援的供應商，這會寫入 `keyRef` 條目；對於自訂供應商，這會將 `models.providers.<id>.apiKey` 寫入為 env ref（例如 `{ source: "env", provider: "default", id: "CUSTOM_API_KEY" }`）。

非互動 `ref` 模式規範：

- 在新手導覽進程環境中設定供應商 env var（例如 `OPENAI_API_KEY`）。
- 除非該 env var 也已設定，否則不要傳遞內聯金鑰旗標（例如 `--openai-api-key`）。
- 若傳遞了內聯金鑰旗標但沒有必要的 env var，新手導覽會快速失敗並提供指引。

非互動模式中的 Gateway token 選項：

- `--gateway-auth token --gateway-token <token>` 儲存明文 token。
- `--gateway-auth token --gateway-token-ref-env <name>` 將 `gateway.auth.token` 儲存為 env SecretRef。
- `--gateway-token` 和 `--gateway-token-ref-env` 互斥。
- `--gateway-token-ref-env` 需要新手導覽進程環境中有非空的 env var。
- 使用 `--install-daemon` 時，當 token 認證需要 token，SecretRef 管理的 gateway tokens 會被驗證但不以解析後的明文儲存至監督服務環境中繼資料。
- 使用 `--install-daemon` 時，若 token 模式需要 token 且配置的 token SecretRef 未解析，新手導覽會快速失敗並提供修復指引。
- 使用 `--install-daemon` 時，若 `gateway.auth.token` 和 `gateway.auth.password` 均已配置且 `gateway.auth.mode` 未設定，新手導覽會阻止安裝直到明確設定 mode 為止。

範例：

```bash
export OPENCLAW_GATEWAY_TOKEN="your-token"
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice skip \
  --gateway-auth token \
  --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --accept-risk
```

使用 reference 模式的互動式新手導覽行為：

- 在提示時選擇 **Use secret reference**。
- 然後選擇：
  - 環境變數
  - 已配置的 secret 供應商（`file` 或 `exec`）
- 新手導覽在儲存 ref 前執行快速預檢驗證。
  - 若驗證失敗，新手導覽顯示錯誤並讓您重試。

非互動式 Z.AI 端點選項：

注意：`--auth-choice zai-api-key` 現在自動偵測您金鑰的最佳 Z.AI 端點（優先使用含 `zai/glm-5` 的通用 API）。
若您特別需要 GLM Coding Plan 端點，請選擇 `zai-coding-global` 或 `zai-coding-cn`。

```bash
# 無提示的端點選擇
openclaw onboard --non-interactive \
  --auth-choice zai-coding-global \
  --zai-api-key "$ZAI_API_KEY"

# 其他 Z.AI 端點選項：
# --auth-choice zai-coding-cn
# --auth-choice zai-global
# --auth-choice zai-cn
```

非互動式 Mistral 範例：

```bash
openclaw onboard --non-interactive \
  --auth-choice mistral-api-key \
  --mistral-api-key "$MISTRAL_API_KEY"
```

流程注意事項：

- `quickstart`：最少提示，自動生成 gateway token。
- `manual`：完整的連接埠/綁定/認證提示（`advanced` 的別名）。
- 本地新手導覽 DM 範圍行為：[CLI Onboarding Reference](/zh-Hant/start/wizard-cli-reference#outputs-and-internals)。
- 最快首聊：`openclaw dashboard`（控制 UI，無需頻道設定）。
- 自訂供應商：連接任何 OpenAI 或 Anthropic 相容的端點，
  包括未列出的託管供應商。使用 Unknown 自動偵測。

## 常見後續指令

```bash
openclaw configure
openclaw agents add <name>
```

<Note>
`--json` 並不隱含非互動模式。請使用 `--non-interactive` 供腳本使用。
</Note>
