---
title: "Onboarding Overview（入門概述）"
summary: "OpenClaw 入門選項和流的概述"
read_when:
  - 選擇入門路徑時
  - 設定新環境時
sidebarTitle: "入門概述"
---

# 入門概述

OpenClaw 根據 Gateway 執行的位置和你喜歡配置提供者的方式支援多個入門路徑。

## 選擇你的入門路徑

- **CLI 精靈**適用於 macOS、Linux 和 Windows（透過 WSL2）。
- **macOS 應用**適用於 Apple silicon 或 Intel Mac 上的引導式首次執行。

## CLI 入門精靈

在終端機中執行精靈：

```bash
openclaw onboard
```

當你想要完整控制 Gateway、工作區、頻道和技能時，使用 CLI 精靈。文件：

- [入門精靈（CLI）](/zh-Hant/start/wizard)
- [`openclaw onboard` 命令](/zh-Hant/cli/onboard)

## macOS 應用入門

在 macOS 上想要完全引導式設定時，使用 OpenClaw 應用。文件：

- [入門（macOS 應用）](/zh-Hant/start/onboarding)

## 自訂提供者

如果需要未列出的端點，包括公開標準 OpenAI 或 Anthropic API 的託管提供者，在 CLI 精靈中選擇**自訂提供者**。系統將要求你：

- 選擇 OpenAI 相容、Anthropic 相容或**未知**（自動偵測）。
- 輸入基本 URL 和 API 金鑰（如果提供者需要）。
- 提供模型 ID 和選用別名。
- 選擇端點 ID，以便多個自訂端點可以共存。

詳細步驟，請追蹤上面的 CLI 入門文件。
