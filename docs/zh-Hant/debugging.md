---
title: "Debugging(除錯)"
summary: "除錯工具：監視模式、原始模型串流以及推理洩漏追蹤"
read_when:
  - 您需要檢查原始模型輸出以查看推理洩漏
  - 您想要在迭代時以監視模式執行 Gateway
  - 您需要可重複的除錯工作流程
---

# Debugging(除錯)

此頁面涵蓋串流輸出的除錯輔助工具，特別是當供應商將推理混入正常文字時。

## 執行時除錯覆蓋

在聊天中使用 `/debug` 來設定**僅執行時**的設定覆蓋（記憶體，非磁碟）。
`/debug` 預設停用；使用 `commands.debug: true` 啟用。
當您需要切換模糊設定而無需編輯 `openclaw.json` 時，這很方便。

範例：

```
/debug show
/debug set messages.responsePrefix="[openclaw]"
/debug unset messages.responsePrefix
/debug reset
```

`/debug reset` 清除所有覆蓋並返回到磁碟上的設定。

## Gateway 監視模式

為了快速迭代，在檔案監視器下執行 gateway：

```bash
pnpm gateway:watch --force
```

這對應到：

```bash
tsx watch src/entry.ts gateway --force
```

在 `gateway:watch` 之後新增任何 gateway CLI 旗標，它們將在每次重新啟動時傳遞。

## Dev profile + dev gateway (--dev)

使用 dev profile 隔離狀態並啟動安全、可拋棄的設定以進行除錯。有**兩個** `--dev` 旗標：

- **全域 `--dev`（profile）：**將狀態隔離在 `~/.openclaw-dev` 下，並將 gateway 埠預設為 `19001`（衍生埠隨之移動）。
- **`gateway --dev`：告訴 Gateway 在缺少時自動建立預設設定 + 工作區**（並跳過 BOOTSTRAP.md）。

建議流程（dev profile + dev bootstrap）：

```bash
pnpm gateway:dev
OPENCLAW_PROFILE=dev openclaw tui
```

如果您還沒有全域安裝，請透過 `pnpm openclaw ...` 執行 CLI。

這會做什麼：

1) **Profile 隔離**（全域 `--dev`）
   - `OPENCLAW_PROFILE=dev`
   - `OPENCLAW_STATE_DIR=~/.openclaw-dev`
   - `OPENCLAW_CONFIG_PATH=~/.openclaw-dev/openclaw.json`
   - `OPENCLAW_GATEWAY_PORT=19001`（browser/canvas 相應移動）

2) **Dev bootstrap**（`gateway --dev`）
   - 如果缺少則寫入最小設定（`gateway.mode=local`，綁定 loopback）。
   - 設定 `agent.workspace` 為 dev workspace。
   - 設定 `agent.skipBootstrap=true`（無 BOOTSTRAP.md）。
   - 如果缺少則種子工作區檔案：
     `AGENTS.md`、`SOUL.md`、`TOOLS.md`、`IDENTITY.md`、`USER.md`、`HEARTBEAT.md`。
   - 預設身份：**C3-PO**（協議機器人）。
   - 在 dev 模式下跳過頻道供應商（`OPENCLAW_SKIP_CHANNELS=1`）。

重設流程（全新開始）：

```bash
pnpm gateway:dev:reset
```

注意：`--dev` 是**全域** profile 旗標，會被某些執行器吃掉。
如果您需要明確拼出它，請使用環境變數形式：

```bash
OPENCLAW_PROFILE=dev openclaw gateway --dev --reset
```

`--reset` 清除設定、憑證、會話和 dev workspace（使用 `trash`，而非 `rm`），然後重新建立預設 dev 設定。

提示：如果非 dev gateway 已在執行（launchd/systemd），請先停止它：

```bash
openclaw gateway stop
```

## 原始串流日誌（OpenClaw）

OpenClaw 可以在任何過濾/格式化之前記錄**原始助理串流**。
這是查看推理是否作為純文字 delta 到達（或作為單獨的思考區塊）的最佳方式。

透過 CLI 啟用：

```bash
pnpm gateway:watch --force --raw-stream
```

選用路徑覆蓋：

```bash
pnpm gateway:watch --force --raw-stream --raw-stream-path ~/.openclaw/logs/raw-stream.jsonl
```

等效環境變數：

```bash
OPENCLAW_RAW_STREAM=1
OPENCLAW_RAW_STREAM_PATH=~/.openclaw/logs/raw-stream.jsonl
```

預設檔案：

`~/.openclaw/logs/raw-stream.jsonl`

## 原始 chunk 日誌（pi-mono）

要在解析為區塊之前捕獲**原始 OpenAI 相容 chunks**，
pi-mono 公開一個單獨的記錄器：

```bash
PI_RAW_STREAM=1
```

選用路徑：

```bash
PI_RAW_STREAM_PATH=~/.pi-mono/logs/raw-openai-completions.jsonl
```

預設檔案：

`~/.pi-mono/logs/raw-openai-completions.jsonl`

> 注意：這僅由使用 pi-mono 的 `openai-completions` 供應商的程序發出。

## 安全注意事項

- 原始串流日誌可以包括完整的提示詞、工具輸出和使用者資料。
- 保持日誌在本地並在除錯後刪除它們。
- 如果您分享日誌，請先清理秘密和 PII。
