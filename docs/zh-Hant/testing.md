---
summary: "測試套件：unit/e2e/live 套件、Docker runners 以及每個測試涵蓋的內容"
read_when:
  - 在本地或 CI 中執行測試時
  - 為模型/提供者錯誤新增回歸測試時
  - 偵錯 gateway + agent 行為時
title: "Testing（測試）"
---

# 測試

OpenClaw 有三個 Vitest 套件（unit/integration、e2e、live）和一小組 Docker runners。

本文是「我們如何測試」的指南：

- 每個套件涵蓋什麼（以及刻意*不*涵蓋什麼）
- 常見工作流程（本地、推送前、偵錯）要執行哪些命令
- live 測試如何探索憑證並選擇模型/提供者
- 如何為真實世界的模型/提供者問題新增回歸測試

## 快速開始

大多數日常：

- 完整閘控（推送前預期執行）：`pnpm build && pnpm check && pnpm test`

當您修改測試或想要額外信心時：

- 覆蓋率閘控：`pnpm test:coverage`
- E2E 套件：`pnpm test:e2e`

在偵錯真實提供者/模型時（需要真實憑證）：

- Live 套件（模型 + gateway 工具/圖片探測）：`pnpm test:live`

提示：當您只需要一個失敗案例時，優先透過下面描述的允許清單環境變數縮小 live 測試範圍。

## 測試套件（哪裡執行什麼）

將套件視為「增加真實性」（以及增加不穩定性/成本）：

### Unit / integration（預設）

- 命令：`pnpm test`
- 設定：`scripts/test-parallel.mjs`（執行 `vitest.unit.config.ts`、`vitest.extensions.config.ts`、`vitest.gateway.config.ts`）
- 檔案：`src/**/*.test.ts`、`extensions/**/*.test.ts`
- 範圍：
  - 純 unit 測試
  - 程序內 integration 測試（gateway 認證、路由、工具、解析、設定）
  - 已知錯誤的確定性回歸測試
- 預期：
  - 在 CI 中執行
  - 不需要真實金鑰
  - 應快速且穩定
- Pool 說明：
  - OpenClaw 在 Node 22/23 上使用 Vitest `vmForks` 以加快 unit shards。
  - 在 Node 24+ 上，OpenClaw 自動回退到一般 `forks` 以避免 Node VM 連結錯誤（`ERR_VM_MODULE_LINK_FAILURE` / `module is already linked`）。
  - 手動覆蓋：`OPENCLAW_TEST_VM_FORKS=0`（強制 `forks`）或 `OPENCLAW_TEST_VM_FORKS=1`（強制 `vmForks`）。

### E2E（gateway smoke）

- 命令：`pnpm test:e2e`
- 設定：`vitest.e2e.config.ts`
- 檔案：`src/**/*.e2e.test.ts`
- 執行階段預設：
  - 使用 Vitest `vmForks` 加快檔案啟動。
  - 使用自適應 workers（CI：2-4，本地：4-8）。
  - 預設以靜默模式執行以減少主控台 I/O 開銷。
- 有用的覆蓋：
  - `OPENCLAW_E2E_WORKERS=<n>` 強制 worker 數量（上限 16）。
  - `OPENCLAW_E2E_VERBOSE=1` 重新啟用詳細主控台輸出。
- 範圍：
  - 多實例 gateway 端到端行為
  - WebSocket/HTTP 介面、節點配對和較重的網路
- 預期：
  - 在 CI 中執行（當流水線中啟用時）
  - 不需要真實金鑰
  - 比 unit 測試有更多活動部件（可能較慢）

### Live（真實提供者 + 真實模型）

- 命令：`pnpm test:live`
- 設定：`vitest.live.config.ts`
- 檔案：`src/**/*.live.test.ts`
- 預設：**啟用**透過 `pnpm test:live`（設定 `OPENCLAW_LIVE_TEST=1`）
- 範圍：
  - 「這個提供者/模型今天用真實憑證實際上能運作嗎？」
  - 捕獲提供者格式變更、工具呼叫的怪癖、認證問題和速率限制行為
- 預期：
  - 設計上在 CI 中不穩定（真實網路、真實提供者政策、配額、停機）
  - 花費金錢/使用速率限制
  - 優先執行縮小範圍的子集而非「所有內容」
  - Live 執行將來源 `~/.profile` 以提取缺少的 API key
