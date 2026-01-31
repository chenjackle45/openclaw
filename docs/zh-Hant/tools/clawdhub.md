---
title: "ClawdHub(ClawdHub)"
summary: "ClawdHub 指南：公開 Skills Registry + CLI 工作流程"
read_when:
  - 向新使用者介紹 ClawdHub
  - 安裝、搜尋或發布 Skills
  - 說明 ClawdHub CLI Flags 和同步行為
---

# ClawdHub

ClawdHub 是 **OpenClaw 的公開 Skill Registry**。這是一項免費服務：所有 Skills 都是公開、開放的，每個人都可以看到並用於分享和重用。一個 Skill 就是一個包含 `SKILL.md` 檔案（加上支援的文字檔案）的資料夾。您可以在 Web App 中瀏覽 Skills 或使用 CLI 搜尋、安裝、更新和發布 Skills。

網站：[clawdhub.com](https://clawdhub.com)

## 適用對象（初學者友善）

如果您想為 OpenClaw Agent 新增功能，ClawdHub 是尋找和安裝 Skills 最簡單的方式。您不需要了解後端如何運作。您可以：

- 使用自然語言搜尋 Skills。
- 將 Skill 安裝到您的 Workspace。
- 稍後使用一個指令更新 Skills。
- 透過發布備份您自己的 Skills。

## 快速開始（非技術）

1) 安裝 CLI（見下一節）。
2) 搜尋您需要的東西：
   - `clawdhub search "calendar"`
3) 安裝 Skill：
   - `clawdhub install <skill-slug>`
4) 啟動新的 OpenClaw Session 讓它載入新 Skill。

## 安裝 CLI

選擇一種：

```bash
npm i -g clawdhub
```

```bash
pnpm add -g clawdhub
```

## 如何融入 OpenClaw

預設情況下，CLI 會將 Skills 安裝到目前工作目錄下的 `./skills`。如果設定了 OpenClaw Workspace，`clawdhub` 會回退到該 Workspace，除非您覆寫 `--workdir`（或 `CLAWDHUB_WORKDIR`）。OpenClaw 從 `<workspace>/skills` 載入 Workspace Skills，並會在**下一個** Session 載入它們。如果您已經使用 `~/.openclaw/skills` 或 Bundled Skills，Workspace Skills 優先。

有關 Skills 如何載入、分享和 Gated 的更多詳情，請見 [Skills](/tools/skills)。

## 服務提供的功能

- Skills 及其 `SKILL.md` 內容的**公開瀏覽**。
- 由 Embeddings 驅動的**搜尋**（向量搜尋），而非僅關鍵字。
- 使用 Semver、Changelogs 和 Tags（包括 `latest`）的**版本控制**。
- 每個版本的 Zip **下載**。
- 社群回饋的**Stars 和留言**。
- 用於核准和稽核的 **Moderation** Hooks。
- 用於自動化和腳本的 **CLI 友善 API**。

## CLI 指令和參數

全域選項（適用於所有指令）：

- `--workdir <dir>`：工作目錄（預設：目前目錄；回退至 OpenClaw Workspace）。
- `--dir <dir>`：Skills 目錄，相對於 Workdir（預設：`skills`）。
- `--site <url>`：Site Base URL（瀏覽器登入）。
- `--registry <url>`：Registry API Base URL。
- `--no-input`：停用提示（非互動式）。
- `-V, --cli-version`：列印 CLI 版本。

Auth：

- `clawdhub login`（瀏覽器流程）或 `clawdhub login --token <token>`
- `clawdhub logout`
- `clawdhub whoami`

選項：

- `--token <token>`：貼上 API Token。
- `--label <label>`：儲存給瀏覽器登入 Tokens 的標籤（預設：`CLI token`）。
- `--no-browser`：不開啟瀏覽器（需要 `--token`）。

搜尋：

- `clawdhub search "query"`
- `--limit <n>`：最大結果數。

安裝：

