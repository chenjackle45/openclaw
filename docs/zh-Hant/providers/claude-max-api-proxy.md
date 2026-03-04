---
summary: "社群代理以 OpenAI 相容端點方式公開 Claude 訂閱認證"
read_when:
  - You want to use Claude Max subscription with OpenAI-compatible tools
  - You want a local API server that wraps Claude Code CLI
  - You want to evaluate subscription-based vs API-key-based Anthropic access
title: "Claude Max API Proxy（Claude Max API Proxy）"
---

# Claude Max API Proxy

**claude-max-api-proxy** 是一個社群工具，將 Claude Max/Pro 訂閱公開為 OpenAI 相容 API 端點。這讓您可以與任何支援 OpenAI API 格式的工具一起使用訂閱。

<Warning>
此路徑僅用於技術相容性。Anthropic 過去曾封鎖某些訂閱在 Claude Code 外的使用。您必須自行決定是否使用，並在依賴它之前驗證 Anthropic 的目前條款。
</Warning>

## 為什麼使用這個？

| 方法            | 成本                                         | 最佳用於                 |
| --------------- | -------------------------------------------- | ------------------------ |
| Anthropic API   | 按令牌付費（Opus 約 $15/M 輸入、$75/M 輸出） | 生產應用、高流量         |
| Claude Max 訂閱 | $200/月固定                                  | 個人使用、開發、無限使用 |

如果您有 Claude Max 訂閱並想用 OpenAI 相容工具，此代理可能會降低某些工作流程的成本。API 鑰仍是生產使用的更清晰政策路徑。

## 運作方式

```
Your App → claude-max-api-proxy → Claude Code CLI → Anthropic（透過訂閱）
   (OpenAI 格式)     (轉換格式)          (使用您的登入)
```

代理：

1. 在 `http://localhost:3456/v1/chat/completions` 接受 OpenAI 格式請求
2. 將它們轉換為 Claude Code CLI 命令
3. 以 OpenAI 格式返回回應（支援串流）

## 安裝

```bash
# 需要 Node.js 20+ 和 Claude Code CLI
npm install -g claude-max-api-proxy

# 驗證 Claude CLI 已認證
claude --version
```

## 使用

### 啟動伺服器

```bash
claude-max-api
# 伺服器在 http://localhost:3456 執行
```

### 測試它

```bash
# 健康狀況檢查
curl http://localhost:3456/health

# 列出模型
curl http://localhost:3456/v1/models

# 聊天完成
curl http://localhost:3456/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-opus-4", "messages": [{"role": "user", "content": "Hello!"}]}'
```

### 使用 OpenClaw

您可以將 OpenClaw 指向代理作為自訂 OpenAI 相容端點：

```json5
{
  env: {
    OPENAI_API_KEY: "not-needed",
    OPENAI_BASE_URL: "http://localhost:3456/v1",
  },
  agents: {
    defaults: {
      model: { primary: "openai/claude-opus-4" },
    },
  },
}
```

## 可用模型

| 模型 ID           | 映射到          |
| ----------------- | --------------- |
| `claude-opus-4`   | Claude Opus 4   |
| `claude-sonnet-4` | Claude Sonnet 4 |
| `claude-haiku-4`  | Claude Haiku 4  |

## macOS 上自動啟動

建立 LaunchAgent 以自動執行代理：

```bash
cat > ~/Library/LaunchAgents/com.claude-max-api.plist << 'LAUNCHEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.claude-max-api</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/node</string>
    <string>/usr/local/lib/node_modules/claude-max-api-proxy/dist/server/standalone.js</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:~/.local/bin:/usr/bin:/bin</string>
  </dict>
</dict>
</plist>
LAUNCHEOF

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.claude-max-api.plist
```

## 連結

- **npm：** [https://www.npmjs.com/package/claude-max-api-proxy](https://www.npmjs.com/package/claude-max-api-proxy)
- **GitHub：** [https://github.com/atalovesyou/claude-max-api-proxy](https://github.com/atalovesyou/claude-max-api-proxy)
- **問題：** [https://github.com/atalovesyou/claude-max-api-proxy/issues](https://github.com/atalovesyou/claude-max-api-proxy/issues)

## 註記

- 這是一個**社群工具**，不是由 Anthropic 或 OpenClaw 官方支援
- 需要使用 Claude Code CLI 認證的有效 Claude Max/Pro 訂閱
- 代理在本機執行，不向任何第三方伺服器發送資料
- 完全支援串流回應

## 另見

- [Anthropic 提供者](/zh-Hant/providers/anthropic) - 透過 Claude setup-token 或 API 鑰的原生 OpenClaw 整合
- [OpenAI 提供者](/zh-Hant/providers/openai) - 適用於 OpenAI/Codex 訂閱
