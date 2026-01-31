---
title: "Testing(測試)"
summary: "測試套件：unit/e2e/live 套件、Docker runners 以及每個測試涵蓋的內容"
read_when:
  - 在本地或 CI 中執行測試
  - 為模型/供應商 bugs 新增回歸測試
  - 除錯 gateway + agent 行為
---

# Testing(測試)

OpenClaw 有三個 Vitest 套件（unit/integration、e2e、live）和一小組 Docker runners。

本文件是「我們如何測試」的指南：
- 每個套件涵蓋什麼（以及故意*不*涵蓋什麼）
- 常見工作流程要執行哪些指令（本地、推送前、除錯）
- live 測試如何發現憑證並選擇模型/供應商
- 如何為真實世界的模型/供應商問題新增回歸測試

## 快速開始

大多數日子：
- 完整 gate（推送前預期）：`pnpm lint && pnpm build && pnpm test`

當您觸及測試或想要額外信心時：
- Coverage gate：`pnpm test:coverage`
- E2E 套件：`pnpm test:e2e`

除錯真實供應商/模型時（需要真實憑證）：
- Live 套件（模型 + gateway tool/image 探測）：`pnpm test:live`

提示：當您只需要一個失敗案例時，透過下面描述的允許清單環境變數優選縮小 live 測試。

## 測試套件（什麼在哪裡執行）

將套件視為「增加真實性」（以及增加不穩定性/成本）：

### Unit / integration（預設）

- 指令：`pnpm test`
- 設定：`vitest.config.ts`
- 檔案：`src/**/*.test.ts`
- 範圍：
  - 純單元測試
  - 程序內整合測試（gateway auth、routing、tooling、parsing、config）
  - 已知 bugs 的確定性回歸測試
- 期望：
  - 在 CI 中執行
  - 不需要真實金鑰
  - 應該快速穩定

### E2E（gateway smoke）

- 指令：`pnpm test:e2e`
- 設定：`vitest.e2e.config.ts`
- 檔案：`src/**/*.e2e.test.ts`
- 範圍：
  - 多實例 gateway 端到端行為
  - WebSocket/HTTP 介面、節點配對和更重的網路
- 期望：
  - 在 CI 中執行（當在流水線中啟用時）
  - 不需要真實金鑰
  - 比單元測試更多的可動部件（可能更慢）

### Live（真實供應商 + 真實模型）

- 指令：`pnpm test:live`
- 設定：`vitest.live.config.ts`
- 檔案：`src/**/*.live.test.ts`
- 預設：由 `pnpm test:live` **啟用**（設定 `OPENCLAW_LIVE_TEST=1`）
- 範圍：
  - 「這個供應商/模型今天是否真的使用真實憑證運作？」
  - 捕獲供應商格式變更、工具呼叫怪癖、認證問題和速率限制行為
- 期望：
  - 設計上不穩定於 CI（真實網路、真實供應商策略、配額、中斷）
  - 花費金錢/使用速率限制
  - 優選執行縮小的子集而不是「所有」
  - Live 執行將來源 `~/.profile` 以提取缺少的 API 金鑰
  - Anthropic 金鑰輪換：設定 `OPENCLAW_LIVE_ANTHROPIC_KEYS="sk-...,sk-..."` （或 `OPENCLAW_LIVE_ANTHROPIC_KEY=sk-...`）或多個 `ANTHROPIC_API_KEY*` 變數；測試將在速率限制時重試

## 我應該執行哪個套件？

使用此決策表：
- 編輯邏輯/測試：執行 `pnpm test`（如果您變更了很多，則 `pnpm test:coverage`）
- 觸及 gateway 網路 / WS 協定 / 配對：新增 `pnpm test:e2e`
- 除錯「我的機器人掛了」/ 供應商特定失敗 / 工具呼叫：執行縮小的 `pnpm test:live`

## Live：模型 smoke（profile 金鑰）

