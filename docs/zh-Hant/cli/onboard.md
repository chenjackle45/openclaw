---
title: "onboard(新手引導)"
summary: "`openclaw onboard` CLI 參考（互動式新手導覽嚮導）"
read_when:
  - 想要針對 Gateway、工作區、認證、頻道與技能進行引導式設定時
---

# `openclaw onboard`

互動式新手導覽嚮導（支援本地或遠端 Gateway 設定）。

相關資訊：
- 嚮導操作指南：[新手導覽 (Onboarding)](/start/onboarding)

## 指令範例

```bash
# 開啟預設的新手導覽
openclaw onboard

# 以「快速開始」流程執行
openclaw onboard --flow quickstart

# 以「手動」流程執行
openclaw onboard --flow manual

# 以遠端模式連線至特定 Gateway 進行設定
openclaw onboard --mode remote --remote-url ws://gateway-host:18789
```

**流程備註**：
- `quickstart`：將提示訊息減至最少，並自動產生 Gateway 權杖。
- `manual`：針對埠位、編譯、認證等提供完整的互動提示（等同於 `advanced`）。
- **最速首聊**：執行 `openclaw dashboard` 可以開啟主控制 UI，無需進行頻道設定即可開始對話。
