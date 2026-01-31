---
title: "configure(互動式配置)"
summary: "`openclaw configure` CLI 參考（互動式配置提示）"
read_when:
  - 想要以互動方式調整憑證、裝置或 Agent 預設值時
---

# `openclaw configure`

互動式提示引導，用於設定憑證、裝置與 Agent 預設值。

**模型 (Model)** 區塊包含一個多選清單，用於設定 `agents.defaults.models` 允許清單（即在 `/model` 與模型選擇器中顯示的項目）。

提示：執行不帶子指令的 `openclaw config` 亦可開啟相同的嚮導。若要進行非互動式的編輯，請改用 `openclaw config get|set|unset`。

相關資訊：
- Gateway 配置參考：[配置導覽 (Configuration)](/gateway/configuration)
- 配置 CLI 指令：[Config](/cli/config)

**注意事項**：
- 選擇 Gateway 的運行位置會同步更新 `gateway.mode`。如果您只需要進行這項設定，在完成該區塊後選取「繼續 (Continue)」即可。
- 頻道類服務（如 Slack/Discord/Matrix/Microsoft Teams）在設定過程中會提示輸入頻道/聊天室允許清單。您可以輸入名稱或 ID；嚮導會在可能的情況下自動將名稱解析為 ID。

## 指令範例

```bash
# 開啟完整的互動式配置嚮導
openclaw configure

# 僅針對模型與頻道區塊進行部分配置
openclaw configure --section models --section channels
```
