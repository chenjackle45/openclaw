---
summary: "`openclaw status` CLI 參考（診斷、探測與使用量快照）"
read_when:
  - 想要快速診斷頻道健康度與近期會話接收者時
  - 想要一份可貼上的「all」狀態以供偵錯時
title: "status（狀態診斷）"
---

# `openclaw status`

頻道與會話的診斷工具。

```bash
openclaw status
openclaw status --all
openclaw status --deep
openclaw status --usage
```

注意事項：

- `--deep` 執行實時探測（WhatsApp Web + Telegram + Discord + Google Chat + Slack + Signal）。
- 當配置了多個 agents 時，輸出包含每個 agent 的會話儲存狀態。
- 總覽包含 Gateway + 節點主機服務安裝/執行時狀態（若可用）。
- 總覽包含更新頻道 + git SHA（適用於原始碼 checkout）。
- 更新資訊顯示在總覽中；若有可用更新，status 會顯示提示以執行 `openclaw update`（請參閱 [Updating](/zh-Hant/install/updating)）。
- 唯讀狀態介面（`status`、`status --json`、`status --all`）在可能時為其目標 config 路徑解析支援的 SecretRefs。
- 若支援的頻道 SecretRef 已配置但在當前指令路徑中無法使用，status 保持唯讀並回報降級輸出而非崩潰。人類可讀輸出顯示警告如「configured token unavailable in this command path」，JSON 輸出包含 `secretDiagnostics`。
