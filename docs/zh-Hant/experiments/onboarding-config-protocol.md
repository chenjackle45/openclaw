---
title: "Onboarding config protocol(引導設定協定)"
summary: "引導嚮導和設定 schema 的 RPC 協定注意事項"
read_when: "更改引導嚮導步驟或設定 schema 端點時"
---

# Onboarding + Config Protocol(引導 + 設定協定)

目的：跨 CLI、macOS app 和 Web UI 的共享引導 + 設定介面。

## 組件
- Wizard 引擎（共享會話 + 提示 + 引導狀態）。
- CLI 引導使用與 UI 客戶端相同的 wizard 流程。
- Gateway RPC 公開 wizard + config schema 端點。
- macOS 引導使用 wizard 步驟模型。
- Web UI 從 JSON Schema + UI hints 呈現設定表單。

## Gateway RPC
- `wizard.start` 參數：`{ mode?: "local"|"remote", workspace?: string }`
- `wizard.next` 參數：`{ sessionId, answer?: { stepId, value? } }`
- `wizard.cancel` 參數：`{ sessionId }`
- `wizard.status` 參數：`{ sessionId }`
- `config.schema` 參數：`{}`

回應（形狀）
- Wizard：`{ sessionId, done, step?, status?, error? }`
- Config schema：`{ schema, uiHints, version, generatedAt }`

## UI Hints
- `uiHints` 按路徑鍵控；選用 metadata（label/help/group/order/advanced/sensitive/placeholder）。
- 敏感欄位呈現為密碼輸入；無脫敏層。
- 不支援的 schema 節點回退到原始 JSON 編輯器。

## 注意事項
- 此文件是追蹤引導/設定協定重構的單一位置。
