---
title: "opencode(OpenCode Zen)"
summary: "在 OpenClaw 中使用 OpenCode Zen (精選模型)"
read_when:
  - 想要使用 OpenCode Zen 進行模型存取時
  - 想要獲得一份適合編碼任務的精選模型清單時
---

# OpenCode Zen

OpenCode Zen 是一份由 OpenCode 團隊推薦給編碼 Agent 使用的**精選模型清單**。
這是一個選用的託管模型存取路徑，使用 API 金鑰與 `opencode` 供應商。
Zen 目前處於 Beta 階段。

## CLI 設定方式

```bash
openclaw onboard --auth-choice opencode-zen
# 或非互動模式
openclaw onboard --opencode-zen-api-key "$OPENCODE_API_KEY"
```

## 配置範例

```json5
{
  env: { OPENCODE_API_KEY: "sk-..." },
  agents: { defaults: { model: { primary: "opencode/claude-opus-4-5" } } }
}
```

## 注意事項

- 也支援 `OPENCODE_ZEN_API_KEY`。
- 您需要登入 Zen，新增帳單資訊，並複製您的 API 金鑰。
- OpenCode Zen 採按請求計費；詳情請查看 OpenCode 控制台。
