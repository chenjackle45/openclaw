---
title: "skills(技能管理)"
summary: "`openclaw skills` CLI 參考（列表、資訊與狀態檢查）以及技能執行門檻"
read_when:
  - 想要查看哪些技能可用且已就緒可執行時
  - 想要偵錯技能缺少的二進位檔、環境變數或配置時
---

# `openclaw skills`

盤查技能（包含內建技能、工作區技能與受管覆寫條目），並查看哪些技能符合執行條件 (Eligible) 或是缺少必要的依賴需求。

相關資訊：
- 技能系統導覽：[技能 (Skills)](/tools/skills)
- 技能配置說明：[技能配置 (Skills config)](/tools/skills-config)
- ClawdHub 安裝指南：[ClawdHub](/tools/clawdhub)

## 指令說明

```bash
# 列出所有發現的技能
openclaw skills list

# 僅顯示符合目前系統執行條件的技能
openclaw skills list --eligible

# 查看特定技能的詳細資訊與需求清單
openclaw skills info <技能名稱>

# 顯示技能就緒狀態的摘要報告
openclaw skills check
```
