---
summary: "CLI backends：透過本地 AI CLI 進行純文字 fallback"
read_when:
  - 當 API 供應商失效時希望有可靠的 fallback
  - 您正在使用 Claude Code CLI 或其他本地 AI CLI 並希望重複利用
  - 您需要仍支援 Session 與圖片的純文字、無工具路徑
title: "CLI Backends（CLI 後端）"
---

# CLI backends（fallback 執行環境）

OpenClaw 可以在 API 供應商中斷、遭遇速率限制或暫時異常時，將**本地 AI CLI** 作為**純文字 fallback** 執行。此設計刻意保守：

- **工具停用**（不進行工具呼叫）。
- **文字輸入 → 文字輸出**（可靠）。
- **支援 Sessions**（讓後續輪次保持連貫）。
- 若 CLI 接受圖片路徑，**可傳遞圖片**。

這是設計為**安全網**而非主要路徑。當您希望在不依賴外部 API 的情況下獲得「永遠有效」的文字回應時使用。

## 初學者快速開始

您可以在**不需任何設定**的情況下使用 Claude Code CLI（OpenClaw 內建預設值）：

```bash
openclaw agent --message "hi" --model claude-cli/opus-4.6
```

Codex CLI 也可立即使用：

```bash
openclaw agent --message "hi" --model codex-cli/gpt-5.4
```

若您的 Gateway 在 launchd/systemd 下運行且 PATH 精簡，只需新增指令路徑：

```json5
{
  agents: {
    defaults: {
      cliBackends: {
        "claude-cli": {
          command: "/opt/homebrew/bin/claude",
        },
      },
    },
  },
}
```

就這樣。不需要 keys，除 CLI 本身外不需要額外的認證設定。

## 作為 fallback 使用

將 CLI backend 加入您的 fallback 清單，使其僅在主要模型失效時執行：

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-6",
        fallbacks: ["claude-cli/opus-4.6", "claude-cli/opus-4.5"],
      },
      models: {
        "anthropic/claude-opus-4-6": { alias: "Opus" },
        "claude-cli/opus-4.6": {},
        "claude-cli/opus-4.5": {},
      },
    },
  },
}
```

注意事項：

- 若您使用 `agents.defaults.models`（allowlist），必須包含 `claude-cli/...`。
- 若主要供應商失效（認證、速率限制、逾時），OpenClaw 會嘗試 CLI backend。

## 設定概覽

所有 CLI backends 位於：

```
agents.defaults.cliBackends
```

每個項目以**供應商 id**（例如 `claude-cli`、`my-cli`）為鍵。
供應商 id 成為模型引用的左側：

```
<provider>/<model>
```

### 設定範例

```json5
{
  agents: {
    defaults: {
      cliBackends: {
        "claude-cli": {
          command: "/opt/homebrew/bin/claude",
        },
        "my-cli": {
          command: "my-cli",
          args: ["--json"],
          output: "json",
          input: "arg",
          modelArg: "--model",
          modelAliases: {
            "claude-opus-4-6": "opus",
            "claude-opus-4-5": "opus",
            "claude-sonnet-4-5": "sonnet",
          },
          sessionArg: "--session",
          sessionMode: "existing",
          sessionIdFields: ["session_id", "conversation_id"],
          systemPromptArg: "--system",
          systemPromptWhen: "first",
          imageArg: "--image",
          imageMode: "repeat",
          serialize: true,
        },
      },
    },
  },
}
```

## 運作原理

1. 根據供應商前綴（`claude-cli/...`）**選擇 backend**。
2. 使用相同的 OpenClaw prompt + 工作空間上下文**建立系統 prompt**。
3. 帶著 session id（若支援）**執行 CLI**，讓歷史記錄保持一致。
4. **解析輸出**（JSON 或純文字）並返回最終文字。
5. 按 backend **持久化 session id**，讓後續操作重複使用相同的 CLI session。

## Sessions

- 若 CLI 支援 sessions，設定 `sessionArg`（例如 `--session-id`）或
  `sessionArgs`（需在多個 flag 中插入 ID 時使用 `{sessionId}` 占位符）。
- 若 CLI 使用帶有不同 flag 的**繼續子指令**，設定
  `resumeArgs`（繼續時取代 `args`）以及選用的 `resumeOutput`
  （用於非 JSON 繼續）。
- `sessionMode`：
  - `always`：永遠傳送 session id（若無儲存則使用新的 UUID）。
  - `existing`：僅在之前有儲存的 session id 時才傳送。
  - `none`：永不傳送 session id。

## 圖片（pass-through）

若您的 CLI 接受圖片路徑，設定 `imageArg`：

```json5
imageArg: "--image",
imageMode: "repeat"
```

OpenClaw 會將 base64 圖片寫入暫存檔案。若設定了 `imageArg`，這些路徑會作為 CLI 引數傳遞。若缺少 `imageArg`，OpenClaw 會將檔案路徑附加到 prompt（路徑注入），對於從純路徑自動載入本地檔案的 CLI（Claude Code CLI 行為）已足夠。

## 輸入/輸出

- `output: "json"`（預設）嘗試解析 JSON 並提取文字 + session id。
- `output: "jsonl"` 解析 JSONL 串流（Codex CLI `--json`），提取最後的 Agent 訊息以及 `thread_id`（若存在）。
- `output: "text"` 將標準輸出視為最終回應。

輸入模式：

- `input: "arg"`（預設）將 prompt 作為最後一個 CLI 引數傳遞。
- `input: "stdin"` 透過 stdin 傳送 prompt。
- 若 prompt 非常長且設定了 `maxPromptArgChars`，則使用 stdin。

## 預設值（內建）

OpenClaw 為 `claude-cli` 提供預設值：

- `command: "claude"`
- `args: ["-p", "--output-format", "json", "--permission-mode", "bypassPermissions"]`
- `resumeArgs: ["-p", "--output-format", "json", "--permission-mode", "bypassPermissions", "--resume", "{sessionId}"]`
- `modelArg: "--model"`
- `systemPromptArg: "--append-system-prompt"`
- `sessionArg: "--session-id"`
- `systemPromptWhen: "first"`
- `sessionMode: "always"`

OpenClaw 也為 `codex-cli` 提供預設值：

- `command: "codex"`
- `args: ["exec","--json","--color","never","--sandbox","read-only","--skip-git-repo-check"]`
- `resumeArgs: ["exec","resume","{sessionId}","--color","never","--sandbox","read-only","--skip-git-repo-check"]`
- `output: "jsonl"`
- `resumeOutput: "text"`
- `modelArg: "--model"`
- `imageArg: "--image"`
- `sessionMode: "existing"`

僅在需要時覆蓋（常見：`command` 的絕對路徑）。

## 限制

- **無 OpenClaw 工具**（CLI backend 永不接收工具呼叫）。部分 CLI 可能仍會執行自己的 Agent 工具。
- **無串流**（CLI 輸出收集完成後才返回）。
- **結構化輸出**取決於 CLI 的 JSON 格式。
- **Codex CLI sessions** 透過文字輸出繼續（非 JSONL），比初始 `--json` 執行結構性更差。OpenClaw sessions 仍正常運作。

## 故障排除

- **CLI not found**：將 `command` 設為完整路徑。
- **Wrong model name**：使用 `modelAliases` 將 `provider/model` 對應到 CLI 模型。
- **No session continuity**：確保設定了 `sessionArg` 且 `sessionMode` 不是 `none`（Codex CLI 目前無法使用 JSON 輸出繼續）。
- **Images ignored**：設定 `imageArg`（並確認 CLI 支援檔案路徑）。
