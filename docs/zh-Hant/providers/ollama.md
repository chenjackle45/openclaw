---
title: "ollama(Ollama)"
summary: "在 OpenClaw 中使用 Ollama (本地 LLM 運行環境)"
read_when:
  - 想要透過 Ollama 在本地運行 OpenClaw 時
  - 需要 Ollama 安裝與配置指南時
---

# Ollama

Ollama 是一個本地 LLM 運行環境，讓您可以輕鬆地在機器上運行開源模型。OpenClaw 整合了 Ollama 的 OpenAI 相容 API，並且當您設定了 `OLLAMA_API_KEY`（或認證設定檔）且未明確定義 `models.providers.ollama` 項目時，能夠**自動探索支援工具調用的模型**。

## 快速開始

1) 安裝 Ollama：https://ollama.ai

2) 拉取模型：

```bash
ollama pull llama3.3
# 或
ollama pull qwen2.5-coder:32b
# 或
ollama pull deepseek-r1:32b
```

3) 為 OpenClaw 啟用 Ollama（任意值皆可；Ollama 不需要真實的金鑰）：

```bash
# 設定環境變數
export OLLAMA_API_KEY="ollama-local"

# 或在設定檔中配置
openclaw config set models.providers.ollama.apiKey "ollama-local"
```

4) 使用 Ollama 模型：

```json5
{
  agents: {
    defaults: {
      model: { primary: "ollama/llama3.3" }
    }
  }
}
```

## 模型自動探索 (隱式供應商)

當您設定 `OLLAMA_API_KEY`（或認證設定檔）且**未**定義 `models.providers.ollama` 時，OpenClaw 會從位於 `http://127.0.0.1:11434` 的本地 Ollama 實例探索模型：

- 查詢 `/api/tags` 與 `/api/show`
- 僅保留報告具有 `tools` 能力的模型
- 若模型報告 `thinking` 能力，則標記為 `reasoning`
- 若可用，從 `model_info["<arch>.context_length"]` 讀取 `contextWindow`
- 將 `maxTokens` 設定為上下文視窗的 10 倍
- 將所有成本設定為 `0`

這避免了手動輸入模型項目的麻煩，同時保持目錄與 Ollama 的能力同步。

查看可用模型：

```bash
ollama list
openclaw models list
```

若要新增模型，只需透過 Ollama 拉取：

```bash
ollama pull mistral
```

新模型將會被自動探索並可供使用。

若您明確設定了 `models.providers.ollama`，則會跳過自動探索，您必須手動定義模型（見下文）。

## 配置說明

### 基礎設定（隱式探索）

啟用 Ollama 最簡單的方式是透過環境變數：

```bash
export OLLAMA_API_KEY="ollama-local"
```

### 顯式設定（手動定義模型）

請在以下情況使用顯式配置：
- Ollama 運行在另一台主機/埠口。
- 您想要強制設定特定的上下文視窗或模型清單。
- 您想要包含未報告工具支援的模型。

```json5
{
  models: {
    providers: {
      ollama: {
        // 使用包含 /v1 的主機路徑以相容 OpenAI API
        baseUrl: "http://ollama-host:11434/v1",
        apiKey: "ollama-local",
        api: "openai-completions",
        models: [
          {
            id: "llama3.3",
            name: "Llama 3.3",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 8192,
            maxTokens: 8192 * 10
          }
        ]
      }
    }
  }
}
```

若已設定 `OLLAMA_API_KEY`，您可以省略供應商設定中的 `apiKey`，OpenClaw 會自動填入以進行可用性檢查。

### 自訂 Base URL（顯式設定）

若 Ollama 運行在不同的主機或埠口（顯式設定會停用自動探索，因此需手動定義模型）：

```json5
{
  models: {
    providers: {
      ollama: {
        apiKey: "ollama-local",
        baseUrl: "http://ollama-host:11434/v1"
      }
    }
  }
}
```

### 模型選擇

配置完成後，所有的 Ollama 模型皆可使用：

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "ollama/llama3.3",
        fallback: ["ollama/qwen2.5-coder:32b"]
      }
    }
  }
}
```

## 進階設定

### 推理模型 (Reasoning models)

當 Ollama 在 `/api/show` 中報告 `thinking` 能力時，OpenClaw 會將該模型標記為具備推理能力：

```bash
ollama pull deepseek-r1:32b
```

### 模型成本

Ollama 是免費且本地運行的，因此所有模型成本皆設為 $0。

### 上下文視窗

對於自動探索的模型，OpenClaw 會使用 Ollama 報告的上下文視窗（若有），否則預設為 `8192`。您可以在顯式供應商配置中覆寫 `contextWindow` 與 `maxTokens`。

## 故障排除

### 未偵測到 Ollama

請確保 Ollama正在運行，且您已設定 `OLLAMA_API_KEY`（或認證設定檔），並且**未**定義明確的 `models.providers.ollama` 項目：

```bash
ollama serve
```

確認 API 可存取：

```bash
curl http://localhost:11434/api/tags
```

### 沒有可用的模型

OpenClaw 僅會自動探索報告具有工具支援的模型。若您的模型未列出，請：
- 拉取一個支援工具的模型，或
- 在 `models.providers.ollama` 中明確定義該模型。

新增模型：

```bash
ollama list  # 查看已安裝模型
ollama pull llama3.3  # 拉取模型
```

### 連線被拒 (Connection refused)

檢查 Ollama 是否運行在正確的埠口：

```bash
# 檢查 Ollama 是否正在運行
ps aux | grep ollama

# 或重新啟動 Ollama
ollama serve
```

## 參見

- [模型服務供應商](/concepts/model-providers) - 所有供應商總覽
- [模型選擇](/concepts/models) - 如何選擇模型
- [配置導覽](/gateway/configuration) - 完整配置參考