Live 測試分為兩層，以便我們可以隔離故障：
- 「直接模型」告訴我們供應商/模型是否可以使用給定金鑰回答。
- 「Gateway smoke」告訴我們完整的 gateway+agent 流水線對該模型是否有效（sessions、history、tools、sandbox policy 等）。

### 層 1：直接模型完成（無 gateway）

- 測試：`src/agents/models.profiles.live.test.ts`
- 目標：
  - 列舉發現的模型
  - 使用 `getApiKeyForModel` 選擇您有憑證的模型
  - 每個模型執行一個小完成（並在需要時進行針對性回歸測試）
- 如何啟用：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
- 設定 `OPENCLAW_LIVE_MODELS=modern`（或 `all`，modern 的別名）以實際執行此套件；否則它會跳過以保持 `pnpm test:live` 專注於 gateway smoke
- 如何選擇模型：
  - `OPENCLAW_LIVE_MODELS=modern` 執行 modern 允許清單（Opus/Sonnet/Haiku 4.5、GPT-5.x + Codex、Gemini 3、GLM 4.7、MiniMax M2.1、Grok 4）
  - `OPENCLAW_LIVE_MODELS=all` 是 modern 允許清單的別名
  - 或 `OPENCLAW_LIVE_MODELS="openai/gpt-5.2,anthropic/claude-opus-4-5,..."`（逗號允許清單）
- 如何選擇供應商：
  - `OPENCLAW_LIVE_PROVIDERS="google,google-antigravity,google-gemini-cli"`（逗號允許清單）
- 金鑰來自何處：
  - 預設：profile 儲存和環境變數回退
  - 設定 `OPENCLAW_LIVE_REQUIRE_PROFILE_KEYS=1` 僅強制執行 **profile 儲存**
- 為什麼存在：
  - 分離「供應商 API 壞了/金鑰無效」與「gateway agent 流水線壞了」
  - 包含小型、隔離的回歸測試（範例：OpenAI Responses/Codex Responses reasoning replay + tool-call flows）

### 層 2：Gateway + dev agent smoke（"@openclaw" 實際做什麼）

- 測試：`src/gateway/gateway-models.profiles.live.test.ts`
- 目標：
  - 啟動程序內 gateway
  - 建立/修補 `agent:dev:*` 會話（每次執行模型覆蓋）
  - 迭代 models-with-keys 並斷言：
    - 「有意義的」回應（無工具）
    - 真實工具呼叫有效（read 探測）
    - 選用額外工具探測（exec+read 探測）
    - OpenAI 回歸路徑（tool-call-only → follow-up）保持運作
- 探測詳情（以便您可以快速解釋失敗）：
  - `read` 探測：測試在工作區中寫入一個 nonce 檔案並要求代理 `read` 它並回顯 nonce。
  - `exec+read` 探測：測試要求代理 `exec` 將 nonce 寫入臨時檔案，然後 `read` 它回來。
  - 圖片探測：測試附加生成的 PNG（cat + 隨機化程式碼）並期望模型返回 `cat <CODE>`。
  - 實作參考：`src/gateway/gateway-models.profiles.live.test.ts` 和 `src/gateway/live-image-probe.ts`。
- 如何啟用：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
- 如何選擇模型：
  - 預設：modern 允許清單（Opus/Sonnet/Haiku 4.5、GPT-5.x + Codex、Gemini 3、GLM 4.7、MiniMax M2.1、Grok 4）
  - `OPENCLAW_LIVE_GATEWAY_MODELS=all` 是 modern 允許清單的別名
  - 或設定 `OPENCLAW_LIVE_GATEWAY_MODELS="provider/model"`（或逗號清單）以縮小
- 如何選擇供應商（避免「OpenRouter 所有」）：
  - `OPENCLAW_LIVE_GATEWAY_PROVIDERS="google,google-antigravity,google-gemini-cli,openai,anthropic,zai,minimax"`（逗號允許清單）
