---
title: "Models CLI（模型）"
summary: "模型 CLI：list、set、aliases、fallbacks、scan、status"
read_when:
  - 新增或修改模型 CLI（models list/set/scan/aliases/fallbacks）
  - 變更模型備用行為或選擇 UX
  - 更新模型掃描探針（tools/images）
---

# Models CLI

關於驗證設定檔輪換、冷卻時間及其與備用的交互，請見 [/concepts/model-failover](/zh-Hant/concepts/model-failover)。
供應商快速概覽 + 範例：[/concepts/model-providers](/zh-Hant/concepts/model-providers)。

## 模型選擇運作方式

OpenClaw 依此順序選擇模型：

1. **Primary** 模型（`agents.defaults.model.primary` 或 `agents.defaults.model`）。
2. `agents.defaults.model.fallbacks` 中的**備用模型**（依序）。
3. **Provider 驗證備用**在移至下一個模型前於供應商內部發生。

相關：

- `agents.defaults.models` 是 OpenClaw 可使用的模型 allowlist/catalog（加上別名）。
- `agents.defaults.imageModel` **僅在** primary 模型無法接受圖片時使用。
- 每個 agent 的預設值可透過 `agents.list[].model` 加上 bindings 覆蓋 `agents.defaults.model`（見 [/concepts/multi-agent](/zh-Hant/concepts/multi-agent)）。

## 快速模型政策

- 將 primary 設定為你可用的最強大的最新一代模型。
- 使用備用模型處理對成本/延遲敏感的任務和低風險聊天。
- 對於啟用工具的 agent 或不受信任的輸入，避免使用較舊/較弱的模型層級。

## 設定精靈（推薦）

若你不想手動編輯設定，執行引導精靈：

```bash
openclaw onboard
```

它可以為常見供應商設定模型 + 驗證，包括 **OpenAI Code（Codex）訂閱**（OAuth）和 **Anthropic**（API key 或 `claude setup-token`）。

## 設定 key（概覽）

- `agents.defaults.model.primary` 和 `agents.defaults.model.fallbacks`
- `agents.defaults.imageModel.primary` 和 `agents.defaults.imageModel.fallbacks`
- `agents.defaults.models`（allowlist + 別名 + provider 參數）
- `models.providers`（寫入 `models.json` 的自訂供應商）

模型參考會正規化為小寫。供應商別名如 `z.ai/*` 會正規化為 `zai/*`。

