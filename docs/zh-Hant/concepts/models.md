---
title: "Models(模型)"
summary: "模型 CLI：list、set、aliases、fallbacks、scan、status"
read_when:
  - 新增或修改模型 CLI（models list/set/scan/aliases/fallbacks）
  - 更改模型備援行為或選擇 UX
  - 更新模型掃描探測（tools/images）
---
# Models CLI（模型 CLI）

請參閱 [/concepts/model-failover](/concepts/model-failover) 了解認證設定檔輪換、冷卻時間以及它如何與備援互動。
快速供應商概述 + 範例：[/concepts/model-providers](/concepts/model-providers)。

## 模型選擇如何運作

OpenClaw 按此順序選擇模型：

1) **主要**模型（`agents.defaults.model.primary` 或 `agents.defaults.model`）。
2) **備援**在 `agents.defaults.model.fallbacks` 中（按順序）。
3) **供應商認證備援**在移動到下一個模型之前在供應商內部發生。

相關：
- `agents.defaults.models` 是 OpenClaw 可以使用的模型的允許清單/目錄（加上別名）。
- `agents.defaults.imageModel` **僅在**主要模型無法接受圖片時使用。
- 每代理預設可以透過 `agents.list[].model` 加上綁定覆寫 `agents.defaults.model`（請參閱 [/concepts/multi-agent](/concepts/multi-agent)）。

## 快速模型選擇（經驗分享）

- **GLM**：編碼/工具呼叫稍好。
- **MiniMax**：寫作和氛圍更好。

## 設定精靈（建議）

如果您不想手動編輯設定，請運行引導精靈：

```bash
openclaw onboard
```

它可以為常見供應商設定模型 + 認證，包括 **OpenAI Code (Codex) 訂閱**（OAuth）和 **Anthropic**（建議使用 API 金鑰；也支援 `claude setup-token`）。

## 設定鍵（概述）

- `agents.defaults.model.primary` 和 `agents.defaults.model.fallbacks`
- `agents.defaults.imageModel.primary` 和 `agents.defaults.imageModel.fallbacks`
- `agents.defaults.models`（允許清單 + 別名 + 供應商參數）
- `models.providers`（自訂供應商寫入 `models.json`）

模型參考被正規化為小寫。供應商別名如 `z.ai/*` 正規化為 `zai/*`。

供應商設定範例（包括 OpenCode Zen）位於 [/gateway/configuration](/gateway/configuration#opencode-zen-multi-model-proxy)。

## 「模型不被允許」（以及為什麼回覆停止）

如果設定了 `agents.defaults.models`，它就成為 `/model` 和會話覆寫的**允許清單**。當使用者選擇不在該允許清單中的模型時，OpenClaw 返回：

```
Model "provider/model" is not allowed. Use /model to list available models.
```

這發生在正常回覆生成**之前**，所以訊息可能感覺像「沒有回應」。修復方法是：

- 將模型新增到 `agents.defaults.models`，或
- 清除允許清單（移除 `agents.defaults.models`），或
- 從 `/model list` 選擇一個模型。

範例允許清單設定：

```json5
{
  agent: {
    model: { primary: "anthropic/claude-sonnet-4-5" },
    models: {
      "anthropic/claude-sonnet-4-5": { alias: "Sonnet" },
      "anthropic/claude-opus-4-5": { alias: "Opus" }
    }
  }
}
```

## 在聊天中切換模型（`/model`）

您可以在不重啟的情況下為當前會話切換模型：

```
/model
/model list
/model 3
/model openai/gpt-5.2
/model status
```

備註：
- `/model`（和 `/model list`）是緊湊的、編號的選擇器（模型系列 + 可用供應商）。
- `/model <#>` 從該選擇器中選擇。
- `/model status` 是詳細視圖（認證候選和，當設定時，供應商端點 `baseUrl` + `api` 模式）。
- 模型參考透過在**第一個** `/` 處分割來解析。輸入 `/model <ref>` 時使用 `provider/model`。
- 如果模型 ID 本身包含 `/`（OpenRouter 風格），您必須包含供應商前綴（例如：`/model openrouter/moonshotai/kimi-k2`）。
- 如果您省略供應商，OpenClaw 會將輸入視為別名或**預設供應商**的模型（僅當模型 ID 中沒有 `/` 時有效）。

完整命令行為/設定：[斜線命令](/tools/slash-commands)。

## CLI 命令

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

`openclaw models`（無子命令）是 `models status` 的捷徑。

### `models list`

預設顯示已設定的模型。有用的選項：

- `--all`：完整目錄
- `--local`：僅本地供應商
- `--provider <name>`：按供應商篩選
- `--plain`：每行一個模型
- `--json`：機器可讀輸出

### `models status`

顯示解析的主要模型、備援、圖片模型，以及已設定供應商的認證概述。它還會顯示在認證儲存中找到的設定檔的 OAuth 過期狀態（預設在 24 小時內警告）。`--plain` 僅列印解析的主要模型。
OAuth 狀態始終顯示（並包含在 `--json` 輸出中）。如果已設定的供應商沒有憑證，`models status` 會列印 **Missing auth** 部分。
JSON 包含 `auth.oauth`（警告視窗 + 設定檔）和 `auth.providers`（每個供應商的有效認證）。
使用 `--check` 進行自動化（缺失/過期時退出 `1`，即將過期時退出 `2`）。

首選的 Anthropic 認證是 Claude Code CLI setup-token（在任何地方運行；如果需要，在 Gateway 主機上貼上）：

```bash
claude setup-token
openclaw models status
```

## 掃描（OpenRouter 免費模型）

`openclaw models scan` 檢查 OpenRouter 的**免費模型目錄**，並可選擇性地探測模型的工具和圖片支援。

關鍵選項：

- `--no-probe`：跳過即時探測（僅元資料）
- `--min-params <b>`：最小參數大小（十億）
- `--max-age-days <days>`：跳過較舊的模型
- `--provider <name>`：供應商前綴篩選
- `--max-candidates <n>`：備援清單大小
- `--set-default`：將 `agents.defaults.model.primary` 設為第一個選擇
- `--set-image`：將 `agents.defaults.imageModel.primary` 設為第一個圖片選擇

探測需要 OpenRouter API 金鑰（來自認證設定檔或 `OPENROUTER_API_KEY`）。沒有金鑰時，使用 `--no-probe` 僅列出候選。

掃描結果按以下順序排名：
1) 圖片支援
2) 工具延遲
3) 上下文大小
4) 參數數量

輸入
- OpenRouter `/models` 清單（篩選 `:free`）
- 需要來自認證設定檔的 OpenRouter API 金鑰或 `OPENROUTER_API_KEY`（請參閱 [/environment](/environment)）
- 可選篩選：`--max-age-days`、`--min-params`、`--provider`、`--max-candidates`
- 探測控制：`--timeout`、`--concurrency`

在 TTY 中運行時，您可以互動式選擇備援。在非互動模式下，傳遞 `--yes` 接受預設值。

## 模型註冊表（`models.json`）

`models.providers` 中的自訂供應商被寫入代理目錄下的 `models.json`（預設 `~/.openclaw/agents/<agentId>/models.json`）。除非 `models.mode` 設為 `replace`，否則此檔案預設會被合併。