- API key 輪替（提供者特定）：使用逗號/分號格式設定 `*_API_KEYS`，或 `*_API_KEY_1`、`*_API_KEY_2`（例如 `OPENAI_API_KEYS`、`ANTHROPIC_API_KEYS`、`GEMINI_API_KEYS`）或透過 `OPENCLAW_LIVE_*_KEY` 做每次 live 覆蓋；測試在速率限制回應時重試。

## 我應該執行哪個套件？

使用此決策表：

- 編輯邏輯/測試：執行 `pnpm test`（如果您修改了很多，也執行 `pnpm test:coverage`）
- 修改 gateway 網路 / WS 協定 / 配對：加上 `pnpm test:e2e`
- 偵錯「我的機器人當機了」/ 提供者特定失敗 / 工具呼叫：執行縮小範圍的 `pnpm test:live`

## Live：Android 節點能力掃描

- 測試：`src/gateway/android-node.capabilities.live.test.ts`
- 腳本：`pnpm android:test:integration`
- 目標：呼叫已連線 Android 節點目前**公告的每個命令**並斷言命令合約行為。
- 範圍：
  - 預設定/手動設定（套件不安裝/執行/配對應用程式）。
  - 針對所選 Android 節點的命令對命令 gateway `node.invoke` 驗證。
- 必要的預設定：
  - Android 應用程式已連線並配對到 gateway。
  - 應用程式保持在前景。
  - 已授予您預期通過的能力的權限/擷取同意。
- 選用的目標覆蓋：
  - `OPENCLAW_ANDROID_NODE_ID` 或 `OPENCLAW_ANDROID_NODE_NAME`。
  - `OPENCLAW_ANDROID_GATEWAY_URL` / `OPENCLAW_ANDROID_GATEWAY_TOKEN` / `OPENCLAW_ANDROID_GATEWAY_PASSWORD`。
- 完整的 Android 設定詳情：[Android 應用程式](/zh-Hant/platforms/android)

## Live：模型 smoke（設定檔金鑰）

Live 測試分為兩層，以便我們能夠隔離失敗：

- 「直接模型」告訴我們提供者/模型是否實際上能用給定的金鑰回答。
- 「Gateway smoke」告訴我們該模型的完整 gateway+agent 管道是否正常運作（會話、歷史、工具、沙箱政策等）。

### 第 1 層：直接模型完成（無 gateway）

- 測試：`src/agents/models.profiles.live.test.ts`
- 目標：
  - 枚舉已發現的模型
  - 使用 `getApiKeyForModel` 選擇您有憑證的模型
  - 每個模型執行一次小型完成（必要時執行目標回歸測試）
- 啟用方式：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
- 設定 `OPENCLAW_LIVE_MODELS=modern`（或 `all`，是 modern 的別名）以實際執行此套件；否則跳過以保持 `pnpm test:live` 專注於 gateway smoke
- 如何選擇模型：
  - `OPENCLAW_LIVE_MODELS=modern` 執行現代允許清單（Opus/Sonnet/Haiku 4.5、GPT-5.x + Codex、Gemini 3、GLM 4.7、MiniMax M2.5、Grok 4）
  - `OPENCLAW_LIVE_MODELS=all` 是現代允許清單的別名
  - 或 `OPENCLAW_LIVE_MODELS="openai/gpt-5.2,anthropic/claude-opus-4-6,..."`（逗號允許清單）
- 如何選擇提供者：
  - `OPENCLAW_LIVE_PROVIDERS="google,google-antigravity,google-gemini-cli"`（逗號允許清單）
- 金鑰來源：
  - 預設：設定檔儲存和 env 後備
  - 設定 `OPENCLAW_LIVE_REQUIRE_PROFILE_KEYS=1` 僅強制使用**設定檔儲存**
- 為何存在：
  - 將「提供者 API 損壞 / 金鑰無效」與「gateway agent 管道損壞」分開
  - 包含小型、隔離的回歸測試（例如：OpenAI Responses/Codex Responses 推理重播 + 工具呼叫流程）

### 第 2 層：Gateway + 開發版 agent smoke（「@openclaw」實際執行的內容）

- 測試：`src/gateway/gateway-models.profiles.live.test.ts`
- 目標：
  - 啟動程序內 gateway
  - 建立/修補 `agent:dev:*` 會話（每次執行的模型覆蓋）
  - 迭代有金鑰的模型並斷言：
    - 「有意義的」回應（無工具）
    - 真實工具呼叫有效（read 探測）
    - 選用的額外工具探測（exec+read 探測）
    - OpenAI 回歸路徑（只有工具呼叫 → 後續）保持正常
