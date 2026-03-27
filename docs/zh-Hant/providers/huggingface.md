---
summary: "Hugging Face 推理設定（認證 + 模型選擇）"
read_when:
  - You want to use Hugging Face Inference with OpenClaw
  - You need the HF token env var or CLI auth choice
title: "Hugging Face (Inference)（Inference）"
---

# Hugging Face（推理）

[Hugging Face 推理提供者](https://huggingface.co/docs/inference-providers)透過單一路由器 API 提供 OpenAI 相容聊天完成。您使用一個令牌取得許多模型（DeepSeek、Llama 等）的存取。OpenClaw 使用 **OpenAI 相容端點**（僅聊天完成）；用於文字轉影像、嵌入或語音，請直接使用 [HF 推理用戶端](https://huggingface.co/docs/api-inference/quicktour)。

- 提供者：`huggingface`
- 認證：`HUGGINGFACE_HUB_TOKEN` 或 `HF_TOKEN`（細粒度令牌，具有**對推理提供者進行呼叫**權限）
- API：OpenAI 相容（`https://router.huggingface.co/v1`）
- 計費：單一 HF 令牌；[定價](https://huggingface.co/docs/inference-providers/pricing)遵循提供者費率，有免費層級。

## 快速開始

1. 在 [Hugging Face → 設定 → 令牌](https://huggingface.co/settings/tokens/new?ownUserPermissions=inference.serverless.write&tokenType=fineGrained)，建立**對推理提供者進行呼叫**權限的細粒度令牌。

2. 執行上線並在提供者下拉清單中選擇 **Hugging Face**，然後在提示時輸入 API 鑰：

```bash
openclaw onboard --auth-choice huggingface-api-key
```

3. 在**預設 Hugging Face 模型**下拉清單中，選擇所需模型（當有效令牌時，清單從推理 API 加載；否則顯示內建清單）。選擇被儲存為預設模型。

4. 您也可以稍後在設定中設定或變更預設模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "huggingface/deepseek-ai/DeepSeek-R1" },
    },
  },
}
```

## 非互動範例

```bash
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice huggingface-api-key \
  --huggingface-api-key "$HF_TOKEN"
```

這會設定 `huggingface/deepseek-ai/DeepSeek-R1` 作為預設模型。

## 環境註記

如果 Gateway 作為守護程式執行（launchd / systemd），確保 `HUGGINGFACE_HUB_TOKEN` 或 `HF_TOKEN`
對該程序可用（例如，在 `~/.openclaw/.env` 或透過
`env.shellEnv`）。

## 模型發現和上線下拉清單

OpenClaw 透過直接呼叫**推理端點**探索模型：

```bash
GET https://router.huggingface.co/v1/models
```

（可選：傳送 `Authorization: Bearer $HUGGINGFACE_HUB_TOKEN` 或 `$HF_TOKEN` 以取得完整清單；某些端點在沒有認證時返回子集）。回應是 OpenAI 風格 `{ "object": "list", "data": [ { "id": "Qwen/Qwen3-8B", "owned_by": "Qwen", ... }, ... ] }`。

當設定 Hugging Face API 鑰（透過上線、`HUGGINGFACE_HUB_TOKEN` 或 `HF_TOKEN`）時，OpenClaw 使用此 GET 探索可用聊天完成模型。在**互動上線**期間，輸入令牌後，您見到來自該清單的**預設 Hugging Face 模型**下拉清單（或內建目錄如果請求失敗）。在執行時（例如 Gateway 啟動），當鑰存在時，OpenClaw 再次呼叫 **GET** `https://router.huggingface.co/v1/models` 重新整理目錄。清單與內建目錄合併（用於中繼資料，如內容視窗和成本）。如果請求失敗或未設定鑰，則只使用內建目錄。

## 模型名稱和可編輯選項

- **API 名稱：** 模型顯示名稱是**透過 GET /v1/models 進行水文化**，當 API 返回 `name`、`title` 或 `display_name` 時；否則從模型 ID 衍生（例如 `deepseek-ai/DeepSeek-R1` → "DeepSeek R1"）。
- **覆蓋顯示名稱：** 您可以在設定中為每個模型設定自訂標籤，使其在 CLI 和 UI 中顯示為您想要的方式。

示例和詳細設定見英文文件...（篇幅限制）
