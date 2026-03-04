---
summary: "在 OpenClaw 中使用 MiniMax M2.5"
read_when:
  - You want MiniMax models in OpenClaw
  - You need MiniMax setup guidance
title: "MiniMax（MiniMax）"
---

# MiniMax

MiniMax 是一家構建 **M2/M2.5** 模型族的 AI 公司。目前編碼聚焦發行版是 **MiniMax M2.5**（2025 年 12 月 23 日），為實際複雜任務而建。

來源：[MiniMax M2.5 發佈說明](https://www.minimax.io/news/minimax-m25)

## 模型概述（M2.5）

MiniMax 在 M2.5 中強調這些改進：

- 更強的**多語言編碼**（Rust、Java、Go、C++、Kotlin、Objective-C、TS/JS）。
- 更好的**網路 / 應用開發**和美學輸出品質（包括原生行動）。
- 改進的**複合指令**處理用於辦公室風格工作流程，基於交錯思考和整合約束執行。
- **更簡潔的回應**，更低令牌使用和更快迭代迴圈。
- 更強的**工具 / 代理框架**相容性和內容管理（Claude Code、Droid/Factory AI、Cline、Kilo Code、Roo Code、BlackBox）。
- 更高品質**對話和技術寫作**輸出。

## MiniMax M2.5 vs MiniMax M2.5 Highspeed

- **速度：** `MiniMax-M2.5-highspeed` 是 MiniMax 文件中的官方快速層級。
- **成本：** MiniMax 定價列出相同的輸入成本和更高的 highspeed 輸出成本。
- **相容性：** OpenClaw 仍接受舊版 `MiniMax-M2.5-Lightning` 設定，但偏好新設定使用 `MiniMax-M2.5-highspeed`。

## 選擇設定

### MiniMax OAuth（編碼方案） — 建議

**最佳用於：** 透過 OAuth 快速設定 MiniMax 編碼方案，不需要 API 鑰。

啟用綁定 OAuth 外掛並認證：

```bash
openclaw plugins enable minimax-portal-auth  # 跳過如果已加載
openclaw gateway restart  # 重啟如果 gateway 已執行
openclaw onboard --auth-choice minimax-portal
```

您將被提示選擇端點：

- **Global** - 國際使用者（`api.minimax.io`）
- **CN** - 中國使用者（`api.minimaxi.com`）

見 [MiniMax OAuth 外掛 README](https://github.com/openclaw/openclaw/tree/main/extensions/minimax-portal-auth)。