- 工具 + 圖片探測在此 live 測試中始終開啟：
  - `read` 探測 + `exec+read` 探測（工具壓力）
  - 當模型廣告圖片輸入支援時，圖片探測執行
  - 流程（高層次）：
    - 測試生成帶有「CAT」+ 隨機程式碼的小 PNG（`src/gateway/live-image-probe.ts`）
    - 透過 `agent` `attachments: [{ mimeType: "image/png", content: "<base64>" }]` 發送
    - Gateway 將附件解析為 `images[]`（`src/gateway/server-methods/agent.ts` + `src/gateway/chat-attachments.ts`）
    - 嵌入式代理將多模態使用者訊息轉發到模型
    - 斷言：回覆包含 `cat` + 程式碼（OCR 容差：允許輕微錯誤）

提示：要查看您可以在機器上測試什麼（以及確切的 `provider/model` ids），請執行：

```bash
openclaw models list
openclaw models list --json
```

## Live：Anthropic setup-token smoke

- 測試：`src/agents/anthropic.setup-token.live.test.ts`
- 目標：驗證 Claude Code CLI setup-token（或粘貼的 setup-token profile）可以完成 Anthropic 提示詞。
- 啟用：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
  - `OPENCLAW_LIVE_SETUP_TOKEN=1`
- Token 來源（選擇一個）：
  - Profile：`OPENCLAW_LIVE_SETUP_TOKEN_PROFILE=anthropic:setup-token-test`
  - 原始 token：`OPENCLAW_LIVE_SETUP_TOKEN_VALUE=sk-ant-oat01-...`
- 模型覆蓋（選用）：
  - `OPENCLAW_LIVE_SETUP_TOKEN_MODEL=anthropic/claude-opus-4-5`

設定範例：

```bash
openclaw models auth paste-token --provider anthropic --profile-id anthropic:setup-token-test
OPENCLAW_LIVE_SETUP_TOKEN=1 OPENCLAW_LIVE_SETUP_TOKEN_PROFILE=anthropic:setup-token-test pnpm test:live src/agents/anthropic.setup-token.live.test.ts
```

## Live：CLI backend smoke（Claude Code CLI 或其他本地 CLIs）

- 測試：`src/gateway/gateway-cli-backend.live.test.ts`
- 目標：驗證 Gateway + agent 流水線使用本地 CLI 後端，而不觸及您的預設設定。
- 啟用：
  - `pnpm test:live`（或直接呼叫 Vitest 時使用 `OPENCLAW_LIVE_TEST=1`）
  - `OPENCLAW_LIVE_CLI_BACKEND=1`
- 預設：
  - 模型：`claude-cli/claude-sonnet-4-5`
  - 指令：`claude`
  - 參數：`["-p","--output-format","json","--dangerously-skip-permissions"]`
- 覆蓋（選用）：
  - `OPENCLAW_LIVE_CLI_BACKEND_MODEL="claude-cli/claude-opus-4-5"`
  - `OPENCLAW_LIVE_CLI_BACKEND_MODEL="codex-cli/gpt-5.2-codex"`
  - `OPENCLAW_LIVE_CLI_BACKEND_COMMAND="/full/path/to/claude"`
  - `OPENCLAW_LIVE_CLI_BACKEND_ARGS='["-p","--output-format","json","--permission-mode","bypassPermissions"]'`
  - `OPENCLAW_LIVE_CLI_BACKEND_CLEAR_ENV='["ANTHROPIC_API_KEY","ANTHROPIC_API_KEY_OLD"]'`
  - `OPENCLAW_LIVE_CLI_BACKEND_IMAGE_PROBE=1` 發送真實圖片附件（路徑注入到提示詞中）。
  - `OPENCLAW_LIVE_CLI_BACKEND_IMAGE_ARG="--image"` 將圖片檔案路徑作為 CLI 參數傳遞而不是提示詞注入。
  - `OPENCLAW_LIVE_CLI_BACKEND_IMAGE_MODE="repeat"`（或 `"list"`）控制設定 `IMAGE_ARG` 時如何傳遞圖片參數。
  - `OPENCLAW_LIVE_CLI_BACKEND_RESUME_PROBE=1` 發送第二輪並驗證恢復流程。
