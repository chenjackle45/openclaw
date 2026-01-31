---
title: "Matrix(Matrix 插件)"
summary: "Matrix 支援狀態、功能與設定"
read_when:
  - 處理 Matrix 頻道功能時
---
# Matrix (插件)

Matrix 是一個開放且去中心化的訊息協定。OpenClaw 作為 Matrix **使用者**連線至任何 homeserver，因此您需要為機器人準備一個 Matrix 帳號。Beeper 也是一個可行的客戶端選擇，但需要啟用 E2EE（端到端加密）。

狀態：透過插件支援。支援私訊、房間 (Rooms)、執行緒、媒體、表情回饋、投票、位置以及 E2EE 加密。

## 安裝插件
```bash
openclaw plugins install @openclaw/matrix
```

## 設定流程
1. 安裝插件。
2. 在 homeserver（如 matrix.org 或自託管）建立帳號。
3. 取得 **存取令牌 (Access Token)**：
   - 您可以使用 `curl` 調用登入 API 取得。
   - 或在 `channels.matrix` 中設定帳號密碼，OpenClaw 會自動處理登入並存儲令牌。
4. 設定認證資訊：
   - 設定：`channels.matrix.homeserver`, `channels.matrix.accessToken` 等。
5. 啟動 Gateway。
6. 從任何 Matrix 客戶端（Element, Beeper 等）發送私訊給機器人。

## 端到端加密 (E2EE)
透過 Rust crypto SDK 支援 E2EE。
- 設定：`channels.matrix.encryption: true`。
- 初次連線時，OpenClaw 會從您的其他會話請求**裝置驗證**。請在 Element 等客戶端中核准驗證以共享密鑰。
- 如果缺少模組，OpenClaw 會記錄警告且無法解密訊息。

## 存取控制
- **私訊**：預設使用配對模式。未知發送者會收到配對碼，需執行 `openclaw pairing approve matrix <代碼>` 核准。
- **房間 (群組)**：預設使用允許清單 (`allowlist`) 且需要標註 (Mention) 機器人。
  - 您可以在 `channels.matrix.groups` 中加入房間 ID 或別名。

## 回覆模式
支援執行緒 (Threads) 回覆，可透過 `channels.matrix.threadReplies` 控制回覆是否留在執行緒中。

## 功能概覽
- ✅ 私訊、房間、執行緒
- ✅ 媒體傳輸
- ✅ E2EE 加密（需 crypto 模組）
- ✅ 表情回饋與位置分享
