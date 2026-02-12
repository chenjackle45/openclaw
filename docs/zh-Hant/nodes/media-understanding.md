---
summary: "入站影像/音訊/影片理解（選擇性）搭配提供者 + CLI 後備"
read_when:
  - 設計或重構媒體理解
  - 調整入站音訊/影片/影像預處理
title: "Media Understanding（媒體理解）"
---

# 媒體理解（入站）— 2026-01-17

OpenClaw 可以在回覆管道執行前**摘要入站媒體**（影像/音訊/影片）。它自動檢測本機工具或提供者金鑰何時可用，並可被停用或自訂。如果理解關閉，模型仍然照常接收原始檔案/URL。

## 目標

- 選擇性：將入站媒體預先消化為簡短文字，以便更快路由 + 更好的命令解析。
- 保留原始媒體傳遞到模型（始終）。
- 支援**提供者 API** 和 **CLI 後備**。
- 允許多個具有排序後備的模型（錯誤/大小/逾時）。

## 高級別行為

1. 收集入站附件（`MediaPaths`、`MediaUrls`、`MediaTypes`）。
2. 對於每個啟用的功能（影像/音訊/影片），根據原則選擇附件（預設：**第一個**）。
3. 選擇第一個合適的模型條目（大小 + 功能 + 驗證）。
4. 如果模型失敗或媒體太大，**回退到下一個條目**。
5. 成功時：
   - `Body` 變成 `[Image]`、`[Audio]` 或 `[Video]` 區塊。
   - 音訊設定 `{{Transcript}}`；命令解析在字幕存在時使用字幕文字，
     否則使用文字記錄。
   - 字幕保留為區塊內的 `User text:`。

如果理解失敗或停用，**回覆流繼續**使用原始本文 + 附件。

## 設定概述

`tools.media` 支援**共享模型**加上每個功能的覆蓋：

- `tools.media.models`：共享模型清單（使用 `capabilities` 進行門控）。
- `tools.media.image` / `tools.media.audio` / `tools.media.video`：
  - 預設值（`prompt`、`maxChars`、`maxBytes`、`timeoutSeconds`、`language`）
  - 提供者覆蓋（`baseUrl`、`headers`、`providerOptions`）
  - Deepgram 音訊選項透過 `tools.media.audio.providerOptions.deepgram`
  - 可選的**每個功能 `models` 清單**（在共享模型前偏好）
  - `attachments` 原則（`mode`、`maxAttachments`、`prefer`）
  - `scope`（選擇性門控透過頻道/chatType/會話金鑰）
- `tools.media.concurrency`：最大並發功能執行（預設 **2**）。

```json5
{
  tools: {
    media: {
      models: [
        /* 共享清單 */
      ],
      image: {
        /* 可選覆蓋 */
      },
      audio: {
        /* 可選覆蓋 */
      },
      video: {
        /* 可選覆蓋 */
      },
    },
  },
}
```

### 模型條目

每個 `models[]` 條目可以是**提供者**或 **CLI**：

```json5
{
  type: "provider", // 如果省略，預設
  provider: "openai",
  model: "gpt-5.2",
  prompt: "描述影像，<=500 個字元。",
  maxChars: 500,
  maxBytes: 10485760,
  timeoutSeconds: 60,
  capabilities: ["image"], // 可選，用於多模態條目
  profile: "vision-profile",
  preferredProfile: "vision-fallback",
}
```

詳見 [API 使用和成本](/zh-Hant/reference/api-usage-costs) 了解媒體理解費用詳情。