- `OPENCLAW_LIVE_CLI_BACKEND_DISABLE_MCP_CONFIG=0` 保持 Claude Code CLI MCP 設定啟用（預設使用臨時空檔案停用 MCP 設定）。

範例：

```bash
OPENCLAW_LIVE_CLI_BACKEND=1 \
  OPENCLAW_LIVE_CLI_BACKEND_MODEL="claude-cli/claude-sonnet-4-5" \
  pnpm test:live src/gateway/gateway-cli-backend.live.test.ts
```

### 推薦的 live 配方

縮小、明確的允許清單最快且最不容易出錯：

- 單一模型，直接（無 gateway）：
  - `OPENCLAW_LIVE_MODELS="openai/gpt-5.2" pnpm test:live src/agents/models.profiles.live.test.ts`

- 單一模型，gateway smoke：
  - `OPENCLAW_LIVE_GATEWAY_MODELS="openai/gpt-5.2" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

- 跨多個供應商的工具呼叫：
  - `OPENCLAW_LIVE_GATEWAY_MODELS="openai/gpt-5.2,anthropic/claude-opus-4-5,google/gemini-3-flash-preview,zai/glm-4.7,minimax/minimax-m2.1" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

- Google 焦點（Gemini API 金鑰 + Antigravity）：
  - Gemini（API 金鑰）：`OPENCLAW_LIVE_GATEWAY_MODELS="google/gemini-3-flash-preview" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`
  - Antigravity（OAuth）：`OPENCLAW_LIVE_GATEWAY_MODELS="google-antigravity/claude-opus-4-5-thinking,google-antigravity/gemini-3-pro-high" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

注意事項：
- `google/...` 使用 Gemini API（API 金鑰）。
- `google-antigravity/...` 使用 Antigravity OAuth bridge（Cloud Code Assist 風格的代理端點）。
- `google-gemini-cli/...` 使用您機器上的本地 Gemini CLI（單獨的認證 + 工具怪癖）。
- Gemini API vs Gemini CLI：
  - API：OpenClaw 透過 HTTP 呼叫 Google 託管的 Gemini API（API 金鑰/profile 認證）；這是大多數使用者所說的「Gemini」。
  - CLI：OpenClaw 外殼到本地 `gemini` 二進位檔；它有自己的認證並且可能行為不同（streaming/tool 支援/版本偏差）。

## Live：模型矩陣（我們涵蓋什麼）

沒有固定的「CI 模型清單」（live 是選用的），但這些是**推薦**在具有金鑰的開發機器上定期涵蓋的模型。

### Modern smoke 集（工具呼叫 + 圖片）

這是我們期望保持運作的「常見模型」執行：
- OpenAI（非 Codex）：`openai/gpt-5.2`（選用：`openai/gpt-5.1`）
- OpenAI Codex：`openai-codex/gpt-5.2`（選用：`openai-codex/gpt-5.2-codex`）
- Anthropic：`anthropic/claude-opus-4-5`（或 `anthropic/claude-sonnet-4-5`）
- Google（Gemini API）：`google/gemini-3-pro-preview` 和 `google/gemini-3-flash-preview`（避免較舊的 Gemini 2.x 模型）
- Google（Antigravity）：`google-antigravity/claude-opus-4-5-thinking` 和 `google-antigravity/gemini-3-flash`
- Z.AI（GLM）：`zai/glm-4.7`
- MiniMax：`minimax/minimax-m2.1`

使用工具 + 圖片執行 gateway smoke：
`OPENCLAW_LIVE_GATEWAY_MODELS="openai/gpt-5.2,openai-codex/gpt-5.2,anthropic/claude-opus-4-5,google/gemini-3-pro-preview,google/gemini-3-flash-preview,google-antigravity/claude-opus-4-5-thinking,google-antigravity/gemini-3-flash,zai/glm-4.7,minimax/minimax-m2.1" pnpm test:live src/gateway/gateway-models.profiles.live.test.ts`

### 基準：工具呼叫（Read + 選用 Exec）

每個供應商系列至少選擇一個：
- OpenAI：`openai/gpt-5.2`（或 `openai/gpt-5-mini`）
- Anthropic：`anthropic/claude-opus-4-5`（或 `anthropic/claude-sonnet-4-5`）
- Google：`google/gemini-3-flash-preview`（或 `google/gemini-3-pro-preview`）
- Z.AI（GLM）：`zai/glm-4.7`
- MiniMax：`minimax/minimax-m2.1`

選用額外涵蓋（很好有）：
- xAI：`xai/grok-4`（或最新可用）
- Mistral：`mistral/`…（選擇一個您啟用的「tools」有能力的模型）
- Cerebras：`cerebras/`…（如果您有存取權限）
- LM Studio：`lmstudio/`…（本地；工具呼叫取決於 API 模式）

### Vision：圖片發送（附件 → 多模態訊息）

在 `OPENCLAW_LIVE_GATEWAY_MODELS` 中至少包含一個圖片有能力的模型（Claude/Gemini/OpenAI vision 有能力的變體等）以執行圖片探測。

### 聚合器 / 替代 gateways

如果您啟用了金鑰，我們也支援透過以下方式測試：
- OpenRouter：`openrouter/...`（數百個模型；使用 `openclaw models scan` 找到 tool+image 有能力的候選者）
- OpenCode Zen：`opencode/...`（透過 `OPENCODE_API_KEY` / `OPENCODE_ZEN_API_KEY` 認證）

您可以在 live 矩陣中包含更多供應商（如果您有憑證/設定）：
- 內建：`openai`、`openai-codex`、`anthropic`、`google`、`google-vertex`、`google-antigravity`、`google-gemini-cli`、`zai`、`openrouter`、`opencode`、`xai`、`groq`、`cerebras`、`mistral`、`github-copilot`
- 透過 `models.providers`（自訂端點）：`minimax`（雲端/API），加上任何 OpenAI/Anthropic 相容代理（LM Studio、vLLM、LiteLLM 等）

提示：不要試圖在文件中硬編碼「所有模型」。權威清單是在您的機器上 `discoverModels(...)` 返回的任何內容 + 任何可用的金鑰。

## 憑證（絕不提交）

Live 測試以與 CLI 相同的方式發現憑證。實際影響：
- 如果 CLI 運作，live 測試應該找到相同的金鑰。
- 如果 live 測試說「無憑證」，以與除錯 `openclaw models list` / 模型選擇相同的方式除錯。

- Profile 儲存：`~/.openclaw/credentials/`（首選；測試中「profile 金鑰」的意思）
- 設定：`~/.openclaw/openclaw.json`（或 `OPENCLAW_CONFIG_PATH`）

如果您想依賴環境變數金鑰（例如在您的 `~/.profile` 中匯出），請在 `source ~/.profile` 之後執行本地測試，或使用下面的 Docker runners（它們可以將 `~/.profile` 掛載到容器中）。

## Deepgram live（音訊轉錄）

- 測試：`src/media-understanding/providers/deepgram/audio.live.test.ts`
- 啟用：`DEEPGRAM_API_KEY=... DEEPGRAM_LIVE_TEST=1 pnpm test:live src/media-understanding/providers/deepgram/audio.live.test.ts`

## Docker runners（選用的「在 Linux 中運作」檢查）

這些在儲存庫 Docker 映像內執行 `pnpm test:live`，掛載您的本地設定目錄和工作區（如果掛載，則來源 `~/.profile`）：

- 直接模型：`pnpm test:docker:live-models`（腳本：`scripts/test-live-models-docker.sh`）
- Gateway + dev agent：`pnpm test:docker:live-gateway`（腳本：`scripts/test-live-gateway-models-docker.sh`）
- Onboarding wizard（TTY、完整架構）：`pnpm test:docker:onboard`（腳本：`scripts/e2e/onboard-docker.sh`）
- Gateway networking（兩個容器、WS auth + health）：`pnpm test:docker:gateway-network`（腳本：`scripts/e2e/gateway-network-docker.sh`）
- Plugins（自訂擴充載入 + 註冊表 smoke）：`pnpm test:docker:plugins`（腳本：`scripts/e2e/plugins-docker.sh`）

有用的環境變數：

- `OPENCLAW_CONFIG_DIR=...`（預設：`~/.openclaw`）掛載到 `/home/node/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=...`（預設：`~/.openclaw/workspace`）掛載到 `/home/node/.openclaw/workspace`
- `OPENCLAW_PROFILE_FILE=...`（預設：`~/.profile`）掛載到 `/home/node/.profile` 並在執行測試前來源
- `OPENCLAW_LIVE_GATEWAY_MODELS=...` / `OPENCLAW_LIVE_MODELS=...` 以縮小執行
- `OPENCLAW_LIVE_REQUIRE_PROFILE_KEYS=1` 以確保憑證來自 profile 儲存（而非環境變數）

## Docs 完整性

編輯文件後執行文件檢查：`pnpm docs:list`。

## 離線回歸測試（CI 安全）

這些是「真實流水線」回歸測試，而沒有真實供應商：
- Gateway 工具呼叫（模擬 OpenAI、真實 gateway + agent 迴圈）：`src/gateway/gateway.tool-calling.mock-openai.test.ts`
- Gateway wizard（WS `wizard.start`/`wizard.next`、寫入設定 + auth enforced）：`src/gateway/gateway.wizard.e2e.test.ts`

## Agent 可靠性評估（skills）

我們已經有一些 CI 安全測試，行為類似「agent 可靠性評估」：
- 透過真實 gateway + agent 迴圈模擬工具呼叫（`src/gateway/gateway.tool-calling.mock-openai.test.ts`）。
- 驗證會話接線和設定效果的端到端 wizard 流程（`src/gateway/gateway.wizard.e2e.test.ts`）。

skills 仍然缺少的內容（請參閱 [Skills](/tools/skills)）：
- **決策**：當 skills 列在提示詞中時，代理是否選擇正確的 skill（或避免不相關的）？
- **合規性**：代理是否在使用前讀取 `SKILL.md` 並遵循所需的步驟/參數？
- **工作流程合約**：多輪場景，斷言工具順序、會話歷史結轉和沙盒邊界。

未來的評估應首先保持確定性：
- 使用模擬供應商斷言工具呼叫 + 順序、skill 檔案讀取和會話接線的場景執行器。
- 一小組以 skill 為中心的場景（使用 vs 避免、gating、提示詞注入）。
- 選用 live 評估（選用、環境變數門控）僅在 CI 安全套件就位後。

## 新增回歸測試（指導）

當您修復在 live 中發現的供應商/模型問題時：
- 如果可能，新增 CI 安全回歸測試（模擬/存根供應商，或捕獲確切的請求形狀轉換）
- 如果它本質上僅限 live（速率限制、認證策略），請透過環境變數保持 live 測試縮小且選用
- 優選針對捕獲 bug 的最小層：
  - 供應商請求轉換/重放 bug → 直接模型測試
  - gateway session/history/tool 流水線 bug → gateway live smoke 或 CI 安全 gateway 模擬測試
