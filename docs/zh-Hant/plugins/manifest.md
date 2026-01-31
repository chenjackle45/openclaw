---
title: "Manifest(Plugin Manifest)"
summary: "Plugin Manifest + JSON Schema 需求（嚴格 Config 驗證）"
read_when:
  - 您正在建立 OpenClaw Plugin
  - 您需要提供 Plugin Config Schema 或除錯 Plugin 驗證錯誤
---
# Plugin Manifest (openclaw.plugin.json)

每個 Plugin **必須**在 **Plugin Root** 中提供 `openclaw.plugin.json` 檔案。OpenClaw 使用此 Manifest 來驗證設定，**無需執行 Plugin 程式碼**。遺失或無效的 Manifests 會被視為 Plugin 錯誤並阻止 Config 驗證。

請見完整的 Plugin 系統指南：[Plugins](/plugin)。

## 必填欄位

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

必填 Keys：
- `id`（string）：標準 Plugin ID。
- `configSchema`（object）：Plugin Config 的 JSON Schema（內嵌）。

選填 Keys：
- `kind`（string）：Plugin 種類（例如：`"memory"`）。
- `channels`（array）：此 Plugin 註冊的 Channel IDs（例如：`["matrix"]`）。
- `providers`（array）：此 Plugin 註冊的 Provider IDs。
- `skills`（array）：要載入的 Skill 目錄（相對於 Plugin Root）。
- `name`（string）：Plugin 的顯示名稱。
- `description`（string）：簡短的 Plugin 摘要。
- `uiHints`（object）：UI 渲染的 Config 欄位標籤/佔位符/敏感旗標。
- `version`（string）：Plugin 版本（資訊性）。

## JSON Schema 需求

- **每個 Plugin 必須提供 JSON Schema**，即使它不接受 Config。
- 空 Schema 是可接受的（例如 `{ "type": "object", "additionalProperties": false }`）。
- Schemas 在 Config 讀取/寫入時驗證，而非 Runtime。

## 驗證行為

- 未知的 `channels.*` Keys 是**錯誤**，除非 Channel ID 由 Plugin Manifest 宣告。
- `plugins.entries.<id>`、`plugins.allow`、`plugins.deny` 和 `plugins.slots.*` 必須參考**可探索的** Plugin IDs。未知 IDs 是**錯誤**。
- 如果 Plugin 已安裝但有損壞或遺失的 Manifest 或 Schema，驗證失敗且 Doctor 會回報 Plugin 錯誤。
- 如果 Plugin Config 存在但 Plugin 被**停用**，Config 會保留並在 Doctor + Logs 中顯示**警告**。

## 注意事項

- **所有 Plugin 都必須有 Manifest**，包括 Local Filesystem 載入。
- Runtime 仍會單獨載入 Plugin 模組；Manifest 僅用於探索 + 驗證。
- 如果您的 Plugin 依賴 Native 模組，請記錄建置步驟和任何 Package-manager Allowlist 需求（例如 pnpm `allow-build-scripts` + `pnpm rebuild <package>`）。
