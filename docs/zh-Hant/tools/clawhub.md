---
summary: "ClawHub 指南：公開技能註冊表 + CLI 工作流"
read_when:
  - 向新使用者介紹 ClawHub
  - 安裝、搜尋或發佈技能
  - 解釋 ClawHub CLI 旗標與同步行為
title: "ClawHub"
---

# ClawHub

ClawHub 是 **OpenClaw 的公開技能註冊表**。這是一項免費服務：所有技能都是公開的、開源的，對每個人都可見，以便於分享和重複使用。技能只是一個包含 `SKILL.md` 檔案的資料夾（加上支援文字檔）。你可以在 Web 應用中瀏覽技能或使用 CLI 搜尋、安裝、更新和發佈技能。

網站：[clawhub.ai](https://clawhub.ai)

## ClawHub 是什麼

- OpenClaw 技能的公開註冊表。
- 技能組合和中繼資料的版本化存放區。
- 搜尋、標籤和使用信號的探索表面。

## 運作方式

1. 使用者發佈技能組合（檔案 + 中繼資料）。
2. ClawHub 存儲組合、解析中繼資料並指派版本。
3. 註冊表為搜尋和探索索引技能。
4. 使用者在 OpenClaw 中瀏覽、下載和安裝技能。

## 你可以做什麼

- 發佈新技能和現有技能的新版本。
- 透過名稱、標籤或搜尋發現技能。
- 下載技能組合並檢查其檔案。
- 報告濫用或不安全的技能。
- 如果你是版主，隱藏、顯示、刪除或禁止。

## 適合誰（初學者友善）

如果你想在 OpenClaw 代理中新增新功能，ClawHub 是尋找和安裝技能的最簡單方式。你不需要知道後端的運作方式。你可以：

- 用純語言搜尋技能。
- 將技能安裝到工作區。
- 稍後用一個指令更新技能。
- 透過發佈備份自己的技能。

## 快速開始（非技術性）

1. 安裝 CLI（見下一節）。
2. 搜尋你需要的東西：
   - `clawhub search "calendar"`
3. 安裝技能：
   - `clawhub install <skill-slug>`
4. 啟動新的 OpenClaw 會話，以便它接收新技能。

## 安裝 CLI

選擇一個：

```bash
npm i -g clawhub
```

```bash
pnpm add -g clawhub
```

## 如何融入 OpenClaw

預設情況下，CLI 將技能安裝到目前工作目錄下的 `./skills`。如果設定了 OpenClaw 工作區，`clawhub` 會除非你覆寫 `--workdir`（或 `CLAWHUB_WORKDIR`），否則後援到該工作區。OpenClaw 從 `<workspace>/skills` 載入工作區技能，並將在 **下一個** 會話中接收。如果你已使用 `~/.openclaw/skills` 或綁定技能，工作區技能優先。

如需有關技能如何載入、共享和閘控的詳細資訊，請參閱
[技能](/tools/skills)。

## 技能系統概覽

技能是教 OpenClaw 如何執行特定任務的檔案的版本化組合。每次發佈都會建立新版本，註冊表保持版本歷史，以便使用者可以稽核變更。

典型的技能包括：

- 含有主要描述和使用方法的 `SKILL.md` 檔案。
- 技能使用的選擇性設定、指令或支援檔案。
- 標籤、摘要和安裝需求等中繼資料。

ClawHub 使用中繼資料來強化探索和安全地公開技能功能。
註冊表還追蹤使用信號（如星標和下載）以改進
排名和可見性。

## 服務提供的內容（功能）

- **公開瀏覽**技能及其 `SKILL.md` 內容。
- **搜尋**由嵌入（向量搜尋）支援，而非僅關鍵字。
- **版本控制**支持 semver、變更記錄和標籤（包括 `latest`）。
- **下載**每個版本的 zip。
- **星標和評論**用於社群回饋。
- **審核**掛鉤用於批准和稽核。
- **CLI 友善的 API** 用於自動化和指令編寫。

## 安全與審核

ClawHub 預設開放。任何人都可以上傳技能，但 GitHub 帳戶必須至少一週前建立才能發佈。這有助於減緩濫用，而不阻止合法貢獻者。

報告和審核：

- 任何登入的使用者都可以報告技能。
- 報告原因是必需的且已記錄。
- 每個使用者最多可有 20 個主動報告。
- 超過 3 個獨特報告的技能預設會自動隱藏。
- 版主可以檢視隱藏的技能、顯示、刪除或禁止使用者。
- 濫用報告功能可能導致帳戶禁止。

有興趣成為版主？在 OpenClaw Discord 中提問並聯絡版主或維護者。

## CLI 指令與參數

全域選項（適用於所有指令）：

- `--workdir <dir>`：工作目錄（預設：當前目錄；後援到 OpenClaw 工作區）。
- `--dir <dir>`：相對於 workdir 的技能目錄（預設：`skills`）。
- `--site <url>`：網站基礎 URL（瀏覽器登入）。
- `--registry <url>`：註冊表 API 基礎 URL。
- `--no-input`：停用提示（非互動式）。
- `-V, --cli-version`：列印 CLI 版本。

驗證：

- `clawhub login`（瀏覽器流程）或 `clawhub login --token <token>`
- `clawhub logout`
- `clawhub whoami`

選項：

- `--token <token>`：貼上 API 令牌。
- `--label <label>`：用於瀏覽器登入令牌的標籤（預設：`CLI token`）。
- `--no-browser`：不開啟瀏覽器（需要 `--token`）。

搜尋：

- `clawhub search "query"`
- `--limit <n>`：最大結果數。

安裝：

- `clawhub install <slug>`
- `--version <version>`：安裝特定版本。
- `--force`：若資料夾已存在則覆寫。

更新：

- `clawhub update <slug>`
- `clawhub update --all`
- `--version <version>`：更新為特定版本（僅單個 slug）。
- `--force`：本地檔案不符合任何發佈版本時覆寫。

列表：

- `clawhub list`（讀取 `.clawhub/lock.json`）

發佈：

- `clawhub publish <path>`
- `--slug <slug>`：技能 slug。
- `--name <name>`：顯示名稱。
- `--version <version>`：Semver 版本。
- `--changelog <text>`：變更記錄文字（可以為空）。
- `--tags <tags>`：逗號分隔的標籤（預設：`latest`）。

刪除／取消刪除（所有者／管理員僅）：

- `clawhub delete <slug> --yes`
- `clawhub undelete <slug> --yes`

同步（掃描本地技能 + 發佈新／已更新）：

- `clawhub sync`
- `--root <dir...>`：額外掃描根目錄。
- `--all`：不提示上傳所有內容。
- `--dry-run`：顯示將上傳的內容。
- `--bump <type>`：`patch|minor|major` 用於更新（預設：`patch`）。
- `--changelog <text>`：用於非互動式更新的變更記錄。
- `--tags <tags>`：逗號分隔的標籤（預設：`latest`）。
- `--concurrency <n>`：註冊表檢查（預設：4）。

## 代理常見工作流

### 搜尋技能

```bash
clawhub search "postgres backups"
```

### 下載新技能

```bash
clawhub install my-skill-pack
```

### 更新已安裝的技能

```bash
clawhub update --all
```

### 備份你的技能（發佈或同步）

對於單個技能資料夾：

```bash
clawhub publish ./my-skill --slug my-skill --name "My Skill" --version 1.0.0 --tags latest
```

一次掃描並備份許多技能：

```bash
clawhub sync --all
```

## 進階詳細資訊（技術）

### 版本控制與標籤

- 每次發佈都會建立新的 **semver** `SkillVersion`。
- 標籤（如 `latest`）指向版本；移動標籤讓你可以復原。
- 變更記錄按版本附加，在同步或發佈更新時可以為空。

### 本地變更 vs 註冊表版本

更新使用內容雜湊比較本地技能內容與註冊表版本。如果本地檔案不符合任何發佈版本，CLI 會詢問是否覆寫（或在非互動式執行中需要 `--force`）。

### 同步掃描與後援根目錄

`clawhub sync` 首先掃描目前工作目錄。如果找不到技能，它會後援到已知舊版位置（例如 `~/openclaw/skills` 和 `~/.openclaw/skills`）。這旨在無需額外旗標即可找到較舊的技能安裝。

### 存儲與鎖檔

- 已安裝的技能記錄在工作目錄下的 `.clawhub/lock.json` 中。
- 驗證令牌存儲在 ClawHub CLI 組態檔中（透過 `CLAWHUB_CONFIG_PATH` 覆寫）。

### 遙測（安裝計數）

當你在登入時執行 `clawhub sync` 時，CLI 會傳送最小快照來計算安裝計數。你可以完全停用：

```bash
export CLAWHUB_DISABLE_TELEMETRY=1
```

## 環境變數

- `CLAWHUB_SITE`：覆寫網站 URL。
- `CLAWHUB_REGISTRY`：覆寫註冊表 API URL。
- `CLAWHUB_CONFIG_PATH`：覆寫 CLI 儲存令牌／組態的位置。
- `CLAWHUB_WORKDIR`：覆寫預設工作目錄。
- `CLAWHUB_DISABLE_TELEMETRY=1`：在 `sync` 時停用遙測。
