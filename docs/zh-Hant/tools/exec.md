---
summary: "執行工具的使用方式、stdin 模式與 TTY 支援"
read_when:
  - 使用或修改 exec 工具
  - 偵錯 stdin 或 TTY 行為
title: "Exec Tool"
---

# Exec 工具

在工作區執行 shell 指令。支援透過 `process` 工具進行前台與背景執行。如果 `process` 不被允許，`exec` 會同步執行並忽略 `yieldMs`/`background`。背景會話按 Agent 劃分範圍；`process` 只會看到同一 Agent 的會話。

## 參數

- `command`（必填）
- `workdir`（預設為 cwd）
- `env`（鍵值覆寫）
- `yieldMs`（預設 10000）：延遲後自動轉入背景
- `background`（bool）：立即轉入背景
- `timeout`（秒，預設 1800）：超過時終止進程
- `pty`（bool）：在可用時在虛擬終端中執行（只有 TTY CLI、編碼 Agent、終端 UI）
- `host`（`sandbox | gateway | node`）：執行位置
- `security`（`deny | allowlist | full`）：針對 `gateway`/`node` 的執行模式
- `ask`（`off | on-miss | always`）：針對 `gateway`/`node` 的核准提示
- `node`（字串）：`host=node` 的節點 ID/名稱
- `elevated`（bool）：要求提權模式（gateway host）；`security=full` 只在 elevated 解析為 `full` 時強制執行

注意：

- `host` 預設為 `sandbox`。
- 當沙盒關閉時會忽略 `elevated`（exec 已在 host 上執行）。
- `gateway`/`node` 核准由 `~/.openclaw/exec-approvals.json` 控制。
- `node` 需要配對的節點（companion app 或 headless node host）。
- 如果有多個節點可用，設定 `exec.node` 或 `tools.exec.node` 以選擇一個。
- 在非 Windows 主機上，當設定 `SHELL` 時 exec 會使用它；如果 `SHELL` 是 `fish`，會優先使用 `PATH` 中的 `bash`（或 `sh`）來避免與 fish 不相容的指令碼，如果都不存在則回退到 `SHELL`。
- Host 執行（`gateway`/`node`）會拒絕 `env.PATH` 和載入器覆寫（`LD_*`/`DYLD_*`）以防止二進位檔案劫持或注入程式碼。
- 重要：沙盒預設是**關閉的**。如果沙盒關閉，`host=sandbox` 直接在 gateway host 上執行（無容器）且**不需要核准**。要求核准，請使用 `host=gateway` 執行並設定 exec 核准（或啟用沙盒）。

## 設定

- `tools.exec.notifyOnExit`（預設：true）：為真時，背景化的 exec 會話會在退出時排入系統事件並要求心跳。
- `tools.exec.approvalRunningNoticeMs`（預設：10000）：當核准限制的 exec 執行時間超過此時間時發出單一「執行中」通知（0 停用）。
- `tools.exec.host`（預設：`sandbox`）
- `tools.exec.security`（預設：沙盒為 `deny`，gateway + node 未設定時為 `allowlist`）
- `tools.exec.ask`（預設：`on-miss`）
- `tools.exec.node`（預設：未設定）
- `tools.exec.pathPrepend`：要前置到 exec 執行的 `PATH` 的目錄列表。
- `tools.exec.safeBins`：不需要顯式 allowlist 項目即可執行的 stdin 專用安全二進位檔案。

範例：

```json5
{
  tools: {
    exec: {
      pathPrepend: ["~/bin", "/opt/oss/bin"],
    },
  },
}
```

### PATH 處理

- `host=gateway`：將登入 shell 的 `PATH` 合併到 exec 環境中。`env.PATH` 覆寫對 host 執行會被拒絕。Daemon 本身仍使用最小 `PATH` 執行：
  - macOS: `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`
  - Linux: `/usr/local/bin`, `/usr/bin`, `/bin`
