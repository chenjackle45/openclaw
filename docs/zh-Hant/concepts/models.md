---
title: "Models CLI（模型 CLI）"
summary: "模型 CLI：list、set、aliases、fallbacks、scan、status"
read_when:
  - 新增或修改模型 CLI（models list/set/scan/aliases/fallbacks）
  - 變更模型後備行為或選擇 UX
  - 更新模型掃描探針（工具/映像）
---

# 模型 CLI

請參閱 [/concepts/model-failover](/zh-Hant/concepts/model-failover) 了解 Auth Profile 輪替、冷卻時間，以及如何與後備互動。
快速 Provider 概覽 + 範例：[/concepts/model-providers](/zh-Hant/concepts/model-providers)。

## 模型選擇的運作方式

OpenClaw 依此順序選擇模型：

1. **主要**模型（`agents.defaults.model.primary` 或 `agents.defaults.model`）。
2. `agents.defaults.model.fallbacks` 中的**後備**（依序）。
3. **Provider 驗證故障移轉**發生在 Provider 內部，然後才移至下一個模型。

相關說明：

- `agents.defaults.models` 是 OpenClaw 可以使用的模型允許清單/目錄（加上別名）。
- `agents.defaults.imageModel` **僅在**主要模型無法接受映像時使用。
- 每個 Agent 的預設值可以透過 `agents.list[].model` 加上繫結覆寫 `agents.defaults.model`（請參閱 [/concepts/multi-agent](/zh-Hant/concepts/multi-agent)）。

## 快速模型策略

- 將您的主要設定為您可用的最強最新一代模型。
- 使用後備處理對成本/延遲敏感的任務和較低風險的聊天。
- 對於工具啟用的 Agent 或不受信任的輸入，避免使用較舊/較弱的模型層。

## 設定精靈（建議）

如果您不想手動編輯設定，請執行引導精靈：

```bash
openclaw onboard
```

它可以設定常見 Provider 的模型 + 驗證，包括 **OpenAI Code（Codex）訂閱**（OAuth）和 **Anthropic**（API 金鑰或 `claude setup-token`）。

## 設定金鑰（概覽）

- `agents.defaults.model.primary` 和 `agents.defaults.model.fallbacks`
- `agents.defaults.imageModel.primary` 和 `agents.defaults.imageModel.fallbacks`
- `agents.defaults.models`（允許清單 + 別名 + Provider 參數）
- `models.providers`（寫入 `models.json` 的自訂 Provider）

模型引用會被正規化為小寫。Provider 別名如 `z.ai/*` 正規化為 `zai/*`。

