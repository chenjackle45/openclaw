---
summary: "OpenClaw macOS 應用程式的首次執行入門流程"
read_when:
  - 設計 macOS 入門助理時
  - 實作認證或身份設定時
title: "入門流程"
---

# 入門流程（macOS 應用程式）

本文件描述**目前**的首次執行入門流程。目標是提供流暢的「第 0 天」體驗：選擇 Gateway 執行位置、連接認證、執行精靈，並讓代理程式自我引導。

## 頁面順序（目前）

1. 歡迎 + 安全性通知
2. **Gateway 選擇**（本地 / 遠端 / 稍後設定）
3. **認證（Anthropic OAuth）** — 僅限本地
4. **設定精靈**（Gateway 驅動）
5. **權限**（TCC 提示）
6. **CLI**（選用）
7. **入門聊天**（專屬會話）
8. 完成

## 1) 歡迎 + 安全性通知

閱讀顯示的安全性通知並據此做出決定。

## 2) 本地 vs 遠端

**Gateway** 在哪裡執行？

- **本地（此 Mac）：**入門可以執行 OAuth 流程並將認證寫入本地。
- **遠端（透過 SSH/Tailnet）：**入門**不會**在本地執行 OAuth；認證必須存在於 Gateway 主機上。
- **稍後設定：**跳過設定，讓應用程式保持未配置。

Gateway 認證提示：

- 精靈現在即使對環回也會產生**令牌**，所以本地 WS 客戶端必須認證。
- 如果您停用認證，任何本地程序都能連線；僅在完全信任的機器上這樣做。
- 多機器存取或非環回綁定時使用**令牌**。

## 3) 僅限本地認證（Anthropic OAuth）

macOS 應用程式支援 Anthropic OAuth（Claude Pro/Max）。流程：

- 在瀏覽器中開啟 OAuth（PKCE）
- 要求使用者貼上 `code#state` 值
- 將認證寫入 `~/.openclaw/credentials/oauth.json`

其他提供商（OpenAI、自訂 API）目前透過環境變數或設定檔配置。

## 4) 設定精靈（Gateway 驅動）

應用程式可以執行與 CLI 相同的設定精靈。這使入門與 Gateway 端行為保持同步，避免在 SwiftUI 中重複邏輯。

## 5) 權限

入門請求以下功能所需的 TCC 權限：

- 通知
- 輔助功能
- 螢幕錄製
- 麥克風 / 語音辨識
- 自動化（AppleScript）

## 6) CLI（選用）

應用程式可透過 npm/pnpm 安裝全域 `openclaw` CLI，使終端工作流和 launchd 工作能開箱即用。

## 7) 入門聊天（專屬會話）

設定完成後，應用程式會開啟一個專屬入門聊天會話，讓代理程式自我介紹並引導後續步驟。這使首次執行的指引與您的正常對話分開。

## Agent 引導儀式

首次執行時，OpenClaw 會引導工作區（預設 `~/.openclaw/workspace`）：

- 植入 `AGENTS.md`、`BOOTSTRAP.md`、`IDENTITY.md`、`USER.md`
- 執行簡短的 Q&A 儀式（一次一個問題）
- 將身份 + 偏好寫入 `IDENTITY.md`、`USER.md`、`SOUL.md`
- 完成時移除 `BOOTSTRAP.md`，所以它只執行一次

## 選用：Gmail 鉤子（手動）

Gmail Pub/Sub 設定目前是手動步驟。使用：

```bash
openclaw webhooks gmail setup --account you@gmail.com
```

詳見 [/automation/gmail-pubsub](/automation/gmail-pubsub)。

## 遠端模式備註

當 Gateway 在另一台機器上執行時，認證和工作區檔案存放**在該主機上**。如果您在遠端模式下需要 OAuth，請在 Gateway 主機上建立：

- `~/.openclaw/credentials/oauth.json`
- `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