- `host=sandbox`：在容器內執行 `sh -lc`（登入 shell），所以 `/etc/profile` 可能重設 `PATH`。OpenClaw 透過內部環境變數（無 shell 內插）在設定檔來源後前置 `env.PATH`；`tools.exec.pathPrepend` 也適用這裡。
- `host=node`：只有非封鎖的環境覆寫會被傳送到節點。`env.PATH` 覆寫對 host 執行會被拒絕。Headless 節點主機只有在前置節點主機 PATH 時才接受 `PATH`（無替換）。macOS 節點完全捨棄 `PATH` 覆寫。

Per-agent 節點綁定（使用 config 中的 agent 清單索引）：

```bash
openclaw config get agents.list
openclaw config set agents.list[0].tools.exec.node "node-id-or-name"
```

控制 UI：Nodes 標籤包含相同設定的小型「Exec node binding」面板。

## 會話覆寫（`/exec`）

使用 `/exec` 為 `host`、`security`、`ask` 和 `node` 設定**每個會話**的預設值。
發送不帶引數的 `/exec` 以顯示目前值。

範例：

```
/exec host=gateway security=allowlist ask=on-miss node=mac-1
```

## 授權模型

`/exec` 只被**授權的寄件者**認可（channel allowlist/配對加上 `commands.useAccessGroups`）。
它只更新**會話狀態**而不寫入 config。要硬停用 exec，透過工具策略否定它（`tools.deny: ["exec"]` 或 per-agent）。Host 核准仍適用，除非您明確設定 `security=full` 和 `ask=off`。

## Exec 核准（companion app / node host）

沙盒化的 Agent 可以在 exec 在 gateway 或 node host 執行之前要求每個要求的核准。
請見 [Exec approvals](/tools/exec-approvals) 了解策略、allowlist 和 UI 流程。

當需要核准時，exec 工具立即回傳
`status: "approval-pending"` 和核准 ID。一旦核准（或拒絕/逾時），
Gateway 發出系統事件（`Exec finished` / `Exec denied`）。如果指令在 `tools.exec.approvalRunningNoticeMs` 後仍在執行，會發出單一 `Exec running` 通知。

## Allowlist + safe bins

Allowlist 執行只匹配**解析的二進位檔案路徑**（無基名稱匹配）。當
`security=allowlist` 時，shell 指令只有在每個管道段都被 allowlist 或是 safe bin 時才會自動允許。
Chaining（`;`、`&&`、`||`）和重定向在 allowlist 模式下被拒絕。

## 範例

前台：

```json
{ "tool": "exec", "command": "ls -la" }
```

背景 + 輪詢：

```json
{"tool":"exec","command":"npm run build","yieldMs":1000}
{"tool":"process","action":"poll","sessionId":"<id>"}
```

發送鍵盤（tmux 風格）：

```json
{"tool":"process","action":"send-keys","sessionId":"<id>","keys":["Enter"]}
{"tool":"process","action":"send-keys","sessionId":"<id>","keys":["C-c"]}
{"tool":"process","action":"send-keys","sessionId":"<id>","keys":["Up","Up","Enter"]}
```

提交（只發送 CR）：

```json
{ "tool": "process", "action": "submit", "sessionId": "<id>" }
```

貼上（預設用括號包含）：

```json
{ "tool": "process", "action": "paste", "sessionId": "<id>", "text": "line1\nline2\n" }
```

## apply_patch（實驗性）

`apply_patch` 是 `exec` 的子工具，用於結構化的多檔案編輯。
明確啟用它：

```json5
{
  tools: {
    exec: {
      applyPatch: { enabled: true, allowModels: ["gpt-5.2"] },
    },
  },
}
```

注意：

- 只適用於 OpenAI/OpenAI Codex 模型。
- 工具策略仍適用；`allow: ["exec"]` 隱含允許 `apply_patch`。
- Config 位於 `tools.exec.applyPatch`。
