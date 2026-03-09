---
summary: "`openclaw models` CLI 參考（狀態、列表、設定、掃描、別名、fallbacks、認證）"
read_when:
  - 想要變更預設模型或查看供應商認證狀態時
  - 想要掃描可用模型/供應商並偵錯認證設定檔時
title: "models（模型配置）"
---

# `openclaw models`

模型探索、掃描和配置（預設模型、fallbacks、認證設定檔）。

相關資訊：

- 供應商 + 模型：[Models](/zh-Hant/providers/models)
- 供應商認證設定：[Getting started](/zh-Hant/start/getting-started)

## 常見指令

```bash
openclaw models status
openclaw models list
openclaw models set <model-or-alias>
openclaw models scan
```

`openclaw models status` 顯示解析後的預設/fallbacks 及認證總覽。
當供應商使用量快照可用時，OAuth/token 狀態區段包含
供應商使用量標頭。
加上 `--probe` 可針對每個已配置的供應商設定檔執行實時認證探測。
探測是真實請求（可能消耗 tokens 並觸發速率限制）。
使用 `--agent <id>` 查看已配置 agent 的模型/認證狀態。若省略，
指令使用 `OPENCLAW_AGENT_DIR`/`PI_CODING_AGENT_DIR`（若已設定），否則使用
已配置的預設 agent。

注意事項：

- `models set <model-or-alias>` 接受 `provider/model` 或別名。
- 模型 refs 以**第一個** `/` 分割解析。若模型 ID 包含 `/`（OpenRouter 格式），請包含供應商前綴（例如：`openrouter/moonshotai/kimi-k2`）。
- 若省略供應商，OpenClaw 將輸入視為別名或**預設供應商**的模型（僅在模型 ID 不含 `/` 時有效）。
- `models status` 可能在認證輸出中顯示 `marker(<value>)`，用於非機密佔位符（例如 `OPENAI_API_KEY`、`secretref-managed`、`minimax-oauth`、`qwen-oauth`、`ollama-local`），而非將其遮罩為機密。

### `models status`

選項：

- `--json`
- `--plain`
- `--check`（退出 1=過期/缺失，2=即將過期）
- `--probe`（對已配置的認證設定檔進行實時探測）
- `--probe-provider <name>`（探測單一供應商）
- `--probe-profile <id>`（重複或逗號分隔的設定檔 IDs）
- `--probe-timeout <ms>`
- `--probe-concurrency <n>`
- `--probe-max-tokens <n>`
- `--agent <id>`（已配置的 agent ID；覆寫 `OPENCLAW_AGENT_DIR`/`PI_CODING_AGENT_DIR`）

## 別名 + Fallbacks

```bash
openclaw models aliases list
openclaw models fallbacks list
```

## 認證設定檔

```bash
openclaw models auth add
openclaw models auth login --provider <id>
openclaw models auth setup-token
openclaw models auth paste-token
```

`models auth login` 執行供應商 plugin 的認證流程（OAuth/API key）。使用
`openclaw plugins list` 查看已安裝的供應商。

注意事項：

- `setup-token` 提示輸入 setup-token 值（在任何機器上使用 `claude setup-token` 生成）。
- `paste-token` 接受在其他地方或自動化生成的 token 字串。
- Anthropic 政策注意：setup-token 支援是技術相容性。Anthropic 過去已封鎖部分在 Claude Code 以外的訂閱使用，請在廣泛使用前確認目前的條款。
