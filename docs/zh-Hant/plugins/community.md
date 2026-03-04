---
summary: "Community plugins: quality bar, hosting requirements, and PR submission path"
read_when:
  - You want to publish a third-party OpenClaw plugin
  - You want to propose a plugin for docs listing
title: "Community plugins（社區外掛程式）"
---

# 社群外掛

此頁面追蹤 OpenClaw 的高品質**社群維護外掛**。

當社群外掛符合品質標準時，我們接受將其新增到此頁面的 PR。

## 清單所需

- 外掛包發佈在 npmjs 上（可透過 `openclaw plugins install <npm-spec>` 安裝）。
- 原始碼託管在 GitHub 上（公開儲存庫）。
- 儲存庫包括設定/使用文件和問題追蹤器。
- 外掛有清晰的維護信號（積極的維護者、最近的更新或回應問題）。

## 如何提交

開啟 PR，將你的外掛新增到此頁面，包括：

- 外掛名稱
- npm 包名稱
- GitHub 儲存庫 URL
- 單行描述
- 安裝命令

## 檢查欄

我們偏好有用、有文件記錄且安全運作的外掛。
低努力包裝器、不清楚的擁有權或未維護的套件可能會被拒絕。

## 候選人格式

新增項目時使用此格式：

- **外掛名稱** — 簡短描述
  npm: `@scope/package`
  repo: `https://github.com/org/repo`
  install: `openclaw plugins install @scope/package`

## 列出的外掛

- **WeChat** — 透過 WeChatPadPro（iPad 協定）將 OpenClaw 連線到 WeChat 個人帳戶。支援文字、影像和檔案交換以及關鍵字觸發的對話。
  npm: `@icesword760/openclaw-wechat`
  repo: `https://github.com/icesword0760/openclaw-wechat`
  install: `openclaw plugins install @icesword760/openclaw-wechat`
