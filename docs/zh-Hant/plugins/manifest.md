---
summary: "Plugin manifest + JSON schema 需求（嚴格設定驗證）"
read_when:
  - 你正在建置 OpenClaw plugin
  - 你需要發布 plugin 設定 schema 或除錯 plugin 驗證錯誤
title: "Plugin Manifest（Plugin 清單）"
---

# Plugin manifest（openclaw.plugin.json）

每個 plugin **必須**在 **plugin 根目錄**中提供 `openclaw.plugin.json` 檔案。
OpenClaw 使用此清單**無需執行 plugin 程式碼**即可驗證設定。缺少或無效的清單會被視為 plugin 錯誤，並阻擋設定驗證。

完整 plugin 系統指南請見：[Plugins](/zh-Hant/tools/plugin)。

## 必要欄位

```json
{
  "id": "voice-call",
  "configSchema": {
    "type": "object",
    "additionalProperties": false,
    "properties": {}
  }
}
```

必要鍵：

- `id`（字串）：正式的 plugin id。
- `configSchema`（物件）：plugin 設定的 JSON Schema（內嵌）。

選用鍵：

- `kind`（字串）：plugin 類型（範例：`"memory"`、`"context-engine"`）。
- `channels`（陣列）：此 plugin 註冊的頻道 id（範例：`["matrix"]`）。
- `providers`（陣列）：此 plugin 註冊的提供商 id。
- `skills`（陣列）：要載入的 skill 目錄（相對於 plugin 根目錄）。
- `name`（字串）：plugin 的顯示名稱。
- `description`（字串）：plugin 的簡短摘要。
- `uiHints`（物件）：設定欄位的標籤/佔位符/敏感旗標，用於 UI 渲染。
- `version`（字串）：plugin 版本（僅供參考）。

## JSON Schema 需求

- **每個 plugin 必須提供 JSON Schema**，即使它不接受任何設定。
- 空 schema 是可接受的（例如 `{ "type": "object", "additionalProperties": false }`）。
- Schema 在設定讀取/寫入時驗證，而非在執行階段。

## 驗證行為

- 未知的 `channels.*` 鍵是**錯誤**，除非頻道 id 由 plugin manifest 聲明。
- `plugins.entries.<id>`、`plugins.allow`、`plugins.deny` 和 `plugins.slots.*`
  必須參考**可探索的** plugin id。未知 id 是**錯誤**。
- 若 plugin 已安裝但 manifest 或 schema 損壞或缺失，驗證失敗，Doctor 會回報 plugin 錯誤。
- 若 plugin 設定存在但 plugin 已**停用**，設定會保留，並在 Doctor + 記錄中顯示**警告**。

## 注意事項

- 清單**所有 plugin 都必須提供**，包括從本地檔案系統載入的 plugin。
- 執行階段仍會單獨載入 plugin 模組；manifest 僅用於探索 + 驗證。
- 排他性 plugin 類型透過 `plugins.slots.*` 選擇。
  - `kind: "memory"` 由 `plugins.slots.memory` 選擇。
  - `kind: "context-engine"` 由 `plugins.slots.contextEngine` 選擇（預設：內建 `legacy`）。
- 若你的 plugin 依賴原生模組，請記錄建置步驟和任何套件管理員允許清單需求（例如 pnpm `allow-build-scripts` - `pnpm rebuild <package>`）。
