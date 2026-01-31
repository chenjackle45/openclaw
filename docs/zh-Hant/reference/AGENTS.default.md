---
title: "AGENTS.default(預設 Agent 設定)"
summary: "個人助理設定的預設 OpenClaw Agent 指令和 Skills 名冊"
read_when:
  - 開始新的 OpenClaw Agent Session
  - 啟用或稽核預設 Skills
---
# AGENTS.md — OpenClaw 個人助理（預設）

## 首次執行（建議）

OpenClaw 使用專用的 Workspace 目錄給 Agent。預設：`~/.openclaw/workspace`（可透過 `agents.defaults.workspace` 設定）。

1) 建立 Workspace（如果尚不存在）：

```bash
mkdir -p ~/.openclaw/workspace
```

2) 將預設 Workspace 模板複製到 Workspace：

```bash
cp docs/reference/templates/AGENTS.md ~/.openclaw/workspace/AGENTS.md
cp docs/reference/templates/SOUL.md ~/.openclaw/workspace/SOUL.md
cp docs/reference/templates/TOOLS.md ~/.openclaw/workspace/TOOLS.md
```

3) 可選：如果您想要個人助理 Skill 名冊，請用此檔案取代 AGENTS.md：

```bash
cp docs/reference/AGENTS.default.md ~/.openclaw/workspace/AGENTS.md
```

4) 可選：透過設定 `agents.defaults.workspace` 選擇不同的 Workspace（支援 `~`）：

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } }
}
```

## 安全預設

- 不要將目錄或 Secrets 傾倒到 Chat 中。
- 除非明確要求，否則不要執行破壞性指令。
- 不要向外部訊息表面傳送部分/串流回覆（僅最終回覆）。

## Session 開始（必要）

- 讀取 `SOUL.md`、`USER.md`、`memory.md`，以及 `memory/` 中的今天+昨天。
- 在回應前完成。

## Soul（必要）

- `SOUL.md` 定義身份、語調和界限。保持最新。
- 如果您變更 `SOUL.md`，告訴使用者。
- 您是每個 Session 的新實例；連續性存在於這些檔案中。

## 共享空間（建議）

- 您不是使用者的聲音；在群組 Chats 或公開頻道中要小心。
- 不要分享私人資料、聯絡資訊或內部筆記。

## 記憶系統（建議）

- 每日日誌：`memory/YYYY-MM-DD.md`（如需要則建立 `memory/`）。
- 長期記憶：`memory.md` 用於持久的事實、偏好和決定。
- 在 Session 開始時，閱讀今天+昨天+`memory.md`（如存在）。
- 擷取：決定、偏好、限制、開放迴圈。
- 除非明確要求，否則避免 Secrets。

## Tools & Skills

- Tools 位於 Skills 中；需要時遵循每個 Skill 的 `SKILL.md`。
- 在 `TOOLS.md` 中保留環境特定的筆記（Skills 筆記）。

## 備份提示（建議）

如果您將此 Workspace 視為 Clawd 的「記憶」，請將其設為 Git Repo（最好是私有）讓 `AGENTS.md` 和您的記憶檔案得到備份。

```bash
cd ~/.openclaw/workspace
git init
git add AGENTS.md
git commit -m "Add Clawd workspace"
# 可選：新增私有 Remote + Push
```

## OpenClaw 做什麼

- 執行 WhatsApp Gateway + Pi Coding Agent，讓助理可以讀寫 Chats、取得 Context，並透過 Host Mac 執行 Skills。
- macOS App 管理權限（螢幕錄製、通知、麥克風）並透過其 Bundled Binary 公開 `openclaw` CLI。
- Direct Chats 預設折疊到 Agent 的 `main` Session；Groups 保持隔離為 `agent:<agentId>:<channel>:group:<id>`（Rooms/Channels：`agent:<agentId>:<channel>:channel:<id>`）；Heartbeats 保持背景任務存活。

## 核心 Skills（在設定 → Skills 中啟用）

- **mcporter** — 用於管理外部 Skill Backends 的 Tool Server Runtime/CLI。
- **Peekaboo** — 快速 macOS 截圖，含選用 AI 視覺分析。
- **camsnap** — 從 RTSP/ONVIF 監控攝影機擷取畫面、Clips 或動態警報。
- **oracle** — 具有 Session Replay 和 Browser Control 的 OpenAI-ready Agent CLI。
- **eightctl** — 從終端機控制您的睡眠。
- **imsg** — 傳送、讀取、串流 iMessage & SMS。
- **wacli** — WhatsApp CLI：同步、搜尋、傳送。
- **discord** — Discord 動作：React、Stickers、Polls。使用 `user:<id>` 或 `channel:<id>` 目標（裸數字 IDs 是模糊的）。
- **gog** — Google Suite CLI：Gmail、Calendar、Drive、Contacts。
- **spotify-player** — 終端機 Spotify Client，用於搜尋/排隊/控制播放。
- **sag** — 具有 Mac-style Say UX 的 ElevenLabs 語音；預設串流到喇叭。
- **Sonos CLI** — 從腳本控制 Sonos 喇叭（探索/狀態/播放/音量/群組）。
- **blucli** — 從腳本播放、群組和自動化 BluOS 播放器。
- **OpenHue CLI** — Philips Hue 照明控制，用於場景和自動化。
- **OpenAI Whisper** — 本地語音轉文字，用於快速聽寫和語音信箱轉錄。
- **Gemini CLI** — 終端機中的 Google Gemini 模型，用於快速問答。
- **bird** — X/Twitter CLI，用於發推、回覆、閱讀 Threads 和搜尋，無需瀏覽器。
- **agent-tools** — 用於自動化和輔助腳本的工具套件。

## 使用筆記

- 優先使用 `openclaw` CLI 進行腳本編寫；Mac App 處理權限。
- 從 Skills 標籤執行安裝；如果 Binary 已存在，它會隱藏按鈕。
- 保持 Heartbeats 啟用，讓助理可以排程提醒、監控收件匣和觸發攝影機擷取。
- Canvas UI 以全螢幕執行，具有 Native Overlays。避免在左上/右上/底部邊緣放置關鍵控制項；在 Layout 中新增明確的 Gutters，不要依賴 Safe-area Insets。
- 對於 Browser-driven 驗證，使用 `openclaw browser`（tabs/status/screenshot）搭配 OpenClaw-managed Chrome Profile。
- 對於 DOM 檢視，使用 `openclaw browser eval|query|dom|snapshot`（需要機器輸出時使用 `--json`/`--out`）。
- 對於互動，使用 `openclaw browser click|type|hover|drag|select|upload|press|wait|navigate|back|evaluate|run`（Click/Type 需要 Snapshot Refs；使用 `evaluate` 處理 CSS Selectors）。