供應商設定範例（包含 OpenCode Zen）位於
[/gateway/configuration](/zh-Hant/gateway/configuration#opencode-zen-multi-model-proxy)。

## 「Model is not allowed」（以及為何回覆停止）

若設定了 `agents.defaults.models`，它成為 `/model` 和工作階段覆蓋的 **allowlist**。當用戶選擇不在 allowlist 中的模型時，
OpenClaw 返回：

```
Model "provider/model" is not allowed. Use /model to list available models.
```

這發生在**正常回覆生成之前**，所以訊息可能感覺像「沒有回應」。修復方法：

- 將模型新增到 `agents.defaults.models`，或
- 清除 allowlist（移除 `agents.defaults.models`），或
- 從 `/model list` 選擇一個模型。

Allowlist 設定範例：

```json5
{
  agent: {
    model: { primary: "anthropic/claude-sonnet-4-5" },
    models: {
      "anthropic/claude-sonnet-4-5": { alias: "Sonnet" },
      "anthropic/claude-opus-4-6": { alias: "Opus" },
    },
  },
}
```

## 在聊天中切換模型（`/model`）

你可以在不重啟的情況下切換當前工作階段的模型：

```
/model
/model list
/model 3
/model openai/gpt-5.2
/model status
```

注意：

- `/model`（和 `/model list`）是緊湊的編號選擇器（模型系列 + 可用供應商）。
- 在 Discord 上，`/model` 和 `/models` 開啟互動選擇器，包含供應商和模型下拉選單以及提交步驟。
- `/model <#>` 從選擇器中選取。
- `/model status` 是詳細視圖（驗證候選項以及設定時的供應商端點 `baseUrl` + `api` 模式）。
- 模型參考透過在**第一個** `/` 處分割來解析。輸入 `/model <ref>` 時使用 `provider/model`。
- 若模型 ID 本身包含 `/`（OpenRouter 風格），必須包含供應商前綴（例如：`/model openrouter/moonshotai/kimi-k2`）。
- 若省略供應商，OpenClaw 將輸入視為別名或**預設供應商**的模型（僅當模型 ID 中沒有 `/` 時有效）。

完整指令行為/設定：[Slash commands](/zh-Hant/tools/slash-commands)。

## CLI 指令

```bash
openclaw models list
openclaw models status
openclaw models set <provider/model>
openclaw models set-image <provider/model>

openclaw models aliases list
openclaw models aliases add <alias> <provider/model>
openclaw models aliases remove <alias>

openclaw models fallbacks list
openclaw models fallbacks add <provider/model>
openclaw models fallbacks remove <provider/model>
openclaw models fallbacks clear

openclaw models image-fallbacks list
openclaw models image-fallbacks add <provider/model>
openclaw models image-fallbacks remove <provider/model>
openclaw models image-fallbacks clear
```

`openclaw models`（無子指令）是 `models status` 的快捷方式。

### `models list`

預設顯示已設定的模型。常用旗標：

- `--all`：完整 catalog
- `--local`：僅本地供應商
- `--provider <name>`：按供應商篩選
- `--plain`：每行一個模型
- `--json`：機器可讀輸出

### `models status`

顯示已解析的 primary 模型、備用模型、圖片模型，以及已設定供應商的驗證概覽。它也顯示驗證存儲中找到的設定檔的 OAuth 到期狀態（預設在 24 小時內警告）。`--plain` 僅印出已解析的 primary 模型。
OAuth 狀態始終顯示（並包含在 `--json` 輸出中）。若已設定的供應商沒有憑證，`models status` 印出 **Missing auth** 區段。
JSON 包含 `auth.oauth`（警告視窗 + 設定檔）和 `auth.providers`（每個供應商的有效驗證）。
使用 `--check` 進行自動化（缺失/過期時退出 `1`，即將到期時退出 `2`）。

驗證選擇取決於供應商/帳號。對於全天候運行的 Gateway 主機，API key 通常最可預期；也支援訂閱 token 流程。

範例（Anthropic setup-token）：

```bash
claude setup-token
openclaw models status
```

## 掃描（OpenRouter 免費模型）

`openclaw models scan` 檢查 OpenRouter 的**免費模型 catalog** 並可
選擇性探測模型的工具和圖片支援。

主要旗標：

- `--no-probe`：跳過即時探測（僅 metadata）
- `--min-params <b>`：最小參數量（十億）
- `--max-age-days <days>`：跳過較舊的模型
- `--provider <name>`：供應商前綴篩選
- `--max-candidates <n>`：備用列表大小
- `--set-default`：將 `agents.defaults.model.primary` 設為第一個選擇
- `--set-image`：將 `agents.defaults.imageModel.primary` 設為第一個圖片選擇

探測需要 OpenRouter API key（來自驗證設定檔或
`OPENROUTER_API_KEY`）。沒有 key 時，使用 `--no-probe` 僅列出候選項。

掃描結果排名依據：

1. 圖片支援
2. 工具延遲
3. 上下文大小
4. 參數數量

輸入

- OpenRouter `/models` 列表（篩選 `:free`）
- 需要來自驗證設定檔或 `OPENROUTER_API_KEY` 的 OpenRouter API key（見 [/environment](/zh-Hant/help/environment)）
- 選用篩選器：`--max-age-days`、`--min-params`、`--provider`、`--max-candidates`
- 探測控制：`--timeout`、`--concurrency`

在 TTY 中執行時，可以互動式選擇備用項。在非互動式
模式下，傳遞 `--yes` 接受預設值。

## 模型 registry（`models.json`）

`models.providers` 中的自訂供應商被寫入 agent 目錄下的 `models.json`（預設 `~/.openclaw/agents/<agentId>/models.json`）。除非 `models.mode` 設定為 `replace`，否則預設合併此檔案。

匹配供應商 ID 的合併模式優先順序：

- agent `models.json` 中已存在的非空 `baseUrl` 優先。
- agent `models.json` 中的非空 `apiKey` 僅在該供應商未在當前設定/驗證設定檔上下文中受 SecretRef 管理時優先。
- SecretRef 管理的供應商 `apiKey` 值從來源標記（env 參考的 `ENV_VAR_NAME`，file/exec 參考的 `secretref-managed`）重新整理，而非持久化已解析的 secret。
- 空或缺失的 agent `apiKey`/`baseUrl` 退回到設定 `models.providers`。
- 其他供應商欄位從設定和正規化 catalog 資料重新整理。

這種基於標記的持久化適用於 OpenClaw 重新生成 `models.json` 的任何時候，包括 `openclaw agent` 等指令驅動路徑。
