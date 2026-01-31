---
title: "memory(記憶體管理)"
summary: "`openclaw memory` CLI 參考（狀態、索引與搜尋）"
read_when:
  - 想要建立索引或搜尋語義記憶體 (Semantic Memory) 時
  - 正在偵錯記憶體的可用性或索引過程時
---

# `openclaw memory`

管理語義記憶體的索引與搜尋。此功能由目前啟用的記憶體外掛提供（預設為 `memory-core`；設定 `plugins.slots.memory = "none"` 可停用此功能）。

相關資訊：
- 記憶體概念：[記憶體 (Memory)](/concepts/memory)
- 外掛系統：[外掛 (Plugins)](/plugins)

## 指令範例

```bash
# 查看記憶體索引狀態
openclaw memory status

# 執行深度探查（包含向量資料與嵌入模型的可用性檢查）
openclaw memory status --deep

# 若索引狀態過期，執行深度探查並觸發重新索引
openclaw memory status --deep --index

# 對所有 Agent 執行重新索引
openclaw memory index

# 顯示詳細的索引過程日誌
openclaw memory index --verbose

# 語義搜尋特定的主題
openclaw memory search "發布清單"

# 僅針對名為 main 的 Agent 查看記憶體狀態
openclaw memory status --agent main
```

## 參數選項

**共用旗標**：
- `--agent <ID>`：限定範圍至單一 Agent（預設為所有已配置的 Agent）。
- `--verbose`：在探查與索引過程中輸出詳細日誌。

**注意事項**：
- `memory status --deep` 會探測向量庫與嵌入 (Embedding) 服務的可用性。
- `memory index --verbose` 會分階段列印細節（包含供應商、模型、來源檔案以及批次處理活動）。
- `memory status` 的結果也會包含透過 `memorySearch.extraPaths` 配置的額外路徑。
