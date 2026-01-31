---
title: "Oauth(OAuth 認證)"
summary: "OpenClaw 中的 OAuth：權杖交換、儲存與多帳戶模式"
read_when:
  - 您想完整了解 OpenClaw 的 OAuth 流程
  - 您遇到權杖失效 / 登出問題
  - 您想使用 setup-token 或 OAuth 認證流程
  - 您想要多帳戶或設定檔路由功能
---
# OAuth（OAuth 認證）

OpenClaw 針對提供此功能的供應商（特別是 **OpenAI Codex (ChatGPT OAuth)**）支援透過 OAuth 進行「訂閱認證」。對於 Anthropic 訂閱，請使用 **setup-token** 流程。本頁面解釋：

- OAuth **權杖交換** 如何運作 (PKCE)
- 權杖**儲存**位置（以及原因）
- 如何處理**多個帳戶**（設定檔 + 每會話覆寫）

OpenClaw 也支援提供自定義 OAuth 或 API 金鑰流程的**供應商外掛**。透過以下命令執行：

```bash
openclaw models auth login --provider <id>
```

## 權杖接收器 (Token sink)（它存在的原因）

OAuth 供應商通常會在登入/重新整理流程中核發**新的重新整理權杖 (refresh token)**。有些供應商（或 OAuth 客戶端）會在為同一個使用者/應用程式核發新權杖時，讓舊的權杖失效。

實際症狀：
- 您同時透過 OpenClaw *與* Claude Code / Codex CLI 登入 -> 其中一個稍後會隨機被「登出」。

為了減少這種情況，OpenClaw 將 `auth-profiles.json` 視為**權杖接收器 (token sink)**：
- 執行環境從**單一位置**讀取憑證。
- 我們可以保留多個設定檔並進行確定性的路由。

## 儲存（權杖存放位置）

秘密（秘密資訊）是**按代理**儲存的：

- 認證設定檔（OAuth + API 金鑰）：`~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
- 執行時快取（自動管理；請勿編輯）：`~/.openclaw/agents/<agentId>/agent/auth.json`

舊版僅供匯入的檔案（仍支援，但不是主儲存點）：
- `~/.openclaw/credentials/oauth.json`（首次使用時會匯入到 `auth-profiles.json` 中）

以上所有路徑均遵循 `$OPENCLAW_STATE_DIR`（狀態目錄覆寫）。完整參考：[/gateway/configuration](/gateway/configuration#auth-storage-oauth--api-keys)

## Anthropic setup-token（訂閱認證）

在任何機器上運行 `claude setup-token`，然後將其貼入 OpenClaw：

```bash
openclaw models auth setup-token --provider anthropic
```

如果您在其他地方生成了權杖，請手動貼上：

```bash
openclaw models auth paste-token --provider anthropic
```

驗證：

```bash
openclaw models status
```

## OAuth 交換（登入如何運作）

OpenClaw 的互動式登入流程實作於 `@mariozechner/pi-ai` 中，並與引導精靈/命令相連接。

### Anthropic (Claude Pro/Max) setup-token

流程形狀：
1. 執行 `claude setup-token`
2. 將權杖貼入 OpenClaw
3. 儲存為權杖認證設定檔（無重新整理機制）

引導精靈路徑為 `openclaw onboard` → 認證選擇 `setup-token` (Anthropic)。

### OpenAI Codex (ChatGPT OAuth)

流程形狀 (PKCE)：
1. 生成 PKCE 驗證器 (verifier)/挑戰碼 (challenge) + 隨機 `state`
2. 開啟 `https://auth.openai.com/oauth/authorize?...`
3. 嘗試在 `http://127.0.0.1:1455/auth/callback` 捕捉回呼 (callback)
4. 如果回呼無法繫結（或者您是在遠端/無頭模式下），請貼上重新導向 URL/代碼
5. 在 `https://auth.openai.com/oauth/token` 進行交換
6. 從存取權杖中提取 `accountId` 並儲存 `{ access, refresh, expires, accountId }`

引導精靈路徑為 `openclaw onboard` → 認證選擇 `openai-codex`。

## 重新整理與過期

設定檔儲存了一個 `expires` 時間戳記。

在執行時：
- 如果 `expires` 在未來 -> 使用儲存的存取權杖。
- 如果已過期 -> 執行重新整理（在檔案鎖定下）並覆寫儲存的憑證。

重新整理流程是自動的；您通常不需要手動管理權杖。

## 多個帳戶（設定檔）與路由

兩種模式：

### 1) 推薦方式：獨立的代理 (Agents)

如果您希望「個人」和「工作」帳戶永不交叉，請使用隔離的代理（獨立的會話 + 憑證 + 工作區）：

```bash
openclaw agents add work
openclaw agents add personal
```

然後按代理進行認證設定（使用精靈），並將聊天路由到正確的代理。

### 2) 進階方式：單個代理中的多個設定檔

`auth-profiles.json` 支援同一個供應商的多個設定檔 ID。

挑選使用的設定檔：
- 透過組態順序 (`auth.order`) 進行全域設定
- 透過 `/model ...@<profileId>` 進行每會話覆寫

範例（會話覆寫）：
- `/model Opus@anthropic:work`

如何查看存在哪些設定檔 ID：
- `openclaw channels list --json` (查看 `auth[]` 欄位)

相關文件：
- [/concepts/model-failover](/concepts/model-failover)（輪換與冷卻規則）
- [/tools/slash-commands](/tools/slash-commands)（命令介面）