- 探測詳情（讓您能快速說明失敗）：
  - `read` 探測：測試在工作區寫入一個 nonce 檔案，並要求 agent 讀取它並回傳 nonce。
  - `exec+read` 探測：測試要求 agent `exec` 寫入 nonce 到暫存檔案，然後讀取它。
  - 圖片探測：測試附加一個生成的 PNG（貓 + 隨機代碼）並期望模型回傳 `cat <CODE>`。
  - 實作參考：`src/gateway/gateway-models.profiles.live.test.ts` 和 `src/gateway/live-image-probe.ts`。
- 啟用方式：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
- 如何選擇模型：
  - 預設：現代允許清單（Opus/Sonnet/Haiku 4.5、GPT-5.x + Codex、Gemini 3、GLM 4.7、MiniMax M2.5、Grok 4）
  - `OPENCLAW_LIVE_GATEWAY_MODELS=all` 是現代允許清單的別名
  - 或設定 `OPENCLAW_LIVE_GATEWAY_MODELS="provider/model"`（或逗號清單）以縮小範圍
- 如何選擇提供者（避免「OpenRouter 所有內容」）：
  - `OPENCLAW_LIVE_GATEWAY_PROVIDERS="google,google-antigravity,google-gemini-cli,openai,anthropic,zai,minimax"`（逗號允許清單）
- 此 live 測試中工具 + 圖片探測始終開啟：
  - `read` 探測 + `exec+read` 探測（工具壓力測試）
  - 當模型公告支援圖片輸入時執行圖片探測
  - 流程（高層次）：
    - 測試使用「CAT」+ 隨機代碼生成一個小 PNG（`src/gateway/live-image-probe.ts`）
    - 透過 `agent` `attachments: [{ mimeType: "image/png", content: "<base64>" }]` 傳送
    - Gateway 將附件解析為 `images[]`（`src/gateway/server-methods/agent.ts` + `src/gateway/chat-attachments.ts`）
    - 嵌入式 agent 轉發多模態使用者訊息給模型
    - 斷言：回覆包含 `cat` + 代碼（OCR 容忍度：允許輕微錯誤）

提示：要查看您的機器上可以測試的內容（以及確切的 `provider/model` ids），請執行：

```bash
openclaw models list
openclaw models list --json
```

## Live：Anthropic setup-token smoke

- 測試：`src/agents/anthropic.setup-token.live.test.ts`
- 目標：驗證 Claude Code CLI setup-token（或貼上的 setup-token 設定檔）是否能完成 Anthropic 提示。
- 啟用：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
  - `OPENCLAW_LIVE_SETUP_TOKEN=1`
- Token 來源（選擇一個）：
  - 設定檔：`OPENCLAW_LIVE_SETUP_TOKEN_PROFILE=anthropic:setup-token-test`
  - 原始 token：`OPENCLAW_LIVE_SETUP_TOKEN_VALUE=sk-ant-oat01-...`
- 模型覆蓋（選用）：
  - `OPENCLAW_LIVE_SETUP_TOKEN_MODEL=anthropic/claude-opus-4-6`

設定範例：

```bash
openclaw models auth paste-token --provider anthropic --profile-id anthropic:setup-token-test
OPENCLAW_LIVE_SETUP_TOKEN=1 OPENCLAW_LIVE_SETUP_TOKEN_PROFILE=anthropic:setup-token-test pnpm test:live src/agents/anthropic.setup-token.live.test.ts
```

## Live：CLI 後端 smoke（Claude Code CLI 或其他本地 CLI）

- 測試：`src/gateway/gateway-cli-backend.live.test.ts`
- 目標：使用本地 CLI 後端驗證 Gateway + agent 管道，而不影響您的預設設定。
- 啟用：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
  - `OPENCLAW_LIVE_CLI_BACKEND=1`
- 預設：
  - 模型：`claude-cli/claude-sonnet-4-6`
  - 命令：`claude`
  - 參數：`["-p","--output-format","json","--permission-mode","bypassPermissions"]`
