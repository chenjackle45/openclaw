---
title: "status(狀態盤查)"
summary: "`openclaw status` CLI 參考（診斷、探針與使用量快照）"
read_when:
  - 想要快速診斷頻道健康度與近期會話接收者時
  - 需要一份可貼上的「完整」狀態報告以進行偵錯時
---

# `openclaw status`

頻道與會話的診斷工具。

```bash
# 基礎狀態顯示
openclaw status

# 顯示所有詳細資訊（適合用於貼上至問題回報）
openclaw status --all

# 執行深度探針（包含 WhatsApp, Telegram, Discord 等實時連線檢查）
openclaw status --deep

# 顯示模型供應商的使用量計量
openclaw status --usage
```

**注意事項**：
- `--deep` 旗標會觸發針對所有已配置頻道的實時連線探測。
- 若配置了多代理系統，輸出將包含各個 Agent 的會話儲存狀態。
- 總覽 (Overview) 資訊中會包含 Gateway 以及節點主機 (Node host) 服務的安裝與運行狀態。
- 總覽資訊也會顯示目前的更新頻道 (Channel) 以及 Git SHA 版本（適用於從原始碼編譯的版本）。
- 如果有可用更新，`status` 會在總覽中顯示提醒，指引用戶執行 `openclaw update`（詳見 [更新指南](/install/updating)）。
