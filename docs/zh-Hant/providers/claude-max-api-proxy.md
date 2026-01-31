---
title: "claude-max-api-proxy(Claude Max API Proxy)"
summary: "使用 Claude Max/Pro 訂閱作為 OpenAI 相容 API 端點"
read_when:
  - 想要在支援 OpenAI 相容工具中使用 Claude Max 訂閱時
  - 想要一個包裝 Claude Code CLI 的本地 API 伺服器時
  - 想要透過訂閱而非 API 金鑰來節省費用時
---

# Claude Max API Proxy

**claude-max-api-proxy** 是一個社群工具，可將您的 Claude Max/Pro 訂閱暴露為 OpenAI 相容的 API 端點。這讓您可以在任何支援 OpenAI API 格式的工具中使用您的訂閱。

## 為何使用此工具？

| 方式 | 成本 | 適用於 |
|----------|------|----------|
| Anthropic API | 按 Token 付費 (Opus 約 $15/M 輸入, $75/M 輸出) | 生產環境應用程式，高用量 |
| Claude Max 訂閱 | $200/月 固定費率 | 個人使用，開發，無限使用量 |

若您擁有 Claude Max 訂閱並希望在 OpenAI 相容工具中使用它，此代理可以為您節省大量費用。

## 運作原理

```
您的應用程式 → claude-max-api-proxy → Claude Code CLI → Anthropic (透過訂閱)
     (OpenAI 格式)              (轉換格式)      (使用您的登入資訊)
```

代理程式會：
1. 接收位於 `http://localhost:3456/v1/chat/completions` 的 OpenAI 格式請求
2. 將其轉換為 Claude Code CLI 指令
3. 以 OpenAI 格式回傳回應（支援串流）

## 安裝

```bash
# 需要 Node.js 20+ 與 Claude Code CLI
npm install -g claude-max-api-proxy

# 驗證 Claude CLI 是否已認證
claude --version
```

## 使用方式

### 啟動伺服器

```bash
claude-max-api
# 伺服器運行於 http://localhost:3456
```

### 測試

```bash
# 健康檢查
curl http://localhost:3456/health

# 列出模型
curl http://localhost:3456/v1/models

# 聊天完成 (Chat completion)
curl http://localhost:3456/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-opus-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### 搭配 OpenClaw 使用

您可以將 OpenClaw 指向該代理，作為自定義的 OpenAI 相容端點：

```json5
{
  env: {
    OPENAI_API_KEY: "not-needed",
    OPENAI_BASE_URL: "http://localhost:3456/v1"
  },
  agents: {
    defaults: {
      model: { primary: "openai/claude-opus-4" }
    }
  }
}
```

## 可用模型

| 模型 ID | 對應至 |
|----------|---------|
| `claude-opus-4` | Claude Opus 4 |
| `claude-sonnet-4` | Claude Sonnet 4 |
| `claude-haiku-4` | Claude Haiku 4 |

## macOS 自動啟動

建立一個 LaunchAgent 以自動運行代理：

```bash
cat > ~/Library/LaunchAgents/com.claude-max-api.plist << 'EOF'
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
EOF

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.claude-max-api.plist
```

## 連結

- **npm:** https://www.npmjs.com/package/claude-max-api-proxy
- **GitHub:** https://github.com/atalovesyou/claude-max-api-proxy
- **Issues:** https://github.com/atalovesyou/claude-max-api-proxy/issues

## 注意事項

- 這是一個**社群工具**，並非由 Anthropic 或 OpenClaw 官方支援
- 需要有效的 Claude Max/Pro 訂閱以及已認證的 Claude Code CLI
- 代理在本地運行，不會傳送資料至第三方伺服器
- 完全支援串流回應

## 參見

- [Anthropic 供應商](/providers/anthropic) - OpenClaw 原生整合，使用 Claude setup-token 或 API 金鑰
- [OpenAI 供應商](/providers/openai) - 用於 OpenAI/Codex 訂閱