- 覆蓋（選用）：
  - `OPENCLAW_LIVE_CLI_BACKEND_MODEL="claude-cli/claude-opus-4-6"`
  - `OPENCLAW_LIVE_CLI_BACKEND_MODEL="codex-cli/gpt-5.4"`
  - `OPENCLAW_LIVE_CLI_BACKEND_COMMAND="/full/path/to/claude"`
  - `OPENCLAW_LIVE_CLI_BACKEND_ARGS='["-p","--output-format","json","--permission-mode","bypassPermissions"]'`
  - `OPENCLAW_LIVE_CLI_BACKEND_CLEAR_ENV='["ANTHROPIC_API_KEY","ANTHROPIC_API_KEY_OLD"]'`
  - `OPENCLAW_LIVE_CLI_BACKEND_IMAGE_PROBE=1` 傳送真實圖片附件（路徑注入提示中）。
  - `OPENCLAW_LIVE_CLI_BACKEND_IMAGE_ARG="--image"` 以 CLI 參數傳遞圖片檔案路徑而非提示注入。
  - `OPENCLAW_LIVE_CLI_BACKEND_IMAGE_MODE="repeat"`（或 `"list"`）控制設定 `IMAGE_ARG` 時如何傳遞圖片參數。
  - `OPENCLAW_LIVE_CLI_BACKEND_RESUME_PROBE=1` 傳送第二輪並驗證恢復流程。
- `OPENCLAW_LIVE_CLI_BACKEND_DISABLE_MCP_CONFIG=0` 保持 Claude Code CLI MCP 設定啟用（預設使用暫存空白檔案停用 MCP 設定）。

範例：

```bash
OPENCLAW_LIVE_CLI_BACKEND=1 \
  OPENCLAW_LIVE_CLI_BACKEND_MODEL="claude-cli/claude-sonnet-4-6" \
  pnpm test:live src/gateway/gateway-cli-backend.live.test.ts
```

### 推薦的 live 配方

縮小範圍的明確允許清單最快且最穩定：

- 單一模型，直接（無 gateway）：
  - `OPENCLAW_LIVE_MODELS="openai/gpt-5.2" pnpm test:live src/agents/models.profiles.live.test.ts`

- 單一模型，gateway smoke：
  - `OPENCLAW_LIVE_GATEWAY_MODELS="openai/gpt-5.2" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

- 多個提供者的工具呼叫：
  - `OPENCLAW_LIVE_GATEWAY_MODELS="openai/gpt-5.2,anthropic/claude-opus-4-6,google/gemini-3-flash-preview,zai/glm-4.7,minimax/minimax-m2.5" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

- Google 焦點（Gemini API key + Antigravity）：
  - Gemini（API key）：`OPENCLAW_LIVE_GATEWAY_MODELS="google/gemini-3-flash-preview" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`
  - Antigravity（OAuth）：`OPENCLAW_LIVE_GATEWAY_MODELS="google-antigravity/claude-opus-4-6-thinking,google-antigravity/gemini-3-pro-high" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

說明：

- `google/...` 使用 Gemini API（API key）。
- `google-antigravity/...` 使用 Antigravity OAuth bridge（Cloud Code Assist 風格的 agent 端點）。
- `google-gemini-cli/...` 使用您機器上的本地 Gemini CLI（獨立認證 + 工具怪癖）。
- Gemini API vs Gemini CLI：
  - API：OpenClaw 透過 HTTP 呼叫 Google 託管的 Gemini API（API key / 設定檔認證）；這是大多數使用者所說的「Gemini」。
  - CLI：OpenClaw 呼叫本地 `gemini` 二進位；它有自己的認證且行為可能不同（串流/工具支援/版本差異）。

## Live：模型矩陣（我們涵蓋什麼）

沒有固定的「CI 模型清單」（live 為選用啟用），但這些是我們預期在有金鑰的開發機器上定期涵蓋的**推薦**模型。

### 現代 smoke 集（工具呼叫 + 圖片）

這是我們預期保持運作的「常見模型」執行：

- OpenAI（非 Codex）：`openai/gpt-5.2`（選用：`openai/gpt-5.1`）
- OpenAI Codex：`openai-codex/gpt-5.4`
- Anthropic：`anthropic/claude-opus-4-6`（或 `anthropic/claude-sonnet-4-5`）
- Google（Gemini API）：`google/gemini-3.1-pro-preview` 和 `google/gemini-3-flash-preview`（避免較舊的 Gemini 2.x 模型）
- Google（Antigravity）：`google-antigravity/claude-opus-4-6-thinking` 和 `google-antigravity/gemini-3-flash`
- Z.AI（GLM）：`zai/glm-4.7`
- MiniMax：`minimax/minimax-m2.5`

使用工具 + 圖片執行 gateway smoke：
`OPENCLAW_LIVE_GATEWAY_MODELS="openai/gpt-5.2,openai-codex/gpt-5.4,anthropic/claude-opus-4-6,google/gemini-3.1-pro-preview,google/gemini-3-flash-preview,google-antigravity/claude-opus-4-6-thinking,google-antigravity/gemini-3-flash,zai/glm-4.7,minimax/minimax-m2.5" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

