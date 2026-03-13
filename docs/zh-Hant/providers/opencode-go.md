---
summary: "在共享的 OpenCode 設定中使用 OpenCode Go 目錄"
read_when:
  - You want the OpenCode Go catalog
  - You need the runtime model refs for Go-hosted models
title: "OpenCode Go"
---

# OpenCode Go

OpenCode Go 是 [OpenCode](/zh-Hant/providers/opencode) 中的 Go 目錄。
它使用與 Zen 目錄相同的 `OPENCODE_API_KEY`，但保持執行時提供者 ID `opencode-go`，使上游按模型路由保持正確。

## 支援的模型

- `opencode-go/kimi-k2.5`
- `opencode-go/glm-5`
- `opencode-go/minimax-m2.5`

## CLI 設定

```bash
openclaw onboard --auth-choice opencode-go
# or non-interactive
openclaw onboard --opencode-go-api-key "$OPENCODE_API_KEY"
```

## 設定片段

```json5
{
  env: { OPENCODE_API_KEY: "YOUR_API_KEY_HERE" }, // pragma: allowlist secret
  agents: { defaults: { model: { primary: "opencode-go/kimi-k2.5" } } },
}
```

## 路由行為

當模型引用使用 `opencode-go/...` 時，OpenClaw 自動處理按模型路由。

## 備註

- 使用 [OpenCode](/zh-Hant/providers/opencode) 瞭解共享的入門和目錄概覽。
- 執行時引用保持明確：`opencode/...` 用於 Zen，`opencode-go/...` 用於 Go。
