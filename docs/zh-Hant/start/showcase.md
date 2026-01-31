---
title: "Showcase(專案展示)"
description: "來自社群的真實 OpenClaw 專案"
summary: "由 OpenClaw 驅動的社群建置專案和整合"
---

# Showcase(專案展示)

來自社群的真實專案。看看人們用 OpenClaw 建置了什麼。

<Info>
**想被展示嗎？** 在 [Discord #showcase](https://discord.gg/clawd) 分享您的專案或在 X 上 [標記 @openclaw](https://x.com/openclaw)。
</Info>

## 🎥 OpenClaw in Action(OpenClaw 實戰)

完整設定演練（28 分鐘），由 VelvetShark 製作。

<div
  style={{
    position: "relative",
    paddingBottom: "56.25%",
    height: 0,
    overflow: "hidden",
    borderRadius: 16,
  }}
>
  <iframe
    src="https://www.youtube-nocookie.com/embed/SaWSPZoPX34"
    title="OpenClaw: The self-hosted AI that Siri should have been (Full setup)"
    style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%" }}
    frameBorder="0"
    loading="lazy"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowFullScreen
  />
</div>

[在 YouTube 觀看](https://www.youtube.com/watch?v=SaWSPZoPX34)

<div
  style={{
    position: "relative",
    paddingBottom: "56.25%",
    height: 0,
    overflow: "hidden",
    borderRadius: 16,
  }}
>
  <iframe
    src="https://www.youtube-nocookie.com/embed/mMSKQvlmFuQ"
    title="OpenClaw showcase video"
    style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%" }}
    frameBorder="0"
    loading="lazy"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowFullScreen
  />
</div>

[在 YouTube 觀看](https://www.youtube.com/watch?v=mMSKQvlmFuQ)

<div
  style={{
    position: "relative",
    paddingBottom: "56.25%",
    height: 0,
    overflow: "hidden",
    borderRadius: 16,
  }}
>
  <iframe
    src="https://www.youtube-nocookie.com/embed/5kkIJNUGFho"
    title="OpenClaw community showcase"
    style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%" }}
    frameBorder="0"
    loading="lazy"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowFullScreen
  />
</div>

[在 YouTube 觀看](https://www.youtube.com/watch?v=5kkIJNUGFho)

## 🆕 Fresh from Discord(來自 Discord 的新鮮內容)

<CardGroup cols={2}>

<Card title="PR Review → Telegram Feedback" icon="code-pull-request" href="https://x.com/i/status/2010878524543131691">
  **@bangnokia** • `review` `github` `telegram`

  OpenCode 完成變更 → 開啟 PR → OpenClaw 審查 diff 並在 Telegram 中以「小建議」回覆，加上明確的合併判斷（包括首先套用的關鍵修復）。

  <img src="/assets/showcase/pr-review-telegram.jpg" alt="OpenClaw PR review feedback delivered in Telegram" />
</Card>

<Card title="Wine Cellar Skill in Minutes(數分鐘內的酒窖 Skill)" icon="wine-glass" href="https://x.com/i/status/2010916352454791216">
  **@prades_maxime** • `skills` `local` `csv`

  請求「Robby」（@openclaw）提供本地酒窖 skill。它請求範例 CSV 匯出 + 儲存位置，然後快速建置/測試 skill（範例中有 962 瓶）。

  <img src="/assets/showcase/wine-cellar-skill.jpg" alt="OpenClaw building a local wine cellar skill from CSV" />
</Card>

<Card title="Tesco Shop Autopilot(Tesco 購物自動駕駛)" icon="cart-shopping" href="https://x.com/i/status/2009724862470689131">
  **@marchattonhere** • `automation` `browser` `shopping`

  每週膳食計畫 → 常規 → 預訂交貨時段 → 確認訂單。無 APIs，僅瀏覽器控制。

  <img src="/assets/showcase/tesco-shop.jpg" alt="Tesco shop automation via chat" />
</Card>

<Card title="SNAG Screenshot-to-Markdown(SNAG 截圖轉 Markdown)" icon="scissors" href="https://github.com/am-will/snag">
  **@am-will** • `devtools` `screenshots` `markdown`

  熱鍵螢幕區域 → Gemini vision → 剪貼簿中的即時 Markdown。

  <img src="/assets/showcase/snag.png" alt="SNAG screenshot-to-markdown tool" />
</Card>

<Card title="Agents UI" icon="window-maximize" href="https://releaseflow.net/kitze/agents-ui">
  **@kitze** • `ui` `skills` `sync`

  桌面 app，用於跨 Agents、Claude、Codex 和 OpenClaw 管理 skills/commands。

  <img src="/assets/showcase/agents-ui.jpg" alt="Agents UI app" />
</Card>

<Card title="Telegram Voice Notes (papla.media)" icon="microphone" href="https://papla.media/docs">
  **Community(社群)** • `voice` `tts` `telegram`

  包裝 papla.media TTS 並將結果作為 Telegram 語音筆記發送（無煩人的自動播放）。

  <img src="/assets/showcase/papla-tts.jpg" alt="Telegram voice note output from TTS" />
</Card>

<Card title="CodexMonitor" icon="eye" href="https://clawdhub.com/odrobnik/codexmonitor">
  **@odrobnik** • `devtools` `codex` `brew`

  Homebrew 安裝的 helper，用於列出/檢查/監視本地 OpenAI Codex 會話（CLI + VS Code）。

  <img src="/assets/showcase/codexmonitor.png" alt="CodexMonitor on ClawdHub" />
</Card>

<Card title="Bambu 3D Printer Control(Bambu 3D 列印機控制)" icon="print" href="https://clawdhub.com/tobiasbischoff/bambu-cli">
  **@tobiasbischoff** • `hardware` `3d-printing` `skill`

  控制和疑難排解 BambuLab 列印機：狀態、作業、攝影機、AMS、校準等。

  <img src="/assets/showcase/bambu-cli.png" alt="Bambu CLI skill on ClawdHub" />
</Card>

<Card title="Vienna Transport (Wiener Linien)(維也納交通)" icon="train" href="https://clawdhub.com/hjanuschka/wienerlinien">
  **@hjanuschka** • `travel` `transport` `skill`

  維也納公共交通的即時出發、中斷、電梯狀態和路線。

  <img src="/assets/showcase/wienerlinien.png" alt="Wiener Linien skill on ClawdHub" />
</Card>

<Card title="ParentPay School Meals(ParentPay 校餐)" icon="utensils" href="#">
  **@George5562** • `automation` `browser` `parenting`

  透過 ParentPay 自動化英國校餐預訂。使用滑鼠座標可靠地點擊表格儲存格。
</Card>

<Card title="R2 Upload (Send Me My Files)" icon="cloud-arrow-up" href="https://clawdhub.com/skills/r2-upload">
  **@julianengel** • `files` `r2` `presigned-urls`

  上傳到 Cloudflare R2/S3 並生成安全的預簽名下載連結。非常適合遠端 OpenClaw 實例。
</Card>

<Card title="iOS App via Telegram(透過 Telegram 的 iOS App)" icon="mobile" href="#">
  **@coard** • `ios` `xcode` `testflight`

  完全透過 Telegram 聊天建置了一個完整的 iOS app，包含地圖和語音錄製，並部署到 TestFlight。

  <img src="/assets/showcase/ios-testflight.jpg" alt="iOS app on TestFlight" />
</Card>

<Card title="Oura Ring Health Assistant(Oura Ring 健康助手)" icon="heart-pulse" href="#">
  **@AS** • `health` `oura` `calendar`

  個人 AI 健康助手，整合 Oura ring 資料與行事曆、約會和健身房時程。

  <img src="/assets/showcase/oura-health.png" alt="Oura ring health assistant" />
</Card>

<Card title="Kev's Dream Team (14+ Agents)(Kev 的夢幻團隊（14+ 個 Agents）)" icon="robot" href="https://github.com/adam91holt/orchestrated-ai-articles">
  **@adam91holt** • `multi-agent` `orchestration` `architecture` `manifesto`

  一個 gateway 下的 14+ 個 agents，Opus 4.5 orchestrator 委派給 Codex workers。全面的[技術文章](https://github.com/adam91holt/orchestrated-ai-articles)涵蓋 Dream Team 名單、模型選擇、沙盒、webhooks、heartbeats 和委派流程。[Clawdspace](https://github.com/adam91holt/clawdspace) 用於 agent 沙盒。[部落格文章](https://adams-ai-journey.ghost.io/2026-the-year-of-the-orchestrator/)。
</Card>

<Card title="Linear CLI" icon="terminal" href="https://github.com/Finesssee/linear-cli">
  **@NessZerra** • `devtools` `linear` `cli` `issues`

  與 agentic workflows（Claude Code、OpenClaw）整合的 Linear CLI。從終端管理 issues、projects 和 workflows。第一個外部 PR 合併！
</Card>

<Card title="Beeper CLI" icon="message" href="https://github.com/blqke/beepcli">
  **@jules** • `messaging` `beeper` `cli` `automation`

  透過 Beeper Desktop 讀取、發送和歸檔訊息。使用 Beeper 本地 MCP API，以便 agents 可以在一個地方管理所有聊天（iMessage、WhatsApp 等）。
</Card>

</CardGroup>

## 🤖 Automation & Workflows(自動化與工作流程)

<CardGroup cols={2}>

<Card title="Winix Air Purifier Control(Winix 空氣清淨機控制)" icon="wind" href="https://x.com/antonplex/status/2010518442471006253">
  **@antonplex** • `automation` `hardware` `air-quality`

  Claude Code 發現並確認清淨機控制，然後 OpenClaw 接管以管理房間空氣品質。

  <img src="/assets/showcase/winix-air-purifier.jpg" alt="Winix air purifier control via OpenClaw" />
</Card>

<Card title="Pretty Sky Camera Shots(美麗天空攝影)" icon="camera" href="https://x.com/signalgaining/status/2010523120604746151">
  **@signalgaining** • `automation` `camera` `skill` `images`

  由屋頂攝影機觸發：當天空看起來很漂亮時，請 OpenClaw 拍照 — 它設計了一個 skill 並拍了照。

  <img src="/assets/showcase/roof-camera-sky.jpg" alt="Roof camera sky snapshot captured by OpenClaw" />
</Card>

<Card title="Visual Morning Briefing Scene(視覺早晨簡報場景)" icon="robot" href="https://x.com/buddyhadry/status/2010005331925954739">
  **@buddyhadry** • `automation` `briefing` `images` `telegram`

  排程提示每天早上生成單個「場景」圖像（天氣、任務、日期、最愛貼文/引用），透過 OpenClaw persona。
</Card>

<Card title="Padel Court Booking(Padel 球場預訂)" icon="calendar-check" href="https://github.com/joshp123/padel-cli">
  **@joshp123** • `automation` `booking` `cli`

  Playtomic 可用性檢查器 + 預訂 CLI。再也不會錯過開放球場。

  <img src="/assets/showcase/padel-screenshot.jpg" alt="padel-cli screenshot" />
</Card>

<Card title="Accounting Intake(會計攝入)" icon="file-invoice-dollar">
  **Community(社群)** • `automation` `email` `pdf`

  從電子郵件收集 PDFs，為稅務顧問準備文件。自動駕駛每月會計。
</Card>

<Card title="Couch Potato Dev Mode(沙發馬鈴薯開發模式)" icon="couch" href="https://davekiss.com">
  **@davekiss** • `telegram` `website` `migration` `astro`

  在看 Netflix 時透過 Telegram 重建整個個人網站 — Notion → Astro，遷移 18 篇文章，DNS 到 Cloudflare。從未打開筆電。
</Card>

<Card title="Job Search Agent(求職 Agent)" icon="briefcase">
  **@attol8** • `automation` `api` `skill`

  搜尋職位清單，與 CV 關鍵字匹配，並返回帶連結的相關機會。使用 JSearch API 在 30 分鐘內建置。
</Card>

<Card title="Jira Skill Builder(Jira Skill 建置器)" icon="diagram-project" href="https://x.com/jdrhyne/status/2008336434827002232">
  **@jdrhyne** • `automation` `jira` `skill` `devtools`

  OpenClaw 連線到 Jira，然後即時生成新 skill（在 ClawdHub 上存在之前）。
</Card>

<Card title="Todoist Skill via Telegram(透過 Telegram 的 Todoist Skill)" icon="list-check" href="https://x.com/iamsubhrajyoti/status/2009949389884920153">
  **@iamsubhrajyoti** • `automation` `todoist` `skill` `telegram`

  自動化 Todoist 任務，並讓 OpenClaw 直接在 Telegram 聊天中生成 skill。
</Card>

<Card title="TradingView Analysis(TradingView 分析)" icon="chart-line">
  **@bheem1798** • `finance` `browser` `automation`

  透過瀏覽器自動化登入 TradingView，截圖圖表，並按需執行技術分析。無需 API — 僅瀏覽器控制。
</Card>

<Card title="Slack Auto-Support(Slack 自動支援)" icon="slack">
  **@henrymascot** • `slack` `automation` `support`

  監視公司 Slack 頻道，提供有益回覆，並將通知轉發到 Telegram。在未被要求的情況下自主修復了已部署 app 中的生產 bug。
</Card>

</CardGroup>

## 🧠 Knowledge & Memory(知識與記憶體)

<CardGroup cols={2}>

<Card title="xuezh Chinese Learning(xuezh 中文學習)" icon="language" href="https://github.com/joshp123/xuezh">
  **@joshp123** • `learning` `voice` `skill`

  中文學習引擎，透過 OpenClaw 提供發音回饋和學習流程。

  <img src="/assets/showcase/xuezh-pronunciation.jpeg" alt="xuezh pronunciation feedback" />
</Card>

<Card title="WhatsApp Memory Vault(WhatsApp 記憶體保險庫)" icon="vault">
  **Community(社群)** • `memory` `transcription` `indexing`

  攝入完整 WhatsApp 匯出，轉錄 1k+ 語音筆記，與 git logs 交叉檢查，輸出連結的 markdown 報告。
</Card>

<Card title="Karakeep Semantic Search(Karakeep 語意搜尋)" icon="magnifying-glass" href="https://github.com/jamesbrooksco/karakeep-semantic-search">
  **@jamesbrooksco** • `search` `vector` `bookmarks`

  使用 Qdrant + OpenAI/Ollama embeddings 向 Karakeep 書籤新增向量搜尋。
</Card>

<Card title="Inside-Out-2 Memory" icon="brain">
  **Community(社群)** • `memory` `beliefs` `self-model`

  單獨的記憶體管理器，將會話檔案轉換為記憶體 → 信念 → 演變的自我模型。
</Card>

</CardGroup>

## 🎙️ Voice & Phone(語音與電話)

<CardGroup cols={2}>

<Card title="Clawdia Phone Bridge" icon="phone" href="https://github.com/alejandroOPI/clawdia-bridge">
  **@alejandroOPI** • `voice` `vapi` `bridge`

  Vapi 語音助手 ↔ OpenClaw HTTP bridge。與您的 agent 進行近即時電話通話。
</Card>

<Card title="OpenRouter Transcription(OpenRouter 轉錄)" icon="microphone" href="https://clawdhub.com/obviyus/openrouter-transcribe">
  **@obviyus** • `transcription` `multilingual` `skill`

  透過 OpenRouter（Gemini 等）進行多語言音訊轉錄。在 ClawdHub 上可用。
</Card>

</CardGroup>

## 🏗️ Infrastructure & Deployment(基礎設施與部署)

<CardGroup cols={2}>

<Card title="Home Assistant Add-on" icon="home" href="https://github.com/ngutman/openclaw-ha-addon">
  **@ngutman** • `homeassistant` `docker` `raspberry-pi`

  在 Home Assistant OS 上執行的 OpenClaw gateway，具有 SSH tunnel 支援和持久狀態。
</Card>

<Card title="Home Assistant Skill" icon="toggle-on" href="https://clawdhub.com/skills/homeassistant">
  **ClawdHub** • `homeassistant` `skill` `automation`

  透過自然語言控制和自動化 Home Assistant 裝置。
</Card>

<Card title="Nix Packaging" icon="snowflake" href="https://github.com/openclaw/nix-openclaw">
  **@openclaw** • `nix` `packaging` `deployment`

  電池包含的 nixified OpenClaw 設定，用於可重現部署。
</Card>

<Card title="CalDAV Calendar" icon="calendar" href="https://clawdhub.com/skills/caldav-calendar">
  **ClawdHub** • `calendar` `caldav` `skill`

  使用 khal/vdirsyncer 的行事曆 skill。自託管行事曆整合。
</Card>

</CardGroup>

## 🏠 Home & Hardware(家居與硬體)

<CardGroup cols={2}>

<Card title="GoHome Automation" icon="house-signal" href="https://github.com/joshp123/gohome">
  **@joshp123** • `home` `nix` `grafana`

  Nix-native 家居自動化，OpenClaw 作為介面，加上美麗的 Grafana 儀表板。

  <img src="/assets/showcase/gohome-grafana.png" alt="GoHome Grafana dashboard" />
</Card>

<Card title="Roborock Vacuum(Roborock 吸塵器)" icon="robot" href="https://github.com/joshp123/gohome/tree/main/plugins/roborock">
  **@joshp123** • `vacuum` `iot` `plugin`

  透過自然對話控制您的 Roborock 機器人吸塵器。

  <img src="/assets/showcase/roborock-screenshot.jpg" alt="Roborock status" />
</Card>

</CardGroup>

## 🌟 Community Projects(社群專案)

<CardGroup cols={2}>

<Card title="StarSwap Marketplace" icon="star" href="https://star-swap.com/">
  **Community(社群)** • `marketplace` `astronomy` `webapp`

  完整的天文設備市場。圍繞 OpenClaw 生態系統建置。
</Card>

</CardGroup>

---

## Submit Your Project(提交您的專案)

有東西要分享嗎？我們很樂意展示它！

<Steps>
  <Step title="分享它">
    在 [Discord #showcase](https://discord.gg/clawd) 發佈或 [tweet @openclaw](https://x.com/openclaw)
  </Step>
  <Step title="包含詳細資訊">
    告訴我們它的作用，連結到 repo/demo，如果有的話分享截圖
  </Step>
  <Step title="獲得展示">
    我們會將出色的專案新增到此頁面
  </Step>
</Steps>
