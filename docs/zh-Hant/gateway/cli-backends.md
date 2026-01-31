---
title: "cli-backends(CLI Backends)"
summary: "CLI backends: 透過本地 AI CLI 進行純文字回退 (fallback)"
read_when:
  - 當 API 供應商失敗時需要可靠的回退方案
  - 運行 Claude Code CLI 或其他本地 AI CLI 並希望重複使用它們
  - 需要一個支援 Session 與 Image 但不使用 Tool 的純文字路徑
---

# CLI Backends (Fallback Runtime)

OpenClaw 可以運行 **本地 AI CLI** 作為 **純文字回退 (Text-only Fallback)**，當 API 供應商當機、速率限制或暫時異常時使用。這是刻意保守的設計：

- **工具被停用** (無 Tool calls)。
- **Text in → text out** (可靠)。
- **支援 Sessions** (因此後續對話保持連貫)。
- **Images 可透傳** (若 CLI 接受圖片路徑)。

這被設計為 **安全網** 而非主要路徑。當您想要不依賴外部 API 且“總是有效”的文字回應時使用它。

## 新手友善快速入門

您可以使用 Claude Code CLI **無需任何設定** (OpenClaw 內建預設值)：

```bash
openclaw agent --message "hi" --model claude-cli/opus-4.5
```

Codex CLI 也可以開箱即用：

```bash
openclaw agent --message "hi" --model codex-cli/gpt-5.2-codex
```

若您的 Gateway 在 launchd/systemd 下運行且 PATH 最小化，僅需新增指令路徑：

```json5
{
  agents: {
    defaults: {
      cliBackends: {
        "claude-cli": {
          command: "/opt/homebrew/bin/claude"
        }
      }
    }
  }
}
```

就這樣。除了 CLI 本身之外，不需要金鑰或額外的 Auth 設定。

## 作為 Fallback 使用

將 CLI Backend 新增至您的 Fallback 清單，使其僅在主要模型失敗時運行：

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-5",
        fallbacks: [
          "claude-cli/opus-4.5"
        ]
      },
      models: {
        "anthropic/claude-opus-4-5": { alias: "Opus" },
        "claude-cli/opus-4.5": {}
      }
    }
  }
}
```

備註:
- 若您使用 `agents.defaults.models` (allowlist)，必須包含 `claude-cli/...`。
- 若主要供應商失敗 (Auth, Rate limits, Timeouts)，OpenClaw 接著會嘗試 CLI Backend。

## 設定概觀

所有 CLI Backends 位於：

```
agents.defaults.cliBackends
```

每個項目以 **Provider ID** 為鍵 (例如 `claude-cli`, `my-cli`)。
Provider ID 成為您 Model Ref 的左側：

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
          command: "/opt/homebrew/bin/claude"
        },
        "my-cli": {
          command: "my-cli",
          args: ["--json"],
          output: "json",
          input: "arg",
          modelArg: "--model",
          modelAliases: {
            "claude-opus-4-5": "opus",
            "claude-sonnet-4-5": "sonnet"
          },
          sessionArg: "--session",
          sessionMode: "existing",
          sessionIdFields: ["session_id", "conversation_id"],
          systemPromptArg: "--system",
          systemPromptWhen: "first",
          imageArg: "--image",
          imageMode: "repeat",
          serialize: true
        }
      }
    }
  }
}
```

## 運作原理

1) 根據 Provider 前綴 (`claude-cli/...`) **選擇 Backend**。
2) 使用相同的 OpenClaw Prompt + Workspace Context **建置 System Prompt**。
3) 使用 Session ID (若支援) **執行 CLI** 以保持歷史記錄一致。
4) **解析輸出** (JSON 或純文字) 並回傳最終文字。
5) 每個 Backend **持久化 Session IDs**，因此後續對話重複使用相同的 CLI Session。

## Sessions

- 若 CLI 支援 Sessions，設定 `sessionArg` (例如 `--session-id`) 或 `sessionArgs` (當 ID 需要插入多個 Flags 時使用 `{sessionId}` 佔位符)。
- 若 CLI 使用 **Resume Subcommand** 搭配不同 Flags，設定 `resumeArgs` (Resume 時取代 `args`) 與選用的 `resumeOutput` (用於非 JSON Resume)。
- `sessionMode`:
  - `always`: 總是發送 Session ID (若無儲存則使用新 UUID)。
  - `existing`: 僅當之前有儲存 Session ID 時才發送。
  - `none`: 從不發送 Session ID。

## Images (透傳)

若您的 CLI 接受圖片路徑，設定 `imageArg`：

```json5
imageArg: "--image",
imageMode: "repeat"
```

OpenClaw 會將 Base64 圖片寫入暫存檔。若設定了 `imageArg`，這些路徑會作為 CLI Args 傳遞。若 `imageArg` 遺失，OpenClaw 會將檔案路徑附加到 Prompt (Path Injection)，這對於從純路徑自動載入本地檔案的 CLI (Claude Code CLI 行為) 已足夠。

## Inputs / Outputs

- `output: "json"` (預設) 嘗試解析 JSON 並提取文字 + Session ID。
- `output: "jsonl"` 解析 JSONL Streams (Codex CLI `--json`) 並提取最後的 Agent 訊息加上 `thread_id` (若存在)。
- `output: "text"` 將 stdout 視為最終回應。

輸入模式:
- `input: "arg"` (預設) 將 Prompt 作為最後一個 CLI Arg 傳遞。
- `input: "stdin"` 透過 stdin 發送 Prompt。
- 若 Prompt 非常長且設定了 `maxPromptArgChars`，則使用 stdin。

## 預設值 (Built-in)

OpenClaw 隨附 `claude-cli` 的預設值：

- `command: "claude"`
- `args: ["-p", "--output-format", "json", "--dangerously-skip-permissions"]`
- `resumeArgs: ["-p", "--output-format", "json", "--dangerously-skip-permissions", "--resume", "{sessionId}"]`
- `modelArg: "--model"`
- `systemPromptArg: "--append-system-prompt"`
- `sessionArg: "--session-id"`
- `systemPromptWhen: "first"`
- `sessionMode: "always"`

OpenClaw 也隨附 `codex-cli` 的預設值：

- `command: "codex"`
- `args: ["exec","--json","--color","never","--sandbox","read-only","--skip-git-repo-check"]`
- `resumeArgs: ["exec","resume","{sessionId}","--color","never","--sandbox","read-only","--skip-git-repo-check"]`
- `output: "jsonl"`
- `resumeOutput: "text"`
- `modelArg: "--model"`
- `imageArg: "--image"`
- `sessionMode: "existing"`

僅在需要時覆蓋 (常見：絕對 `command` 路徑)。

## 限制

- **無 OpenClaw Tools** (CLI Backend 從不接收 Tool calls)。部分 CLI 可能仍運行自己的 Agent Tooling。
- **無 Streaming** (CLI 輸出被收集後才回傳)。
- **Structured Outputs** 取決於 CLI 的 JSON 格式。
- **Codex CLI Sessions** 透過文字輸出 (無 JSONL) 恢復，結構比初始 `--json` 執行較少。OpenClaw Sessions 仍正常運作。

## 故障排除

- **CLI not found**: 將 `command` 設定為完整路徑。
- **Wrong model name**: 使用 `modelAliases` 將 `provider/model` 映射至 CLI Model。
- **No session continuity**: 確保設定了 `sessionArg` 且 `sessionMode` 不是 `none` (Codex CLI 目前無法透過 JSON 輸出恢復)。
- **Images ignored**: 設定 `imageArg` (並驗證 CLI 是否支援檔案路徑)。
