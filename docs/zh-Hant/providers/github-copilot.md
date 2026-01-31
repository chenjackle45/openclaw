---
title: "github-copilot(Github Copilot)"
summary: "在 OpenClaw 中使用 GitHub Copilot (裝置登入流程)"
read_when:
  - 想要使用 GitHub Copilot 作為模型服務供應商時
  - 需要 `openclaw models auth login-github-copilot` 流程說明時
---

# Github Copilot

## 什麼是 GitHub Copilot?

GitHub Copilot 是 GitHub 的 AI 編碼助理。它提供對應您 GitHub 帳戶與方案的 Copilot 模型存取權。OpenClaw 可以透過兩種不同方式使用 Copilot 作為模型服務供應商。

## 在 OpenClaw 中使用 Copilot 的兩種方式

### 1) 內建 GitHub Copilot 供應商 (`github-copilot`)

使用原生的裝置登入流程取得 GitHub Token，然後在 OpenClaw 運行時將其交換為 Copilot API Token。這是**預設**且最簡單的路徑，因為它不需要 VS Code。

### 2) Copilot Proxy 外掛 (`copilot-proxy`)

使用 **Copilot Proxy** VS Code 擴充功能作為本地橋接器。OpenClaw 會與 Proxy 的 `/v1` 端點通訊，並使用您在該處配置的模型清單。當您已經在 VS Code 中運行 Copilot Proxy 或需要透過它進行路由時，請選擇此方式。您必須啟用該外掛並保持 VS Code 擴充功能運行。

使用 GitHub Copilot 作為模型服務供應商 (`github-copilot`)。登入指令會執行 GitHub 裝置流程，儲存認證設定檔，並更新您的配置以使用該設定檔。

## CLI 設定方式

```bash
openclaw models auth login-github-copilot
```

系統會提示您訪問一個 URL 並輸入一次性代碼。請保持終端機開啟直到流程完成。

### 選用旗標

```bash
openclaw models auth login-github-copilot --profile-id github-copilot:work
openclaw models auth login-github-copilot --yes
```

## 設定預設模型

```bash
openclaw models set github-copilot/gpt-4o
```

### 配置範例

```json5
{
  agents: { defaults: { model: { primary: "github-copilot/gpt-4o" } } }
}
```

## 注意事項

- 需要互動式 TTY；請直接在終端機中執行。
- Copilot 模型的可用性取決於您的方案；若模型被拒絕，請嘗試另一個 ID（例如 `github-copilot/gpt-4.1`）。
- 登入過程會將 GitHub Token 儲存在認證設定檔儲存區中，並在 OpenClaw 運行時交換為 Copilot API Token。
