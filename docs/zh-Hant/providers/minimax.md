---
summary: "在 OpenClaw 中使用 MiniMax M2.5"
read_when:
  - 你想在 OpenClaw 中使用 MiniMax 模型
  - 你需要 MiniMax 設定指南
title: "MiniMax"
---

# MiniMax

MiniMax 是一家建立 **M2/M2.5** 模型系列的 AI 公司。當前編碼重點版本是 **MiniMax M2.5**（2025 年 12 月 23 日），專為真實世界複雜任務建造。

來源：[MiniMax M2.5 發佈說明](https://www.minimax.io/news/minimax-m25)

## 模型概覽（M2.5）

MiniMax 在 M2.5 中強調了這些改進：

- 更強的**多語言編碼**（Rust、Java、Go、C++、Kotlin、Objective-C、TS/JS）。
- 更好的 **Web/應用開發**與美觀輸出品質（包括原生行動應用）。
- 改進的**複合指令**處理，用於辦公式工作流程，建立在交錯思考與整合約束執行基礎上。
- **更簡潔的響應**，具有更低的令牌使用與更快的迭代迴圈。
- 更強的 **Tool/Agent 框架**相容性與上下文管理（Claude Code、
  Droid/Factory AI、Cline、Kilo Code、Roo Code、BlackBox）。
- 更高品質的**對話與技術寫作**輸出。

## MiniMax M2.5 vs MiniMax M2.5 Highspeed

- **速度：** \`MiniMax-M2.5-highspeed\` 是 MiniMax 文件中的官方快速層級。
- **成本：** MiniMax 價格列表針對 highspeed 顯示相同的輸入成本與更高的輸出成本。
- **當前模型 ID：** 使用 \`MiniMax-M2.5\` 或 \`MiniMax-M2.5-highspeed\`。

## 選擇一個設定

### MiniMax OAuth（編碼計劃）— 推薦

**最適合：** 透過 OAuth 快速設定 MiniMax 編碼計劃，不需要 API 密鑰。

啟用捆綁的 OAuth 外掛程式並進行驗證：

\`\`\`bash
openclaw plugins enable minimax-portal-auth # 如已載入則跳過。
openclaw gateway restart # 如 gateway 已在執行則重新啟動
openclaw onboard --auth-choice minimax-portal
\`\`\`

系統會提示你選擇端點：

- **Global** - 國際使用者（\`api.minimax.io\`）
- **CN** - 中國使用者（\`api.minimaxi.com\`）

見 [MiniMax OAuth plugin README](https://github.com/openclaw/openclaw/tree/main/extensions/minimax-portal-auth) 以瞭解詳情。

### MiniMax M2.5（API 密鑰）

**最適合：** 使用 Anthropic 相容 API 的託管 MiniMax。

透過 CLI 設定：

- 執行 \`openclaw configure\`
- 選擇 **Model/auth**
- 選擇 **MiniMax M2.5**

\`\`\`json5
{
env: { MINIMAX_API_KEY: "sk-..." },
agents: { defaults: { model: { primary: "minimax/MiniMax-M2.5" } } },
models: {
mode: "merge",
providers: {
minimax: {
baseUrl: "https://api.minimax.io/anthropic",
apiKey: "\${MINIMAX_API_KEY}",
api: "anthropic-messages",
models: [
{
id: "MiniMax-M2.5",
name: "MiniMax M2.5",
reasoning: true,
input: ["text"],
cost: { input: 0.3, output: 1.2, cacheRead: 0.03, cacheWrite: 0.12 },
contextWindow: 200000,
maxTokens: 8192,
},
{
id: "MiniMax-M2.5-highspeed",
name: "MiniMax M2.5 Highspeed",
reasoning: true,
input: ["text"],
cost: { input: 0.3, output: 1.2, cacheRead: 0.03, cacheWrite: 0.12 },
contextWindow: 200000,
maxTokens: 8192,
},
],
},
},
},
}
\`\`\`

### MiniMax M2.5 作為備用（範例）

**最適合：** 將最強的最新世代模型保持為主模型，容錯轉移至 MiniMax M2.5。
下面的範例使用 Opus 作為具體主模型；交換至你偏好的最新世代主模型。

\`\`\`json5
{
env: { MINIMAX_API_KEY: "sk-..." },
agents: {
defaults: {
models: {
"anthropic/claude-opus-4-6": { alias: "primary" },
"minimax/MiniMax-M2.5": { alias: "minimax" },
},
model: {
primary: "anthropic/claude-opus-4-6",
fallbacks: ["minimax/MiniMax-M2.5"],
},
},
},
}
\`\`\`

### 可選：透過 LM Studio 本機執行（手動）

**最適合：** 使用 LM Studio 進行本機推論。
我們已在強大的硬體（例如桌上型電腦/伺服器）上使用 LM Studio 的本機伺服器為 MiniMax M2.5 看到了強大結果。

透過 \`openclaw.json\` 手動設定：

\`\`\`json5
{
agents: {
defaults: {
model: { primary: "lmstudio/minimax-m2.5-gs32" },
models: { "lmstudio/minimax-m2.5-gs32": { alias: "Minimax" } },
},
},
models: {
mode: "merge",
providers: {
lmstudio: {
baseUrl: "http://127.0.0.1:1234/v1",
apiKey: "lmstudio",
api: "openai-responses",
models: [
{
id: "minimax-m2.5-gs32",
name: "MiniMax M2.5 GS32",
reasoning: true,
input: ["text"],
cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
contextWindow: 196608,
maxTokens: 8192,
},
],
},
},
},
}
\`\`\`

## 透過 \`openclaw configure\` 設定

使用互動式設定精靈無需編輯 JSON 即可設定 MiniMax：

1. 執行 \`openclaw configure\`。
2. 選擇 **Model/auth**。
3. 選擇 **MiniMax M2.5**。
4. 出現提示時選擇預設模型。

## 設定選項

- \`models.providers.minimax.baseUrl\`：偏好 \`https://api.minimax.io/anthropic\`（Anthropic 相容）；\`https://api.minimax.io/v1\` 對於 OpenAI 相容酬載是選項。
- \`models.providers.minimax.api\`：偏好 \`anthropic-messages\`；\`openai-completions\` 對於 OpenAI 相容酬載是選項。
- \`models.providers.minimax.apiKey\`：MiniMax API 密鑰（\`MINIMAX_API_KEY\`）。
- \`models.providers.minimax.models\`：定義 \`id\`、\`name\`、\`reasoning\`、\`contextWindow\`、\`maxTokens\`、\`cost\`。
- \`agents.defaults.models\`：別名化你想要在允許清單中的模型。
- \`models.mode\`：如果想將 MiniMax 與內建模型一起新增，保持 \`merge\`。

## 注意事項

- 模型參考是 \`minimax/<model>\`。
- 建議的模型 ID：\`MiniMax-M2.5\` 與 \`MiniMax-M2.5-highspeed\`。
- 編碼計劃使用量 API：\`https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains\`（需要編碼計劃密鑰）。
- 如果需要精確成本追蹤，請更新 \`models.json\` 中的價格值。
- MiniMax 編碼計劃推薦連結（8 折）：[https://platform.minimax.io/subscribe/coding-plan?code=DbXJTRClnb&source=link](https://platform.minimax.io/subscribe/coding-plan?code=DbXJTRClnb&source=link)
- 見 [/concepts/model-providers](/zh-Hant/concepts/model-providers) 瞭解提供者規則。
- 使用 \`openclaw models list\` 與 \`openclaw models set minimax/MiniMax-M2.5\` 進行切換。

## 疑難解除

### 「未知模型：minimax/MiniMax-M2.5」

這通常表示 **MiniMax 提供者未設定**（未找到提供者項目且未找到 MiniMax 驗證組態檔/環境密鑰）。此偵測的修正在
**2026.1.12**（撰寫時未發佈）。修正方法：

- 升級到 **2026.1.12**（或從原始碼執行 \`main\`），然後重新啟動 gateway。
- 執行 \`openclaw configure\` 並選擇 **MiniMax M2.5**，或
- 手動新增 \`models.providers.minimax\` 塊，或
- 設定 \`MINIMAX_API_KEY\`（或 MiniMax 驗證組態檔）以便提供者可以被注入。

確保模型 ID **區分大小寫**：

- \`minimax/MiniMax-M2.5\`
- \`minimax/MiniMax-M2.5-highspeed\`

然後以以下方式重新檢查：

\`\`\`bash
openclaw models list
\`\`\`
