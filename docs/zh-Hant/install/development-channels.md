---
title: "Development channels(發布頻道)"
summary: "Stable, Beta 與 Dev 頻道：語義說明、頻道切換與標籤管理"
read_when:
  - 您想要在穩定版/測試版/開發版之間切換時
  - 您正在標記或發布預發布版本時
---

# 發布頻道 (Development Channels)

最後更新日期：2026-01-21

OpenClaw 提供三種更新頻道：

- **stable** (穩定版)：對應 npm dist-tag `latest`。
- **beta** (測試版)：對應 npm dist-tag `beta` (待測試的建置版本)。
- **dev** (開發版)：Git `main` 分支的最新狀態；或 npm dist-tag `dev`。

我們會先將版本發布至 **beta** 頻道進行測試，通過驗證後再將該版本**晉升 (Promote) 至 `latest`**，而不一定會變更版本號 —— npm 安裝的最終權威來源是 dist-tags。

## 切換頻道

如果您是使用 Git 原始碼檢出版本或是 npm 全域安裝：

```bash
openclaw update --channel stable
openclaw update --channel beta
openclaw update --channel dev
```

- `stable`/`beta` 會切換至最新的對應標籤 (Tag)。
- `dev` 會切換至 `main` 分支並與遠端原始碼同步。

當您**明確地**使用 `--channel` 切換頻道時，OpenClaw 會自動調整安裝方式：
- `dev` 會確保使用 Git 檢出版本（預設存放於 `~/openclaw`），更新該版本並從中安裝全域 CLI。
- `stable`/`beta` 則會透過 npm 使用對應的 dist-tag 進行安裝。

提示：如果您想平行並用穩定版與開發版，建議保留兩個不同的目錄。

## 插件與頻道

當您執行 `openclaw update` 切換頻道時，OpenClaw 也會同步插件來源：
- `dev` 頻道優先使用 Git 檢出版本中的內建插件。
- `stable` 與 `beta` 頻道則會還原使用 npm 安裝的插件套件。

## 標籤 (Tagging) 最佳實踐

- 針對想要讓 Git 客戶端定錨的版本進行標記 (例如 `v2026.1.21`)。
- 保持標籤不可變 (Immutable)：絕不移動或重複使用已存在的標籤。
- npm dist-tags 仍是 npm 安裝的權威來源：
  - `latest` → stable (穩定版)
  - `beta` → candidate build (候選版本)

## macOS App 可用性

Beta 與 Dev 版本**不一定**會包含 macOS App 的發布檔。這是正常的：
- Git 標籤與 npm dist-tag 仍可正常發布。
- 請在發布說明或變更日誌中標註「此測試版不提供 macOS 建置檔」。
