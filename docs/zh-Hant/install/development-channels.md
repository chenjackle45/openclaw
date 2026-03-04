---
summary: "穩定版、Beta 版和開發版頻道：語義、切換方式和標籤規則"
read_when:
  - You want to switch between stable/beta/dev
  - You are tagging or publishing prereleases
title: "Development Channels（開發頻道）"
---

# 開發頻道

最後更新：2026-01-21

OpenClaw 提供三個更新頻道：

- **穩定版（stable）**：npm dist-tag `latest`。
- **Beta 版（beta）**：npm dist-tag `beta`（測試中的建置）。
- **開發版（dev）**：移動中的 `main` 分支（git）。npm dist-tag：`dev`（發佈時）。

我們會先發佈建置到 **Beta 版**，進行測試，然後**推廣經過驗證的建置至 `latest`**（不改變版本號）。npm dist-tag 是 npm 安裝的唯一信源。

## 切換頻道

Git checkout：

```bash
openclaw update --channel stable
openclaw update --channel beta
openclaw update --channel dev
```

- `stable`/`beta` 會 checkout 最新相符的標籤（通常是同一個標籤）。
- `dev` 會切換到 `main` 並 rebase 上游。

npm/pnpm 全域安裝：

```bash
openclaw update --channel stable
openclaw update --channel beta
openclaw update --channel dev
```

這會通過相應的 npm dist-tag（`latest`、`beta`、`dev`）進行更新。

當你**明確地**使用 `--channel` 切換頻道時，OpenClaw 也會對齐安裝方式：

- `dev` 確保進行 git checkout（預設 `~/openclaw`，使用 `OPENCLAW_GIT_DIR` 覆寫），更新它，並從該 checkout 安裝全域 CLI。
- `stable`/`beta` 使用相符的 dist-tag 從 npm 安裝。

提示：如果想同時使用穩定版和開發版，保留兩個複製副本，將 Gateway 指向穩定版的那個。

## 外掛程式和頻道

當你使用 `openclaw update` 切換頻道時，OpenClaw 也會同步外掛程式來源：

- `dev` 優先使用 git checkout 中的整合外掛程式。
- `stable` 和 `beta` 恢復 npm 安裝的外掛程式套件。

## 標籤最佳實踐

- 標籤標記你希望 git checkout 落地的版本（穩定版用 `vYYYY.M.D`，Beta 版用 `vYYYY.M.D-beta.N`）。
- `vYYYY.M.D.beta.N` 也可被識別以支援相容性，但優先使用 `-beta.N`。
- 舊版 `vYYYY.M.D-<patch>` 標籤仍被識別為穩定版（非 Beta）。
- 保持標籤不可變：絕不移動或重複使用標籤。
- npm dist-tag 保持為 npm 安裝的唯一信源：
  - `latest` → 穩定版
  - `beta` → 候選建置
  - `dev` → main 快照（選用）

## macOS 應用程式可用性

Beta 和開發版建置**可能不會**包含 macOS 應用程式發行。沒問題：

- git 標籤和 npm dist-tag 仍可發佈。
- 在發行說明或變更日誌中說明「本 Beta 版沒有 macOS 建置」。
