---
title: "models(模型配置)"
summary: "`openclaw models` CLI 參考（狀態、列表、設定、掃描、別名、退回機制與認證）"
read_when:
  - 想要變更預設模型或查看供應商認證狀態時
  - 想要掃描可用模型/供應商或對認證配置檔進行偵錯時
---

# `openclaw models`

模型的發現、掃描與配置（包含預設模型、退回機制與認證配置檔）。

相關資訊：
- 供應商與模型概念：[模型 (Models)](/providers/models)
- 供應商認證設定：[馬上開始 (Getting started)](/start/getting-started)

## 常見指令

```bash
# 查看目前的預設模型、退回機制與認證總覽
openclaw models status

# 列出所有可用的模型
openclaw models list

# 設定全域預設模型
openclaw models set <模型ID或別名>

# 掃描供應商以發現新模型
openclaw models scan
```

`openclaw models status` 會顯示解析後的預設模型、退回清單以及認證狀態。
若供應商的使用量快照功能可用，認證狀態區塊將包含使用量統計。加上 `--probe` 可針對每個已配置的供應商配置檔執行實時認證探測（請注意：探針會發送真實請求，可能會消耗 Token 並觸發速率限制）。

**注意事項**：
- `models set` 接受 `供應商/模型` 格式或別名。
- 模型 ID 的解析是以**第一個** `/` 為準。若模型 ID 本身包含斜線（例如 OpenRouter 格式），請務必包含供應商前綴（範例：`openrouter/moonshotai/kimi-k2`）。
- 若省略供應商，OpenClaw 將視為別名或**預設供應商**的模型。

### `models status` 選項

- `--json` / `--plain`：輸出格式。
- `--check`：檢查認證狀態（退出代碼 1=過期/缺失，2=即將過期）。
- `--probe`：對配置檔執行實時探測。
- `--probe-provider <name>`：僅探測特定供應商。
- `--probe-concurrency <n>`：設定探測的併發數。

## 別名與退回機制 (Aliases & fallbacks)

```bash
# 管理模型別名
openclaw models aliases list

# 管理模型退回清單
openclaw models fallbacks list
```

## 認證配置檔 (Auth profiles)

```bash
# 互動式新增認證
openclaw models auth add

# 執行特定供應商的登入流程 (OAuth 或 API Key)
openclaw models auth login --provider <ID>

# 設定或貼上認證權仗
openclaw models auth setup-token
openclaw models auth paste-token
```

`models auth login` 會啟動供應商外掛的認證流程。使用 `openclaw plugins list` 可查看已安裝的供應商外掛。
- `setup-token`：提示輸入安裝權杖。
- `paste-token`：接受由自動化流程生成的權杖字串。
