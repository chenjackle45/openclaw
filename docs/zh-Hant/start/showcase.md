---
title: "Showcase（展示）"
description: "來自社群的真實 OpenClaw 專案"
summary: "由社群建構的專案和由 OpenClaw 提供支援的整合"
read_when:
  - 尋找真實 OpenClaw 使用範例
  - 更新社群專案亮點
---

# 展示

來自社群的真實專案。看看人們用 OpenClaw 建構什麼。

<Info>
**想被推薦嗎？** 在 [Discord 的 #showcase](https://discord.gg/clawd) 分享你的專案或[在 X 上標籤 @openclaw](https://x.com/openclaw)。
</Info>

## 影片展示

全部設定演練（28 分鐘），由 VelvetShark 呈現。

[觀看 YouTube](https://www.youtube.com/watch?v=SaWSPZoPX34)

[觀看 YouTube](https://www.youtube.com/watch?v=mMSKQvlmFuQ)

[觀看 YouTube](https://www.youtube.com/watch?v=5kkIJNUGFho)

## 最新來自 Discord

**PR 評論 → Telegram 反饋** • `review` `github` `telegram`
@bangnokia

OpenCode 完成變更 → 開啟 PR → OpenClaw 評論差異並在 Telegram 中回覆「次要建議」加清晰合併決定（包括首先應用的重要修復）。

**分鐘內的葡萄酒地窖技能** • `skills` `local` `csv`
@prades_maxime

要求「Robby」(@openclaw) 製作本地葡萄酒地窖技能。它要求範例 CSV 匯出加儲存位置，然後快速構建/測試技能（示例中 962 瓶）。

**Tesco 商店自動駕駛** • `automation` `browser` `shopping`
@marchattonhere

每週膳食計畫 → 常客 → 預訂配送時段 → 確認訂單。無 API，僅瀏覽器控制。

**SNAG 屏幕截圖轉 Markdown** • `devtools` `screenshots` `markdown`
@am-will

快速鍵螢幕區域 → Gemini 視覺 → 剪貼簿中的即時 Markdown。

**代理 UI** • `ui` `skills` `sync`
@kitze

桌面應用程式以管理代理、Claude、Codex 和 OpenClaw 的技能/命令。

**Telegram 語音筆記 (papla.media)** • `voice` `tts` `telegram`
社群

包裝 papla.media TTS 並將結果傳送為 Telegram 語音筆記（無惱人的自動播放）。

**CodexMonitor** • `devtools` `codex` `brew`
@odrobnik

Homebrew 安裝的輔助工具，用於列出/檢查/監視本地 OpenAI Codex 會話（CLI + VS Code）。

**Bambu 3D 印表機控制** • `hardware` `3d-printing` `skill`
@tobiasbischoff

控制和故障排查 BambuLab 印表機：狀態、工作、相機、AMS、校正等。

**維也納交通（Wiener Linien）** • `travel` `transport` `skill`
@hjanuschka

維也納公共交通的實時出發、中斷、電梯狀態和路由。

**ParentPay 學校膳食** • `automation` `browser` `parenting`
@George5562

通過 ParentPay 自動化英國學校膳食預訂。使用滑鼠座標以可靠的表格儲存格點擊。

**R2 上傳（傳送我的檔案）** • `files` `r2` `presigned-urls`
@julianengel

上傳到 Cloudflare R2/S3 並生成安全預簽名下載連結。非常適合遠端 OpenClaw 執行個體。

**通過 Telegram 的 iOS 應用程式** • `ios` `xcode` `testflight`
@coard

構建一個完整的 iOS 應用程式，配有地圖和語音錄製，完全通過 Telegram 聊天部署到 TestFlight。

**Oura Ring 健康助手** • `health` `oura` `calendar`
@AS

個人 AI 健康助手，整合 Oura 環資料與日曆、約會和健身房時程表。

**Kev 的夢幻隊（14+ 代理）** • `multi-agent` `orchestration` `architecture` `manifesto`
@adam91holt

一個網關下的 14+ 代理，由 Opus 4.5 協調器委派給 Codex 工作者。全面[技術撰寫](https://github.com/adam91holt/orchestrated-ai-articles)涵蓋夢幻隊名單、模型選擇、沙盒、webhook、心跳和委派流。[Clawdspace](https://github.com/adam91holt/clawdspace) 用於代理沙盒。[部落格文章](https://adams-ai-journey.ghost.io/2026-the-year-of-the-orchestrator/)。

**Linear CLI** • `devtools` `linear` `cli` `issues`
@NessZerra

整合代理工作流（Claude Code、OpenClaw）的 Linear CLI。從終端機管理問題、專案和工作流。首個外部 PR 已合併！

**Beeper CLI** • `messaging` `beeper` `cli` `automation`
@jules

通過 Beeper Desktop 讀取、傳送和封存訊息。使用 Beeper 本地 MCP API，使代理可以在一個地方管理所有聊天（iMessage、WhatsApp 等）。

## 自動化和工作流

**Winix 空氣淨化器控制** • `automation` `hardware` `air-quality`
@antonplex

Claude Code 發現並確認淨化器控制，然後 OpenClaw 接管以管理房間空氣品質。

**漂亮的天空相機拍攝** • `automation` `camera` `skill` `images`
@signalgaining

由屋頂相機觸發：每當天空看起來很漂亮時，要求 OpenClaw 快照天空照片 — 它設計了一個技能並拍攝了照片。

**視覺早晨簡報場景** • `automation` `briefing` `images` `telegram`
@buddyhadry

排程提示每天上午生成單個「場景」影像（天氣、任務、日期、最喜歡的貼文/引用）透過 OpenClaw 角色。

**Padel 球場預訂** • `automation` `booking` `cli`
@joshp123

Playtomic 可用性檢查器加預訂 CLI。永遠不會錯過開放球場。

**會計攝入** • `automation` `email` `pdf`
社群

從電子郵件收集 PDF，為稅務顧問準備檔案。每月會計自動化。

**沙發馬鈴薯開發模式** • `telegram` `website` `migration` `astro`
@davekiss

在看 Netflix 時通過 Telegram 重建整個個人網站 — Notion → Astro，18 篇文章遷移，DNS 到 Cloudflare。從未打開過筆記型電腦。

**工作搜尋代理** • `automation` `api` `skill`
@attol8

搜尋工作清單、與履歷關鍵字匹配，並返回相關機會及連結。使用 JSearch API 在 30 分鐘內構建。

**Jira 技能構建器** • `automation` `jira` `skill` `devtools`
@jdrhyne

OpenClaw 連接到 Jira，然後即時生成新技能（在 ClawHub 上存在之前）。

**通過 Telegram 的 Todoist 技能** • `automation` `todoist` `skill` `telegram`
@iamsubhrajyoti

自動化 Todoist 任務，並讓 OpenClaw 直接在 Telegram 聊天中生成技能。

**TradingView 分析** • `finance` `browser` `automation`
@bheem1798

登入 TradingView 通過瀏覽器自動化、螢幕截圖圖表，並按需進行技術分析。無 API — 僅瀏覽器控制。

**Slack 自動支援** • `slack` `automation` `support`
@henrymascot

監視公司 Slack 頻道、有用地回應，並將通知轉發到 Telegram。自主修復已部署應用程式中的生產錯誤，未被要求。

## 知識和記憶

**xuezh 中文學習** • `learning` `voice` `skill`
@joshp123

帶發音反饋和通過 OpenClaw 研究流的中文學習引擎。

**WhatsApp 記憶庫** • `memory` `transcription` `indexing`
社群

攝入完整 WhatsApp 匯出、轉錄 1k+ 語音筆記、與 git 日誌交叉檢查、輸出連結 markdown 報告。

**Karakeep 語義搜尋** • `search` `vector` `bookmarks`
@jamesbrooksco

使用 Qdrant + OpenAI/Ollama 嵌入將向量搜尋新增至 Karakeep 書籤。

**向內而外 2 記憶** • `memory` `beliefs` `self-model`
社群

單獨記憶經理，將會話檔案變成記憶 → 信念 → 演變自我模型。

## 語音和電話

**Clawdia 電話橋** • `voice` `vapi` `bridge`
@alejandroOPI

Vapi 語音助手 ↔ OpenClaw HTTP 橋接。與你的代理通話接近實時。

**OpenRouter 轉錄** • `transcription` `multilingual` `skill`
@obviyus

多語言音訊轉錄通過 OpenRouter（Gemini 等）。在 ClawHub 上可用。

## 基礎架構和部署

**Home Assistant 附加元件** • `homeassistant` `docker` `raspberry-pi`
@ngutman

OpenClaw 網關在 Home Assistant OS 上執行，帶 SSH 通道支援和持續狀態。

**Home Assistant 技能** • `homeassistant` `skill` `automation`
ClawHub

通過自然語言控制和自動化 Home Assistant 裝置。

**Nix 套件** • `nix` `packaging` `deployment`
@openclaw

電池包含的 nixified OpenClaw 設定以實現可重現部署。

**CalDAV 日曆** • `calendar` `caldav` `skill`
ClawHub

使用 khal/vdirsyncer 的日曆技能。自主控管日曆整合。

## 家庭和硬體

**GoHome 自動化** • `home` `nix` `grafana`
@joshp123

Nix 原生家庭自動化，OpenClaw 作為介面，加美麗的 Grafana 儀表板。

**Roborock 真空** • `vacuum` `iot` `plugin`
@joshp123

通過自然對話控制你的 Roborock 機器人真空。

## 社群專案

**StarSwap 市場** • `marketplace` `astronomy` `webapp`
社群

完整的天文學齒輪市場。使用/圍繞 OpenClaw 生態系統構建。

---

## 提交你的專案

有東西要分享？我們很樂意推薦它！

<Steps>
  <Step title="分享它">
    在 [Discord 的 #showcase](https://discord.gg/clawd) 或[推文 @openclaw](https://x.com/openclaw) 貼文
  </Step>
  <Step title="包含詳細資訊">
    告訴我們它做什麼、連結到回購/演示、如果你有的話分享屏幕截圖
  </Step>
  <Step title="獲得推薦">
    我們會將傑出專案新增到此頁面
  </Step>
</Steps>