### 基準線：工具呼叫（Read + 選用 Exec）

每個提供者系列至少選一個：

- OpenAI：`openai/gpt-5.2`（或 `openai/gpt-5-mini`）
- Anthropic：`anthropic/claude-opus-4-6`（或 `anthropic/claude-sonnet-4-5`）
- Google：`google/gemini-3-flash-preview`（或 `google/gemini-3.1-pro-preview`）
- Z.AI（GLM）：`zai/glm-4.7`
- MiniMax：`minimax/minimax-m2.5`

選用的額外涵蓋（錦上添花）：

- xAI：`xai/grok-4`（或最新可用）
- Mistral：`mistral/`…（選擇一個您已啟用且支援工具的模型）
- Cerebras：`cerebras/`…（如果您有存取權）
- LM Studio：`lmstudio/`…（本地；工具呼叫取決於 API 模式）

### Vision：圖片傳送（附件 → 多模態訊息）

在 `OPENCLAW_LIVE_GATEWAY_MODELS` 中包含至少一個支援圖片的模型（Claude/Gemini/OpenAI 支援視覺的變體等）以測試圖片探測。

### 聚合器 / 替代 gateway

如果您有啟用的金鑰，我們也支援透過以下方式測試：

- OpenRouter：`openrouter/...`（數百個模型；使用 `openclaw models scan` 找到支援工具+圖片的候選）
- OpenCode Zen：`opencode/...`（透過 `OPENCODE_API_KEY` / `OPENCODE_ZEN_API_KEY` 認證）

更多您可以包含在 live 矩陣中的提供者（如果您有憑證/設定）：

- 內建：`openai`、`openai-codex`、`anthropic`、`google`、`google-vertex`、`google-antigravity`、`google-gemini-cli`、`zai`、`openrouter`、`opencode`、`xai`、`groq`、`cerebras`、`mistral`、`github-copilot`
- 透過 `models.providers`（自訂端點）：`minimax`（雲端/API），加上任何 OpenAI/Anthropic 相容代理（LM Studio、vLLM、LiteLLM 等）

提示：不要試圖在文件中寫死「所有模型」。權威清單是您的機器上 `discoverModels(...)` 返回的內容 + 可用金鑰。

## 憑證（永不提交）

Live 測試與 CLI 用相同方式探索憑證。實際含義：

- 如果 CLI 正常運作，live 測試應找到相同的金鑰。
- 如果 live 測試說「無憑證」，以偵錯 `openclaw models list` / 模型選擇的相同方式偵錯。

- 設定檔儲存：`~/.openclaw/credentials/`（首選；測試中「設定檔金鑰」的含義）
- 設定：`~/.openclaw/openclaw.json`（或 `OPENCLAW_CONFIG_PATH`）

如果您想依賴 env 金鑰（例如在 `~/.profile` 中匯出），請在 `source ~/.profile` 後執行本地測試，或使用下面的 Docker runners（它們可以將 `~/.profile` 掛載到容器中）。

## Deepgram live（音訊轉錄）

- 測試：`src/media-understanding/providers/deepgram/audio.live.test.ts`
- 啟用：`DEEPGRAM_API_KEY=... DEEPGRAM_LIVE_TEST=1 pnpm test:live src/media-understanding/providers/deepgram/audio.live.test.ts`

## BytePlus 編碼計劃 live

- 測試：`src/agents/byteplus.live.test.ts`
- 啟用：`BYTEPLUS_API_KEY=... BYTEPLUS_LIVE_TEST=1 pnpm test:live src/agents/byteplus.live.test.ts`
- 選用模型覆蓋：`BYTEPLUS_CODING_MODEL=ark-code-latest`

## Docker runners（選用的「在 Linux 上有效」檢查）

這些在 repo Docker 映像中執行 `pnpm test:live`，掛載您的本地設定目錄和工作區（如果掛載則來源 `~/.profile`）：

