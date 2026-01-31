---
title: "Onboarding(入門流程)"
summary: "OpenClaw macOS 應用程式的初次執行入門流程說明"
read_when:
  - 設計 macOS 入門助理介面時
  - 實作認證或身份設定時
---
# 入門流程 (macOS App)

本文件描述了**目前**的初次執行入門 (First-run Onboarding) 流程。目標是提供平滑的「第 0 天」體驗：選擇 Gateway 執行位置、連接認證、執行引導精靈，並讓 Agent 完成自我引導 (Bootstrap)。

## 頁面順序（目前）

1) 歡迎頁面 + 安全性通知
2) **Gateway 選擇**（本地執行 / 遠端連線 / 稍後設定）
3) **認證 (Anthropic OAuth)** —— 僅限本地模式
4) **設定精靈 (Setup Wizard)** —— 由 Gateway 驅動
5) **權限要求** (TCC 權限提示)
6) **CLI 安裝**（選用）
7) **入門對話**（專屬會話）
8) 完成設定

## 1) 本地 vs 遠端

**Gateway** 在哪裡執行？

- **本地 (這台 Mac)：** 入門流程可以執行 OAuth 流程並將憑證寫入本地路徑。
- **遠端 (經由 SSH/Tailnet)：** 入門流程**不會**在本地執行 OAuth；憑證必須已存在於 Gateway 主機上。
- **稍後設定：** 跳過設定，讓應用程式保持未配置狀態。

Gateway 認證提示：
- 引導精靈現在即使對 loopback 連線也會生成 **Token**，因此本地的 WebSocket 客戶端必須進行認證。
- 如果您停用認證，任何本地程序都可以連線；請僅在完全受信任的機器上這樣做。
- 建議在多機存取或非 loopback 綁定時使用 **Token**。

## 2) 僅限本地認證 (Anthropic OAuth)

macOS 應用程式支援 Anthropic OAuth (Claude Pro/Max)。流程如下：

- 開啟瀏覽器進行 OAuth (PKCE)
- 要求使用者貼上 `code#state` 值
- 將憑證寫入 `~/.openclaw/credentials/oauth.json`

其他供應商（OpenAI、自訂 API）目前需透過環境變數或設定檔進行配置。

## 3) 設定精靈 (Setup Wizard)

應用程式可以執行與 CLI 相同的設定精靈。這讓應用程式的入門流程與 Gateway 端的行為保持同步，避免在 SwiftUI 中重複實作邏輯。

## 4) 權限要求

入門流程會請求以下功能所需的 TCC 權限：

- 通知 (Notifications)
- 輔助功能 (Accessibility)
- 螢幕錄影 (Screen Recording)
- 麥克風 / 語音辨識 (Microphone / Speech Recognition)
- 自動化控制 (Automation / AppleScript)

## 5) CLI（選用）

應用程式可以透過 npm/pnpm 安裝全域 `openclaw` CLI，讓終端機工作流與 launchd 任務能夠即裝即用。

## 6) 入門對話（專屬會話）

完成設定後，應用程式會開啟一個專屬的「入門對話會話」，讓 Agent 進行自我介紹並引導後續步驟。這能將初次執行的指引與您的日常對話區分開來。

## Agent 引導儀式 (Bootstrap ritual)

在 Agent 首次執行時，OpenClaw 會引導工作區 (預設為 `~/.openclaw/workspace`)：

- 產生 `AGENTS.md`, `BOOTSTRAP.md`, `IDENTITY.md`, `USER.md` 初值
- 執行短暫的問答儀式（一次一個問題）
- 將身份與偏好寫入 `IDENTITY.md`, `USER.md`, `SOUL.md`
- 完成後移除 `BOOTSTRAP.md`，因此該儀式僅執行一次

## 遠端模式注意事項

當 Gateway 執行在另一台機器上時，憑證與工作區檔案皆存放在**該主機上**。如果您在遠端模式下需要 OAuth，請在 Gateway 主機上建立：

- `~/.openclaw/credentials/oauth.json`
- `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
