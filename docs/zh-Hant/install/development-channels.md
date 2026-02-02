---
title: "Development Channels"
summary: "穩定版、測試版與開發版：語義、切換與標籤"
read_when:
  - 您想在穩定版/測試版/開發版間切換
  - 您正標記或發布預發布版本
---

# Development Channels

最後更新：2026-01-21

OpenClaw 提供三個更新頻道：

- **stable**：npm dist-tag `latest`。
- **beta**：npm dist-tag `beta`（測試中的建置）。
- **dev**：`main` 分支移動頭部（git）。npm dist-tag：`dev`（發布時）。

我們將建置發布至 **beta**，測試後，將已驗證的建置**提升至 `latest`**
而不變更版本號 —— dist-tags 是 npm 安裝的真實來源。

## 切換頻道

Git checkout：

```bash
openclaw update --channel stable
openclaw update --channel beta
openclaw update --channel dev
```

- `stable`/`beta` 檢出最新的相符標籤（通常是同一標籤）。
- `dev` 切換至 `main` 並在上游 rebase。

npm/pnpm 全域安裝：

```bash
openclaw update --channel stable
openclaw update --channel beta
openclaw update --channel dev
```

這會透過對應的 npm dist-tag（`latest`、`beta`、`dev`）更新。

當您**明確地**使用 `--channel` 切換頻道時，OpenClaw 也會調整
安裝方法：

- `dev` 確保 git checkout（預設 `~/openclaw`，可用 `OPENCLAW_GIT_DIR` 覆蓋），
  更新它，並從該 checkout 安裝全域 CLI。
- `stable`/`beta` 使用相符的 dist-tag 從 npm 安裝。

提示：若想平行執行穩定版 + 開發版，保留兩個複製並將 Gateway 指向穩定版複製。

## 插件與頻道

當您使用 `openclaw update` 切換頻道時，OpenClaw 也會同步插件來源：

- `dev` 偏好 git checkout 的內建插件。
- `stable` 和 `beta` 還原 npm 安裝的插件套件。

## 標籤最佳實踐

- 標籤 git checkout 應著陸的發布（`vYYYY.M.D` 或 `vYYYY.M.D-<patch>`）。
- 保持標籤不可變：絕不移動或重複使用標籤。
- npm dist-tags 保持 npm 安裝的真實來源：
  - `latest` → 穩定版
  - `beta` → 候選建置
  - `dev` → main 快照（選用）

## macOS app 可用性

Beta 和 dev 建置**可能**不包括 macOS app 發布。這是正常的：

- git 標籤和 npm dist-tag 仍可發布。
- 在發布說明或變更日誌中說明「此 beta 無 macOS 建置」。
