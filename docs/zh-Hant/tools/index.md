---
summary: "OpenClaw 的代理工具表面（瀏覽器、畫布、節點、訊息、cron）替代舊版 `openclaw-*` 技能"
read_when:
  - Adding or modifying agent tools
  - Retiring or changing `openclaw-*` skills
title: "Tools（工具）"
---

# 工具（OpenClaw）

OpenClaw 公開**一級代理工具**用於瀏覽器、畫布、節點和 cron。
這些替代舊版 `openclaw-*` 技能：工具是類型化的，無殼層，
代理應直接依賴於它們。

## 停用工具

您可以透過 `openclaw.json` 中的 `tools.allow` / `tools.deny` 全域允許 / 拒絕工具（拒絕優先）。這防止不允許的工具被發送到模型提供者。

```json5
{
  tools: { deny: ["browser"] },
}
```

註記：

- 匹配大小寫不敏感。
- 支援 `*` 萬用字元（`"*"` 表示所有工具）。
- 如果 `tools.allow` 只參考未知或未加載的外掛工具名稱，OpenClaw 會記錄警告並忽略允許清單，以保持核心工具可用。

## 工具設定檔（基本允許清單）

`tools.profile` 設定**基本工具允許清單**，在 `tools.allow`/`tools.deny` 之前。
按代理覆蓋：`agents.list[].tools.profile`。

設定檔：

- `minimal`：僅 `session_status`
- `coding`：`group:fs`、`group:runtime`、`group:sessions`、`group:memory`、`image`
- `messaging`：`group:messaging`、`sessions_list`、`sessions_history`、`sessions_send`、`session_status`
- `full`：無限制（與未設定相同）

範例（預設僅訊息，也允許 Slack + Discord 工具）：

```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"],
  },
}
```
