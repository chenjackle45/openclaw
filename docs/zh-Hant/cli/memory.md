---
summary: "`openclaw memory` CLI 參考（狀態、索引與搜尋）"
read_when:
  - 想要建立索引或搜尋語義記憶體時
  - 正在偵錯記憶體的可用性或索引過程時
title: "memory（記憶體管理）"
---

# `openclaw memory`

管理語義記憶體索引與搜尋。
由目前啟用的記憶體 plugin 提供（預設：`memory-core`；設定 `plugins.slots.memory = "none"` 可停用）。

相關資訊：

- 記憶體概念：[Memory](/zh-Hant/concepts/memory)
- Plugins：[Plugins](/zh-Hant/tools/plugin)

## 範例

```bash
openclaw memory status
openclaw memory status --deep
openclaw memory index --force
openclaw memory search "meeting notes"
openclaw memory search --query "deployment" --max-results 20
openclaw memory status --json
openclaw memory status --deep --index
openclaw memory status --deep --index --verbose
openclaw memory status --agent main
openclaw memory index --agent main --verbose
```

## 選項

`memory status` 和 `memory index`：

- `--agent <id>`：限定範圍至單一 agent。若未指定，這些指令會對每個已配置的 agent 執行；若未配置 agent 清單，則回退至預設 agent。
- `--verbose`：在探測和索引期間輸出詳細日誌。

`memory status`：

- `--deep`：探測向量 + 嵌入可用性。
- `--index`：若儲存已過期則執行重新索引（隱含 `--deep`）。
- `--json`：列印 JSON 輸出。

`memory index`：

- `--force`：強制完整重新索引。

`memory search`：

- 查詢輸入：傳遞位置參數 `[query]` 或 `--query <text>`。
- 若兩者都提供，`--query` 優先。
- 若兩者都未提供，指令以錯誤退出。
- `--agent <id>`：限定範圍至單一 agent（預設：預設 agent）。
- `--max-results <n>`：限制返回結果數量。
- `--min-score <n>`：過濾低分匹配。
- `--json`：列印 JSON 結果。

注意事項：

- `memory index --verbose` 會列印各階段詳細資訊（供應商、模型、來源、批次活動）。
- `memory status` 包含透過 `memorySearch.extraPaths` 配置的任何額外路徑。
- 若有效啟用的記憶體遠端 API key 欄位被配置為 SecretRefs，指令會從目前的 gateway 快照解析這些值。若 gateway 無法使用，指令會快速失敗。
- Gateway 版本差異注意：此指令路徑需要支援 `secrets.resolve` 的 gateway；較舊的 gateway 會返回未知方法錯誤。