- `clawdhub install <slug>`
- `--version <version>`：安裝特定版本。
- `--force`：如果資料夾已存在則覆寫。

更新：

- `clawdhub update <slug>`
- `clawdhub update --all`
- `--version <version>`：更新至特定版本（僅限單一 Slug）。
- `--force`：當本地檔案不符合任何已發布版本時覆寫。

清單：

- `clawdhub list`（讀取 `.clawdhub/lock.json`）

發布：

- `clawdhub publish <path>`
- `--slug <slug>`：Skill Slug。
- `--name <name>`：顯示名稱。
- `--version <version>`：Semver 版本。
- `--changelog <text>`：Changelog 文字（可為空）。
- `--tags <tags>`：逗號分隔的 Tags（預設：`latest`）。

刪除/取消刪除（僅限 Owner/Admin）：

- `clawdhub delete <slug> --yes`
- `clawdhub undelete <slug> --yes`

同步（掃描本地 Skills + 發布新增/更新）：

- `clawdhub sync`
- `--root <dir...>`：額外掃描根目錄。
- `--all`：上傳所有內容而不提示。
- `--dry-run`：顯示將上傳的內容。
- `--bump <type>`：更新時使用 `patch|minor|major`（預設：`patch`）。
- `--changelog <text>`：非互動式更新的 Changelog。
- `--tags <tags>`：逗號分隔的 Tags（預設：`latest`）。
- `--concurrency <n>`：Registry 檢查數（預設：4）。

## Agents 的常見工作流程

### 搜尋 Skills

```bash
clawdhub search "postgres backups"
```

### 下載新 Skills

```bash
clawdhub install my-skill-pack
```

### 更新已安裝的 Skills

```bash
clawdhub update --all
```

### 備份您的 Skills（發布或同步）

對於單一 Skill 資料夾：

```bash
clawdhub publish ./my-skill --slug my-skill --name "My Skill" --version 1.0.0 --tags latest
```

一次掃描並備份多個 Skills：

```bash
clawdhub sync --all
```

## 進階詳情（技術）

### 版本控制和 Tags

- 每次發布會建立新的 **Semver** `SkillVersion`。
- Tags（如 `latest`）指向一個版本；移動 Tags 讓您可以 Rollback。
- Changelogs 會附加至每個版本，同步或發布更新時可以為空。

### 本地變更 vs Registry 版本

更新會使用 Content Hash 比較本地 Skill 內容與 Registry 版本。如果本地檔案不符合任何已發布版本，CLI 會在覆寫前詢問（或在非互動式執行中需要 `--force`）。

### 同步掃描和 Fallback 根目錄

`clawdhub sync` 首先掃描您目前的 Workdir。如果找不到 Skills，它會回退至已知的舊版位置（例如 `~/openclaw/skills` 和 `~/.openclaw/skills`）。這是為了在不需要額外 Flags 的情況下找到舊版 Skill 安裝。

### 儲存和 Lockfile

- 已安裝的 Skills 記錄在 Workdir 下的 `.clawdhub/lock.json`。
- Auth Tokens 儲存在 ClawdHub CLI Config 檔案中（透過 `CLAWDHUB_CONFIG_PATH` 覆寫）。

### 遙測（安裝計數）

當您在登入狀態下執行 `clawdhub sync` 時，CLI 會傳送最小快照以計算安裝次數。您可以完全停用此功能：

```bash
export CLAWDHUB_DISABLE_TELEMETRY=1
```

## 環境變數

- `CLAWDHUB_SITE`：覆寫 Site URL。
- `CLAWDHUB_REGISTRY`：覆寫 Registry API URL。
- `CLAWDHUB_CONFIG_PATH`：覆寫 CLI 儲存 Token/Config 的位置。
- `CLAWDHUB_WORKDIR`：覆寫預設 Workdir。
- `CLAWDHUB_DISABLE_TELEMETRY=1`：停用 `sync` 時的遙測。
