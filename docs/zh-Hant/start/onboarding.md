---
summary: "OpenClaw macOS 應用程式的首次執行入門流程"
read_when:
  - 設計 macOS 入門助理時
  - 實作認證或身份設定時
title: "Onboarding (macOS App)（macOS 應用程式入門流程）"
sidebarTitle: "Onboarding: macOS App"
---

# 入門流程（macOS 應用程式）

本文件描述**目前**的首次執行入門流程。目標是提供流暢的「第 0 天」體驗：選擇 Gateway 執行位置、連接認證、執行精靈，並讓代理程式自我引導。
如需入門路徑的整體概覽，請參閱[入門概覽](/zh-Hant/start/onboarding-overview)。

<Steps>
<Step title="核准 macOS 警告">
<Frame>
<img src="/assets/macos-onboarding/01-macos-warning.jpeg" alt="" />
</Frame>
</Step>
<Step title="核准尋找本地網路">
<Frame>
<img src="/assets/macos-onboarding/02-local-networks.jpeg" alt="" />
</Frame>
</Step>
<Step title="歡迎與安全性通知">
<Frame caption="閱讀顯示的安全性通知並據此做出決定">
<img src="/assets/macos-onboarding/03-security-notice.png" alt="" />
</Frame>

安全信任模型：

- 預設情況下，OpenClaw 是個人代理程式：一個受信任的操作員邊界。
- 共享/多使用者設定需要鎖定（分割信任邊界、保持最少工具存取，並遵循[安全性](/zh-Hant/gateway/security)）。
- 本地入門現在預設將新設定的 `tools.profile` 設為 `"coding"`，因此新的本地設定無需強制使用不受限制的 `full` 設定檔，也能保留檔案系統/執行階段工具。
- 如果啟用了 hooks/webhooks 或其他不受信任的內容饋送，請使用強大的現代模型層，並保持嚴格的工具政策/沙箱。

</Step>
<Step title="本地 vs 遠端">
<Frame>
<img src="/assets/macos-onboarding/04-choose-gateway.png" alt="" />
</Frame>

**Gateway** 在哪裡執行？

- **此 Mac（僅限本地）：**入門可以設定認證並將憑證寫入本地。
- **遠端（透過 SSH/Tailnet）：**入門**不會**設定本地認證；憑證必須存在於 Gateway 主機上。
- **稍後設定：**跳過設定，讓應用程式保持未配置。

<Tip>
**Gateway 認證提示：**

- 精靈現在即使對環回也會產生**令牌**，所以本地 WS 客戶端必須認證。
- 如果您停用認證，任何本地程序都能連線；僅在完全信任的機器上這樣做。
- 多機器存取或非環回綁定時使用**令牌**。

</Tip>
</Step>
<Step title="權限">
<Frame caption="選擇您要授予 OpenClaw 的權限">
<img src="/assets/macos-onboarding/05-permissions.png" alt="" />
</Frame>

入門請求以下功能所需的 TCC 權限：

- 自動化（AppleScript）
- 通知
- 輔助功能
- 螢幕錄製
- 麥克風
- 語音辨識
- 相機
- 位置

</Step>
<Step title="CLI">
  <Info>此步驟為選用</Info>
  應用程式可透過 npm/pnpm 安裝全域 `openclaw` CLI，使終端工作流和 launchd 工作能開箱即用。
</Step>
<Step title="入門聊天（專屬會話）">
  設定完成後，應用程式會開啟一個專屬入門聊天會話，讓代理程式自我介紹並引導後續步驟。這使首次執行的指引與您的正常對話分開。請參閱[引導](/zh-Hant/start/bootstrapping)，了解代理程式首次執行期間 Gateway 主機上發生的情況。
</Step>
</Steps>
