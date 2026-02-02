---
title: "首頁"
summary: "OpenClaw 頂層概覽、功能與目的"
read_when:
  - 向新用戶介紹 OpenClaw
---

# OpenClaw 🦞

> _「EXFOLIATE! EXFOLIATE!」_ — 某隻太空龍蝦

<p align="center">
    <picture>
        <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/openclaw/openclaw/main/docs/assets/openclaw-logo-text-dark.png" />
        <img src="https://raw.githubusercontent.com/openclaw/openclaw/main/docs/assets/openclaw-logo-text.png" alt="OpenClaw" width="500" />
    </picture>
</p>

<p align="center">
  <strong>跨平台 + WhatsApp/Telegram/Discord/iMessage 的 AI 代理 Gateway。</strong><br />
  透過插件支援 Mattermost 等更多平台。
  發送訊息，獲得代理回應 — 隨時隨地。
</p>

<p align="center">
  <a href="https://github.com/openclaw/openclaw">GitHub</a> ·
  <a href="https://github.com/openclaw/openclaw/releases">發布版本</a> ·
  <a href="/">文件</a> ·
  <a href="/start/openclaw">OpenClaw 助理設定</a>
</p>

<Warning>
**非官方翻譯聲明**

這個中文網站是由 **[陳泰呈（Jackle）](https://www.facebook.com/jackle45/)** 因為自己要研究而順手翻譯的。未來不一定會即時更新，也不保證翻譯內容的正確性，純粹就是分享。如需最新且正確的資訊，請參考 [官方英文文件](https://docs.openclaw.ai)。
</Warning>

OpenClaw 將 WhatsApp（透過 WhatsApp Web / Baileys）、Telegram（Bot API / grammY）、Discord（Bot API / discord.js）和 iMessage（imsg CLI）橋接到程式碼代理如 [Pi](https://github.com/badlogic/pi-mono)。插件還支援 Mattermost（Bot API + WebSocket）等更多平台。
OpenClaw 同時也驅動著 OpenClaw 助理。

## 從這裡開始

- **從零開始安裝：** [入門指南](/start/getting-started)
- **引導式設定（推薦）：** [設定精靈](/start/wizard)（`openclaw onboard`）
- **開啟儀表板（本地 Gateway）：** http://127.0.0.1:18789/（或 http://localhost:18789/）

如果 Gateway 在同一台電腦上運行，該連結會立即開啟瀏覽器控制 UI。如果失敗，請先啟動 Gateway：`openclaw gateway`。

## 儀表板（瀏覽器控制 UI）

儀表板是用於聊天、設定、節點、會話等功能的瀏覽器控制 UI。
本地預設：http://127.0.0.1:18789/
遠端存取：[Web 界面](/web) 和 [Tailscale](/gateway/tailscale)

<p align="center">
  <img src="/whatsapp-openclaw.jpg" alt="OpenClaw" width="420" />
</p>

## 運作原理

```
WhatsApp / Telegram / Discord / iMessage（+ 插件）
        │
        ▼
  ┌───────────────────────────┐
  │          Gateway          │  ws://127.0.0.1:18789（僅限本機）
  │       （單一來源）         │
  │                           │  http://[gateway-host]:18793
  │                           │    /__openclaw__/canvas/（Canvas 主機）
  └───────────┬───────────────┘
              │
              ├─ Pi 代理（RPC）
              ├─ CLI（openclaw …）
              ├─ 聊天 UI（SwiftUI）
              ├─ macOS 應用程式（OpenClaw.app）
              ├─ iOS 節點（透過 Gateway WS + 配對）
              └─ Android 節點（透過 Gateway WS + 配對）
```

大多數操作都透過 **Gateway**（`openclaw gateway`）進行，這是一個長期運行的程序，負責管理頻道連線和 WebSocket 控制平面。

## 網路模型

- **每台主機一個 Gateway（建議）**：這是唯一允許擁有 WhatsApp Web 會話的程序。如果您需要救援機器人或嚴格隔離，可以使用隔離的設定檔和連接埠運行多個 Gateway；請參閱 [多 Gateway](/gateway/multiple-gateways)。
- **本機優先**：Gateway WS 預設為 `ws://127.0.0.1:18789`。
  - 精靈現在預設會生成 Gateway 令牌（即使是本機連線）。
  - 對於 Tailnet 存取，請執行 `openclaw gateway --bind tailnet --token ...`（非本機綁定需要令牌）。
- **節點**：連接到 Gateway WebSocket（根據需要使用 LAN/tailnet/SSH）；舊版 TCP 橋接已棄用/移除。
- **Canvas 主機**：在 `canvasHost.port`（預設 `18793`）上的 HTTP 檔案伺服器，為節點 WebView 提供 `/__openclaw__/canvas/`；請參閱 [Gateway 設定](/gateway/configuration)（`canvasHost`）。
- **遠端使用**：SSH 隧道或 tailnet/VPN；請參閱 [遠端存取](/gateway/remote) 和 [探索](/gateway/discovery)。

## 功能（概覽）

- 📱 **WhatsApp 整合** — 使用 Baileys 實作 WhatsApp Web 協議
- ✈️ **Telegram 機器人** — 透過 grammY 支援私訊 + 群組
- 🎮 **Discord 機器人** — 透過 discord.js 支援私訊 + 伺服器頻道
- 🧩 **Mattermost 機器人（插件）** — Bot token + WebSocket 事件
- 💬 **iMessage** — 本地 imsg CLI 整合（僅 macOS）
- 🤖 **代理橋接** — Pi（RPC 模式）搭配工具串流
- ⏱️ **串流 + 分塊** — 區塊串流 + Telegram 草稿串流詳情（[/concepts/streaming](/concepts/streaming)）
- 🧠 **多代理路由** — 將供應商帳戶/對等方路由到隔離的代理（工作區 + 每代理會話）
- 🔐 **訂閱認證** — Anthropic（Claude Pro/Max）+ OpenAI（ChatGPT/Codex）透過 OAuth
- 💬 **會話** — 直接聊天會合併到共享的 `main`（預設）；群組則隔離
- 👥 **群組聊天支援** — 預設為提及式；擁有者可切換 `/activation always|mention`
- 📎 **媒體支援** — 發送和接收圖片、音訊、文件
- 🎤 **語音筆記** — 可選的轉錄 hook
- 🖥️ **WebChat + macOS 應用程式** — 本地 UI + 選單列伴侶應用，用於操作和語音喚醒
- 📱 **iOS 節點** — 配對為節點並公開 Canvas 介面
- 📱 **Android 節點** — 配對為節點並公開 Canvas + 聊天 + 相機

注意：舊版 Claude/Codex/Gemini/Opencode 路徑已移除；Pi 是唯一的程式碼代理路徑。

## 快速開始

運行環境要求：**Node ≥ 22**。

```bash
# 推薦：全域安裝（npm/pnpm）
npm install -g openclaw@latest
# 或：pnpm add -g openclaw@latest

# 引導安裝 + 安裝服務（launchd/systemd 使用者服務）
openclaw onboard --install-daemon

# 配對 WhatsApp Web（顯示 QR 碼）
openclaw channels login

# 引導後 Gateway 會透過服務運行；仍可手動運行：
openclaw gateway --port 18789
```

在 npm 和 git 安裝之間切換很簡單：安裝另一個版本並執行 `openclaw doctor` 以更新 Gateway 服務入口點。

從原始碼（開發）：

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build # 首次運行時自動安裝 UI 依賴
pnpm build
openclaw onboard --install-daemon
```

如果您還沒有全域安裝，請從 repo 透過 `pnpm openclaw ...` 運行引導步驟。

多實例快速開始（可選）：

```bash
OPENCLAW_CONFIG_PATH=~/.openclaw/a.json \
OPENCLAW_STATE_DIR=~/.openclaw-a \
openclaw gateway --port 19001
```

發送測試訊息（需要運行中的 Gateway）：

```bash
openclaw message send --target +15555550123 --message "來自 OpenClaw 的問候"
```

## 設定（可選）

設定檔位於 `~/.openclaw/openclaw.json`。

- 如果您**什麼都不做**，OpenClaw 會以 RPC 模式使用內建的 Pi 二進制檔，並按發送者建立會話。
- 如果您想限制存取，請從 `channels.whatsapp.allowFrom` 開始，並（對於群組）設定提及規則。

範例：

```json5
{
  channels: {
    whatsapp: {
      allowFrom: ["+15555550123"],
      groups: { "*": { requireMention: true } },
    },
  },
  messages: { groupChat: { mentionPatterns: ["@openclaw"] } },
}
```

## 文件

- 從這裡開始：
  - [文件中心（所有頁面連結）](/start/hubs)
  - [幫助](/help) ← _常見修復 + 疑難排解_
  - [設定](/gateway/configuration)
  - [設定範例](/gateway/configuration-examples)
  - [斜線命令](/tools/slash-commands)
  - [多代理路由](/concepts/multi-agent)
  - [更新 / 回滾](/install/updating)
  - [配對（私訊 + 節點）](/start/pairing)
  - [Nix 模式](/install/nix)
  - [OpenClaw 助理設定](/start/openclaw)
  - [技能](/tools/skills)
  - [技能設定](/tools/skills-config)
  - [工作區範本](/reference/templates/AGENTS)
  - [RPC 適配器](/reference/rpc)
  - [Gateway 操作手冊](/gateway)
  - [節點（iOS/Android）](/nodes)
  - [Web 界面（控制 UI）](/web)
  - [探索 + 傳輸](/gateway/discovery)
  - [遠端存取](/gateway/remote)
- 供應商和用戶體驗：
  - [WebChat](/web/webchat)
  - [控制 UI（瀏覽器）](/web/control-ui)
  - [Telegram](/channels/telegram)
  - [Discord](/channels/discord)
  - [Mattermost（插件）](/channels/mattermost)
  - [iMessage](/channels/imessage)
  - [群組](/concepts/groups)
  - [WhatsApp 群組訊息](/concepts/group-messages)
  - [媒體：圖片](/nodes/images)
  - [媒體：音訊](/nodes/audio)
- 伴侶應用程式：
  - [macOS 應用程式](/platforms/macos)
  - [iOS 應用程式](/platforms/ios)
  - [Android 應用程式](/platforms/android)
  - [Windows（WSL2）](/platforms/windows)
  - [Linux 應用程式](/platforms/linux)
- 營運和安全：
  - [會話](/concepts/session)
  - [排程任務](/automation/cron-jobs)
  - [Webhooks](/automation/webhook)
  - [Gmail hooks（Pub/Sub）](/automation/gmail-pubsub)
  - [安全性](/gateway/security)
  - [疑難排解](/gateway/troubleshooting)

## 名稱由來

**OpenClaw = CLAW + TARDIS** — 因為每隻太空龍蝦都需要一台時空機器。

---

_「我們都只是在玩弄自己的提示詞。」_ — 某個可能 token 過量的 AI

## 致謝

- **Peter Steinberger**（[@steipete](https://twitter.com/steipete)）— 創作者，龍蝦語者
- **Mario Zechner**（[@badlogicc](https://twitter.com/badlogicgames)）— Pi 創作者，安全滲透測試員
- **Clawd** — 要求更好名字的太空龍蝦

## 核心貢獻者

- **Maxim Vovshin**（@Hyaxia, 36747317+Hyaxia@users.noreply.github.com）— Blogwatcher 技能
- **Nacho Iacovino**（@nachoiacovino, nacho.iacovino@gmail.com）— 位置解析（Telegram + WhatsApp）

## 授權

MIT — 像海洋中的龍蝦一樣自由 🦞

---

_「我們都只是在玩弄自己的提示詞。」_ — 某個可能 token 過量的 AI