Provider 設定範例（包括 OpenCode）位於
[/gateway/configuration](/zh-Hant/gateway/configuration#opencode)。

## 「模型不被允許」（以及回覆為何停止）

如果設定了 `agents.defaults.models`，它會成為 `/model` 和對話覆寫的**允許清單**。當使用者選擇不在該允許清單中的模型時，OpenClaw 回傳：

```
Model "provider/model" is not allowed. Use /model to list available models.
```

這在產生正常回覆**之前**發生，因此訊息可能感覺像是「沒有回應」。修復方法是：

- 將模型新增到 `agents.defaults.models`，或
- 清除允許清單（移除 `agents.defaults.models`），或
- 從 `/model list` 選擇模型。

允許清單設定範例：

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

您可以在不重新啟動的情況下切換目前對話的模型：

```
/model
/model list
/model 3
/model openai/gpt-5.2
/model status
```

注意：

- `/model`（和 `/model list`）是緊湊的、帶編號的選取器（模型系列 + 可用 Provider）。
- 在 Discord 上，`/model` 和 `/models` 開啟帶有 Provider 和模型下拉選單及提交步驟的互動式選取器。
- `/model <#>` 從該選取器中選取。
- `/model status` 是詳細視圖（驗證候選者，以及設定時的 Provider 端點 `baseUrl` + `api` 模式）。
- 模型引用透過在**第一個** `/` 上分割來解析。輸入 `/model <ref>` 時請使用 `provider/model`。
- 如果模型 ID 本身包含 `/`（OpenRouter 樣式），您必須包含 Provider 前置詞（範例：`/model openrouter/moonshotai/kimi-k2`）。
- 如果您省略 Provider，OpenClaw 將輸入視為別名或**預設 Provider** 的模型（只有當模型 ID 中沒有 `/` 時才有效）。

完整的指令行為/設定：[Slash 指令](/zh-Hant/tools/slash-commands)。

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

`openclaw models`（沒有子指令）是 `models status` 的捷徑。

### `models list`

預設顯示已設定的模型。實用旗標：

- `--all`：完整目錄
- `--local`：僅限本機 Provider
- `--provider <name>`：按 Provider 篩選
- `--plain`：每行一個模型
- `--json`：機器可讀輸出

### `models status`

顯示已解析的主要模型、後備、映像模型，以及已設定 Provider 的驗證概覽。它也會顯示在驗證儲存中找到的設定檔的 OAuth 到期狀態（預設在 24 小時內警告）。`--plain` 只列印已解析的主要模型。
OAuth 狀態始終顯示（並包含在 `--json` 輸出中）。如果已設定的 Provider 沒有憑證，`models status` 會列印**缺少驗證**區段。
JSON 包含 `auth.oauth`（警告視窗 + 設定檔）和 `auth.providers`（每個 Provider 的有效驗證）。
使用 `--check` 進行自動化（缺少/過期時退出 `1`，即將過期時退出 `2`）。

驗證選擇取決於 Provider/帳號。對於始終開啟的 Gateway 主機，API 金鑰通常是最可預測的；也支援訂閱 Token 流程。

範例（Anthropic setup-token）：

```bash
claude setup-token
openclaw models status
```

## 掃描（OpenRouter 免費模型）

`openclaw models scan` 檢查 OpenRouter 的**免費模型目錄**，並可以選擇性地探測模型的工具和映像支援。

主要旗標：

- `--no-probe`：跳過即時探針（僅限元資料）
- `--min-params <b>`：最小參數大小（十億）
- `--max-age-days <days>`：跳過較舊的模型
- `--provider <name>`：Provider 前置詞篩選
- `--max-candidates <n>`：後備列表大小
- `--set-default`：將 `agents.defaults.model.primary` 設定為第一個選擇
- `--set-image`：將 `agents.defaults.imageModel.primary` 設定為第一個映像選擇

探測需要 OpenRouter API 金鑰（來自 Auth Profile 或 `OPENROUTER_API_KEY`）。沒有金鑰時，使用 `--no-probe` 只列出候選者。

掃描結果按以下排名：

1. 映像支援
2. 工具延遲
3. 上下文大小
4. 參數數量

輸入

- OpenRouter `/models` 列表（篩選 `:free`）
- 需要來自 Auth Profile 或 `OPENROUTER_API_KEY` 的 OpenRouter API 金鑰（請參閱 [/environment](/zh-Hant/help/environment)）
- 選用篩選：`--max-age-days`、`--min-params`、`--provider`、`--max-candidates`
- 探針控制：`--timeout`、`--concurrency`

在 TTY 中執行時，您可以互動式地選擇後備。在非互動式模式下，傳遞 `--yes` 以接受預設值。

## 模型登錄（`models.json`）

`models.providers` 中的自訂 Provider 被寫入 Agent 目錄下的 `models.json`（預設 `~/.openclaw/agents/<agentId>/agent/models.json`）。除非 `models.mode` 設定為 `replace`，否則預設合併此檔案。

匹配 Provider ID 的合併模式優先順序：

- Agent `models.json` 中已存在的非空 `baseUrl` 優先。
- 只有當該 Provider 在目前設定/Auth Profile 上下文中不受 SecretRef 管理時，Agent `models.json` 中的非空 `apiKey` 才優先。
- SecretRef 管理的 Provider `apiKey` 值從來源標記（env 引用的 `ENV_VAR_NAME`，file/exec 引用的 `secretref-managed`）重新整理，而非持久化已解析的機密。
- SecretRef 管理的 Provider 標頭值從來源標記（env 引用的 `secretref-env:ENV_VAR_NAME`，file/exec 引用的 `secretref-managed`）重新整理。
- 空的或遺失的 Agent `apiKey`/`baseUrl` 後退到設定 `models.providers`。
- 其他 Provider 欄位從設定和正規化的目錄資料重新整理。

標記持久化是來源權威的：OpenClaw 從活躍的來源設定快照（解析前）寫入標記，而非從已解析的執行期機密值。
這適用於 OpenClaw 重新產生 `models.json` 的任何時候，包括指令驅動的路徑如 `openclaw agent`。