- 直接模型：`pnpm test:docker:live-models`（腳本：`scripts/test-live-models-docker.sh`）
- Gateway + 開發版 agent：`pnpm test:docker:live-gateway`（腳本：`scripts/test-live-gateway-models-docker.sh`）
- 入門精靈（TTY，完整腳手架）：`pnpm test:docker:onboard`（腳本：`scripts/e2e/onboard-docker.sh`）
- Gateway 網路（兩個容器，WS 認證 + 健康）：`pnpm test:docker:gateway-network`（腳本：`scripts/e2e/gateway-network-docker.sh`）
- 外掛（自訂擴充功能載入 + 登錄 smoke）：`pnpm test:docker:plugins`（腳本：`scripts/e2e/plugins-docker.sh`）

live-model Docker runners 也以唯讀方式綁定掛載目前的 checkout，並在容器內的暫存工作目錄中暫存它。這使執行階段映像保持精簡，同時仍針對您的確切本地原始碼/設定執行 Vitest。

手動 ACP 純語言執行緒 smoke（非 CI）：

- `bun scripts/dev/discord-acp-plain-language-smoke.ts --channel <discord-channel-id> ...`
- 保留此腳本以供回歸/偵錯工作流程使用。它可能再次需要用於 ACP 執行緒路由驗證，因此不要刪除它。

有用的環境變數：

- `OPENCLAW_CONFIG_DIR=...`（預設：`~/.openclaw`）掛載到 `/home/node/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=...`（預設：`~/.openclaw/workspace`）掛載到 `/home/node/.openclaw/workspace`
- `OPENCLAW_PROFILE_FILE=...`（預設：`~/.profile`）掛載到 `/home/node/.profile` 並在執行測試前來源
- `OPENCLAW_LIVE_GATEWAY_MODELS=...` / `OPENCLAW_LIVE_MODELS=...` 縮小執行範圍
- `OPENCLAW_LIVE_REQUIRE_PROFILE_KEYS=1` 確保憑證來自設定檔儲存（非 env）

## 文件健全性

文件編輯後執行文件檢查：`pnpm docs:list`。

## 離線回歸（CI 安全）

這些是沒有真實提供者的「真實管道」回歸：

- Gateway 工具呼叫（模擬 OpenAI，真實 gateway + agent 迴圈）：`src/gateway/gateway.test.ts`（案例：「透過 gateway agent 迴圈端對端執行模擬 OpenAI 工具呼叫」）
- Gateway 精靈（WS `wizard.start`/`wizard.next`，寫入設定 + 強制認證）：`src/gateway/gateway.test.ts`（案例：「透過 ws 執行精靈並寫入認證 token 設定」）

## Agent 可靠性評估（技能）

我們已經有一些行為類似「agent 可靠性評估」的 CI 安全測試：

- 透過真實 gateway + agent 迴圈的模擬工具呼叫（`src/gateway/gateway.test.ts`）。
- 驗證會話接線和設定效果的端對端精靈流程（`src/gateway/gateway.test.ts`）。

技能目前仍缺少的內容（請參閱[技能](/zh-Hant/tools/skills)）：

- **決策：**當技能列在提示中時，agent 是否選擇正確的技能（或避免不相關的技能）？
- **合規：**agent 是否在使用前閱讀 `SKILL.md` 並遵循必要的步驟/參數？
- **工作流程合約：**斷言工具順序、會話歷史延續和沙箱邊界的多輪場景。

未來的評估應先保持確定性：

- 使用模擬提供者斷言工具呼叫 + 順序、技能檔案讀取和會話接線的場景執行器。
- 一小組以技能為焦點的場景（使用 vs 避免、閘控、提示注入）。
- 選用的 live 評估（選用啟用，env 閘控）僅在 CI 安全套件就位後。

## 新增回歸（指南）

修復在 live 中發現的提供者/模型問題時：

- 如果可能，新增 CI 安全回歸（模擬/存根提供者，或擷取確切的請求形狀轉換）
- 如果本質上是只能 live 的（速率限制、認證政策），保持 live 測試縮小範圍並透過環境變數選用啟用
- 優先針對捕獲錯誤的最小層：
  - 提供者請求轉換/重播錯誤 → 直接模型測試
  - gateway 會話/歷史/工具管道錯誤 → gateway live smoke 或 CI 安全 gateway 模擬測試
