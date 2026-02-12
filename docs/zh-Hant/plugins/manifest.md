---
summary: "外掛程式清單 + JSON 結構描述要求（嚴格設定驗證）"
read_when:
  - 你正在建置 OpenClaw 外掛程式
  - 你需要運出外掛程式設定結構描述或調試外掛程式驗證錯誤
title: "Plugin Manifest（外掛程式清單）"
---

# 外掛程式清單（openclaw.plugin.json）

每個外掛程式**必須**在**外掛程式根目錄**中運出 `openclaw.plugin.json` 檔案。
OpenClaw 使用此清單**無需執行外掛程式程式碼**來驗證設定。遺漏或無效的清單被視為外掛程式錯誤並阻止設定驗證。

詳見完整外掛程式系統指南：[外掛程式](/zh-Hant/tools/plugin)。

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

- `id`（字串）：規範外掛程式 ID。
- `configSchema`（物件）：外掛程式設定的 JSON 結構描述（內聯）。

選擇性鍵：

- `kind`（字串）：外掛程式類型（範例：`"memory"`）。
- `channels`（陣列）：此外掛程式註冊的頻道 ID（範例：`["matrix"]`）。
- `providers`（陣列）：此外掛程式註冊的提供者 ID。
- `skills`（陣列）：要載入的技能目錄（相對於外掛程式根目錄）。
- `name`（字串）：外掛程式的顯示名稱。
- `description`（字串）：外掛程式的簡短摘要。
- `uiHints`（物件）：設定欄位標籤/預留位置/敏感旗標用於 UI 轉譯。
- `version`（字串）：外掛程式版本（資訊性）。

## JSON 結構描述要求

- **每個外掛程式必須運出 JSON 結構描述**，即使它不接受設定。
- 空結構描述是可接受的（例如 `{ "type": "object", "additionalProperties": false }`）。
- 結構描述在設定讀取/寫入時驗證，而非在執行時。

## 驗證行為

- 未知 `channels.*` 鍵是**錯誤**，除非頻道 ID 由外掛程式清單聲明。
- `plugins.entries.<id>`、`plugins.allow`、`plugins.deny` 和 `plugins.slots.*`
  必須參考**可探索**的外掛程式 ID。未知 ID 是**錯誤**。
- 如果外掛程式已安裝但有損壞或遺漏的清單或結構描述，驗證失敗且醫生報告外掛程式錯誤。
- 如果外掛程式設定存在但外掛程式已**停用**，設定會保留且在醫生 + 日誌中表面出現**警告**。

## 筆記

- 清單**對所有外掛程式都是必要的**，包括本機檔案系統載入。
- 執行時仍單獨載入外掛程式模組；清單僅用於發現 + 驗證。
- 如果外掛程式依賴原生模組，記錄建置步驟和任何套件管理員允許清單要求（例如 pnpm `allow-build-scripts` - `pnpm rebuild <package>`）。
