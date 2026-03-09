---
summary: "`openclaw configure` CLI 參考（互動式配置提示）"
read_when:
  - 想要透過互動方式調整憑證、裝置或 Agent 預設值時
title: "configure（互動式配置）"
---

# `openclaw configure`

互動式提示，用於設定憑證、裝置和 Agent 預設值。

注意：**Model** 區段現在包含多選功能，用於設定 `agents.defaults.models` 允許清單（即 `/model` 和模型選擇器中顯示的內容）。

提示：不帶子指令的 `openclaw config` 會開啟相同的精靈。使用 `openclaw config get|set|unset` 進行非互動式編輯。

相關資訊：

- Gateway 配置參考：[Configuration](/zh-Hant/gateway/configuration)
- Config CLI：[Config](/zh-Hant/cli/config)

注意事項：

- 選擇 Gateway 運行位置時，一律會更新 `gateway.mode`。若這是您唯一需要的設定，您可以選擇「Continue」而不修改其他區段。
- 頻道導向的服務（Slack/Discord/Matrix/Microsoft Teams）在設定期間會提示輸入頻道/房間允許清單。您可以輸入名稱或 ID；精靈會在可能時將名稱解析為 ID。
- 若您執行 daemon 安裝步驟，token 認證需要 token，而 `gateway.auth.token` 是 SecretRef 管理的，configure 會驗證 SecretRef 但不會將解析後的明文 token 值儲存至監督服務的環境中繼資料。
- 若 token 認證需要 token 且配置的 token SecretRef 未解析，configure 會阻止 daemon 安裝並提供可操作的修復指引。
- 若 `gateway.auth.token` 和 `gateway.auth.password` 均已配置，且 `gateway.auth.mode` 未設定，configure 會阻止 daemon 安裝，直到明確設定 mode 為止。

## 範例

```bash
openclaw configure
openclaw configure --section model --section channels
```
