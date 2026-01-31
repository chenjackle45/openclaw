---
title: "Strict config(嚴格設定驗證)"
summary: "嚴格設定驗證 + 僅 doctor 遷移"
read_when:
  - 設計或實作設定驗證行為
  - 處理設定遷移或 doctor 工作流程
  - 處理外掛設定 schemas 或外掛載入門控
---
# Strict config validation (doctor-only migrations)(嚴格設定驗證（僅 doctor 遷移）)

## 目標
- **在任何地方拒絕未知設定鍵**（根 + 巢狀）。
- **拒絕沒有 schema的外掛設定**；不載入該外掛。
- **移除載入時的舊版自動遷移**；遷移僅透過 doctor 執行。
- **啟動時自動執行 doctor（dry-run）**；如果無效，阻止非診斷指令。

## 非目標
- 載入時的向後相容性（舊版鍵不自動遷移）。
- 靜默刪除未識別的鍵。

## 嚴格驗證規則
- 設定必須在每個層級精確匹配 schema。
- 未知鍵是驗證錯誤（根或巢狀不允許透傳）。
- `plugins.entries.<id>.config` 必須由外掛的 schema 驗證。
  - 如果外掛缺少 schema，**拒絕外掛載入**並顯示明確錯誤。
- 未知 `channels.<id>` 鍵是錯誤，除非外掛 manifest 宣告頻道 id。
- 所有外掛都需要外掛 manifests（`openclaw.plugin.json`）。

## 外掛 schema 強制執行
- 每個外掛為其設定提供嚴格的 JSON Schema（內聯在 manifest 中）。
- 外掛載入流程：
  1) 解析外掛 manifest + schema（`openclaw.plugin.json`）。
  2) 根據 schema 驗證設定。
  3) 如果缺少 schema 或設定無效：阻止外掛載入，記錄錯誤。
- 錯誤訊息包括：
  - 外掛 id
  - 原因（缺少 schema / 設定無效）
  - 驗證失敗的路徑
- 停用的外掛保留其設定，但 Doctor + 日誌顯示警告。

## Doctor 流程
- 每次載入設定時 Doctor **執行**（預設為 dry-run）。
- 如果設定無效：
  - 列印摘要 + 可行錯誤。
  - 指示：`openclaw doctor --fix`。
- `openclaw doctor --fix`：
  - 套用遷移。
  - 移除未知鍵。
  - 寫入更新的設定。

## 指令門控（當設定無效時）
允許（僅診斷）：
- `openclaw doctor`
- `openclaw logs`
- `openclaw health`
- `openclaw help`
- `openclaw status`
- `openclaw gateway status`

其他一切必須硬失敗，訊息為：「Config invalid. Run `openclaw doctor --fix`.」

## 錯誤 UX 格式
- 單一摘要標頭。
- 分組區段：
  - 未知鍵（完整路徑）
  - 舊版鍵 / 需要遷移
  - 外掛載入失敗（外掛 id + 原因 + 路徑）

## 實作接觸點
- `src/config/zod-schema.ts`：移除根透傳；到處都是嚴格物件。
- `src/config/zod-schema.providers.ts`：確保嚴格頻道 schemas。
- `src/config/validation.ts`：未知鍵失敗；不套用舊版遷移。
- `src/config/io.ts`：移除舊版自動遷移；始終執行 doctor dry-run。
- `src/config/legacy*.ts`：將使用移動到僅 doctor。
- `src/plugins/*`：新增 schema 註冊表 + 門控。
- `src/cli` 中的 CLI 指令門控。

## 測試
- 未知鍵拒絕（根 + 巢狀）。
- 外掛缺少 schema → 外掛載入被阻止，並顯示明確錯誤。
- 設定無效 → gateway 啟動被阻止，除了診斷指令。
- Doctor dry-run 自動；`doctor --fix` 寫入已更正的設定。
