---
title: "qwen(Qwen)"
summary: "在 OpenClaw 中使用 Qwen OAuth (免費層級)"
read_when:
  - 想要在 OpenClaw 中使用 Qwen 時
  - 想要使用 Qwen Coder 的免費層級 OAuth 權限時
---

# Qwen

Qwen 為 Qwen Coder 與 Qwen Vision 模型提供免費層級的 OAuth 流程（每日 2,000 次請求，受 Qwen 速率限制規範）。

## 啟用外掛

```bash
openclaw plugins enable qwen-portal-auth
```

啟用後請重新啟動 Gateway。

## 進行認證

```bash
openclaw models auth login --provider qwen-portal --set-default
```

此指令會執行 Qwen 裝置代碼 OAuth 流程，並將供應商項目寫入您的 `models.json`（外加一個 `qwen` 別名以便快速切換）。

## 模型 ID

- `qwen-portal/coder-model`
- `qwen-portal/vision-model`

切換模型：

```bash
openclaw models set qwen-portal/coder-model
```

## 重用 Qwen Code CLI 登入資訊

若您已經使用 Qwen Code CLI 登入，OpenClaw 在載入認證儲存區時，會從 `~/.qwen/oauth_creds.json` 同步憑證。您仍需要建立一個 `models.providers.qwen-portal` 項目（使用上方的登入指令即可建立）。

## 注意事項

- Token 會自動刷新；若刷新失敗或存取權被撤銷，請重新執行登入指令。
- 預設 Base URL：`https://portal.qwen.ai/v1`（若 Qwen 提供不同端點，可透過 `models.providers.qwen-portal.baseUrl` 覆寫）。
- 全供應商通用規則請參閱 [模型服務供應商](/concepts/model-providers)。
